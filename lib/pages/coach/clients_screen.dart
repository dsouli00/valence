import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:valence/l10n/app_localizations.dart';
import 'package:valence/l10n/l10n_ext.dart';
import 'package:valence/models/enums.dart';
import 'package:valence/models/user_model.dart';
import 'package:valence/pages/coach/client_details_screen.dart';
import 'package:valence/providers/auth_provider.dart';
import 'package:valence/services/firestore_service.dart';
import 'package:valence/theme/app_theme.dart';

/// The coach's home: the client roster, sorted by risk so the people who
/// need attention surface first. Layout: greeting header → roster pulse
/// (stacked health bar) → search → status filter chips → premium client
/// cards (status strip, gradient-ring avatar, last-7-days adherence chips
/// parsed from `statusSummary`).
///
/// DESIGN NOTE — read before restyling: this screen's "alive premium"
/// language (gradient rings, subtle washes, glows, container-color chips,
/// the pulse card) is deliberate and owner-approved. A calmer iOS-flat
/// rewrite was tried and rejected outright. Iterate ONE element at a time on
/// the existing language; don't flatten or batch-replace it.
///
/// Status meta everywhere on the coach side: atRisk="Alert"/red,
/// slipping="Watch"/yellow, onTrack="Good"/green, unconfigured="Setup"/grey.
class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final _firestoreService = FirestoreService();
  final Set<String> _deletingClientIds = {};

  ClientStatus? _statusFilter;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Cache the roster stream so rebuilds (e.g. typing in search) don't recreate
  // it — recreating would reset StreamBuilder to "waiting" and flash the
  // skeleton on every keystroke. Tracks which cards have already animated in
  // so filtering/searching never re-triggers the staggered entrance.
  Stream<List<AppUser>>? _clientsStream;
  String? _streamCoachId;
  final Set<String> _seenClientIds = {};

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
    final cs = Theme.of(context).colorScheme;
    final coachId = context.read<AuthProvider>().currentUser?.uid;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.removeClientTitle),
        content: Text(
          context.l10n.removeClientMsg(client.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: cs.error),
            child: Text(context.l10n.remove),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;
    setState(() => _deletingClientIds.add(client.uid));
    try {
      await _firestoreService.deleteClientCompletely(
        client.uid,
        requestedByCoachId: coachId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.clientRemoved(client.name))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.removeClientError)),
      );
    } finally {
      if (mounted) setState(() => _deletingClientIds.remove(client.uid));
    }
  }

  void _openDetails(AppUser client, {int tab = 0}) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientDetailsScreen(client: client, initialTabIndex: tab),
      ),
    );
  }

  Future<void> _showClientActions(AppUser client) async {
    HapticFeedback.selectionClick();
    final cs = Theme.of(context).colorScheme;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(PhosphorIconsRegular.eye, color: cs.onSurface),
              title: Text(context.l10n.viewDetails),
              onTap: () {
                Navigator.pop(ctx);
                _openDetails(client);
              },
            ),
            ListTile(
              leading: Icon(PhosphorIconsRegular.slidersHorizontal, color: cs.onSurface),
              title: Text(
                client.status == ClientStatus.unconfigured ? context.l10n.configurePlan : context.l10n.editMacros,
              ),
              onTap: () {
                Navigator.pop(ctx);
                _openDetails(client, tab: 2);
              },
            ),
            ListTile(
              leading: Icon(PhosphorIconsRegular.trash, color: cs.error),
              title: Text(context.l10n.removeClient, style: TextStyle(color: cs.error)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmAndDeleteClient(client);
              },
            ),
            SizedBox(height: AppSpacing.p8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    final coach = context.watch<AuthProvider>().currentUser;
    final coachId = coach?.uid;

    if (coachId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_clientsStream == null || _streamCoachId != coachId) {
      _streamCoachId = coachId;
      _clientsStream = _firestoreService.streamClientsByCoach(coachId);
    }

    return Scaffold(
      backgroundColor: cs.surface,
      body: _AmbientGlow(
        child: SafeArea(
        bottom: false,
        child: StreamBuilder<List<AppUser>>(
          stream: _clientsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _SkeletonRoster(theme: theme);
            }
            if (snapshot.hasError) {
              return _RosterMessage(
                theme: theme,
                icon: PhosphorIconsRegular.cloudSlash,
                title: context.l10n.loadClientsError,
                subtitle: context.l10n.checkConnection,
              );
            }

            final clients = snapshot.data ?? const <AppUser>[];
            final sorted = [...clients]
              ..sort((a, b) => _statusRank(a.status).compareTo(_statusRank(b.status)));
            final counts = _statusCounts(sorted);
            final alertCount = counts[ClientStatus.atRisk] ?? 0;
            final query = _searchQuery.trim().toLowerCase();
            final visible = sorted.where((c) {
              final statusOk = _statusFilter == null || c.status == _statusFilter;
              final nameOk = query.isEmpty || c.name.toLowerCase().contains(query);
              return statusOk && nameOk;
            }).toList();

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _Header(
                    theme: theme,
                    coachName: coach?.name ?? context.l10n.coachWord,
                    total: sorted.length,
                    counts: counts,
                    onTapAlerts: alertCount == 0
                        ? null
                        : () => setState(() => _statusFilter = ClientStatus.atRisk),
                  ),
                ),
                if (sorted.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                          AppSpacing.p16, AppSpacing.p12, AppSpacing.p16, AppSpacing.p12),
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
                if (sorted.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _FilterBar(
                      theme: theme,
                      total: sorted.length,
                      counts: counts,
                      selected: _statusFilter,
                      onSelect: (status) => setState(
                        () => _statusFilter = _statusFilter == status ? null : status,
                      ),
                    ),
                  ),
                if (sorted.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.p20,
                        AppSpacing.p20,
                        AppSpacing.p20,
                        AppSpacing.p12,
                      ),
                      child: _SectionLabel(
                        theme: theme,
                        label: _statusFilter == null
                            ? context.l10n.sortedByRisk.toUpperCase()
                            : '${_statusMeta(_statusFilter!, cs, context.l10n).label.toUpperCase()} · ${visible.length}',
                      ),
                    ),
                  ),
                if (sorted.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _RosterMessage(
                      theme: theme,
                      icon: PhosphorIconsRegular.usersThree,
                      title: context.l10n.noClientsYet,
                      subtitle:
                          context.l10n.noClientsBody,
                    ),
                  )
                else if (visible.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.p32),
                      child: Center(
                        child: Text(
                          query.isNotEmpty
                              ? context.l10n.noClientsMatch(_searchQuery.trim())
                              : context.l10n.noClientsInGroup,
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
                      0,
                      AppSpacing.p16,
                      AppSpacing.p32,
                    ),
                    sliver: SliverList.separated(
                      itemCount: visible.length,
                      separatorBuilder: (context, index) =>
                          SizedBox(height: AppSpacing.p12),
                      itemBuilder: (context, index) {
                        final client = visible[index];
                        final firstSeen = _seenClientIds.add(client.uid);
                        return _EntranceFade(
                          key: ValueKey(client.uid),
                          index: index,
                          animate: firstSeen,
                          child: _ClientCard(
                            theme: theme,
                            client: client,
                            meta: _statusMeta(client.status, cs, context.l10n),
                            isDeleting: _deletingClientIds.contains(client.uid),
                            onTap: () => _openDetails(client),
                            onConfigure: () => _openDetails(client, tab: 2),
                            onMore: () => _showClientActions(client),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header — gradient-ring avatar + greeting + gold-glow total badge.
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  final ThemeData theme;
  final String coachName;
  final int total;
  final Map<ClientStatus, int> counts;
  final VoidCallback? onTapAlerts;

  const _Header({
    required this.theme,
    required this.coachName,
    required this.total,
    required this.counts,
    required this.onTapAlerts,
  });

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    final firstName = coachName.trim().split(' ').first;
    final initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'C';

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.p16,
        AppSpacing.p20,
        AppSpacing.p16,
        AppSpacing.p8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _GradientRing(
                color: AppColors.secondaryColor,
                size: 46,
                child: Text(
                  initial,
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.secondaryColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.p12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greetingWord(context.l10n).toUpperCase(),
                      style: textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
                        fontSize: 10,
                      ),
                    ),
                    SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '${context.l10n.coachWord} ',
                          style: textTheme.titleLarge?.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            firstName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleLarge?.copyWith(
                              color: cs.secondary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (total > 0) ...[
            SizedBox(height: AppSpacing.p20),
            _RosterPulse(
              theme: theme,
              total: total,
              counts: counts,
              onTapAlerts: onTapAlerts,
            ),
          ],
        ],
      ),
    );
  }
}

/// At-a-glance roster health: an animated stacked bar + legend. Gives the
/// screen a "command-centre" pulse instead of just listing rows.
class _RosterPulse extends StatelessWidget {
  final ThemeData theme;
  final int total;
  final Map<ClientStatus, int> counts;
  final VoidCallback? onTapAlerts;

  static const _order = [
    ClientStatus.onTrack,
    ClientStatus.slipping,
    ClientStatus.atRisk,
    ClientStatus.unconfigured,
  ];

  const _RosterPulse({
    required this.theme,
    required this.total,
    required this.counts,
    required this.onTapAlerts,
  });

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    final segments = [
      for (final s in _order)
        if ((counts[s] ?? 0) > 0) (s, counts[s]!),
    ];
    final alertCount = counts[ClientStatus.atRisk] ?? 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondaryColor.withValues(alpha: 0.08),
            AppColors.secondaryColor.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                context.l10n.rosterHealth.toUpperCase(),
                style: textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                  fontSize: 10,
                ),
              ),
              const Spacer(),
              if (alertCount == 0)
                Row(
                  children: [
                    Icon(PhosphorIconsFill.checkCircle, size: 13, color: AppColors.statusGreen),
                    SizedBox(width: AppSpacing.p4),
                    Text(
                      context.l10n.allOnTrack,
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.statusGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                )
              else
                GestureDetector(
                  onTap: onTapAlerts == null
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          onTapAlerts!();
                        },
                  child: Row(
                    children: [
                      Text(
                        context.l10n.needsYou(alertCount),
                        style: textTheme.labelSmall?.copyWith(
                          color: AppColors.statusRed,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(PhosphorIconsBold.arrowRight, size: 12, color: AppColors.statusRed),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: AppSpacing.p12),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 3.0;
              final usable = constraints.maxWidth - gap * (segments.length - 1).clamp(0, 99);
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 750),
                curve: Curves.easeOutCubic,
                builder: (context, t, _) {
                  return Row(
                    children: [
                      for (var i = 0; i < segments.length; i++) ...[
                        Container(
                          width: usable * (segments[i].$2 / total) * t,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _statusMeta(segments[i].$1, cs, context.l10n).color,
                            borderRadius: BorderRadius.circular(5),
                            boxShadow: [
                              BoxShadow(
                                color: _statusMeta(segments[i].$1, cs, context.l10n).color.withValues(alpha: 0.4),
                                blurRadius: 7,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                        if (i < segments.length - 1) const SizedBox(width: gap),
                      ],
                    ],
                  );
                },
              );
            },
          ),
          SizedBox(height: AppSpacing.p12),
          Wrap(
            spacing: AppSpacing.p16,
            runSpacing: AppSpacing.p8,
            children: [
              for (final s in segments)
                _LegendDot(theme: theme, meta: _statusMeta(s.$1, cs, context.l10n), count: s.$2),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final ThemeData theme;
  final _StatusMeta meta;
  final int count;

  const _LegendDot({required this.theme, required this.meta, required this.count});

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: meta.color, shape: BoxShape.circle),
        ),
        SizedBox(width: AppSpacing.p4 + 2),
        Text(
          '$count',
          style: theme.textTheme.labelMedium?.copyWith(
            color: cs.onSurface,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(width: AppSpacing.p4),
        Text(
          meta.label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: cs.onSurfaceVariant.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Filter row.
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Search — filter the roster by client name.
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
                hintText: context.l10n.searchClients,
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

class _FilterBar extends StatelessWidget {
  final ThemeData theme;
  final int total;
  final Map<ClientStatus, int> counts;
  final ClientStatus? selected;
  final ValueChanged<ClientStatus> onSelect;

  const _FilterBar({
    required this.theme,
    required this.total,
    required this.counts,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    const buckets = [ClientStatus.atRisk, ClientStatus.slipping, ClientStatus.onTrack];

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.p16),
        children: [
          _Seg(
            theme: theme,
            label: context.l10n.filterAll,
            count: total,
            color: cs.secondary,
            active: selected == null,
            onTap: () {
              if (selected != null) onSelect(selected!);
            },
          ),
          for (final status in buckets) ...[
            SizedBox(width: AppSpacing.p8),
            _Seg(
              theme: theme,
              label: _statusMeta(status, cs, context.l10n).label,
              count: counts[status] ?? 0,
              color: _statusMeta(status, cs, context.l10n).color,
              active: selected == status,
              onTap: () => onSelect(status),
            ),
          ],
        ],
      ),
    );
  }
}

class _Seg extends StatelessWidget {
  final ThemeData theme;
  final String label;
  final int count;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  const _Seg({
    required this.theme,
    required this.label,
    required this.count,
    required this.color,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.p16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: active
              ? LinearGradient(
                  colors: [color.withValues(alpha: 0.20), color.withValues(alpha: 0.08)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: active ? null : cs.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(19),
          border: Border.all(
            color: active ? color.withValues(alpha: 0.45) : cs.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: active ? color : cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            SizedBox(width: AppSpacing.p8),
            Text(
              '$count',
              style: theme.textTheme.labelMedium?.copyWith(
                color: active ? color : cs.onSurfaceVariant.withValues(alpha: 0.6),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Client card — built in the home-screen language (gradient ring, status
// strip with glow, container-chip metrics, two-layer shadow, big numbers).
// ---------------------------------------------------------------------------

class _ClientCard extends StatefulWidget {
  final ThemeData theme;
  final AppUser client;
  final _StatusMeta meta;
  final bool isDeleting;
  final VoidCallback onTap;
  final VoidCallback onConfigure;
  final VoidCallback onMore;

  const _ClientCard({
    required this.theme,
    required this.client,
    required this.meta,
    required this.isDeleting,
    required this.onTap,
    required this.onConfigure,
    required this.onMore,
  });

  @override
  State<_ClientCard> createState() => _ClientCardState();
}

class _ClientCardState extends State<_ClientCard> with SingleTickerProviderStateMixin {
  bool _pressed = false;
  AnimationController? _pulse;

  bool get _isAtRisk => widget.client.status == ClientStatus.atRisk;

  @override
  void initState() {
    super.initState();
    if (_isAtRisk) {
      _pulse = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2200),
      )..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse?.dispose();
    super.dispose();
  }

  void _setPressed(bool v) {
    if (_pressed != v && mounted) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    final client = widget.client;
    final meta = widget.meta;
    final streak = client.currentStreak ?? 0;
    final isUnconfigured = client.status == ClientStatus.unconfigured;
    final adherence = isUnconfigured ? null : _Adherence.tryParse(client.statusSummary);

    return Opacity(
      opacity: widget.isDeleting ? 0.45 : 1,
      child: GestureDetector(
        onTapDown: widget.isDeleting ? null : (_) => _setPressed(true),
        onTapCancel: widget.isDeleting ? null : () => _setPressed(false),
        onTapUp: widget.isDeleting ? null : (_) => _setPressed(false),
        onTap: widget.isDeleting ? null : widget.onTap,
        onLongPress: widget.isDeleting ? null : widget.onMore,
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1,
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeOut,
          child: AnimatedBuilder(
            animation: _pulse ?? const AlwaysStoppedAnimation(0),
            builder: (context, child) {
              final t = _pulse?.value ?? 0;
              final glowAlpha = _isAtRisk ? 0.08 + 0.16 * t : 0.07;
              final glowBlur = _isAtRisk ? 26.0 + 12.0 * t : 28.0;
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.alphaBlend(
                        meta.color.withValues(alpha: _isAtRisk ? 0.07 + 0.05 * t : 0.06),
                        cs.surfaceContainerLow,
                      ),
                      cs.surfaceContainerLow,
                    ],
                    stops: const [0.0, 0.62],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: _isAtRisk
                        ? meta.color.withValues(alpha: 0.18 + 0.14 * t)
                        : cs.outlineVariant.withValues(alpha: 0.28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: cs.shadow.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                    BoxShadow(
                      color: meta.color.withValues(alpha: glowAlpha),
                      blurRadius: glowBlur,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Status accent strip — gradient + glow (their meal-card signature).
                    Container(
                      width: 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [meta.color, meta.color.withValues(alpha: 0.3)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: meta.color.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: AppSpacing.p16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              _GradientRing(
                                color: meta.color,
                                size: 42,
                                child: Text(
                                  _initials(client.name),
                                  style: textTheme.labelLarge?.copyWith(
                                    color: cs.onSurface,
                                    fontWeight: FontWeight.w800,
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
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.3,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                    SizedBox(height: 3),
                                    _MetaLine(theme: theme, client: client, streak: streak),
                                  ],
                                ),
                              ),
                              SizedBox(width: AppSpacing.p8),
                              if (widget.isDeleting)
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: cs.secondary),
                                )
                              else
                                _StatusPill(theme: theme, meta: meta),
                            ],
                          ),
                          SizedBox(height: AppSpacing.p12),
                          Divider(color: cs.outlineVariant.withValues(alpha: 0.25), height: 1),
                          SizedBox(height: AppSpacing.p12),
                          if (isUnconfigured)
                            _ConfigureButton(theme: theme, onTap: widget.onConfigure)
                          else if (adherence != null)
                            _DayMetrics(theme: theme, adherence: adherence)
                          else
                            _AwaitingChip(theme: theme),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  final ThemeData theme;
  final AppUser client;
  final int streak;

  const _MetaLine({required this.theme, required this.client, required this.streak});

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    return Row(
      children: [
        Icon(PhosphorIconsRegular.clock, size: 11, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
        SizedBox(width: AppSpacing.p4),
        Flexible(
          child: Text(
            _lastLogLabel(client.lastLogDate, context.l10n),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.55),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (streak > 0) ...[
          SizedBox(width: AppSpacing.p8),
          Icon(Icons.local_fire_department_rounded, size: 13, color: cs.secondary),
          SizedBox(width: 2),
          Text(
            '$streak',
            style: textTheme.labelSmall?.copyWith(
              color: cs.secondary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final ThemeData theme;
  final _StatusMeta meta;

  const _StatusPill({required this.theme, required this.meta});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: meta.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: meta.color.withValues(alpha: 0.20), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: meta.color,
              boxShadow: [BoxShadow(color: meta.color.withValues(alpha: 0.5), blurRadius: 4)],
            ),
          ),
          const SizedBox(width: 5),
          Text(
            meta.label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: meta.color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Three glanceable habit reads for the last 3 days. Each shows filled "day
/// dots" (●●○ = did it 2 of the last 3 days), colour-graded so gaps jump out —
/// full = green, partial = amber, none = red. No fractions to decode.
class _DayMetrics extends StatelessWidget {
  final ThemeData theme;
  final _Adherence adherence;

  const _DayMetrics({required this.theme, required this.adherence});

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.last7Days.toUpperCase(),
          style: textTheme.labelSmall?.copyWith(
            color: cs.onSurfaceVariant.withValues(alpha: 0.5),
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            fontSize: 9.5,
          ),
        ),
        SizedBox(height: AppSpacing.p8 + 2),
        Row(
          children: [
            Expanded(
              child: _DayMetric(
                theme: theme,
                icon: PhosphorIconsFill.forkKnife,
                label: context.l10n.metricFood,
                done: adherence.nutrition,
                total: adherence.nutritionTotal,
                color: cs.primaryContainer,
                onColor: cs.onPrimaryContainer,
              ),
            ),
            SizedBox(width: AppSpacing.p8),
            Expanded(
              child: _DayMetric(
                theme: theme,
                icon: PhosphorIconsFill.heartbeat,
                label: context.l10n.metricHabits,
                done: adherence.habits,
                total: adherence.habitsTotal,
                color: cs.secondaryContainer,
                onColor: cs.onSecondaryContainer,
              ),
            ),
            SizedBox(width: AppSpacing.p8),
            Expanded(
              child: _DayMetric(
                theme: theme,
                icon: PhosphorIconsFill.barbell,
                label: context.l10n.metricTraining,
                done: adherence.workouts,
                total: adherence.workoutsTotal,
                color: cs.tertiaryContainer,
                onColor: cs.onTertiaryContainer,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DayMetric extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final String label;
  final int done;
  final int total;
  final Color color;
  final Color onColor;

  const _DayMetric({
    required this.theme,
    required this.icon,
    required this.label,
    required this.done,
    required this.total,
    required this.color,
    required this.onColor,
  });

  @override
  Widget build(BuildContext context) {
    // total == 0 means there was nothing to do in the window (e.g. no workouts
    // assigned, or a brand-new client) — show "n/a" rather than a fake 0%.
    final na = total == 0;
    final pct = na ? 0 : ((done / total) * 100).round();
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 8, 9, 9),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.62), color.withValues(alpha: 0.4)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: onColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Icon(icon, size: 12, color: onColor.withValues(alpha: 0.85)),
              const Spacer(),
              Text(
                na ? '–' : '$pct',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: na ? onColor.withValues(alpha: 0.6) : onColor,
                  height: 1,
                  letterSpacing: -0.6,
                ),
              ),
              if (!na)
                Text(
                  '%',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: onColor.withValues(alpha: 0.6),
                    height: 1,
                  ),
                ),
            ],
          ),
          SizedBox(height: AppSpacing.p8),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              color: onColor.withValues(alpha: 0.75),
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _AwaitingChip extends StatelessWidget {
  final ThemeData theme;
  const _AwaitingChip({required this.theme});

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    return Row(
      children: [
        Icon(PhosphorIconsRegular.chartLineUp, size: 14, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
        SizedBox(width: AppSpacing.p8),
        Text(
          context.l10n.awaitingLogs,
          style: theme.textTheme.labelMedium?.copyWith(
            color: cs.onSurfaceVariant.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ConfigureButton extends StatelessWidget {
  final ThemeData theme;
  final VoidCallback onTap;

  const _ConfigureButton({required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.secondaryColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppColors.secondaryColor.withValues(alpha: 0.28), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.secondaryColor.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(PhosphorIconsBold.slidersHorizontal,
                  size: 12, color: AppColors.secondaryColor),
            ),
            SizedBox(width: AppSpacing.p8),
            Expanded(
              child: Text(
                context.l10n.setupMacrosPlan,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
              ),
            ),
            Icon(PhosphorIconsBold.arrowRight, size: 14, color: AppColors.secondaryColor),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared bits.
// ---------------------------------------------------------------------------

class _AmbientGlow extends StatelessWidget {
  final Widget child;
  const _AmbientGlow({required this.child});

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

class _GradientRing extends StatelessWidget {
  final Color color;
  final double size;
  final Widget child;

  const _GradientRing({required this.color, required this.size, required this.child});

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
          colors: [color, color.withValues(alpha: 0.25)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: CircleAvatar(backgroundColor: cs.surface, child: child),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final ThemeData theme;
  final String label;

  const _SectionLabel({required this.theme, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    return Row(
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: cs.onSurfaceVariant.withValues(alpha: 0.45),
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            fontSize: 10,
          ),
        ),
        SizedBox(width: AppSpacing.p12),
        Expanded(
          child: Divider(color: cs.outlineVariant.withValues(alpha: 0.28), thickness: 1, height: 1),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Staggered entrance.
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Skeleton loading.
// ---------------------------------------------------------------------------

class _SkeletonRoster extends StatefulWidget {
  final ThemeData theme;
  const _SkeletonRoster({required this.theme});

  @override
  State<_SkeletonRoster> createState() => _SkeletonRosterState();
}

class _SkeletonRosterState extends State<_SkeletonRoster> with SingleTickerProviderStateMixin {
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
                _box(150, 20),
              ],
            ),
          ],
        ),
        SizedBox(height: AppSpacing.p20),
        _box(double.infinity, 96, radius: 18),
        SizedBox(height: AppSpacing.p24),
        for (var i = 0; i < 4; i++) ...[
          _box(double.infinity, 132, radius: 22),
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

// ---------------------------------------------------------------------------
// Empty / error state.
// ---------------------------------------------------------------------------

class _RosterMessage extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final String title;
  final String subtitle;

  const _RosterMessage({
    required this.theme,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

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
              width: 80,
              height: 80,
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
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(icon, color: AppColors.secondaryColor, size: 32),
            ),
            SizedBox(height: AppSpacing.p20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            SizedBox(height: AppSpacing.p8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
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

String _greetingWord(AppLocalizations l) {
  final hour = DateTime.now().hour;
  if (hour < 12) return l.greetingMorning;
  if (hour < 17) return l.greetingAfternoon;
  return l.greetingEvening;
}

/// Roster sort order: the coach is exception-monitoring, so the list leads
/// with who needs action (Alert → Watch → Setup → Good).
int _statusRank(ClientStatus? status) {
  switch (status) {
    case ClientStatus.atRisk:
      return 0;
    case ClientStatus.slipping:
      return 1;
    case ClientStatus.unconfigured:
      return 2;
    case ClientStatus.onTrack:
    case null:
      return 3;
  }
}

Map<ClientStatus, int> _statusCounts(List<AppUser> clients) {
  final counts = <ClientStatus, int>{};
  for (final c in clients) {
    final status = c.status ?? ClientStatus.onTrack;
    counts[status] = (counts[status] ?? 0) + 1;
  }
  return counts;
}

_StatusMeta _statusMeta(ClientStatus? status, ColorScheme cs, AppLocalizations l) {
  switch (status) {
    case ClientStatus.unconfigured:
      return _StatusMeta(l.statusSetup, cs.onSurfaceVariant);
    case ClientStatus.atRisk:
      return _StatusMeta(l.statusAlert, AppColors.statusRed);
    case ClientStatus.slipping:
      return _StatusMeta(l.statusWatch, AppColors.statusYellow);
    case ClientStatus.onTrack:
    case null:
      return _StatusMeta(l.statusGood, AppColors.statusGreen);
  }
}

String _initials(String name) {
  final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return 'U';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

String _lastLogLabel(String? lastLogDate, AppLocalizations l) {
  if (lastLogDate == null || lastLogDate.trim().isEmpty) return l.noLogsYet;
  final parsed = DateTime.tryParse(lastLogDate);
  if (parsed == null) return l.lastLogOn(lastLogDate);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final days = today.difference(DateTime(parsed.year, parsed.month, parsed.day)).inDays;
  if (days <= 0) return l.loggedToday;
  if (days == 1) return l.yesterday;
  return l.daysAgo(days);
}

class _StatusMeta {
  final String label;
  final Color color;
  const _StatusMeta(this.label, this.color);
}
