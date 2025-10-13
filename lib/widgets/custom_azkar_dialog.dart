import 'package:flutter/material.dart';
import '../models/zikr_model.dart';

class CustomAzkarDialog extends StatefulWidget {
  const CustomAzkarDialog({super.key});

  @override
  State<CustomAzkarDialog> createState() => _CustomAzkarDialogState();
}

class _CustomAzkarDialogState extends State<CustomAzkarDialog> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  final _countController = TextEditingController(text: '1');

  @override
  void dispose() {
    _textController.dispose();
    _countController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final zikr = Zikr(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: _textController.text.trim(),
        count: int.parse(_countController.text),
      );
      Navigator.pop(context, zikr);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // العنوان
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7D9D9C).withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.add_circle_outline,
                        color: Color(0xFF7D9D9C),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'إضافة ذكر جديد',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      color: Colors.grey,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // حقل نص الذكر
                TextFormField(
                  controller: _textController,
                  maxLines: 5,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    labelText: 'نص الذكر',
                    hintText: 'اكتب الذكر هنا...',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF7D9D9C),
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F0),
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.8,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'الرجاء إدخال نص الذكر';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // حقل العدد
                TextFormField(
                  controller: _countController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    labelText: 'عدد المرات',
                    prefixIcon: const Icon(Icons.remove_circle_outline),
                    suffixIcon: const Icon(Icons.add_circle_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF7D9D9C),
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F0),
                  ),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال عدد المرات';
                    }
                    final count = int.tryParse(value);
                    if (count == null || count < 1) {
                      return 'الرجاء إدخال رقم صحيح أكبر من 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // أزرار الحفظ والإلغاء
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(
                            color: Color(0xFF7D9D9C),
                          ),
                        ),
                        child: const Text(
                          'إلغاء',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7D9D9C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'حفظ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}