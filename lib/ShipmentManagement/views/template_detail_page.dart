import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:io' show Process;
import '../models/template_model.dart';
import '../services/api_service.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/platform_file_handler.dart';
import 'package:http/http.dart' as http;

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
    if (_localPdfPath == null) {
      return const Center(child: Text('无法加载PDF'));
    }
    
    if (_localPdfPath!.startsWith('http')) {
      // 网络PDF
      return SfPdfViewer.network(
        _localPdfPath!,
        enableDoubleTapZooming: true,
      );
    } else {
      // 本地PDF
      return SfPdfViewer.file(
        File(_localPdfPath!),
        enableDoubleTapZooming: true,
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
          : _buildPdfPreview(),
    );
  }

  Future<void> _downloadDocument() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final filePath = await ApiService.generateDocument(
          widget.updatedDetails, widget.template.name, Format.docx.value);

      // 直接在这里处理下载，不再调用_downloadFile
      if (kIsWeb) {
        // Web平台实现
        final response = await http.get(Uri.parse(filePath));
        if (response.statusCode == 200) {
          final fileName = filePath.split('/').last;
          await downloadFileWeb(response.bodyBytes, fileName);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('下载失败: ${response.statusCode}')),
          );
        }
      } else {
        // 非Web平台实现
        if (filePath.startsWith('http')) {
          final response = await http.get(Uri.parse(filePath));
          if (response.statusCode == 200) {
            final fileName = filePath.split('/').last;
            await downloadFileNative(response.bodyBytes, fileName);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('下载失败: ${response.statusCode}')),
            );
          }
        } else {
          // 本地文件路径
          final file = File(filePath);
          if (await file.exists()) {
            final fileName = filePath.split('/').last;
            await downloadFileNative(await file.readAsBytes(), fileName);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('文件未找到: $filePath')),
            );
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('下载失败: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
