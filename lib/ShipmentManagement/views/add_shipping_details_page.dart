import 'package:flutter/material.dart';

class AddShippingDetailsPage extends StatefulWidget {
  const AddShippingDetailsPage({super.key});

  @override
  State<AddShippingDetailsPage> createState() => _AddShippingDetailsPageState();
}

class _AddShippingDetailsPageState extends State<AddShippingDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _exportPortController = TextEditingController();
  final _transportModeController = TextEditingController();
  final _contractNumberController = TextEditingController();

  @override
  void dispose() {
    _exportPortController.dispose();
    _transportModeController.dispose();
    _contractNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shipping Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                'Export Port',
                _exportPortController,
                hintText: 'e.g. ALASHANKOU',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                'Transport Mode',
                _transportModeController,
                hintText: 'e.g. SUBWAY',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                'Contract Number',
                _contractNumberController,
                hintText: 'e.g. RGB/TTS-2309',
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _generateDocument,
                  child: const Text('Generate Document'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter $label';
            }
            return null;
          },
        ),
      ],
    );
  }

  void _generateDocument() {
    if (_formKey.currentState!.validate()) {
      // TODO: 调用Python脚本生成文档
      final details = {
        'exportPort': _exportPortController.text,
        'transportMode': _transportModeController.text,
        'contractNumber': _contractNumberController.text,
      };
      print('Document details: $details');
      // 这里添加生成文档的逻辑
    }
  }
}
