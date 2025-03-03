// 此文件只在Web平台编译时使用
import 'dart:async';
import 'dart:html' as html;

Future<void> downloadFileWeb(List<int> bytes, String fileName) async {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}