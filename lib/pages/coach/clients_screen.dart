import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:valence/models/enums.dart';
import 'package:valence/models/user_model.dart';
import 'package:valence/pages/coach/client_details_screen.dart';
import 'package:valence/providers/auth_provider.dart';
import 'package:valence/services/firestore_service.dart';
import 'package:valence/theme/app_theme.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final _firestoreService = FirestoreService();
  final Set<String> _deletingClientIds = {};

  Future<void> _confirmAndDeleteClient(AppUser client) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete client?'),
        content: Text(
          'This will permanently remove ${client.name} from your roster and delete their app data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;
    setState(() => _deletingClientIds.add(client.uid));
    try {
      // This removes client profile + all daily logs so no orphan records remain.
      await _firestoreService.deleteClientCompletely(client.uid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${client.name} was deleted')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete client')),
      );
    } finally {
      if (mounted) setState(() => _deletingClientIds.remove(client.uid));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final coach = context.watch<AuthProvider>().currentUser;
    final coachId = coach?.uid;

    if (coachId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Coach ',
                style: textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextSpan(
                text: coach?.name.split(' ').first ?? '',
                style: textTheme.titleLarge?.copyWith(
                  color: colorScheme.secondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
      body: StreamBuilder<List<AppUser>>(
        stream: _firestoreService.streamClientsByCoach(coachId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final clients = snapshot.data ?? [];
          if (clients.isEmpty) {
            return Center(
              child: Text(
                'No clients yet. Share an invite link from Profile.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }

          final sortedClients = [...clients]
            ..sort((a, b) {
              final rankA = _statusRank(a.status);
              final rankB = _statusRank(b.status);
              return rankA.compareTo(rankB);
            });

          return ListView.separated(
            padding: EdgeInsets.all(AppSpacing.p16),
            itemCount: sortedClients.length,
            separatorBuilder: (_, __) => SizedBox(height: AppSpacing.p12),
            itemBuilder: (context, index) {
              final client = sortedClients[index];
              final statusMeta = _statusMeta(client.status);
              final isDeleting = _deletingClientIds.contains(client.uid);
              final initials = _initials(client.name);

              return Container(
                padding: EdgeInsets.all(AppSpacing.p12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  borderRadius: AppTheme.defaultBorderRadius,
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: colorScheme.secondary.withAlpha(30),
                      child: Text(
                        initials,
                        style: textTheme.labelLarge?.copyWith(
                          color: colorScheme.secondary,
                          fontWeight: FontWeight.bold,
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
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: AppSpacing.p4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: statusMeta.color.withAlpha(25),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  statusMeta.label,
                                  style: textTheme.labelSmall?.copyWith(
                                    color: statusMeta.color,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              SizedBox(width: AppSpacing.p8),
                              Icon(
                                Icons.local_fire_department,
                                size: 14,
                                color: AppColors.secondaryColor,
                              ),
                              SizedBox(width: AppSpacing.p4),
                              Text(
                                '${client.currentStreak ?? 0}d',
                                style: textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Open details',
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ClientDetailsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chevron_right),
                    ),
                    IconButton(
                      tooltip: 'Delete client',
                      onPressed: isDeleting
                          ? null
                          : () {
                              _confirmAndDeleteClient(client);
                            },
                      icon: isDeleting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.delete_outline, color: AppColors.statusRed),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

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

  _StatusMeta _statusMeta(ClientStatus? status) {
    switch (status) {
      case ClientStatus.unconfigured:
        return const _StatusMeta('Unconfigured', Colors.blueGrey);
      case ClientStatus.atRisk:
        return const _StatusMeta('At Risk', AppColors.statusRed);
      case ClientStatus.slipping:
        return const _StatusMeta('Watch', AppColors.statusYellow);
      case ClientStatus.onTrack:
      case null:
        return const _StatusMeta('On Track', AppColors.statusGreen);
    }
  }
}

class _StatusMeta {
  final String label;
  final Color color;
  const _StatusMeta(this.label, this.color);
}
