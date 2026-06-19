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
import '../../theme/app_theme.dart';

/// The three phases of the meal-logging experience.
enum _Phase { input, analyzing, result }

/// A single food line returned by the AI ("what the AI saw").
class _AiItem {
  final String name;
  final String portion;
  final int calories;
  const _AiItem({required this.name, required this.portion, required this.calories});
}

/// Premium meal-logging flow:
/// **Capture** (photo / describe / manual) → **Analyzing** (animated AI read) →
/// **Result** (confidence + macro chips + per-item breakdown, editable) → log.
class LogMealBottomSheet extends StatefulWidget {
  final String clientId;
  final String coachId;

  const LogMealBottomSheet({
    super.key,
    required this.clientId,
    required this.coachId,
  });

  @override
  State<LogMealBottomSheet> createState() => _LogMealBottomSheetState();
}

class _LogMealBottomSheetState extends State<LogMealBottomSheet>
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
      HapticFeedback.lightImpact();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      _showError(context.l10n.failedToSaveMeal);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
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

  // -------------------------------------------------------------------------
  // UI
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final media = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.92),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Flexible(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.03),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: _buildPhase(theme, cs),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhase(ThemeData theme, ColorScheme cs) {
    switch (_phase) {
      case _Phase.input:
        return _InputView(
          key: const ValueKey('input'),
          theme: theme,
          descriptionController: _descriptionController,
          onCamera: () => _pickImage(ImageSource.camera),
          onGallery: () => _pickImage(ImageSource.gallery),
          onDescribe: _analyzeFromDescription,
          onManual: _startManual,
        );
      case _Phase.analyzing:
        return _AnalyzingView(
          key: const ValueKey('analyzing'),
          theme: theme,
          scan: _scan,
          imageBytes: _fromPhoto ? _imageBytes : null,
        );
      case _Phase.result:
        return _buildResult(theme, cs);
    }
  }

  // ---- Result phase --------------------------------------------------------

  Widget _buildResult(ThemeData theme, ColorScheme cs) {
    final textTheme = theme.textTheme;
    final isAi = !_isManual;

    return SingleChildScrollView(
      key: const ValueKey('result'),
      padding: EdgeInsets.fromLTRB(AppSpacing.p20, AppSpacing.p16, AppSpacing.p20, AppSpacing.p20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: thumbnail + source label + name + time + confidence ring.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _MealThumb(imageBytes: _imageBytes, theme: theme),
              SizedBox(width: AppSpacing.p12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isAi ? PhosphorIconsFill.sparkle : PhosphorIconsFill.pencilSimple,
                          size: 12,
                          color: AppColors.secondaryColor,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isAi ? context.l10n.readByValenceAI.toUpperCase() : context.l10n.manualEntry.toUpperCase(),
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.secondaryColor,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.4,
                            fontSize: 10,
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
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _mealSlotLabel(),
                      style: textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isAi) ...[
                SizedBox(width: AppSpacing.p8),
                _ConfidenceRing(score: _confidenceScore, theme: theme),
              ],
            ],
          ),
          SizedBox(height: AppSpacing.p20),

          // Calorie headline.
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                const Icon(PhosphorIconsFill.fire, color: AppColors.secondaryColor, size: 22),
                SizedBox(width: AppSpacing.p8),
                Text(
                  _calsController.text.trim().isEmpty ? '–' : _calsController.text.trim(),
                  style: textTheme.displaySmall?.copyWith(
                    color: AppColors.secondaryColor,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -2,
                    height: 1,
                  ),
                ),
                Text(
                  ' ${context.l10n.kcal}',
                  style: textTheme.titleMedium?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.p16),

          // Macro chips (container colours, matching the home dashboard).
          _MacroRow(
            theme: theme,
            protein: _proteinController.text,
            carbs: _carbsController.text,
            fat: _fatController.text,
          ),

          if (isAi) ...[
            SizedBox(height: AppSpacing.p16),
            _ConfidenceNote(score: _confidenceScore, theme: theme),
          ],

          // Edit panel OR the AI breakdown.
          if (_editing) ...[
            SizedBox(height: AppSpacing.p20),
            _EditPanel(
              nameController: _nameController,
              calsController: _calsController,
              proteinController: _proteinController,
              carbsController: _carbsController,
              fatController: _fatController,
              onChanged: () => setState(() {}),
            ),
          ] else if (isAi && _items.isNotEmpty) ...[
            SizedBox(height: AppSpacing.p20),
            _SectionLabel(theme: theme, label: context.l10n.whatTheAiSaw.toUpperCase()),
            SizedBox(height: AppSpacing.p12),
            ..._items.map((it) => _ItemRow(item: it, theme: theme)),
          ],

          SizedBox(height: AppSpacing.p24),

          // Actions.
          Row(
            children: [
              Expanded(
                child: _SecondaryButton(
                  theme: theme,
                  icon: _editing ? PhosphorIconsBold.check : PhosphorIconsBold.slidersHorizontal,
                  label: _editing ? context.l10n.done : context.l10n.adjust,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _editing = !_editing);
                  },
                ),
              ),
              SizedBox(width: AppSpacing.p12),
              Expanded(
                flex: 2,
                child: _PrimaryButton(
                  theme: theme,
                  icon: PhosphorIconsFill.checkCircle,
                  label: context.l10n.logMeal,
                  loading: _isSaving,
                  onTap: _isSaving ? null : _saveMeal,
                ),
              ),
            ],
          ),
          if (isAi) ...[
            SizedBox(height: AppSpacing.p12),
            Center(
              child: GestureDetector(
                onTap: _reset,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    context.l10n.startOver,
                    style: textTheme.labelMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
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
    final hour12 = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final ampm = now.hour < 12 ? 'am' : 'pm';
    final mm = now.minute.toString().padLeft(2, '0');
    return '$slot · $hour12:$mm $ampm';
  }
}

// ===========================================================================
// Input phase
// ===========================================================================

class _InputView extends StatelessWidget {
  final ThemeData theme;
  final TextEditingController descriptionController;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onDescribe;
  final VoidCallback onManual;

  const _InputView({
    super.key,
    required this.theme,
    required this.descriptionController,
    required this.onCamera,
    required this.onGallery,
    required this.onDescribe,
    required this.onManual,
  });

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(AppSpacing.p20, AppSpacing.p16, AppSpacing.p20, AppSpacing.p20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.logAMeal.toUpperCase(),
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.secondaryColor,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            context.l10n.snapItLogged,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: AppSpacing.p4),
          Text(
            context.l10n.aiReadsPlate,
            style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          SizedBox(height: AppSpacing.p20),

          // Hero scan tile (camera-first).
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onCamera();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.alphaBlend(
                      AppColors.secondaryColor.withValues(alpha: 0.10),
                      cs.surfaceContainerLow,
                    ),
                    cs.surfaceContainerLow,
                  ],
                  stops: const [0, 0.7],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.secondaryColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.secondaryColor,
                          AppColors.secondaryColor.withValues(alpha: 0.3),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: CircleAvatar(
                      backgroundColor: cs.surface,
                      child: const Icon(PhosphorIconsFill.camera,
                          color: AppColors.secondaryColor, size: 28),
                    ),
                  ),
                  SizedBox(height: AppSpacing.p12),
                  Text(
                    context.l10n.scanAMeal,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.tapToOpenCamera,
                    style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: AppSpacing.p12),
          Center(
            child: TextButton.icon(
              onPressed: onGallery,
              icon: const Icon(PhosphorIconsRegular.image, size: 17),
              style: TextButton.styleFrom(foregroundColor: cs.onSurfaceVariant),
              label: Text(context.l10n.chooseFromGallery),
            ),
          ),

          SizedBox(height: AppSpacing.p8),
          _OrDivider(theme: theme),
          SizedBox(height: AppSpacing.p16),

          // Describe path.
          TextField(
            controller: descriptionController,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: context.l10n.describeMealHint,
              labelText: context.l10n.describeYourMeal,
            ),
          ),
          SizedBox(height: AppSpacing.p12),
          _PrimaryButton(
            theme: theme,
            icon: PhosphorIconsFill.sparkle,
            label: context.l10n.analyzeWithAI,
            loading: false,
            onTap: () {
              HapticFeedback.lightImpact();
              onDescribe();
            },
          ),
          SizedBox(height: AppSpacing.p12),
          Center(
            child: TextButton(
              onPressed: onManual,
              style: TextButton.styleFrom(foregroundColor: cs.onSurfaceVariant),
              child: Text(context.l10n.enterMacrosManually),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  final ThemeData theme;
  const _OrDivider({required this.theme});

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final line = Expanded(
      child: Divider(color: cs.outlineVariant.withValues(alpha: 0.4), height: 1),
    );
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            context.l10n.orDivider,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.6),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        line,
      ],
    );
  }
}

// ===========================================================================
// Analyzing phase
// ===========================================================================

class _AnalyzingView extends StatelessWidget {
  final ThemeData theme;
  final AnimationController scan;
  final Uint8List? imageBytes;

  const _AnalyzingView({
    super.key,
    required this.theme,
    required this.scan,
    required this.imageBytes,
  });

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.p20, AppSpacing.p20, AppSpacing.p20, AppSpacing.p24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo (or AI orb) with a sweeping scan line.
          AspectRatio(
            aspectRatio: 16 / 10,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageBytes != null)
                    Image.memory(imageBytes!, fit: BoxFit.cover)
                  else
                    Container(color: cs.surfaceContainerHighest.withValues(alpha: 0.5)),
                  Container(color: AppColors.primaryColor.withValues(alpha: 0.25)),
                  if (imageBytes == null)
                    Center(
                      child: Icon(PhosphorIconsFill.sparkle,
                          size: 44, color: AppColors.secondaryColor.withValues(alpha: 0.8)),
                    ),
                  // Sweeping gold scan line.
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
                                AppColors.secondaryColor.withValues(alpha: 0),
                                AppColors.secondaryColor,
                                AppColors.secondaryColor.withValues(alpha: 0),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.secondaryColor.withValues(alpha: 0.6),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  // Corner brackets.
                  const Positioned.fill(child: _ScanCorners()),
                ],
              ),
            ),
          ),
          SizedBox(height: AppSpacing.p20),
          Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.secondaryColor,
                  backgroundColor: AppColors.secondaryColor.withValues(alpha: 0.2),
                ),
              ),
              SizedBox(width: AppSpacing.p8),
              Text(
                'Valence AI',
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.secondaryColor,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.p8),
          Text(
            context.l10n.readingYourPlate,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          _RotatingStatus(theme: theme),
          SizedBox(height: AppSpacing.p16),
          // Shimmer skeleton lines.
          ...List.generate(3, (i) => _ShimmerBar(theme: theme, widthFactor: 1 - i * 0.18)),
        ],
      ),
    );
  }
}

/// Cycles through "what the AI is doing" lines to make the wait feel intelligent.
class _RotatingStatus extends StatefulWidget {
  final ThemeData theme;
  const _RotatingStatus({required this.theme});

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
    final cs = widget.theme.colorScheme;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(anim),
          child: child,
        ),
      ),
      child: Text(
        _messages(context)[_i],
        key: ValueKey(_i),
        style: widget.theme.textTheme.bodyMedium?.copyWith(
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ScanCorners extends StatelessWidget {
  const _ScanCorners();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _Corner(top: true, left: true),
              _Corner(top: true, left: false),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _Corner(top: false, left: true),
              _Corner(top: false, left: false),
            ],
          ),
        ],
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  final bool top;
  final bool left;
  const _Corner({required this.top, required this.left});

  @override
  Widget build(BuildContext context) {
    const c = AppColors.secondaryColor;
    final side = BorderSide(color: c.withValues(alpha: 0.9), width: 2.5);
    return SizedBox(
      width: 22,
      height: 22,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: top ? side : BorderSide.none,
            bottom: top ? BorderSide.none : side,
            left: left ? side : BorderSide.none,
            right: left ? BorderSide.none : side,
          ),
        ),
      ),
    );
  }
}

class _ShimmerBar extends StatefulWidget {
  final ThemeData theme;
  final double widthFactor;
  const _ShimmerBar({required this.theme, required this.widthFactor});

  @override
  State<_ShimmerBar> createState() => _ShimmerBarState();
}

class _ShimmerBarState extends State<_ShimmerBar> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.theme.colorScheme;
    final base = cs.surfaceContainerHighest.withValues(alpha: 0.5);
    final hi = cs.surfaceContainerHighest.withValues(alpha: 0.9);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: widget.widthFactor,
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              return ShaderMask(
                blendMode: BlendMode.srcATop,
                shaderCallback: (rect) => LinearGradient(
                  begin: Alignment(_c.value * 3 - 1.5, 0),
                  end: Alignment(_c.value * 3 - 0.5, 0),
                  colors: [base, hi, base],
                ).createShader(rect),
                child: Container(
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Result pieces
// ===========================================================================

class _MealThumb extends StatelessWidget {
  final Uint8List? imageBytes;
  final ThemeData theme;
  const _MealThumb({required this.imageBytes, required this.theme});

  @override
  Widget build(BuildContext context) {
    if (imageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.memory(imageBytes!, width: 52, height: 52, fit: BoxFit.cover),
      );
    }
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.secondaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(PhosphorIconsFill.forkKnife, color: AppColors.secondaryColor, size: 22),
    );
  }
}

class _ConfidenceRing extends StatelessWidget {
  final int score;
  final ThemeData theme;
  const _ConfidenceRing({required this.score, required this.theme});

  @override
  Widget build(BuildContext context) {
    final textTheme = theme.textTheme;
    final cs = theme.colorScheme;
    return SizedBox(
      width: 64,
      height: 64,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: score / 100),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) {
          return Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: value,
                strokeWidth: 5,
                backgroundColor: cs.surfaceContainerHighest,
                valueColor: const AlwaysStoppedAnimation(AppColors.secondaryColor),
                strokeCap: StrokeCap.round,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${(value * 100).round()}',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      height: 1,
                    ),
                  ),
                  Text(
                    context.l10n.scoreLabel.toUpperCase(),
                    style: textTheme.labelSmall?.copyWith(
                      fontSize: 7,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ConfidenceNote extends StatelessWidget {
  final int score;
  final ThemeData theme;
  const _ConfidenceNote({required this.score, required this.theme});

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    final word = score >= 80
        ? context.l10n.confHigh
        : score >= 50
            ? context.l10n.confMedium
            : context.l10n.confLow;
    return Row(
      children: [
        Icon(PhosphorIconsFill.info, size: 14, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '$word confidence ($score/100) — tap Adjust to fine-tune.',
            style: textTheme.labelMedium?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _MacroRow extends StatelessWidget {
  final ThemeData theme;
  final String protein;
  final String carbs;
  final String fat;

  const _MacroRow({
    required this.theme,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    return Row(
      children: [
        Expanded(
          child: _MacroChip(
            theme: theme,
            value: protein,
            label: 'PROTEIN',
            icon: PhosphorIconsBold.barbell,
            chipColor: cs.primaryContainer,
            onChipColor: cs.onPrimaryContainer,
          ),
        ),
        SizedBox(width: AppSpacing.p8),
        Expanded(
          child: _MacroChip(
            theme: theme,
            value: carbs,
            label: 'CARBS',
            icon: PhosphorIconsFill.lightning,
            chipColor: cs.secondaryContainer,
            onChipColor: cs.onSecondaryContainer,
          ),
        ),
        SizedBox(width: AppSpacing.p8),
        Expanded(
          child: _MacroChip(
            theme: theme,
            value: fat,
            label: 'FAT',
            icon: PhosphorIconsFill.drop,
            chipColor: cs.tertiaryContainer,
            onChipColor: cs.onTertiaryContainer,
          ),
        ),
      ],
    );
  }
}

class _MacroChip extends StatelessWidget {
  final ThemeData theme;
  final String value;
  final String label;
  final IconData icon;
  final Color chipColor;
  final Color onChipColor;

  const _MacroChip({
    required this.theme,
    required this.value,
    required this.label,
    required this.icon,
    required this.chipColor,
    required this.onChipColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    final shown = value.trim().isEmpty ? '–' : value.trim();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: onChipColor.withValues(alpha: 0.10)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 11, color: onChipColor.withValues(alpha: 0.7)),
              const SizedBox(width: 4),
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w800,
                  color: onChipColor.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: RichText(
              text: TextSpan(
                text: shown,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                  height: 1,
                  color: onChipColor,
                ),
                children: [
                  TextSpan(
                    text: 'g',
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final ThemeData theme;
  final String label;
  const _SectionLabel({required this.theme, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    return Row(
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: cs.onSurfaceVariant.withValues(alpha: 0.5),
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            fontSize: 10,
          ),
        ),
        SizedBox(width: AppSpacing.p8),
        Expanded(child: Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.25))),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  final _AiItem item;
  final ThemeData theme;
  const _ItemRow({required this.item, required this.theme});

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 10),
            decoration: const BoxDecoration(
              color: AppColors.secondaryColor,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                text: item.name,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
                children: item.portion.isEmpty
                    ? null
                    : [
                        TextSpan(
                          text: '  ·  ${item.portion}',
                          style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
              ),
            ),
          ),
          if (item.calories > 0)
            Text(
              '${item.calories} kcal',
              style: textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurfaceVariant,
              ),
            ),
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
    return Column(
      children: [
        TextField(
          controller: nameController,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            labelText: context.l10n.mealName,
            prefixIcon: const Icon(PhosphorIconsRegular.forkKnife, size: 18),
          ),
        ),
        SizedBox(height: AppSpacing.p12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: calsController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => onChanged(),
                decoration: InputDecoration(labelText: context.l10n.caloriesLabel, suffixText: context.l10n.kcal),
              ),
            ),
            SizedBox(width: AppSpacing.p12),
            Expanded(
              child: TextField(
                controller: proteinController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => onChanged(),
                decoration: InputDecoration(labelText: context.l10n.macroProtein, suffixText: 'g'),
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.p12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: carbsController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => onChanged(),
                decoration: InputDecoration(labelText: context.l10n.macroCarbs, suffixText: 'g'),
              ),
            ),
            SizedBox(width: AppSpacing.p12),
            Expanded(
              child: TextField(
                controller: fatController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => onChanged(),
                decoration: InputDecoration(labelText: context.l10n.macroFat, suffixText: 'g'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ===========================================================================
// Buttons (local — gold-ink primary, neutral secondary)
// ===========================================================================

class _PrimaryButton extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final String label;
  final bool loading;
  final VoidCallback? onTap;

  const _PrimaryButton({
    required this.theme,
    required this.icon,
    required this.label,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !loading;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.secondaryColor.withValues(alpha: enabled ? 1 : 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.primaryColor),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 17, color: AppColors.primaryColor),
                  SizedBox(width: AppSpacing.p8),
                  Text(
                    label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SecondaryButton({
    required this.theme,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: cs.onSurface),
            SizedBox(width: AppSpacing.p8),
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
