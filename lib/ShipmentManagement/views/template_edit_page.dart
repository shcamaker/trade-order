import 'package:flutter/material.dart';
import '../models/template_model.dart';
import './template_detail_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TemplateEditPage extends StatefulWidget {
  final TemplateModel template;

  const TemplateEditPage({
    super.key,
    required this.template,
  });

  @override
  State<TemplateEditPage> createState() => _TemplateEditPageState();
}

class _TemplateEditPageState extends State<TemplateEditPage> {
  final _formKey = GlobalKey<FormState>();
  late SharedPreferences _prefs;

  // Map to store all controllers
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _initControllers();
    _initPrefs();
  }

  void _initControllers() {
    // Initialize controllers for each editable field
    for (var info in widget.template.editableInfos ?? []) {
      _controllers[info.key] = TextEditingController();
    }

    // Add listeners for calculating total amount
    _controllers['netWeight']?.addListener(_calculateTotalAmount);
    _controllers['unitPrice']?.addListener(_calculateTotalAmount);
  }

  // Initialize SharedPreferences and load default values
  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      // Load saved default values for each field
      for (var info in widget.template.editableInfos ?? []) {
        _controllers[info.key]?.text =
            _prefs.getString('default_${info.key}') ?? '';
      }
    });
  }

  // Save default value
  Future<void> _saveDefaultValue(String key, String value) async {
    await _prefs.setString('default_$key', value);
  }

  // Calculate total amount
  void _calculateTotalAmount() {
    final netWeight =
        double.tryParse(_controllers['netWeight']?.text ?? '') ?? 0;
    final unitPrice =
        double.tryParse(_controllers['unitPrice']?.text ?? '') ?? 0;
    final total = netWeight * unitPrice;
    _controllers['totalAmount']?.text = total.toStringAsFixed(2);
  }

  // 添加清除所有默认值的方法
  Future<void> _clearAllDefaults() async {
    for (var info in widget.template.editableInfos ?? []) {
      await _prefs.remove('default_${info.key}');
    }

    // 重新加载页面
    setState(() {
      for (var controller in _controllers.values) {
        controller.clear();
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已清除所有默认值')),
      );
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('编辑${widget.template.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearAllDefaults,
            tooltip: '清除所有默认值',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...(widget.template.editableInfos ?? [])
                        .map(_buildFormField),
                  ],
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField(EditableInfo info) {
    final controller = _controllers[info.key];
    if (controller == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          info.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: info.isSelectable && info.options != null
                  ? // 下拉选择框
                  TextFormField(
                      controller: controller,
                      readOnly: true,
                      decoration: InputDecoration(
                        hintText: info.hintText,
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: const Icon(Icons.arrow_drop_down),
                      ),
                      onTap: () => _showSelectionDialog(
                          context, info.name, info.options!, controller),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请选择${info.name}';
                        }
                        return null;
                      },
                    )
                  : // 普通输入框或只读总金额
                  TextFormField(
                      controller: controller,
                      readOnly: !info.canEdit,
                      enabled: info.canEdit,
                      keyboardType: info.isNumber
                          ? const TextInputType.numberWithOptions(decimal: true)
                          : TextInputType.text,
                      decoration: InputDecoration(
                        hintText: info.hintText,
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (info.isNumber && double.tryParse(value!) == null) {
                          return '请输入有效的数字';
                        }
                        if (value == null || value.isEmpty) {
                          return '请输入${info.name}';
                        }
                        return null;
                      },
                    ),
            ),
            const SizedBox(width: 8),
            if (info.supportDefault)
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, child) {
                  final bool hasValue = value.text.isNotEmpty;
                  return ElevatedButton(
                    onPressed: hasValue
                        ? () async {
                            await _saveDefaultValue(info.key, controller.text);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('已将${info.name}设为默认值'),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          hasValue ? Colors.blue : Colors.grey[300],
                      foregroundColor:
                          hasValue ? Colors.white : Colors.grey[500],
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(80, 40),
                    ),
                    child: const Text(
                      '设为默认',
                      style: TextStyle(fontSize: 12),
                    ),
                  );
                },
              ),
          ],
        ),
      ],
    );
  }

  // 添加选择对话框方法
  Future<void> _showSelectionDialog(
    BuildContext context,
    String title,
    List<String> items,
    TextEditingController controller,
  ) async {
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('选择$title'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(items[index]),
                  onTap: () {
                    Navigator.of(context).pop(items[index]);
                  },
                );
              },
            ),
          ),
        );
      },
    );

    if (result != null) {
      controller.text = result;
    }
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _saveTemplate,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('保存'),
          ),
        ),
      ),
    );
  }

  void _saveTemplate() async {
    if (_formKey.currentState!.validate()) {
      try {
        final Map<String, String> details = Map.fromEntries(
          widget.template.editableInfos?.map((info) => MapEntry(
                    info.key,
                    _controllers[info.key]?.text ?? '',
                  )) ??
              [],
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TemplateDetailPage(
                template: widget.template, updatedDetails: details),
          ),
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('生成文档失败: $e')),
          );
        }
      }
    }
  }
}
