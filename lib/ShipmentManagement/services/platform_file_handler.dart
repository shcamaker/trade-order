import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import '../../config.dart';

// 导入平台特定的实现
import 'platform_file_handler_web.dart' if (dart.library.io) 'platform_file_handler_native.dart' as impl;

Future<void> downloadFile(List<int> bytes, String fileName) async {
  if (kIsWeb) {
    await impl.downloadFileWeb(bytes, fileName);
  } else {
    await impl.downloadFileNative(bytes, fileName);
  }
}

// 委托给平台特定的实现
Future<void> downloadFileWeb(List<int> bytes, String fileName) async {
  await impl.downloadFileWeb(bytes, fileName);
}

Future<void> downloadFileNative(List<int> bytes, String fileName) async {
  await impl.downloadFileNative(bytes, fileName);
} 