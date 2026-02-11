import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nearo_app/app/app.dart';
import 'package:nearo_app/shared/api/api_client.dart';

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

  // 3. 포그라운드(앱이 켜져있을 때) 알림 처리
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      // 에러 해결: show 메서드 호출 시 모든 인자에 이름(Named)을 붙임
      flutterLocalNotificationsPlugin.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: message.data.toString(),
      );
    }
  });

  // 4. 알림 클릭 시 앱 오픈 핸들러
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('알림 클릭으로 앱 오픈: ${message.data}');
  });

  runApp(const NearoApp());
}