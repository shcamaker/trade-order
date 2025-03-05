import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/template_model.dart';
import './template_edit_page.dart';
import '../services/api_service.dart';
import 'dart:io';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class TemplateListPage extends StatefulWidget {
  const TemplateListPage({super.key});

  @override
  State<TemplateListPage> createState() => _TemplateListPageState();
}

class _TemplateListPageState extends State<TemplateListPage> {
  List<TemplateModel> templates = [];
  List<TemplateModel> filteredTemplates = []; // 添加过滤后的模板列表
  bool isLoading = true;
  String _selectedFunction = '单据模板'; // 添加状态变量跟踪当前选中的功能
  String _selectedCategory = '全部'; // 添加状态变量跟踪当前选中的分类
  String? _localPdfPath; // 添加PDF路径变量
  bool _isLoading = false; // 添加PDF加载状态变量
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> _pdfPathNotifier = ValueNotifier<String?>(null);

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    try {
      // 读取JSON文件
      final String jsonString = await rootBundle
          .loadString('lib/ShipmentManagement/models/templates.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      // 解析JSON数据
      setState(() {
        templates = (jsonData['templates'] as List)
            .map((template) => TemplateModel.fromJson(template))
            .toList();
        filteredTemplates = List.from(templates); // 初始化过滤后的列表
        isLoading = false;
      });
    } catch (e) {
      print('Error loading templates: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // 根据分类过滤模板
  void _filterTemplatesByCategory(String category) {
    setState(() {
      _selectedCategory = category;
      
      if (category == '全部') {
        filteredTemplates = List.from(templates);
      } else {
        
        // 使用TemplateType.value进行比较
        filteredTemplates = templates.where((template) => 
          template.type.value == category
        ).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 定义颜色常量
    const Color primaryColor = Color(0xFF4CAF50); // 主题绿色
    const Color backgroundColor = Color(0xFFF9FAFB); // 浅灰背景色
    const Color textColor = Color(0xFF333333); // 深灰文字色
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(primaryColor, textColor),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(context, primaryColor, textColor),
    );
  }
  
  // 构建顶部导航栏
  PreferredSizeWidget _buildAppBar(Color primaryColor, Color textColor) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      toolbarHeight: 60, // 保持足够的高度
      automaticallyImplyLeading: false, // 禁用自动添加的返回按钮
      flexibleSpace: SafeArea(
        child: Column(
          children: [
            // 主要内容行
            Expanded(
              child: Row(
                children: [
                  // 左侧标题
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      Text(
                        'TRADE-ASSISTANT',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  
                  // 中间空间用于居中导航菜单
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildNavItem('单据模板', _selectedFunction == '单据模板', primaryColor, textColor),
                        _buildNavItem('客户管理', _selectedFunction == '客户管理', primaryColor, textColor),
                        _buildNavItem('订单管理', _selectedFunction == '订单管理', primaryColor, textColor),
                        _buildNavItem('统计分析', _selectedFunction == '统计分析', primaryColor, textColor),
                      ],
                    ),
                  ),
                  
                  // 右侧操作按钮
                  IconButton(
                    icon: Icon(Icons.search, color: textColor),
                    onPressed: () {},
                    tooltip: '搜索',
                  ),
                  IconButton(
                    icon: Icon(Icons.notifications_none, color: textColor),
                    onPressed: () {},
                    tooltip: '通知',
                  ),
                  const SizedBox(width: 8),
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(0xFFEEEEEE),
                    child: Icon(Icons.person, color: Color(0xFF666666), size: 20),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
            // 分隔线
            Container(
              height: 1,
              color: const Color(0xFFEEEEEE),
            ),
          ],
        ),
      ),
      // 清空title和actions，因为我们在flexibleSpace中自定义了
      title: null,
      actions: null,
    );
  }
  
  // 构建导航项
  Widget _buildNavItem(String label, bool isSelected, Color primaryColor, Color textColor) {
    return InkWell(
      onTap: () {
        setState(() {
          
          
          _selectedFunction = label;
        });
        
        // 如果选择的不是"单据模板"，显示提示
        if (label != '单据模板') {
          // 使用SnackBar显示提示信息
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('产品内容待定'),
              duration: const Duration(seconds: 2),
              action: SnackBarAction(
                label: '返回',
                onPressed: () {
                  setState(() {
                    _selectedFunction = '单据模板';
                    
                  });
                },
              ),
            ),
          );
          
          // 2秒后自动切回"单据模板"
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _selectedFunction = '单据模板';
                
              });
            }
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? primaryColor : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? primaryColor : textColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14, // 稍微减小字体以适应空间
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, Color primaryColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 只在选择"单据模板"时显示页面标题、描述和分类标签
          if (_selectedFunction == '单据模板') ...[
            // 页面标题和描述
            _buildPageHeader(primaryColor, textColor),
            
            const SizedBox(height: 24),
            
            // 模板分类标签
            _buildCategoryTabs(primaryColor),
            
            const SizedBox(height: 24),
          ],
          
          // 根据选中的功能显示不同内容
          _selectedFunction == '单据模板' 
              ? _buildTemplatesContent(context, primaryColor, textColor)
              : _buildComingSoonContent(context, primaryColor, textColor),
        ],
      ),
    );
  }
  
  // 构建页面标题和描述
  Widget _buildPageHeader(Color primaryColor, Color textColor) {
    return SizedBox(
      width: double.infinity, // 确保容器占满宽度
      child: Column(
        children: [
          Center(
            child: Text(
              '单据模板',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '选择并编辑适合您业务需求的单据模板',
              style: TextStyle(
                fontSize: 16,
                color: textColor.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
  
  // 构建分类标签
  Widget _buildCategoryTabs(Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0), // 与卡片区域保持相同的水平内边距
      child: Container(
        width: double.infinity, // 确保容器占满宽度
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCategoryChip('全部', _selectedCategory == '全部', primaryColor),
              const SizedBox(width: 16),
              _buildCategoryChip('出口单据', _selectedCategory == '出口单据', primaryColor),
              const SizedBox(width: 16),
              _buildCategoryChip('进口单据', _selectedCategory == '进口单据', primaryColor),
              const SizedBox(width: 16),
              _buildCategoryChip('其他', _selectedCategory == '其他', primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  // 创建分类标签
  Widget _buildCategoryChip(String label, bool isSelected, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: primaryColor.withAlpha(20),
        checkmarkColor: primaryColor,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? primaryColor : Colors.grey.shade300,
            width: 1,
          ),
        ),
        labelStyle: TextStyle(
          color: isSelected ? primaryColor : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (bool selected) {
          if (selected) {
            _filterTemplatesByCategory(label);
          }
        },
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // 增加内部填充
      ),
    );
  }

  // 单据模板内容
  Widget _buildTemplatesContent(BuildContext context, Color primaryColor, Color textColor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 模板网格
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0), // 增加模板区域两侧间距
              child: filteredTemplates.isEmpty
                  ? _buildEmptyState(primaryColor, textColor)
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5, // 每行显示4个卡片
                        crossAxisSpacing: 24,
                        mainAxisSpacing: 24,
                        childAspectRatio: 1.0, // 调整卡片比例为正方形
                      ),
                      itemCount: filteredTemplates.length,
                      itemBuilder: (context, index) {
                        final template = filteredTemplates[index];
                        return _buildTemplateCard(context, template, primaryColor, textColor);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
  
  // 构建空状态提示
  Widget _buildEmptyState(Color primaryColor, Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: primaryColor.withAlpha(50),
          ),
          const SizedBox(height: 16),
          Text(
            '没有找到相关模板',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '请尝试选择其他分类或返回"全部"查看所有模板',
            style: TextStyle(
              fontSize: 14,
              color: textColor.withAlpha(70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(BuildContext context, TemplateModel template, Color primaryColor, Color textColor) {
    IconData templateIcon = _getTemplateIcon(template.type.value);
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TemplateEditPage(template: template),
              ),
            );
          },
          hoverColor: Colors.grey.withAlpha(10),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 模板图标
                Icon(
                  templateIcon,
                  size: 48,
                  color: primaryColor,
                ),
                const SizedBox(height: 16),
                // 模板名称
                Text(
                  template.name,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // 模板描述
                Text(
                  template.description,
                  style: TextStyle(
                    color: textColor.withAlpha(70),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                // 添加预览按钮
                ElevatedButton.icon(
                  onPressed: () async {
                    // 先显示对话框
                    _showPreviewDialog(context, template, primaryColor, textColor);
                    // 然后开始加载PDF
                    await _previewDocument(template);
                  },
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('预览'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor.withAlpha(30),
                    foregroundColor: primaryColor,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // 修改预览对话框方法
  void _showPreviewDialog(BuildContext context, TemplateModel template, Color primaryColor, Color textColor) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (BuildContext dialogContext) {
        return StatefulBuilder( // 使用StatefulBuilder使对话框内部可以使用setState
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.7,
                height: MediaQuery.of(context).size.height * 0.8,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 对话框标题栏
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _getTemplateIcon(template.type.value),
                              color: primaryColor,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${template.name} 预览',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                          tooltip: '关闭',
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    // 模板信息
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          _buildInfoChip(Icons.description, template.description, primaryColor),
                        ],
                      ),
                    ),
                    // 预览内容
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: ValueListenableBuilder<bool>(
                          valueListenable: _isLoadingNotifier,
                          builder: (context, isLoading, child) {
                            return ValueListenableBuilder<String?>(
                              valueListenable: _pdfPathNotifier,
                              builder: (context, pdfPath, child) {
                                if (isLoading) {
                                  return const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        CircularProgressIndicator(),
                                        SizedBox(height: 16),
                                        Text('正在生成模版预览...'),
                                      ],
                                    ),
                                  );
                                }
                                
                                if (pdfPath == null) {
                                  return const Center(child: Text('无法加载PDF'));
                                }
                                
                                return SfPdfViewer.file(
                                  File(pdfPath),
                                  enableDoubleTapZooming: true,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // 底部按钮
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textColor,
                            side: BorderSide(color: Colors.grey.shade300),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          child: const Text('关闭'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TemplateEditPage(template: template),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          child: const Text('编辑模板'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 修改预览文档方法
  Future<void> _previewDocument(TemplateModel template) async {
    try {
      _isLoadingNotifier.value = true;

      final Map<String, String> details = Map.fromEntries(
        template.editableInfos?.map((info) => MapEntry(
              info.key,
              '',
            )) ??
            [],
      );
      
      final pdfPath = await ApiService.generateDocument(
          details, template.name, Format.pdf.value, true);

      if (File(pdfPath).existsSync()) {
        _pdfPathNotifier.value = pdfPath;
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
    } finally {
      _isLoadingNotifier.value = false;
    }
  }
  
  // 构建信息标签
  Widget _buildInfoChip(IconData icon, String label, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: primaryColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // 根据模板类型获取图标
  IconData _getTemplateIcon(String type) {
    switch (type) {
      case 'export':
        return Icons.flight_takeoff;
      case 'import':
        return Icons.flight_land;
      case 'other':
        return Icons.description;
      default:
        return Icons.article;
    }
  }

  // 即将推出的内容提示
  Widget _buildComingSoonContent(BuildContext context, Color primaryColor, Color textColor) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 80,
              color: primaryColor.withAlpha(50),
            ),
            const SizedBox(height: 24),
            Text(
              '功能待定',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '该功能模块待定',
              style: TextStyle(
                fontSize: 16,
                color: textColor.withAlpha(70),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedFunction = '单据模板';
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('返回单据模板'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _isLoadingNotifier.dispose();
    _pdfPathNotifier.dispose();
    super.dispose();
  }
}

// 辅助函数
double min(double a, double b) => a < b ? a : b;
double max(double a, double b) => a > b ? a : b;
