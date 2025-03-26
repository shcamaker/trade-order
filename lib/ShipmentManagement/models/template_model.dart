import 'package:flutter/material.dart';

class EditableInfo {
  final String name;
  final String key;
  final String hintText;
  final bool supportDefault;
  final List<String>? options;
  final bool isRequired;
  final EditableType type;
  EditableInfo({
    required this.name,
    required this.key,
    required this.hintText,
    required this.supportDefault,
    this.options,
    required this.isRequired,
    required this.type,
  });

  factory EditableInfo.fromJson(Map<String, dynamic> json) {
    return EditableInfo(
      name: json['name'] ?? '',
      key: json['key'] ?? '',
      hintText: json['hintText'] ?? '请输入',
      supportDefault: json['supportDefault'] ?? true,
      options: json['options']?.cast<String>(),
      isRequired: json['isRequired'] ?? false,
      type: EditableType.values.firstWhere(
        (t) => t.value == json['type'],
        orElse: () => EditableType.text,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'key': key,
      'hintText': hintText,
      'supportDefault': supportDefault,
      'options': options,
      'isRequired': isRequired,
      'type': type.value,
    };
  }
}

class TemplateModel {
  final String id;
  final String name;
  final String description;
  final Color backgroundColor;
  final List<EditableInfo>? editableInfos;
  final TemplateType type;

  TemplateModel({
    required this.id,
    required this.name,
    required this.description,
    required this.backgroundColor,
    this.editableInfos,
    required this.type,
  });

  factory TemplateModel.fromJson(Map<String, dynamic> json) {
    // 将十六进制颜色字符串转换为Color对象
    Color parseColor(String? hexColor) {
      if (hexColor == null || hexColor.isEmpty) {
        return Colors.blue; // 默认颜色
      }
      hexColor = hexColor.replaceAll('#', '');
      try {
        return Color(int.parse('FF$hexColor', radix: 16));
      } catch (e) {
        debugPrint('颜色转换错误: $e');
        return Colors.blue; // 解析错误时的默认颜色
      }
    }

    try {
      return TemplateModel(
        id: json['id']?.toString() ?? '0',
        name: json['name'] ?? '未命名模板',
        description: json['description'] ?? '无描述',
        backgroundColor: parseColor(json['backgroundColor']),
        editableInfos: (json['editableInfos'] as List?)
            ?.map((e) => EditableInfo.fromJson(e as Map<String, dynamic>))
            .toList(),
        type: TemplateType.values.firstWhere(
          (t) => t.value == json['type'],
          orElse: () => TemplateType.export,
        )
      );
    } catch (e) {
      debugPrint('模板解析错误: $e');
      // 返回一个最小可用的模板对象
      return TemplateModel(
        id: '0',
        name: '数据错误',
        description: '模板数据格式错误',
        backgroundColor: Colors.red,
        editableInfos: [],
        type: TemplateType.other,
      );
    }
  }
}

enum Format {
  docx('docx'),
  pdf('pdf');

  final String value;
  const Format(this.value);
}
enum TemplateType {
  export('出口单据'),
  import('进口单据'),
  other('其他');

  final String value;
  const TemplateType(this.value);
}

enum EditableType {
  text('text'),
  dropdown('dropdown'),
  date('date'),
  number('number'),
  auto('auto');

  final String value;
  const EditableType(this.value);
}
