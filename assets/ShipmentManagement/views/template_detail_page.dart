import 'package:flutter/material.dart';
import 'dart:io';
import '../models/template_model.dart';
import '../services/api_service.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

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

  Future<String?> _downloadAndGetPath(String format) async {
    try {
      final filePath = await ApiService.generateDocument(
        widget.updatedDetails,
        widget.template.name,
        format == 'pdf' ? Format.pdf.value : Format.docx.value,
        false,
      );

      if (filePath.startsWith('http')) {
        // 下载网络文件
        final response = await http.get(Uri.parse(filePath));
        if (response.statusCode == 200) {
          // 获取临时目录来保存文件
          final tempDir = await path_provider.getTemporaryDirectory();
          final fileName = '${widget.template.name}.$format';
          final tempFile = File('${tempDir.path}/$fileName');
          
          // 保存文件
          await tempFile.writeAsBytes(response.bodyBytes);
          return tempFile.path;
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('下载失败: ${response.statusCode}')),
            );
          }
        }
      } else {
        // 本地文件，直接返回路径
        return filePath;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('下载失败: $e')),
        );
      }
    }
    return null;
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
      final filePath = await _downloadAndGetPath(format);
      
      if (filePath != null) {
        // 分享本地文件
        _hideLoadingDialog();
        await Share.shareXFiles([XFile(filePath)]);
      } else {
        _hideLoadingDialog();
      }
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
      // 先下载文件到临时目录
      final tempFilePath = await _downloadAndGetPath(format);
      
      if (tempFilePath != null) {
        if (kIsWeb) {
          // Web平台直接下载
          final file = File(tempFilePath);
          final bytes = await file.readAsBytes();
          final fileName = '${widget.template.name}.$format';
          // await downloadFileWeb(bytes, fileName);
          _hideLoadingDialog();
        } else {
          // 在显示文件选择器之前隐藏加载对话框
          _hideLoadingDialog();
          
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
      } else {
        _hideLoadingDialog();
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

  void _previewDocument() async {
    try {
      final pdfPath = await ApiService.generateDocument(
          widget.updatedDetails, widget.template.name, Format.pdf.value, true);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _handleShare,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloadDocument,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: Color(0xFF4CAF50).withOpacity(0.05),
            child: const Text(
              '以下为预览效果，标有颜色的为修改的部分',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
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
