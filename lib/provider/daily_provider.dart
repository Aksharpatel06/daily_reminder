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
      _dailyImages.clear(); // Clear existing images

      final downloadFutures = images.map((image) => downloadImage(image));
      final files = await Future.wait(downloadFutures);

      _dailyImages = files.map((file) => file.path).toList();
    } catch (e) {
      debugPrint('Error fetching daily images: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<File> downloadImage(String url) async {
    debugPrint('Downloading image from $url');

    // Convert Google Drive viewer URL to direct download URL
    String downloadUrl = url;
    if (url.contains('drive.google.com')) {
      final idRegExp = RegExp(r'/file/d/([a-zA-Z0-9_-]+)/');
      final match = idRegExp.firstMatch(url);
      if (match != null && match.groupCount >= 1) {
        final id = match.group(1);
        downloadUrl = 'https://drive.google.com/uc?export=download&id=$id';
        debugPrint('Converted to direct link: $downloadUrl');
      }
    }

    final response = await http.get(Uri.parse(downloadUrl));

    if (response.statusCode != 200) {
      throw HttpException('Failed to download image: ${response.statusCode}');
    }

    final dir = await getApplicationCacheDirectory();
    final file = File('${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg');
    return file.writeAsBytes(response.bodyBytes);
  }
}
