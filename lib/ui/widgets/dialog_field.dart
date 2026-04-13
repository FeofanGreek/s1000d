import 'package:flutter/material.dart';
import '../../styles.dart';

class DialogField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? errorText;

  const DialogField({super.key, required this.controller, required this.label, this.errorText});

  @override
  State<DialogField> createState() => _DialogFieldState();
}

class _DialogFieldState extends State<DialogField> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: widget.controller,
        style: const TextStyle(color: QRHColors.textPrimary),
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: const TextStyle(color: QRHColors.textTertiary),
          errorText: widget.errorText,
          errorStyle: const TextStyle(color: QRHColors.danger),
          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: QRHColors.borderColor)),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: QRHColors.info)),
        ),
      ),
    );
  }
}
