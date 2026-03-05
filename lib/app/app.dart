
import 'package:app_links/app_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:nearo_app/app/app_routes.dart';
import 'package:nearo_app/shared/theme/nearo_theme.dart';
import 'package:nearo_app/shared/theme/theme_controller.dart';
import 'package:nearo_app/shared/utils/token_storage.dart';
import 'package:nearo_app/features/auth/screens/environment_screen.dart';
import 'package:nearo_app/features/auth/screens/login_screen.dart';
import 'package:nearo_app/features/auth/screens/onboarding_screen.dart';
import 'package:nearo_app/presentation/pages/meetzy_onboarding_page.dart';
import 'package:nearo_app/features/consent/screens/consent_decision_screen.dart';
import 'package:nearo_app/features/consent/screens/consent_preview_screen.dart';
import 'package:nearo_app/features/consent/screens/consent_success_screen.dart';
import 'package:nearo_app/features/health/screens/health_screen.dart';
import 'package:nearo_app/features/matching/screens/matching_result_screen.dart';
import 'package:nearo_app/features/matching/screens/matching_wait_screen.dart';
import 'package:nearo_app/features/matching/screens/matching_home_screen.dart';
import 'package:nearo_app/features/messages/screens/chat_room_screen.dart';
import 'package:nearo_app/features/photo/screens/photo_screen.dart';
import 'package:nearo_app/features/subscription/screens/subscription_screen.dart';
import 'package:nearo_app/features/dev/screens/api_dashboard_screen.dart';
import 'package:nearo_app/features/auth/screens/profile_screen.dart';
import 'package:nearo_app/features/profile/screens/profile_setup_screen.dart';
import 'package:nearo_app/features/profile/screens/partner_profile_screen.dart';
import 'package:nearo_app/features/users/screens/users_screen.dart';
import 'package:nearo_app/features/auth/data/auth_repository.dart';
import 'package:nearo_app/features/auth/data/environment_status_repository.dart';
import 'package:nearo_app/features/home/screens/home_shell_screen.dart';
import 'package:nearo_app/features/home/screens/splash_screen.dart';
import 'package:nearo_app/features/matching_board/screens/take_note_request_response_screen.dart';
import 'dart:async';
import 'package:nearo_app/features/profile/screens/avatar_setup_screen.dart';
import 'package:nearo_app/features/settings/screens/customer_support_screen.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class NearoApp extends StatefulWidget {
  const NearoApp({super.key});

  @override
  State<NearoApp> createState() => _NearoAppState();
}

class _NearoAppState extends State<NearoApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _appLinks = AppLinks();
  final _tokenStorage = TokenStorage();
  final _authRepository = AuthRepository();
  final _environmentStatusRepository = EnvironmentStatusRepository();
  StreamSubscription<Uri>? _linkSub;
  Map<String, dynamic>? _pendingNotificationData;
  /// 앱 진입 시 세션 확인 후 결정. null이면 아직 확인 중(스플래시만 표시).
  String? _initialRoute;

  @override
  void initState() {
    super.initState();
    _initFcmOpenHandler();
    _resolveInitialRoute();
    _initDeepLinks();
  }

  /// 세션 확인 후 첫 화면 라우트만 결정. 최소 3.3초 스플래시 표시 후 설정.
  Future<void> _resolveInitialRoute() async {
    final stopwatch = Stopwatch()..start();
    String? route;
    // 로그인 성공 딥링크 등 초기 링크 먼저 처리(토큰 저장) 후 토큰 기준으로 라우트 결정
    final initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) {
      _handleLink(initialLink);
    }
    final token = await _tokenStorage.readAccessToken();
    if (token == null || token.isEmpty) {
      route = AppRoutes.onboarding;
    } else {
      try {
        final profile = await _authRepository.getProfile();
        final user = (profile['user'] as Map?) ?? profile;
        final hasProfile = user['nickname'] != null;
        final hasAffiliation =
            (user['affiliationText'] as String?)?.trim().isNotEmpty ?? false;
        if (!hasProfile || !hasAffiliation) {
          route = AppRoutes.profileSetup;
        } else {
          try {
            final status =
                await _environmentStatusRepository.getMyEnvironmentStatus();
            if (status == null || status['environmentId'] == null) {
              route = AppRoutes.environment;
            } else if (status['verified'] == true) {
              route = AppRoutes.home;
            } else {
              route = AppRoutes.environment;
            }
          } catch (_) {
            route = AppRoutes.environment;
          }
        }
      } catch (_) {
        await _tokenStorage.clear();
        route = AppRoutes.onboarding;
      }
    }
    // Design 스플래시: 최소 3.3초 표시 후 화면 전환
    final elapsed = stopwatch.elapsedMilliseconds;
    if (elapsed < 3300) {
      await Future.delayed(Duration(milliseconds: 3300 - elapsed));
    }
    if (mounted) setState(() => _initialRoute = route);
  }

  Future<void> _initFcmOpenHandler() async {
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial?.data != null && initial!.data.isNotEmpty) {
      _pendingNotificationData = Map<String, dynamic>.from(initial.data);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pendingNotificationData != null) {
          _handleNotificationData(_pendingNotificationData!);
          _pendingNotificationData = null;
        }
      });
    }
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage msg) {
      if (msg.data.isNotEmpty) {
        _handleNotificationData(Map<String, dynamic>.from(msg.data));
      }
    });
  }

  void _handleNotificationData(Map<String, dynamic> data) {
    final type = data['type']?.toString();
    if (type == 'support_reply' || type == 'support_submitted') {
      _navigatorKey.currentState?.pushNamed(AppRoutes.customerSupport);
      return;
    }
    if (type == 'take_note_request') {
      final requestId = data['requestId']?.toString();
      if (requestId != null && requestId.isNotEmpty) {
        Map<String, dynamic>? requesterProfile;
        final rp = data['requesterProfile'];
        if (rp is Map) requesterProfile = Map<String, dynamic>.from(rp);
        _navigatorKey.currentState?.push(
          MaterialPageRoute<void>(
            builder: (_) => TakeNoteRequestResponseScreen(
              requestId: requestId,
              requesterProfile: requesterProfile,
            ),
          ),
        );
      }
      return;
    }
    final roomId = data['roomId']?.toString();
    if (roomId != null && roomId.isNotEmpty) {
      _navigatorKey.currentState?.pushNamed(
        AppRoutes.chatRoom,
        arguments: {'roomId': roomId, 'partnerNickname': '대화'},
      );
    }
  }

  Future<void> _initDeepLinks() async {
    final initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) {
      _handleLink(initialLink);
    }
    _linkSub = _appLinks.uriLinkStream.listen(_handleLink);
  }

  Future<void> _restoreSession() async {
    final token = await _tokenStorage.readAccessToken();
    if (token != null && token.isNotEmpty) {
      try {
        final profile = await _authRepository.getProfile();
        final user = (profile['user'] as Map?) ?? profile;
        final hasProfile = user['nickname'] != null;
        final hasAffiliation = (user['affiliationText'] as String?)
                ?.trim()
                .isNotEmpty ??
            false;
        if (hasProfile && hasAffiliation) {
          try {
            // 환경 정보 확인
            final status =
                await _environmentStatusRepository.getMyEnvironmentStatus();
            if (status != null && status['environmentId'] != null) {
              // 환경이 설정되어 있음
              if (status['verified'] == true) {
                _navigatorKey.currentState?.pushNamedAndRemoveUntil(
                  AppRoutes.home,
                  (route) => false,
                );
              } else {
                _navigatorKey.currentState?.pushNamedAndRemoveUntil(
                  AppRoutes.environment,
                  (route) => false,
                );
              }
            } else {
              // 환경이 설정되지 않았으면 환경 선택 화면으로
              _navigatorKey.currentState?.pushNamedAndRemoveUntil(
                AppRoutes.environment,
                (route) => false,
              );
            }
          } catch (_) {
            // 환경 조회 실패 시 환경 선택 화면으로
            _navigatorKey.currentState?.pushNamedAndRemoveUntil(
              AppRoutes.environment,
              (route) => false,
            );
          }
        } else {
          _navigatorKey.currentState?.pushNamedAndRemoveUntil(
            AppRoutes.profileSetup,
            (route) => false,
          );
        }
      } catch (_) {
        await _tokenStorage.clear();
      }
    }
  }

  void _handleLink(Uri uri) {
    if (uri.scheme == 'nearo' && uri.host == 'login-success') {
      final token = uri.queryParameters['token'];
      if (token != null && token.isNotEmpty) {
        _tokenStorage.saveAccessToken(token);
      }
      _restoreSession();
    }
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeMode,
      builder: (context, mode, _) {
        return ValueListenableBuilder<Color>(
          valueListenable: ThemeController.seedColor,
          builder: (context, color, __) {
            return ValueListenableBuilder<bool>(
              valueListenable: ThemeController.secretMode,
              builder: (context, secret, ___) {
                // 세션 확인이 끝나기 전에는 Design 스타일 스플래시 표시
                if (_initialRoute == null) {
                  final theme = secret
                      ? NearoTheme.secret(seedColor: color)
                      : NearoTheme.light(seedColor: color);
                  return MaterialApp(
                    title: 'NEARO',
                    theme: theme,
                    debugShowCheckedModeBanner: false,
                    home: SplashScreen(
                      onComplete: () {},
                    ),
                  );
                }
                return MaterialApp(
                  title: 'NEARO',
                  theme: secret ? NearoTheme.secret(seedColor: color) : NearoTheme.light(seedColor: color),
                  darkTheme: secret ? NearoTheme.secret(seedColor: color) : NearoTheme.dark(seedColor: color),
                  themeMode: mode,
                  navigatorKey: _navigatorKey,
                  initialRoute: _initialRoute,
                  builder: (context, child) => child ?? const SizedBox.shrink(),
                  routes: {
                    AppRoutes.onboarding: (context) => MeetzyOnboardingPage(
                      onComplete: () {
                        if (context.mounted) {
                          Navigator.of(context).pushReplacementNamed(AppRoutes.login);
                        }
                      },
                    ),
                    AppRoutes.login: (_) => const LoginScreen(),
                    AppRoutes.environment: (_) => const EnvironmentScreen(),
                    AppRoutes.matchingResult: (_) => const MatchingResultScreen(),
                    AppRoutes.matchingHome: (_) => const MatchingHomeScreen(),
                    AppRoutes.chatPreview: (_) => const ConsentPreviewScreen(),
                    AppRoutes.chatRoom: (_) => const ChatRoomScreen(),
                    AppRoutes.consentDecision: (_) => const ConsentDecisionScreen(),
                    AppRoutes.consentSuccess: (_) => const ConsentSuccessScreen(),
                    AppRoutes.apiDashboard: (_) => const ApiDashboardScreen(),
                    AppRoutes.photo: (_) => const PhotoScreen(),
                    AppRoutes.subscription: (_) => const SubscriptionScreen(),
                    AppRoutes.health: (_) => const HealthScreen(),
                    AppRoutes.authProfile: (_) => const ProfileScreen(),
                    AppRoutes.users: (_) => const UsersScreen(),
                    AppRoutes.profileSetup: (_) => const ProfileSetupScreen(),
                    AppRoutes.avatarSetup: (_) => AvatarSetupScreen(),
                    AppRoutes.partnerProfile: (_) => const PartnerProfileScreen(),
                    AppRoutes.home: (_) => const HomeShellScreen(),
                    AppRoutes.customerSupport: (_) => const CustomerSupportScreen(),
                  },
                  navigatorObservers: [routeObserver],
                );
              },
            );
          },
        );
      },
    );
  }
}
