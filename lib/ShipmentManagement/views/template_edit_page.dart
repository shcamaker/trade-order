import 'package:flutter/material.dart';
import '../models/template_model.dart';
import './template_detail_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 客户数据模型
class Customer {
  final String id;
  final String name;
  final Map<String, String> defaultValues;

  Customer({
    required this.id,
    required this.name,
    required this.defaultValues,
  });
}

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
  
  // 客户列表（示例数据）
  final List<Customer> _customers = [
    Customer(
      id: 'customer1',
      name: '上海贸易有限公司',
      defaultValues: {
        'exportPort': '上海',
        'transportMode': '海运',
        'tradeCountry': '美国',
        'destinationPort': '洛杉矶',
        'consumptionCountry': '美国',
      },
    ),
    Customer(
      id: 'customer2',
      name: '广州进出口有限公司',
      defaultValues: {
        'exportPort': '广州',
        'transportMode': '空运',
        'tradeCountry': '德国',
        'destinationPort': '汉堡',
        'consumptionCountry': '德国',
      },
    ),
    Customer(
      id: 'customer3',
      name: '深圳外贸集团',
      defaultValues: {
        'exportPort': '深圳',
        'transportMode': '海运',
        'tradeCountry': '日本',
        'destinationPort': '东京',
        'consumptionCountry': '日本',
      },
    ),
  ];
  
  // 当前选择的客户
  Customer? _selectedCustomer;

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
  }

  // 根据选择的客户填充表单
  void _fillFormWithCustomerData(Customer customer) {
    setState(() {
      for (var info in widget.template.editableInfos ?? []) {
        final key = info.key;
        // 首先尝试加载该客户的保存默认值
        String? savedValue = _prefs.getString('${customer.id}_$key');
        
        // 如果有保存的默认值，优先使用
        if (savedValue != null && _controllers.containsKey(key)) {
          // 对于可选项，确保值在可选范围内
          if (info.isSelectable && info.options != null) {
            if (info.options!.contains(savedValue)) {
              _controllers[key]?.text = savedValue;
            } else {
              // 如果保存的值不在可选范围内，使用客户默认值或清空
              _controllers[key]?.text = _getValidValueForField(customer, key, info);
            }
          } else {
            // 非选择字段直接使用保存的值
            _controllers[key]?.text = savedValue;
          }
        } else {
          // 没有保存的默认值，使用客户默认值
          _controllers[key]?.text = _getValidValueForField(customer, key, info);
        }
      }
      // 触发总金额计算
      _calculateTotalAmount();
    });
  }
  
  // 获取字段的有效值（确保在可选范围内）
  String _getValidValueForField(Customer customer, String key, EditableInfo info) {
    // 获取客户默认值
    final defaultValue = customer.defaultValues[key] ?? '';
    
    // 如果是可选字段，确保值在可选范围内
    if (info.isSelectable && info.options != null) {
      return info.options!.contains(defaultValue) ? defaultValue : '';
    }
    
    return defaultValue;
  }

  // Save default value for specific customer
  Future<void> _saveDefaultValue(String key, String value) async {
    if (_selectedCustomer == null) return;
    
    // 使用客户ID作为键的一部分，为每个客户保存独立的默认值
    await _prefs.setString('${_selectedCustomer!.id}_$key', value);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已将${_getFieldNameByKey(key)}设为${_selectedCustomer!.name}的默认值'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }
  
  // 根据key获取字段名称
  String _getFieldNameByKey(String key) {
    for (var info in widget.template.editableInfos ?? []) {
      if (info.key == key) return info.name;
    }
    return key;
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

  // 清除当前客户的所有默认值
  Future<void> _clearAllDefaults() async {
    if (!mounted) return;

    if (_selectedCustomer == null) {
      // 如果没有选择客户，提示用户先选择客户
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择客户')),
      );
      return;
    }

    // 只清除当前选择客户的默认值
    for (var info in widget.template.editableInfos ?? []) {
      await _prefs.remove('${_selectedCustomer!.id}_${info.key}');
    }

    // 重新加载客户默认数据
    _fillFormWithCustomerData(_selectedCustomer!);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已清除${_selectedCustomer!.name}的所有默认值')),
    );
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
    // 定义颜色常量 - 与主页匹配的配色方案
    const Color backgroundColor = Colors.white; // 白色背景
    const Color titleColor = Color(0xFF333333); // 深灰色标题
    const Color primaryColor = Color(0xFF4CAF50); // 绿色主色调（与TRADE-ASSISTANT标志匹配）
    const Color defaultButtonColor = Color(0xFF4CAF50); // 绿色按钮
    const Color saveButtonColor = Color(0xFF4CAF50); // 绿色保存按钮
    const Color hintTextColor = Color(0xFF999999); // 浅灰色提示文字
    const Color borderColor = Color(0xFFEEEEEE); // 浅灰色边框
    const Color cardBackgroundColor = Colors.white; // 卡片背景色
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: titleColor, size: 20),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: '返回上一页',
        ),
        title: Text(
          '编辑${widget.template.name}',
          style: const TextStyle(
            color: titleColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          Tooltip(
            message: '清除当前客户的所有默认值',
            child: IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: primaryColor),
              onPressed: _clearAllDefaults,
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 客户选择下拉框
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardBackgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(color: borderColor, width: 1),
                      ),
                      child: _buildCustomerSelector(hintTextColor, borderColor),
                    ),
                    
                    const SizedBox(height: 20), // 增加间隔
                    
                    // 表单字段
                    ...(widget.template.editableInfos ?? []).map(
                      (info) => Container(
                        margin: const EdgeInsets.only(bottom: 20), // 增加间隔
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(color: borderColor, width: 1),
                        ),
                        child: _buildFormField(info, defaultButtonColor, hintTextColor, borderColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildBottomBar(saveButtonColor),
          ],
        ),
      ),
    );
  }

  // 构建客户选择器
  Widget _buildCustomerSelector(Color hintTextColor, Color borderColor) {
    const Color primaryColor = Color(0xFF4CAF50); // 添加主色调定义
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '选择客户',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333), // 深灰色标题
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Customer>(
              value: _selectedCustomer,
              hint: Text('请选择客户', style: TextStyle(color: hintTextColor)),
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, size: 22),
              elevation: 16,
              style: const TextStyle(
                color: Color(0xFF333333), // 深灰色文字
                fontSize: 16,
              ),
              onChanged: (Customer? newValue) {
                setState(() {
                  _selectedCustomer = newValue;
                  if (newValue != null) {
                    _fillFormWithCustomerData(newValue);
                  }
                });
              },
              items: _customers.map<DropdownMenuItem<Customer>>((Customer customer) {
                return DropdownMenuItem<Customer>(
                  value: customer,
                  child: Text(customer.name),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_selectedCustomer != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('重置为客户默认值'),
                onPressed: () {
                  if (_selectedCustomer != null) {
                    _fillFormWithCustomerData(_selectedCustomer!);
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: primaryColor, // 绿色
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildFormField(EditableInfo info, Color defaultButtonColor, Color hintTextColor, Color borderColor) {
    const Color primaryColor = Color(0xFF4CAF50); // 添加主色调定义
    final controller = _controllers[info.key];
    if (controller == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              info.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333), // 深灰色标题
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8)
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: info.isSelectable && info.options != null
                  ? // 下拉选择框
                  Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor, width: 1),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: ButtonTheme(
                          alignedDropdown: true,
                          child: DropdownButton<String>(
                            value: controller.text.isEmpty ? null : controller.text,
                            hint: Text(info.hintText, style: TextStyle(color: hintTextColor)),
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down, size: 22),
                            elevation: 16,
                            style: const TextStyle(
                              color: Color(0xFF333333), // 深灰色文字
                              fontSize: 16,
                            ),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  controller.text = newValue;
                                });
                              }
                            },
                            items: info.options!.map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            underline: Container(
                              height: 0,
                              color: Colors.transparent,
                            ),
                            dropdownColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        ),
                      ),
                    )
                  : // 普通输入框或只读总金额
                  TextFormField(
                      controller: controller,
                      readOnly: !info.canEdit,
                      enabled: info.canEdit,
                      style: const TextStyle(
                        color: Color(0xFF333333), // 深灰色文字
                        fontSize: 16,
                      ),
                      keyboardType: info.isNumber
                          ? const TextInputType.numberWithOptions(decimal: true)
                          : TextInputType.text,
                      decoration: InputDecoration(
                        hintText: info.hintText,
                        hintStyle: TextStyle(color: hintTextColor),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: borderColor, width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: borderColor, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: primaryColor, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            const SizedBox(width: 12),
            if (info.supportDefault && _selectedCustomer != null)
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, child) {
                  final bool hasValue = value.text.isNotEmpty;
                  return Tooltip(
                    message: '将当前值设为${_selectedCustomer!.name}的默认值',
                    child: ElevatedButton(
                      onPressed: hasValue
                          ? () async {
                              await _saveDefaultValue(info.key, controller.text);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            hasValue ? defaultButtonColor : Colors.grey[300],
                        foregroundColor:
                            hasValue ? Colors.white : Colors.grey[500],
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                        minimumSize: const Size(100, 46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: hasValue ? 2 : 0,
                        shadowColor: hasValue ? defaultButtonColor.withOpacity(0.4) : Colors.transparent,
                      ),
                      child: const Text(
                        '设为默认',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
    final Color borderColor = const Color(0xFFDDDDDD);
    final Color primaryColor = const Color(0xFF4CAF50); // 修改为绿色
    
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            '选择$title',
            style: const TextStyle(
              color: Color(0xFF333333),
              fontWeight: FontWeight.bold,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(
                    items[index],
                    style: const TextStyle(
                      color: Color(0xFF333333),
                      fontSize: 16,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop(items[index]);
                  },
                  hoverColor: const Color(0xFFE8F5E9), // 淡绿色悬停效果
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                '取消',
                style: TextStyle(
                  color: Color(0xFF999999),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (result != null) {
      controller.text = result;
    }
  }

  Widget _buildBottomBar(Color saveButtonColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _saveTemplate,
            style: ElevatedButton.styleFrom(
              backgroundColor: saveButtonColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 3,
              shadowColor: saveButtonColor.withOpacity(0.4),
            ),
            child: const Text(
              '保存',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
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
