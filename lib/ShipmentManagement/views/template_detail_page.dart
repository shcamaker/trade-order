import 'package:flutter/material.dart';
import 'dart:io';
import '../models/template_model.dart';
import '../services/api_service.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:share_plus/share_plus.dart';

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
            onPressed: () {
              _downloadDocument();
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _localPdfPath != null
              ? PDFView(
                  filePath: _localPdfPath!,
                  enableSwipe: true,
                  swipeHorizontal: false,
                  autoSpacing: false,
                  pageFling: true,
                )
              : const Center(child: Text('无法加载PDF')),
    );
  }

  Future<void> _downloadDocument() async {
    final filePath = await ApiService.generateDocument(
        widget.updatedDetails, widget.template.name, Format.docx.value);
    if (!mounted) return;

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

  void _previewDocument() async {
    try {
      final pdfPath = await ApiService.generateDocument(
          widget.updatedDetails, widget.template.name, Format.pdf.value);

      if (File(pdfPath).existsSync()) {
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
