import 'dart:convert';

import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nearo_app/app/app.dart';
import 'package:nearo_app/features/notifications/data/notification_history_store.dart';
import 'package:nearo_app/features/notifications/data/pending_take_note_store.dart';
import 'package:nearo_app/shared/api/api_client.dart';

void _saveNotificationToHistory(RemoteMessage message) {
  final id = message.messageId ?? '${message.hashCode}_${DateTime.now().millisecondsSinceEpoch}';
  NotificationHistoryStore.instance.add(
    id: id,
    title: message.notification?.title,
    body: message.notification?.body,
    data: Map<String, dynamic>.from(message.data),
  );
}

Future<void> _showForegroundLocalNotification({
  required FlutterLocalNotificationsPlugin plugin,
  required AndroidNotificationChannel channel,
  required RemoteMessage message,
  required String fallbackTitle,
  required String fallbackBody,
}) async {
  final title = message.notification?.title ?? fallbackTitle;
  final body = message.notification?.body ?? fallbackBody;

  await plugin.show(
    id: ('${message.data['type'] ?? 'notification'}_${message.messageId ?? DateTime.now().millisecondsSinceEpoch}')
        .hashCode
        .abs(),
    title: title,
    body: body,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(),
    ),
    payload: jsonEncode(message.data),
  );
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background message received: ${message.messageId}');
}

Future<void> _clearAppBadge() async {
  try {
    await AppBadgePlus.updateBadge(0);
  } catch (_) {}
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(alert: true, badge: true, sound: true);
  await messaging.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const initializationSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(),
  );
  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
  );

  const channel = AndroidNotificationChannel(
    'high_importance_channel',
    '중요 알림',
    description: '매칭과 채팅 관련 중요 알림 채널입니다.',
    importance: Importance.max,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  final token = await messaging.getToken();
  debugPrint('FCM Token: $token');
  if (token != null && token.isNotEmpty) {
    try {
      final apiClient = ApiClient();
      await apiClient.dio.post('/users/push-token', data: {'token': token});
      debugPrint('FCM token registered to server');
    } catch (e) {
      debugPrint('FCM token registration failed: $e');
    }
  }

  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null && initialMessage.data.isNotEmpty) {
    final type = initialMessage.data['type']?.toString();
    if (type == 'take_note_request') {
      final requestId = initialMessage.data['requestId']?.toString();
      if (requestId != null && requestId.isNotEmpty) {
        Map<String, dynamic>? requesterProfile;
        final rp = initialMessage.data['requesterProfile'];
        if (rp is Map) requesterProfile = Map<String, dynamic>.from(rp);
        PendingTakeNoteStore.instance.setPending(requestId, requesterProfile);
      }
    } else {
      _saveNotificationToHistory(initialMessage);
    }
  }

  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    if (message.data.isEmpty && message.notification == null) return;

    final type = message.data['type']?.toString();
    if (type == 'take_note_request') {
      final requestId = message.data['requestId']?.toString();
      if (requestId != null && requestId.isNotEmpty) {
        Map<String, dynamic>? requesterProfile;
        final rp = message.data['requesterProfile'];
        if (rp is Map) requesterProfile = Map<String, dynamic>.from(rp);
        PendingTakeNoteStore.instance.setPending(requestId, requesterProfile);
      }
      await _showForegroundLocalNotification(
        plugin: flutterLocalNotificationsPlugin,
        channel: channel,
        message: message,
        fallbackTitle: '매칭 요청',
        fallbackBody: '새로운 매칭 요청이 도착했어요.',
      );
      return;
    }

    if (type == 'take_note_accepted') {
      _saveNotificationToHistory(message);
      await _showForegroundLocalNotification(
        plugin: flutterLocalNotificationsPlugin,
        channel: channel,
        message: message,
        fallbackTitle: '매칭 수락',
        fallbackBody: '상대가 요청을 수락했어요. 대화를 시작해 보세요.',
      );
      return;
    }

    if (type == 'take_note_rejected') {
      _saveNotificationToHistory(message);
      await _showForegroundLocalNotification(
        plugin: flutterLocalNotificationsPlugin,
        channel: channel,
        message: message,
        fallbackTitle: '매칭 거절',
        fallbackBody: '상대가 요청을 거절했어요.',
      );
      return;
    }

    _saveNotificationToHistory(message);
    await _showForegroundLocalNotification(
      plugin: flutterLocalNotificationsPlugin,
      channel: channel,
      message: message,
      fallbackTitle: '알림',
      fallbackBody: message.notification?.body ?? '',
    );
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint('Notification opened app: ${message.data}');
    if (message.data.isEmpty && message.notification == null) return;

    final type = message.data['type']?.toString();
    if (type == 'take_note_request') {
      final requestId = message.data['requestId']?.toString();
      if (requestId != null && requestId.isNotEmpty) {
        Map<String, dynamic>? requesterProfile;
        final rp = message.data['requesterProfile'];
        if (rp is Map) requesterProfile = Map<String, dynamic>.from(rp);
        PendingTakeNoteStore.instance.setPending(requestId, requesterProfile);
      }
      return;
    }

    _saveNotificationToHistory(message);
  });

  await _clearAppBadge();
  runApp(const NearoApp());
}
