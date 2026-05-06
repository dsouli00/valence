import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/daily_log_model.dart';
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
  // Local state for water and sleep — kept in sync with Firestore on init
  // and written back on every user interaction (optimistic update pattern).
  int _waterLiters = 0;
  int _sleepRating = 0;
  final _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    // Defer until the first frame so context.read is safe to call.
    WidgetsBinding.instance.addPostFrameCallback((_) => _initLog());
  }

  /// Seeds local water/sleep state from today's existing log.
  /// Also creates the log document if this is the client's first action of the day.
  Future<void> _initLog() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final user = context.watch<AuthProvider>().currentUser!;
    final targets = user.targetMacros ?? const TargetMacros();

    final firstName = user.name.split(' ').first;
    final initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U';

    final now = DateTime.now();
    final days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final dayLabel = '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: _buildAppBar(
        theme, textTheme, initial, firstName, dayLabel, user.currentStreak ?? 0,
      ),
      body: SafeArea(
        // StreamBuilder keeps the nutrition dashboard live — any meal logged
        // (even from another device) reflects here without a manual refresh.
        child: StreamBuilder<DailyLog>(
          stream: _firestoreService.streamTodayLog(user.uid),
          builder: (context, snapshot) {
            final log = snapshot.data;
            return _buildBody(
              context, theme, textTheme, colorScheme,
              log?.coachNote,
              log?.totalCalories ?? 0,
              log?.totalProtein.toInt() ?? 0,
              log?.totalCarbs.toInt() ?? 0,
              log?.totalFat.toInt() ?? 0,
              targets,
              _waterLiters,
              _sleepRating,
              log?.weightKg,
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
      ) {
    return AppBar(
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      centerTitle: false,
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.secondaryColor.withAlpha(50),
            child: Text(
              initial,
              style: textTheme.titleMedium?.copyWith(
                color: AppColors.secondaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: AppSpacing.p12),
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
                'Good Morning, $firstName',
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
      ) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.p16,
        vertical: AppSpacing.p12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Coach Note (only if there is one)
          if (coachNote != null && coachNote.isNotEmpty) ...[
            _buildCoachNote(theme, textTheme, coachNote),
            SizedBox(height: AppSpacing.p32),
          ],

          // 2. Nutrition Dashboard
          _buildNutritionDashboard(context, theme, textTheme, currentCals,
              currentProtein, currentCarbs, currentFat, targets),
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
                child: _buildWaterCard(theme, textTheme, waterLiters),
              ),
              SizedBox(width: AppSpacing.p12),
              Expanded(
                child: _buildWeightCard(context, theme, textTheme, weight),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.p12),
          _buildSleepCard(theme, textTheme, sleepRating),
          SizedBox(height: AppSpacing.p32),
        ],
      ),
    );
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

        // Log Meal button
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () {
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
            },
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
  // WATER TRACKER CARD
  // ==========================================
  Widget _buildWaterCard(
      ThemeData theme,
      TextTheme textTheme,
      int waterLiters,
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
              }),
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
              onPressed: () => _showWeightDialog(),
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
                onTap: () {
                  setState(() => _sleepRating = index + 1);
                  HapticFeedback.lightImpact();
                  _firestoreService.updateSleep(
                    context.read<AuthProvider>().currentUser!.uid,
                    index + 1,
                  );
                },
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
      }) {
    final activeColor = color ?? theme.colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
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
          color: isPrimary ? activeColor : theme.colorScheme.onSurfaceVariant,
          size: 20,
        ),
      ),
    );
  }
}

