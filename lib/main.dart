import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:valence/pages/auth/splash_screen.dart';
import 'package:valence/pages/client/client_home_screen.dart';
import 'package:valence/pages/client/client_persistant_tabs.dart';
import 'package:valence/pages/coach/client_details_screen.dart';
import 'package:valence/pages/coach/coach_persistant_tabs.dart';
import 'package:valence/providers/auth_provider.dart';
import 'package:valence/providers/theme_provider.dart';
import 'package:valence/theme/app_theme.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ScreenUtil.ensureScreenSize();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const ValenceApp(),
    ),

  );
}

class ValenceApp extends StatelessWidget {
  const ValenceApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    ScreenUtil.init(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Valence',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home:  SplashScreen(),
    );
  }
}

