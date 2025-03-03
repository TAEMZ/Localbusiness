import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;
  final bool isObscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final InputDecoration? decoration;
  final TextStyle? textStyle;
  final bool isEmailField;

  const CustomTextField({
    super.key,
    required this.hintText,
    required this.controller,
    this.isObscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
    this.decoration,
    this.textStyle,
    this.isEmailField = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      style: textStyle ?? const TextStyle(color: Colors.white),
      controller: controller,
      decoration: decoration ?? _defaultDecoration(context),
      validator: validator ?? _defaultValidator,
      keyboardType: keyboardType ??
          (isEmailField ? TextInputType.emailAddress : TextInputType.text),
      obscureText: isObscureText,
    );
  }

  InputDecoration _defaultDecoration(BuildContext context) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.grey),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
            color: Color.fromARGB(255, 236, 213, 255), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  String? _defaultValidator(String? value) {
    if (value == null || value.isEmpty) {
      return "$hintText is missing!";
    }
    return null;
  }
}
