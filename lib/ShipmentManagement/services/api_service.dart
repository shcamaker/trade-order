import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import '../../config.dart';

// 仅在 Web 平台导入
import 'dart:html' as html;

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
          _downloadFileWeb(response.bodyBytes, '$filename.$format');
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

  // Web平台下载文件的特殊方法
  static void _downloadFileWeb(List<int> bytes, String filename) {
    // 使用 HTML5 的下载功能
    // 注意：这段代码只能在Web平台运行
    if (!kIsWeb) return;

    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement()
      ..href = url
      ..style.display = 'none'
      ..download = filename;

    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }
}
