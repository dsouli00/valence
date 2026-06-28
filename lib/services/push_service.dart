import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:valence/models/user_model.dart';
import 'package:valence/pages/coach/client_details_screen.dart';
import 'package:valence/services/firestore_service.dart';
import 'package:valence/services/notification_service.dart';

/// Background handler for pushes that arrive while the app is terminated or
/// backgrounded. The OS displays notification messages automatically, so there's
/// nothing to do here yet — but FCM requires a registered top-level handler.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

/// App-side Firebase Cloud Messaging — receiving only.
///
/// This is the FREE half of push (no Blaze, no Cloud Functions): the app asks
/// permission, stores its device token on the user doc, and shows foreground
/// messages. The *sending* (e.g. coach at-risk alerts) is done by a separate
/// free external worker that reads Firestore and calls FCM — never from the app.
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  /// Root navigator, so a tapped push can deep-link. Wired to `MaterialApp`.
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final FirestoreService _fs = FirestoreService();
  final FirebaseMessaging _fm = FirebaseMessaging.instance;
  bool _started = false;
  StreamSubscription<String>? _tokenSub;

  /// Sets up the foreground-message + tap listeners. Call once at startup.
  Future<void> init() async {
    if (_started) return;
    _started = true;
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification != null) {
        NotificationService.instance.showNow(
          title: notification.title ?? 'Valence',
          body: notification.body ?? '',
        );
      }
    });
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);
  }

  /// Routes a tapped push. For now only the coach at-risk alert deep-links
  /// (to the client's detail screen); other taps just open the app.
  Future<void> _handleTap(RemoteMessage message) async {
    final nav = navigatorKey.currentState;
    if (nav == null) return;
    if (message.data['type'] == 'at_risk') {
      final clientId = message.data['clientId'] as String?;
      if (clientId == null || clientId.isEmpty) return;
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(clientId).get();
        if (!doc.exists) return;
        nav.push(
          MaterialPageRoute(
            builder: (_) => ClientDetailsScreen(client: AppUser.fromJson(doc.data()!, clientId)),
          ),
        );
      } catch (_) {}
    }
  }

  /// Requests permission, fetches this device's token, saves it to the user doc,
  /// and keeps it fresh on refresh. Safe to call after login.
  Future<void> syncToken(String uid) async {
    try {
      await _fm.requestPermission();
      final token = await _fm.getToken();
      if (token != null) await _fs.saveFcmToken(uid, token);
      await _tokenSub?.cancel();
      _tokenSub = _fm.onTokenRefresh.listen((t) => _fs.saveFcmToken(uid, t));
    } catch (_) {
      // e.g. iOS without an APNs key yet, or permission denied. Local reminders
      // still work, and Android push works regardless.
    }
  }

  /// Best-effort token removal on sign-out.
  Future<void> clearToken(String uid) async {
    await _tokenSub?.cancel();
    _tokenSub = null;
    try {
      await _fs.clearFcmToken(uid);
    } catch (_) {}
  }
}
