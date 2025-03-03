import 'dart:async';
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import '../../config.dart';  // Import the Config class

// 使用条件导入
import 'dart:async';

class ApiService {
  static String get baseUrl => Config.baseUrl;

  static Future<String> generateDocument(
      Map<String, String> details, String filename, String format, bool previewMode) async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/api/generate-document/$filename/$format/$previewMode'),
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
          await downloadFileWeb(response.bodyBytes, '$filename.$format');
          
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

  static Future<void> downloadFileWeb(List<int> bytes, String fileName) async {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

}
