import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../services/database_service.dart';

class DailyProvider extends ChangeNotifier {
  List<String> _dailyImages = [];
  bool _isLoading = false;

  List<String> get dailyImages => _dailyImages;
  bool get isLoading => _isLoading;

  Future<void> fetchDailyImages() async {
    _isLoading = true;
    notifyListeners();

    try {
      final images = await DatabaseService().getDailyImages();
      for (final image in images) {
        final file = await downloadImage(image);
        _dailyImages.add(file.path);
      }
    } catch (e) {
      debugPrint('Error fetching daily images: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<File> downloadImage(String url) async {
    final response = await http.get(Uri.parse(url));
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg');
    return file.writeAsBytes(response.bodyBytes);
  }
}
