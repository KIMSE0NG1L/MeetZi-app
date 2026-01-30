import 'package:flutter/material.dart';
import 'package:nearo_app/theme/nearo_theme.dart';
import 'package:nearo_app/ui/screens/onboarding/onboarding_screen.dart';

class NearoApp extends StatelessWidget {
  const NearoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NEARO',
      theme: NearoTheme.light(),
      home: const OnboardingScreen(),
    );
  }
}
