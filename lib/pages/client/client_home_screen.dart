import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../models/daily_log_model.dart';
import '../../models/enums.dart';
import '../../models/habit_model.dart';
import '../../models/meal_model.dart';
import '../../models/target_macros.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import 'log_meal_bottom_sheet.dart';
import '../../l10n/l10n_ext.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  static const int _maxDailyWinCaloriePercent = 300;
  static const String _dailyWinHashtag = '#valence';
  int _waterLiters = 0;
  int _sleepRating = 0;
  bool _isSavingClientNote = false;
  final _clientNoteController = TextEditingController();
  final _firestoreService = FirestoreService();
  DateTime _selectedDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initLog());
  }

  @override
  void dispose() {
    _clientNoteController.dispose();
    super.dispose();
  }

  Future<void> _initLog() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    if ((user.coachId ?? '').trim().isEmpty) return;
    try {
      final log = await _firestoreService.getOrCreateTodayLog(
        user.uid,
        user.coachId ?? '',
      );
      if (mounted) {
        setState(() {
          _waterLiters = (log.waterLiters ?? 0).round();
          _sleepRating = log.sleepRating ?? 0;
        });
      }
    } catch (_) {}
  }

  DateTime _normalizedDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _showWeightDialog() {
    final controller = TextEditingController();
    final uid = context.read<AuthProvider>().currentUser!.uid;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.logWeightTitle),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(hintText: context.l10n.enterWeightHint),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null) {
                _firestoreService.updateWeight(uid, value);
                Navigator.pop(ctx);
              }
            },
            child: Text(context.l10n.save),
          ),
        ],
      ),
    );
  }

  Future<void> _saveClientNote({
    required String clientId,
    required String coachId,
    required DateTime date,
  }) async {
    final note = _clientNoteController.text.trim();
    if (note.isEmpty || _isSavingClientNote) return;

    setState(() => _isSavingClientNote = true);
    try {
      if (_isSameDay(date, DateTime.now())) {
        await _firestoreService.getOrCreateTodayLog(clientId, coachId);
      }
      final saved = await _firestoreService.saveClientNoteForDate(
        clientId,
        date,
        note,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              saved ? context.l10n.noteSentToCoach : context.l10n.noLogForDay),
        ),
      );
      if (saved) _clientNoteController.clear();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.noteSaveFailed)),
      );
    } finally {
      if (mounted) setState(() => _isSavingClientNote = false);
    }
  }

  Future<void> _showEditMealDialog(Meal meal) async {
    final nameController = TextEditingController(text: meal.name);
    final caloriesController =
    TextEditingController(text: meal.calories.toString());
    final proteinController =
    TextEditingController(text: meal.protein.toStringAsFixed(0));
    final carbsController =
    TextEditingController(text: meal.carbs.toStringAsFixed(0));
    final fatController =
    TextEditingController(text: meal.fat.toStringAsFixed(0));
    final userId = context.read<AuthProvider>().currentUser?.uid;
    if (userId == null) return;

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.editMeal),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: context.l10n.mealName),
              ),
              TextField(
                controller: caloriesController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: context.l10n.caloriesLabel),
              ),
              TextField(
                controller: proteinController,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: context.l10n.proteinG),
              ),
              TextField(
                controller: carbsController,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: context.l10n.carbsG),
              ),
              TextField(
                controller: fatController,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: context.l10n.fatG),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.save),
          ),
        ],
      ),
    );

    if (shouldSave != true) return;
    final calories = int.tryParse(caloriesController.text.trim());
    final protein = double.tryParse(proteinController.text.trim());
    final carbs = double.tryParse(carbsController.text.trim());
    final fat = double.tryParse(fatController.text.trim());
    if (calories == null || protein == null || carbs == null || fat == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.invalidMacros)),
      );
      return;
    }

    final editedMeal = Meal(
      id: meal.id,
      name: nameController.text.trim(),
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      imageUrl: meal.imageUrl,
      aiConfidence: meal.aiConfidence,
      loggedAt: meal.loggedAt,
    );
    await _firestoreService.updateMealInTodayLog(userId, editedMeal);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.l10n.mealUpdated)));
  }

  Future<void> _deleteMeal(Meal meal) async {
    final userId = context.read<AuthProvider>().currentUser?.uid;
    if (userId == null) return;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.deleteMealTitle),
        content: Text(context.l10n.deleteMealMsg(meal.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return;

    await _firestoreService.deleteMealFromTodayLog(userId, meal.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.l10n.mealDeleted)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final user = context.watch<AuthProvider>().currentUser!;
    final targets = user.targetMacros ?? const TargetMacros();

    final firstName = user.name.split(' ').first;
    final initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U';

    final now = _selectedDate;
    final dayLabel = MaterialLocalizations.of(context).formatMediumDate(now);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: _buildAppBar(
        theme, textTheme, initial, firstName, dayLabel,
        user.currentStreak ?? 0, user.uid, user.coachId ?? '',
      ),
      body: SafeArea(
        child: StreamBuilder<DailyLog?>(
          stream: _firestoreService.streamLogForDateNullable(
              user.uid, _selectedDate),
          builder: (context, snapshot) {
            final log = snapshot.data;
            final isViewingToday =
            _isSameDay(_selectedDate, DateTime.now());
            final waterLiters = isViewingToday
                ? _waterLiters
                : (log?.waterLiters ?? 0).round();
            final sleepRating =
            isViewingToday ? _sleepRating : (log?.sleepRating ?? 0);
            return _buildBody(
              context, theme, textTheme, colorScheme,
              log?.coachNote,
              log?.totalCalories ?? 0,
              log?.totalProtein.toInt() ?? 0,
              log?.totalCarbs.toInt() ?? 0,
              log?.totalFat.toInt() ?? 0,
              targets, waterLiters, sleepRating, log?.weightKg,
              log?.meals ?? [], isViewingToday, user.currentStreak ?? 0,
              log?.habitChecks ?? const <String, bool>{},
            );
          },
        ),
      ),
    );
  }

  // ==========================================
  // APP BAR
  // ==========================================
  PreferredSizeWidget _buildAppBar(
      ThemeData theme, TextTheme textTheme,
      String initial, String firstName, String dayLabel,
      int streak, String clientId, String coachId,
      ) {
    final cs = theme.colorScheme;
    return AppBar(
      backgroundColor: cs.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      title: Row(
        children: [
          // Gradient-ring avatar
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.secondaryColor,
                  AppColors.secondaryColor.withOpacity(0.25),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: cs.surface,
              child: Text(
                initial,
                style: textTheme.labelLarge?.copyWith(
                  color: AppColors.secondaryColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          SizedBox(width: AppSpacing.p8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dayLabel,
                style: textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant.withOpacity(0.55),
                  letterSpacing: 0.2,
                ),
              ),
              Row(
                children: [
                  Text(
                    context.l10n.hi,
                    style: textTheme.titleMedium?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(width: AppSpacing.p4,),
                  Text(
                    '$firstName',
                    style: textTheme.titleMedium?.copyWith(
                      color: cs.secondary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              _showClientNoteDialog(
                clientId: clientId, coachId: coachId, date: _selectedDate,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.secondaryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.secondaryColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(PhosphorIconsFill.notePencil,
                      color: AppColors.secondaryColor, size: 15),
                  const SizedBox(width: 5),
                  Text(
                    context.l10n.noteButton,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.secondaryColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Streak badge
        Container(
          margin: EdgeInsets.only(right: AppSpacing.p16),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.secondaryColor.withOpacity(0.18),
                AppColors.secondaryColor.withOpacity(0.07),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.secondaryColor.withOpacity(0.32),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondaryColor.withOpacity(0.14),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.local_fire_department_rounded,
                  color: AppColors.secondaryColor, size: 16),
              SizedBox(width: AppSpacing.p4),
              Text(
                '$streak',
                style: textTheme.labelLarge?.copyWith(
                  color: AppColors.secondaryColor,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showClientNoteDialog({
    required String clientId,
    required String coachId,
    required DateTime date,
  }) async {
    if (!_isSameDay(date, DateTime.now())) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.noteOnlyToday)),
      );
      return;
    }
    // Prefill with today's existing note (one-time) before opening the sheet.
    final existing = (await _firestoreService.streamLogForDateNullable(clientId, date).first)
        ?.clientNote
        ?.trim();
    if (existing != null && existing.isNotEmpty) {
      _clientNoteController.text = existing;
    }
    if (!mounted) return;

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final hasText = _clientNoteController.text.trim().isNotEmpty;
          return Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
            ),
            padding: EdgeInsets.only(
              left: AppSpacing.p20,
              right: AppSpacing.p20,
              top: AppSpacing.p12,
              bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.p20,
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  SizedBox(height: AppSpacing.p16),
                  Text(
                    context.l10n.noteToCoach.toUpperCase(),
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.secondaryColor,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.todaysCheckIn,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  SizedBox(height: AppSpacing.p8),
                  Text(
                    context.l10n.noteToCoachBody,
                    style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.45),
                  ),
                  SizedBox(height: AppSpacing.p16),
                  TextField(
                    controller: _clientNoteController,
                    maxLines: 5,
                    minLines: 3,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => setSheet(() {}),
                    decoration: InputDecoration(
                      hintText: context.l10n.noteToCoachHint,
                      filled: true,
                      fillColor: cs.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.secondaryColor, width: 1.5),
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.p16),
                  GestureDetector(
                    onTap: (!hasText || _isSavingClientNote)
                        ? null
                        : () async {
                            HapticFeedback.lightImpact();
                            final navigator = Navigator.of(ctx);
                            setSheet(() {});
                            await _saveClientNote(
                              clientId: clientId, coachId: coachId, date: date,
                            );
                            if (mounted && !_isSavingClientNote) {
                              navigator.pop();
                            }
                          },
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 150),
                      opacity: hasText ? 1 : 0.5,
                      child: Container(
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.secondaryColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: _isSavingClientNote
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.2, color: AppColors.primaryColor),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(PhosphorIconsFill.paperPlaneTilt,
                                      size: 16, color: AppColors.primaryColor),
                                  SizedBox(width: AppSpacing.p8),
                                  Text(
                                    context.l10n.sendToCoach,
                                    style: textTheme.titleSmall?.copyWith(
                                      color: AppColors.primaryColor,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // MAIN BODY
  // ==========================================
  Widget _buildBody(
      BuildContext context, ThemeData theme, TextTheme textTheme,
      ColorScheme colorScheme, String? coachNote,
      int currentCals, int currentProtein, int currentCarbs, int currentFat,
      TargetMacros targets, int waterLiters, int sleepRating,
      double? weight, List<Meal> meals, bool isViewingToday, int streak,
      Map<String, bool> habitChecks,
      ) {
    final dailyWinText = _buildDailyWinText(
      currentCals: currentCals, targets: targets, waterLiters: waterLiters,
      sleepRating: sleepRating, weight: weight, meals: meals, streak: streak,
    );

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.p16,
        vertical: AppSpacing.p12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCalendarStrip(theme, textTheme),
          SizedBox(height: AppSpacing.p16),

          if (!isViewingToday) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer.withOpacity(0.45),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colorScheme.secondary.withOpacity(0.15),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history_rounded, size: 14,
                      color: colorScheme.onSecondaryContainer),
                  SizedBox(width: AppSpacing.p8),
                  Text(
                    context.l10n.viewingPastDay,
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.p12),
          ],

          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: dailyWinText));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.l10n.dailyWinCopied)),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.secondaryColor,
                side: BorderSide(
                  color: AppColors.secondaryColor.withOpacity(0.3),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 11),
              ),
              icon: const Icon(Icons.ios_share_rounded, size: 16),
              label: Text(
                context.l10n.shareDailyWin,
                style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.1),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.p16),

          if (coachNote != null && coachNote.isNotEmpty) ...[
            _buildCoachNote(theme, textTheme, coachNote),
            SizedBox(height: AppSpacing.p32),
          ],

          _buildNutritionDashboard(
            context, theme, textTheme,
            currentCals, currentProtein, currentCarbs, currentFat,
            targets, meals, isViewingToday,
          ),
          SizedBox(height: AppSpacing.p32),

          _buildSectionLabel(theme, textTheme, context.l10n.dailyHabits.toUpperCase()),
          SizedBox(height: AppSpacing.p16),

          Row(
            children: [
              Expanded(child: _buildWaterCard(
                  theme, textTheme, waterLiters, isViewingToday)),
              SizedBox(width: AppSpacing.p12),
              Expanded(child: _buildWeightCard(
                  context, theme, textTheme, weight, isViewingToday)),
            ],
          ),
          SizedBox(height: AppSpacing.p12),
          _buildSleepCard(theme, textTheme, sleepRating, isViewingToday),
          _buildCustomHabits(
              context, theme, textTheme, colorScheme, habitChecks, isViewingToday),
          SizedBox(height: AppSpacing.p32),
        ],
      ),
    );
  }

  // ==========================================
  // CUSTOM HABITS (coach-defined, additive — supplements water/sleep/weight)
  // ==========================================
  IconData _habitIcon(String key) {
    switch (key) {
      case 'footprints':
        return PhosphorIconsFill.footprints;
      case 'drop':
        return PhosphorIconsFill.drop;
      case 'barbell':
        return PhosphorIconsFill.barbell;
      case 'pill':
        return PhosphorIconsFill.pill;
      case 'forkKnife':
        return PhosphorIconsFill.forkKnife;
      case 'moon':
        return PhosphorIconsFill.moon;
      case 'heartbeat':
        return PhosphorIconsFill.heartbeat;
      case 'sun':
        return PhosphorIconsFill.sun;
      case 'leaf':
        return PhosphorIconsFill.leaf;
      case 'prohibit':
        return PhosphorIconsFill.prohibit;
      default:
        return PhosphorIconsFill.checkCircle;
    }
  }

  void _toggleHabit(String habitId, bool currentlyDone) {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    HapticFeedback.lightImpact();
    _firestoreService.toggleHabitCompletion(
        user.uid, user.coachId ?? '', habitId, !currentlyDone);
  }

  Widget _buildCustomHabits(
      BuildContext context, ThemeData theme, TextTheme textTheme,
      ColorScheme cs, Map<String, bool> checks, bool isEnabled,
      ) {
    final habits =
        context.read<AuthProvider>().currentUser?.customHabits ?? const <HabitDefinition>[];
    if (habits.isEmpty) return const SizedBox.shrink();
    final doneCount = habits.where((h) => checks[h.id] == true).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: AppSpacing.p32),
        Row(
          children: [
            Expanded(child: _buildSectionLabel(theme, textTheme, context.l10n.yourHabits.toUpperCase())),
            SizedBox(width: AppSpacing.p12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.secondaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.secondaryColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                '$doneCount/${habits.length}',
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.secondaryColor,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.p16),
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.28)),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondaryColor.withValues(alpha: 0.05),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              for (var i = 0; i < habits.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: 60,
                    color: cs.outlineVariant.withValues(alpha: 0.2),
                  ),
                _buildHabitRow(theme, textTheme, cs, habits[i],
                    checks[habits[i].id] == true, isEnabled),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHabitRow(
      ThemeData theme, TextTheme textTheme, ColorScheme cs,
      HabitDefinition habit, bool done, bool isEnabled,
      ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isEnabled ? () => _toggleHabit(habit.id, done) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: done
                    ? AppColors.secondaryColor.withValues(alpha: 0.16)
                    : cs.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_habitIcon(habit.icon),
                  size: 17, color: done ? AppColors.secondaryColor : cs.onSurfaceVariant),
            ),
            SizedBox(width: AppSpacing.p12),
            Expanded(
              child: Text(
                habit.name,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: done ? cs.onSurfaceVariant : cs.onSurface,
                  decoration: done ? TextDecoration.lineThrough : null,
                  decorationColor: cs.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: done ? AppColors.secondaryColor : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: done
                      ? AppColors.secondaryColor
                      : cs.outlineVariant.withValues(alpha: 0.6),
                  width: 2,
                ),
              ),
              child: done
                  ? const Icon(PhosphorIconsBold.check, size: 15, color: AppColors.primaryColor)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(ThemeData theme, TextTheme textTheme, String label) {
    final cs = theme.colorScheme;
    return Row(
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: cs.onSurfaceVariant.withOpacity(0.45),
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            fontSize: 10,
          ),
        ),
        SizedBox(width: AppSpacing.p12),
        Expanded(
          child: Divider(
            color: cs.outlineVariant.withOpacity(0.28),
            thickness: 1,
            height: 1,
          ),
        ),
      ],
    );
  }

  String _buildDailyWinText({
    required int currentCals, required TargetMacros targets,
    required int waterLiters, required int sleepRating,
    required double? weight, required List<Meal> meals, required int streak,
  }) {
    final date = _normalizedDate(_selectedDate);
    final caloriesPct = targets.calories <= 0
        ? 0
        : ((currentCals / targets.calories) * 100)
        .round()
        .clamp(0, _maxDailyWinCaloriePercent);
    final weightLabel = weight == null || weight <= 0
        ? '—'
        : '${weight.toStringAsFixed(1)}kg';
    return '🏆 Daily Win (${date.month}/${date.day})\n'
        '🔥 Streak: ${streak}d\n'
        '🍽 Meals: ${meals.length}\n'
        '⚡ Calories: $currentCals/${targets.calories} ($caloriesPct%)\n'
        '💧 Water: ${waterLiters}L\n'
        '😴 Sleep: ${sleepRating}/5\n'
        '⚖️ Weight: $weightLabel\n'
        '$_dailyWinHashtag';
  }

  // ==========================================
  // COACH NOTE
  // ==========================================
  Widget _buildCoachNote(ThemeData theme, TextTheme textTheme, String note) {
    final cs = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.p16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondaryColor.withOpacity(0.10),
            AppColors.secondaryColor.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.secondaryColor.withOpacity(0.20),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondaryColor.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.secondaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.chat_bubble_rounded,
                color: AppColors.secondaryColor, size: 16),
          ),
          SizedBox(width: AppSpacing.p12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.badgeCoach,
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.secondaryColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                    fontSize: 9.5,
                  ),
                ),
                SizedBox(height: AppSpacing.p4),
                Text(
                  '"$note"',
                  style: textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withOpacity(0.8),
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // NUTRITION DASHBOARD
  // ==========================================
  Widget _buildNutritionDashboard(
      BuildContext context, ThemeData theme, TextTheme textTheme,
      int currentCals, int currentProtein, int currentCarbs, int currentFat,
      TargetMacros targets, List<Meal> meals, bool isEditingEnabled,
      ) {
    final isCalOver = currentCals > targets.calories;
    final calOverage = currentCals - targets.calories;
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── CALORIES ─────────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            PhosphorIcon(
              PhosphorIcons.fire(PhosphorIconsStyle.fill),
              color: isCalOver ? cs.error : AppColors.secondaryColor,
              size: 24,
            ),
            SizedBox(width: AppSpacing.p8),
            Text(
              '$currentCals',
              style: textTheme.displaySmall?.copyWith(
                color: isCalOver ? cs.error : cs.secondary,
                fontWeight: FontWeight.w900,
                letterSpacing: -2,
                height: 1,
              ),
            ),
            Text(
              ' / ${targets.calories} kcal',
              style: textTheme.titleMedium?.copyWith(
                color: cs.onSurfaceVariant.withOpacity(0.55),
                fontWeight: FontWeight.w400,
              ),
            ),
            if (isCalOver) ...[
              SizedBox(width: AppSpacing.p8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: cs.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+$calOverage',
                  style: textTheme.labelSmall?.copyWith(
                    color: cs.onErrorContainer,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: AppSpacing.p16),

        // ── PROGRESS BAR ──────────────────────────────────────────────────────
        LayoutBuilder(builder: (context, constraints) {
          final fillFraction =
          (currentCals / targets.calories).clamp(0.0, 1.0);
          final fillWidth = constraints.maxWidth * fillFraction;
          final fillColor =
          fillFraction >= 1.0 ? cs.error : AppColors.secondaryColor;

          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 12,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    color: cs.surfaceContainerHighest.withOpacity(0.55),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 550),
                    curve: Curves.easeOutCubic,
                    width: fillWidth,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          fillColor.withOpacity(0.65),
                          fillColor,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        SizedBox(height: AppSpacing.p24),

        // ── MACRO COLUMNS ─────────────────────────────────────────────────────
        Row(
          children: [
            Expanded(child: _buildMacroColumn(theme, textTheme,
              label: context.l10n.macroProtein.toUpperCase(),
              icon: PhosphorIcons.barbell(PhosphorIconsStyle.bold),
              current: currentProtein, target: targets.protein,
              chipColor: cs.primaryContainer, onChipColor: cs.onPrimaryContainer,
            )),
            SizedBox(width: AppSpacing.p12),
            Expanded(child: _buildMacroColumn(theme, textTheme,
              label: context.l10n.macroCarbs.toUpperCase(),
              icon: PhosphorIcons.lightning(PhosphorIconsStyle.fill),
              current: currentCarbs, target: targets.carbs,
              chipColor: cs.secondaryContainer, onChipColor: cs.onSecondaryContainer,
            )),
            SizedBox(width: AppSpacing.p12),
            Expanded(child: _buildMacroColumn(theme, textTheme,
              label: context.l10n.macroFat.toUpperCase(),
              icon: PhosphorIcons.drop(PhosphorIconsStyle.fill),
              current: currentFat, target: targets.fat,
              chipColor: cs.tertiaryContainer, onChipColor: cs.onTertiaryContainer,
            )),
          ],
        ),
        SizedBox(height: AppSpacing.p24),

        // ── LOG MEAL BUTTON ───────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: isEditingEnabled
                      ? () {
                    final user =
                    context.read<AuthProvider>().currentUser!;
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => LogMealBottomSheet(
                        clientId: user.uid,
                        coachId: user.coachId ?? '',
                      ),
                    );
                  }
                      : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cs.onSurface,
                    backgroundColor: AppColors.secondaryColor.withOpacity(0.04),
                    side: BorderSide(
                      color: AppColors.secondaryColor.withOpacity(0.28),
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryColor.withOpacity(0.14),
                      shape: BoxShape.circle,
                    ),
                    child: PhosphorIcon(
                      PhosphorIcons.plus(PhosphorIconsStyle.bold),
                      size: 14,
                      color: AppColors.secondaryColor,
                    ),
                  ),
                  label: Text(
                    context.l10n.logMeal,
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700, letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
            if (meals.isNotEmpty) ...[
              SizedBox(width: AppSpacing.p12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cs.secondary.withOpacity(0.18)),
                ),
                child: Row(
                  children: [
                    PhosphorIcon(
                      PhosphorIcons.notepad(PhosphorIconsStyle.duotone),
                      size: 15, color: cs.onSecondaryContainer,
                    ),
                    SizedBox(width: AppSpacing.p4),
                    Text(
                      '${meals.length}',
                      style: textTheme.labelLarge?.copyWith(
                        color: cs.onSecondaryContainer,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),

        // ── MEALS LIST ────────────────────────────────────────────────────────
        if (meals.isNotEmpty) ...[
          SizedBox(height: AppSpacing.p24),
          Row(
            children: [
              Expanded(child: Divider(
                color: cs.outlineVariant.withOpacity(0.28),
                thickness: 1, height: 1,
              )),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.p12),
                child: Text(
                  context.l10n.todaysMeals.toUpperCase(),
                  style: textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant.withOpacity(0.38),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                    fontSize: 9.5,
                  ),
                ),
              ),
              Expanded(child: Divider(
                color: cs.outlineVariant.withOpacity(0.28),
                thickness: 1, height: 1,
              )),
            ],
          ),
          SizedBox(height: AppSpacing.p12),
          ...meals.map((meal) => _buildMealCard(
            theme, textTheme, meal, canEdit: isEditingEnabled,
          )),
        ],
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  //  MACRO COLUMN
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildMacroColumn(
      ThemeData theme, TextTheme textTheme, {
        required String label, required IconData icon,
        required int current, required int target,
        required Color chipColor, required Color onChipColor,
      }) {
    final cs = theme.colorScheme;
    final isOver = current > target;
    final progress = (current / target).clamp(0.0, 1.0);
    final valueColor = isOver ? cs.error : onChipColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.22),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: onChipColor.withOpacity(0.10), width: 1),
        boxShadow: [
          BoxShadow(
            color: chipColor.withOpacity(0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PhosphorIcon(icon, size: 12,
                  color: onChipColor.withOpacity(0.7)),
              SizedBox(width: AppSpacing.p4),
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: onChipColor.withOpacity(0.6),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    fontSize: 9,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.p8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$current',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: valueColor,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                    height: 1,
                  ),
                ),
                Text(
                  ' /${target}g',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant.withOpacity(0.4),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.p12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LayoutBuilder(builder: (context, constraints) {
              final fillWidth = constraints.maxWidth * progress;
              final barColor = isOver ? cs.error : onChipColor;
              return SizedBox(
                height: 5,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      color: chipColor.withOpacity(0.4),
                    ),
                    Container(
                      width: fillWidth,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            barColor.withOpacity(0.55),
                            barColor,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MEAL CARD
  // ==========================================
  Widget _buildMealCard(
      ThemeData theme, TextTheme textTheme, Meal meal, {required bool canEdit}
      ) {
    final cs = theme.colorScheme;
    final timeLabel =
        '${meal.loggedAt.hour.toString().padLeft(2, '0')}:${meal.loggedAt.minute.toString().padLeft(2, '0')}';

    final confidenceColor = switch (meal.aiConfidence) {
      MealConfidence.high   => cs.tertiary,
      MealConfidence.medium => cs.secondary,
      MealConfidence.low    => cs.error,
      MealConfidence.manual => cs.onSurfaceVariant,
    };
    final confidenceLabel = switch (meal.aiConfidence) {
      MealConfidence.high => context.l10n.confHigh,
      MealConfidence.medium => context.l10n.confMedium,
      MealConfidence.low => context.l10n.confLow,
      MealConfidence.manual => context.l10n.confManual,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: cs.surfaceContainerLow,
        border: Border.all(
          color: cs.outlineVariant.withOpacity(0.28), width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: cs.shadow.withOpacity(0.07),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Confidence strip — gradient + glow
                Container(
                  width: 3.5,
                  height: 44,
                  margin: const EdgeInsets.only(right: 14, top: 2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        confidenceColor,
                        confidenceColor.withOpacity(0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: confidenceColor.withOpacity(0.40),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.name,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: cs.onSurface,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          _confidencePill(cs, confidenceColor, confidenceLabel),
                          const SizedBox(width: 8),
                          Icon(PhosphorIconsRegular.clock, size: 11,
                              color: cs.onSurfaceVariant.withOpacity(0.38)),
                          const SizedBox(width: 3),
                          Text(
                            timeLabel,
                            style: textTheme.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant.withOpacity(0.38),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${meal.calories}',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: cs.primary,
                        letterSpacing: -1,
                        height: 1,
                      ),
                    ),
                    Text(
                      context.l10n.kcal,
                      style: textTheme.labelSmall?.copyWith(
                        color: cs.primary.withOpacity(0.38),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Divider(color: cs.outlineVariant.withOpacity(0.25), height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                _macroChip(cs, textTheme,
                  icon: PhosphorIconsFill.lightning,
                  label: '${meal.protein.toStringAsFixed(0)}g',
                  sublabel: context.l10n.macroProtein,
                  color: cs.primaryContainer,
                  onColor: cs.onPrimaryContainer,
                ),
                const SizedBox(width: 6),
                _macroChip(cs, textTheme,
                  icon: PhosphorIconsFill.bread,
                  label: '${meal.carbs.toStringAsFixed(0)}g',
                  sublabel: context.l10n.macroCarbs,
                  color: cs.secondaryContainer,
                  onColor: cs.onSecondaryContainer,
                ),
                const SizedBox(width: 6),
                _macroChip(cs, textTheme,
                  icon: PhosphorIconsFill.drop,
                  label: '${meal.fat.toStringAsFixed(0)}g',
                  sublabel: context.l10n.macroFat,
                  color: cs.tertiaryContainer,
                  onColor: cs.onTertiaryContainer,
                ),
                const Spacer(),
                _actionButton(
                  icon: PhosphorIconsRegular.pencilSimple,
                  color: cs.secondary, onColor: cs.onSecondary,
                  containerColor: cs.secondaryContainer,
                  enabled: canEdit, tooltip: context.l10n.editMeal,
                  onTap: canEdit ? () => _showEditMealDialog(meal) : null,
                ),
                const SizedBox(width: 6),
                _actionButton(
                  icon: PhosphorIconsRegular.trash,
                  color: cs.error, onColor: cs.onError,
                  containerColor: cs.errorContainer,
                  enabled: canEdit, tooltip: context.l10n.deleteMeal,
                  onTap: canEdit ? () => _deleteMeal(meal) : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _confidencePill(ColorScheme cs, Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.20), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5, height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.5), blurRadius: 4),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700,
              color: color, letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _macroChip(
      ColorScheme cs, TextTheme textTheme, {
        required IconData icon, required String label, required String sublabel,
        required Color color, required Color onColor,
      }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: onColor.withOpacity(0.75)),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w800,
                  color: onColor, height: 1.1, letterSpacing: -0.2,
                ),
              ),
              Text(
                sublabel,
                style: TextStyle(
                  fontSize: 9, fontWeight: FontWeight.w500,
                  color: onColor.withOpacity(0.55), height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon, required Color color, required Color onColor,
    required Color containerColor, required bool enabled,
    required String tooltip, required VoidCallback? onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: enabled ? 1.0 : 0.25,
          child: Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: containerColor.withOpacity(0.7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.14), width: 0.8),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // CALENDAR STRIP
  // ==========================================
  Widget _buildCalendarStrip(ThemeData theme, TextTheme textTheme) {
    final now = DateTime.now();
    final days = List.generate(
      7,
      (index) => DateTime(now.year, now.month, now.day - (6 - index)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(theme, textTheme, context.l10n.thisWeek.toUpperCase()),
        SizedBox(height: AppSpacing.p8),
        // Full-width row of 7 equal cells — today is always the last and always
        // fully visible, with no horizontal-scroll clipping.
        Row(
          children: [
            for (final day in days)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _calendarDayCell(theme, textTheme, day, now),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _calendarDayCell(ThemeData theme, TextTheme textTheme, DateTime day, DateTime now) {
    final cs = theme.colorScheme;
    final normalizedDay = _normalizedDate(day);
    final isToday = day.year == now.year && day.month == now.month && day.day == now.day;
    final isSelected = _isSameDay(_selectedDate, normalizedDay);
    return GestureDetector(
      onTap: () {
        setState(() => _selectedDate = normalizedDay);
        HapticFeedback.selectionClick();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        height: 60,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.secondaryColor.withValues(alpha: 0.14)
              : cs.surfaceContainerHighest.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.secondaryColor.withValues(alpha: 0.5)
                : cs.outlineVariant.withValues(alpha: 0.22),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              ['M', 'T', 'W', 'T', 'F', 'S', 'S'][day.weekday - 1],
              style: textTheme.labelSmall?.copyWith(
                color: isSelected
                    ? AppColors.secondaryColor.withValues(alpha: 0.8)
                    : cs.onSurfaceVariant.withValues(alpha: 0.5),
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${day.day}',
              style: textTheme.titleSmall?.copyWith(
                color: isSelected ? AppColors.secondaryColor : cs.onSurface.withValues(alpha: 0.75),
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: isToday ? 5 : 0,
              height: isToday ? 5 : 0,
              decoration: const BoxDecoration(
                color: AppColors.secondaryColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // WATER CARD — cs.primary as water accent
  // ==========================================
  Widget _buildWaterCard(
      ThemeData theme, TextTheme textTheme,
      int waterLiters, bool isEnabled,
      ) {
    final cs = theme.colorScheme;
    return Container(
      padding: EdgeInsets.all(AppSpacing.p16),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(0.22),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.primaryContainer.withOpacity(0.20), width: 1),
        boxShadow: [
          BoxShadow(
            color: cs.primaryContainer.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.water_drop_rounded, color: cs.onPrimaryContainer, size: 16),
              SizedBox(width: AppSpacing.p8),
              Text(
                context.l10n.waterLabel.toUpperCase(),
                style: textTheme.labelSmall?.copyWith(
                  color: cs.onPrimaryContainer.withOpacity(0.75),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.3,
                  fontSize: 9.5,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.p12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$waterLiters',
                style: textTheme.headlineMedium?.copyWith(
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              Text(
                ' L',
                style: textTheme.bodyLarge?.copyWith(
                  color: cs.onPrimaryContainer.withOpacity(0.4),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.p12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildRoundButton(
                theme, Icons.remove_rounded,
                    () {
                  if (_waterLiters > 0) {
                    setState(() => _waterLiters--);
                    HapticFeedback.lightImpact();
                    _firestoreService.updateWater(
                      context.read<AuthProvider>().currentUser!.uid,
                      _waterLiters.toDouble(),
                    );
                  }
                },
                enabled: isEnabled,
                color: cs.onPrimaryContainer.withOpacity(0.1),
              ),
              _buildRoundButton(
                theme, Icons.add_rounded,
                    () {
                  setState(() => _waterLiters++);
                  HapticFeedback.lightImpact();
                  _firestoreService.updateWater(
                    context.read<AuthProvider>().currentUser!.uid,
                    _waterLiters.toDouble(),
                  );
                },
                isPrimary: true,
                color: cs.onPrimaryContainer,
                enabled: isEnabled,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // WEIGHT CARD
  // ==========================================
  Widget _buildWeightCard(
      BuildContext context, ThemeData theme, TextTheme textTheme,
      double? weight, bool isEnabled,
      ) {
    final cs = theme.colorScheme;
    return Container(
      padding: EdgeInsets.all(AppSpacing.p16),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withOpacity(0.22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.22), width: 1),
        boxShadow: [
          BoxShadow(
            color: cs.secondaryContainer.withOpacity(0.18),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.monitor_weight_outlined,
                  color: cs.onSecondaryContainer, size: 16),
              SizedBox(width: AppSpacing.p8),
              Text(
                context.l10n.weightLabel.toUpperCase(),
                style: textTheme.labelSmall?.copyWith(
                  color: cs.onSecondaryContainer.withOpacity(0.75),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.3,
                  fontSize: 9.5,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.p12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                weight != null ? weight.toStringAsFixed(1) : '--',
                style: textTheme.headlineMedium?.copyWith(
                  color: cs.onSecondaryContainer,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              if (weight != null)
                Text(
                  ' KG',
                  style: textTheme.bodyLarge?.copyWith(
                    color: cs.onSecondaryContainer.withOpacity(0.4),
                  ),
                ),
            ],
          ),
          SizedBox(height: AppSpacing.p12),
      GestureDetector(
        onTap: isEnabled ? () => _showWeightDialog() : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isEnabled ? 1.0 : 0.3,
          child: Container(
            height: 40,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: cs.secondaryContainer.withOpacity(0.85),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cs.onSecondaryContainer.withOpacity(0.35), width: 0.5,),

            ),
            child: Center(
              child: Text(
                context.l10n.logNow,
                style: textTheme.labelMedium?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w700, letterSpacing: 0.1,
                ),
              ),
            ),
          ),
        ),
      ),
        ],
      ),
    );
  }

  // ==========================================
  // SLEEP CARD — cs.tertiary as sleep accent
  // ==========================================
  Widget _buildSleepCard(
      ThemeData theme, TextTheme textTheme,
      int sleepRating, bool isEnabled,
      ) {
    final cs = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.p24),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer.withOpacity(0.22),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.tertiaryContainer.withOpacity(0.10), width: 1),
        boxShadow: [
          BoxShadow(
            color: cs.tertiaryContainer.withOpacity(0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.nights_stay_rounded, color: cs.onTertiaryContainer.withOpacity(0.7), size: 18),
              SizedBox(width: AppSpacing.p8),
              Text(
                context.l10n.sleepQuality.toUpperCase(),
                style: textTheme.labelSmall?.copyWith(
                  color: cs.onTertiaryContainer.withOpacity(0.6),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.3,
                  fontSize: 9.5,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.p12),
          Text(
            context.l10n.howRested,
            style: textTheme.bodyMedium?.copyWith(
              color: cs.onSurface.withOpacity(0.5),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppSpacing.p16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              final isActive = index < sleepRating;
              return GestureDetector(
                onTap: isEnabled
                    ? () {
                  setState(() => _sleepRating = index + 1);
                  HapticFeedback.lightImpact();
                  _firestoreService.updateSleep(
                    context.read<AuthProvider>().currentUser!.uid,
                    index + 1,
                  );
                }
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutBack,
                  padding: EdgeInsets.all(isActive ? 9 : 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? cs.onTertiaryContainer.withOpacity(0.2)
                        : cs.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isActive
                          ? cs.tertiary.withOpacity(0.45)
                          : cs.outlineVariant.withOpacity(0.25),
                      width: isActive ? 1.5 : 1,
                    ),
                    boxShadow: isActive
                        ? [
                      BoxShadow(
                        color: cs.tertiary.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                        : null,
                  ),
                  child: Icon(
                    isActive ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: isActive
                        ? cs.onTertiaryContainer
                        : cs.onTertiaryContainer.withOpacity(0.2),
                    size: isActive ? 28 : 25,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundButton(
      ThemeData theme, IconData icon, VoidCallback onTap, {
        bool isPrimary = false, Color? color, bool enabled = true,
      }) {
    final cs = theme.colorScheme;
    final activeColor = color ?? cs.onPrimaryContainer;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1 : 0.3,
        child: Container(
          padding: EdgeInsets.all(AppSpacing.p8),
          decoration: BoxDecoration(
            color: isPrimary
                ? activeColor.withOpacity(0.22)
                : activeColor.withOpacity(0.08),
            shape: BoxShape.circle,
            border: Border.all(
              color: activeColor.withOpacity(isPrimary ? 0 : 0.15),
              width: 1,
            ),
            boxShadow: isPrimary
                ? [
              BoxShadow(
                color: activeColor.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ]
                : null,
          ),
          child: Icon(
            icon,
            color: isPrimary
                ? activeColor
                : cs.onSurfaceVariant.withOpacity(0.55),
            size: 20,
          ),
        ),
      ),
    );
  }
}