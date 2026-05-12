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
  await Firebase.initializeApp();

  // AdMob과 알림 서비스는 Firebase와 무관하므로 병렬 초기화
  final notificationService = NotificationService();
  await Future.wait([
    initializeAdMob(),
    notificationService.initialize(rootNavigatorKey),
  ]);

  runApp(NearoApp(navigatorKey: rootNavigatorKey));
}
