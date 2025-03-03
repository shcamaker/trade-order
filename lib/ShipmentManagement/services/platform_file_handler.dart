import 'dart:html' as html;
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import '../../config.dart';

// 导入平台特定的库
// ignore: unused_import
import 'platform_file_handler_web.dart' if (dart.library.io) 'platform_file_handler_native.dart';

Future<void> downloadFile(List<int> bytes, String fileName) async {
  if (kIsWeb) {
    await downloadFileWeb(bytes, fileName);
  } else {
    await downloadFileNative(bytes, fileName);
  }
}

Future<void> downloadFileWeb(List<int> bytes, String fileName) async {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}

Future<void> downloadFileNative(List<int> bytes, String fileName) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/$fileName');
  await file.writeAsBytes(bytes);
}

// 这些函数在各自的平台特定文件中实现
@pragma('vm:entry-point')
external Future<void> downloadFileWebImpl(List<int> bytes, String fileName);

@pragma('vm:entry-point')
external Future<void> downloadFileNativeImpl(List<int> bytes, String fileName); 