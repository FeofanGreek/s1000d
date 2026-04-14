import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../styles.dart';
import 'md_viewer_dialog.dart';

class DialogField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? errorText;
  final String? mdAbout;

  const DialogField({super.key, required this.controller, required this.label, this.errorText, this.mdAbout});

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
          suffix: SizedBox(
            width: widget.mdAbout != null ? 50 : 30,
            child: Row(
              children: [
                InkWell(
                  onTap: () => widget.controller.clear(),
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
