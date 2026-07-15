import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:valence/l10n/l10n_ext.dart';
import 'package:valence/models/daily_log_model.dart';
import 'package:valence/models/target_macros.dart';
import 'package:valence/pages/shared/progress_charts_section.dart';
import 'package:valence/providers/auth_provider.dart';
import 'package:valence/services/firestore_service.dart';
import 'package:valence/ui/ui.dart';

/// Progress tab — weight/calorie/macro trend charts over a selectable range.
/// Thin screen by design: all chart rendering lives in the shared
/// ProgressChartsSection, which the coach's client-details Analytics tab
/// reuses — improve charts THERE so both sides benefit.
///
/// DESIGN: §5.8 — VHeader on flat canvas; the section carries the VSegmented
/// range, VChart cards and the VStatColumn summary.
class ClientProgressScreen extends StatefulWidget {
  const ClientProgressScreen({super.key});

  @override
  State<ClientProgressScreen> createState() => _ClientProgressScreenState();
}

class _ClientProgressScreenState extends State<ClientProgressScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  ChartRange _selectedRange = ChartRange.weekly;

  // Cache the logs stream, re-created only when its key inputs (uid / range)
  // change — never inline in build (house stream-caching law): unrelated
  // rebuilds would reset the StreamBuilder to "waiting" and flash the
  // skeleton.
  Stream<List<DailyLog>>? _logsStream;
  String? _streamUid;
  int? _streamDays;
  Stream<List<DailyLog>> _logsFor(String uid, int days) {
    if (_logsStream == null || _streamUid != uid || _streamDays != days) {
      _streamUid = uid;
      _streamDays = days;
      _logsStream = _firestoreService.streamRecentLogs(uid, days: days);
    }
    return _logsStream!;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final user = context.watch<AuthProvider>().currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: t.canvas,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final targets = user.targetMacros ?? const TargetMacros();

    return Scaffold(
      backgroundColor: t.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: VSpace.screenMargin),
              child: VHeader(title: context.l10n.navProgress),
            ),
            Expanded(
              child: StreamBuilder<List<DailyLog>>(
                stream: _logsFor(user.uid, _selectedRange.days),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _ChartsSkeleton();
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        context.l10n.progressLoadError,
                        style: VType.body.copyWith(color: t.inkSecondary),
                      ),
                    );
                  }

                  final logs = snapshot.data ?? const <DailyLog>[];
                  return ProgressChartsSection(
                    logs: logs,
                    targets: targets,
                    weightUnit: user.weightUnit,
                    selectedRange: _selectedRange,
                    onRangeChanged: (value) =>
                        setState(() => _selectedRange = value),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mirrors the real layout: range pill + three chart cards.
class _ChartsSkeleton extends StatelessWidget {
  const _ChartsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsetsDirectional.fromSTEB(
          VSpace.screenMargin, 16, VSpace.screenMargin, 0),
      children: const [
        VSkeleton(height: 40, radius: VRadius.pill),
        SizedBox(height: 20),
        VSkeleton(height: 220, radius: VRadius.card),
        SizedBox(height: VSpace.cardGap),
        VSkeleton(height: 220, radius: VRadius.card),
        SizedBox(height: VSpace.cardGap),
        VSkeleton(height: 220, radius: VRadius.card),
      ],
    );
  }
}
