import 'file_helper_stub.dart' if (dart.library.io) 'file_helper_mobile.dart' if (dart.library.html) 'file_helper_web.dart';

class FileHelper {
  static Future<void> saveAndLaunchFile(List<int> bytes, String fileName) => saveAndLaunchFileImpl(bytes, fileName);
}
