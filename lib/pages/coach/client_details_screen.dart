import 'package:flutter/material.dart';
import 'package:valence/theme/app_theme.dart';

import '../../models/enums.dart';


class ClientDetailsScreen extends StatefulWidget {
  const ClientDetailsScreen({super.key});

  @override
  State<ClientDetailsScreen> createState() => _ClientDetailsScreenState();
}

class _ClientDetailsScreenState extends State<ClientDetailsScreen> {
  final _noteController = TextEditingController();
  bool _isSavingNote = false;

  // ── MOCK DATA ──────────────────────────────────────────────────
  final _mockClient = _MockClient(
    name: 'Sarah Johnson',
    status: ClientStatus.atRisk,
    currentStreak: 4,
    currentWeight: 168.4,
  );

  final _mockTargets = _MockMacros(calories: 2000, protein: 140, carbs: 200, fat: 65);

  final _mockLog = _MockLog(
    waterLiters: 2.5,
    sleepRating: 3,
    weight: 168.0,
    consumedMacros: _MockMacros(calories: 1850, protein: 130, carbs: 180, fat: 60),
    clientNote: "Felt a bit tired today but pushed through the upper body workout. Left shoulder is slightly sore.",
    meals: [
      _MockMeal(hasImage: true, description: 'Oatmeal with berries & protein', macros: _MockMacros(calories: 450, protein: 30, carbs: 60, fat: 10)),
      _MockMeal(hasImage: false, description: 'Chicken salad with olive oil', macros: _MockMacros(calories: 550, protein: 45, carbs: 15, fat: 25)),
    ],
  );

  final _mockWorkout = _MockWorkout(
    title: 'Upper Body Power',
    isCompleted: false,
    completedExercises: 3,
    totalExercises: 5,
    clientFeedback: "Couldn't finish the last two tricep sets, arms were dead!",
  );

  Color _getStatusColor(ClientStatus status) {
    switch (status) {
      case ClientStatus.onTrack: return const Color(0xFF10B981);
      case ClientStatus.slipping: return const Color(0xFFF59E0B);
      case ClientStatus.atRisk: return const Color(0xFFEF4444);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = _getStatusColor(_mockClient.status);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: colorScheme.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: colorScheme.onSurface, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Client Details',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.p12),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: statusColor.withOpacity(0.8), width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: statusColor.withOpacity(0.1),
                      child: Text(
                        _mockClient.name[0],
                        style: theme.textTheme.titleMedium?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: AppSpacing.p8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _mockClient.name,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: AppSpacing.p4),
                        Row(
                          children: [
                            _buildBadge(
                              _mockClient.status == ClientStatus.atRisk ? 'At Risk' : 'On Track',
                              statusColor,
                              theme,
                            ),
                            SizedBox(width: AppSpacing.p4),
                            _buildBadge('${_mockClient.currentStreak} 🔥', const Color(0xFFF59E0B), theme),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.p16),
            _buildTabBar(theme, colorScheme),
            Expanded(
              child: TabBarView(
                children: [
                  _buildTodayTab(theme, colorScheme),
                  _buildAnalyticsTab(theme, colorScheme),
                  _buildPlanTab(theme, colorScheme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.2 : 0.1),
        borderRadius: AppTheme.defaultBorderRadius,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.p12),
      height: 38,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TabBar(
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
                color: colorScheme.shadow.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2)
            ),
          ],
        ),
        labelColor: colorScheme.secondary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        labelStyle: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
        unselectedLabelStyle: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500),
        padding: const EdgeInsets.all(3),
        tabs: const [
          Tab(text: 'Today'),
          Tab(text: 'Analytics'),
          Tab(text: 'Plan'),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // 3. TODAY TAB
  // ──────────────────────────────────────────────────────────────────
  Widget _buildTodayTab(ThemeData theme, ColorScheme colorScheme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Mini-stats
        Row(
          children: [
            Expanded(child: _buildMiniStatCard(Icons.monitor_weight_outlined, 'Weight', '${_mockLog.weight} lbs', theme, colorScheme, trend: -0.4)),
            const SizedBox(width: 8),
            Expanded(child: _buildMiniStatCard(Icons.water_drop_outlined, 'Water', '${_mockLog.waterLiters}L', theme, colorScheme)),
            const SizedBox(width: 8),
            Expanded(child: _buildMiniStatCard(Icons.bed_outlined, 'Sleep', 'Good', theme, colorScheme)),
          ],
        ),
        const SizedBox(height: 24),

        // Macros & Meals
        _buildSectionTitle('Nutrition Summary', theme, colorScheme, actionText: 'Edit Targets'),
        const SizedBox(height: 12),
        _buildPremiumMacroCard(theme, colorScheme),
        const SizedBox(height: 12),
        _buildMealsList(theme, colorScheme), // Added missing meals section!
        const SizedBox(height: 24),

        // Workout
        _buildSectionTitle('Today\'s Workout', theme, colorScheme, actionText: 'Swap Workout'),
        const SizedBox(height: 12),
        _buildWorkoutCard(theme, colorScheme),
        const SizedBox(height: 24),

        // Client Check-in Note
        _buildClientNoteCard(theme, colorScheme),
        const SizedBox(height: 24),

        // Coach Note Input
        _buildSectionTitle('Coach Action', theme, colorScheme),
        const SizedBox(height: 12),
        _buildCoachNoteInput(theme, colorScheme),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme, ColorScheme colorScheme, {String? actionText}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        if (actionText != null)
          InkWell(
            onTap: () {}, // Handle action
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                  actionText,
                  style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.secondary
                  )
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMiniStatCard(IconData icon, String title, String value, ThemeData theme, ColorScheme colorScheme, {double? trend}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(colorScheme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 18, color: colorScheme.secondary),
              if (trend != null)
                Icon(trend < 0 ? Icons.trending_down : Icons.trending_up, size: 16, color: const Color(0xFF10B981)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          Text(title, style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildPremiumMacroCard(ThemeData theme, ColorScheme colorScheme) {
    double calProgress = _mockLog.consumedMacros.calories / _mockTargets.calories;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(colorScheme),
      child: Row(
        children: [
          SizedBox(
            height: 90,
            width: 90,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: calProgress,
                  strokeWidth: 8,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(colorScheme.secondary),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                          '${_mockLog.consumedMacros.calories}',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
                      ),
                      Text('kcal', style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: [
                _buildLinearMacro('Protein', _mockLog.consumedMacros.protein, _mockTargets.protein, colorScheme.secondary, theme, colorScheme),
                const SizedBox(height: 10),
                _buildLinearMacro('Carbs', _mockLog.consumedMacros.carbs, _mockTargets.carbs, colorScheme.secondary.withOpacity(0.6), theme, colorScheme),
                const SizedBox(height: 10),
                _buildLinearMacro('Fat', _mockLog.consumedMacros.fat, _mockTargets.fat, colorScheme.secondary.withOpacity(0.3), theme, colorScheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinearMacro(String label, int current, int target, Color color, ThemeData theme, ColorScheme colorScheme) {
    double progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
            Text('${current} / ${target}g', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  // Added this missing view so the coach actually sees what the client ate
  Widget _buildMealsList(ThemeData theme, ColorScheme colorScheme) {
    if (_mockLog.meals.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _mockLog.meals.map((meal) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                    meal.hasImage ? Icons.image_outlined : Icons.restaurant_menu_outlined,
                    size: 16,
                    color: colorScheme.onSurfaceVariant
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    meal.description,
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${meal.macros.calories} kcal',
                  style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWorkoutCard(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(colorScheme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: colorScheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)
                ),
                child: Icon(Icons.fitness_center, color: colorScheme.secondary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_mockWorkout.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(
                        '${_mockWorkout.completedExercises}/${_mockWorkout.totalExercises} exercises completed',
                        style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_mockWorkout.clientFeedback.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8)
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.format_quote, size: 16, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _mockWorkout.clientFeedback,
                      style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildClientNoteCard(ThemeData theme, ColorScheme colorScheme) {
    final warningColor = const Color(0xFFF59E0B);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: warningColor.withOpacity(isDark ? 0.1 : 0.05),
        border: Border.all(color: warningColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: warningColor, size: 18),
              const SizedBox(width: 8),
              Text(
                  'Client Check-in Note',
                  style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: warningColor)
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(_mockLog.clientNote, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildCoachNoteInput(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      decoration: _cardDecoration(colorScheme),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: TextField(
        controller: _noteController,
        maxLines: 3,
        minLines: 1,
        style: theme.textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Leave a note for ${_mockClient.name.split(' ').first}...',
          hintStyle: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          suffixIcon: IconButton(
            icon: _isSavingNote
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(Icons.send, color: colorScheme.secondary),
            onPressed: () {
              setState(() => _isSavingNote = true);
              Future.delayed(const Duration(seconds: 1), () {
                if (mounted) setState(() => _isSavingNote = false);
              });
            },
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // 4. ANALYTICS & PLAN TABS (Mocks)
  // ──────────────────────────────────────────────────────────────────
  Widget _buildAnalyticsTab(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 60, color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text('Analytics', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          Text('Charts and trends go here.', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildPlanTab(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_month, size: 60, color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text('Program Builder', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          Text('Manage upcoming schedule here.', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  // Adaptable card decoration using Theme colors
  BoxDecoration _cardDecoration(ColorScheme colorScheme) {
    return BoxDecoration(
      color: colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      boxShadow: [
        BoxShadow(
          color: colorScheme.shadow.withOpacity(0.02),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRIVATE MOCK CLASSES
// ─────────────────────────────────────────────────────────────────────────────
class _MockClient {
  final String name;
  final ClientStatus status;
  final int currentStreak;
  final double currentWeight;

  _MockClient({required this.name, required this.status, required this.currentStreak, required this.currentWeight});
}

class _MockMacros {
  final int calories, protein, carbs, fat;
  _MockMacros({required this.calories, required this.protein, required this.carbs, required this.fat});
}

class _MockMeal {
  final bool hasImage;
  final String description;
  final _MockMacros macros;
  _MockMeal({required this.hasImage, required this.description, required this.macros});
}

class _MockLog {
  final double waterLiters;
  final int sleepRating;
  final double weight;
  final _MockMacros consumedMacros;
  final String clientNote;
  final List<_MockMeal> meals;

  _MockLog({required this.waterLiters, required this.sleepRating, required this.weight, required this.consumedMacros, required this.clientNote, required this.meals});
}

class _MockWorkout {
  final String title;
  final bool isCompleted;
  final int completedExercises, totalExercises;
  final String clientFeedback;

  _MockWorkout({required this.title, required this.isCompleted, required this.completedExercises, required this.totalExercises, required this.clientFeedback});
}