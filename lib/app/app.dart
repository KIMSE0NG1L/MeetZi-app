import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:nearo_app/app/app_routes.dart';
import 'package:nearo_app/shared/theme/nearo_theme.dart';
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
import 'package:nearo_app/features/photo/screens/photo_screen.dart';
import 'package:nearo_app/features/subscription/screens/subscription_screen.dart';
import 'package:nearo_app/features/dev/screens/api_dashboard_screen.dart';
import 'package:nearo_app/features/auth/screens/profile_screen.dart';
import 'package:nearo_app/features/profile/screens/profile_setup_screen.dart';
import 'package:nearo_app/features/users/screens/users_screen.dart';

class NearoApp extends StatefulWidget {
  const NearoApp({super.key});

  @override
  State<NearoApp> createState() => _NearoAppState();
}

class _NearoAppState extends State<NearoApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _appLinks = AppLinks();
  final _tokenStorage = TokenStorage();
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
      _navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRoutes.profileSetup,
        (route) => false,
      );
    }
  }

  void _handleLink(Uri uri) {
    if (uri.scheme == 'nearo' && uri.host == 'login-success') {
      final token = uri.queryParameters['token'];
      if (token != null && token.isNotEmpty) {
        _tokenStorage.saveAccessToken(token);
      }
      _navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRoutes.profileSetup,
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
    return MaterialApp(
      title: 'NEARO',
      theme: NearoTheme.light(),
      navigatorKey: _navigatorKey,
      initialRoute: AppRoutes.onboarding,
      routes: {
        AppRoutes.onboarding: (_) => const OnboardingScreen(),
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.environment: (_) => const EnvironmentScreen(),
        AppRoutes.matchingWait: (_) => const MatchingWaitScreen(),
        AppRoutes.matchingResult: (_) => const MatchingResultScreen(),
        AppRoutes.chatPreview: (_) => const ConsentPreviewScreen(),
        AppRoutes.consentDecision: (_) => const ConsentDecisionScreen(),
        AppRoutes.consentSuccess: (_) => const ConsentSuccessScreen(),
        AppRoutes.apiDashboard: (_) => const ApiDashboardScreen(),
        AppRoutes.photo: (_) => const PhotoScreen(),
        AppRoutes.subscription: (_) => const SubscriptionScreen(),
        AppRoutes.health: (_) => const HealthScreen(),
        AppRoutes.authProfile: (_) => const ProfileScreen(),
        AppRoutes.users: (_) => const UsersScreen(),
        AppRoutes.profileSetup: (_) => const ProfileSetupScreen(),
      },
    );
  }
}
