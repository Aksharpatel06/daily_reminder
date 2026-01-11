import 'package:shared_preferences/shared_preferences.dart';

class AppPref {
  static final AppPref appPref = AppPref._internal();
  factory AppPref() => appPref;
  AppPref._internal();

  late SharedPreferences _preferences;

  Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  // Keys
  static const String _keyArea = 'user_area';

  Future<void> saveArea(String area) async {
    await _preferences.setString(_keyArea, area);
  }

  // Get Area
  String? getArea() {
    return _preferences.getString(_keyArea);
  }

  // Clear
  Future<void> clear() async {
    await _preferences.clear();
  }
}
