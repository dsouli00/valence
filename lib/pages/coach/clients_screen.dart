import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:valence/l10n/app_localizations.dart';
import 'package:valence/l10n/l10n_ext.dart';
import 'package:valence/models/enums.dart';
import 'package:valence/models/user_model.dart';
import 'package:valence/pages/coach/client_details_screen.dart';
import 'package:valence/providers/auth_provider.dart';
import 'package:valence/services/firestore_service.dart';
import 'package:valence/ui/ui.dart';

/// The coach's home: the client roster, sorted by risk so the people who
/// need attention surface first. Layout (LOCKED — design.md §5.11): greeting
/// header → Roster Pulse (health bar + legend) → search → status filter →
/// grouped client list.
///
/// DESIGN NOTE: this screen is reskinned to design system v2.2 (design.md
/// §5.11, archetype A). The old "alive premium" language (gradient rings,
/// ambient glow, container-color chips, two-layer shadows) is RETIRED — it is
/// now flat warm-paper V-core: `surface` cards on flat `canvas`, ink structure,
/// gold as identity, status color said ONCE per row (the trailing VStatusPill,
/// whose `alert` dot is the app's only looping animation). Layout/IA and all
/// data logic (5-bucket truth model, sort, stream caching) are unchanged.
///
/// Status meta everywhere on the coach side: atRisk="Alert"/alert,
/// slipping="Watch"/watch, onTrack="Good"/good, unconfigured="Setup"/neutral.
class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final _firestoreService = FirestoreService();
  final Set<String> _deletingClientIds = {};

  _RosterBucket? _bucketFilter;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Cache the roster stream so rebuilds (e.g. typing in search) don't recreate
  // it — recreating would reset StreamBuilder to "waiting" and flash the
  // skeleton on every keystroke. Tracks which cards have already animated in
  // so filtering/searching never re-triggers the staggered entrance.
  Stream<List<AppUser>>? _clientsStream;
  String? _streamCoachId;
  final Set<String> _seenClientIds = {};

  /// Drops the cached stream so the next build re-subscribes, and waits on a
  /// fresh read so the spinner reports a real server round-trip rather than
  /// performing one. A stream that is still the same object would not
  /// re-subscribe at all, which is why this cannot just await a delay.
  Future<void> _refresh(String coachId) async {
    if (mounted) setState(() => _clientsStream = null);
    try {
      await _firestoreService
          .streamClientsByCoach(coachId)
          .first
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      // Whatever went wrong, the StreamBuilder reports it — and its message
      // now carries a Try again that can actually be pressed.
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Removes a client and ALL their data (logs + workouts + user doc) after
  /// confirmation. Also queues an admin task so the orphaned Firebase Auth
  /// account can be cleaned up server-side (the coach can't delete another
  /// user's auth account from the client SDK).
  Future<void> _confirmAndDeleteClient(AppUser client) async {
    final coachId = context.read<AuthProvider>().currentUser?.uid;
    final shouldDelete = await showVSheet<bool>(
      context: context,
      builder: (ctx) {
        final t = ctx.tokens;
        return VSheet(
          title: context.l10n.removeClientTitle,
          scrollable: false,
          pinnedAction: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              VPillButton.destructive(
                label: context.l10n.remove,
                solid: true,
                onPressed: () => Navigator.pop(ctx, true),
              ),
              const SizedBox(height: 8),
              VPillButton.secondary(
                label: context.l10n.cancel,
                onPressed: () => Navigator.pop(ctx, false),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.only(bottom: 8),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                context.l10n.removeClientMsg(client.name),
                style: VType.body.copyWith(color: t.inkSecondary),
              ),
            ),
          ),
        );
      },
    );

    if (shouldDelete != true) return;
    setState(() => _deletingClientIds.add(client.uid));
    try {
      await _firestoreService.deleteClientCompletely(
        client.uid,
        requestedByCoachId: coachId,
      );
      if (!mounted) return;
      showVToast(context, context.l10n.clientRemoved(client.name));
    } catch (_) {
      if (!mounted) return;
      showVToast(context, context.l10n.removeClientError);
    } finally {
      if (mounted) setState(() => _deletingClientIds.remove(client.uid));
    }
  }

  void _openDetails(AppUser client, {int tab = 0}) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ClientDetailsScreen(client: client, initialTabIndex: tab),
      ),
    );
  }

  Future<void> _showClientActions(AppUser client) async {
    HapticFeedback.selectionClick();
    final isSetup = _bucketOf(client) == _RosterBucket.setup;
    // Focus first: the sheet returns focus to the search field on dismiss,
    // popping the keyboard again — which is the trap in finding 40. Dropping
    // focus before the sheet opens means dismissing it lands you back on a
    // quiet screen.
    FocusScope.of(context).unfocus();
    await showVSheet<void>(
      context: context,
      builder: (ctx) => VSheet(
        // Names the client. Long-pressing a row gave View details / Edit macros
        // / REMOVE CLIENT with nothing on screen saying who — on a thirty-client
        // roster you can mis-press and be looking at an irreversible action
        // against an unnamed target. The meal-actions sheet already does this.
        title: client.name,
        scrollable: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            VSheetAction(
              icon: PhosphorIconsRegular.eye,
              label: context.l10n.viewDetails,
              onTap: () {
                Navigator.pop(ctx);
                _openDetails(client);
              },
            ),
            VSheetAction(
              icon: PhosphorIconsRegular.slidersHorizontal,
              label: isSetup
                  ? context.l10n.configurePlan
                  : context.l10n.editMacros,
              onTap: () {
                Navigator.pop(ctx);
                _openDetails(client, tab: 2);
              },
            ),
            VSheetAction(
              icon: PhosphorIconsRegular.trash,
              label: context.l10n.removeClient,
              destructive: true,
              onTap: () {
                Navigator.pop(ctx);
                _confirmAndDeleteClient(client);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final coach = context.watch<AuthProvider>().currentUser;
    final coachId = coach?.uid;

    if (coachId == null) {
      return Scaffold(
        backgroundColor: t.canvas,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_clientsStream == null || _streamCoachId != coachId) {
      _streamCoachId = coachId;
      _clientsStream = _firestoreService.streamClientsByCoach(coachId);
    }
    Future<void> refresh() => _refresh(coachId);

    final firstName = (coach?.name ?? context.l10n.coachWord)
        .trim()
        .split(' ')
        .first;

    return Scaffold(
      backgroundColor: t.canvas,
      body: SafeArea(
        bottom: false,
        // Tap anywhere to dismiss the keyboard. Focusing the search field put
        // the keyboard over the tab bar, and nothing on this screen dropped
        // focus — not the header, not a card, not empty space — so the only way
        // out was the system back button. The login screen already does this.
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: StreamBuilder<List<AppUser>>(
            stream: _clientsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _SkeletonRoster();
              }
              if (snapshot.hasError) {
                // "Check your connection and try again" used to be a dead end:
                // there was nothing on screen to press.
                return _RosterMessage(
                  icon: PhosphorIconsRegular.cloudSlash,
                  title: context.l10n.loadClientsError,
                  subtitle: context.l10n.checkConnection,
                  actionLabel: context.l10n.retry,
                  onAction: refresh,
                );
              }

              final clients = snapshot.data ?? const <AppUser>[];
              final sorted = [...clients]
                ..sort(
                  (a, b) => _bucketOf(a).index.compareTo(_bucketOf(b).index),
                );
              final counts = _bucketCounts(sorted);
              final alertCount = counts[_RosterBucket.alert] ?? 0;
              final query = _searchQuery.trim().toLowerCase();
              final visible = sorted.where((c) {
                final statusOk =
                    _bucketFilter == null || _bucketOf(c) == _bucketFilter;
                final nameOk =
                    query.isEmpty || c.name.toLowerCase().contains(query);
                return statusOk && nameOk;
              }).toList();

              return VRefresh(
                onRefresh: refresh,
                child: CustomScrollView(
                  // AlwaysScrollable so the pull gesture works even when the
                  // roster is short enough not to scroll — otherwise a coach with
                  // three clients has no way to reach for it.
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          VSpace.screenMargin,
                          8,
                          VSpace.screenMargin,
                          0,
                        ),
                        child: _GreetingHeader(firstName: firstName),
                      ),
                    ),
                    if (sorted.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            VSpace.screenMargin,
                            20,
                            VSpace.screenMargin,
                            0,
                          ),
                          child: _RosterPulse(
                            total: sorted.length,
                            counts: counts,
                            onTapAlerts: alertCount == 0
                                ? null
                                : () => setState(
                                    () => _bucketFilter = _RosterBucket.alert,
                                  ),
                          ),
                        ),
                      ),
                    if (sorted.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            VSpace.screenMargin,
                            16,
                            VSpace.screenMargin,
                            0,
                          ),
                          child: VSearchBar(
                            controller: _searchController,
                            hint: context.l10n.searchClients,
                            onChanged: (v) => setState(() => _searchQuery = v),
                          ),
                        ),
                      ),
                    if (sorted.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            VSpace.screenMargin,
                            12,
                            VSpace.screenMargin,
                            0,
                          ),
                          child: _FilterBar(
                            counts: counts,
                            selected: _bucketFilter,
                            onSelect: (bucket) =>
                                setState(() => _bucketFilter = bucket),
                          ),
                        ),
                      ),
                    if (sorted.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _RosterMessage(
                          icon: PhosphorIconsRegular.usersThree,
                          title: context.l10n.noClientsYet,
                          subtitle: context.l10n.noClientsBody,
                        ),
                      )
                    else if (visible.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            VSpace.screenMargin,
                            40,
                            VSpace.screenMargin,
                            0,
                          ),
                          child: Center(
                            child: Text(
                              query.isNotEmpty
                                  ? context.l10n.noClientsMatch(
                                      _searchQuery.trim(),
                                    )
                                  : context.l10n.noClientsInGroup,
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
                          16,
                          VSpace.screenMargin,
                          VSpace.scrollBottom + 72,
                        ),
                        // The whole roster is ONE grouped surface (the iOS inset-list
                        // pattern): a single crafted object, each row calm inside it.
                        sliver: SliverToBoxAdapter(
                          child: VGroupCard(
                            header: VListHeader(
                              title: _bucketFilter == null
                                  ? context.l10n.navClients
                                  : _bucketMeta(
                                      _bucketFilter!,
                                      t,
                                      context.l10n,
                                    ).label,
                              count: visible.length,
                            ),
                            children: [
                              for (
                                var index = 0;
                                index < visible.length;
                                index++
                              )
                                Builder(
                                  key: ValueKey(visible[index].uid),
                                  builder: (context) {
                                    final client = visible[index];
                                    final firstSeen = _seenClientIds.add(
                                      client.uid,
                                    );
                                    return _EntranceFade(
                                      index: index,
                                      animate: firstSeen,
                                      child: _ClientRow(
                                        client: client,
                                        bucket: _bucketOf(client),
                                        isDeleting: _deletingClientIds.contains(
                                          client.uid,
                                        ),
                                        onTap: () => _openDetails(client),
                                        onConfigure: () =>
                                            _openDetails(client, tab: 2),
                                        onMore: () =>
                                            _showClientActions(client),
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
              );
            },
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Greeting header — logo + serif "Hi, {name}" (design.md §5.11, archetype A).
// ---------------------------------------------------------------------------

class _GreetingHeader extends StatelessWidget {
  final String firstName;
  const _GreetingHeader({required this.firstName});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 30,
          height: 30,
          child: SvgPicture.asset(
            'assets/logo/valence_logo.svg',
            colorFilter: ColorFilter.mode(t.gold, BlendMode.srcIn),
            fit: BoxFit.contain,
            semanticsLabel: 'Valence',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: VTextScaleCap(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${context.l10n.hi} ',
                    style: VType.serifTitle.copyWith(color: t.ink),
                  ),
                  TextSpan(
                    text: firstName,
                    style: VType.serifTitle.copyWith(color: t.goldDeep),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Roster Pulse — the command-centre health strip (design.md §5.11): one slim
// `surface` card, legend counts + "N need you →" on the header row, the
// VHealthBar beneath. The "N clients" title was dropped — the list header
// already carries the count, and the pulse earns its place by being GLANCEABLE.
// ---------------------------------------------------------------------------

class _RosterPulse extends StatelessWidget {
  final int total;
  final Map<_RosterBucket, int> counts;
  final VoidCallback? onTapAlerts;

  // Setup is IN the bar, last.
  //
  // It used to grade active clients only, on the grounds that Setup is a
  // pending state rather than a health verdict. True — but the bar is sized to
  // the whole roster, so excluding them left an unexplained dark gap at the
  // end, and the one client actually waiting on the coach was the one the
  // summary didn't mention. Steel keeps it legible as "not a verdict": it is
  // ΔE 67 from `watch`, where the goldDeep I first used was ΔE 15 — close
  // enough to read as the same colour, which is exactly what Yassine caught.
  static const _order = [
    _RosterBucket.good,
    _RosterBucket.watch,
    _RosterBucket.alert,
    _RosterBucket.setup,
  ];

  const _RosterPulse({
    required this.total,
    required this.counts,
    required this.onTapAlerts,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final alertCount = counts[_RosterBucket.alert] ?? 0;
    final segments = [
      for (final b in _order)
        if ((counts[b] ?? 0) > 0)
          VHealthSegment(
            color: _bucketMeta(b, t, context.l10n).color,
            count: counts[b]!,
            label: _bucketMeta(b, t, context.l10n).label,
          ),
    ];

    // Slim: the needs-you VTextAction already carries ≥44pt of vertical hit
    // area, so when it's present the card needs little headroom of its own.
    final topPad = alertCount == 0 ? 14.0 : 6.0;

    return Container(
      padding: EdgeInsetsDirectional.fromSTEB(16, topPad, 16, 16),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(VRadius.card),
        boxShadow: t.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: VHealthLegend(segments: segments)),
              const SizedBox(width: 8),
              if (alertCount == 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: t.good,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      context.l10n.allOnTrack,
                      style: VType.subhead.copyWith(
                        color: t.good,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              else
                VTextAction(
                  label: context.l10n.needsYou(alertCount),
                  color: t.alert,
                  arrow: true,
                  onTap: onTapAlerts,
                ),
            ],
          ),
          const SizedBox(height: 8),
          VHealthBar(segments: segments, total: total, showLegend: false),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter — VSegmented over the buckets (design.md §5.11). New / Setup segments
// appear only when non-empty; "All" clears the filter.
// ---------------------------------------------------------------------------

class _FilterBar extends StatelessWidget {
  final Map<_RosterBucket, int> counts;
  final _RosterBucket? selected;
  final ValueChanged<_RosterBucket?> onSelect;

  const _FilterBar({
    required this.counts,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // All / Alert / Watch / Good always; New + Setup only when non-empty.
    final buckets = <_RosterBucket?>[
      null,
      _RosterBucket.alert,
      _RosterBucket.watch,
      _RosterBucket.good,
      if ((counts[_RosterBucket.fresh] ?? 0) > 0) _RosterBucket.fresh,
      if ((counts[_RosterBucket.setup] ?? 0) > 0) _RosterBucket.setup,
    ];

    return VSegmented<_RosterBucket?>(
      selected: selected,
      onChanged: onSelect,
      segments: [
        for (final b in buckets)
          VSegment(
            b,
            b == null
                ? context.l10n.filterAll
                : _bucketMeta(b, t, context.l10n).label,
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Client row — VAvatar identity circle · name · status-aware subline (+ quiet
// gold streak on Good rows) · full-width micro pillar bars · trailing
// VStatusPill (design.md §5.11). Calm by default; status color appears exactly
// once per row, and the gold bars give each client a visual fingerprint.
// ---------------------------------------------------------------------------

class _ClientRow extends StatelessWidget {
  final AppUser client;
  final _RosterBucket bucket;
  final bool isDeleting;
  final VoidCallback onTap;
  final VoidCallback onConfigure;
  final VoidCallback onMore;

  const _ClientRow({
    required this.client,
    required this.bucket,
    required this.isDeleting,
    required this.onTap,
    required this.onConfigure,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = context.l10n;
    final adherence = bucket == _RosterBucket.setup
        ? null
        : _Adherence.tryParse(client.statusSummary);
    final gap = _daysSince(client.lastLogDate);

    // Overall 7-day consistency (met pillars / applicable pillars), surfaced as
    // a number in the subline when a bucket asks for it.
    int? weekPct;
    if (adherence != null) {
      final done = adherence.nutrition + adherence.habits + adherence.workouts;
      final tot =
          adherence.nutritionTotal +
          adherence.habitsTotal +
          adherence.workoutsTotal;
      if (tot > 0) weekPct = ((done / tot) * 100).round();
    }

    // --- subline: recency / status, colored ONLY when the bucket demands it.
    final String subText;
    final Color subColor;
    switch (bucket) {
      case _RosterBucket.setup:
        subText = l.setupMacrosPlan;
        subColor = t.inkSecondary;
      case _RosterBucket.fresh:
        subText = l.joinedRecently;
        subColor = t.goldDeep;
      case _RosterBucket.alert:
        final silent = gap == null || gap >= 2;
        subText = gap == null
            ? l.noLogsYet
            : silent
            ? l.quietForDays(gap)
            : l.consistencyThisWeek(weekPct ?? 0);
        subColor = t.alert;
      case _RosterBucket.watch:
        final silent = gap != null && gap >= 2;
        subText = (!silent && weekPct != null)
            ? l.consistencyThisWeek(weekPct)
            : _lastLogLabel(client.lastLogDate, l);
        subColor = t.watch;
      case _RosterBucket.good:
        subText = adherence == null
            ? l.awaitingLogs
            : _lastLogLabel(client.lastLogDate, l);
        subColor = t.inkSecondary;
    }

    // --- third line: the 7-day pillars as micro fill bars (the client-home
    // macro treatment scaled down — icon · tabular % · thin gold bar). Shape
    // instead of a wall of grey words; each client gets a visual fingerprint.
    Widget? adherenceLine;
    if (adherence != null) {
      String pct(int done, int tot) =>
          tot == 0 ? '–' : '${((done / tot) * 100).round()}%';
      double frac(int done, int tot) =>
          tot == 0 ? 0.0 : (done / tot).clamp(0.0, 1.0).toDouble();
      adherenceLine = Row(
        children: [
          Expanded(
            child: _PillarBar(
              icon: PhosphorIconsRegular.forkKnife,
              semanticLabel: l.metricFood,
              fraction: frac(adherence.nutrition, adherence.nutritionTotal),
              value: pct(adherence.nutrition, adherence.nutritionTotal),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _PillarBar(
              icon: PhosphorIconsRegular.listChecks,
              semanticLabel: l.metricHabits,
              fraction: frac(adherence.habits, adherence.habitsTotal),
              value: pct(adherence.habits, adherence.habitsTotal),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _PillarBar(
              icon: PhosphorIconsRegular.barbell,
              semanticLabel: l.metricTraining,
              fraction: frac(adherence.workouts, adherence.workoutsTotal),
              value: pct(adherence.workouts, adherence.workoutsTotal),
            ),
          ),
        ],
      );
    }

    // --- trailing: the ONE status signal on the row.
    final Widget trailing;
    if (isDeleting) {
      trailing = SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: t.gold),
      );
    } else {
      switch (bucket) {
        case _RosterBucket.setup:
          // Dot + word, like the three pills beside it. Bare gold text made
          // the Setup row scan as EMPTY next to Alert / Watch / Good — the one
          // client who most needs the coach to do something looked like the one
          // with nothing going on.
          trailing = VTextAction(
            label: l.statusSetup,
            dot: true,
            arrow: true,
            // Steel, matching its segment in the health bar above. Gold put it
            // within ΔE 15 of the Watch pill sitting two rows away, so the
            // roster looked like it had two amber states.
            color: t.steel,
            onTap: onConfigure,
          );
        case _RosterBucket.alert:
          trailing = VStatusPill(
            variant: VStatusVariant.alert,
            label: l.statusAlert,
            breathing: true,
          );
        case _RosterBucket.watch:
          trailing = VStatusPill(
            variant: VStatusVariant.watch,
            label: l.statusWatch,
          );
        case _RosterBucket.fresh:
          trailing = VStatusPill(
            variant: VStatusVariant.brandNew,
            label: l.statusNew,
          );
        case _RosterBucket.good:
          trailing = VStatusPill(
            variant: VStatusVariant.good,
            label: l.statusGood,
          );
      }
    }

    // Good rows get their streak back — a quiet gold flame, the same voice as
    // the client home's streak chip.
    final streak = client.currentStreak ?? 0;
    // Two lines. Most sublines are three words ("Quiet for 6 days"), but the
    // Setup one is a whole instruction — "Set up macros & plan to activate this
    // client" — and it ellipsized in English against the "Setup →" action. It
    // is the only subline that tells the coach to DO something, so it was the
    // one sentence in the list that could not afford to be cut.
    Widget sublineWidget = Text(
      subText,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: VType.subhead.copyWith(color: subColor),
    );
    if (bucket == _RosterBucket.good && streak > 0) {
      sublineWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: sublineWidget),
          const SizedBox(width: 8),
          Icon(PhosphorIconsFill.fire, size: 12, color: t.goldDeep),
          const SizedBox(width: 2),
          Text(
            '$streak',
            style: VType.caption.copyWith(
              color: t.goldDeep,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      );
    }

    return Opacity(
      opacity: isDeleting ? 0.45 : 1,
      child: VPressable(
        onTap: isDeleting ? null : onTap,
        onLongPress: isDeleting ? null : onMore,
        overlay: true,
        overlayRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: VSpace.rowMinHeight),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              12,
              VSpace.rowVPad,
              8,
              VSpace.rowVPad,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    VAvatar(name: client.name, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            client.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: VType.headline.copyWith(color: t.ink),
                          ),
                          const SizedBox(height: 3),
                          sublineWidget,
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    trailing,
                  ],
                ),
                // The bars span the FULL row width, inset to the text start —
                // they'd suffocate squeezed beside the status pill.
                if (adherenceLine != null) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 52),
                    child: adherenceLine,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One pillar of the 7-day adherence line: a 12px glyph, the percentage in
/// tabular figures, and a hair-thin gold fill bar beneath (charts are gold —
/// §1.1). "–" + empty bar when the pillar doesn't apply (no assigned days).
class _PillarBar extends StatelessWidget {
  final IconData icon;
  final String semanticLabel;
  final double fraction;
  final String value;

  const _PillarBar({
    required this.icon,
    required this.semanticLabel,
    required this.fraction,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      label: '$semanticLabel $value',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: t.inkTertiary),
              const SizedBox(width: 5),
              Text(
                value,
                style: VType.caption.copyWith(
                  color: t.ink,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(VRadius.pill),
            child: Container(
              height: 3,
              color: t.surfaceSubtle,
              child: FractionallySizedBox(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: fraction,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: t.gold,
                    borderRadius: BorderRadius.circular(VRadius.pill),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared bits.
// ---------------------------------------------------------------------------

/// A tappable action row inside a client-actions [VSheet].

// ---------------------------------------------------------------------------
// Staggered entrance (design.md §1.7-①): one-time fade + 8px rise, 40ms/index,
// cap 8, never re-triggers on filter/search (the seen-set gates `animate`).
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
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );
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
// Skeleton loading — mirrors the real layout (header · pulse · rows).
// ---------------------------------------------------------------------------

class _SkeletonRoster extends StatelessWidget {
  const _SkeletonRoster();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsetsDirectional.fromSTEB(
        VSpace.screenMargin,
        12,
        VSpace.screenMargin,
        0,
      ),
      children: [
        Row(
          children: [
            const VSkeleton(width: 30, height: 30, radius: 8),
            const SizedBox(width: 10),
            const VSkeleton(width: 150, height: 22, radius: 8),
          ],
        ),
        const SizedBox(height: 24),
        const VSkeleton(height: 78, radius: VRadius.card),
        const SizedBox(height: 16),
        const VSkeleton(height: 48, radius: 16),
        const SizedBox(height: 12),
        const VSkeleton(height: 40, radius: VRadius.pill),
        const SizedBox(height: 24),
        for (var i = 0; i < 5; i++) ...[
          Row(
            children: [
              const VSkeleton(width: 40, height: 40, radius: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    VSkeleton(width: 130, height: 14),
                    SizedBox(height: 8),
                    VSkeleton(width: 200, height: 11),
                  ],
                ),
              ),
              const VSkeleton(width: 56, height: 22, radius: VRadius.pill),
            ],
          ),
          const SizedBox(height: 22),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Empty / error state — VEmpty language (flat gold circle, no gradients/glow).
// ---------------------------------------------------------------------------

class _RosterMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _RosterMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return VEmpty(
      icon: icon,
      title: title,
      message: subtitle,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}

// ---------------------------------------------------------------------------
// Data helpers.
// ---------------------------------------------------------------------------

class _Adherence {
  final int nutrition;
  final int nutritionTotal;
  final int habits;
  final int habitsTotal;
  final int workouts;
  final int workoutsTotal;

  const _Adherence({
    required this.nutrition,
    required this.nutritionTotal,
    required this.habits,
    required this.habitsTotal,
    required this.workouts,
    required this.workoutsTotal,
  });

  /// Parses the denormalized `statusSummary` string written by
  /// FirestoreService._refreshClientStatus ("Last 7d: nutrition n/d • habits
  /// n/d • workouts n/d") — reading three counters from one field the roster
  /// already has beats querying every client's logs. If that format changes,
  /// change this regex with it.
  static _Adherence? tryParse(String? summary) {
    if (summary == null) return null;
    final match = RegExp(
      r'nutrition\s*(\d+)\s*/\s*(\d+).*?habits\s*(\d+)\s*/\s*(\d+).*?workouts\s*(\d+)\s*/\s*(\d+)',
      caseSensitive: false,
    ).firstMatch(summary);
    if (match == null) return null;
    return _Adherence(
      nutrition: int.parse(match.group(1)!),
      nutritionTotal: int.parse(match.group(2)!),
      habits: int.parse(match.group(3)!),
      habitsTotal: int.parse(match.group(4)!),
      workouts: int.parse(match.group(5)!),
      workoutsTotal: int.parse(match.group(6)!),
    );
  }
}

/// Roster sort order: the coach is exception-monitoring, so the list leads
/// with who needs action (Alert → Watch → Setup → Good).
// ===========================================================================
// ROSTER TRUTH MODEL
//
// Five buckets, declared in coach-attention order (sort = enum order):
//   alert – needs you NOW
//   watch – heading the wrong way
//   fresh – "New": joined < 3 full days ago and hasn't logged yet. Too early
//           to judge — a client can never be alerted minutes after setup.
//   setup – not configured yet (no macros/plan): a COACH action is pending.
//   good  – recent logs AND healthy 7-day consistency.
//
// Severity = WORST OF two independent signals (same shape as the engine):
//   1. RECENCY, computed LIVE from lastLogDate (fixes the stale-status bug —
//      the stored status only refreshes when the client logs):
//        gap 0–1 days -> ok · gap 2 -> watch · gap >=3 -> alert
//   2. CONSISTENCY, the engine's stored verdict (computed at each log over
//      the rolling 7 completed days as the share of applicable pillars met:
//      nutrition + habits daily, training only on assigned days):
//        <50% -> alert · 50–75% -> watch · >=75% -> ok
// During the 3-day grace window severity is capped at watch. A configured
// client who has NEVER logged escalates to alert once grace expires.
// ===========================================================================

enum _RosterBucket { alert, watch, fresh, setup, good }

const _kGraceDays = 3;

int? _daysSince(String? ymd) {
  if (ymd == null || ymd.isEmpty) return null;
  final parsed = DateTime.tryParse(ymd);
  if (parsed == null) return null;
  final now = DateTime.now();
  return DateTime(
    now.year,
    now.month,
    now.day,
  ).difference(DateTime(parsed.year, parsed.month, parsed.day)).inDays;
}

_RosterBucket _bucketOf(AppUser c) {
  if (c.status == ClientStatus.unconfigured) return _RosterBucket.setup;

  final now = DateTime.now();
  final created = c.createdAt;
  final joinedDays = DateTime(
    now.year,
    now.month,
    now.day,
  ).difference(DateTime(created.year, created.month, created.day)).inDays;
  final inGrace = joinedDays < _kGraceDays;

  final gap = _daysSince(c.lastLogDate);
  if (gap == null) {
    // Configured but never logged: benefit of the doubt during grace, then
    // it's exactly the client the coach must chase.
    return inGrace ? _RosterBucket.fresh : _RosterBucket.alert;
  }

  final recency = gap >= 3 ? 2 : (gap == 2 ? 1 : 0);
  final consistency = c.status == ClientStatus.atRisk
      ? 2
      : (c.status == ClientStatus.slipping ? 1 : 0);
  var worst = recency > consistency ? recency : consistency;
  if (inGrace && worst > 1) worst = 1;

  switch (worst) {
    case 2:
      return _RosterBucket.alert;
    case 1:
      return _RosterBucket.watch;
    default:
      return _RosterBucket.good;
  }
}

Map<_RosterBucket, int> _bucketCounts(List<AppUser> clients) {
  final counts = <_RosterBucket, int>{};
  for (final c in clients) {
    final b = _bucketOf(c);
    counts[b] = (counts[b] ?? 0) + 1;
  }
  return counts;
}

_StatusMeta _bucketMeta(
  _RosterBucket bucket,
  ValenceTokens t,
  AppLocalizations l,
) {
  switch (bucket) {
    case _RosterBucket.setup:
      // Steel, not gold and not grey. Grey made it invisible; gold put it
      // within ΔE 15 of `watch`, so the roster appeared to have two amber
      // states. Steel is a neutral blue — clearly NOT a health verdict, which
      // is the point: "not configured yet" is an absence, not a grade.
      return _StatusMeta(l.statusSetup, t.steel);
    case _RosterBucket.fresh:
      return _StatusMeta(l.statusNew, t.gold);
    case _RosterBucket.alert:
      return _StatusMeta(l.statusAlert, t.alert);
    case _RosterBucket.watch:
      return _StatusMeta(l.statusWatch, t.watch);
    case _RosterBucket.good:
      return _StatusMeta(l.statusGood, t.good);
  }
}

String _lastLogLabel(String? lastLogDate, AppLocalizations l) {
  if (lastLogDate == null || lastLogDate.trim().isEmpty) return l.noLogsYet;
  final parsed = DateTime.tryParse(lastLogDate);
  if (parsed == null) return l.lastLogOn(lastLogDate);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final days = today
      .difference(DateTime(parsed.year, parsed.month, parsed.day))
      .inDays;
  if (days <= 0) return l.loggedToday;
  if (days == 1) return l.yesterday;
  return l.daysAgo(days);
}

class _StatusMeta {
  final String label;
  final Color color;
  const _StatusMeta(this.label, this.color);
}
