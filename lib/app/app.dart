
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
import 'package:nearo_app/features/matching/screens/matching_home_screen.dart';
import 'package:nearo_app/features/messages/screens/chat_room_screen.dart';
import 'package:nearo_app/features/photo/screens/photo_screen.dart';
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
import 'package:nearo_app/presentation/pages/meetzy_university_select_page.dart';
import 'package:nearo_app/presentation/pages/meetzy_email_verification_page.dart';

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
  /// 설명 주석
  String? _initialRoute;

  @override
  void initState() {
    super.initState();
    _initFcmOpenHandler();
    _resolveInitialRoute();
    _initDeepLinks();
  }

  /// 설명 주석
  Future<void> _resolveInitialRoute() async {
    final stopwatch = Stopwatch()..start();
    String? route;
    // 설명 주석
    final initialLink = await _appLinks.getInitialLink();
    final isLoginSuccessLink = initialLink != null &&
        initialLink.scheme == 'nearo' &&
        initialLink.host == 'login-success' &&
        (initialLink.queryParameters['token'] ?? '').trim().isNotEmpty;

    if (initialLink != null) {
      _handleLink(initialLink, isInitial: true);
    }

    if (isLoginSuccessLink) {
      final tokenFromLink = (initialLink.queryParameters['token'] ?? '').trim();
      if (tokenFromLink.isNotEmpty) {
        await _tokenStorage.saveAccessToken(tokenFromLink);
      }
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
          route = AppRoutes.universitySelect;
        } else {
          try {
            final status =
                await _environmentStatusRepository.getMyEnvironmentStatus();
            if (status['environmentId'] == null) {
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
    // 설명 주석
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
        arguments: {'roomId': roomId, 'partnerNickname': '상대'},
      );
    }
  }

  Future<void> _initDeepLinks() async {
    final initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) {
      _handleLink(initialLink, isInitial: true);
    }
    _linkSub = _appLinks.uriLinkStream.listen((uri) => _handleLink(uri));
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
            // 설명 주석
            final status =
                await _environmentStatusRepository.getMyEnvironmentStatus();
            if (status['environmentId'] != null) {
              // 설명 주석
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
              // 설명 주석
              _navigatorKey.currentState?.pushNamedAndRemoveUntil(
                AppRoutes.environment,
                (route) => false,
              );
            }
          } catch (_) {
            // 설명 주석
            _navigatorKey.currentState?.pushNamedAndRemoveUntil(
              AppRoutes.environment,
              (route) => false,
            );
          }
        } else {
          _navigatorKey.currentState?.pushNamedAndRemoveUntil(
            AppRoutes.universitySelect,
            (route) => false,
          );
        }
      } catch (_) {
        await _tokenStorage.clear();
      }
    }
  }

  void _handleLink(Uri uri, {bool isInitial = false}) {
    if (uri.scheme == 'nearo' && uri.host == 'login-success') {
      final token = uri.queryParameters['token'];
      if (token != null && token.isNotEmpty) {
        _tokenStorage.saveAccessToken(token);
      }
      // 코드 시작이 아닌 동안(앱이 이미 떠 있는 상태에서 링크로 복귀) 세션 복원 분기로 이동
      if (!isInitial) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _restoreSession();
        });
      }
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
                // 설명 주석
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
                  onGenerateRoute: (settings) {
                    if (settings.name == AppRoutes.emailVerification) {
                      final universityName = settings.arguments is String
                          ? settings.arguments as String
                          : (settings.arguments?.toString().trim().isNotEmpty == true
                              ? settings.arguments.toString()
                              : null);
                      return MaterialPageRoute<void>(
                        settings: RouteSettings(
                          name: settings.name,
                          arguments: universityName,
                        ),
                        builder: (ctx) => MeetzyEmailVerificationPage(
                          onBack: () => Navigator.of(ctx).pushReplacementNamed(AppRoutes.universitySelect),
                          onComplete: () => Navigator.of(ctx).pushReplacementNamed(
                            AppRoutes.universitySelect,
                            arguments: {'isInitialSetup': true},
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                  routes: {
                    AppRoutes.onboarding: (context) => MeetzyOnboardingPage(
                      onComplete: () {
                        if (context.mounted) {
                          Navigator.of(context).pushReplacementNamed(AppRoutes.login);
                        }
                      },
                    ),
                    AppRoutes.login: (_) => const LoginScreen(),
                    AppRoutes.universitySelect: (ctx) => MeetzyUniversitySelectPage(
                      onBack: () => Navigator.pushReplacementNamed(ctx, AppRoutes.login),
                      onComplete: null,
                    ),
                    AppRoutes.environment: (_) => const EnvironmentScreen(),
                    AppRoutes.matchingHome: (_) => const MatchingHomeScreen(),
                    AppRoutes.chatPreview: (_) => const ConsentPreviewScreen(),
                    AppRoutes.chatRoom: (_) => const ChatRoomScreen(),
                    AppRoutes.consentDecision: (_) => const ConsentDecisionScreen(),
                    AppRoutes.consentSuccess: (_) => const ConsentSuccessScreen(),
                    AppRoutes.photo: (_) => const PhotoScreen(),
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


