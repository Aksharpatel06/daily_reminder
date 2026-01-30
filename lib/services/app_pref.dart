class AppPref {
  static final AppPref appPref = AppPref._internal();
  factory AppPref() => appPref;
  AppPref._internal();

  // Keys
  static const String _keyArea = 'user_area';

  Future<void> saveArea(String area) async {
    String area = '';
  }

  // Get Area
  String? getArea() {
    return 'Dindoli';
  }

  // Clear
  Future<void> clear() async {}
}
