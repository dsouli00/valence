import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:valence/l10n/l10n_ext.dart';
import 'package:valence/models/user_model.dart';
import 'package:valence/models/workout_models.dart';
import 'package:valence/providers/auth_provider.dart';
import 'package:valence/services/firestore_service.dart';
import 'package:valence/ui/ui.dart';
import 'package:valence/pages/coach/template_editor_screen.dart';

/// Library tab — the coach's reusable workout templates. Each row shows a
/// quiet Exercises/Sets/Reps stats line with a gold Assign action (opens
/// AssignWorkoutSheet for single-day or weekly recurring assignment); tapping
/// a row opens the full-screen TemplateEditorScreen. Assigning COPIES the
/// template into per-day docs, so editing a template later never changes
/// workouts already on a client's calendar.
///
/// DESIGN: reskinned to design system v2.2 (design.md §5.13, archetype B):
/// VHeader → VSearchBar → one VGroupCard with a VListHeader whose "+ New"
/// VMiniPill replaces the FAB (deleted per §6.6). Rows = squircle identity
/// avatar · name · VQuietStats · trailing "Assign" VMiniPill. Delete confirm
/// is a VSheet; toasts replace snackbars. Logic and streams untouched.
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
    final shouldDelete = await showVSheet<bool>(
      context: context,
      builder: (ctx) {
        final t = ctx.tokens;
        return VSheet(
          title: ctx.l10n.deleteTemplateTitle,
          scrollable: false,
          pinnedAction: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              VPillButton.destructive(
                label: ctx.l10n.delete,
                solid: true,
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
              const SizedBox(height: 8),
              VPillButton.secondary(
                label: ctx.l10n.cancel,
                onPressed: () => Navigator.of(ctx).pop(false),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.only(bottom: 8),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                ctx.l10n.deleteTemplateMsg(template.name),
                style: VType.body.copyWith(color: t.inkSecondary),
              ),
            ),
          ),
        );
      },
    );
    if (shouldDelete != true) return;
    try {
      await _firestoreService.deleteWorkoutTemplate(template.id);
      if (!mounted) return;
      showVToast(context, context.l10n.templateDeleted);
    } catch (_) {
      if (!mounted) return;
      showVToast(context, context.l10n.deleteTemplateError);
    }
  }

  Future<void> _showAssignDialog(
    WorkoutTemplate template,
    List<AppUser> clients,
    String coachId,
  ) async {
    if (clients.isEmpty) {
      showVToast(context, context.l10n.noClientsToAssign);
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
      showVToast(
        context,
        count > 1 ? context.l10n.assignedDays(count, name) : context.l10n.assignedToName(name),
      );
    } catch (_) {
      if (!mounted) return;
      showVToast(context, context.l10n.assignError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final coach = context.watch<AuthProvider>().currentUser;
    if (coach == null) {
      return Scaffold(
        backgroundColor: t.canvas,
        body: const Center(child: CircularProgressIndicator()),
      );
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
                    .where((tpl) => tpl.name.toLowerCase().contains(query))
                    .toList();
            return Scaffold(
              backgroundColor: t.canvas,
              body: SafeArea(
                bottom: false,
                child: loading
                    ? const _LibrarySkeleton()
                    : CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: VHeader(
                              title: context.l10n.workoutPlansTitle,
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  VSpace.screenMargin, 12, VSpace.screenMargin, 0),
                            ),
                          ),
                          if (templates.isNotEmpty)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    VSpace.screenMargin, 18, VSpace.screenMargin, 0),
                                child: VSearchBar(
                                  controller: _searchController,
                                  hint: context.l10n.searchTemplates,
                                  onChanged: (v) => setState(() => _searchQuery = v),
                                ),
                              ),
                            ),
                          if (templates.isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: VEmpty(
                                icon: PhosphorIconsRegular.barbell,
                                title: context.l10n.buildFirstPlan,
                                message: context.l10n.buildFirstPlanBody,
                                actionLabel: context.l10n.createTemplate,
                                onAction: () => _showCreateTemplateDialog(coach.uid),
                              ),
                            )
                          else if (visible.isEmpty)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    VSpace.screenMargin, 40, VSpace.screenMargin, 0),
                                child: Center(
                                  child: Text(
                                    context.l10n.noTemplatesMatch(_searchQuery.trim()),
                                    textAlign: TextAlign.center,
                                    style: VType.body.copyWith(color: t.inkSecondary),
                                  ),
                                ),
                              ),
                            )
                          else
                            SliverPadding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                VSpace.screenMargin,
                                20,
                                VSpace.screenMargin,
                                VSpace.scrollBottom + 72,
                              ),
                              // One grouped surface for the whole library — same
                              // calm-row recipe as the roster. Tap = edit, gold
                              // Assign = the row's single action, long-press =
                              // delete. The VListHeader's "+ New" pill replaces
                              // the FAB (deleted — design.md §6.6).
                              sliver: SliverToBoxAdapter(
                                child: VGroupCard(
                                  header: VListHeader(
                                    title: context.l10n.navLibrary,
                                    count: visible.length,
                                    trailing: VMiniPill(
                                      icon: PhosphorIconsBold.plus,
                                      label: context.l10n.newTemplate,
                                      onTap: () => _showCreateTemplateDialog(coach.uid),
                                    ),
                                  ),
                                  children: [
                                    for (var index = 0; index < visible.length; index++)
                                      Builder(
                                        key: ValueKey(visible[index].id),
                                        builder: (context) {
                                          final template = visible[index];
                                          final firstSeen =
                                              _seenTemplateIds.add(template.id);
                                          return _EntranceFade(
                                            index: index,
                                            animate: firstSeen,
                                            child: _TemplateRow(
                                              template: template,
                                              onAssign: () => _showAssignDialog(
                                                  template, clients, coach.uid),
                                              onEdit: () =>
                                                  _showEditTemplateDialog(template),
                                              onDelete: () =>
                                                  _confirmDeleteTemplate(template),
                                            ),
                                          );
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            ),
                        ],
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
// Template row — squircle identity avatar (things are squircles, §2) · name ·
// naked stat clusters (exercises / sets / reps) · a gold COMPOSITION BAR (one
// segment per exercise, width ∝ its sets) — the template's fingerprint, same
// family language as the roster's pillar bars. Trailing gold Assign pill.
// Tap = edit, long-press = delete confirm.
// ---------------------------------------------------------------------------

class _TemplateRow extends StatelessWidget {
  final WorkoutTemplate template;
  final VoidCallback onAssign;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TemplateRow({
    required this.template,
    required this.onAssign,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = context.l10n;
    final exCount = template.exercises.length;
    final totalSets = template.exercises.fold<int>(0, (sum, e) => sum + e.sets);
    final totalReps =
        template.exercises.fold<int>(0, (sum, e) => sum + e.sets * e.reps);

    final tint = t.identityTint(template.name);

    return VPressable(
      onTap: onEdit,
      onLongPress: onDelete,
      overlay: true,
      overlayRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
            12, VSpace.rowVPad, 8, VSpace.rowVPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Workout-type glyph in an identity-tinted squircle — inferred
                // from the name (barbell fallback). Tinted icon squircles are
                // the emoji replacement (§1.6); letters read anonymous here.
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: t.tintFill(tint),
                    borderRadius: BorderRadius.circular(VRadius.squircle),
                  ),
                  child: Icon(
                    _workoutGlyph(template.name),
                    size: 19,
                    color: t.legibleTint(tint),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    template.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: VType.headline.copyWith(color: t.ink),
                  ),
                ),
                const SizedBox(width: 10),
                VMiniPill(label: l.assign, onTap: onAssign),
              ],
            ),
            // Fingerprint spans the full row width, inset to the text start —
            // naked numbers over the composition bar (roster-row geometry).
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 52),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Intrinsic widths spread edge-to-edge — equal thirds
                  // truncated the longest label ("1 Exerci…") and read as
                  // drifting right.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: _StatCluster(
                          icon: PhosphorIconsFill.listBullets,
                          tint: t.teal,
                          value: '$exCount',
                          label: l.statExercises,
                        ),
                      ),
                      Flexible(
                        child: _StatCluster(
                          icon: PhosphorIconsFill.stackSimple,
                          tint: t.steel,
                          value: '$totalSets',
                          label: l.statSets,
                        ),
                      ),
                      Flexible(
                        child: _StatCluster(
                          icon: PhosphorIconsFill.arrowsClockwise,
                          tint: t.sage,
                          value: '$totalReps',
                          label: l.statReps,
                        ),
                      ),
                    ],
                  ),
                  if (template.exercises.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _CompositionBar(exercises: template.exercises),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Best-effort workout-type glyph from the template's name — common training
/// words (a few languages included) map to a Phosphor glyph; everything else
/// falls back to the barbell. Purely decorative, so a miss is harmless.
IconData _workoutGlyph(String name) {
  final n = name.toLowerCase();
  bool has(List<String> words) => words.any(n.contains);

  if (has(['run', 'sprint', 'cardio', 'hiit', 'conditioning', 'course', 'correr', 'lauf'])) {
    return PhosphorIconsFill.personSimpleRun;
  }
  if (has(['bike', 'cycle', 'spin', 'vélo', 'velo', 'bici', 'rad'])) {
    return PhosphorIconsFill.personSimpleBike;
  }
  if (has(['swim', 'nage', 'nata', 'schwimm'])) {
    return PhosphorIconsFill.personSimpleSwim;
  }
  if (has(['box', 'mma', 'kick', 'fight'])) {
    return PhosphorIconsFill.boxingGlove;
  }
  if (has(['yoga', 'stretch', 'mobility', 'flex', 'recovery', 'étirement'])) {
    return PhosphorIconsFill.personSimpleTaiChi;
  }
  if (has(['walk', 'steps', 'marche', 'caminar', 'geh'])) {
    return PhosphorIconsFill.footprints;
  }
  if (has(['core', 'abs', 'plank', 'gainage'])) {
    return PhosphorIconsFill.target;
  }
  if (has(['heart', 'endurance'])) {
    return PhosphorIconsFill.heartbeat;
  }
  return PhosphorIconsFill.barbell;
}

/// One naked stat: tinted glyph · bold tabular number · quiet label, centered
/// inside its third so the summary line reads as an even, balanced strip.
class _StatCluster extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final String value;
  final String label;

  const _StatCluster({
    required this.icon,
    required this.tint,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 13, color: t.legibleTint(tint)),
        const SizedBox(width: 5),
        Text(
          value,
          style: VType.stat(15).copyWith(color: t.ink, height: 1.0),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: VType.caption.copyWith(color: t.inkSecondary, height: 1.0),
          ),
        ),
      ],
    );
  }
}

/// The template's shape at a glance: an h3 gold bar split into one segment per
/// exercise, each segment's width proportional to its set count (charts are
/// gold — §1.1). A 4-exercise, even-split day reads instantly different from
/// one long circuit.
class _CompositionBar extends StatelessWidget {
  final List<WorkoutExercise> exercises;

  const _CompositionBar({required this.exercises});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SizedBox(
      height: 3,
      child: Row(
        children: [
          for (var i = 0; i < exercises.length; i++) ...[
            if (i > 0) const SizedBox(width: 2),
            Expanded(
              flex: exercises[i].sets < 1 ? 1 : exercises[i].sets,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: t.gold,
                  borderRadius: BorderRadius.circular(VRadius.pill),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Staggered entrance (design.md §1.7-①): one-time fade + rise, 40ms/index,
// cap 8, never re-triggers on search (the seen-set gates `animate`).
// ---------------------------------------------------------------------------

class _EntranceFade extends StatefulWidget {
  final int index;
  final bool animate;
  final Widget child;
  const _EntranceFade({
    required this.index,
    this.animate = true,
    required this.child,
  });

  @override
  State<_EntranceFade> createState() => _EntranceFadeState();
}

class _EntranceFadeState extends State<_EntranceFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: VDuration.entrance,
  );
  late final Animation<double> _fade =
      CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.05),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: VMotion.curve));

  @override
  void initState() {
    super.initState();
    if (!widget.animate) {
      _controller.value = 1.0;
      return;
    }
    final delayMs = (widget.index.clamp(0, 8)) * 40;
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduce Motion → land instantly (design.md §1.7).
    if (MediaQuery.of(context).disableAnimations) _controller.value = 1.0;
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

// ---------------------------------------------------------------------------
// Skeleton loading — mirrors the real layout (header · search · rows).
// ---------------------------------------------------------------------------

class _LibrarySkeleton extends StatelessWidget {
  const _LibrarySkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsetsDirectional.fromSTEB(
          VSpace.screenMargin, 16, VSpace.screenMargin, 0),
      children: [
        const VSkeleton(width: 190, height: 26, radius: 8),
        const SizedBox(height: 20),
        const VSkeleton(height: 48, radius: 16),
        const SizedBox(height: 24),
        for (var i = 0; i < 5; i++) ...[
          Row(
            children: [
              const VSkeleton(width: 40, height: 40, radius: VRadius.squircle),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    VSkeleton(width: 140, height: 14),
                    SizedBox(height: 8),
                    VSkeleton(width: 200, height: 11),
                  ],
                ),
              ),
              const VSkeleton(width: 64, height: 30, radius: VRadius.pill),
            ],
          ),
          const SizedBox(height: 22),
        ],
      ],
    );
  }
}
