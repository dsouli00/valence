/// App entry point and root widget.
///
/// Boot order matters here: Firebase must be initialized before App Check,
/// App Check before anything that talks to Firebase AI Logic, Crashlytics as
/// early as possible after core init (so it catches failures in everything that
/// boots after it), and the background-message handler must be registered
/// before PushService so FCM messages received while the app is dead are still
/// handled. Providers are created once at the root so every screen can
/// `context.watch` them.
library;

import 'dart:ui' show PlatformDispatcher;

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kReleaseMode;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:valence/l10n/app_localizations.dart';
import 'package:valence/pages/auth/splash_screen.dart';
import 'package:valence/providers/auth_provider.dart';
import 'package:valence/providers/locale_provider.dart';
import 'package:valence/providers/theme_provider.dart';
import 'package:valence/services/notification_service.dart';
import 'package:valence/services/purchase_service.dart';
import 'package:valence/services/push_service.dart';
import 'package:valence/theme/app_theme.dart';
import 'package:valence/utils/app_info.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Portrait only. Nothing stopped the app rotating — no setPreferredOrientations
  // here, no android:screenOrientation in the manifest — and landscape is not a
  // layout anyone designed. It doesn't crash, but the Progress bars become
  // ~130dp slabs, one card fills the viewport, and the nav bar takes a fifth of
  // the height. A phone propped on a bench mid-set does this by itself.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Loads the real version string from the platform so Settings/About never
  // shows a stale hardcoded number.
  await AppInfo.load();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Crash reporting. Collection is OFF in debug so day-to-day development never
  // pollutes the console with crashes we caused ourselves — only real builds on
  // real devices report. Both error channels are routed:
  //   FlutterError.onError            → errors inside the widget/framework layer
  //   PlatformDispatcher.onError      → uncaught async errors outside the zone
  // Without the second one, a failed Future in a service reports nothing.
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true; // handled — don't also crash the app
  };

  // App Check gates the Firebase AI Logic (Gemini) proxy so only our app can
  // call it. Dev builds use the debug provider (prints a token to register in
  // the console); release builds use Play Integrity / App Attest.
  //
  // Gated on !kReleaseMode, NOT kDebugMode. Play Integrity only attests an app
  // that Play itself signed and distributed, so a locally-built profile APK
  // fails attestation — and with enforcement on, that is not a degraded app,
  // it is a blank one: every Firestore read denied. Profile is a developer
  // build like debug, and it is the build worth filming (release-grade
  // animation, Test Store purchases). It gets the developer's provider.
  await FirebaseAppCheck.instance.activate(
    providerAndroid:
        kReleaseMode ? AndroidPlayIntegrityProvider() : AndroidDebugProvider(),
    providerApple:
        kReleaseMode ? AppleAppAttestProvider() : AppleDebugProvider(),
  );
  await NotificationService.instance.init();
  // FCM push (receiving). Sending is handled by a separate free worker.
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await PushService.instance.init();
  // No-op until RevenueCat is configured (store accounts + API keys).
  await PurchaseService.instance.init();

  runApp(
    // App-wide state. AuthProvider drives routing (who am I / where do I go),
    // ThemeProvider the light/dark toggle, LocaleProvider the language
    // override. All three are cheap ChangeNotifiers, created once for the
    // whole app lifetime.
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const ValenceApp(),
    ),

  );
}

/// Root MaterialApp. Rebuilds when theme or locale changes; everything else
/// (auth routing) happens below in [SplashScreen], which decides the first
/// real screen based on auth + onboarding state.
class ValenceApp extends StatelessWidget {
  const ValenceApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // PushService uses this key to navigate from a tapped notification
      // without having a BuildContext of its own.
      navigatorKey: PushService.navigatorKey,
      title: 'Valence',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      // Localization: device language by default; user override via Settings.
      // Text direction (incl. Arabic RTL) is applied automatically per locale.
      locale: localeProvider.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Dynamic Type: clamp the system text scale app-wide to 0.85–1.3
      // (design.md §1.10). Hero styles (display/stat/serifDisplay) cap tighter
      // at 1.15 locally via VTextScaleCap so dense metrics never collide.
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(
              minScaleFactor: 0.85,
              maxScaleFactor: 1.3,
            ),
          ),
          child: child!,
        );
      },
      home: SplashScreen(),
    );
  }
}

