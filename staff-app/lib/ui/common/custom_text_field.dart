import 'package:flutter/material.dart';

/// A reusable text field wrapper used across forms.
class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final int? maxLines;
  final VoidCallback? onTap;
  final IconData? prefixIcon;
  final ValueChangedCallback<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final EdgeInsetsGeometry? padding;

  const CustomTextField({
    super.key,
    required this.controller,
    this.labelText,
    this.hintText,
    this.maxLines,
    this.onTap,
    this.prefixIcon,
    this.onChanged,
    this.validator,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.all(0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          prefixIcon: prefixIcon,
          border: const OutlineInputBorder(),
        ),
        maxLines: maxLines ?? 1,
        onTap: onTap,
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }
}