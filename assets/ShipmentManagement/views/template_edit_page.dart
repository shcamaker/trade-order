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

  // 添加搜索相关的状态变量
  final TextEditingController _customerSearchController = TextEditingController();
  final FocusNode _customerFocusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  List<Customer> _filteredCustomers = [];

  // 添加新的状态变量用于编辑项下拉框
  Map<String, OverlayEntry?> _dropdownOverlays = {};

  @override
  void initState() {
    super.initState();
    _initControllers();
    _initPrefs();
    _filteredCustomers = List.from(_customers);
    
    // 添加客户搜索监听
    _customerSearchController.addListener(_onCustomerSearchChanged);
  }

  // 客户搜索文本变化处理
  void _onCustomerSearchChanged() {
    _filterCustomers(_customerSearchController.text);
    // 不要在这里尝试显示下拉框，因为可能没有有效的context
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
    _customerSearchController.dispose();
    _customerFocusNode.dispose();
    _hideOverlay();
    // 清理所有下拉框
    _dropdownOverlays.values.forEach((overlay) => overlay?.remove());
    super.dispose();
  }

  // 过滤客户列表
  void _filterCustomers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCustomers = List.from(_customers);
      } else {
        _filteredCustomers = _customers
            .where((customer) =>
                customer.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
      _updateOverlay();
    });
  }

  // 修改显示下拉框方法 - 移除搜索框，简化实现
  void _showOverlay(BuildContext context) {
    // 安全检查
    if (context == null) {
      print("Context is null in _showOverlay");
      return;
    }
    
    // 查找渲染对象
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      print("RenderBox is null in _showOverlay");
      return;
    }
    
    // 获取选择框的位置和大小
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    // 关闭可能存在的overlay
    _hideOverlay();
    
    // 创建新的overlay
    _overlayEntry = OverlayEntry(
      builder: (overlayContext) => Stack(
        children: [
          // 添加一个透明层来处理点击外部关闭
          Positioned.fill(
            child: GestureDetector(
              onTap: _hideOverlay,
              behavior: HitTestBehavior.opaque,
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
          // 下拉框内容
          Positioned(
            left: position.dx,
            top: position.dy + size.height + 5,
            width: size.width,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: 300,
                  maxWidth: size.width,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 客户列表
                    Flexible(
                      child: _filteredCustomers.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  '没有找到匹配的客户',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              itemCount: _filteredCustomers.length,
                              itemBuilder: (context, index) {
                                final customer = _filteredCustomers[index];
                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    customer.name,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  selected: _selectedCustomer?.id == customer.id,
                                  selectedTileColor: const Color(0xFF4CAF50).withOpacity(0.1),
                                  onTap: () {
                                    setState(() {
                                      _selectedCustomer = customer;
                                      // 更新输入框文本为选中的客户名称
                                      _customerSearchController.text = customer.name;
                                    });
                                    // 填充表单
                                    _fillFormWithCustomerData(customer);
                                    // 关闭覆盖层
                                    _hideOverlay();
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // 使用正确的方式插入overlay
    Overlay.of(context).insert(_overlayEntry!);
  }

  // 隐藏下拉框
  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  // 更新下拉框
  void _updateOverlay() {
    _overlayEntry?.markNeedsBuild();
  }

  // 隐藏编辑项下拉框
  void _hideDropdownOverlay(String key) {
    _dropdownOverlays[key]?.remove();
    _dropdownOverlays[key] = null;
  }

  // 隐藏所有编辑项下拉框
  void _hideAllDropdownOverlays() {
    _dropdownOverlays.forEach((key, overlay) {
      overlay?.remove();
      _dropdownOverlays[key] = null;
    });
  }

  // 构建下拉选择框
  Widget _buildDropdown(EditableInfo info, TextEditingController controller, Color hintTextColor, Color borderColor) {
    return Builder(
      builder: (context) => GestureDetector(
        onTap: () {
          _hideAllDropdownOverlays(); // 先隐藏所有下拉框
          _showDropdownOverlay(context, info, controller);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  controller.text.isEmpty ? info.hintText : controller.text,
                  style: TextStyle(
                    color: controller.text.isEmpty ? hintTextColor : const Color(0xFF333333),
                    fontSize: 14,
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down,
                size: 20,
                color: Color(0xFF999999),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 显示编辑项下拉框
  void _showDropdownOverlay(BuildContext context, EditableInfo info, TextEditingController controller) {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _dropdownOverlays[info.key]?.remove();
    _dropdownOverlays[info.key] = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // 添加一个透明层来处理点击外部关闭
          Positioned.fill(
            child: GestureDetector(
              onTap: () => _hideDropdownOverlay(info.key),
              behavior: HitTestBehavior.opaque,
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
          // 下拉框内容
          Positioned(
            left: position.dx,
            top: position.dy + size.height + 4,
            width: size.width,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                constraints: const BoxConstraints(
                  maxHeight: 200,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: info.options?.length ?? 0,
                  itemBuilder: (context, index) {
                    final option = info.options![index];
                    return ListTile(
                      dense: true,
                      title: Text(
                        option,
                        style: const TextStyle(fontSize: 14),
                      ),
                      selected: controller.text == option,
                      selectedTileColor: const Color(0xFF4CAF50).withOpacity(0.1),
                      onTap: () {
                        setState(() {
                          controller.text = option;
                        });
                        _hideDropdownOverlay(info.key);
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_dropdownOverlays[info.key]!);
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
                    // 添加提示文字
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF4CAF50).withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.tips_and_updates,
                            color: const Color(0xFF4CAF50).withOpacity(0.7),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              '可以选择客户，灵活设置各项参数的默认值，实现单据系统的个性化配置',
                              style: TextStyle(
                                color: Color(0xFF666666),
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // 客户选择区域
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: primaryColor.withOpacity(0.1), width: 1),
                      ),
                      child: _buildCustomerSelector(hintTextColor, borderColor),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // 编辑项网格布局 - 增加列间距
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 50, // 增加列间距
                        mainAxisSpacing: 20,
                        mainAxisExtent: 80,
                      ),
                      itemCount: widget.template.editableInfos?.length ?? 0,
                      itemBuilder: (context, index) {
                        final info = widget.template.editableInfos![index];
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        );
                      },
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

  // 修改客户选择器 - 添加条件清空按钮
  Widget _buildCustomerSelector(Color hintTextColor, Color borderColor) {
    const Color primaryColor = Color(0xFF4CAF50);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 标题部分
        const SizedBox(
          width: 180,
          child: Row(
            children: [
              Icon(Icons.business, color: primaryColor, size: 24),
              SizedBox(width: 12),
              Text(
                '选择客户',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // 客户搜索输入框 - 添加条件清空按钮
        Expanded(
          child: Builder(
            builder: (context) => GestureDetector(
              onTap: () {
                // 确保弹出下拉框，这是关键修复
                _showOverlay(context);
                // 然后请求焦点
                _customerFocusNode.requestFocus();
              },
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _customerSearchController,
                builder: (context, value, child) {
                  // 根据输入框内容决定是否显示清空按钮
                  final bool hasText = value.text.isNotEmpty;
                  return TextField(
                    controller: _customerSearchController,
                    focusNode: _customerFocusNode,
                    decoration: InputDecoration(
                      hintText: '请选择或搜索客户',
                      hintStyle: TextStyle(color: hintTextColor),
                      // 条件显示清空按钮
                      suffixIcon: hasText 
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Color(0xFF999999), size: 20),
                              splashRadius: 20,
                              onPressed: () {
                                // 清空输入框
                                _customerSearchController.clear();
                                // 重置选中客户
                                setState(() {
                                  _selectedCustomer = null;
                                });
                                // 重新显示所有客户
                                _filterCustomers('');
                                // 显示下拉框以便重新选择
                                _showOverlay(context);
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: primaryColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF333333),
                    ),
                    onTap: () {
                      // 确保点击输入框时显示下拉框
                      _showOverlay(context);
                    },
                    onChanged: (value) {
                      // 在文本改变时过滤客户并显示下拉框
                      _filterCustomers(value);
                      if (_overlayEntry == null) {
                        _showOverlay(context);
                      }
                    },
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // 重置按钮
        if (_selectedCustomer != null)
          TextButton.icon(
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('重置为客户默认值'),
            onPressed: () {
              if (_selectedCustomer != null) {
                _fillFormWithCustomerData(_selectedCustomer!);
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
      ],
    );
  }

  // 修改表单字段布局 - 调整间距和对齐
  Widget _buildFormField(EditableInfo info, Color defaultButtonColor, Color hintTextColor, Color borderColor) {
    const Color primaryColor = Color(0xFF4CAF50);
    final controller = _controllers[info.key];
    if (controller == null) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 标题部分
        SizedBox(
          width: 100, // 稍微减小标题宽度，为按钮留出更多空间
          child: Text(
            info.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // 输入框部分
        Expanded(
          child: info.isSelectable && info.options != null
              ? _buildDropdown(info, controller, hintTextColor, borderColor)
              : _buildTextField(info, controller, hintTextColor, borderColor),
        ),
        // 设为默认按钮
        if (info.supportDefault && _selectedCustomer != null) ...[
          const SizedBox(width: 4),
          _buildDefaultButton(info, controller, defaultButtonColor),
        ],
      ],
    );
  }

  // 构建文本输入框
  Widget _buildTextField(EditableInfo info, TextEditingController controller, Color hintTextColor, Color borderColor) {
    const Color primaryColor = Color(0xFF4CAF50);
    return TextFormField(
      controller: controller,
      readOnly: !info.canEdit,
      enabled: info.canEdit,
      style: const TextStyle(
        color: Color(0xFF333333),
        fontSize: 14,
      ),
      keyboardType: info.isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(
        hintText: info.hintText,
        hintStyle: TextStyle(color: hintTextColor, fontSize: 14),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      validator: (value) {
        if (info.isNumber && value!.isNotEmpty && double.tryParse(value) == null) {
          return '请输入有效的数字';
        }
        if (value == null || value.isEmpty) {
          return '请输入${info.name}';
        }
        return null;
      },
    );
  }

  // 修改设为默认按钮为文字按钮
  Widget _buildDefaultButton(EditableInfo info, TextEditingController controller, Color defaultButtonColor) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final bool hasValue = value.text.isNotEmpty;
        return TextButton(
          onPressed: hasValue
              ? () async {
                  await _saveDefaultValue(info.key, controller.text);
                }
              : null,
          style: TextButton.styleFrom(
            foregroundColor: hasValue ? defaultButtonColor : Colors.grey[400],
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: const Size(80, 36),
            textStyle: const TextStyle(fontSize: 13),
          ),
          child: const Text('设为默认'),
        );
      },
    );
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
