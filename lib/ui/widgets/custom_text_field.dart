import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final TextInputType keyboardType;
  final bool obscureText;
  final IconData? icon;
  final String? Function(String?)? validator;
  final int? maxLines; // اضافه شد ✅
  final ValueChanged<String>? onChanged; // اضافه شد برای سرچ realtime

  const CustomTextField({
    super.key,
    required this.controller,
    this.label = '',
    this.hintText,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.icon,
    this.validator,
    this.maxLines = 1, // پیش‌فرض ۱ خط
    this.onChanged, // پیش‌فرض null
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      maxLines: maxLines, // اضافه شد ✅
      onChanged: onChanged, // اضافه شد برای سرچ realtime
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white70),
        labelStyle: const TextStyle(color: Colors.amber),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.amber),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.amber, width: 2),
        ),
        filled: true,
        fillColor: Colors.black.withOpacity(0.3),
        prefixIcon: icon != null ? Icon(icon, color: Colors.amber) : null,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
      ),
    );
  }
}
