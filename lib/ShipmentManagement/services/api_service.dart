import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../config.dart';
import 'package:flutter/foundation.dart' show debugPrint;

// Platform-specific imports
// Use separate imports and let Dart's tree-shaking optimize them
import 'dart:io';  // Only used on non-web platforms
import 'package:path_provider/path_provider.dart';  // Only used on non-web platforms

class ApiService {
  static String get baseUrl => Config.baseUrl;

  static Future<String> getTemplate(
      Map<String, String> details, String filename, String format, [bool previewMode = false]) async {
    try {
      // URL encode the filename to handle special characters
      final encodedFilename = Uri.encodeComponent(filename);
      
      final uri = Uri.parse('$baseUrl/api/download-template/$encodedFilename').replace(
        queryParameters: {
          'format': format.toLowerCase(),
          'preview_mode': previewMode.toString(),
        },
      );
      
      // 添加调试日志
      debugPrint('发送模板请求：$uri');
      debugPrint('请求参数：${json.encode(details)}');
      
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

      // 添加状态码和响应头的调试信息
      debugPrint('响应状态码: ${response.statusCode}');
      debugPrint('响应头: ${response.headers}');
      
      if (response.statusCode == 200) {
        
        // 拼接完整的HTTP URL
        final fileUrl = '$baseUrl/api/documents/$filename.$format';
        debugPrint('getTemplate fileUrl: $fileUrl');
        return fileUrl;
      } else {
        // 尝试解析错误消息
        String errorDetail;
        try {
          errorDetail = json.decode(response.body)['detail'] ?? '生成文档失败';
        } catch (e) {
          // 如果无法解析JSON，直接使用响应体
          errorDetail = 'HTTP ${response.statusCode}: ${response.body}';
        }
        
        debugPrint('获取模板失败: $errorDetail');
        throw Exception(errorDetail);
      }
    } catch (e) {
      debugPrint('Error generating document: $e');
      rethrow;
    }
  }

  static Future<String> downloadTemplate(
      Map<String, String> details, String filename, String format, [bool previewMode = false]) async {
    try {
      // URL encode the filename to handle special characters
      final encodedFilename = Uri.encodeComponent(filename);
      
      final uri = Uri.parse('$baseUrl/api/download-template/$encodedFilename').replace(
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
        if (kIsWeb) {
          final fileUrl = '$baseUrl/api/documents/$filename.$format';
          print('getTemplate fileUrl: $fileUrl');
          return fileUrl;
        } else {
          // Mobile platform
          final directory = await getApplicationDocumentsDirectory();
          final extension = format.toLowerCase();
          final filePath = '${directory.path}/templates/$filename.$extension';

          // Create directory if it doesn't exist
          await Directory('${directory.path}/templates').create(recursive: true);

          // Write file
          final file = File(filePath);
          await file.writeAsBytes(response.bodyBytes);
          return filePath;
        }
      } else {
        final errorMessage = json.decode(response.body)['detail'] ?? '生成文档失败';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error generating document: $e');
      rethrow;
    }
  }

  // 添加获取模板数据的方法
  static Future<Map<String, dynamic>> getTemplates() async {
    try {
      final uri = Uri.parse('$baseUrl/api/templates');
      
      final response = await http
          .get(
        uri,
        headers: {
          'Accept': 'application/json; charset=utf-8',
        },
      )
          .timeout(
        Config.apiTimeout,
        onTimeout: () {
          throw Exception('请求超时，请检查网络连接');
        },
      );

      if (response.statusCode == 200) {
        // 确保使用UTF-8解码
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        final errorMessage = json.decode(response.body)['detail'] ?? '获取模板数据失败';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error fetching templates: $e');
      rethrow;
    }
  }
}
