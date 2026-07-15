import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/l10n_ext.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../services/win_summary.dart';
import '../../ui/ui.dart';
import '../../utils/units.dart';

/// The shareable progress card — a Moment (design.md §4-D), so atmosphere and
/// the serif voice are allowed here in a way they are not on working screens.
///
/// WHY IT LOOKS LIKE THIS. The old "daily win" copied a line of text about one
/// day. Two things were wrong: nobody shares text (people post images), and
/// nobody brags about hitting 92% of their calories on a Tuesday. So the card
/// shows REAL progress read from their own logs — weight moved toward the goal,
/// a streak, weeks of consistency — and every number on it is a fact they can
/// point at.
///
/// THE COACH CREDIT IS THE POINT. A client's post reaches their friends, who
/// are potential CLIENTS, not coaches — and coaches are who pay. Crediting the
/// coach flips the loop: the client's post advertises their coach, so coaches
/// WANT their roster sharing, and other coaches see a peer being promoted. The
/// client is the megaphone; the coach is what is being advertised.
///
/// The card is deliberately screenshot-safe: everything that matters sits
/// inside the frame with nothing cropped, because most people will screenshot
/// rather than tap Share.
class ShareWinScreen extends StatefulWidget {
  const ShareWinScreen({
    super.key,
    required this.client,
    required this.coachName,
  });

  final AppUser client;

  /// Empty when the coach's name could not be loaded — the credit line is then
  /// dropped rather than showing "Coached by ".
  final String coachName;

  @override
  State<ShareWinScreen> createState() => _ShareWinScreenState();
}

class _ShareWinScreenState extends State<ShareWinScreen> {
  /// The window the card reports on. Long enough for weight to actually move
  /// and for consistency to mean something.
  static const int _windowDays = 30;

  final _firestore = FirestoreService();
  final _cardKey = GlobalKey();

  WinSummary? _summary;
  bool _loading = true;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final logs =
          await _firestore.streamRecentLogs(widget.client.uid, days: _windowDays).first;
      final workouts =
          await _firestore.getRecentWorkouts(widget.client.uid, days: _windowDays);
      if (!mounted) return;
      setState(() {
        _summary = computeWinSummary(
          logs: logs,
          workouts: workouts,
          today: DateTime.now(),
          windowDays: _windowDays,
          goal: widget.client.goal,
          joined: widget.client.createdAt,
          streak: widget.client.currentStreak ?? 0,
        );
        _loading = false;
      });
    } catch (e) {
      debugPrint('Share win load failed: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  /// Rasterizes the card and hands it to the OS share sheet — which is also
  /// how it gets "downloaded" (every platform's sheet offers Save Image), so
  /// there is no second gallery permission to ask for.
  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final boundary =
          _cardKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      // 3x so the PNG is crisp on a phone screen and when a platform re-encodes
      // it for a story.
      final image = await boundary.toImage(pixelRatio: 3.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw Exception('Failed to encode the card.');

      // The share sheet needs a real file on disk. Temp dir is right: the OS
      // reclaims it, and "saving" is what the sheet's own Save Image does —
      // so there is no gallery permission to ask for.
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/valence_progress.png');
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);

      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
      if (!mounted) return;
      setState(() => _sharing = false);
    } catch (e) {
      debugPrint('Share win failed: $e');
      if (!mounted) return;
      setState(() => _sharing = false);
      showVToast(context, context.l10n.shareWinFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l10n = context.l10n;
    final s = _summary;

    return Scaffold(
      backgroundColor: t.canvas,
      body: Stack(
        children: [
          const Positioned.fill(child: VSkyGlow()),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                      VSpace.screenMargin, 8, VSpace.screenMargin, 0),
                  child: Row(
                    children: [
                      VIconCircle(
                        icon: PhosphorIconsBold.caretLeft,
                        semanticLabel: l10n.back,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 12),
                      Text(l10n.shareWinTitle,
                          style: VType.title2.copyWith(color: t.ink)),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(VSpace.screenMargin),
                      child: _loading
                          ? const VSkeleton(height: 380, radius: VRadius.card)
                          : (s == null || !s.hasAnything)
                              ? VEmpty(
                                  icon: PhosphorIconsRegular.chartLineUp,
                                  title: l10n.shareWinTitle,
                                  message: l10n.shareWinNothingYet,
                                )
                              : RepaintBoundary(
                                  key: _cardKey,
                                  child: _WinCard(
                                    summary: s,
                                    client: widget.client,
                                    coachName: widget.coachName,
                                  ),
                                ),
                    ),
                  ),
                ),
                if (!_loading && s != null && s.hasAnything)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      VSpace.screenMargin,
                      0,
                      VSpace.screenMargin,
                      MediaQuery.of(context).padding.bottom + 16,
                    ),
                    child: VPillButton.primary(
                      label: l10n.shareWinCta,
                      loading: _sharing,
                      onPressed: _share,
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
// The card itself
// ---------------------------------------------------------------------------

class _WinCard extends StatelessWidget {
  const _WinCard({
    required this.summary,
    required this.client,
    required this.coachName,
  });

  final WinSummary summary;
  final AppUser client;
  final String coachName;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l10n = context.l10n;
    final metric = isMetricWeight(client.weightUnit);
    final unit = metric ? l10n.unitKg : l10n.unitLb;

    // The hero is whichever true thing is biggest — never an invented one.
    late final String heroValue;
    late final String heroLabel;
    String? heroSub;

    switch (summary.hero) {
      case WinHero.weight:
        final abs = summary.weightDeltaKg!.abs();
        final shown = displayWeight(abs, client.weightUnit);
        heroValue = shown.toStringAsFixed(metric ? 1 : 0);
        heroLabel = summary.weightDeltaKg! < 0
            ? l10n.shareWinLost('', unit).trim()
            : l10n.shareWinGained('', unit).trim();
        final weeks = (summary.weightSpanDays / 7).round();
        if (weeks >= 1) heroSub = l10n.shareWinInWeeks(weeks);
      case WinHero.streak:
        heroValue = '${summary.streak}';
        heroLabel = l10n.shareWinStreakHero(summary.streak)
            .replaceFirst('${summary.streak}', '')
            .trim();
      case WinHero.consistency:
        heroValue = '${summary.consistencyPct}%';
        heroLabel = l10n.shareWinShowedUp;
    }

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(VRadius.card),
        boxShadow: t.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            client.name,
            style: VType.caption.copyWith(color: t.inkTertiary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // The one number. Gold, because this is the moment gold is FOR.
          VTextScaleCap(
            child: Text(
              heroValue,
              style: VType.display.copyWith(
                color: t.legibleTint(t.gold),
                fontSize: 64,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            heroLabel,
            style: VType.serifTitle.copyWith(color: t.ink),
            textAlign: TextAlign.center,
          ),
          if (heroSub != null) ...[
            const SizedBox(height: 6),
            Text(
              heroSub,
              style: VType.subhead.copyWith(color: t.inkSecondary),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: 28),
          Divider(height: 1, thickness: 1, color: t.hairline),
          const SizedBox(height: 20),

          // The supporting facts. Naked data, no containers (§2 VStatColumn).
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: VStatColumn(
                  icon: PhosphorIconsFill.flame,
                  tint: t.gold,
                  value: '${summary.streak}',
                  label: l10n.shareWinStatStreak,
                  statSize: 20,
                ),
              ),
              Expanded(
                child: VStatColumn(
                  icon: PhosphorIconsFill.checkCircle,
                  tint: t.teal,
                  value: '${summary.daysLogged}',
                  label: l10n.shareWinStatDays,
                  statSize: 20,
                ),
              ),
              Expanded(
                child: VStatColumn(
                  icon: PhosphorIconsFill.barbell,
                  tint: t.clay,
                  value: '${summary.workoutsDone}',
                  label: l10n.shareWinStatSessions,
                  statSize: 20,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // The growth loop, said quietly. The coach gets the credit; Valence
          // is a wordmark, not a billboard.
          if (coachName.trim().isNotEmpty) ...[
            Text(
              l10n.shareWinCoachedBy(coachName),
              style: VType.caption.copyWith(color: t.inkSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
          ],
          Text(
            'Valence',
            style: VType.caption.copyWith(
              color: t.legibleTint(t.gold),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
