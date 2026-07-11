import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:valence/l10n/l10n_ext.dart';
import 'package:valence/models/user_model.dart';
import 'package:valence/models/workout_models.dart';
import 'package:valence/providers/auth_provider.dart';
import 'package:valence/services/firestore_service.dart';
import 'package:valence/theme/app_theme.dart';
import 'package:valence/pages/coach/template_editor_screen.dart';

/// Library tab — the coach's reusable workout templates. Each card shows
/// Exercises/Sets/Reps stat chips with a gold Assign action (opens
/// AssignWorkoutSheet for single-day or weekly recurring assignment) and a
/// neutral Edit (full-screen TemplateEditorScreen). Assigning COPIES the
/// template into per-day docs, so editing a template later never changes
/// workouts already on a client's calendar.
class CoachWorkoutLibraryScreen extends StatefulWidget {
  const CoachWorkoutLibraryScreen({super.key});

  @override
  State<CoachWorkoutLibraryScreen> createState() => _CoachWorkoutLibraryScreenState();
}

class _CoachWorkoutLibraryScreenState extends State<CoachWorkoutLibraryScreen> {
  final _firestoreService = FirestoreService();

  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Cache the streams so rebuilds (e.g. typing in search) don't recreate them —
  // recreating would reset StreamBuilder to "waiting" and flash the skeleton on
  // every keystroke. Tracks which cards have already animated in so searching
  // never re-triggers the staggered entrance.
  Stream<List<AppUser>>? _clientsStream;
  Stream<List<WorkoutTemplate>>? _templatesStream;
  String? _streamCoachId;
  final Set<String> _seenTemplateIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showEditTemplateDialog(WorkoutTemplate template) async {
    final coachId = context.read<AuthProvider>().currentUser?.uid;
    if (coachId == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TemplateEditorScreen(coachId: coachId, template: template),
      ),
    );
  }

  Future<void> _showCreateTemplateDialog(String coachId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TemplateEditorScreen(coachId: coachId),
      ),
    );
  }

  Future<void> _confirmDeleteTemplate(WorkoutTemplate template) async {
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
                        context.l10n.deleteTemplateTitle,
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
                  context.l10n.deleteTemplateMsg(template.name),
                  style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.4),
                ),
                SizedBox(height: AppSpacing.p20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: Text(context.l10n.cancel),
                      ),
                    ),
                    SizedBox(width: AppSpacing.p12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(ctx).pop(true);
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
                            context.l10n.delete,
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
      await _firestoreService.deleteWorkoutTemplate(template.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.templateDeleted)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.deleteTemplateError)),
      );
    }
  }

  Future<void> _showAssignDialog(
    WorkoutTemplate template,
    List<AppUser> clients,
    String coachId,
  ) async {
    if (clients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.noClientsToAssign)),
      );
      return;
    }
    final result = await showModalBottomSheet<AssignResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AssignWorkoutSheet(template: template, clients: clients),
    );
    if (result == null || !mounted) return;
    final name = clients
        .firstWhere((c) => c.uid == result.clientId, orElse: () => clients.first)
        .name;
    try {
      final count = await _firestoreService.assignWorkoutToClientDates(
        coachId: coachId,
        clientId: result.clientId,
        dates: result.dates,
        title: template.name,
        exercises: template.exercises,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count > 1 ? context.l10n.assignedDays(count, name) : context.l10n.assignedToName(name),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.assignError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    final coach = context.watch<AuthProvider>().currentUser;
    if (coach == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final coachId = coach.uid;
    if (_streamCoachId != coachId) {
      _streamCoachId = coachId;
      _clientsStream = _firestoreService.streamClientsByCoach(coachId);
      _templatesStream = _firestoreService.streamWorkoutTemplates(coachId);
    }

    return StreamBuilder<List<AppUser>>(
      stream: _clientsStream,
      builder: (context, clientsSnapshot) {
        final clients = clientsSnapshot.data ?? const <AppUser>[];
        return StreamBuilder<List<WorkoutTemplate>>(
          stream: _templatesStream,
          builder: (context, snapshot) {
            final loading = snapshot.connectionState == ConnectionState.waiting;
            final templates = snapshot.data ?? const <WorkoutTemplate>[];
            final query = _searchQuery.trim().toLowerCase();
            final visible = query.isEmpty
                ? templates
                : templates
                    .where((t) => t.name.toLowerCase().contains(query))
                    .toList();
            return Scaffold(
              backgroundColor: cs.surface,
              floatingActionButton: templates.isEmpty
                  ? null
                  : _NewTemplateFab(
                      theme: theme,
                      onPressed: () => _showCreateTemplateDialog(coach.uid),
                    ),
              body: _LibraryGlow(
                child: SafeArea(
                  bottom: false,
                  child: loading
                      ? _LibrarySkeleton(theme: theme)
                      : CustomScrollView(
                          physics: const BouncingScrollPhysics(),
                          slivers: [
                            SliverToBoxAdapter(
                              child: _LibraryHeader(theme: theme, count: templates.length),
                            ),
                            if (templates.isNotEmpty)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(
                                      AppSpacing.p16, 0, AppSpacing.p16, AppSpacing.p12),
                                  child: _SearchBar(
                                    theme: theme,
                                    controller: _searchController,
                                    onChanged: (v) => setState(() => _searchQuery = v),
                                    onClear: () => setState(() {
                                      _searchController.clear();
                                      _searchQuery = '';
                                    }),
                                  ),
                                ),
                              ),
                            if (templates.isEmpty)
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: _LibraryEmpty(
                                  theme: theme,
                                  onCreate: () => _showCreateTemplateDialog(coach.uid),
                                ),
                              )
                            else if (visible.isEmpty)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.all(AppSpacing.p32),
                                  child: Center(
                                    child: Text(
                                      context.l10n.noTemplatesMatch(_searchQuery.trim()),
                                      textAlign: TextAlign.center,
                                      style: textTheme.bodyMedium
                                          ?.copyWith(color: cs.onSurfaceVariant),
                                    ),
                                  ),
                                ),
                              )
                            else
                              SliverPadding(
                                padding: EdgeInsets.fromLTRB(
                                  AppSpacing.p16,
                                  AppSpacing.p4,
                                  AppSpacing.p16,
                                  100,
                                ),
                                // One grouped surface for the whole library —
                                // same calm-row recipe as the roster. Tap = edit,
                                // gold Assign = the row's single action,
                                // long-press = delete.
                                sliver: SliverToBoxAdapter(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: cs.surfaceContainerLow,
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(
                                          color: cs.outlineVariant.withValues(alpha: 0.28)),
                                      boxShadow: [
                                        BoxShadow(
                                          color: cs.shadow.withValues(alpha: 0.05),
                                          blurRadius: 18,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    child: Column(
                                      children: [
                                        for (var index = 0; index < visible.length; index++) ...[
                                          if (index > 0)
                                            Padding(
                                              padding: const EdgeInsetsDirectional.only(start: 10),
                                              child: Divider(
                                                color: cs.outlineVariant.withValues(alpha: 0.18),
                                                height: 1,
                                                thickness: 1,
                                              ),
                                            ),
                                          Builder(builder: (context) {
                                            final template = visible[index];
                                            final firstSeen = _seenTemplateIds.add(template.id);
                                            return _EntranceFade(
                                              key: ValueKey(template.id),
                                              index: index,
                                              animate: firstSeen,
                                              child: _TemplateCard(
                                                theme: theme,
                                                template: template,
                                                onAssign: () =>
                                                    _showAssignDialog(template, clients, coach.uid),
                                                onEdit: () => _showEditTemplateDialog(template),
                                                onDelete: () => _confirmDeleteTemplate(template),
                                              ),
                                            );
                                          }),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Header.
// ---------------------------------------------------------------------------

class _LibraryHeader extends StatelessWidget {
  final ThemeData theme;
  final int count;

  const _LibraryHeader({required this.theme, required this.count});

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.p16, AppSpacing.p20, AppSpacing.p16, AppSpacing.p16),
      child: Row(
        children: [
          _GoldRing(
            size: 46,
            child: Icon(PhosphorIconsFill.barbell, color: AppColors.secondaryColor, size: 20),
          ),
          SizedBox(width: AppSpacing.p12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.yourLibrary.toUpperCase(),
                  style: textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                    fontSize: 10,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  context.l10n.workoutPlansTitle,
                  style: textTheme.titleLarge?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
          ),
          if (count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.secondaryColor.withValues(alpha: 0.18),
                    AppColors.secondaryColor.withValues(alpha: 0.07),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.secondaryColor.withValues(alpha: 0.32)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondaryColor.withValues(alpha: 0.14),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(PhosphorIconsFill.cards, color: AppColors.secondaryColor, size: 14),
                  SizedBox(width: AppSpacing.p4 + 1),
                  Text(
                    '$count',
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.secondaryColor,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Template card.
// ---------------------------------------------------------------------------

class _TemplateCard extends StatefulWidget {
  final ThemeData theme;
  final WorkoutTemplate template;
  final VoidCallback onAssign;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TemplateCard({
    required this.theme,
    required this.template,
    required this.onAssign,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_TemplateCard> createState() => _TemplateCardState();
}

// A calm row: name + one quiet stats line, a single gold Assign action.
// Tap opens the editor; long-press deletes (with the existing confirm).
class _TemplateCardState extends State<_TemplateCard> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v && mounted) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    final template = widget.template;
    final exCount = template.exercises.length;
    final totalSets = template.exercises.fold<int>(0, (sum, e) => sum + e.sets);
    final totalReps =
        template.exercises.fold<int>(0, (sum, e) => sum + e.sets * e.reps);

    final muted = textTheme.labelSmall?.copyWith(
      color: cs.onSurfaceVariant.withValues(alpha: 0.5),
      fontWeight: FontWeight.w500,
      fontSize: 11,
    );
    final value = textTheme.labelSmall?.copyWith(
      color: cs.onSurface.withValues(alpha: 0.75),
      fontWeight: FontWeight.w700,
      fontSize: 11,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onEdit();
      },
      onLongPress: widget.onDelete,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
        decoration: BoxDecoration(
          color: _pressed ? cs.onSurface.withValues(alpha: 0.035) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(text: '$exCount ', style: value),
                      TextSpan(text: context.l10n.statExercises, style: muted),
                      TextSpan(text: '   ·   ', style: muted),
                      TextSpan(text: '$totalSets ', style: value),
                      TextSpan(text: context.l10n.statSets, style: muted),
                      TextSpan(text: '   ·   ', style: muted),
                      TextSpan(text: '$totalReps ', style: value),
                      TextSpan(text: context.l10n.statReps, style: muted),
                    ]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: AppSpacing.p12),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onAssign();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.l10n.assign,
                      style: textTheme.labelMedium?.copyWith(
                        color: AppColors.secondaryColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(PhosphorIconsBold.arrowRight,
                        size: 12, color: AppColors.secondaryColor),
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

class _NewTemplateFab extends StatelessWidget {
  final ThemeData theme;
  final VoidCallback onPressed;

  const _NewTemplateFab({required this.theme, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondaryColor.withValues(alpha: 0.32),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        backgroundColor: AppColors.secondaryColor,
        foregroundColor: AppColors.primaryColor,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        icon: Icon(PhosphorIconsBold.plus, size: 18, color: AppColors.primaryColor),
        label: Text(
          context.l10n.newTemplate,
          style: theme.textTheme.labelLarge?.copyWith(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state.
// ---------------------------------------------------------------------------

class _LibraryEmpty extends StatelessWidget {
  final ThemeData theme;
  final VoidCallback onCreate;

  const _LibraryEmpty({required this.theme, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.p32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.secondaryColor.withValues(alpha: 0.18),
                    AppColors.secondaryColor.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.secondaryColor.withValues(alpha: 0.25)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondaryColor.withValues(alpha: 0.12),
                    blurRadius: 22,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(PhosphorIconsFill.barbell, color: AppColors.secondaryColor, size: 34),
            ),
            SizedBox(height: AppSpacing.p20),
            Text(
              context.l10n.buildFirstPlan,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            SizedBox(height: AppSpacing.p8),
            Text(
              context.l10n.buildFirstPlanBody,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            SizedBox(height: AppSpacing.p24),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onCreate();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
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
                      blurRadius: 16,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(PhosphorIconsBold.plus, size: 16, color: AppColors.primaryColor),
                    SizedBox(width: AppSpacing.p8),
                    Text(
                      context.l10n.createTemplate,
                      style: textTheme.labelLarge?.copyWith(
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

// ---------------------------------------------------------------------------
// Shared bits.
// ---------------------------------------------------------------------------

class _LibraryGlow extends StatelessWidget {
  final Widget child;
  const _LibraryGlow({required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.7, -1.0),
          radius: 1.1,
          colors: [
            AppColors.secondaryColor.withValues(alpha: 0.10),
            AppColors.secondaryColor.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.7],
        ),
      ),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Search — filter the library by template name.
// ---------------------------------------------------------------------------

class _SearchBar extends StatelessWidget {
  final ThemeData theme;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.theme,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    final hasText = controller.text.isNotEmpty;
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(PhosphorIconsRegular.magnifyingGlass, size: 18, color: cs.onSurfaceVariant),
          SizedBox(width: AppSpacing.p8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: textTheme.bodyMedium,
              cursorColor: AppColors.secondaryColor,
              decoration: InputDecoration(
                isCollapsed: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: context.l10n.searchTemplates,
                hintStyle: textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
          if (hasText)
            GestureDetector(
              onTap: onClear,
              child: Icon(PhosphorIconsFill.xCircle, size: 18, color: cs.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}

class _GoldRing extends StatelessWidget {
  final double size;
  final Widget child;

  const _GoldRing({required this.size, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppColors.secondaryColor,
            AppColors.secondaryColor.withValues(alpha: 0.25),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: CircleAvatar(backgroundColor: cs.surface, child: child),
    );
  }
}

class _EntranceFade extends StatefulWidget {
  final int index;
  final bool animate;
  final Widget child;
  const _EntranceFade({
    super.key,
    required this.index,
    this.animate = true,
    required this.child,
  });

  @override
  State<_EntranceFade> createState() => _EntranceFadeState();
}

class _EntranceFadeState extends State<_EntranceFade> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final Animation<double> _fade =
      CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.05),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    if (!widget.animate) {
      _controller.value = 1.0;
      return;
    }
    final delayMs = (widget.index.clamp(0, 8)) * 55;
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

class _LibrarySkeleton extends StatefulWidget {
  final ThemeData theme;
  const _LibrarySkeleton({required this.theme});

  @override
  State<_LibrarySkeleton> createState() => _LibrarySkeletonState();
}

class _LibrarySkeletonState extends State<_LibrarySkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
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
    final highlight = cs.surfaceContainerHighest.withValues(alpha: 0.95);

    final content = ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(AppSpacing.p16, AppSpacing.p20, AppSpacing.p16, 0),
      children: [
        Row(
          children: [
            _box(44, 44, radius: 23),
            SizedBox(width: AppSpacing.p12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _box(90, 10),
                SizedBox(height: AppSpacing.p8),
                _box(140, 20),
              ],
            ),
          ],
        ),
        SizedBox(height: AppSpacing.p24),
        for (var i = 0; i < 4; i++) ...[
          _box(double.infinity, 150, radius: 22),
          SizedBox(height: AppSpacing.p12),
        ],
      ],
    );

    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final dx = _c.value * 3 - 1.5;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(dx - 0.6, 0),
            end: Alignment(dx + 0.6, 0),
            colors: [base, highlight, base],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(bounds),
          child: child,
        );
      },
      child: content,
    );
  }

  Widget _box(double w, double h, {double radius = 7}) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}
