import 'package:flutter/material.dart';
import '../models/template_model.dart';
import '../services/api_service.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
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

  @override
  void initState() {
    super.initState();
    _loadDocument();
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
          : SfPdfViewer.network(
              "http://127.0.0.1:8000/api/documents/${widget.template.name}.pdf"),
    );
  }

  Future<void> _downloadDocument() async {
    final filePath = await ApiService.downloadDocument(
        widget.updatedDetails, widget.template.name);
    if (!mounted) return;

    // 添加空值检查
    if (filePath.isNotEmpty) {
      await Share.shareXFiles(
        [XFile(filePath)],
        text: '分享文档：${widget.template.name}', // 修复字符串插值语法
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

  void _loadDocument() async {
    await ApiService.generateDocument(
        widget.updatedDetails, "${widget.template.name}.docx");

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('文档生成成功')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }
}
