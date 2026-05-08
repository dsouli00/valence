import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:valence/models/daily_log_model.dart';
import 'package:valence/models/target_macros.dart';
import 'package:valence/pages/shared/progress_charts_section.dart';
import 'package:valence/providers/auth_provider.dart';
import 'package:valence/services/firestore_service.dart';

class ClientProgressScreen extends StatelessWidget {
  ClientProgressScreen({super.key});

  final FirestoreService _firestoreService = FirestoreService();

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
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        title: const Text('Progress'),
        centerTitle: false,
      ),
      body: StreamBuilder<List<DailyLog>>(
        stream: _firestoreService.streamRecentLogs(user.uid, days: 14),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Could not load progress right now.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }

          final logs = snapshot.data ?? const <DailyLog>[];
          return ProgressChartsSection(logs: logs, targets: targets);
        },
      ),
    );
  }
}
