import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../config.dart';  // Import the Config class

class ApiService {
  static String get baseUrl => Config.baseUrl;

  static Future<String> generateDocument(
      Map<String, String> details, String filename, String format, [bool previewMode = false]) async {
    try {
      // URL encode the filename to handle special characters
      final encodedFilename = Uri.encodeComponent(filename);
      
      final uri = Uri.parse('$baseUrl/api/generate-document/$encodedFilename').replace(
        queryParameters: {
          'format': format.toLowerCase(),
          'preview_mode': previewMode.toString(),
        },
      );
      
      final response = await http
          .post(
        uri,
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

}
