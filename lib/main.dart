import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:nearo_app/app/app.dart';
import 'package:nearo_app/core/ads/ad_service.dart';
import 'package:nearo_app/core/notifications/notification_service.dart';
import 'package:nearo_app/core/supabase/supabase_service.dart';

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
      SupabaseService.initialize(),
    ]).timeout(const Duration(seconds: 15));
  } catch (e) {
    debugPrint('Service init error: $e');
  }

  runApp(NearoApp(navigatorKey: rootNavigatorKey));
}
