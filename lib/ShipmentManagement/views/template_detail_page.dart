import 'package:flutter/material.dart';
import 'dart:io';
import '../models/template_model.dart';
import '../services/api_service.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Web平台的文件分享模拟
import 'dart:html' as html;

class TemplateDetailPage extends StatefulWidget {
  final TemplateModel template;
  final Map<String, String> updatedDetails;

  const TemplateDetailPage({
    super.key,
    required this.template,
    required this.updatedDetails,
  });

  @override
  State<TemplateDetailPage> createState() => _TemplateDetailPageState();
}

class _TemplateDetailPageState extends State<TemplateDetailPage> {
  bool _isLoading = true;
  String? _localPdfPath;

  @override
  void initState() {
    super.initState();
    _previewDocument();
  }

  Widget _buildPdfPreview() {
    if (kIsWeb) {
      // Web平台显示文件路径
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Web平台PDF预览'),
            Text(_localPdfPath ?? '未找到文件'),
            ElevatedButton(
              onPressed: _downloadDocument,
              child: const Text('下载文件'),
            )
          ],
        ),
      );
    } else if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      // 桌面平台显示文件路径
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('PDF文件位置：'),
            Text(_localPdfPath ?? '未找到文件'),
            ElevatedButton(
              onPressed: _downloadDocument,
              child: const Text('下载文件'),
            )
          ],
        ),
      );
    } else if (Platform.isAndroid || Platform.isIOS) {
      // 移动平台使用 PDFView
      return PDFView(
        filePath: _localPdfPath!,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: false,
        pageFling: true,
      );
    } else {
      return const Center(
        child: Text('当前平台不支持PDF预览'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloadDocument,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _localPdfPath != null
              ? _buildPdfPreview()
              : const Center(child: Text('无法加载PDF')),
    );
  }

  Future<void> _downloadDocument() async {
    try {
      final filePath = await ApiService.generateDocument(
          widget.updatedDetails, widget.template.name, Format.docx.value);

      if (kIsWeb) {
        // Web平台使用浏览器下载
        _downloadFileWeb(filePath);
      } else {
        // 移动和桌面平台使用 share_plus
        if (File(filePath).existsSync()) {
          await Share.shareXFiles(
            [XFile(filePath)],
            text: '分享文档：${widget.template.name}',
          ).catchError((error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('分享失败: $error')),
            );
            return const ShareResult('', ShareResultStatus.dismissed);
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('文件路径无效')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('下载失败: $e')),
      );
    }
  }

  // Web平台下载文件的特殊方法
  void _downloadFileWeb(String filePath) {
    // 使用 HTML5 的下载功能
    if (!kIsWeb) return;

    final fileName = filePath.split('/').last;
    final anchor = html.AnchorElement(href: filePath)
      ..setAttribute('download', fileName)
      ..style.display = 'none';

    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
  }

  void _previewDocument() async {
    try {
      final pdfPath = await ApiService.generateDocument(
          widget.updatedDetails, widget.template.name, Format.pdf.value);

      if (kIsWeb || File(pdfPath).existsSync()) {
        setState(() {
          _localPdfPath = pdfPath;
          _isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法加载PDF')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('文档生成失败: $e')),
        );
      }
    }
  }
}
