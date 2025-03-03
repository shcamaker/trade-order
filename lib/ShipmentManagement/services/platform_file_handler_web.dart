// 此文件只在Web平台编译时使用
import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

Future<void> downloadFileWebImpl(List<int> bytes, String fileName) async {
  if (kIsWeb) {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement()
      ..href = url
      ..style.display = 'none'
      ..download = fileName;
    
    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }
} 