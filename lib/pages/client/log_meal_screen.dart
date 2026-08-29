import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../models/enums.dart';
import '../../models/meal_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/food_ai_service.dart';
import '../../services/storage_service.dart';
import '../../l10n/l10n_ext.dart';
import '../../ui/ui.dart';

/// The four acts of the meal-logging experience.
enum _Phase { input, viewfinder, analyzing, result }

/// The entry paths. Chosen in [LogMealChooserSheet] (the compact creation
/// sheet on home) — the full-screen flow then opens already in that mode.
enum LogMealAction { scan, gallery, describe, manual }

/// A single food line returned by the AI ("what the AI saw").
class _AiItem {
  final String name;
  final String portion;
  final int calories;
  const _AiItem({required this.name, required this.portion, required this.calories});
}

// The capture stage is cinematic dark in BOTH themes (like the cover, §1.9) —
// camera chrome lives on the Night tokens regardless of the app theme.
const _kDark = Color(0xFF14120D);
const _kOnDark = Color(0xFFF1EDE3);
const _kOnDarkDim = Color(0xFFA79F90);
const _kGold = Color(0xFFC6A87C);

/// Meal logging (design.md §5.9, v2.12): the user CHOOSES the method first —
/// a calm chooser with all three paths visible — and only "Scan a meal" opens
/// the custom in-app camera.
///
///  • **Choose** — warm paper: scan hero card (→ live viewfinder), quiet
///    gallery link, then Describe and Manual as full option cards.
///  • **Viewfinder** — full-bleed live camera on the dark stage: back, torch
///    (lights the plate live), gallery chip, shutter. Camera starts only here.
///  • **Analyzing** — the Moment: the shot freezes in place, dimmed, ONE gold
///    sweep reads it, a serif statement + one rotating quiet line.
///  • **Result** — back on warm paper: photo hero, naked kcal, portion chips
///    (½×–2×), home-tint macro columns, confidence dot + word, hairline AI
///    rows, Adjust/Log pills; a "N kcal left today" toast closes the loop.
///
/// Present with `MaterialPageRoute(fullscreenDialog: true)`.
class LogMealScreen extends StatefulWidget {
  final String clientId;
  final String coachId;

  /// When set (the home chooser sheet's pick), the screen opens straight into
  /// that path; cancelling it pops the flow. Null lands on the in-screen
  /// chooser (used again by "start over" and analyze-failure returns).
  final LogMealAction? initialAction;

  const LogMealScreen({
    super.key,
    required this.clientId,
    required this.coachId,
    this.initialAction,
  });

  @override
  State<LogMealScreen> createState() => _LogMealScreenState();
}

class _LogMealScreenState extends State<LogMealScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  _Phase _phase = _Phase.input;
  bool _isManual = false;
  bool _editing = false;
  bool _isSaving = false;
  bool _fromPhoto = false;

  Uint8List? _imageBytes;
  int _confidenceScore = 0;
  List<_AiItem> _items = const [];
  MealConfidence _aiConfidence = MealConfidence.manual;

  /// Result-act portion multiplier (½× … 2×) applied to every number at
  /// display and save time. Reset to 1 whenever base values change.
  double _portion = 1.0;

  final _descriptionController = TextEditingController();
  final _nameController = TextEditingController();
  final _calsController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();

  final _firestoreService = FirestoreService();
  final _foodAiService = FoodAiService();
  final _storageService = StorageService();
  final _imagePicker = ImagePicker();

  CameraController? _camera;
  bool _cameraFailed = false;
  bool _capturing = false;
  bool _torchOn = false;

  late final AnimationController _scan = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final action = widget.initialAction;
    if (action != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        switch (action) {
          case LogMealAction.scan:
            _openViewfinder();
          case LogMealAction.gallery:
            _pickFromGallery(popOnCancel: true);
          case LogMealAction.describe:
            _openDescribe(popOnCancel: true);
          case LogMealAction.manual:
            _startManual();
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera?.dispose();
    _scan.dispose();
    _descriptionController.dispose();
    _nameController.dispose();
    _calsController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Camera — alive ONLY while the viewfinder act is on screen.
  // -------------------------------------------------------------------------

  void _openViewfinder() {
    HapticFeedback.lightImpact();
    setState(() {
      _phase = _Phase.viewfinder;
      _cameraFailed = false;
    });
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (_camera != null) return;
    try {
      final cams = await availableCameras();
      if (cams.isEmpty) throw CameraException('no-camera', 'No cameras found');
      final back = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cams.first,
      );
      // Medium (~720p) is plenty for the AI read + thumbnails and keeps
      // uploads light — no separate resize step needed.
      final controller = CameraController(
        back,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);
      if (!mounted || _phase != _Phase.viewfinder) {
        controller.dispose();
        return;
      }
      setState(() {
        _camera = controller;
        _torchOn = false;
        _cameraFailed = false;
      });
    } catch (_) {
      if (mounted) setState(() => _cameraFailed = true);
    }
  }

  void _disposeCamera() {
    final cam = _camera;
    _camera = null;
    _torchOn = false;
    cam?.dispose();
  }

  /// Standard camera-plugin lifecycle: release on background, re-arm on
  /// resume if the viewfinder is still the active act.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _disposeCamera();
    } else if (state == AppLifecycleState.resumed &&
        _phase == _Phase.viewfinder) {
      _initCamera();
    }
  }

  /// Torch, not still-flash: the LED lights the plate LIVE in the preview (and
  /// stays on through the capture) — visible, predictable, right for food.
  Future<void> _toggleTorch() async {
    final cam = _camera;
    if (cam == null || !cam.value.isInitialized) return;
    HapticFeedback.selectionClick();
    final next = !_torchOn;
    try {
      await cam.setFlashMode(next ? FlashMode.torch : FlashMode.off);
      if (mounted) setState(() => _torchOn = next);
    } catch (_) {}
  }

  Future<void> _shoot() async {
    final cam = _camera;
    if (cam == null || !cam.value.isInitialized || _capturing) return;
    HapticFeedback.mediumImpact();
    setState(() => _capturing = true);
    try {
      final shot = await cam.takePicture();
      final bytes = await shot.readAsBytes();
      if (!mounted) return;
      setState(() {
        _imageBytes = bytes;
        _fromPhoto = true;
      });
      _disposeCamera();
      await _analyze();
    } catch (_) {
      if (!mounted) return;
      _showError(context.l10n.aiCameraError);
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  void _backToChooser() {
    _disposeCamera();
    setState(() => _phase = _Phase.input);
  }

  // -------------------------------------------------------------------------
  // Input paths
  // -------------------------------------------------------------------------

  Future<void> _pickFromGallery({bool popOnCancel = false}) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) {
        if (popOnCancel && mounted) Navigator.of(context).pop();
        return;
      }
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      _disposeCamera();
      setState(() {
        _imageBytes = bytes;
        _fromPhoto = true;
      });
      await _analyze();
    } catch (_) {
      if (!mounted) return;
      _showError(context.l10n.aiCameraError);
    }
  }

  Future<void> _openDescribe({bool popOnCancel = false}) async {
    final description = await showVSheet<String>(
      context: context,
      builder: (_) => const _DescribeSheet(),
    );
    if (!mounted) return;
    if (description == null || description.trim().isEmpty) {
      if (popOnCancel) Navigator.of(context).pop();
      return;
    }
    _descriptionController.text = description.trim();
    setState(() {
      _fromPhoto = false;
      _imageBytes = null;
    });
    await _analyze();
  }

  void _startManual() {
    HapticFeedback.lightImpact();
    _nameController.clear();
    _calsController.clear();
    _proteinController.clear();
    _carbsController.clear();
    _fatController.clear();
    setState(() {
      _isManual = true;
      _editing = true;
      _fromPhoto = false;
      _imageBytes = null;
      _confidenceScore = 0;
      _items = const [];
      _portion = 1.0;
      _phase = _Phase.result;
    });
  }

  // -------------------------------------------------------------------------
  // AI
  // -------------------------------------------------------------------------

  Future<void> _analyze() async {
    final description = _descriptionController.text.trim();
    // The meal name/portion the AI returns is shown in the UI AND saved to the
    // meal, so it must come back in the app's language — otherwise an Arabic
    // user scans a plate and gets "Grilled salmon bowl" stored forever in an
    // RTL screen. Read before the await, not across it.
    final locale = Localizations.localeOf(context).languageCode;
    setState(() => _phase = _Phase.analyzing);
    try {
      // Run the real AI call alongside a minimum dwell so the "reading" moment
      // is felt rather than flashing past.
      final results = await Future.wait([
        _foodAiService.analyzeFood(
          locale: locale,
          description: description.isEmpty ? null : description,
          imageBytes: _fromPhoto ? _imageBytes : null,
        ),
        Future<void>.delayed(const Duration(milliseconds: 1300)),
      ]);
      final result = results.first as Map<String, dynamic>?;
      if (result == null) throw Exception('No result from AI.');
      _applyResult(result);
      if (!mounted) return;
      setState(() {
        _isManual = false;
        _editing = false;
        _portion = 1.0;
        _phase = _Phase.result;
      });
      HapticFeedback.mediumImpact();
    } catch (e) {
      if (!mounted) return;
      setState(() => _phase = _Phase.input);
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _applyResult(Map<String, dynamic> result) {
    _nameController.text = '${result['name'] ?? ''}'.trim();
    _calsController.text = '${(result['calories'] as num?)?.round() ?? ''}';
    _proteinController.text = _trimNum(result['protein']);
    _carbsController.text = _trimNum(result['carbs']);
    _fatController.text = _trimNum(result['fat']);

    final conf = result['confidence'];
    if (conf is num) {
      _confidenceScore = conf.round().clamp(0, 100);
    } else if (conf is String) {
      _confidenceScore = conf == 'high'
          ? 92
          : conf == 'medium'
              ? 68
              : 38;
    } else {
      _confidenceScore = 70;
    }
    _aiConfidence = _confidenceScore >= 80
        ? MealConfidence.high
        : _confidenceScore >= 50
            ? MealConfidence.medium
            : MealConfidence.low;

    final raw = result['items'];
    _items = (raw is List)
        ? raw
            .whereType<Map>()
            .map((m) => _AiItem(
                  name: '${m['name'] ?? ''}'.trim(),
                  portion: '${m['portion'] ?? ''}'.trim(),
                  calories: (m['calories'] as num?)?.round() ?? 0,
                ))
            .where((it) => it.name.isNotEmpty)
            .toList()
        : const [];
  }

  String _trimNum(dynamic v) {
    if (v is num) {
      return v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(1);
    }
    return '';
  }

  // -------------------------------------------------------------------------
  // Portion scaling + save
  // -------------------------------------------------------------------------

  String _fmtMacro(double v) =>
      v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(1);

  String _scaledCalsText() {
    final c = int.tryParse(_calsController.text.trim());
    return c == null ? '–' : '${(c * _portion).round()}';
  }

  String _scaledMacroText(TextEditingController c) {
    final v = double.tryParse(c.text.trim());
    return v == null ? '–' : '${_fmtMacro(v * _portion)}g';
  }

  bool get _hasNumbers => int.tryParse(_calsController.text.trim()) != null;

  /// Entering edit mode bakes the current portion into the base values, so
  /// what the user edits is exactly what they see.
  void _toggleEditing() {
    HapticFeedback.selectionClick();
    setState(() {
      if (!_editing && _portion != 1.0) {
        final c = int.tryParse(_calsController.text.trim());
        if (c != null) _calsController.text = '${(c * _portion).round()}';
        for (final ctrl in [_proteinController, _carbsController, _fatController]) {
          final v = double.tryParse(ctrl.text.trim());
          if (v != null) ctrl.text = _fmtMacro(v * _portion);
        }
        _portion = 1.0;
      }
      _editing = !_editing;
    });
  }

  Future<void> _saveMeal() async {
    final name = _nameController.text.trim();
    final cals = int.tryParse(_calsController.text.trim());
    final protein = double.tryParse(_proteinController.text.trim());
    final carbs = double.tryParse(_carbsController.text.trim());
    final fat = double.tryParse(_fatController.text.trim());

    if (name.isEmpty || cals == null || protein == null || carbs == null || fat == null) {
      _showError(context.l10n.fillMealAndMacros);
      setState(() => _editing = true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      String? imageUrl;
      if (_fromPhoto && _imageBytes != null) {
        try {
          imageUrl = await _storageService.uploadMealPhoto(widget.clientId, _imageBytes!);
        } catch (e) {
          debugPrint('Meal photo upload failed: $e');
        }
      }

      final meal = Meal(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        calories: (cals * _portion).round(),
        protein: double.parse(_fmtMacro(protein * _portion)),
        carbs: double.parse(_fmtMacro(carbs * _portion)),
        fat: double.parse(_fmtMacro(fat * _portion)),
        imageUrl: imageUrl,
        aiConfidence: _isManual ? MealConfidence.manual : _aiConfidence,
        loggedAt: DateTime.now(),
      );
      await _firestoreService.addMealToLog(widget.clientId, meal);
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      // Close the loop: how much budget is left today. Toast BEFORE the pop —
      // it lives on the root overlay, so it survives the navigation.
      await _showRemainingToast();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      _showError(context.l10n.failedToSaveMeal);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _showRemainingToast() async {
    try {
      final target =
          context.read<AuthProvider>().currentUser?.targetMacros?.calories ?? 0;
      if (target <= 0) return;
      final log = await _firestoreService.getOrCreateTodayLog(
        widget.clientId,
        widget.coachId,
      );
      if (!mounted) return;
      final remaining = target - log.totalCalories;
      showVToast(
        context,
        remaining >= 0
            ? context.l10n.kcalLeftToday(remaining)
            : context.l10n.kcalOverToday(-remaining),
      );
    } catch (_) {}
  }

  void _showError(String message) {
    if (!mounted) return;
    showVToast(context, message);
  }

  void _reset() {
    _disposeCamera();
    setState(() {
      _phase = _Phase.input;
      _isManual = false;
      _editing = false;
      _fromPhoto = false;
      _imageBytes = null;
      _items = const [];
      _confidenceScore = 0;
      _portion = 1.0;
    });
  }

  Color _confidenceTint(ValenceTokens t) => switch (_aiConfidence) {
        MealConfidence.high => t.sage,
        MealConfidence.medium => t.gold,
        MealConfidence.low => t.clay,
        MealConfidence.manual => t.inkTertiary,
      };

  // -------------------------------------------------------------------------
  // UI
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final onStage = _phase == _Phase.viewfinder || _phase == _Phase.analyzing;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: onStage
          ? SystemUiOverlayStyle.light
          : (t.isLight ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light),
      child: PopScope(
        // Android back: viewfinder steps back to the chooser instead of
        // killing the whole flow; analyzing is not interruptible.
        canPop: _phase == _Phase.input || _phase == _Phase.result,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && _phase == _Phase.viewfinder) _backToChooser();
        },
        child: Scaffold(
          backgroundColor: onStage ? _kDark : t.canvas,
          body: AnimatedSwitcher(
            duration: VDuration.standard,
            switchInCurve: VMotion.curve,
            switchOutCurve: Curves.easeIn,
            child: switch (_phase) {
              _Phase.input => _buildChooser(),
              _Phase.viewfinder => _buildViewfinder(),
              _Phase.analyzing => _buildAnalyzing(),
              _Phase.result => _buildResult(),
            },
          ),
        ),
      ),
    );
  }

  // ---- Act 0 — Choose the method --------------------------------------------

  Widget _buildChooser() {
    final t = context.tokens;

    return SafeArea(
      key: const ValueKey('input'),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsetsDirectional.fromSTEB(
            VSpace.screenMargin, 8, VSpace.screenMargin, VSpace.scrollBottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VIconCircle(
              icon: PhosphorIconsBold.x,
              semanticLabel: context.l10n.close,
              onTap: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(height: 18),
            Text(
              context.l10n.snapItLogged,
              style: VType.title1.copyWith(color: t.ink),
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.aiReadsPlate,
              style: VType.subhead.copyWith(color: t.inkSecondary),
            ),
            const SizedBox(height: 24),

            // The hero path — a slice of the camera stage on warm paper.
            _ScanHeroCard(onTap: _openViewfinder),
            const SizedBox(height: VSpace.cardGap),

            // The other paths — one calm grouped card, nothing hidden.
            VGroupCard(
              dividerInset: 62,
              children: [
                _MethodRow(
                  icon: PhosphorIconsFill.image,
                  tint: t.steel,
                  title: context.l10n.chooseFromGallery,
                  subtitle: context.l10n.galleryCardSub,
                  onTap: () => _pickFromGallery(),
                ),
                _MethodRow(
                  icon: PhosphorIconsFill.sparkle,
                  tint: t.gold,
                  title: context.l10n.describeYourMeal,
                  subtitle: context.l10n.describeCardSub,
                  onTap: () => _openDescribe(),
                ),
                _MethodRow(
                  icon: PhosphorIconsFill.pencilSimple,
                  tint: t.clay,
                  title: context.l10n.enterMacrosManually,
                  subtitle: context.l10n.manualCardSub,
                  onTap: _startManual,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---- Act 1 — Viewfinder ---------------------------------------------------

  Widget _buildViewfinder() {
    final cam = _camera;
    final ready = cam != null && cam.value.isInitialized;

    return Stack(
      key: const ValueKey('viewfinder'),
      fit: StackFit.expand,
      children: [
        // Live preview, cover-fit.
        if (ready)
          _CoverPreview(controller: cam)
        else
          Container(
            color: _kDark,
            child: Center(
              child: _cameraFailed
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(PhosphorIconsRegular.cameraSlash,
                              size: 40, color: _kOnDark.withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          Text(
                            context.l10n.aiCameraError,
                            textAlign: TextAlign.center,
                            style: VType.subhead.copyWith(color: _kOnDarkDim),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _kGold),
                    ),
            ),
          ),
        // Legibility scrims over the live image (chrome, not decoration).
        const _StageScrims(),
        SafeArea(
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
                VSpace.screenMargin, 8, VSpace.screenMargin, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    _StageChip(
                      icon: PhosphorIconsBold.caretLeft,
                      semanticLabel: context.l10n.back,
                      onTap: _backToChooser,
                    ),
                    const Spacer(),
                  ],
                ),
                if (ready) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(VRadius.pill),
                    ),
                    child: Text(
                      context.l10n.centerYourPlate,
                      style: VType.caption.copyWith(color: _kOnDark),
                    ),
                  ),
                ],
                const Spacer(),
                // Gallery · shutter · torch.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StageChip(
                      icon: PhosphorIconsRegular.image,
                      semanticLabel: context.l10n.chooseFromGallery,
                      size: 48,
                      onTap: _pickFromGallery,
                    ),
                    _Shutter(
                      enabled: ready && !_capturing,
                      capturing: _capturing,
                      onTap: _shoot,
                    ),
                    _StageChip(
                      icon: _torchOn
                          ? PhosphorIconsFill.lightning
                          : PhosphorIconsRegular.lightningSlash,
                      iconColor: _torchOn ? _kGold : _kOnDark,
                      semanticLabel: context.l10n.flashLabel,
                      size: 48,
                      onTap: ready ? _toggleTorch : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---- Act 2 — Analyzing (the Moment) ---------------------------------------

  Widget _buildAnalyzing() {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final hasPhoto = _fromPhoto && _imageBytes != null;

    return Stack(
      key: const ValueKey('analyzing'),
      fit: StackFit.expand,
      children: [
        // The frozen shot stays exactly where the live preview was.
        if (hasPhoto)
          Image.memory(_imageBytes!, fit: BoxFit.cover)
        else
          Container(color: _kDark),
        Container(color: Colors.black.withValues(alpha: hasPhoto ? 0.45 : 0)),
        const VSkyGlow(alpha: 0.22),
        // THE one gold sweep, across the whole stage.
        if (!reduceMotion)
          AnimatedBuilder(
            animation: _scan,
            builder: (context, _) {
              return Align(
                alignment: Alignment(0, (_scan.value * 2) - 1),
                child: Container(
                  height: 2.5,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0x00C6A87C), _kGold, Color(0x00C6A87C)],
                    ),
                  ),
                ),
              );
            },
          ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 3),
                if (!hasPhoto)
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: _kGold.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(PhosphorIconsFill.sparkle,
                        size: 32, color: _kGold),
                  ),
                const Spacer(flex: 2),
                VTextScaleCap(
                  child: Text(
                    context.l10n.readingYourPlate,
                    textAlign: TextAlign.center,
                    style: VType.serifTitle.copyWith(color: _kOnDark),
                  ),
                ),
                const SizedBox(height: 10),
                const _RotatingStatus(color: _kOnDarkDim),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---- Act 3 — Result (back on warm paper) ----------------------------------

  Widget _buildResult() {
    final t = context.tokens;
    final isAi = !_isManual;
    final confTint = _confidenceTint(t);
    final confWord = _confidenceScore >= 80
        ? context.l10n.confHigh
        : _confidenceScore >= 50
            ? context.l10n.confMedium
            : context.l10n.confLow;
    final hasPhoto = _imageBytes != null;

    return SafeArea(
      key: const ValueKey('result'),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsetsDirectional.fromSTEB(
            VSpace.screenMargin, 8, VSpace.screenMargin, VSpace.scrollBottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VIconCircle(
              icon: PhosphorIconsBold.x,
              semanticLabel: context.l10n.close,
              onTap: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(height: 16),

            // The plate, settled from the stage into a warm-paper hero.
            if (hasPhoto) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(VRadius.card),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 16),
            ],

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (!hasPhoto) ...[
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: t.tintFill(t.clay),
                      borderRadius: BorderRadius.circular(VRadius.squircle),
                    ),
                    child:
                        Icon(PhosphorIconsFill.forkKnife, size: 22, color: t.clay),
                  ),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isAi
                                ? PhosphorIconsFill.sparkle
                                : PhosphorIconsFill.pencilSimple,
                            size: 12,
                            color: t.goldDeep,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              isAi
                                  ? context.l10n.readByValenceAI
                                  : context.l10n.manualEntry,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: VType.caption.copyWith(
                                color: t.goldDeep,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _nameController.text.trim().isEmpty
                            ? (isAi
                                ? context.l10n.yourMeal
                                : context.l10n.newMeal)
                            : _nameController.text.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: VType.title2.copyWith(color: t.ink),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _mealSlotLabel(),
                        style: VType.subhead.copyWith(color: t.inkSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // Naked calorie headline (scaled by portion).
            Center(
              child: VTextScaleCap(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(PhosphorIconsFill.fire, size: 26, color: t.goldDeep),
                    const SizedBox(width: 10),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          _scaledCalsText(),
                          style: VType.display.copyWith(color: t.ink),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          context.l10n.kcal,
                          style: VType.subhead.copyWith(color: t.inkSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Portion chips — "I ate half" beats editing grams.
            if (!_editing && _hasNumbers) ...[
              const SizedBox(height: 18),
              Row(
                children: [
                  Text(
                    context.l10n.portionLabel,
                    style: VType.subhead.copyWith(color: t.inkSecondary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: VSegmented<double>(
                      selected: _portion,
                      onChanged: (v) => setState(() => _portion = v),
                      segments: const [
                        VSegment(0.5, '½×'),
                        VSegment(1.0, '1×'),
                        VSegment(1.5, '1½×'),
                        VSegment(2.0, '2×'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),

            // Macros — the home-dashboard columns, scaled by portion.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: VStatColumn(
                    icon: PhosphorIconsFill.fish,
                    tint: t.teal,
                    value: _scaledMacroText(_proteinController),
                    label: context.l10n.macroProtein,
                    statSize: 20,
                  ),
                ),
                Expanded(
                  child: VStatColumn(
                    icon: PhosphorIconsFill.bread,
                    tint: t.gold,
                    value: _scaledMacroText(_carbsController),
                    label: context.l10n.macroCarbs,
                    statSize: 20,
                  ),
                ),
                Expanded(
                  child: VStatColumn(
                    icon: PhosphorIconsFill.cheese,
                    tint: t.clay,
                    value: _scaledMacroText(_fatController),
                    label: context.l10n.macroFat,
                    statSize: 20,
                  ),
                ),
              ],
            ),

            if (isAi) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration:
                        BoxDecoration(color: confTint, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.confidenceNote(confWord, _confidenceScore),
                      style: VType.caption.copyWith(color: t.inkSecondary),
                    ),
                  ),
                ],
              ),
            ],

            if (_editing) ...[
              const SizedBox(height: 24),
              _EditPanel(
                nameController: _nameController,
                calsController: _calsController,
                proteinController: _proteinController,
                carbsController: _carbsController,
                fatController: _fatController,
                onChanged: () => setState(() {}),
              ),
            ] else if (isAi && _items.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                context.l10n.whatTheAiSaw,
                style: VType.subhead.copyWith(
                  color: t.inkSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              for (var i = 0; i < _items.length; i++) ...[
                if (i > 0) Divider(height: 1, thickness: 1, color: t.hairline),
                _ItemRow(item: _items[i], portion: _portion),
              ],
            ],

            const SizedBox(height: 28),

            // Stacked, not side by side.
            //
            // These two were an Expanded(1) : Expanded(2) row, which on a
            // 393pt screen left the secondary button 41.7px of text room after
            // its 44px of padding and its 20px icon. "Adjust" needs ~56px, so
            // it clipped mid-glyph in ENGLISH; "Anpassen" needs ~75 and
            // "Concluído" ~85. The primary was no better — "Enregistrer un
            // repas" and "Mahlzeit eintragen" both wrapped to two lines, which
            // left the two buttons at visibly different heights.
            //
            // Full width removes the constraint entirely in all six languages
            // on the smallest phone we support, and primary-over-secondary is
            // already the app's own pattern (showSettingsConfirm, the delete
            // sheet). VPillButton now also scales a label down rather than
            // clipping it, but that is a backstop — this is the actual fix.
            VPillButton.primary(
              label: context.l10n.logMeal,
              icon: PhosphorIconsFill.checkCircle,
              loading: _isSaving,
              onPressed: _isSaving ? null : _saveMeal,
            ),
            const SizedBox(height: 10),
            VPillButton.secondary(
              label: _editing ? context.l10n.done : context.l10n.adjust,
              icon: _editing
                  ? PhosphorIconsBold.check
                  : PhosphorIconsBold.slidersHorizontal,
              onPressed: _toggleEditing,
            ),
            Center(
              child: VTextAction(
                label: context.l10n.startOver,
                color: t.inkSecondary,
                onTap: _reset,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _mealSlotLabel() {
    final l10n = context.l10n;
    final now = DateTime.now();
    final h = now.hour;
    final slot = h < 11
        ? l10n.mealBreakfast
        : h < 15
            ? l10n.mealLunch
            : h < 18
                ? l10n.mealSnack
                : l10n.mealDinner;
    final time = MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay.fromDateTime(now));
    return '$slot · $time';
  }
}

// ===========================================================================
// Chooser pieces — shared by the home LogMealChooserSheet and the in-screen
// chooser act (start-over / analyze-failure returns).
// ===========================================================================

/// The compact creation sheet opened from the home "Log meal" pill (the
/// Instagram-style pattern): pick a method, the sheet pops with a
/// [LogMealAction], and home pushes the full-screen flow already in that mode.
class LogMealChooserSheet extends StatelessWidget {
  const LogMealChooserSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return VSheet(
      title: context.l10n.logAMeal,
      scrollable: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          _ScanHeroCard(
            onTap: () => Navigator.pop(context, LogMealAction.scan),
          ),
          const SizedBox(height: VSpace.cardGap),
          VGroupCard(
            dividerInset: 62,
            children: [
              _MethodRow(
                icon: PhosphorIconsFill.image,
                tint: t.steel,
                title: context.l10n.chooseFromGallery,
                subtitle: context.l10n.galleryCardSub,
                onTap: () => Navigator.pop(context, LogMealAction.gallery),
              ),
              _MethodRow(
                icon: PhosphorIconsFill.sparkle,
                tint: t.gold,
                title: context.l10n.describeYourMeal,
                subtitle: context.l10n.describeCardSub,
                onTap: () => Navigator.pop(context, LogMealAction.describe),
              ),
              _MethodRow(
                icon: PhosphorIconsFill.pencilSimple,
                tint: t.clay,
                title: context.l10n.enterMacrosManually,
                subtitle: context.l10n.manualCardSub,
                onTap: () => Navigator.pop(context, LogMealAction.manual),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// The scan hero — an INK slab (the primary-action color, §1.1: ink acts):
/// near-black on cream in Day, warm cream on dark in Night, so it flips with
/// the theme instead of fighting it. Framing brackets + a shutter ring with a
/// single gold dot are its identity — the screen's one considered detail, in
/// tokens only.
class _ScanHeroCard extends StatelessWidget {
  final VoidCallback onTap;
  const _ScanHeroCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return VPressable(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(18, 20, 18, 20),
        decoration: BoxDecoration(
          color: t.ink,
          borderRadius: BorderRadius.circular(VRadius.card),
          boxShadow: t.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: t.gold.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(PhosphorIconsFill.camera, size: 22, color: t.gold),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n.scanAMeal,
                    style: VType.headline.copyWith(color: t.onInk),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    context.l10n.scanCardSub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: VType.caption.copyWith(
                      color: t.onInk.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(PhosphorIconsBold.caretRight,
                size: 14, color: t.onInk.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

class _MethodRow extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MethodRow({
    required this.icon,
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return VPressable(
      onTap: onTap,
      overlay: true,
      overlayRadius: BorderRadius.circular(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 11, 10, 11),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: t.tintFill(tint),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 17, color: t.legibleTint(tint)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: VType.body.copyWith(
                        color: t.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: VType.caption.copyWith(color: t.inkSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(PhosphorIconsBold.caretRight, size: 14, color: t.inkTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Stage pieces (dark camera chrome)
// ===========================================================================

/// Cover-fit live camera preview (fills the stage regardless of sensor ratio).
class _CoverPreview extends StatelessWidget {
  final CameraController controller;
  const _CoverPreview({required this.controller});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    var scale = size.aspectRatio * controller.value.aspectRatio;
    if (scale < 1) scale = 1 / scale;
    return ClipRect(
      child: Transform.scale(
        scale: scale,
        child: Center(child: CameraPreview(controller)),
      ),
    );
  }
}

/// Top + bottom legibility scrims over the live image.
class _StageScrims extends StatelessWidget {
  const _StageScrims();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.45),
                Colors.black.withValues(alpha: 0),
              ],
            ),
          ),
        ),
        const Spacer(),
        Container(
          height: 200,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withValues(alpha: 0.55),
                Colors.black.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Round translucent chrome chip for the dark stage (no blur — a BackdropFilter
/// over a live camera feed costs frames on Android).
class _StageChip extends StatelessWidget {
  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onTap;
  final double size;
  final Color iconColor;

  const _StageChip({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
    this.size = 40,
    this.iconColor = _kOnDark,
  });

  @override
  Widget build(BuildContext context) {
    final hit = size < 44 ? 44.0 : size;
    return Semantics(
      label: semanticLabel,
      button: true,
      child: VPressable(
        onTap: onTap,
        semanticButton: false,
        child: SizedBox(
          width: hit,
          height: hit,
          child: Center(
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                shape: BoxShape.circle,
                border: Border.all(color: _kOnDark.withValues(alpha: 0.18)),
              ),
              child: Icon(icon, size: size * 0.42, color: iconColor),
            ),
          ),
        ),
      ),
    );
  }
}

/// The shutter — white ring + solid core, iOS camera language.
class _Shutter extends StatelessWidget {
  final bool enabled;
  final bool capturing;
  final VoidCallback onTap;

  const _Shutter({
    required this.enabled,
    required this.capturing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.scanAMeal,
      button: true,
      child: VPressable(
        onTap: enabled ? onTap : null,
        enableFeedback: enabled,
        semanticButton: false,
        scale: 0.92,
        child: Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _kOnDark.withValues(alpha: enabled ? 0.9 : 0.35),
              width: 4,
            ),
          ),
          padding: const EdgeInsets.all(5),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _kOnDark.withValues(alpha: enabled ? 1 : 0.4),
              shape: BoxShape.circle,
            ),
            child: capturing
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: _kDark),
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

/// Cycles through "what the AI is doing" lines to make the wait feel
/// intelligent.
class _RotatingStatus extends StatefulWidget {
  final Color color;
  const _RotatingStatus({required this.color});

  @override
  State<_RotatingStatus> createState() => _RotatingStatusState();
}

class _RotatingStatusState extends State<_RotatingStatus> {
  static const _messageCount = 4;
  List<String> _messages(BuildContext context) => [
        context.l10n.aiStatus1,
        context.l10n.aiStatus2,
        context.l10n.aiStatus3,
        context.l10n.aiStatus4,
      ];
  int _i = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
      if (!mounted) return;
      setState(() => _i = (_i + 1) % _messageCount);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
              .animate(anim),
          child: child,
        ),
      ),
      child: Text(
        _messages(context)[_i],
        key: ValueKey(_i),
        textAlign: TextAlign.center,
        style: VType.body.copyWith(color: widget.color),
      ),
    );
  }
}

// ===========================================================================
// Describe sheet — owns its controller (design.md §2 sheet law).
// ===========================================================================

class _DescribeSheet extends StatefulWidget {
  const _DescribeSheet();

  @override
  State<_DescribeSheet> createState() => _DescribeSheetState();
}

class _DescribeSheetState extends State<_DescribeSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      showVToast(context, context.l10n.describeMealFirst);
      return;
    }
    HapticFeedback.mediumImpact();
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.pop(context, text);
  }

  @override
  Widget build(BuildContext context) {
    return VSheet(
      title: context.l10n.describeYourMeal,
      pinnedAction: VPillButton.primary(
        label: context.l10n.analyzeWithAI,
        icon: PhosphorIconsFill.sparkle,
        onPressed: _submit,
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(top: 4, bottom: 8),
        child: VField(
          controller: _controller,
          hint: context.l10n.describeMealHint,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          onSubmitted: (_) => _submit(),
        ),
      ),
    );
  }
}

// ===========================================================================
// Result pieces
// ===========================================================================

/// One "what the AI saw" line — hairline-separated table row: name + portion
/// on the left, calories on the right (scaled with the portion multiplier).
class _ItemRow extends StatelessWidget {
  final _AiItem item;
  final double portion;
  const _ItemRow({required this.item, required this.portion});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: 11),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                text: item.name,
                style: VType.subhead.copyWith(
                  color: t.ink,
                  fontWeight: FontWeight.w600,
                ),
                children: item.portion.isEmpty
                    ? null
                    : [
                        TextSpan(
                          text: '  ·  ${item.portion}',
                          style: VType.caption.copyWith(color: t.inkSecondary),
                        ),
                      ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (item.calories > 0) ...[
            const SizedBox(width: 8),
            Text(
              '${(item.calories * portion).round()} ${context.l10n.kcal}',
              style: VType.subhead.copyWith(
                color: t.inkSecondary,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EditPanel extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController calsController;
  final TextEditingController proteinController;
  final TextEditingController carbsController;
  final TextEditingController fatController;
  final VoidCallback onChanged;

  const _EditPanel({
    required this.nameController,
    required this.calsController,
    required this.proteinController,
    required this.carbsController,
    required this.fatController,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    Widget unit(String text) =>
        Text(text, style: VType.caption.copyWith(color: t.inkTertiary));

    return Column(
      children: [
        VField(
          controller: nameController,
          label: context.l10n.mealName,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: VField(
                controller: calsController,
                label: context.l10n.caloriesLabel,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                suffix: unit(context.l10n.kcal),
                onChanged: (_) => onChanged(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: VField(
                controller: proteinController,
                label: context.l10n.macroProtein,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                suffix: unit('g'),
                onChanged: (_) => onChanged(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: VField(
                controller: carbsController,
                label: context.l10n.macroCarbs,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                suffix: unit('g'),
                onChanged: (_) => onChanged(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: VField(
                controller: fatController,
                label: context.l10n.macroFat,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                suffix: unit('g'),
                onChanged: (_) => onChanged(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
