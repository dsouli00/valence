import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:valence/pages/auth/signup_screen.dart';
import '../../theme/app_theme.dart';

class ClientOnboardingScreen extends StatefulWidget {
  const ClientOnboardingScreen({super.key});

  @override
  State<ClientOnboardingScreen> createState() => _ClientOnboardingScreenState();
}

class _ClientOnboardingScreenState extends State<ClientOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      'title': 'Welcome to Valence',
      'description':
      'Your journey to fitness excellence starts here. Connect with expert coaches who care about your progress.',
      'icon': 'assets/logo/valence_logo.svg',
    },
    {
      'title': 'Track Your Progress',
      'description':
      'Log your workouts, meals, and water intake with just a few taps. Stay consistent with daily streaks.',
      'icon': 'assets/logo/valence_logo.svg',
    },
    {
      'title': 'Get Personalized Feedback',
      'description':
      'Receive real-time feedback from your coach based on your logs and progress.',
      'icon': 'assets/logo/valence_logo.svg',
    },
  ];

  void _nextPage() {
    if (_currentPage < _onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SignupScreen(userRole: "client",)),
      );
    }
  }

  void _skipOnboarding() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SignupScreen(userRole: "client",)),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          gradient: RadialGradient(
            center: const Alignment(0.0, -0.4),
            radius: 1.0,
            colors: [
              colorScheme.secondary.withOpacity(0.35),
              colorScheme.secondary.withOpacity(0.10),
              colorScheme.secondary.withOpacity(0.0),
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.p16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: 50.w,
                      height: 50.w,
                      child: SvgPicture.asset(
                        "assets/logo/valence_logo.svg",
                        colorFilter: ColorFilter.mode(
                          colorScheme.secondary,
                          BlendMode.srcIn,
                        ),
                        fit: BoxFit.contain,
                      ),
                    ),
                    TextButton(
                      onPressed: _skipOnboarding,
                      child: Text(
                        'Skip',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),

                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _onboardingData.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final page = _onboardingData[index];
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 250.w,
                            height: 250.w,
                            child: SvgPicture.asset(
                              page['icon']!,
                              colorFilter: ColorFilter.mode(
                                colorScheme.secondary,
                                BlendMode.srcIn,
                              ),
                              fit: BoxFit.contain,
                            ),
                          ),
                          SizedBox(height: AppSpacing.p24),


                          Text(
                            page['title']!,
                            textAlign: TextAlign.center,
                            style: textTheme.headlineMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: AppSpacing.p12),

                          // Description
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            child: Text(
                              page['description']!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 14.sp,
                                color: colorScheme.onSurfaceVariant,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),


                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _onboardingData.length,
                        (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      width: _currentPage == index ? 24.w : 8.w,
                      height: 8.w,
                      margin: EdgeInsets.symmetric(horizontal: 4.w),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: index == _currentPage
                            ? colorScheme.secondary
                            : colorScheme.onSurface.withOpacity(0.2),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.p24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    child: Text(
                      _currentPage == _onboardingData.length - 1
                          ? 'GET STARTED'
                          : 'NEXT',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.p16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}