import 'package:flutter/material.dart';

class AppInput extends StatelessWidget {
  const AppInput({
    required this.controller,
    required this.label,
    this.icon,
    this.validator,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.sentences,
    super.key,
  });
  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: icon == null ? null : Icon(icon),
    ),
    validator: validator,
    keyboardType: keyboardType,
    textCapitalization: textCapitalization,
  );
}
