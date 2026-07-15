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
                              // The poster is 9:16 — taller than the space
                              // between the header and the CTA on most phones.
                              // FittedBox scales the PREVIEW to fit; the
                              // rasterized PNG is unaffected because
                              // toImage() captures the boundary's own layout
                              // size, not what the screen shows.
                              : FittedBox(
                                  child: SizedBox(
                                    width: 360,
                                    child: RepaintBoundary(
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


/// The poster. A 9:16 story frame — WhatsApp status and Instagram stories are
/// where this gets posted, and that is the shape they want.
///
/// Composition: the NUMBER is the headline (what happened) and the GRID is the
/// receipt (proof it happened). Same philosophy as the coach's AI card — a
/// claim is worthless next to the evidence for it.
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

    // The hero is whichever fact is biggest and TRUE — never an invented one.
    String heroValue;
    String heroLabel;
    String? heroSub;
    switch (summary.hero) {
      case WinHero.weight:
        final shown = displayWeight(summary.weightDeltaKg!.abs(), client.weightUnit);
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

    return AspectRatio(
      aspectRatio: 9 / 16,
      child: Container(
        decoration: BoxDecoration(
          color: t.canvas,
          borderRadius: BorderRadius.circular(VRadius.card),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Atmosphere is allowed here — this is a Moment (§1.9 / §4-D).
            const Positioned.fill(child: VSkyGlow()),
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 32, 30, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // NOTE ON TYPE: everything here is sized for a POSTER, not
                  // for a phone row. The first version reused the UI ramp
                  // (subhead 13 / caption 12) and it rendered ~3% of the width
                  // of a 1080px story — unreadable, which is exactly what
                  // Yassine saw. A card that becomes a story needs its own,
                  // much larger scale.
                  Text(
                    'VALENCE',
                    style: VType.label.copyWith(
                      color: t.legibleTint(t.gold),
                      fontSize: 15,
                      letterSpacing: 2.4,
                    ),
                  ),
                  const Spacer(flex: 2),

                  // ---- the headline.
                  Text(client.name,
                      style: VType.subhead
                          .copyWith(color: t.inkSecondary, fontSize: 20)),
                  const SizedBox(height: 12),
                  VTextScaleCap(
                    child: Text(
                      heroValue,
                      style: VType.display.copyWith(
                        color: t.legibleTint(t.gold),
                        fontSize: 96,
                        height: 0.92,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(heroLabel,
                      style: VType.serifTitle
                          .copyWith(color: t.ink, fontSize: 32)),
                  if (heroSub != null) ...[
                    const SizedBox(height: 6),
                    Text(heroSub,
                        style: VType.subhead
                            .copyWith(color: t.inkSecondary, fontSize: 18)),
                  ],

                  const Spacer(flex: 2),

                  // ---- the receipt.
                  _MonthGrid(levels: summary.dayLevels),

                  const Spacer(flex: 2),

                  // ---- the quiet facts.
                  _StatLine(summary: summary),
                  const SizedBox(height: 14),
                  Divider(height: 1, thickness: 1, color: t.hairline),
                  const SizedBox(height: 12),
                  // The growth loop, said once and quietly: the client's post
                  // advertises their coach.
                  Text(
                    coachName.trim().isEmpty
                        ? ''
                        : l10n.shareWinCoachedBy(coachName),
                    style: VType.caption
                        .copyWith(color: t.inkSecondary, fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// THE SIGNATURE: a month of effort, one cell per day, **7 per row so each row
/// is a week** — that is what makes the rhythm legible (the weekends someone
/// always drops, the week they came back).
///
/// Gold intensity = how much of the day they did. Missed days stay as empty
/// cells rather than vanishing: the gaps are what make a full grid mean
/// anything, and a card that hid them would be bragging, not proof.
class _MonthGrid extends StatelessWidget {
  const _MonthGrid({required this.levels});

  final List<int> levels;

  static const int _cols = 7;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // Pad the FRONT so the last cell is always the most recent day and the
    // rows stay aligned as weeks.
    final rows = (levels.length / _cols).ceil();
    final pad = rows * _cols - levels.length;
    final cells = [...List.filled(pad, -1), ...levels];

    Color fill(int level) => switch (level) {
          -1 => Colors.transparent,
          0 => t.gold.withValues(alpha: t.isLight ? 0.08 : 0.10),
          1 => t.gold.withValues(alpha: 0.34),
          2 => t.gold.withValues(alpha: 0.66),
          _ => t.gold,
        };

    return LayoutBuilder(
      builder: (context, c) {
        const gap = 6.0;
        final size = (c.maxWidth - gap * (_cols - 1)) / _cols;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var r = 0; r < rows; r++) ...[
              Row(
                children: [
                  for (var i = 0; i < _cols; i++) ...[
                    if (i > 0) const SizedBox(width: gap),
                    Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: fill(cells[r * _cols + i]),
                        borderRadius: BorderRadius.circular(size * 0.28),
                      ),
                    ),
                  ],
                ],
              ),
              if (r < rows - 1) const SizedBox(height: gap),
            ],
          ],
        );
      },
    );
  }
}

/// Streak · days · sessions, as one quiet tabular line. Deliberately NOT three
/// stat columns with icons — the grid above is the signature, and a second
/// visual would fight it (design.md §6-9: one per screen).
class _StatLine extends StatelessWidget {
  const _StatLine({required this.summary});

  final WinSummary summary;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l10n = context.l10n;
    final num = VType.subhead.copyWith(
      color: t.ink,
      fontSize: 17,
      fontWeight: FontWeight.w700,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final lab = VType.subhead.copyWith(color: t.inkTertiary, fontSize: 17);

    return Text.rich(
      TextSpan(children: [
        TextSpan(text: '${summary.streak}', style: num),
        TextSpan(text: ' ${l10n.shareWinStatStreak.toLowerCase()}   ', style: lab),
        TextSpan(text: '${summary.daysLogged}/${summary.daysPossible}', style: num),
        TextSpan(text: ' ${l10n.shareWinStatDays.toLowerCase()}   ', style: lab),
        TextSpan(text: '${summary.workoutsDone}', style: num),
        TextSpan(text: ' ${l10n.shareWinStatSessions.toLowerCase()}', style: lab),
      ]),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
