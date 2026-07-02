import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:valence/models/daily_log_model.dart';
import 'package:valence/l10n/l10n_ext.dart';
import 'package:valence/models/enums.dart';
import 'package:valence/models/habit_model.dart';
import 'package:valence/models/target_macros.dart';
import 'package:valence/models/user_model.dart';
import 'package:valence/models/workout_models.dart';
import 'package:valence/pages/shared/progress_charts_section.dart';
import 'package:valence/services/firestore_service.dart';
import 'package:valence/theme/app_theme.dart';
import 'package:valence/utils/units.dart';

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
  /// Cached display unit of the client currently being viewed ('kg'|'lb'),
  /// refreshed each build from the streamed client so deep workout/weight
  /// helpers can convert without threading it through every signature.
  String? _unit;
  String get _weightUnitLabel => isMetricWeight(_unit) ? context.l10n.unitKg : context.l10n.unitLb;
  String _weightStr(double kg) => '${_formatNumber(displayWeight(kg, _unit))} $_weightUnitLabel';
  final _firestoreService = FirestoreService();
  bool _isSavingMacros = false;
  DateTime _selectedDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  ChartRange _selectedRange = ChartRange.weekly;

  // Cached Firestore streams — created lazily and re-created only when their key
  // inputs (the viewed date / chart range) change. This stops unrelated rebuilds
  // — notably the keyboard opening, which re-runs build repeatedly during its
  // animation — from restarting the streams and rebuilding the whole screen
  // (the source of the typing lag).
  Stream<AppUser?>? _clientStream;
  Stream<AppUser?> get _clientStreamCached =>
      _clientStream ??= _firestoreService.streamUserById(widget.client.uid);

  DateTime? _logStreamDate;
  Stream<DailyLog?>? _logStream;
  Stream<DailyLog?> _logStreamFor(DateTime date) {
    if (_logStream == null || !_isSameDay(_logStreamDate!, date)) {
      _logStreamDate = date;
      _logStream = _firestoreService.streamLogForDateNullable(widget.client.uid, date);
    }
    return _logStream!;
  }

  DateTime? _workoutStreamDate;
  Stream<AssignedWorkout?>? _workoutStream;
  Stream<AssignedWorkout?> _assignedWorkoutStreamFor(DateTime date) {
    if (_workoutStream == null || !_isSameDay(_workoutStreamDate!, date)) {
      _workoutStreamDate = date;
      _workoutStream = _firestoreService.streamAssignedWorkoutForDate(widget.client.uid, date);
    }
    return _workoutStream!;
  }

  int? _recentLogsDays;
  Stream<List<DailyLog>>? _recentLogsStream;
  Stream<List<DailyLog>> _recentLogsStreamFor(int days) {
    if (_recentLogsStream == null || _recentLogsDays != days) {
      _recentLogsDays = days;
      _recentLogsStream = _firestoreService.streamRecentLogs(widget.client.uid, days: days);
    }
    return _recentLogsStream!;
  }

  // Status palette + labels mirror clients_screen's _statusMeta so the two
  // surfaces read identically.
  Color _getStatusColor(ClientStatus status) {
    switch (status) {
      case ClientStatus.unconfigured:
        return const Color(0xFF8E8E93);
      case ClientStatus.onTrack:
        return AppColors.statusGreen;
      case ClientStatus.slipping:
        return AppColors.statusYellow;
      case ClientStatus.atRisk:
        return AppColors.statusRed;
    }
  }

  String _statusLabel(ClientStatus status) {
    switch (status) {
      case ClientStatus.unconfigured:
        return context.l10n.statusSetup;
      case ClientStatus.onTrack:
        return context.l10n.statusGood;
      case ClientStatus.slipping:
        return context.l10n.statusWatch;
      case ClientStatus.atRisk:
        return context.l10n.statusAlert;
    }
  }

  String _sleepLabel(int? rating) {
    switch (rating) {
      case 1:
      case 2:
        return context.l10n.sleepPoor;
      case 3:
        return context.l10n.sleepFair;
      case 4:
        return context.l10n.statusGood;
      case 5:
        return context.l10n.sleepGreat;
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
    if (trimmed.isEmpty) return context.l10n.roleClient;
    return trimmed.split(' ').first;
  }

  DateTime _normalizedDate(DateTime date) => DateTime(date.year, date.month, date.day);

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Saves (or overwrites) the coach note for [date]. Returns whether it saved
  /// — the note overwrites the same day's note rather than appending a new one.
  Future<bool> _saveCoachNoteText(String clientId, DateTime date, String text) async {
    final note = text.trim();
    if (note.isEmpty) return false;
    try {
      final saved = await _firestoreService.saveCoachNoteForDate(clientId, date, note);
      if (!mounted) return saved;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(saved ? context.l10n.noteSaved : context.l10n.noLogForDay),
        ),
      );
      return saved;
    } catch (_) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.noteSaveFailed)),
      );
      return false;
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
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final cs = theme.colorScheme;
        final textTheme = theme.textTheme;

        Widget field(TextEditingController c, String label, String unit, IconData icon, Color accent) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextField(
              controller: c,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: label,
                suffixText: unit,
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 14, right: 10),
                  child: Icon(icon, size: 18, color: accent),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              ),
            ),
          );
        }

        return Dialog(
          backgroundColor: cs.surface,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.secondaryColor.withValues(alpha: 0.9),
                            AppColors.secondaryColor.withValues(alpha: 0.55),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.secondaryColor.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(PhosphorIconsFill.target, color: AppColors.primaryColor, size: 21),
                    ),
                    SizedBox(width: AppSpacing.p12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.macroTargets.toUpperCase(),
                            style: textTheme.labelSmall?.copyWith(
                              color: AppColors.secondaryColor,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.4,
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            context.l10n.dailyGoalsName(_firstName(client.name)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.p20),
                field(caloriesController, context.l10n.caloriesLabel, 'kcal', PhosphorIconsFill.fire, AppColors.secondaryColor),
                field(proteinController, context.l10n.macroProtein, 'g', PhosphorIconsBold.barbell, cs.primary),
                field(carbsController, context.l10n.macroCarbs, 'g', PhosphorIconsFill.lightning, cs.tertiary),
                field(fatController, context.l10n.macroFat, 'g', PhosphorIconsFill.drop, cs.error),
                SizedBox(height: AppSpacing.p8),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(context.l10n.cancel),
                      ),
                    ),
                    SizedBox(width: AppSpacing.p12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(ctx, true);
                        },
                        child: Container(
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.secondaryColor,
                                AppColors.secondaryColor.withValues(alpha: 0.82),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.secondaryColor.withValues(alpha: 0.3),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Text(
                            context.l10n.saveTargets,
                            style: textTheme.titleSmall?.copyWith(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    final caloriesText = caloriesController.text.trim();
    final proteinText = proteinController.text.trim();
    final carbsText = carbsController.text.trim();
    final fatText = fatController.text.trim();
    caloriesController.dispose();
    proteinController.dispose();
    carbsController.dispose();
    fatController.dispose();

    if (shouldSave != true) return;

    final calories = int.tryParse(caloriesText);
    final protein = int.tryParse(proteinText);
    final carbs = int.tryParse(carbsText);
    final fat = int.tryParse(fatText);

    if (calories == null || protein == null || carbs == null || fat == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.enterValidMacros)),
      );
      return;
    }

    if (calories <= 0 || protein <= 0 || carbs <= 0 || fat <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.macrosMustBePositive)),
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
        SnackBar(content: Text(context.l10n.macroTargetsUpdated)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.failedSaveMacros)),
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
      stream: _clientStreamCached,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: Text(context.l10n.clientDetailsTitle),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  context.l10n.loadClientError,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }
        final client = snapshot.data ?? widget.client;
        _unit = client.weightUnit;
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
                context.l10n.clientDetailsTitle,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
            ),
            body: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(AppSpacing.p16, AppSpacing.p4, AppSpacing.p16, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [statusColor, statusColor.withValues(alpha: 0.25)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withValues(alpha: 0.28),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          backgroundColor: colorScheme.surface,
                          child: Text(
                            client.name.isEmpty ? 'C' : client.name[0].toUpperCase(),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: AppSpacing.p12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              client.name,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: AppSpacing.p4 + 2),
                            Row(
                              children: [
                                _buildStatusPill(_statusLabel(status), statusColor, theme),
                                SizedBox(width: AppSpacing.p8),
                                _buildStreakPill(client.currentStreak ?? 0, theme),
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
                        stream: _logStreamFor(_selectedDate),
                        builder: (context, logSnapshot) {
                          if (logSnapshot.hasError) {
                            return Center(
                              child: Text(
                                context.l10n.loadDayError,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            );
                          }
                          final log = logSnapshot.data;
                          return _buildTodayTab(
                            theme,
                            colorScheme,
                            client,
                            log,
                            _selectedDate,
                          );
                        },
                      ),
                      _buildAnalyticsTab(theme, colorScheme, client),
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

  Widget _buildStatusPill(String label, Color color, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4)],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakPill(int streak, ThemeData theme) {
    const gold = AppColors.secondaryColor;
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: gold.withValues(alpha: isDark ? 0.18 : 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: gold.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(PhosphorIconsFill.flame, size: 12, color: gold),
          const SizedBox(width: 5),
          Text(
            '$streak',
            style: theme.textTheme.labelSmall?.copyWith(
              color: gold,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ],
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
        tabs: [
          Tab(text: context.l10n.todayLabel),
          Tab(text: context.l10n.tabAnalytics),
          Tab(text: context.l10n.tabPlan),
        ],
      ),
    );
  }

  Widget _buildTodayTab(
    ThemeData theme,
    ColorScheme colorScheme,
    AppUser client,
    DailyLog? log,
    DateTime selectedDate,
  ) {
    final targets = client.targetMacros ?? const TargetMacros();
    final weight = log?.weightKg ?? client.currentWeight;
    final water = log?.waterLiters;
    final sleep = log?.sleepRating;
    final isToday = _isSameDay(selectedDate, DateTime.now());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCoachDateStrip(theme, colorScheme),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMiniStatCard(
                Icons.monitor_weight_outlined,
                context.l10n.weightLabel,
                weight == null ? '--' : _weightStr(weight),
                theme,
                colorScheme,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMiniStatCard(
                Icons.water_drop_outlined,
                context.l10n.waterLabel,
                water == null ? '--' : '${_formatNumber(water)}L',
                theme,
                colorScheme,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMiniStatCard(
                Icons.bed_outlined,
                context.l10n.sleepLabel,
                _sleepLabel(sleep),
                theme,
                colorScheme,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSectionTitle(
          context.l10n.nutritionSummary,
          theme,
          colorScheme,
          actionText: context.l10n.editTargets,
          onActionTap: () => _configureMacros(client),
        ),
        const SizedBox(height: 12),
        _buildNutritionDashboard(theme, colorScheme, log, targets),
        const SizedBox(height: 12),
        _buildMealsList(theme, colorScheme, log),
        const SizedBox(height: 24),
        _buildSectionTitle(
          isToday ? context.l10n.todaysWorkout : context.l10n.workoutLabel,
          theme,
          colorScheme,
          actionText: context.l10n.swapWorkout,
          onActionTap: () => _showSwapWorkoutDialog(client, selectedDate),
        ),
        const SizedBox(height: 12),
        _buildWorkoutCard(theme, colorScheme, client.uid, selectedDate),
        const SizedBox(height: 24),
        _buildClientNoteCard(theme, colorScheme, log?.clientNote),
        const SizedBox(height: 24),
        _buildSectionTitle(context.l10n.coachNoteLabel, theme, colorScheme),
        const SizedBox(height: 12),
        _CoachNoteEditor(
          key: ValueKey('coachnote_${selectedDate.toIso8601String()}'),
          theme: theme,
          initialNote: log?.coachNote,
          firstName: _firstName(client.name),
          isToday: isToday,
          onSave: (text) => _saveCoachNoteText(client.uid, selectedDate, text),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSectionTitle(
    String title,
    ThemeData theme,
    ColorScheme colorScheme, {
    String? actionText,
    VoidCallback? onActionTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        if (actionText != null)
          InkWell(
            onTap: onActionTap,
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
      padding: const EdgeInsets.all(13),
      decoration: _cardDecoration(colorScheme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.secondaryColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 16, color: AppColors.secondaryColor),
              ),
              if (trend != null)
                Icon(
                  trend < 0 ? Icons.trending_down : Icons.trending_up,
                  size: 16,
                  color: AppColors.statusGreen,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          Text(
            title,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Compact nutrition card (read-only for the coach): a calorie ring + three
  /// macro bars coloured per-macro to match the client's own dashboard.
  Widget _buildNutritionDashboard(
    ThemeData theme,
    ColorScheme cs,
    DailyLog? log,
    TargetMacros targets,
  ) {
    final textTheme = theme.textTheme;
    final cals = log?.totalCalories ?? 0;
    final protein = log?.totalProtein ?? 0;
    final carbs = log?.totalCarbs ?? 0;
    final fat = log?.totalFat ?? 0;
    final isOver = targets.calories > 0 && cals > targets.calories;
    final calProgress =
        targets.calories > 0 ? (cals / targets.calories).clamp(0.0, 1.0).toDouble() : 0.0;
    final ringColor = isOver ? cs.error : AppColors.secondaryColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(cs),
      child: Row(
        children: [
          SizedBox(
            height: 92,
            width: 92,
            child: Stack(
              fit: StackFit.expand,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: calProgress),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => CircularProgressIndicator(
                    value: value,
                    strokeWidth: 8,
                    strokeCap: StrokeCap.round,
                    backgroundColor: cs.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(ringColor),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$cals',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          height: 1,
                          color: isOver ? cs.error : cs.onSurface,
                        ),
                      ),
                      Text(
                        context.l10n.ofTarget('${targets.calories}'),
                        style: textTheme.labelSmall?.copyWith(
                          fontSize: 8,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ),
                      Text(
                        context.l10n.kcal.toUpperCase(),
                        style: textTheme.labelSmall?.copyWith(
                          fontSize: 8,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.p20),
          Expanded(
            child: Column(
              children: [
                _buildLinearMacro(theme, cs, context.l10n.macroProtein, PhosphorIconsBold.barbell, protein,
                    targets.protein.toDouble(), cs.primaryContainer, cs.onPrimaryContainer),
                const SizedBox(height: 12),
                _buildLinearMacro(theme, cs, context.l10n.macroCarbs, PhosphorIconsFill.lightning, carbs,
                    targets.carbs.toDouble(), cs.secondaryContainer, cs.onSecondaryContainer),
                const SizedBox(height: 12),
                _buildLinearMacro(theme, cs, context.l10n.macroFat, PhosphorIconsFill.drop, fat,
                    targets.fat.toDouble(), cs.tertiaryContainer, cs.onTertiaryContainer),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinearMacro(
    ThemeData theme,
    ColorScheme cs,
    String label,
    IconData icon,
    double current,
    double target,
    Color chipColor,
    Color onChipColor,
  ) {
    final textTheme = theme.textTheme;
    final isOver = target > 0 && current > target;
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0).toDouble() : 0.0;
    final barColor = isOver ? cs.error : onChipColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 13, color: barColor),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Text(
              '${_formatNumber(current)} / ${_formatNumber(target)}g',
              style: textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: isOver ? cs.error : cs.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: progress),
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) => ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 7,
              backgroundColor: chipColor.withValues(alpha: 0.4),
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMealsList(ThemeData theme, ColorScheme colorScheme, DailyLog? log) {
    final meals = log?.meals ?? const [];
    final textTheme = theme.textTheme;
    if (meals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(PhosphorIconsRegular.forkKnife,
                size: 16, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
            const SizedBox(width: 8),
            Text(
              context.l10n.noMealsLogged,
              style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: meals.map((meal) {
        final hasImage = (meal.imageUrl ?? '').isNotEmpty;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      hasImage ? PhosphorIconsFill.image : PhosphorIconsFill.forkKnife,
                      size: 15,
                      color: AppColors.secondaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        meal.name,
                        style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${meal.calories}',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.secondaryColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      ' kcal',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _mealMacroTag(theme, colorScheme, 'P', meal.protein,
                        colorScheme.primaryContainer, colorScheme.onPrimaryContainer),
                    const SizedBox(width: 6),
                    _mealMacroTag(theme, colorScheme, 'C', meal.carbs,
                        colorScheme.secondaryContainer, colorScheme.onSecondaryContainer),
                    const SizedBox(width: 6),
                    _mealMacroTag(theme, colorScheme, 'F', meal.fat,
                        colorScheme.tertiaryContainer, colorScheme.onTertiaryContainer),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _mealMacroTag(
    ThemeData theme,
    ColorScheme cs,
    String letter,
    double grams,
    Color chipColor,
    Color onChipColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$letter ',
              style: theme.textTheme.labelSmall?.copyWith(
                color: onChipColor.withValues(alpha: 0.7),
                fontWeight: FontWeight.w800,
              ),
            ),
            TextSpan(
              text: '${_formatNumber(grams)}g',
              style: theme.textTheme.labelSmall?.copyWith(
                color: onChipColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutCard(
    ThemeData theme,
    ColorScheme colorScheme,
    String clientId,
    DateTime selectedDate,
  ) {
    return StreamBuilder<AssignedWorkout?>(
      stream: _assignedWorkoutStreamFor(selectedDate),
      builder: (context, snapshot) {
        final workout = snapshot.data;
        if (workout == null) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(colorScheme),
            child: Text(
              context.l10n.noWorkoutAssignedLib,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }

        final exercises = workout.exercises;
        final totalSets = exercises.fold<int>(0, (s, e) => s + e.sets);
        final doneSets = exercises.fold<int>(0, (s, e) => s + _loggedDoneSets(e));
        final setProgress = totalSets > 0 ? doneSets / totalSets : 0.0;
        final statusColor = workout.isCompleted ? AppColors.statusGreen : colorScheme.secondary;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(colorScheme),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(PhosphorIconsFill.barbell, color: colorScheme.secondary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      workout.title,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      workout.isCompleted ? context.l10n.done : context.l10n.inProgress,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: setProgress.toDouble()),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) => ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: value,
                          minHeight: 8,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation(statusColor),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$doneSets/$totalSets sets',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...exercises.map((e) => _buildExerciseProgress(theme, colorScheme, e)),
            ],
          ),
        );
      },
    );
  }

  /// Number of sets the client has actually logged reps for.
  int _loggedDoneSets(WorkoutExercise e) {
    final logs = e.loggedRepsBySet;
    var count = 0;
    for (var i = 0; i < e.sets; i++) {
      if (i < logs.length && logs[i] > 0) count++;
    }
    return count;
  }

  /// Read-only per-exercise breakdown mirroring what the client logs:
  /// each set's reps and weight (logged, falling back to the coach target).
  Widget _buildExerciseProgress(ThemeData theme, ColorScheme cs, WorkoutExercise e) {
    final textTheme = theme.textTheme;
    final done = _loggedDoneSets(e);
    final complete = done >= e.sets && e.sets > 0;
    final badgeColor = complete ? AppColors.statusGreen : cs.secondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  e.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  complete ? context.l10n.done : '$done/${e.sets}',
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...List.generate(e.sets, (i) {
            final reps = i < e.loggedRepsBySet.length ? e.loggedRepsBySet[i] : 0;
            final logged = i < e.loggedWeightKgBySet.length ? e.loggedWeightKgBySet[i] : null;
            final target = i < e.targetWeightKgBySet.length ? e.targetWeightKgBySet[i] : null;
            final weight = logged ?? target;
            final dn = reps > 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                children: [
                  Icon(
                    dn ? PhosphorIconsFill.checkCircle : PhosphorIconsRegular.circle,
                    size: 15,
                    color: dn ? AppColors.statusGreen : cs.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.setNumberLabel(i + 1),
                    style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const Spacer(),
                  Text(
                    dn ? '$reps reps' : context.l10n.pendingTarget(e.reps),
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: dn ? cs.onSurface : cs.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                  if (weight != null) ...[
                    Text(
                      '  ·  ',
                      style: textTheme.labelMedium?.copyWith(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    Text(
                      _weightStr(weight),
                      style: textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: logged != null ? cs.secondary : cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildClientNoteCard(ThemeData theme, ColorScheme colorScheme, String? note) {
    const accent = AppColors.secondaryColor;
    final hasNote = note?.trim().isNotEmpty == true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(accent.withValues(alpha: 0.07), colorScheme.surfaceContainerLow),
            colorScheme.surfaceContainerLow,
          ],
          stops: const [0.0, 0.62],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(PhosphorIconsFill.chatCircleText, color: accent, size: 17),
              const SizedBox(width: 8),
              Text(
                context.l10n.clientCheckIn.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  fontSize: 10,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hasNote ? note!.trim() : context.l10n.noCheckInNote,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.4,
              color: hasNote ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
              fontStyle: hasNote ? FontStyle.normal : FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachDateStrip(ThemeData theme, ColorScheme colorScheme) {
    final now = DateTime.now();
    final days = List.generate(
      14,
      (index) => DateTime(now.year, now.month, now.day).subtract(
        Duration(days: 13 - index),
      ),
    );

    return SizedBox(
      height: 62,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final day = days[index];
          final normalizedDay = _normalizedDate(day);
          final isToday = _isSameDay(day, now);
          final isSelected = _isSameDay(_selectedDate, normalizedDay);
          return InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => setState(() => _selectedDate = normalizedDay),
            child: Container(
              width: 46,
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.secondary.withOpacity(0.14)
                    : colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? colorScheme.secondary
                      : colorScheme.outlineVariant.withOpacity(0.6),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    ['M', 'T', 'W', 'T', 'F', 'S', 'S'][day.weekday - 1],
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${day.day}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: isSelected ? colorScheme.secondary : colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isToday)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.secondary,
                        shape: BoxShape.circle,
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

  Widget _buildAnalyticsTab(ThemeData theme, ColorScheme colorScheme, AppUser client) {
    final targets = client.targetMacros ?? const TargetMacros();
    return StreamBuilder<List<DailyLog>>(
      stream: _recentLogsStreamFor(_selectedRange.days),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              context.l10n.loadAnalyticsError,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }

        return ProgressChartsSection(
          logs: snapshot.data ?? const <DailyLog>[],
          targets: targets,
          weightUnit: client.weightUnit,
          selectedRange: _selectedRange,
          onRangeChanged: (value) => setState(() => _selectedRange = value),
        );
      },
    );
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showSwapWorkoutDialog(AppUser client, DateTime date) async {
    final coachId = client.coachId?.trim();
    if (coachId == null || coachId.isEmpty) {
      _toast(context.l10n.noCoachLinked);
      return;
    }

    final templates = await _firestoreService.getWorkoutTemplates(coachId);
    if (!mounted) return;
    if (templates.isEmpty) {
      _toast(context.l10n.noLibraryWorkouts);
      return;
    }

    final selected = await showModalBottomSheet<WorkoutTemplate>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SwapWorkoutSheet(
        templates: templates,
        clientName: _firstName(client.name),
        date: date,
      ),
    );
    if (selected == null) return;

    try {
      await _firestoreService.assignWorkoutToClient(
        coachId: coachId,
        clientId: client.uid,
        date: date,
        title: selected.name,
        exercises: selected.exercises,
      );
      _toast(context.l10n.workoutAssignedName(selected.name));
    } catch (_) {
      _toast(context.l10n.assignWorkoutErr);
    }
  }

  Future<void> _showEditWorkoutDialog(AssignedWorkout workout) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final titleController = TextEditingController(text: workout.title);
    final exerciseNameControllers = workout.exercises
        .map((e) => TextEditingController(text: e.name))
        .toList();
    final sets = workout.exercises.map((e) => e.sets).toList();
    final reps = workout.exercises.map((e) => e.reps).toList();
    final targetWeights = workout.exercises
        .map((e) => e.targetWeightKgBySet.isEmpty ? null : e.targetWeightKgBySet.first)
        .toList();

    final shouldSave = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final cs = colorScheme;
          final textTheme = theme.textTheme;

          Widget stepper({
            required String label,
            required String value,
            required VoidCallback onMinus,
            required VoidCallback onPlus,
            String? suffix,
          }) {
            Widget btn(IconData icon, VoidCallback onTap) => GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onTap();
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
                    ),
                    child: Icon(icon, size: 14, color: cs.onSurface),
                  ),
                );
            return Row(
              children: [
                Text(
                  label,
                  style: textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                btn(PhosphorIconsBold.minus, onMinus),
                SizedBox(
                  width: 52,
                  child: Text(
                    suffix == null ? value : '$value$suffix',
                    textAlign: TextAlign.center,
                    style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                btn(PhosphorIconsBold.plus, onPlus),
              ],
            );
          }

          return Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
            ),
            padding: EdgeInsets.only(
              left: AppSpacing.p20,
              right: AppSpacing.p20,
              top: AppSpacing.p12,
              bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.p16,
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
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.secondaryColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(PhosphorIconsFill.pencilSimple,
                            color: AppColors.secondaryColor, size: 18),
                      ),
                      SizedBox(width: AppSpacing.p12),
                      Text(
                        context.l10n.updateWorkout,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.p16),
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          TextField(
                            controller: titleController,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(labelText: context.l10n.workoutTitleLabel),
                          ),
                          const SizedBox(height: 12),
                          ...List.generate(exerciseNameControllers.length, (index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: cs.outlineVariant.withValues(alpha: 0.28)),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: exerciseNameControllers[index],
                                            textCapitalization: TextCapitalization.words,
                                            decoration: InputDecoration(
                                              labelText: context.l10n.exerciseNumber(index + 1),
                                              isDense: true,
                                              filled: true,
                                              fillColor: cs.surface,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: exerciseNameControllers.length <= 1
                                              ? null
                                              : () => setSheetState(() {
                                                    exerciseNameControllers.removeAt(index).dispose();
                                                    sets.removeAt(index);
                                                    reps.removeAt(index);
                                                    targetWeights.removeAt(index);
                                                  }),
                                          child: Container(
                                            width: 38,
                                            height: 38,
                                            decoration: BoxDecoration(
                                              color: AppColors.statusRed.withValues(
                                                  alpha: exerciseNameControllers.length <= 1 ? 0.04 : 0.1),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Icon(
                                              PhosphorIconsBold.trash,
                                              size: 16,
                                              color: AppColors.statusRed.withValues(
                                                  alpha: exerciseNameControllers.length <= 1 ? 0.3 : 1),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    stepper(
                                      label: context.l10n.statSets,
                                      value: '${sets[index]}',
                                      onMinus: () => setSheetState(
                                          () => sets[index] = (sets[index] - 1).clamp(1, 50)),
                                      onPlus: () => setSheetState(
                                          () => sets[index] = (sets[index] + 1).clamp(1, 50)),
                                    ),
                                    const SizedBox(height: 8),
                                    stepper(
                                      label: context.l10n.statReps,
                                      value: '${reps[index]}',
                                      onMinus: () => setSheetState(
                                          () => reps[index] = (reps[index] - 1).clamp(1, 100)),
                                      onPlus: () => setSheetState(
                                          () => reps[index] = (reps[index] + 1).clamp(1, 100)),
                                    ),
                                    const SizedBox(height: 8),
                                    stepper(
                                      label: context.l10n.targetWeightLabel,
                                      suffix: targetWeights[index] == null ? '' : _weightUnitLabel,
                                      // Edited in the client's unit; stored as kg.
                                      value: targetWeights[index] == null
                                          ? '—'
                                          : _formatNumber(displayWeight(targetWeights[index]!, _unit)),
                                      onMinus: () => setSheetState(() {
                                        final inc = isMetricWeight(_unit) ? 2.5 : 5.0;
                                        final disp = displayWeight(targetWeights[index] ?? 0, _unit) - inc;
                                        targetWeights[index] = disp <= 0
                                            ? null
                                            : weightToKg(disp.clamp(0, 2000).toDouble(), _unit);
                                      }),
                                      onPlus: () => setSheetState(() {
                                        final inc = isMetricWeight(_unit) ? 2.5 : 5.0;
                                        final disp = (displayWeight(targetWeights[index] ?? 0, _unit) + inc)
                                            .clamp(0, 2000)
                                            .toDouble();
                                        targetWeights[index] = weightToKg(disp, _unit);
                                      }),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () => setSheetState(() {
                                exerciseNameControllers.add(TextEditingController());
                                sets.add(3);
                                reps.add(10);
                                targetWeights.add(null);
                              }),
                              icon: const Icon(PhosphorIconsBold.plus, size: 15),
                              style: TextButton.styleFrom(foregroundColor: AppColors.secondaryColor),
                              label: Text(context.l10n.addExercise),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.p12),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(context.l10n.cancel),
                        ),
                      ),
                      SizedBox(width: AppSpacing.p12),
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(ctx, true);
                          },
                          child: Container(
                            height: 50,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.secondaryColor,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              context.l10n.saveWorkout,
                              style: textTheme.titleSmall?.copyWith(
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    final nameValues = exerciseNameControllers.map((c) => c.text.trim()).toList();
    for (final c in exerciseNameControllers) {
      c.dispose();
    }
    final title = titleController.text.trim();
    titleController.dispose();

    if (shouldSave != true) return;
    final exercises = <WorkoutExercise>[];
    for (var i = 0; i < nameValues.length; i++) {
      if (nameValues[i].isEmpty) continue;
      final existing = i < workout.exercises.length ? workout.exercises[i] : null;
      final oldLogs = existing?.loggedRepsBySet ?? const <int>[];
      final oldWeightLogs = existing?.loggedWeightKgBySet ?? const <double?>[];
      final newSets = sets[i];
      final newLogs = oldLogs.length >= newSets
          ? oldLogs.take(newSets).toList()
          : [...oldLogs, ...List.generate(newSets - oldLogs.length, (_) => 0)];
      final newWeightLogs = oldWeightLogs.length >= newSets
          ? oldWeightLogs.take(newSets).toList()
          : [...oldWeightLogs, ...List.generate(newSets - oldWeightLogs.length, (_) => null)];
      exercises.add(
        WorkoutExercise(
          name: nameValues[i],
          sets: newSets,
          reps: reps[i],
          completedSets: newLogs.where((v) => v > 0).length,
          loggedRepsBySet: newLogs,
          targetWeightKgBySet: List.generate(newSets, (_) => targetWeights[i]),
          loggedWeightKgBySet: newWeightLogs,
        ),
      );
    }
    if (title.isEmpty || exercises.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.workoutTitleRequired)),
      );
      return;
    }

    try {
      await _firestoreService.updateAssignedWorkout(
        clientId: workout.clientId,
        date: workout.date,
        title: title,
        exercises: exercises,
      );
      _toast(context.l10n.workoutUpdated);
    } catch (_) {
      _toast(context.l10n.updateWorkoutError);
    }
  }

  Future<void> _confirmDeleteWorkout(AssignedWorkout workout) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final cs = theme.colorScheme;
        final textTheme = theme.textTheme;
        return Dialog(
          backgroundColor: cs.surface,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.statusRed.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.statusRed.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(PhosphorIconsFill.trash, color: AppColors.statusRed, size: 20),
                    ),
                    SizedBox(width: AppSpacing.p12),
                    Expanded(
                      child: Text(
                        context.l10n.removeWorkoutTitle,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.p12),
                Text(
                  context.l10n.removeWorkoutMsg,
                  style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.4),
                ),
                SizedBox(height: AppSpacing.p20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(context.l10n.cancel),
                      ),
                    ),
                    SizedBox(width: AppSpacing.p12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(ctx, true);
                        },
                        child: Container(
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.statusRed,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.statusRed.withValues(alpha: 0.3),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Text(
                            context.l10n.remove,
                            style: textTheme.titleSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    if (shouldDelete != true) return;
    try {
      await _firestoreService.deleteAssignedWorkout(
        clientId: workout.clientId,
        date: workout.date,
      );
      _toast(context.l10n.workoutRemoved);
    } catch (_) {
      _toast(context.l10n.removeWorkoutError);
    }
  }

  // ==========================================
  // CUSTOM HABITS (coach-managed, additive)
  // ==========================================
  Widget _buildHabitsCard(ThemeData theme, ColorScheme colorScheme, AppUser client) {
    final habits = client.customHabits ?? const <HabitDefinition>[];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(colorScheme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(PhosphorIconsBold.listChecks, color: colorScheme.secondary, size: 20),
              const SizedBox(width: 8),
              Text(
                context.l10n.dailyHabits,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (habits.isNotEmpty)
                Text(
                  '${habits.length}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (habits.isEmpty)
            Text(
                            context.l10n.noCustomHabitsBody,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: habits.map((h) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_habitIconData(h.icon), size: 14, color: colorScheme.secondary),
                      const SizedBox(width: 6),
                      Text(
                        h.name,
                        style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => _manageHabits(client),
            child: Container(
              width: double.infinity,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    habits.isEmpty ? PhosphorIconsBold.plus : PhosphorIconsBold.pencilSimple,
                    size: 16,
                    color: colorScheme.onSurface,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    habits.isEmpty ? context.l10n.addHabits : context.l10n.manageHabits,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _manageHabits(AppUser client) async {
    final result = await showModalBottomSheet<List<HabitDefinition>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HabitsManagerSheet(initial: client.customHabits ?? const []),
    );
    if (result == null || !mounted) return;
    try {
      await _firestoreService.setClientHabits(client.uid, result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.habitsUpdated)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.saveHabitsError)),
      );
    }
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
                    context.l10n.macroTargets,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _macroRow(theme, colorScheme, context.l10n.caloriesLabel, '${targets.calories} kcal'),
              const SizedBox(height: 8),
              _macroRow(theme, colorScheme, context.l10n.macroProtein, '${targets.protein} g'),
              const SizedBox(height: 8),
              _macroRow(theme, colorScheme, context.l10n.macroCarbs, '${targets.carbs} g'),
              const SizedBox(height: 8),
              _macroRow(theme, colorScheme, context.l10n.macroFat, '${targets.fat} g'),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _isSavingMacros ? null : () => _configureMacros(client),
                child: Container(
                  width: double.infinity,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.secondaryColor,
                        AppColors.secondaryColor.withValues(alpha: 0.82),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondaryColor.withValues(alpha: 0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: _isSavingMacros
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.2, color: AppColors.primaryColor),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(PhosphorIconsBold.slidersHorizontal,
                                size: 17, color: AppColors.primaryColor),
                            SizedBox(width: AppSpacing.p8),
                            Text(
                              isUnconfigured ? context.l10n.configureMacros : context.l10n.updateMacros,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              if (isUnconfigured) ...[
                const SizedBox(height: 8),
                Text(
                  context.l10n.savingMacrosConfigures,
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildHabitsCard(theme, colorScheme, client),
        const SizedBox(height: 16),
        _buildSectionTitle(
          context.l10n.workoutLogTitle('${_selectedDate.month}/${_selectedDate.day}'),
          theme,
          colorScheme,
          actionText: context.l10n.swapWorkout,
          onActionTap: () => _showSwapWorkoutDialog(client, _selectedDate),
        ),
        const SizedBox(height: 12),
        StreamBuilder<AssignedWorkout?>(
          stream: _assignedWorkoutStreamFor(_selectedDate),
          builder: (context, snapshot) {
            final workout = snapshot.data;
            if (workout == null) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: _cardDecoration(colorScheme),
                child: Text(
                  context.l10n.noWorkoutSelectedDay,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(colorScheme),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(PhosphorIconsFill.barbell, color: colorScheme.secondary, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          workout.title,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...workout.exercises.map((e) {
                    final w = e.targetWeightKgBySet.isNotEmpty ? e.targetWeightKgBySet.first : null;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                e.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _planTag(theme, colorScheme, '${e.sets} × ${e.reps}'),
                            if (w != null) ...[
                              const SizedBox(width: 6),
                              _planTag(theme, colorScheme, _weightStr(w), subtle: true),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: _planActionButton(
                          theme,
                          colorScheme,
                          icon: PhosphorIconsBold.pencilSimple,
                          label: context.l10n.updateBtn,
                          onTap: () => _showEditWorkoutDialog(workout),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _planActionButton(
                          theme,
                          colorScheme,
                          icon: PhosphorIconsBold.trash,
                          label: context.l10n.remove,
                          destructive: true,
                          onTap: () => _confirmDeleteWorkout(workout),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
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

  Widget _planTag(ThemeData theme, ColorScheme cs, String text, {bool subtle = false}) {
    final color = subtle ? cs.onSurfaceVariant : AppColors.secondaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: subtle ? 0.1 : 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: subtle ? 0.2 : 0.3)),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _planActionButton(
    ThemeData theme,
    ColorScheme cs, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    final color = destructive ? AppColors.statusRed : cs.onSurface;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: destructive
              ? AppColors.statusRed.withValues(alpha: 0.08)
              : cs.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: destructive
                ? AppColors.statusRed.withValues(alpha: 0.25)
                : cs.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 7),
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration(ColorScheme colorScheme) {
    return BoxDecoration(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.28)),
      boxShadow: [
        BoxShadow(
          color: colorScheme.shadow.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: colorScheme.shadow.withValues(alpha: 0.02),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }
}

// ===========================================================================
// Coach note editor — shows & edits the existing note for the day (overwrites,
// never appends). Keyed by date so switching days reloads the right note.
// ===========================================================================

class _CoachNoteEditor extends StatefulWidget {
  final ThemeData theme;
  final String? initialNote;
  final String firstName;
  final bool isToday;
  final Future<bool> Function(String text) onSave;

  const _CoachNoteEditor({
    super.key,
    required this.theme,
    required this.initialNote,
    required this.firstName,
    required this.isToday,
    required this.onSave,
  });

  @override
  State<_CoachNoteEditor> createState() => _CoachNoteEditorState();
}

class _CoachNoteEditorState extends State<_CoachNoteEditor> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialNote ?? '');
  late String _saved = (widget.initialNote ?? '').trim();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _hasText => _controller.text.trim().isNotEmpty;
  bool get _dirty => _controller.text.trim() != _saved;

  Future<void> _save() async {
    if (_saving || !_dirty || !_hasText) return;
    HapticFeedback.lightImpact();
    setState(() => _saving = true);
    final ok = await widget.onSave(_controller.text);
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (ok) _saved = _controller.text.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    final hasSaved = _saved.isNotEmpty;
    final canSave = _dirty && _hasText && !_saving;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.28)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(PhosphorIconsFill.notePencil, size: 15, color: AppColors.secondaryColor),
              const SizedBox(width: 6),
              Text(
                hasSaved ? context.l10n.yourNote.toUpperCase() : context.l10n.leaveANote.toUpperCase(),
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.secondaryColor,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  fontSize: 10,
                ),
              ),
              const Spacer(),
              if (hasSaved && !_dirty)
                Row(
                  children: [
                    const Icon(PhosphorIconsFill.checkCircle, size: 13, color: AppColors.statusGreen),
                    const SizedBox(width: 4),
                    Text(
                      context.l10n.savedLabel,
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.statusGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            maxLines: 4,
            minLines: 1,
            onChanged: (_) => setState(() {}),
            style: textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: context.l10n.writeFeedbackFor(widget.firstName),
              filled: true,
              fillColor: cs.surface,
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (!widget.isToday)
                Expanded(
                  child: Text(
                    context.l10n.editingPastDay,
                    style: textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ),
                )
              else
                const Spacer(),
              GestureDetector(
                onTap: canSave ? _save : null,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: canSave ? 1 : 0.5,
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.primaryColor),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                hasSaved ? PhosphorIconsBold.check : PhosphorIconsBold.paperPlaneTilt,
                                size: 14,
                                color: AppColors.primaryColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                hasSaved ? context.l10n.updateNote : context.l10n.saveNote,
                                style: textTheme.labelLarge?.copyWith(
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
        ],
      ),
    );
  }
}

// ===========================================================================
// Swap workout — premium bottom sheet with a tappable template picker.
// Returns the chosen template via Navigator.pop, or null on cancel.
// ===========================================================================

class _SwapWorkoutSheet extends StatefulWidget {
  final List<WorkoutTemplate> templates;
  final String clientName;
  final DateTime date;

  const _SwapWorkoutSheet({
    required this.templates,
    required this.clientName,
    required this.date,
  });

  @override
  State<_SwapWorkoutSheet> createState() => _SwapWorkoutSheetState();
}

class _SwapWorkoutSheetState extends State<_SwapWorkoutSheet> {
  late WorkoutTemplate _selected = widget.templates.first;

  String get _dateLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(widget.date.year, widget.date.month, widget.date.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return context.l10n.relToday;
    if (diff == 1) return context.l10n.relTomorrow;
    if (diff == -1) return context.l10n.relYesterday;
    return '${widget.date.day}/${widget.date.month}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;

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
              context.l10n.swapWorkout.toUpperCase(),
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.secondaryColor,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              context.l10n.forClientDate(widget.clientName, _dateLabel),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            SizedBox(height: AppSpacing.p20),
            _SheetFieldLabel(theme: theme, label: context.l10n.chooseAWorkout.toUpperCase()),
            SizedBox(height: AppSpacing.p8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: widget.templates.length,
                separatorBuilder: (_, _) => SizedBox(height: AppSpacing.p8),
                itemBuilder: (context, index) {
                  final t = widget.templates[index];
                  return _TemplatePick(
                    theme: theme,
                    name: t.name,
                    exerciseCount: t.exercises.length,
                    selected: t.id == _selected.id,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selected = t);
                    },
                  );
                },
              ),
            ),
            if (_selected.exercises.isNotEmpty) ...[
              SizedBox(height: AppSpacing.p20),
              _SheetFieldLabel(theme: theme, label: context.l10n.includesLabel.toUpperCase()),
              SizedBox(height: AppSpacing.p8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 132),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _selected.exercises
                        .map(
                          (e) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: cs.outlineVariant.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              '${e.name} · ${e.sets}×${e.reps}',
                              style: textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ],
            SizedBox(height: AppSpacing.p24),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop(_selected);
              },
              child: Container(
                width: double.infinity,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.secondaryColor,
                      AppColors.secondaryColor.withValues(alpha: 0.82),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondaryColor.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(PhosphorIconsFill.arrowsClockwise,
                        size: 16, color: AppColors.primaryColor),
                    SizedBox(width: AppSpacing.p8),
                    Text(
                      context.l10n.assignWorkoutBtn,
                      style: textTheme.titleMedium?.copyWith(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplatePick extends StatelessWidget {
  final ThemeData theme;
  final String name;
  final int exerciseCount;
  final bool selected;
  final VoidCallback onTap;

  const _TemplatePick({
    required this.theme,
    required this.name,
    required this.exerciseCount,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.secondaryColor.withValues(alpha: 0.12)
              : cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.secondaryColor.withValues(alpha: 0.5)
                : cs.outlineVariant.withValues(alpha: 0.3),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.secondaryColor,
                    AppColors.secondaryColor.withValues(alpha: 0.25),
                  ],
                ),
              ),
              child: CircleAvatar(
                backgroundColor: cs.surface,
                child: const Icon(PhosphorIconsFill.barbell,
                    size: 17, color: AppColors.secondaryColor),
              ),
            ),
            SizedBox(width: AppSpacing.p12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    context.l10n.exerciseCount(exerciseCount),
                    style: textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? PhosphorIconsFill.checkCircle : PhosphorIconsRegular.circle,
              color: selected
                  ? AppColors.secondaryColor
                  : cs.onSurfaceVariant.withValues(alpha: 0.4),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Custom-habit icon set (shared keys with the client home resolver)
// ===========================================================================

const List<String> _habitIconKeys = [
  'footprints', 'drop', 'barbell', 'pill', 'forkKnife',
  'moon', 'heartbeat', 'sun', 'leaf', 'prohibit',
];

IconData _habitIconData(String key) {
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

// ===========================================================================
// Habits manager — add / edit / remove a client's custom habits
// ===========================================================================

class _HabitsManagerSheet extends StatefulWidget {
  final List<HabitDefinition> initial;
  const _HabitsManagerSheet({required this.initial});

  @override
  State<_HabitsManagerSheet> createState() => _HabitsManagerSheetState();
}

class _HabitsManagerSheetState extends State<_HabitsManagerSheet> {
  late final List<HabitDefinition> _habits = List.of(widget.initial);
  final _nameController = TextEditingController();
  String _icon = _habitIconKeys.first;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _add() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _habits.add(HabitDefinition(
        id: DateTime.now().microsecondsSinceEpoch.toRadixString(36),
        name: name,
        icon: _icon,
      ));
      _nameController.clear();
    });
  }

  void _remove(String id) {
    HapticFeedback.selectionClick();
    setState(() => _habits.removeWhere((h) => h.id == id));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(context.l10n.dailyHabits, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              context.l10n.habitsManagerBody,
              style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            if (_habits.isNotEmpty) ...[
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _habits.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final h = _habits[i];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: AppColors.secondaryColor.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(_habitIconData(h.icon),
                                size: 17, color: AppColors.secondaryColor),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              h.name,
                              style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _remove(h.id),
                            icon: const Icon(PhosphorIconsBold.trash,
                                size: 18, color: AppColors.statusRed),
                            splashRadius: 20,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              context.l10n.addAHabit.toUpperCase(),
              style: textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _habitIconKeys.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final key = _habitIconKeys[i];
                  final sel = key == _icon;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _icon = key);
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: sel
                            ? AppColors.secondaryColor.withValues(alpha: 0.16)
                            : cs.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: sel
                              ? AppColors.secondaryColor.withValues(alpha: 0.5)
                              : cs.outlineVariant.withValues(alpha: 0.3),
                          width: sel ? 1.5 : 1,
                        ),
                      ),
                      child: Icon(_habitIconData(key),
                          size: 19, color: sel ? AppColors.secondaryColor : cs.onSurfaceVariant),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _add(),
                    decoration: InputDecoration(hintText: context.l10n.habitNameHint, isDense: true),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _add,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(PhosphorIconsBold.plus, color: AppColors.primaryColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(_habits),
              child: Container(
                width: double.infinity,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.secondaryColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondaryColor.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Text(
                  context.l10n.saveHabits,
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetFieldLabel extends StatelessWidget {
  final ThemeData theme;
  final String label;

  const _SheetFieldLabel({required this.theme, required this.label});

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
        Expanded(
          child: Divider(
            height: 1,
            color: cs.outlineVariant.withValues(alpha: 0.25),
          ),
        ),
      ],
    );
  }
}
