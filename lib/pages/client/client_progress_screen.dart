import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:valence/l10n/l10n_ext.dart';
import 'package:valence/models/daily_log_model.dart';
import 'package:valence/models/target_macros.dart';
import 'package:valence/pages/shared/progress_charts_section.dart';
import 'package:valence/providers/auth_provider.dart';
import 'package:valence/services/firestore_service.dart';
import 'package:valence/theme/app_theme.dart';

class ClientProgressScreen extends StatefulWidget {
  const ClientProgressScreen({super.key});

  @override
  State<ClientProgressScreen> createState() => _ClientProgressScreenState();
}

class _ClientProgressScreenState extends State<ClientProgressScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  ChartRange _selectedRange = ChartRange.weekly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = context.watch<AuthProvider>().currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final targets = user.targetMacros ?? const TargetMacros();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.p16, AppSpacing.p12, AppSpacing.p16, AppSpacing.p4),
              child: Text(
                context.l10n.navProgress,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<DailyLog>>(
                stream: _firestoreService.streamRecentLogs(
                  user.uid,
                  days: _selectedRange.days,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        context.l10n.progressLoadError,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }

                  final logs = snapshot.data ?? const <DailyLog>[];
                  return ProgressChartsSection(
                    logs: logs,
                    targets: targets,
                    weightUnit: user.weightUnit,
                    selectedRange: _selectedRange,
                    onRangeChanged: (value) => setState(() => _selectedRange = value),
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
