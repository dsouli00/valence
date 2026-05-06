import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  // ── MOCK STATE ─────────────────────────────────────────────────
  // Using local state to make the buttons visually interactive
  int _waterLiters = 2;
  int _sleepRating = 3;
  final double _weight = 168.4;

  final _mockUser = _MockUser(
    name: 'Sarah Johnson',
    currentStreak: 12,
    targetMacros: _MockMacros(calories: 2000, protein: 140, carbs: 200, fat: 65),
  );

  final _mockLog = _MockLog(
    coachNote: "You crushed the workouts this week! Let's focus on hitting that protein goal today.",
    consumedMacros: _MockMacros(calories: 1450, protein: 110, carbs: 150, fat: 45),
  );

  void _showMockDialog(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final targets = _mockUser.targetMacros;
    final log = _mockLog;

    // First name only for the greeting
    final firstName = _mockUser.name.split(' ').first;
    final initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U';

    // Day/date label
    final now = DateTime.now();
    final days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final dayLabel = '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: _buildAppBar(
        theme, textTheme, initial, firstName, dayLabel, _mockUser.currentStreak,
      ),
      body: SafeArea(
        child: _buildBody(
          context, theme, textTheme, colorScheme, log.coachNote,
          log.consumedMacros.calories, log.consumedMacros.protein,
          log.consumedMacros.carbs, log.consumedMacros.fat,
          targets, _waterLiters, _sleepRating, _weight,
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
      _MockMacros targets,
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
      _MockMacros targets,
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
            onPressed: () => _showMockDialog("Opening Meal Logger..."),
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
                }
              }),
              _buildRoundButton(
                theme,
                Icons.add,
                    () {
                  setState(() => _waterLiters++);
                  HapticFeedback.lightImpact();
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
              onPressed: () => _showMockDialog("Opening Weight Logger..."),
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

// ─────────────────────────────────────────────────────────────────────────────
// PRIVATE MOCK CLASSES
// ─────────────────────────────────────────────────────────────────────────────

class _MockUser {
  final String name;
  final int currentStreak;
  final _MockMacros targetMacros;

  _MockUser({
    required this.name,
    required this.currentStreak,
    required this.targetMacros,
  });
}

class _MockMacros {
  final int calories;
  final int protein;
  final int carbs;
  final int fat;

  _MockMacros({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
}

class _MockLog {
  final String coachNote;
  final _MockMacros consumedMacros;

  _MockLog({
    required this.coachNote,
    required this.consumedMacros,
  });
}