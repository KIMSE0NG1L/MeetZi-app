import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:nearo_app/app/app_routes.dart';
import 'package:nearo_app/shared/theme/nearo_theme.dart';
import 'package:nearo_app/shared/theme/theme_controller.dart';
import 'package:nearo_app/shared/utils/token_storage.dart';
import 'package:nearo_app/features/auth/screens/environment_screen.dart';
import 'package:nearo_app/features/auth/screens/login_screen.dart';
import 'package:nearo_app/features/auth/screens/onboarding_screen.dart';
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
import 'package:nearo_app/features/profile/screens/avatar_setup_screen.dart';
import 'package:nearo_app/shared/widgets/version_overlay.dart';

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

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    final initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) {
      _handleLink(initialLink);
    }
    _linkSub = _appLinks.uriLinkStream.listen(_handleLink);
    await _restoreSession();
  }

  Future<void> _restoreSession() async {
    final token = await _tokenStorage.readAccessToken();
    if (token != null && token.isNotEmpty) {
      try {
        final profile = await _authRepository.getProfile();
        final user = (profile['user'] as Map?) ?? profile;
        final hasProfile = user['nickname'] != null && user['birthYear'] != null;
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
            return MaterialApp(
              title: 'NEARO',
              theme: NearoTheme.light(seedColor: color),
              darkTheme: NearoTheme.dark(seedColor: color),
              themeMode: mode,
              navigatorKey: _navigatorKey,
              initialRoute: AppRoutes.onboarding,
              builder: (context, child) {
                return Stack(
                  children: [
                    if (child != null) child,
                    const VersionOverlay(version: "1.0.0.2"),
                  ],
                );
              },
              routes: {
                AppRoutes.onboarding: (_) => const OnboardingScreen(),
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
              },
            );
          },
        );
      },
    );
  }
}
