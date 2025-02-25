import 'package:flutter/material.dart';

class EditableInfo {
  final String name;
  final String key;
  final String hintText;
  final bool isSelectable;
  final bool supportDefault;
  final List<String>? options;
  final bool canEdit;
  final bool isNumber;

  EditableInfo({
    required this.name,
    required this.key,
    required this.hintText,
    required this.isSelectable,
    required this.supportDefault,
    this.options,
    required this.canEdit,
    required this.isNumber,
  });

  factory EditableInfo.fromJson(Map<String, dynamic> json) {
    return EditableInfo(
      name: json['name'],
      key: json['key'],
      hintText: json['hintText'],
      isSelectable: json['isSelectable'],
      supportDefault: json['supportDefault'],
      options: json['options']?.cast<String>(),
      canEdit: json['isEditable'],
      isNumber: json['isNumericField'],
    );
  }
}

class TemplateModel {
  final String id;
  final String name;
  final Color backgroundColor;
  final List<EditableInfo>? editableInfos;

  TemplateModel({
    required this.id,
    required this.name,
    required this.backgroundColor,
    this.editableInfos,
  });

  factory TemplateModel.fromJson(Map<String, dynamic> json) {
    // 将十六进制颜色字符串转换为Color对象
    Color parseColor(String hexColor) {
      hexColor = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hexColor', radix: 16));
    }

    return TemplateModel(
      id: json['id'].toString(),
      name: json['name'],
      backgroundColor: parseColor(json['backgroundColor']),
      editableInfos: (json['editableInfos'] as List?)
          ?.map((e) => EditableInfo.fromJson(e))
          .toList(),
    );
  }
}

enum Format {
  docx('docx'),
  pdf('pdf');

  final String value;
  const Format(this.value);
}
