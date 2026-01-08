import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<void> saveAndLaunchFileImpl(List<int> bytes, String fileName) async {
  final base64Data = base64Encode(bytes);
  final anchor = html.AnchorElement(href: 'data:application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;base64,$base64Data')
    ..target = 'blank'
    ..download = fileName;

  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
}
