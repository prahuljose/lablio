import 'package:shared_preferences/shared_preferences.dart';

const _key = 'onboarding_seen';

/// Loaded once at startup so the router's redirect can read it synchronously.
bool gOnboardingSeen = true;

Future<void> loadOnboardingSeen() async {
  final prefs = await SharedPreferences.getInstance();
  gOnboardingSeen = prefs.getBool(_key) ?? false;
}

Future<void> markOnboardingSeen() async {
  gOnboardingSeen = true;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_key, true);
}
