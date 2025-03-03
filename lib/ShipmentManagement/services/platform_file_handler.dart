import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../config.dart';

// 导入平台特定的库
// ignore: unused_import
import 'platform_file_handler_web.dart' if (dart.library.io) 'platform_file_handler_native.dart';

// 平台无关的接口
Future<void> downloadFileWeb(List<int> bytes, String fileName) async {
  if (kIsWeb) {
    // 实际实现在platform_file_handler_web.dart中
    await downloadFileWebImpl(bytes, fileName);
  }
}

Future<void> downloadFileNative(List<int> bytes, String fileName) async {
  if (!kIsWeb) {
    // 实际实现在platform_file_handler_native.dart中
    await downloadFileNativeImpl(bytes, fileName);
  }
}

// 这些函数在各自的平台特定文件中实现
@pragma('vm:entry-point')
external Future<void> downloadFileWebImpl(List<int> bytes, String fileName);

@pragma('vm:entry-point')
external Future<void> downloadFileNativeImpl(List<int> bytes, String fileName); 