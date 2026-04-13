import 'package:flutter/material.dart';
import '../../styles.dart';

class ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final TextStyle? textStyle;
  final AlignmentGeometry? alignment;

  const ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
    this.backgroundColor,
    this.textStyle,
    this.alignment,
  });

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: ElevatedButton.icon(
        onPressed: widget.onPressed,
        icon: Icon(widget.icon),
        label: Text(widget.label),
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.backgroundColor ?? QRHColors.secondaryBg,
          foregroundColor: widget.color,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: widget.textStyle ?? const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          alignment: widget.alignment ?? Alignment.centerLeft,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: widget.color.withValues(alpha: 0.5)),
          ),
        ),
      ),
    );
  }
}
