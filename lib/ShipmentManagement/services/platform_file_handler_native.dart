// 此文件只在非Web平台编译时使用
import 'dart:async';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

Future<void> downloadFileWeb(List<int> bytes, String fileName) async {
  throw UnsupportedError('Web download is not supported on native platform.');
}

Future<void> downloadFileNative(List<int> bytes, String fileName) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/$fileName');
  await file.writeAsBytes(bytes);
}

Future<void> downloadFileWebImpl(List<int> bytes, String fileName) async {
  // 在非Web平台上，这个函数不会被调用，但需要提供实现
  return;
}

Future<void> downloadFileNativeImpl(List<int> bytes, String fileName) async {
  if (!kIsWeb) {
    try {
      // 获取应用文档目录
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = io.File(filePath);
      
      // 写入文件
      await file.writeAsBytes(bytes);
      
      // 在某些平台上，可以尝试打开文件
      if (io.Platform.isIOS || io.Platform.isAndroid) {
        final url = Uri.file(filePath);
        if (await canLaunchUrl(url)) {
          await launchUrl(url);
        }
      } else {
        print('File saved to: $filePath');
      }
    } catch (e) {
      print('Error saving file: $e');
    }
  }
} 