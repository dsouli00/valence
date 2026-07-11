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
              ..sort((a, b) => _bucketOf(a).index.compareTo(_bucketOf(b).index));
            final counts = _bucketCounts(sorted);
            final alertCount = counts[_RosterBucket.alert] ?? 0;
            final query = _searchQuery.trim().toLowerCase();
            final visible = sorted.where((c) {
              final statusOk = _bucketFilter == null || _bucketOf(c) == _bucketFilter;
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
                        : () => setState(() => _bucketFilter = _RosterBucket.alert),
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
                      selected: _bucketFilter,
                      onSelect: (bucket) => setState(
                        () => _bucketFilter = _bucketFilter == bucket ? null : bucket,
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
                        label: _bucketFilter == null
                            ? context.l10n.sortedByRisk.toUpperCase()
                            : '${_bucketMeta(_bucketFilter!, cs, context.l10n).label.toUpperCase()} · ${visible.length}',
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
                    // One grouped surface for the whole roster (the Revolut/iOS
                    // inset-list pattern): the list reads as a single crafted
                    // object, while each row inside stays calm.
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
                                  padding: const EdgeInsetsDirectional.only(start: 58),
                                  child: Divider(
                                    color: cs.outlineVariant.withValues(alpha: 0.18),
                                    height: 1,
                                    thickness: 1,
                                  ),
                                ),
                              Builder(
                                builder: (context) {
                                  final client = visible[index];
                                  final firstSeen = _seenClientIds.add(client.uid);
                                  return _EntranceFade(
                                    key: ValueKey(client.uid),
                                    index: index,
                                    animate: firstSeen,
                                    child: _ClientCard(
                                      theme: theme,
                                      client: client,
                                      bucket: _bucketOf(client),
                                      meta: _bucketMeta(_bucketOf(client), cs, context.l10n),
                                      isDeleting: _deletingClientIds.contains(client.uid),
                                      onTap: () => _openDetails(client),
                                      onConfigure: () => _openDetails(client, tab: 2),
                                      onMore: () => _showClientActions(client),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
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
// Header — brand logo + greeting; the Roster Pulse hero card sits below.
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  final ThemeData theme;
  final String coachName;
  final int total;
  final Map<_RosterBucket, int> counts;
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
              SizedBox(
                width: 38,
                height: 38,
                child: SvgPicture.asset(
                  'assets/logo/valence_logo.svg',
                  colorFilter: const ColorFilter.mode(
                      AppColors.secondaryColor, BlendMode.srcIn),
                  fit: BoxFit.contain,
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
  final Map<_RosterBucket, int> counts;
  final VoidCallback? onTapAlerts;

  // The health bar shows ACTIVE clients only — New and Setup are pending
  // states, surfaced via their filter chips instead.
  static const _order = [
    _RosterBucket.good,
    _RosterBucket.watch,
    _RosterBucket.alert,
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
    final alertCount = counts[_RosterBucket.alert] ?? 0;

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
                            color: _bucketMeta(segments[i].$1, cs, context.l10n).color,
                            borderRadius: BorderRadius.circular(5),
                            boxShadow: [
                              BoxShadow(
                                color: _bucketMeta(segments[i].$1, cs, context.l10n).color.withValues(alpha: 0.4),
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
                _LegendDot(theme: theme, meta: _bucketMeta(s.$1, cs, context.l10n), count: s.$2),
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
  final Map<_RosterBucket, int> counts;
  final _RosterBucket? selected;
  final ValueChanged<_RosterBucket> onSelect;

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
    // Alert/Watch/Good always; New + Setup chips appear only when non-empty.
    final buckets = [
      _RosterBucket.alert,
      _RosterBucket.watch,
      _RosterBucket.good,
      if ((counts[_RosterBucket.fresh] ?? 0) > 0) _RosterBucket.fresh,
      if ((counts[_RosterBucket.setup] ?? 0) > 0) _RosterBucket.setup,
    ];

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
          for (final bucket in buckets) ...[
            SizedBox(width: AppSpacing.p8),
            _Seg(
              theme: theme,
              label: _bucketMeta(bucket, cs, context.l10n).label,
              count: counts[bucket] ?? 0,
              color: _bucketMeta(bucket, cs, context.l10n).color,
              active: selected == bucket,
              onTap: () => onSelect(bucket),
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

// Each client gets a stable, muted identity tint (Linear/Slack-style) — it
// gives the roster life without competing with status colors, which stay
// reserved for the dot + subline.
const _identityTints = [
  Color(0xFFC6A87C), // gold
  Color(0xFF9BB08C), // sage
  Color(0xFF8FA7BC), // steel
  Color(0xFFC08D7C), // clay
  Color(0xFFA79ABF), // lilac
  Color(0xFF7CB0A5), // teal
];

Color _identityTint(String name) =>
    _identityTints[name.codeUnits.fold<int>(0, (a, c) => a + c) % _identityTints.length];

class _ClientCard extends StatefulWidget {
  final ThemeData theme;
  final AppUser client;
  final _RosterBucket bucket;
  final _StatusMeta meta;
  final bool isDeleting;
  final VoidCallback onTap;
  final VoidCallback onConfigure;
  final VoidCallback onMore;

  const _ClientCard({
    required this.theme,
    required this.client,
    required this.bucket,
    required this.meta,
    required this.isDeleting,
    required this.onTap,
    required this.onConfigure,
    required this.onMore,
  });

  @override
  State<_ClientCard> createState() => _ClientCardState();
}

// A calm ROW, not a card: content sits on the background, typography does the
// work, and color appears ONLY where status demands attention — on-track rows
// are fully neutral so the one red dot on screen is impossible to miss. This
// is the screen's actual job (triage) expressed as design.
class _ClientCardState extends State<_ClientCard> with SingleTickerProviderStateMixin {
  bool _pressed = false;
  AnimationController? _pulse;

  bool get _isAtRisk => widget.bucket == _RosterBucket.alert;

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
    final streak = client.currentStreak ?? 0;
    final bucket = widget.bucket;
    final isSetup = bucket == _RosterBucket.setup;
    final isFresh = bucket == _RosterBucket.fresh;
    final isWatch = bucket == _RosterBucket.watch;
    final adherence = isSetup ? null : _Adherence.tryParse(client.statusSummary);
    final gap = _daysSince(client.lastLogDate);
    // Overall 7-day consistency (the engine's formula, surfaced as a number):
    // met pillars / applicable pillars across the window.
    int? weekPct;
    if (adherence != null) {
      final done = adherence.nutrition + adherence.habits + adherence.workouts;
      final total = adherence.nutritionTotal + adherence.habitsTotal + adherence.workoutsTotal;
      if (total > 0) weekPct = ((done / total) * 100).round();
    }

    // --- second line: recency, colored only when the status needs attention.
    Widget subline;
    if (isSetup) {
      subline = Text(
        context.l10n.setupMacrosPlan,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textTheme.labelSmall?.copyWith(
          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
          fontWeight: FontWeight.w500,
        ),
      );
    } else if (isFresh) {
      subline = Text(
        context.l10n.joinedRecently,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textTheme.labelSmall?.copyWith(
          color: AppColors.secondaryColor.withValues(alpha: 0.85),
          fontWeight: FontWeight.w600,
        ),
      );
    } else if (_isAtRisk) {
      // Tell the coach WHY: silence shows the gap; weak consistency (still
      // logging, but missing pillars) shows the week's percentage.
      final silent = gap == null || gap >= 2;
      subline = Text(
        gap == null
            ? context.l10n.noLogsYet
            : silent
                ? context.l10n.quietForDays(gap)
                : context.l10n.consistencyThisWeek(weekPct ?? 0),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textTheme.labelSmall?.copyWith(
          color: AppColors.statusRed,
          fontWeight: FontWeight.w700,
        ),
      );
    } else if (isWatch) {
      final silent = gap != null && gap >= 2;
      subline = Text(
        !silent && weekPct != null
            ? context.l10n.consistencyThisWeek(weekPct)
            : _lastLogLabel(client.lastLogDate, context.l10n),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textTheme.labelSmall?.copyWith(
          color: AppColors.statusYellow,
          fontWeight: FontWeight.w600,
        ),
      );
    } else {
      subline = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              adherence == null
                  ? context.l10n.awaitingLogs
                  : _lastLogLabel(client.lastLogDate, context.l10n),
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
            Icon(Icons.local_fire_department_rounded, size: 12, color: cs.secondary),
            const SizedBox(width: 2),
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

    // --- third line: the 7-day pillars as quiet text — no chips, no gradients.
    Widget? adherenceLine;
    if (adherence != null) {
      String pct(int done, int total) =>
          total == 0 ? '–' : '${((done / total) * 100).round()}%';
      final muted = textTheme.labelSmall?.copyWith(
        color: cs.onSurfaceVariant.withValues(alpha: 0.45),
        fontWeight: FontWeight.w500,
        fontSize: 11,
      );
      final value = textTheme.labelSmall?.copyWith(
        color: cs.onSurface.withValues(alpha: 0.8),
        fontWeight: FontWeight.w700,
        fontSize: 11,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
      adherenceLine = Text.rich(
        TextSpan(children: [
          TextSpan(text: context.l10n.metricFood, style: muted),
          TextSpan(text: ' ${pct(adherence.nutrition, adherence.nutritionTotal)}', style: value),
          TextSpan(text: '   ·   ', style: muted),
          TextSpan(text: context.l10n.metricHabits, style: muted),
          TextSpan(text: ' ${pct(adherence.habits, adherence.habitsTotal)}', style: value),
          TextSpan(text: '   ·   ', style: muted),
          TextSpan(text: context.l10n.metricTraining, style: muted),
          TextSpan(text: ' ${pct(adherence.workouts, adherence.workoutsTotal)}', style: value),
        ]),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    // --- right side: the ONLY status signal on the row.
    Widget trailing;
    if (widget.isDeleting) {
      trailing = SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: cs.secondary),
      );
    } else if (isSetup) {
      trailing = GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onConfigure();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.l10n.statusSetup,
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.secondaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 3),
              Icon(PhosphorIconsBold.arrowRight, size: 12, color: AppColors.secondaryColor),
            ],
          ),
        ),
      );
    } else if (_isAtRisk) {
      trailing = AnimatedBuilder(
        animation: _pulse ?? const AlwaysStoppedAnimation(0),
        builder: (context, _) {
          final t = _pulse?.value ?? 0;
          return Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.statusRed,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.statusRed.withValues(alpha: 0.25 + 0.35 * t),
                  blurRadius: 6 + 6 * t,
                  spreadRadius: 1 + 1.5 * t,
                ),
              ],
            ),
          );
        },
      );
    } else if (isWatch) {
      trailing = Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.statusYellow,
          shape: BoxShape.circle,
        ),
      );
    } else if (isFresh) {
      trailing = Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.secondaryColor,
          shape: BoxShape.circle,
        ),
      );
    } else {
      trailing = const SizedBox.shrink();
    }

    return Opacity(
      opacity: widget.isDeleting ? 0.45 : 1,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.isDeleting ? null : (_) => _setPressed(true),
        onTapCancel: widget.isDeleting ? null : () => _setPressed(false),
        onTapUp: widget.isDeleting ? null : (_) => _setPressed(false),
        onTap: widget.isDeleting ? null : widget.onTap,
        onLongPress: widget.isDeleting ? null : widget.onMore,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
          decoration: BoxDecoration(
            color: _pressed ? cs.onSurface.withValues(alpha: 0.035) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _identityTint(client.name).withValues(alpha: 0.16),
                child: Text(
                  _initials(client.name),
                  style: textTheme.labelLarge?.copyWith(
                    color: _identityTint(client.name),
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
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    subline,
                    if (adherenceLine != null) ...[
                      const SizedBox(height: 4),
                      adherenceLine,
                    ],
                  ],
                ),
              ),
              SizedBox(width: AppSpacing.p12),
              trailing,
            ],
          ),
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
        for (var i = 0; i < 5; i++) ...[
          Row(
            children: [
              _box(40, 40, radius: 20),
              SizedBox(width: AppSpacing.p12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _box(130, 12),
                    SizedBox(height: AppSpacing.p8),
                    _box(200, 9),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.p20),
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
  return DateTime(now.year, now.month, now.day)
      .difference(DateTime(parsed.year, parsed.month, parsed.day))
      .inDays;
}

_RosterBucket _bucketOf(AppUser c) {
  if (c.status == ClientStatus.unconfigured) return _RosterBucket.setup;

  final now = DateTime.now();
  final created = c.createdAt;
  final joinedDays = DateTime(now.year, now.month, now.day)
      .difference(DateTime(created.year, created.month, created.day))
      .inDays;
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

_StatusMeta _bucketMeta(_RosterBucket bucket, ColorScheme cs, AppLocalizations l) {
  switch (bucket) {
    case _RosterBucket.setup:
      return _StatusMeta(l.statusSetup, cs.onSurfaceVariant);
    case _RosterBucket.fresh:
      return _StatusMeta(l.statusNew, AppColors.secondaryColor);
    case _RosterBucket.alert:
      return _StatusMeta(l.statusAlert, AppColors.statusRed);
    case _RosterBucket.watch:
      return _StatusMeta(l.statusWatch, AppColors.statusYellow);
    case _RosterBucket.good:
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
