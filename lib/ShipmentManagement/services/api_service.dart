import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config.dart';  // Import the Config class

// 使用条件导入
import 'dart:async';
import 'dart:io' as io;

// 仅在Web平台导入dart:html
import 'platform_file_handler.dart';

class ApiService {
  static String get baseUrl => Config.baseUrl;

  static Future<String> generateDocument(
      Map<String, String> details, String filename, String format) async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/api/generate-document/$filename/$format'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/octet-stream',
        },
        body: json.encode(details),
      )
          .timeout(
        Config.apiTimeout,
        onTimeout: () {
          throw Exception('请求超时，请检查网络连接');
        },
      );

      if (response.statusCode == 200) {
        // Web平台特殊处理
        if (kIsWeb) {
          // 在Web平台，我们无法直接保存文件到本地文件系统
          // 可以考虑使用 web 特定的下载方法
          await downloadFile(response.bodyBytes, '$filename.$format');
          return '$filename.$format';
        }

        // 非Web平台（移动端和桌面端）
        final directory = await getApplicationDocumentsDirectory();
        final extension = format.toLowerCase();
        final filePath = '${directory.path}/templates/$filename.$extension';

        // 确保目录存在
        await Directory('${directory.path}/templates').create(recursive: true);

        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        return filePath;
      } else {
        final errorMessage = json.decode(response.body)['detail'] ?? '生成文档失败';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error generating document: $e');
      rethrow;
    }
  }

  // 修改下载文件方法，使用平台特定实现
  static Future<void> downloadFile(List<int> bytes, String fileName) async {
    try {
      if (kIsWeb) {
        // Web平台实现
        await downloadFileWeb(bytes, fileName);
      } else {
        // 移动端和桌面端实现
        await downloadFileNative(bytes, fileName);
      }
    } catch (e) {
      print('Error downloading file: $e');
      rethrow;
    }
  }

}
