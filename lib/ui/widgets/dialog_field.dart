import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../styles.dart';
import 'md_viewer_dialog.dart';

class DialogField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? errorText;
  final String? mdAbout;
  final RegExp? regExpPattern;
  final String? regExpErrorText;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final String? helperText;
  final Color? helperColor;

  const DialogField({
    super.key,
    required this.controller,
    required this.label,
    this.errorText,
    this.mdAbout,
    this.regExpPattern,
    this.regExpErrorText,
    this.maxLength,
    this.inputFormatters,
    this.helperText,
    this.helperColor,
  });

  @override
  State<DialogField> createState() => _DialogFieldState();
}

class _DialogFieldState extends State<DialogField> {
  String? _internalErrorText;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_validate);
    _validate();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_validate);
    super.dispose();
  }

  void _validate() {
    if (widget.regExpPattern != null) {
      final text = widget.controller.text;
      if (text.isNotEmpty && !widget.regExpPattern!.hasMatch(text)) {
        if (_internalErrorText == null) {
          setState(() {
            _internalErrorText = widget.regExpErrorText ?? 'Неверный формат';
          });
        }
      } else {
        if (_internalErrorText != null) {
          setState(() {
            _internalErrorText = null;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: widget.controller,
        maxLength: widget.maxLength,
        inputFormatters: widget.inputFormatters,
        style: const TextStyle(color: QRHColors.textPrimary),
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: const TextStyle(color: QRHColors.textTertiary),
          errorText: widget.errorText ?? _internalErrorText,
          errorStyle: const TextStyle(color: QRHColors.danger),
          helperText: widget.helperText,
          helperStyle: widget.helperColor != null ? TextStyle(color: widget.helperColor, fontSize: 12) : null,
          counterText: '',
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: widget.helperColor ?? QRHColors.borderColor),
          ),
          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: widget.helperColor ?? QRHColors.info)),
          suffix: SizedBox(
            width: widget.mdAbout != null ? 50 : 30,
            child: Row(
              children: [
                InkWell(
                  onTap: () {
                    widget.controller.clear();
                    _validate();
                  },
                  child: Icon(Icons.clear, color: QRHColors.textSecondary),
                ),
                if (widget.mdAbout != null)
                  InkWell(
                    onTap: () => _showMdAsset(context, widget.mdAbout!),
                    child: Icon(Icons.info_outline, color: QRHColors.textSecondary),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showMdAsset(BuildContext context, String assetPath) async {
    try {
      final mdContent = await rootBundle.loadString('assets/$assetPath');
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => MdViewerDialog(title: assetPath, mdContent: mdContent),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Не удалось загрузить файл: $e')));
      }
    }
  }
}
