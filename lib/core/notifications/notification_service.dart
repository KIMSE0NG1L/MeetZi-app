import 'dart:async';
import 'dart:convert';

import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nearo_app/app/app_routes.dart';
import 'package:nearo_app/features/community/screens/community_post_detail_screen.dart';
import 'package:nearo_app/features/matching_board/screens/mailbox_screen.dart';
import 'package:nearo_app/features/notifications/data/notification_history_store.dart';
import 'package:nearo_app/features/notifications/data/pending_match_accept_store.dart';
import 'package:nearo_app/features/notifications/data/pending_take_note_store.dart';
import 'package:nearo_app/shared/api/api_client.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background message received: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    '중요 알림',
    description: '매칭과 채팅 관련 중요 알림 채널입니다.',
    importance: Importance.max,
  );

  Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await messaging.subscribeToTopic('notices');

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    final token = await messaging.getToken();
    debugPrint('FCM Token: $token');
    if (token != null && token.isNotEmpty) {
      // 토큰 등록은 백그라운드로 처리 (초기화 블로킹 방지)
      unawaited(ApiClient().dio.post('/users/push-token', data: {'token': token}).then(
        (_) => debugPrint('FCM token registered to server'),
        onError: (e) => debugPrint('FCM token registration failed: $e'),
      ));
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
      } else if (type == 'take_note_accepted') {
        final requestId = initialMessage.data['requestId']?.toString();
        if (requestId != null && requestId.isNotEmpty) {
          PendingMatchAcceptStore.instance.setPending(
            requestId: requestId,
            roomId: initialMessage.data['roomId']?.toString(),
            matchId: initialMessage.data['matchId']?.toString(),
          );
        }
        saveNotificationToHistory(initialMessage);
      } else {
        saveNotificationToHistory(initialMessage);
      }
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if (message.data.isEmpty && message.notification == null) return;

      final type = message.data['type']?.toString();
      saveNotificationToHistory(message);

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

      if (type == 'take_note_accepted') {
        final requestId = message.data['requestId']?.toString();
        if (requestId != null && requestId.isNotEmpty) {
          PendingMatchAcceptStore.instance.setPending(
            requestId: requestId,
            roomId: message.data['roomId']?.toString(),
            matchId: message.data['matchId']?.toString(),
          );
        }
        return;
      }

      if (type == 'take_note_rejected') {
        return;
      }

      // Foreground 상태에서는 중복 배너를 띄우지 않고 화면 UI만 갱신한다.
      return;
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
        WidgetsBinding.instance.addPostFrameCallback((_) {
          handleNotificationNavigation(
            navigatorKey,
            Map<String, dynamic>.from(message.data),
          );
        });
        return;
      }

      if (type == 'take_note_accepted') {
        final requestId = message.data['requestId']?.toString();
        if (requestId != null && requestId.isNotEmpty) {
          PendingMatchAcceptStore.instance.setPending(
            requestId: requestId,
            roomId: message.data['roomId']?.toString(),
            matchId: message.data['matchId']?.toString(),
          );
        }
      }

      saveNotificationToHistory(message);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        handleNotificationNavigation(
          navigatorKey,
          Map<String, dynamic>.from(message.data),
        );
      });
    });

    await clearAppBadge();
  }

  void saveNotificationToHistory(RemoteMessage message) {
    // 채팅 메시지 알림은 알림함(History)에 저장하지 않음 (사용자 요청)
    final type = message.data['type']?.toString();
    if (type == 'chat') return;

    final id =
        message.messageId ??
        '${message.hashCode}_${DateTime.now().millisecondsSinceEpoch}';
    NotificationHistoryStore.instance.add(
      id: id,
      title: message.notification?.title,
      body: message.notification?.body,
      data: Map<String, dynamic>.from(message.data),
    );
  }

  Future<void> showForegroundLocalNotification({
    required RemoteMessage message,
    required String fallbackTitle,
    required String fallbackBody,
  }) async {
    final title = message.notification?.title ?? fallbackTitle;
    final body = message.notification?.body ?? fallbackBody;

    await flutterLocalNotificationsPlugin.show(
      id:
          ('${message.data['type'] ?? 'notification'}_${message.messageId ?? DateTime.now().millisecondsSinceEpoch}')
              .hashCode
              .abs(),
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  Future<void> clearAppBadge() async {
    try {
      await AppBadgePlus.updateBadge(0);
    } catch (_) {}
  }

  void handleNotificationNavigation(
    GlobalKey<NavigatorState> navigatorKey,
    Map<String, dynamic> data,
  ) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    final type = data['type']?.toString();
    if (type == 'support_reply' || type == 'support_submitted') {
      navigator.pushNamed(AppRoutes.customerSupport);
      return;
    }
    if (type == 'community_comment_reply' || type == 'community_mention') {
      final environmentId = data['environmentId']?.toString();
      final postId = data['postId']?.toString();
      final schoolName = data['schoolName']?.toString() ?? '커뮤니티';
      if (environmentId != null &&
          environmentId.isNotEmpty &&
          postId != null &&
          postId.isNotEmpty) {
        navigator.push(
          MaterialPageRoute<void>(
            builder:
                (_) => CommunityPostDetailScreen(
                  environmentId: environmentId,
                  schoolName: schoolName,
                  postId: postId,
                ),
          ),
        );
      }
      return;
    }
    if (type == 'take_note_request') {
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => const MailboxScreen(),
        ),
      );
      return;
    }
    if (type == 'take_note_accepted') {
      final acceptedRoomId = data['roomId']?.toString();
      if (acceptedRoomId != null && acceptedRoomId.isNotEmpty) {
        navigator.pushNamed(
          AppRoutes.chatRoom,
          arguments: {
            'roomId': acceptedRoomId,
            'partnerNickname': data['partnerNickname']?.toString() ?? '',
          },
        );
      } else {
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => const MailboxScreen(),
          ),
        );
      }
      return;
    }
    final roomId = data['roomId']?.toString();
    if (roomId != null && roomId.isNotEmpty) {
      navigator.pushNamed(
        AppRoutes.chatRoom,
        arguments: {
          'roomId': roomId,
          'partnerNickname': data['partnerNickname']?.toString() ?? '',
        },
      );
    }
  }
}
