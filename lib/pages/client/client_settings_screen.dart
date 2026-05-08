import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../auth/get_started.dart';

class ClientSettingsScreen extends StatelessWidget {
  const ClientSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final authProvider = context.watch<AuthProvider>();

    final user = authProvider.currentUser;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // 🔹 Mock/Extracted data
    final clientName = user?.name ?? 'Fitness Member';
    final clientEmail = user?.email ?? 'member@valenceapp.com';
    const coachName = 'Coach Alex Morgan'; // This would eventually come from a CoachProvider

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
              // 1. Profile Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.secondaryColor.withAlpha(50),
                    child: Text(
                      clientName.isNotEmpty ? clientName[0].toUpperCase() : 'U',
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
                          clientName,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: AppSpacing.p4),
                        Text(
                          clientEmail,
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

              // 2. Coach Connection Info
              Text(
                "MY COACH",
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
                  color: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
                  borderRadius: AppTheme.defaultBorderRadius,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.fitness_center, color: AppColors.secondaryColor),
                    SizedBox(width: AppSpacing.p16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          coachName,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Active Program",
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: AppSpacing.p32),

              // 3. Simple Mock Settings
              _buildSettingsTile(
                icon: Icons.person_outline,
                title: "Edit Profile",
                onTap: () {},
              ),
              _buildSettingsTile(
                icon: Icons.notifications_none,
                title: "Notifications",
                onTap: () {},
              ),
              _buildSettingsTile(
                icon: Icons.help_outline,
                title: "Help & Support",
                onTap: () {},
              ),

              SizedBox(height: AppSpacing.p32),

              // 4. Logout (Functional)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    // Actual sign out logic
                    await context.read<AuthProvider>().signOut();

                    if (context.mounted) {
                      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const GettingStartedScreen()),
                        (route) => false,
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.p12),
                    foregroundColor: AppColors.statusRed,
                    side: BorderSide(color: AppColors.statusRed.withAlpha(100)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text(
                    "Log Out",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.p24),
              Center(
                child: Text(
                  "Valence Fitness v1.0.0",
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withAlpha(100),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 24),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
    );
  }
}
