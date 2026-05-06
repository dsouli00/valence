import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../auth/get_started.dart';

class CoachSettingsScreen extends StatelessWidget {
  const CoachSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // 🔹 Mock data (still UI-only for user)
    const coachName = 'Alex Morgan';
    const coachEmail = 'alex@valenceapp.com';
    const inviteCode = 'VAL-2847-COACH';

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
              themeProvider.isDarkMode
                  ? Icons.light_mode
                  : Icons.dark_mode,
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
                      coachName[0],
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

              // Invite Code (still fake)
              Text(
                "CLIENT INVITE CODE",
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
                      "Share this code with new clients so they can link to your roster.",
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: AppSpacing.p16),
                    SelectableText(
                      inviteCode,
                      style: textTheme.headlineSmall?.copyWith(
                        color: AppColors.secondaryColor,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4.0,
                      ),
                    ),
                    SizedBox(height: AppSpacing.p16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondaryColor,
                          foregroundColor: AppColors.primaryColor,
                        ),
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text("Copy Code"),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: AppSpacing.p32),

              // Logout stays real
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
                    padding:
                    EdgeInsets.symmetric(vertical: AppSpacing.p12),
                    foregroundColor: AppColors.statusRed,
                    side: BorderSide(
                        color: AppColors.statusRed.withAlpha(100)),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text(
                    "Log Out",
                    style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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