import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../config.dart';

class ApiService {
  static String get baseUrl => Config.baseUrl;

  static Future<void> generateDocument(
      Map<String, String> details, String filename) async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/api/generate-document/$filename'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
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
        return;
      } else {
        final errorMessage = json.decode(response.body)['detail'] ?? '生成文档失败';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error generating document: $e');
      rethrow;
    }
  }

  static Future<String> downloadDocument(
      Map<String, String> details, String filename) async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/api/download-document/$filename'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/octet-stream',
        },
        body: json.encode(details),
      )
          .timeout(
        Config.apiTimeout,
        onTimeout: () {
          throw Exception('下载超时，请检查网络连接');
        },
      );

      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/templates/${filename}.docx';

        // 确保目录存在
        await Directory('${directory.path}/templates').create(recursive: true);

        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        return filePath;
      } else {
        final errorMessage = json.decode(response.body)['detail'] ?? '下载文档失败';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error downloading document: $e');
      rethrow;
    }
  }
}
