import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../models/enums.dart';
import '../../models/meal_model.dart';
import '../../services/firestore_service.dart';
import '../../services/food_ai_service.dart';
import '../../services/storage_service.dart';
import '../../l10n/l10n_ext.dart';
import '../../ui/ui.dart';

/// The three phases of the meal-logging experience.
enum _Phase { input, analyzing, result }

/// A single food line returned by the AI ("what the AI saw").
class _AiItem {
  final String name;
  final String portion;
  final int calories;
  const _AiItem({required this.name, required this.portion, required this.calories});
}

/// The meal-logging flow — a FULL-SCREEN modal route (design.md §5.9, pivoted
/// from a bottom sheet at Yassine's call: capture is the product's hero moment
/// and deserves a stage, and iOS houses create/capture flows in full-screen
/// modals, not sheets). Present with
/// `MaterialPageRoute(fullscreenDialog: true)`.
///
/// Three acts:
///  • **Capture** — calm working screen: camera hero card, gallery/describe/
///    manual quiet paths.
///  • **Analyzing** — a MOMENT (§4-D): skyGlow, the photo dimmed in a big
///    squircle, ONE gold sweep, a serif statement and one rotating quiet line.
///    (Scan corners / shimmer bars / spinner rows are retired per §5.9.)
///  • **Result** — calm reveal: photo squircle + name, naked calorie number,
///    three tinted macro columns (home-dashboard tints), confidence as a tint
///    dot + word, "what the AI saw" hairline rows, Adjust/Log pills.
class LogMealScreen extends StatefulWidget {
  final String clientId;
  final String coachId;

  const LogMealScreen({
    super.key,
    required this.clientId,
    required this.coachId,
  });

  @override
  State<LogMealScreen> createState() => _LogMealScreenState();
}

class _LogMealScreenState extends State<LogMealScreen>
    with SingleTickerProviderStateMixin {
  _Phase _phase = _Phase.input;
  bool _isManual = false;
  bool _editing = false;
  bool _isSaving = false;
  bool _fromPhoto = false;

  Uint8List? _imageBytes;
  int _confidenceScore = 0;
  List<_AiItem> _items = const [];
  MealConfidence _aiConfidence = MealConfidence.manual;

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

  late final AnimationController _scan = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
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
  // Logic
  // -------------------------------------------------------------------------

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
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

  Future<void> _analyzeFromDescription() async {
    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      _showError(context.l10n.describeMealFirst);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _fromPhoto = false);
    await _analyze();
  }

  Future<void> _analyze() async {
    final description = _descriptionController.text.trim();
    setState(() => _phase = _Phase.analyzing);
    try {
      // Run the real AI call alongside a minimum dwell so the "reading" moment
      // is felt rather than flashing past.
      final results = await Future.wait([
        _foodAiService.analyzeFood(
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

  void _startManual() {
    setState(() {
      _isManual = true;
      _editing = true;
      _fromPhoto = false;
      _imageBytes = null;
      _confidenceScore = 0;
      _items = const [];
      _phase = _Phase.result;
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
        calories: cals,
        protein: protein,
        carbs: carbs,
        fat: fat,
        imageUrl: imageUrl,
        aiConfidence: _isManual ? MealConfidence.manual : _aiConfidence,
        loggedAt: DateTime.now(),
      );
      await _firestoreService.addMealToLog(widget.clientId, meal);
      HapticFeedback.mediumImpact();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      _showError(context.l10n.failedToSaveMeal);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    showVToast(context, message);
  }

  void _reset() {
    setState(() {
      _phase = _Phase.input;
      _isManual = false;
      _editing = false;
      _fromPhoto = false;
      _imageBytes = null;
      _items = const [];
      _confidenceScore = 0;
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
    final isMoment = _phase == _Phase.analyzing;

    return Scaffold(
      backgroundColor: t.canvas,
      body: Stack(
        children: [
          // Atmosphere ONLY while the AI reads — the analyzing act is the
          // flow's Moment (§4-D); capture and result stay flat canvas.
          if (isMoment) const VSkyGlow(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                      VSpace.screenMargin, 8, VSpace.screenMargin, 0),
                  child: VIconCircle(
                    icon: PhosphorIconsBold.x,
                    semanticLabel: context.l10n.close,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: VDuration.standard,
                    switchInCurve: VMotion.curve,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.02),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: _buildPhase(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhase() {
    switch (_phase) {
      case _Phase.input:
        return _InputView(
          key: const ValueKey('input'),
          descriptionController: _descriptionController,
          onCamera: () => _pickImage(ImageSource.camera),
          onGallery: () => _pickImage(ImageSource.gallery),
          onDescribe: _analyzeFromDescription,
          onManual: _startManual,
        );
      case _Phase.analyzing:
        return _AnalyzingView(
          key: const ValueKey('analyzing'),
          scan: _scan,
          imageBytes: _fromPhoto ? _imageBytes : null,
        );
      case _Phase.result:
        return _buildResult();
    }
  }

  // ---- Result phase --------------------------------------------------------

  Widget _buildResult() {
    final t = context.tokens;
    final isAi = !_isManual;
    final confTint = _confidenceTint(t);
    final confWord = _confidenceScore >= 80
        ? context.l10n.confHigh
        : _confidenceScore >= 50
            ? context.l10n.confMedium
            : context.l10n.confLow;

    return SingleChildScrollView(
      key: const ValueKey('result'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsetsDirectional.fromSTEB(
          VSpace.screenMargin, 16, VSpace.screenMargin, VSpace.scrollBottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: photo squircle · quiet source line · name · meal slot.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _MealThumb(imageBytes: _imageBytes),
              const SizedBox(width: 14),
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
                          ? (isAi ? context.l10n.yourMeal : context.l10n.newMeal)
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
          const SizedBox(height: 24),

          // Calorie headline — the home-hero language: fire + naked number.
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
                        _calsController.text.trim().isEmpty
                            ? '–'
                            : _calsController.text.trim(),
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
          const SizedBox(height: 20),

          // Macros — the home-dashboard columns (protein=teal fish, carbs=gold
          // bread, fat=clay cheese).
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: VStatColumn(
                  icon: PhosphorIconsFill.fish,
                  tint: t.teal,
                  value: _macroValue(_proteinController.text),
                  label: context.l10n.macroProtein,
                  statSize: 20,
                ),
              ),
              Expanded(
                child: VStatColumn(
                  icon: PhosphorIconsFill.bread,
                  tint: t.gold,
                  value: _macroValue(_carbsController.text),
                  label: context.l10n.macroCarbs,
                  statSize: 20,
                ),
              ),
              Expanded(
                child: VStatColumn(
                  icon: PhosphorIconsFill.cheese,
                  tint: t.clay,
                  value: _macroValue(_fatController.text),
                  label: context.l10n.macroFat,
                  statSize: 20,
                ),
              ),
            ],
          ),

          if (isAi) ...[
            const SizedBox(height: 20),
            // Confidence = tint dot + word (design.md §5.9 — the ring retired).
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

          // Edit panel OR the AI breakdown.
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
              _ItemRow(item: _items[i]),
            ],
          ],

          const SizedBox(height: 28),

          // Actions.
          Row(
            children: [
              Expanded(
                child: VPillButton.secondary(
                  label: _editing ? context.l10n.done : context.l10n.adjust,
                  icon: _editing
                      ? PhosphorIconsBold.check
                      : PhosphorIconsBold.slidersHorizontal,
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() => _editing = !_editing);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: VPillButton.primary(
                  label: context.l10n.logMeal,
                  icon: PhosphorIconsFill.checkCircle,
                  loading: _isSaving,
                  onPressed: _isSaving ? null : _saveMeal,
                ),
              ),
            ],
          ),
          if (isAi)
            Center(
              child: VTextAction(
                label: context.l10n.startOver,
                color: t.inkSecondary,
                onTap: _reset,
              ),
            ),
        ],
      ),
    );
  }

  String _macroValue(String raw) {
    final v = raw.trim();
    return v.isEmpty ? '–' : '${v}g';
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
// Act 1 — Capture
// ===========================================================================

class _InputView extends StatelessWidget {
  final TextEditingController descriptionController;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onDescribe;
  final VoidCallback onManual;

  const _InputView({
    super.key,
    required this.descriptionController,
    required this.onCamera,
    required this.onGallery,
    required this.onDescribe,
    required this.onManual,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsetsDirectional.fromSTEB(
          VSpace.screenMargin, 14, VSpace.screenMargin, VSpace.scrollBottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

          // Hero scan card (camera-first) — the screen's one considered detail.
          VPressable(
            onTap: () {
              HapticFeedback.lightImpact();
              onCamera();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(VRadius.card),
                boxShadow: t.cardShadow,
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: t.tintFill(t.gold),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(PhosphorIconsFill.camera,
                        size: 28, color: t.legibleTint(t.gold)),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    context.l10n.scanAMeal,
                    style: VType.headline.copyWith(color: t.ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.tapToOpenCamera,
                    style: VType.caption.copyWith(color: t.inkSecondary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: VTextAction(
              icon: PhosphorIconsRegular.image,
              label: context.l10n.chooseFromGallery,
              onTap: onGallery,
            ),
          ),

          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: Divider(height: 1, thickness: 1, color: t.hairline)),
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
                child: Text(
                  context.l10n.orDivider,
                  style: VType.caption.copyWith(color: t.inkTertiary),
                ),
              ),
              Expanded(child: Divider(height: 1, thickness: 1, color: t.hairline)),
            ],
          ),
          const SizedBox(height: 18),

          // Describe path.
          VField(
            controller: descriptionController,
            label: context.l10n.describeYourMeal,
            hint: context.l10n.describeMealHint,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 14),
          VPillButton.primary(
            label: context.l10n.analyzeWithAI,
            icon: PhosphorIconsFill.sparkle,
            onPressed: () {
              HapticFeedback.lightImpact();
              onDescribe();
            },
          ),
          const SizedBox(height: 6),
          Center(
            child: VTextAction(
              label: context.l10n.enterMacrosManually,
              color: t.inkSecondary,
              onTap: onManual,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Act 2 — Analyzing (the Moment: photo · ONE gold sweep · serif statement ·
// one rotating quiet line — nothing else, §4-D/§5.9)
// ===========================================================================

class _AnalyzingView extends StatelessWidget {
  final AnimationController scan;
  final Uint8List? imageBytes;

  const _AnalyzingView({
    super.key,
    required this.scan,
    required this.imageBytes,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // The plate, dimmed, being read.
            ClipRRect(
              borderRadius: BorderRadius.circular(VRadius.card),
              child: AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imageBytes != null)
                      Image.memory(imageBytes!, fit: BoxFit.cover)
                    else
                      Container(
                        color: t.surfaceSubtle,
                        child: Center(
                          child: Icon(PhosphorIconsFill.sparkle,
                              size: 40, color: t.legibleTint(t.gold)),
                        ),
                      ),
                    if (imageBytes != null)
                      Container(color: t.ink.withValues(alpha: 0.25)),
                    // THE one gold sweep.
                    if (!reduceMotion)
                      AnimatedBuilder(
                        animation: scan,
                        builder: (context, _) {
                          return Align(
                            alignment: Alignment(0, (scan.value * 2) - 1),
                            child: Container(
                              height: 2.5,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    t.gold.withValues(alpha: 0),
                                    t.gold,
                                    t.gold.withValues(alpha: 0),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 36),
            VTextScaleCap(
              child: Text(
                context.l10n.readingYourPlate,
                textAlign: TextAlign.center,
                style: VType.serifTitle.copyWith(color: t.ink),
              ),
            ),
            const SizedBox(height: 10),
            _RotatingStatus(),
          ],
        ),
      ),
    );
  }
}

/// Cycles through "what the AI is doing" lines to make the wait feel
/// intelligent.
class _RotatingStatus extends StatefulWidget {
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
    final t = context.tokens;
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
        style: VType.body.copyWith(color: t.inkSecondary),
      ),
    );
  }
}

// ===========================================================================
// Act 3 — Result pieces
// ===========================================================================

class _MealThumb extends StatelessWidget {
  final Uint8List? imageBytes;
  const _MealThumb({required this.imageBytes});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    if (imageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(VRadius.squircle),
        child: Image.memory(imageBytes!, width: 56, height: 56, fit: BoxFit.cover),
      );
    }
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: t.tintFill(t.clay),
        borderRadius: BorderRadius.circular(VRadius.squircle),
      ),
      child: Icon(PhosphorIconsFill.forkKnife, size: 24, color: t.clay),
    );
  }
}

/// One "what the AI saw" line — hairline-separated table row: name + portion
/// on the left, calories on the right (design.md §5.9).
class _ItemRow extends StatelessWidget {
  final _AiItem item;
  const _ItemRow({required this.item});

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
              '${item.calories} ${context.l10n.kcal}',
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
