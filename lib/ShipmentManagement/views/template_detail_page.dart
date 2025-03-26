import 'package:flutter/material.dart';
import 'dart:io';
import '../models/template_model.dart';
import '../services/api_service.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'tips_view.dart';
import '../models/theme_colors.dart';

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

  Future<String?> _showFormatDialog() async {
    String? result;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('选择文件格式'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('Word文档 (.docx)'),
                onTap: () {
                  result = 'docx';
                  Navigator.of(dialogContext).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('PDF文档 (.pdf)'),
                onTap: () {
                  result = 'pdf';
                  Navigator.of(dialogContext).pop();
                },
              ),
            ],
          ),
        );
      },
    );
    return result;
  }

  // 显示加载对话框
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('正在生成文件...'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 隐藏加载对话框
  void _hideLoadingDialog() {
    if (mounted && Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleShare() async {
    final format = await _showFormatDialog();
    if (format == null) return;

    _showLoadingDialog();
    
    try {
      // 先下载文件
      final filePath = await ApiService.downloadTemplate(
        widget.updatedDetails,
        widget.template.name,
        format == 'pdf' ? Format.pdf.value : Format.docx.value,
        false,
      );
      
      // 分享本地文件
      _hideLoadingDialog();
      await Share.shareXFiles([XFile(filePath)]);
    } catch (e) {
      _hideLoadingDialog();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('分享失败: $e')),
        );
      }
    }
  }

  Future<void> _downloadDocument() async {
    final format = await _showFormatDialog();
    if (format == null) return;

    _showLoadingDialog();

    try {
      // 先下载文件
      final tempFilePath = await ApiService.downloadTemplate(
        widget.updatedDetails,
        widget.template.name,
        format == 'pdf' ? Format.pdf.value : Format.docx.value,
        false,
      );
      
      _hideLoadingDialog();
      if (kIsWeb) {
        _openInBrowser(tempFilePath);
        
      } else {
        
        // 让用户选择保存位置
        String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
        
        if (selectedDirectory != null && mounted) {
          // 重新显示加载对话框进行文件复制
          _showLoadingDialog();
          
          final fileName = '${widget.template.name}.$format';
          final savePath = path.join(selectedDirectory, fileName);
          
          // 复制文件到用户选择的位置
          await File(tempFilePath).copy(savePath);
          
          _hideLoadingDialog();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('文件已保存到: $savePath')),
            );
          }
        }
      }
    } catch (e) {
      _hideLoadingDialog();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('下载失败: $e')),
        );
      }
    }
  }

  // 添加在浏览器中打开PDF的方法
  Future<void> _openInBrowser(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('无法打开URL: $url');
    }
  }

  void _previewDocument() async {
    try {
      final pdfPath = await ApiService.getTemplate(
          widget.updatedDetails, widget.template.name, Format.pdf.value, true);

      setState(() {
          _localPdfPath = pdfPath;
          _isLoading = false;
      });
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('文档生成失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(widget.template.name),
        ),
        actions: [
          if (!kIsWeb)
            IconButton(
              icon: const Icon(Icons.share, color: ThemeColors.primaryColor),
              onPressed: _handleShare,
            ),
          IconButton(
            icon: const Icon(Icons.download, color: ThemeColors.primaryColor),
            onPressed: _downloadDocument,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          const TipsView(text: '注意：以下为预览效果，标有颜色的为修改的部分，下载或分享都不带颜色'),
          Expanded(
            child: _isLoading
                ? _buildPreviewLoadingView()
                : _buildPdfPreview(),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewLoadingView() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('正在生成结果预览...'),
      ],
    );
  }
}
