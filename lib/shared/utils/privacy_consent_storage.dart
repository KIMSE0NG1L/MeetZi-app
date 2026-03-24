import 'package:shared_preferences/shared_preferences.dart';

class PrivacyConsentStorage {
  PrivacyConsentStorage._();

  static const String _acceptedKey = 'privacy_notice_accepted_v1';

  static Future<bool> hasAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_acceptedKey) ?? false;
  }

  static Future<void> markAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_acceptedKey, true);
  }
}
