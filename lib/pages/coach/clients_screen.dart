import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:valence/pages/coach/client_details_screen.dart';
import '../../../../models/enums.dart';
import '../../theme/app_theme.dart';

// ─── Status meta ──────────────────────────────────────────────────────────────

class _SM {
  final Color accent;
  final Color chip;
  final Color border;
  final String label;
  final IconData icon;

  const _SM({
    required this.accent,
    required this.chip,
    required this.border,
    required this.label,
    required this.icon,
  });

  static _SM of(ClientStatus s, bool isDark) {
    switch (s) {
      case ClientStatus.atRisk:
        return _SM(
          accent: AppColors.statusRed,
          chip: AppColors.statusRed.withOpacity(isDark ? 0.15 : 0.10),
          border: AppColors.statusRed.withOpacity(isDark ? 0.35 : 0.22),
          label: 'At Risk',
          icon: Icons.warning_amber_rounded,
        );
      case ClientStatus.slipping:
        return _SM(
          accent: AppColors.statusYellow,
          chip: AppColors.statusYellow.withOpacity(isDark ? 0.15 : 0.10),
          border: AppColors.statusYellow.withOpacity(isDark ? 0.35 : 0.22),
          label: 'Watch',
          icon: Icons.trending_down_rounded,
        );
      case ClientStatus.onTrack:
        return _SM(
          accent: AppColors.statusGreen,
          chip: AppColors.statusGreen.withOpacity(isDark ? 0.15 : 0.09),
          border: AppColors.statusGreen.withOpacity(isDark ? 0.30 : 0.18),
          label: 'On Track',
          icon: Icons.check_circle_outline_rounded,
        );
    }
  }
}

// ─── Model ────────────────────────────────────────────────────────────────────

class _Client {
  final String name;
  final ClientStatus status;
  final int streak;
  final int? sleepRating;
  final double? weight;

  const _Client({
    required this.name,
    required this.status,
    required this.streak,
    this.sleepRating,
    this.weight,
  });

  String get initials {
    final p = name.trim().split(' ');
    return p.length >= 2
        ? '${p.first[0]}${p.last[0]}'.toUpperCase()
        : p.first[0].toUpperCase();
  }

  static String sleepText(int? r) =>
      const {1: 'Poor', 2: 'Fair', 3: 'Good', 4: 'Great', 5: 'Excellent'}[r] ??
          '—';

  static int rank(ClientStatus s) => s == ClientStatus.atRisk
      ? 0
      : s == ClientStatus.slipping
      ? 1
      : 2;
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  static const _raw = [
    _Client(
      name: 'Sarah Johnson',
      status: ClientStatus.atRisk,
      streak: 2,
      sleepRating: 1,
      weight: 168.4,
    ),
    _Client(
      name: 'Michael Brown',
      status: ClientStatus.slipping,
      streak: 5,
      sleepRating: 2,
      weight: 182.1,
    ),
    _Client(
      name: 'Emma Wilson',
      status: ClientStatus.onTrack,
      streak: 14,
      sleepRating: 4,
      weight: 141.7,
    ),
    _Client(
      name: 'Daniel Lee',
      status: ClientStatus.onTrack,
      streak: 9,
      sleepRating: 5,
      weight: 195.0,
    ),
    _Client(
      name: 'Olivia Martinez',
      status: ClientStatus.slipping,
      streak: 3,
      sleepRating: 3,
    ),
    _Client(
      name: 'Noah Davis',
      status: ClientStatus.atRisk,
      streak: 1,
      weight: 210.3,
    ),
    _Client(
      name: 'Noah Davis',
      status: ClientStatus.atRisk,
      streak: 1,
      weight: 210.3,
    ),
    _Client(
      name: 'Noah Davis',
      status: ClientStatus.atRisk,
      streak: 1,
      weight: 210.3,
    ),
    _Client(
      name: 'Noah Davis',
      status: ClientStatus.atRisk,
      streak: 1,
      weight: 210.3,
    ),
  ];

  late final List<_Client> _clients;
  late final int _atRisk;
  late final int _slipping;
  late final int _onTrack;

  @override
  void initState() {
    super.initState();
    // 1. FIX: Sort the data exactly ONCE during initialization
    _clients = List.of(_raw)
      ..sort((a, b) => _Client.rank(a.status).compareTo(_Client.rank(b.status)));

    // 2. FIX: Pre-calculate counts outside the build method
    _atRisk = _clients.where((c) => c.status == ClientStatus.atRisk).length;
    _slipping = _clients.where((c) => c.status == ClientStatus.slipping).length;
    _onTrack = _clients.where((c) => c.status == ClientStatus.onTrack).length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final isDark = colorScheme.brightness == Brightness.dark;
    final totalClients = _clients.length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.p12,
                    vertical: AppSpacing.p12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 40.h,
                        child: SvgPicture.asset(
                          "assets/logo/valence_logo.svg",
                          colorFilter: ColorFilter.mode(
                            colorScheme.secondary,
                            BlendMode.srcIn,
                          ),
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(width: AppSpacing.p4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Coach ',
                                    style: textTheme.headlineMedium?.copyWith(
                                      color: colorScheme.onSurface,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.8,
                                      height: 1.1,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Alex',
                                    style: textTheme.headlineMedium?.copyWith(
                                      color: colorScheme.secondary,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.8,
                                      height: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => HapticFeedback.selectionClick(),
                        child: Container(
                          width: 44.r,
                          height: 44.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.surfaceContainerHighest
                                .withOpacity(0.4),
                            border: Border.all(
                              color: colorScheme.outlineVariant.withOpacity(0.4),
                            ),
                          ),
                          child: Icon(
                            PhosphorIcons.userPlus(),
                            size: 20.sp,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      // 3. FIX: Standardized spacing token
                      SizedBox(width: AppSpacing.p12),
                      GestureDetector(
                        onTap: () => HapticFeedback.selectionClick(),
                        child: Container(
                          width: 44.r,
                          height: 44.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.surfaceContainerHighest
                                .withOpacity(0.4),
                            border: Border.all(
                              color: colorScheme.outlineVariant.withOpacity(0.4),
                            ),
                          ),
                          child: Icon(
                            PhosphorIcons.bell(),
                            size: 20.sp,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.p12,
                    vertical: AppSpacing.p8,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Active clients',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Text(
                          '$totalClients',
                          style: textTheme.headlineMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        // 3. FIX: Standardized spacing token
                        SizedBox(width: AppSpacing.p8),
                        Icon(
                          PhosphorIcons.users(),
                          color: colorScheme.secondary,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Priority strip
              SliverToBoxAdapter(
                child: _PriorityStrip(
                  isDark: isDark,
                  atRisk: _atRisk,
                  slipping: _slipping,
                  onTrack: _onTrack,
                ),
              ),

              // Section eyebrow
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.p12,
                    AppSpacing.p24,
                    AppSpacing.p12,
                    AppSpacing.p12,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'ALL CLIENTS',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                          fontSize: 10.sp,
                        ),
                      ),
                      SizedBox(width: AppSpacing.p8),
                      Expanded(
                        child: Divider(
                          color: colorScheme.outlineVariant.withOpacity(0.6),
                          height: 1,
                        ),
                      ),
                      SizedBox(width: AppSpacing.p8),
                      Text(
                        'priority order',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withOpacity(0.45),
                          fontSize: 10.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Client list
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.p16,
                  0,
                  AppSpacing.p16,
                  32.h,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (ctx, i) => Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.p8),
                      child: _ClientCard(client: _clients[i], isDark: isDark),
                    ),
                    childCount: _clients.length,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Priority Strip ───────────────────────────────────────────────────────────

class _PriorityStrip extends StatelessWidget {
  final bool isDark;
  final int atRisk, slipping, onTrack;

  const _PriorityStrip({
    required this.isDark,
    required this.atRisk,
    required this.slipping,
    required this.onTrack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.p12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  sm: _SM.of(ClientStatus.atRisk, isDark),
                  count: atRisk,
                  isDark: isDark,
                ),
              ),
              SizedBox(width: AppSpacing.p8),
              Expanded(
                child: _StatTile(
                  sm: _SM.of(ClientStatus.slipping, isDark),
                  count: slipping,
                  isDark: isDark,
                ),
              ),
              SizedBox(width: AppSpacing.p8),
              Expanded(
                child: _StatTile(
                  sm: _SM.of(ClientStatus.onTrack, isDark),
                  count: onTrack,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.p12),
          // Segmented progress bar
          ClipRRect(
            borderRadius: AppTheme.defaultBorderRadius,
            child: SizedBox(
              height: 5.h,
              child: Row(
                children: [
                  if (atRisk > 0)
                    Flexible(
                      flex: atRisk * 10,
                      child: Container(
                        color: AppColors.statusRed.withOpacity(0.75),
                      ),
                    ),
                  if (atRisk > 0 && (slipping > 0 || onTrack > 0))
                    SizedBox(width: 2.w),
                  if (slipping > 0)
                    Flexible(
                      flex: slipping * 10,
                      child: Container(
                        color: AppColors.statusYellow.withOpacity(0.75),
                      ),
                    ),
                  if (slipping > 0 && onTrack > 0) SizedBox(width: 2.w),
                  if (onTrack > 0)
                    Flexible(
                      flex: onTrack * 10,
                      child: Container(
                        color: AppColors.statusGreen.withOpacity(0.75),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final _SM sm;
  final int count;
  final bool isDark;
  const _StatTile({
    required this.sm,
    required this.count,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.p8,
        vertical: AppSpacing.p8,
      ),
      decoration: BoxDecoration(
        color: sm.chip,
        borderRadius: AppTheme.defaultBorderRadius,
        border: Border.all(color: sm.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: sm.accent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: sm.accent.withOpacity(0.6),
                  blurRadius: 8,
                  spreadRadius: 1.5,
                ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.p4),
          Text(
            '$count',
            style: tt.titleSmall?.copyWith(
              color: sm.accent,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(width: AppSpacing.p8),
          Flexible(
            child: Text(
              sm.label,
              style: tt.labelMedium?.copyWith(
                color: sm.accent.withOpacity(0.8),
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Client Card ─────────────────────────────────────────────────────────────

class _ClientCard extends StatelessWidget {
  final _Client client;
  final bool isDark;

  const _ClientCard({required this.client, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final sm = _SM.of(client.status, isDark);

    return GestureDetector(
      onTap: (){
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ClientDetailsScreen()),
        );
      },
      child: ClipRRect(
        borderRadius: AppTheme.defaultBorderRadius,
        // 4. FIX: Removed unnecessary Stack widget here
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.surfaceContainerLow
                : colorScheme.surfaceContainerLowest,
            borderRadius: AppTheme.defaultBorderRadius,
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.55),
              width: 1,
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left status bar
                Container(
                  width: 4.w,
                  decoration: BoxDecoration(
                    color: sm.accent.withOpacity(0.70),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12.r),
                      bottomLeft: Radius.circular(12.r),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: sm.accent.withOpacity(0.7),
                        blurRadius: 4,
                        spreadRadius: 1.5,
                      ),
                    ],
                  ),
                ),

                // Card body
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.p12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Gold avatar
                        Container(
                          width: 44.r,
                          height: 44.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.secondary.withOpacity(0.10),
                            border: Border.all(
                              color: colorScheme.secondary.withOpacity(0.22),
                              width: 1.2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            client.initials,
                            style: textTheme.labelLarge?.copyWith(
                              color: colorScheme.secondary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),

                        SizedBox(width: AppSpacing.p12),

                        // Name + stats
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Name row + chip
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Text(
                                      client.name,
                                      style: textTheme.titleSmall?.copyWith(
                                        color: colorScheme.onSurface,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.1,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(width: AppSpacing.p8),
                                  // Status chip
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 7.w,
                                      vertical: 3.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: sm.chip,
                                      borderRadius: BorderRadius.circular(6.r),
                                      border: Border.all(
                                        color: sm.border,
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 5.r,
                                          height: 5.r,
                                          decoration: BoxDecoration(
                                            color: sm.accent,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: sm.accent.withOpacity(0.6),
                                                blurRadius: 4,
                                                spreadRadius: 1.5,
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(width: AppSpacing.p4),
                                        Text(
                                          sm.label,
                                          style: textTheme.labelSmall?.copyWith(
                                            color: sm.accent,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 10.sp,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: AppSpacing.p8),

                              // Stats row
                              Row(
                                children: [
                                  _MiniStat(
                                    icon: Icons.local_fire_department_rounded,
                                    color: AppColors.statusRed,
                                    value: '${client.streak}d',
                                    cs: colorScheme,
                                    tt: textTheme,
                                  ),
                                  _Dot(cs: colorScheme),
                                  _MiniStat(
                                    icon: Icons.bedtime_outlined,
                                    color: colorScheme.secondary,
                                    value: _Client.sleepText(client.sleepRating),
                                    cs: colorScheme,
                                    tt: textTheme,
                                  ),
                                  _Dot(cs: colorScheme),
                                  _MiniStat(
                                    icon: Icons.monitor_weight_outlined,
                                    color: colorScheme.onSurfaceVariant,
                                    value: client.weight != null
                                        ? '${client.weight!.toStringAsFixed(1)} lb'
                                        : '—',
                                    cs: colorScheme,
                                    tt: textTheme,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        SizedBox(width: AppSpacing.p4),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18.sp,
                          color: colorScheme.onSurfaceVariant.withOpacity(0.35),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Mini stat ────────────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final ColorScheme cs;
  final TextTheme tt;

  const _MiniStat({
    required this.icon,
    required this.color,
    required this.value,
    required this.cs,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11.sp, color: color),
        SizedBox(width: 3.w),
        Text(
          value,
          style: tt.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w500,
            fontSize: 11.sp,
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final ColorScheme cs;
  const _Dot({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5.w),
      child: Container(
        width: 3.r,
        height: 3.r,
        decoration: BoxDecoration(
          color: cs.onSurfaceVariant.withOpacity(0.22),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}