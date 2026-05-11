import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/daily_log_model.dart';
import '../../models/meal_model.dart';
import '../../models/target_macros.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import 'log_meal_bottom_sheet.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  // Cap share percentage text to avoid noisy values when users are far above target.
  static const int _maxDisplayCaloriePercent = 300;
  // Local state for water and sleep — kept in sync with Firestore on init
  // and written back on every user interaction (optimistic update pattern).
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
    // Defer until the first frame so context.read is safe to call.
    WidgetsBinding.instance.addPostFrameCallback((_) => _initLog());
  }

  @override
  void dispose() {
    _clientNoteController.dispose();
    super.dispose();
  }

  /// Seeds local water/sleep state from today's existing log.
  /// Also creates the log document if this is the client's first action of the day.
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

  DateTime _normalizedDate(DateTime date) => DateTime(date.year, date.month, date.day);

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _showWeightDialog() {
    final controller = TextEditingController();
    final uid = context.read<AuthProvider>().currentUser!.uid;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Weight'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(hintText: 'Enter your weight'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null) {
                _firestoreService.updateWeight(uid, value);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
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
          content: Text(saved ? 'Note sent to coach' : 'No log exists for this day yet'),
        ),
      );
      if (saved) _clientNoteController.clear();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save note')),
      );
    } finally {
      if (mounted) setState(() => _isSavingClientNote = false);
    }
  }

  Future<void> _showEditMealDialog(Meal meal) async {
    final nameController = TextEditingController(text: meal.name);
    final caloriesController = TextEditingController(text: meal.calories.toString());
    final proteinController =
        TextEditingController(text: meal.protein.toStringAsFixed(0));
    final carbsController = TextEditingController(text: meal.carbs.toStringAsFixed(0));
    final fatController = TextEditingController(text: meal.fat.toStringAsFixed(0));
    final userId = context.read<AuthProvider>().currentUser?.uid;
    if (userId == null) return;

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit meal'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Meal name'),
              ),
              TextField(
                controller: caloriesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Calories'),
              ),
              TextField(
                controller: proteinController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Protein (g)'),
              ),
              TextField(
                controller: carbsController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Carbs (g)'),
              ),
              TextField(
                controller: fatController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Fat (g)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
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
        const SnackBar(content: Text('Please enter valid macro values')),
      );
      return;
    }

    // Persist meal edits and recompute totals in the same daily-log write.
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Meal updated')),
    );
  }

  Future<void> _deleteMeal(Meal meal) async {
    final userId = context.read<AuthProvider>().currentUser?.uid;
    if (userId == null) return;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete meal?'),
        content: Text('Remove "${meal.name}" from today\'s history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return;

    await _firestoreService.deleteMealFromTodayLog(userId, meal.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Meal deleted')),
    );
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
    final days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final dayLabel = '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: _buildAppBar(
        theme,
        textTheme,
        initial,
        firstName,
        dayLabel,
        user.currentStreak ?? 0,
        user.uid,
        user.coachId ?? '',
      ),
      body: SafeArea(
        // StreamBuilder keeps the nutrition dashboard live — any meal logged
        // (even from another device) reflects here without a manual refresh.
        child: StreamBuilder<DailyLog?>(
          stream: _firestoreService.streamLogForDateNullable(user.uid, _selectedDate),
          builder: (context, snapshot) {
            final log = snapshot.data;
            final isViewingToday = _isSameDay(_selectedDate, DateTime.now());
            final waterLiters = isViewingToday
                ? _waterLiters
                : (log?.waterLiters ?? 0).round();
            final sleepRating = isViewingToday ? _sleepRating : (log?.sleepRating ?? 0);
            return _buildBody(
              context, theme, textTheme, colorScheme,
              log?.coachNote,
              log?.totalCalories ?? 0,
              log?.totalProtein.toInt() ?? 0,
              log?.totalCarbs.toInt() ?? 0,
              log?.totalFat.toInt() ?? 0,
              targets,
              waterLiters,
              sleepRating,
              log?.weightKg,
              log?.meals ?? [],
              isViewingToday,
              user.currentStreak ?? 0,
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
      ThemeData theme,
      TextTheme textTheme,
      String initial,
      String firstName,
      String dayLabel,
      int streak,
      String clientId,
      String coachId,
      ) {
    return AppBar(
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      centerTitle: false,
      title: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.secondaryColor.withAlpha(50),
            child: Text(
              initial,
              style: textTheme.labelLarge?.copyWith(
                color: AppColors.secondaryColor,
                fontWeight: FontWeight.bold,
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
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                'Hi, $firstName',
                style: textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => _showClientNoteDialog(
            clientId: clientId,
            coachId: coachId,
            date: _selectedDate,
          ),
          icon: Icon(
            Icons.info_outline,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          tooltip: 'Note to coach',
        ),
        Container(
          margin: EdgeInsets.only(right: AppSpacing.p16),
          padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.p12, vertical: AppSpacing.p4),
          decoration: BoxDecoration(
            color: AppColors.secondaryColor.withAlpha(25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.secondaryColor.withAlpha(100)),
          ),
          child: Row(
            children: [
              Icon(Icons.local_fire_department,
                  color: AppColors.secondaryColor, size: 18),
              SizedBox(width: AppSpacing.p4),
              Text(
                '$streak',
                style: textTheme.labelLarge?.copyWith(
                  color: AppColors.secondaryColor,
                  fontWeight: FontWeight.bold,
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
        const SnackBar(content: Text('You can only leave a note for today')),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => StreamBuilder<DailyLog?>(
        stream: _firestoreService.streamLogForDateNullable(clientId, date),
        builder: (context, snapshot) {
          final existingNote = snapshot.data?.clientNote?.trim();
          if (_clientNoteController.text.isEmpty &&
              existingNote != null &&
              existingNote.isNotEmpty) {
            _clientNoteController.text = existingNote;
          }
          return AlertDialog(
            title: const Text('Note to Coach'),
            content: TextField(
              controller: _clientNoteController,
              maxLines: 4,
              minLines: 2,
              decoration: const InputDecoration(
                hintText: 'Share your check-in note for today...',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close'),
              ),
              FilledButton.icon(
                onPressed: _isSavingClientNote
                    ? null
                    : () async {
                        await _saveClientNote(
                          clientId: clientId,
                          coachId: coachId,
                          date: date,
                        );
                        if (mounted && !_isSavingClientNote) {
                          Navigator.of(ctx).pop();
                        }
                      },
                icon: _isSavingClientNote
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_outlined, size: 16),
                label: const Text('Send'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==========================================
  // MAIN BODY
  // ==========================================
  Widget _buildBody(
      BuildContext context,
      ThemeData theme,
      TextTheme textTheme,
      ColorScheme colorScheme,
      String? coachNote,
      int currentCals,
      int currentProtein,
      int currentCarbs,
      int currentFat,
      TargetMacros targets,
      int waterLiters,
      int sleepRating,
      double? weight,
      List<Meal> meals,
      bool isViewingToday,
      int streak,
      ) {
    final dailyWinText = _buildDailyWinText(
      currentCals: currentCals,
      targets: targets,
      waterLiters: waterLiters,
      sleepRating: sleepRating,
      weight: weight,
      meals: meals,
      streak: streak,
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
          SizedBox(height: AppSpacing.p20),
          if (!isViewingToday) ...[
            Text(
              'Viewing past day (read-only)',
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
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
                  const SnackBar(content: Text('Daily win copied for sharing')),
                );
              },
              icon: const Icon(Icons.ios_share),
              label: const Text('Share Daily Win'),
            ),
          ),
          SizedBox(height: AppSpacing.p12),
          // 1. Coach Note (only if there is one)
          if (coachNote != null && coachNote.isNotEmpty) ...[
            _buildCoachNote(theme, textTheme, coachNote),
            SizedBox(height: AppSpacing.p32),
          ],

          // 2. Nutrition Dashboard + inline meal history
          _buildNutritionDashboard(
            context,
            theme,
            textTheme,
            currentCals,
            currentProtein,
            currentCarbs,
            currentFat,
            targets,
            meals,
            isViewingToday,
          ),
          SizedBox(height: AppSpacing.p32),

          // 3. Daily Habits Section
          Text(
            'DAILY HABITS',
            style: textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: AppSpacing.p16),

          Row(
            children: [
              Expanded(
                child: _buildWaterCard(theme, textTheme, waterLiters, isViewingToday),
              ),
              SizedBox(width: AppSpacing.p12),
              Expanded(
                child: _buildWeightCard(context, theme, textTheme, weight, isViewingToday),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.p12),
          _buildSleepCard(theme, textTheme, sleepRating, isViewingToday),
          SizedBox(height: AppSpacing.p32),
        ],
      ),
    );
  }

  String _buildDailyWinText({
    required int currentCals,
    required TargetMacros targets,
    required int waterLiters,
    required int sleepRating,
    required double? weight,
    required List<Meal> meals,
    required int streak,
  }) {
    final date = _normalizedDate(_selectedDate);
    final caloriesPct = targets.calories <= 0
        ? 0
        : ((currentCals / targets.calories) * 100).round().clamp(0, _maxDisplayCaloriePercent);
    final weightLabel = weight == null || weight <= 0 ? '—' : '${weight.toStringAsFixed(1)}kg';
    return '🏆 Daily Win (${date.month}/${date.day})\n'
        '🔥 Streak: ${streak}d\n'
        '🍽 Meals: ${meals.length}\n'
        '⚡ Calories: $currentCals/${targets.calories} ($caloriesPct%)\n'
        '💧 Water: ${waterLiters}L\n'
        '😴 Sleep: ${sleepRating}/5\n'
        '⚖️ Weight: $weightLabel\n'
        '#valence';
  }

  // ==========================================
  // COACH NOTE BUBBLE
  // ==========================================
  Widget _buildCoachNote(
      ThemeData theme, TextTheme textTheme, String note) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.p16),
      decoration: BoxDecoration(
        color: AppColors.secondaryColor.withAlpha(15),
        borderRadius: AppTheme.defaultBorderRadius,
        border: Border.all(color: AppColors.secondaryColor.withAlpha(50)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.chat_bubble_outline,
              color: AppColors.secondaryColor, size: 20),
          SizedBox(width: AppSpacing.p12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Coach:',
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.secondaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: AppSpacing.p4),
                Text(
                  '"$note"',
                  style: textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontStyle: FontStyle.italic,
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
      BuildContext context,
      ThemeData theme,
      TextTheme textTheme,
      int currentCals,
      int currentProtein,
      int currentCarbs,
      int currentFat,
      TargetMacros targets,
      List<Meal> meals,
      bool isEditingEnabled,
      ) {
    final isCalOver = currentCals > targets.calories;
    final calOverage = currentCals - targets.calories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Calories header
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Icon(Icons.local_fire_department,
                color: AppColors.secondaryColor, size: 24),
            SizedBox(width: AppSpacing.p8),
            Text(
              '$currentCals',
              style: textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              ' / ${targets.calories} kcal',
              style: textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (isCalOver) ...[
              SizedBox(width: AppSpacing.p8),
              Text(
                '(+$calOverage)',
                style: textTheme.titleSmall?.copyWith(
                  color: AppColors.statusRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: AppSpacing.p12),

        // Calories progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (currentCals / targets.calories).clamp(0.0, 1.0),
            minHeight: 14,
            backgroundColor:
            theme.colorScheme.surfaceContainerHighest.withAlpha(100),
            valueColor:
            AlwaysStoppedAnimation<Color>(AppColors.secondaryColor),
          ),
        ),
        SizedBox(height: AppSpacing.p24),

        // Macro columns
        Row(
          children: [
            Expanded(
              child: _buildMacroColumn(theme, textTheme, 'PROTEIN',
                  Icons.fitness_center, currentProtein, targets.protein,
                  theme.colorScheme.onSurface),
            ),
            SizedBox(width: AppSpacing.p12),
            Expanded(
              child: _buildMacroColumn(theme, textTheme, 'CARBS', Icons.bolt,
                  currentCarbs, targets.carbs,
                  theme.colorScheme.onSurface.withAlpha(150)),
            ),
            SizedBox(width: AppSpacing.p12),
            Expanded(
              child: _buildMacroColumn(theme, textTheme, 'FAT',
                  Icons.water_drop, currentFat, targets.fat,
                  theme.colorScheme.onSurface.withAlpha(80)),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.p24),

        // Log Meal button with a meal-count badge when meals have been logged today
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: isEditingEnabled
                      ? () {
                    final user = context.read<AuthProvider>().currentUser!;
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
                    foregroundColor: theme.colorScheme.onSurface,
                    side: BorderSide(
                        color: theme.colorScheme.onSurfaceVariant.withAlpha(50)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(Icons.add, size: 20, color: AppColors.secondaryColor),
                  label: Text('Log Meal',
                      style: textTheme.labelLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            // Badge showing how many meals have been logged today
            if (meals.isNotEmpty) ...[
              SizedBox(width: AppSpacing.p12),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.p12, vertical: AppSpacing.p8),
                decoration: BoxDecoration(
                  color: AppColors.secondaryColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.secondaryColor.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 16, color: AppColors.secondaryColor),
                    SizedBox(width: AppSpacing.p4),
                    Text(
                      '${meals.length}',
                      style: textTheme.labelLarge?.copyWith(
                        color: AppColors.secondaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),

        // Today's meal cards — shown inline below the button once any meal is logged
        if (meals.isNotEmpty) ...[
          SizedBox(height: AppSpacing.p20),
          Text(
            "TODAY'S MEALS",
            style: textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: AppSpacing.p12),
          ...meals.map((meal) => _buildMealCard(theme, textTheme, meal, canEdit: isEditingEnabled)),
        ],
      ],
    );
  }

  Widget _buildMacroColumn(
      ThemeData theme,
      TextTheme textTheme,
      String label,
      IconData icon,
      int current,
      int target,
      Color themeColor,
      ) {
    final isOver = current > target;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: themeColor),
            SizedBox(width: AppSpacing.p4),
            Flexible(
              child: Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.p4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$current',
                style: textTheme.titleMedium?.copyWith(
                  color: isOver
                      ? AppColors.statusRed
                      : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                ' / ${target}g',
                style: textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.p8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (current / target).clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor:
            theme.colorScheme.surfaceContainerHighest.withAlpha(100),
            valueColor: AlwaysStoppedAnimation<Color>(themeColor),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // MEAL HISTORY CARD
  // ==========================================

  /// A compact card for a single logged meal showing name, calories,
  /// P/C/F macros, time, and an AI confidence dot.
  Widget _buildMealCard(
    ThemeData theme,
    TextTheme textTheme,
    Meal meal, {
    required bool canEdit,
  }) {
    // Colour-coded dot indicating how confident the AI was about this entry
    final confidenceColor = switch (meal.aiConfidence) {
      MealConfidence.high => AppColors.statusGreen,
      MealConfidence.medium => AppColors.statusYellow,
      MealConfidence.low => AppColors.statusRed,
      MealConfidence.manual => theme.colorScheme.onSurfaceVariant,
    };

    final timeLabel =
        '${meal.loggedAt.hour.toString().padLeft(2, '0')}:${meal.loggedAt.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.p8),
      padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.p16, vertical: AppSpacing.p12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(40),
        borderRadius: AppTheme.defaultBorderRadius,
        border: Border.all(
            color: theme.colorScheme.onSurfaceVariant.withAlpha(25)),
      ),
      child: Row(
        children: [
          // AI confidence dot
          Container(
            width: 8,
            height: 8,
            margin: EdgeInsets.only(right: AppSpacing.p12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: confidenceColor,
            ),
          ),
          // Meal name + macro chips
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.name,
                  style: textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: AppSpacing.p4),
                Row(
                  children: [
                    _macroChip(theme, textTheme,
                        '${meal.protein.toStringAsFixed(0)}p'),
                    SizedBox(width: AppSpacing.p4),
                    _macroChip(theme, textTheme,
                        '${meal.carbs.toStringAsFixed(0)}c'),
                    SizedBox(width: AppSpacing.p4),
                    _macroChip(theme, textTheme,
                        '${meal.fat.toStringAsFixed(0)}f'),
                  ],
                ),
              ],
            ),
          ),
          // Calories + time + edit/delete actions
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${meal.calories} kcal',
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondaryColor,
                ),
              ),
              SizedBox(height: AppSpacing.p4),
              Text(
                timeLabel,
                style: textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant),
              ),
              SizedBox(height: AppSpacing.p4),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Edit meal',
                    onPressed: canEdit ? () => _showEditMealDialog(meal) : null,
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: theme.colorScheme.secondary,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    tooltip: 'Delete meal',
                    onPressed: canEdit ? () => _deleteMeal(meal) : null,
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: AppColors.statusRed,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Tiny pill chip used inside the meal card for each macro value.
  Widget _macroChip(ThemeData theme, TextTheme textTheme, String label) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.p8, vertical: AppSpacing.p4 / 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: textTheme.labelSmall
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }

  Widget _buildCalendarStrip(ThemeData theme, TextTheme textTheme) {
    final now = DateTime.now();
    final days = List.generate(
      7,
      (index) => DateTime(now.year, now.month, now.day - (6 - index)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RECENT DAYS',
          style: textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: AppSpacing.p8),
        SizedBox(
          height: 60,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            separatorBuilder: (_, __) => SizedBox(width: AppSpacing.p4),
            itemBuilder: (context, index) {
              final day = days[index];
              final normalizedDay = _normalizedDate(day);
              final isToday =
                  day.year == now.year && day.month == now.month && day.day == now.day;
              final isSelected = _isSameDay(_selectedDate, normalizedDay);
              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  setState(() => _selectedDate = normalizedDay);
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  width: 46,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.secondaryColor.withAlpha(28)
                        : theme.colorScheme.surfaceContainerHighest.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.secondaryColor.withAlpha(130)
                          : theme.colorScheme.outlineVariant.withAlpha(65),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        ['M', 'T', 'W', 'T', 'F', 'S', 'S'][day.weekday - 1],
                        style: textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: AppSpacing.p4 / 2),
                      Text(
                        '${day.day}',
                        style: textTheme.titleSmall?.copyWith(
                          color: isSelected
                              ? AppColors.secondaryColor
                              : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isToday)
                        Container(
                          margin: EdgeInsets.only(top: AppSpacing.p4 / 2),
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: AppColors.secondaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ==========================================
  // WATER TRACKER CARD
  // ==========================================
  Widget _buildWaterCard(
      ThemeData theme,
      TextTheme textTheme,
      int waterLiters,
      bool isEnabled,
      ) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.p16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(40),
        borderRadius: AppTheme.defaultBorderRadius,
        border: Border.all(color: Colors.blueAccent.withAlpha(30)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.water_drop, color: Colors.blueAccent, size: 20),
              SizedBox(width: AppSpacing.p8),
              Text('WATER',
                  style: textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: AppSpacing.p12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$waterLiters',
                  style: textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold)),
              Text(' L',
                  style: textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
          SizedBox(height: AppSpacing.p12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildRoundButton(theme, Icons.remove, () {
                if (_waterLiters > 0) {
                  setState(() => _waterLiters--);
                  HapticFeedback.lightImpact();
                  _firestoreService.updateWater(
                    context.read<AuthProvider>().currentUser!.uid,
                    _waterLiters.toDouble(),
                  );
                }
              }, enabled: isEnabled),
              _buildRoundButton(
                theme,
                Icons.add,
                    () {
                  setState(() => _waterLiters++);
                  HapticFeedback.lightImpact();
                  _firestoreService.updateWater(
                    context.read<AuthProvider>().currentUser!.uid,
                    _waterLiters.toDouble(),
                  );
                },
                isPrimary: true,
                color: Colors.blueAccent,
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
      BuildContext context,
      ThemeData theme,
      TextTheme textTheme,
      double? weight,
      bool isEnabled,
      ) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.p16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(40),
        borderRadius: AppTheme.defaultBorderRadius,
        border: Border.all(
            color: theme.colorScheme.onSurfaceVariant.withAlpha(30)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.monitor_weight_outlined,
                  color: theme.colorScheme.onSurfaceVariant, size: 20),
              SizedBox(width: AppSpacing.p8),
              Text('WEIGHT',
                  style: textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold)),
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
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold),
              ),
              if (weight != null)
                Text(' lbs',
                    style: textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
          SizedBox(height: AppSpacing.p12),
          SizedBox(
            height: 40,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isEnabled ? () => _showWeightDialog() : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.surface,
                foregroundColor: AppColors.secondaryColor,
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                      color:
                      theme.colorScheme.onSurfaceVariant.withAlpha(50)),
                ),
              ),
              child: Text('Log Now',
                  style: textTheme.labelMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SLEEP CARD
  // ==========================================
  Widget _buildSleepCard(
      ThemeData theme,
      TextTheme textTheme,
      int sleepRating,
      bool isEnabled,
      ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.p24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(40),
        borderRadius: AppTheme.defaultBorderRadius,
        border:
        Border.all(color: Colors.deepPurpleAccent.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.nights_stay_outlined,
                  color: Colors.deepPurpleAccent, size: 20),
              SizedBox(width: AppSpacing.p8),
              Text('SLEEP QUALITY',
                  style: textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: AppSpacing.p12),
          Text(
            'How rested do you feel today?',
            style: textTheme.bodyLarge
                ?.copyWith(color: theme.colorScheme.onSurface),
          ),
          SizedBox(height: AppSpacing.p16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              final isActive = index < sleepRating;
              return GestureDetector(
                onTap: isEnabled ? () {
                  setState(() => _sleepRating = index + 1);
                  HapticFeedback.lightImpact();
                  _firestoreService.updateSleep(
                    context.read<AuthProvider>().currentUser!.uid,
                    index + 1,
                  );
                } : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.all(AppSpacing.p8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.secondaryColor.withAlpha(25)
                        : theme.colorScheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isActive
                          ? AppColors.secondaryColor
                          : theme.colorScheme.onSurfaceVariant.withAlpha(50),
                    ),
                  ),
                  child: Icon(
                    isActive
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: isActive
                        ? AppColors.secondaryColor
                        : theme.colorScheme.onSurfaceVariant,
                    size: 28,
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
      ThemeData theme,
      IconData icon,
      VoidCallback onTap, {
        bool isPrimary = false,
        Color? color,
        bool enabled = true,
      }) {
    final activeColor = color ?? theme.colorScheme.onSurface;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.all(AppSpacing.p8),
        decoration: BoxDecoration(
          color: isPrimary
              ? activeColor.withAlpha(30)
              : theme.colorScheme.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: isPrimary
                ? activeColor
                : theme.colorScheme.onSurfaceVariant.withAlpha(50),
          ),
        ),
          child: Icon(
          icon,
          color: enabled
              ? (isPrimary ? activeColor : theme.colorScheme.onSurfaceVariant)
              : theme.colorScheme.onSurfaceVariant.withAlpha(120),
          size: 20,
        ),
      ),
    );
  }
}
