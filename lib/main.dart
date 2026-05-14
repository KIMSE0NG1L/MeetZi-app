import 'dart:convert';

import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:nearo_app/app/app.dart';
import 'package:nearo_app/app/app_routes.dart';
import 'package:nearo_app/core/ads/ad_service.dart';
import 'package:nearo_app/core/notifications/notification_service.dart';
import 'package:nearo_app/features/community/screens/community_post_detail_screen.dart';
import 'package:nearo_app/features/matching_board/screens/mailbox_screen.dart';
import 'package:nearo_app/features/notifications/data/notification_history_store.dart';
import 'package:nearo_app/features/notifications/data/pending_take_note_store.dart';
import 'package:nearo_app/shared/api/api_client.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  final notificationService = NotificationService();
  try {
    await Future.wait([
      initializeAdMob(),
      notificationService.initialize(rootNavigatorKey),
    ]).timeout(const Duration(seconds: 15));
  } catch (e) {
    debugPrint('Service init error: $e');
  }

  runApp(NearoApp(navigatorKey: rootNavigatorKey));
}
