import 'package:shared_preferences/shared_preferences.dart';

class ReviewerFlowStorage {
  ReviewerFlowStorage._();

  static const String _activeKey = 'reviewer_flow_active';
  static const String _stageKey = 'reviewer_flow_stage';
  static const String _coachMarkShownKey = 'meetzy_coach_mark_shown';

  static const String stageOnboarding = 'onboarding';
  static const String stageProfileSetup = 'profile_setup';
  static const String stageCompleted = 'completed';

  static Future<void> startFreshFlow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_activeKey, true);
    await prefs.setString(_stageKey, stageOnboarding);
    await prefs.remove(_coachMarkShownKey);
  }

  static Future<bool> isActive() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_activeKey) ?? false;
  }

  static Future<String> getStage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_stageKey) ?? stageOnboarding;
  }

  static Future<void> markProfileSetupReady() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_activeKey, true);
    await prefs.setString(_stageKey, stageProfileSetup);
  }

  static Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_activeKey, true);
    await prefs.setString(_stageKey, stageCompleted);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeKey);
    await prefs.remove(_stageKey);
  }
}
