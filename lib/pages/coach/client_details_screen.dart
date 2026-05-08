import 'package:flutter/material.dart';
import 'package:valence/models/daily_log_model.dart';
import 'package:valence/models/enums.dart';
import 'package:valence/models/target_macros.dart';
import 'package:valence/models/user_model.dart';
import 'package:valence/services/firestore_service.dart';
import 'package:valence/theme/app_theme.dart';

class ClientDetailsScreen extends StatefulWidget {
  final AppUser client;
  final int initialTabIndex;

  const ClientDetailsScreen({
    super.key,
    required this.client,
    this.initialTabIndex = 0,
  });

  @override
  State<ClientDetailsScreen> createState() => _ClientDetailsScreenState();
}

class _ClientDetailsScreenState extends State<ClientDetailsScreen> {
  final _firestoreService = FirestoreService();
  final _noteController = TextEditingController();
  bool _isSavingNote = false;
  bool _isSavingMacros = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Color _getStatusColor(ClientStatus status) {
    switch (status) {
      case ClientStatus.unconfigured:
        return Colors.blueGrey;
      case ClientStatus.onTrack:
        return const Color(0xFF10B981);
      case ClientStatus.slipping:
        return const Color(0xFFF59E0B);
      case ClientStatus.atRisk:
        return const Color(0xFFEF4444);
    }
  }

  String _statusLabel(ClientStatus status) {
    switch (status) {
      case ClientStatus.unconfigured:
        return 'Unconfigured';
      case ClientStatus.onTrack:
        return 'On Track';
      case ClientStatus.slipping:
        return 'Watch';
      case ClientStatus.atRisk:
        return 'At Risk';
    }
  }

  String _sleepLabel(int? rating) {
    switch (rating) {
      case 1:
      case 2:
        return 'Poor';
      case 3:
        return 'Fair';
      case 4:
        return 'Good';
      case 5:
        return 'Great';
      default:
        return '--';
    }
  }

  String _formatNumber(num value) {
    final asDouble = value.toDouble();
    if (asDouble == asDouble.roundToDouble()) {
      return asDouble.toInt().toString();
    }
    return asDouble.toStringAsFixed(1);
  }

  String _firstName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'client';
    return trimmed.split(' ').first;
  }

  Future<void> _saveCoachNote(String clientId) async {
    final note = _noteController.text.trim();
    if (note.isEmpty || _isSavingNote) return;

    setState(() => _isSavingNote = true);
    try {
      final saved = await _firestoreService.saveCoachNoteForToday(clientId, note);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(saved ? 'Coach note saved' : 'No log exists for today yet'),
        ),
      );
      if (saved) _noteController.clear();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save coach note')),
      );
    } finally {
      if (mounted) setState(() => _isSavingNote = false);
    }
  }

  Future<void> _configureMacros(AppUser client) async {
    if (_isSavingMacros) return;

    final current = client.targetMacros ?? const TargetMacros();
    final caloriesController = TextEditingController(text: current.calories.toString());
    final proteinController = TextEditingController(text: current.protein.toString());
    final carbsController = TextEditingController(text: current.carbs.toString());
    final fatController = TextEditingController(text: current.fat.toString());

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Configure Macro Targets'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: caloriesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Calories'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: proteinController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Protein (g)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: carbsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Carbs (g)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: fatController,
                keyboardType: TextInputType.number,
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
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (shouldSave != true) return;

    final calories = int.tryParse(caloriesController.text.trim());
    final protein = int.tryParse(proteinController.text.trim());
    final carbs = int.tryParse(carbsController.text.trim());
    final fat = int.tryParse(fatController.text.trim());

    if (calories == null || protein == null || carbs == null || fat == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid macro values')),
      );
      return;
    }

    if (calories <= 0 || protein <= 0 || carbs <= 0 || fat <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All macro values must be greater than 0')),
      );
      return;
    }

    setState(() => _isSavingMacros = true);
    try {
      final targets = TargetMacros(
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
      );
      await _firestoreService.updateClientMacros(client.uid, targets);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Macro targets updated')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save macros')),
      );
    } finally {
      if (mounted) setState(() => _isSavingMacros = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return StreamBuilder<AppUser?>(
      stream: _firestoreService.streamUserById(widget.client.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Client Details'),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Could not load this client right now.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }
        final client = snapshot.data ?? widget.client;
        final status = client.status ?? ClientStatus.onTrack;
        final statusColor = _getStatusColor(status);

        return DefaultTabController(
          length: 3,
          initialIndex: widget.initialTabIndex.clamp(0, 2).toInt(),
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
                            client.name.isEmpty ? 'C' : client.name[0].toUpperCase(),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
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
                              client.name,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: AppSpacing.p4),
                            Row(
                              children: [
                                _buildBadge(_statusLabel(status), statusColor, theme),
                                SizedBox(width: AppSpacing.p4),
                                _buildBadge(
                                  '${client.currentStreak ?? 0} 🔥',
                                  const Color(0xFFF59E0B),
                                  theme,
                                ),
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
                      StreamBuilder<DailyLog?>(
                        stream: _firestoreService.streamTodayLogNullable(client.uid),
                        builder: (context, logSnapshot) {
                          if (logSnapshot.hasError) {
                            return Center(
                              child: Text(
                                'Could not load today\'s log.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            );
                          }
                          final log = logSnapshot.data;
                          return _buildTodayTab(theme, colorScheme, client, log);
                        },
                      ),
                      _buildAnalyticsTab(theme, colorScheme),
                      _buildPlanTab(theme, colorScheme, client),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
              offset: const Offset(0, 2),
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

  Widget _buildTodayTab(
    ThemeData theme,
    ColorScheme colorScheme,
    AppUser client,
    DailyLog? log,
  ) {
    final targets = client.targetMacros ?? const TargetMacros();
    final weight = log?.weightKg ?? client.currentWeight;
    final water = log?.waterLiters;
    final sleep = log?.sleepRating;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMiniStatCard(
                Icons.monitor_weight_outlined,
                'Weight',
                weight == null ? '--' : '${_formatNumber(weight)} kg',
                theme,
                colorScheme,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMiniStatCard(
                Icons.water_drop_outlined,
                'Water',
                water == null ? '--' : '${_formatNumber(water)}L',
                theme,
                colorScheme,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMiniStatCard(
                Icons.bed_outlined,
                'Sleep',
                _sleepLabel(sleep),
                theme,
                colorScheme,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('Nutrition Summary', theme, colorScheme, actionText: 'Edit Targets'),
        const SizedBox(height: 12),
        _buildPremiumMacroCard(theme, colorScheme, log, targets),
        const SizedBox(height: 12),
        _buildMealsList(theme, colorScheme, log),
        const SizedBox(height: 24),
        _buildSectionTitle('Today\'s Workout', theme, colorScheme, actionText: 'Swap Workout'),
        const SizedBox(height: 12),
        _buildWorkoutCard(theme, colorScheme),
        const SizedBox(height: 24),
        _buildClientNoteCard(theme, colorScheme, log?.clientNote),
        const SizedBox(height: 24),
        _buildSectionTitle('Coach Action', theme, colorScheme),
        const SizedBox(height: 12),
        _buildCoachNoteInput(theme, colorScheme, client.uid, _firstName(client.name)),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSectionTitle(
    String title,
    ThemeData theme,
    ColorScheme colorScheme, {
    String? actionText,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        if (actionText != null)
          InkWell(
            onTap: () {},
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
                  color: colorScheme.secondary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMiniStatCard(
    IconData icon,
    String title,
    String value,
    ThemeData theme,
    ColorScheme colorScheme, {
    double? trend,
  }) {
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
                Icon(
                  trend < 0 ? Icons.trending_down : Icons.trending_up,
                  size: 16,
                  color: const Color(0xFF10B981),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          Text(title, style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildPremiumMacroCard(
    ThemeData theme,
    ColorScheme colorScheme,
    DailyLog? log,
    TargetMacros targets,
  ) {
    final calories = log?.totalCalories ?? 0;
    final protein = log?.totalProtein ?? 0.0;
    final carbs = log?.totalCarbs ?? 0.0;
    final fat = log?.totalFat ?? 0.0;
    final calProgress = targets.calories > 0
        ? (calories / targets.calories).clamp(0.0, 1.0)
        : 0.0;

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
                  value: calProgress.toDouble(),
                  strokeWidth: 8,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(colorScheme.secondary),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$calories',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'kcal',
                        style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
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
                _buildLinearMacro('Protein', protein, targets.protein.toDouble(), colorScheme.secondary, theme, colorScheme),
                const SizedBox(height: 10),
                _buildLinearMacro('Carbs', carbs, targets.carbs.toDouble(), colorScheme.secondary.withOpacity(0.6), theme, colorScheme),
                const SizedBox(height: 10),
                _buildLinearMacro('Fat', fat, targets.fat.toDouble(), colorScheme.secondary.withOpacity(0.3), theme, colorScheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinearMacro(
    String label,
    double current,
    double target,
    Color color,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
            Text(
              '${_formatNumber(current)} / ${_formatNumber(target)}g',
              style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress.toDouble(),
            minHeight: 6,
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  Widget _buildMealsList(ThemeData theme, ColorScheme colorScheme, DailyLog? log) {
    final meals = log?.meals ?? const [];
    if (meals.isEmpty) {
      return Text(
        'No meals logged today.',
        style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: meals.map((meal) {
        final hasImage = (meal.imageUrl ?? '').isNotEmpty;
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
                  hasImage ? Icons.image_outlined : Icons.restaurant_menu_outlined,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    meal.name,
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${meal.calories} kcal',
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.fitness_center, color: colorScheme.secondary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Workout details coming soon',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  'Program/workout integration is not wired in this screen yet.',
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientNoteCard(ThemeData theme, ColorScheme colorScheme, String? note) {
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
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: warningColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(note?.trim().isNotEmpty == true ? note!.trim() : 'No client note for today.'),
        ],
      ),
    );
  }

  Widget _buildCoachNoteInput(
    ThemeData theme,
    ColorScheme colorScheme,
    String clientId,
    String firstName,
  ) {
    return Container(
      decoration: _cardDecoration(colorScheme),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: TextField(
        controller: _noteController,
        maxLines: 3,
        minLines: 1,
        style: theme.textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Leave a note for $firstName...',
          hintStyle: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          suffixIcon: IconButton(
            icon: _isSavingNote
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(Icons.send, color: colorScheme.secondary),
            onPressed: () => _saveCoachNote(clientId),
          ),
        ),
      ),
    );
  }

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

  Widget _buildPlanTab(ThemeData theme, ColorScheme colorScheme, AppUser client) {
    final targets = client.targetMacros ?? const TargetMacros();
    final isUnconfigured = (client.status ?? ClientStatus.unconfigured) == ClientStatus.unconfigured;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(colorScheme),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.flag_outlined, color: colorScheme.secondary),
                  const SizedBox(width: 8),
                  Text(
                    'Macro Targets',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _macroRow(theme, colorScheme, 'Calories', '${targets.calories} kcal'),
              const SizedBox(height: 8),
              _macroRow(theme, colorScheme, 'Protein', '${targets.protein} g'),
              const SizedBox(height: 8),
              _macroRow(theme, colorScheme, 'Carbs', '${targets.carbs} g'),
              const SizedBox(height: 8),
              _macroRow(theme, colorScheme, 'Fat', '${targets.fat} g'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSavingMacros ? null : () => _configureMacros(client),
                  icon: _isSavingMacros
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.tune),
                  label: Text(isUnconfigured ? 'Configure Macros' : 'Update Macros'),
                ),
              ),
              if (isUnconfigured) ...[
                const SizedBox(height: 8),
                Text(
                  'Saving macros marks this client as configured.',
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(colorScheme),
          child: Row(
            children: [
              Icon(Icons.fitness_center, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Workout planning will be added here next.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _macroRow(ThemeData theme, ColorScheme colorScheme, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
        Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

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
