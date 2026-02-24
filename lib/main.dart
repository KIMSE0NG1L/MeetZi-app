import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nearo_app/app/app.dart';
import 'package:nearo_app/features/notifications/data/notification_history_store.dart';
import 'package:nearo_app/features/notifications/data/pending_take_note_store.dart';
import 'package:nearo_app/shared/api/api_client.dart';
import 'package:app_badge_plus/app_badge_plus.dart';

void _saveNotificationToHistory(RemoteMessage message) {
  final id = message.messageId ?? '${message.hashCode}_${DateTime.now().millisecondsSinceEpoch}';
  NotificationHistoryStore.instance.add(
    id: id,
    title: message.notification?.title,
    body: message.notification?.body,
    data: Map<String, dynamic>.from(message.data),
  );
}

// 1. 백그라운드 메시지 핸들러 (최상위 함수)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('백그라운드 메시지 수신: ${message.messageId}');
}

void main() async {
  // 초기화 보장
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // FCM 설정 및 권한 요청
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(alert: true, badge: true, sound: true);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 2. 알림 플러그인 초기화
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();

    // 알림 아이콘은 반드시 drawable 폴더에 있어야 함. 없으면 기본 아이콘 사용
    const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings();

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );

  // 에러 해결: initialize 메서드 호출 방식 (버전별 대응)
  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
  );

  // 안드로이드 채널 생성 (포그라운드 알림용)
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    '중요 알림',
    description: '이 채널은 중요한 알림을 전달합니다.',
    importance: Importance.max,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // FCM 토큰 확인 및 서버 등록
  String? token = await messaging.getToken();
  print('FCM Token: $token');
  if (token != null) {
    try {
      // accessToken 읽어서 헤더 자동 추가
      final apiClient = ApiClient();
      await apiClient.dio.post(
        '/users/push-token',
        data: {'token': token},
      );
      print('FCM token registered to server');
    } catch (e) {
      print('FCM token registration failed: $e');
    }
  }



  // 알림 히스토리 저장 (알람 확인 화면에서 조회용). 매칭(가져가기) 알림은 메일함으로만 감
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

  // 3. 포그라운드(앱이 켜져있을 때) 알림 처리
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.data.isNotEmpty || message.notification != null) {
      final data = message.data;
      final type = data['type']?.toString();
      if (type == 'take_note_request') {
        final requestId = data['requestId']?.toString();
        if (requestId != null && requestId.isNotEmpty) {
          Map<String, dynamic>? requesterProfile;
          final rp = data['requesterProfile'];
          if (rp is Map) requesterProfile = Map<String, dynamic>.from(rp);
          PendingTakeNoteStore.instance.setPending(requestId, requesterProfile);
        }
        // 매칭 알림은 메일함에만 (알림 목록에 저장 안 함)
      } else {
        _saveNotificationToHistory(message);
      }
    }
    // 앱이 포그라운드일 때는 FCM 푸시 무시(로컬 알림만 표시)
    // (아래 코드를 주석 처리하거나, 조건문으로 분기 가능)
    // RemoteNotification? notification = message.notification;
    // AndroidNotification? android = message.notification?.android;
    // if (notification != null && android != null) {
    //   flutterLocalNotificationsPlugin.show(
    //     id: notification.hashCode,
    //     title: notification.title,
    //     body: notification.body,
    //     notificationDetails: NotificationDetails(
    //       android: AndroidNotificationDetails(
    //         channel.id,
    //         channel.name,
    //         channelDescription: channel.description,
    //         importance: Importance.max,
    //         priority: Priority.high,
    //         icon: '@mipmap/ic_launcher',
    //       ),
    //     ),
    //     payload: message.data.toString(),
    //   );
    // }
    // FCM 푸시 무시: 아무 동작도 하지 않음
  });

  // 4. 알림 클릭 시 앱 오픈 핸들러 (가져가기 요청이면 메일함용으로만 처리, 알림 목록에는 안 넣음)
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('알림 클릭으로 앱 오픈: ${message.data}');
    if (message.data.isNotEmpty || message.notification != null) {
      final type = message.data['type']?.toString();
      if (type == 'take_note_request') {
        final requestId = message.data['requestId']?.toString();
        if (requestId != null && requestId.isNotEmpty) {
          Map<String, dynamic>? requesterProfile;
          final rp = message.data['requesterProfile'];
          if (rp is Map) requesterProfile = Map<String, dynamic>.from(rp);
          PendingTakeNoteStore.instance.setPending(requestId, requesterProfile);
        }
      } else {
        _saveNotificationToHistory(message);
      }
    }
  });

  runApp(const NearoApp());
}