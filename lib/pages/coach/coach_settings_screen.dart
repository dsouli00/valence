import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../auth/get_started.dart';

class CoachSettingsScreen extends StatefulWidget {
  const CoachSettingsScreen({super.key});

  @override
  State<CoachSettingsScreen> createState() => _CoachSettingsScreenState();
}

class _CoachSettingsScreenState extends State<CoachSettingsScreen> {
  final _firestoreService = FirestoreService();
  String? _latestInviteLink;
  bool _isGenerating = false;

  Future<void> _generateInviteLink() async {
    final coachId = context.read<AuthProvider>().currentUser?.uid;
    if (coachId == null) return;

    setState(() => _isGenerating = true);
    try {
      // A single-use, expiring invite link keeps coach onboarding secure by default.
      final token = await _firestoreService.createCoachInviteToken(
        coachId,
        ttl: const Duration(days: 7),
        maxUses: 1,
      );
      final link = _firestoreService.buildInviteLink(token);
      if (!mounted) return;
      setState(() => _latestInviteLink = link);
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _copyInviteLink() async {
    final link = _latestInviteLink;
    if (link == null || link.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invite link copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final authProvider = context.watch<AuthProvider>();

    final coach = authProvider.currentUser;
    final coachName = coach?.name ?? 'Coach';
    final coachEmail = coach?.email ?? '';

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: false,
        title: Text(
          "Settings",
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: AppColors.secondaryColor,
            ),
            iconSize: 30,
            onPressed: () {
              context.read<ThemeProvider>().toggleTheme();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.secondaryColor.withAlpha(50),
                    child: Text(
                      coachName.isNotEmpty ? coachName[0].toUpperCase() : 'C',
                      style: textTheme.headlineMedium?.copyWith(
                        color: AppColors.secondaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: AppSpacing.p16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          coachName,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: AppSpacing.p4),
                        Text(
                          coachEmail,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.p32),
              Text(
                "SECURE CLIENT INVITE LINK",
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              SizedBox(height: AppSpacing.p12),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(AppSpacing.p16),
                decoration: BoxDecoration(
                  color: AppColors.secondaryColor.withAlpha(15),
                  borderRadius: AppTheme.defaultBorderRadius,
                  border: Border.all(
                    color: AppColors.secondaryColor.withAlpha(50),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      "Generate and share one-time invite links. New clients who use a valid link are automatically added to your dashboard as unconfigured.",
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: AppSpacing.p16),
                    SelectableText(
                      _latestInviteLink ?? 'No active link generated yet',
                      style: textTheme.bodyMedium?.copyWith(
                        color: _latestInviteLink == null
                            ? colorScheme.onSurfaceVariant
                            : AppColors.secondaryColor,
                        fontWeight:
                            _latestInviteLink == null ? FontWeight.w500 : FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: AppSpacing.p16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isGenerating ? null : _generateInviteLink,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondaryColor,
                          foregroundColor: AppColors.primaryColor,
                        ),
                        icon: _isGenerating
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.link, size: 18),
                        label: Text(_isGenerating
                            ? "Generating..."
                            : "Generate New Invite Link"),
                      ),
                    ),
                    SizedBox(height: AppSpacing.p12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: (_latestInviteLink == null || _isGenerating)
                            ? null
                            : _copyInviteLink,
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text("Copy Invite Link"),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.p32),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.read<AuthProvider>().signOut();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const GettingStartedScreen()),
                      (route) => false,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.p12),
                    foregroundColor: AppColors.statusRed,
                    side: BorderSide(color: AppColors.statusRed.withAlpha(100)),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text(
                    "Log Out",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
