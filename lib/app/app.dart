import 'package:app_links/app_links.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:nearo_app/app/app_routes.dart';
import 'package:nearo_app/shared/theme/nearo_theme.dart';
import 'package:nearo_app/shared/theme/theme_controller.dart';
import 'package:nearo_app/shared/utils/token_storage.dart';
import 'package:nearo_app/shared/utils/reviewer_flow_storage.dart';
import 'package:nearo_app/features/auth/screens/environment_screen.dart';
import 'package:nearo_app/features/auth/screens/login_screen.dart';
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
import 'package:nearo_app/shared/api/api_client.dart';
import 'package:nearo_app/shared/auth/auth_service.dart';
import 'dart:async';
import 'package:nearo_app/features/profile/screens/avatar_setup_screen.dart';
import 'package:nearo_app/features/settings/screens/privacy_consent_gate_screen.dart';
import 'package:nearo_app/features/settings/screens/customer_support_screen.dart';
import 'package:nearo_app/presentation/pages/meetzy_university_select_page.dart';
import 'package:nearo_app/presentation/pages/meetzy_email_verification_page.dart';
import 'package:nearo_app/shared/utils/privacy_consent_storage.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class NearoApp extends StatefulWidget {
  const NearoApp({super.key, this.navigatorKey});

  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  State<NearoApp> createState() => _NearoAppState();
}

class _NearoAppState extends State<NearoApp> {
  static const int _minSplashDurationMs = 3300;
  final _fallbackNavigatorKey = GlobalKey<NavigatorState>();
  final _appLinks = AppLinks();
  final _tokenStorage = TokenStorage();
  late final ApiClient _apiClient;
  late final AuthService _authService;
  late final AuthRepository _authRepository;
  final _environmentStatusRepository = EnvironmentStatusRepository();
  StreamSubscription<Uri>? _linkSub;

  /// 설명 주석
  String? _initialRoute;

  GlobalKey<NavigatorState> get _navigatorKey =>
      widget.navigatorKey ?? _fallbackNavigatorKey;

  bool _hasAvatarConfigured(Map user) {
    final avatarSeed = user['avatarSeed']?.toString().trim();
    return avatarSeed != null && avatarSeed.isNotEmpty;
  }

  Future<String> _routeAfterVerified() async {
    final hasAcceptedPrivacy = await PrivacyConsentStorage.hasAccepted();
    return hasAcceptedPrivacy ? AppRoutes.home : AppRoutes.privacyConsentGate;
  }

  bool _isAuthFailure(Object error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      return statusCode == 401 || statusCode == 403;
    }
    return false;
  }

  Future<String> _reviewerRouteAfterLogin() async {
    final stage = await ReviewerFlowStorage.getStage();
    switch (stage) {
      case ReviewerFlowStorage.stageProfileSetup:
        return AppRoutes.reviewerProfileSetup;
      case ReviewerFlowStorage.stageCompleted:
        return await _routeAfterVerified();
      case ReviewerFlowStorage.stageOnboarding:
      default:
        return AppRoutes.onboarding;
    }
  }

  @override
  void initState() {
    super.initState();

    _apiClient =
        ApiClient(onLogout: _handleLogout, tokenStorage: _tokenStorage);
    _authService = AuthService(
        apiClient: _apiClient,
        tokenStorage: _tokenStorage,
        onLogout: _handleLogout);
    _authRepository =
        AuthRepository(client: _apiClient, tokenStorage: _tokenStorage);

    _authService.init();
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
      final refreshFromLink =
          (initialLink.queryParameters['refresh_token'] ?? '').trim();
      await ReviewerFlowStorage.clear();
      if (tokenFromLink.isNotEmpty && refreshFromLink.isNotEmpty) {
        await _authRepository.saveTokens(
            accessToken: tokenFromLink, refreshToken: refreshFromLink);
      } else if (tokenFromLink.isNotEmpty) {
        // 기존 동작 유지 (구버전 호환)
        await _tokenStorage.saveAccessToken(tokenFromLink);
      }
    }

    final token = await _tokenStorage.readAccessToken();
    if (token == null || token.isEmpty) {
      route = AppRoutes.onboarding;
    } else {
      if (await ReviewerFlowStorage.isActive()) {
        route = await _reviewerRouteAfterLogin();
      } else {
      try {
        final profile = await _authRepository.getProfile();
        final user = (profile['user'] as Map?) ?? profile;
        final hasProfile = user['nickname'] != null;
        final hasAffiliation =
            (user['affiliationText'] as String?)?.trim().isNotEmpty ?? false;
        if (!hasProfile || !hasAffiliation) {
          route = AppRoutes.universitySelect;
        } else if (!_hasAvatarConfigured(user)) {
          route = AppRoutes.avatarSetup;
        } else {
          try {
            final status =
                await _environmentStatusRepository.getMyEnvironmentStatus();
            if (status['environmentId'] == null) {
              route = AppRoutes.environment;
            } else if (status['verified'] == true) {
              route = await _routeAfterVerified();
            } else {
              route = AppRoutes.environment;
            }
          } catch (e) {
            debugPrint('Error getting environment status: $e');
            route = AppRoutes.environment;
          }
        }
      } catch (e) {
        debugPrint('Error fetching profile during init: $e');
        if (_isAuthFailure(e)) {
          await _tokenStorage.clear();
          route = AppRoutes.onboarding;
        } else {
          route = await _routeAfterVerified();
        }
      }
      }
    }
    // 설명 주석
    final elapsed = stopwatch.elapsedMilliseconds;
    if (elapsed < _minSplashDurationMs) {
      await Future.delayed(
          Duration(milliseconds: _minSplashDurationMs - elapsed));
    }
    if (mounted) setState(() => _initialRoute = route);
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
      if (await ReviewerFlowStorage.isActive()) {
        final reviewerRoute = await _reviewerRouteAfterLogin();
        _navigatorKey.currentState?.pushNamedAndRemoveUntil(
          reviewerRoute,
          (route) => false,
        );
        return;
      }
      try {
        final profile = await _authRepository.getProfile();
        final user = (profile['user'] as Map?) ?? profile;
        final hasProfile = user['nickname'] != null;
        final hasAffiliation =
            (user['affiliationText'] as String?)?.trim().isNotEmpty ?? false;
        final hasAvatar = _hasAvatarConfigured(user);
        if (hasProfile && hasAffiliation && hasAvatar) {
          try {
            // 설명 주석
            final status =
                await _environmentStatusRepository.getMyEnvironmentStatus();
            if (status['environmentId'] != null) {
              // 설명 주석
              if (status['verified'] == true) {
                final nextRoute = await _routeAfterVerified();
                _navigatorKey.currentState?.pushNamedAndRemoveUntil(
                  nextRoute,
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
          } catch (e) {
            // 설명 주석
            debugPrint('Error restoring session: $e');
            _navigatorKey.currentState?.pushNamedAndRemoveUntil(
              AppRoutes.environment,
              (route) => false,
            );
          }
        } else if (hasProfile && hasAffiliation) {
          _navigatorKey.currentState?.pushNamedAndRemoveUntil(
            AppRoutes.avatarSetup,
            (route) => false,
          );
        } else {
          _navigatorKey.currentState?.pushNamedAndRemoveUntil(
            AppRoutes.universitySelect,
            (route) => false,
          );
        }
      } catch (e) {
        debugPrint('Error restoring profile: $e');
        if (_isAuthFailure(e)) {
          await _tokenStorage.clear();
          _navigatorKey.currentState?.pushNamedAndRemoveUntil(
            AppRoutes.login,
            (route) => false,
          );
        }
      }
    }
  }

  void _handleLink(Uri uri, {bool isInitial = false}) {
    if (uri.scheme == 'nearo' && uri.host == 'login-success') {
      final token = uri.queryParameters['token'];
      final refreshToken = uri.queryParameters['refresh_token'];
      if (token != null && token.isNotEmpty) {
        ReviewerFlowStorage.clear().then((_) {
          if (refreshToken != null && refreshToken.isNotEmpty) {
            _authRepository.saveTokens(
                accessToken: token, refreshToken: refreshToken);
          } else {
            _tokenStorage.saveAccessToken(token);
          }
        });
      }
      // 코드 시작이 아닌 동안(앱이 이미 떠 있는 상태에서 링크로 복귀) 세션 복원 분기로 이동
      if (!isInitial) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _restoreSession();
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    await ReviewerFlowStorage.clear();
    if (_navigatorKey.currentState != null) {
      _navigatorKey.currentState!.pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        ThemeController.themeMode,
        ThemeController.seedColor,
        ThemeController.secretMode,
      ]),
      builder: (context, _) {
        final mode = ThemeController.themeMode.value;
        final color = ThemeController.seedColor.value;
        final secret = ThemeController.secretMode.value;

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
          theme: secret
              ? NearoTheme.secret(seedColor: color)
              : NearoTheme.light(seedColor: color),
          darkTheme: secret
              ? NearoTheme.secret(seedColor: color)
              : NearoTheme.dark(seedColor: color),
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
                  onBack: () => Navigator.of(ctx)
                      .pushReplacementNamed(AppRoutes.universitySelect),
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
                    ReviewerFlowStorage.isActive().then((isReviewerFlow) async {
                      if (!context.mounted) return;
                      if (isReviewerFlow) {
                        await ReviewerFlowStorage.markProfileSetupReady();
                        if (!context.mounted) return;
                        Navigator.of(context).pushReplacementNamed(
                          AppRoutes.reviewerProfileSetup,
                        );
                        return;
                      }
                      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
                    });
                  },
                ),
            AppRoutes.login: (_) => const LoginScreen(),
            AppRoutes.universitySelect: (ctx) => MeetzyUniversitySelectPage(
                  onBack: () =>
                      Navigator.pushReplacementNamed(ctx, AppRoutes.login),
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
            AppRoutes.reviewerProfileSetup: (_) => const ProfileSetupScreen(),
            AppRoutes.avatarSetup: (_) => const AvatarSetupScreen(),
            AppRoutes.partnerProfile: (_) => const PartnerProfileScreen(),
            AppRoutes.home: (_) => const HomeShellScreen(),
            AppRoutes.customerSupport: (_) => const CustomerSupportScreen(),
            AppRoutes.privacyConsentGate: (_) =>
                const PrivacyConsentGateScreen(),
          },
          navigatorObservers: [routeObserver],
        );
      },
    );
  }
}
