import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:app_badge_plus/app_badge_plus.dart';

Future<void> clearAllNotifications() async {
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin.cancelAll();
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: false,
    sound: true,
  );
  // 앱 아이콘 뱃지 제거 (setBadgeCount(0) 사용)
  try {
    await AppBadgePlus.updateBadge(0);
  } catch (e) {
    // 지원 안 하는 플랫폼 등 예외 무시
  }
}