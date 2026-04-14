import 'package:flutter/material.dart';
import '../../styles.dart';
import 'dialog_field.dart';

class NewFileDialog extends StatefulWidget {
  final String title;
  final String actionText;
  final String initialSystemCode;
  final String initialInfoCode;
  final String initialInfoCodeVariant;
  final String initialInfoName;
  final bool Function(String sysCode, String infoCode, String variant) isFileExists;

  const NewFileDialog({
    super.key,
    required this.title,
    required this.actionText,
    required this.initialSystemCode,
    required this.initialInfoCode,
    required this.initialInfoCodeVariant,
    required this.initialInfoName,
    required this.isFileExists,
  });

  @override
  State<NewFileDialog> createState() => _NewFileDialogState();
}

class _NewFileDialogState extends State<NewFileDialog> {
  late TextEditingController sysCodeCtrl;
  late TextEditingController infoCodeCtrl;
  late TextEditingController infoCodeVarCtrl;
  late TextEditingController infoNameCtrl;

  bool _exists = false;

  @override
  void initState() {
    super.initState();
    sysCodeCtrl = TextEditingController(text: widget.initialSystemCode);
    infoCodeCtrl = TextEditingController(text: widget.initialInfoCode);
    infoCodeVarCtrl = TextEditingController(text: widget.initialInfoCodeVariant);
    infoNameCtrl = TextEditingController(text: widget.initialInfoName);

    sysCodeCtrl.addListener(_validate);
    infoCodeCtrl.addListener(_validate);
    infoCodeVarCtrl.addListener(_validate);
    infoNameCtrl.addListener(() => setState(() {})); // To toggle action button
    _validate();
  }

  void _validate() {
    final sysCode = sysCodeCtrl.text.trim();
    final infoCode = infoCodeCtrl.text.trim();
    final variant = infoCodeVarCtrl.text.trim();

    final exists = widget.isFileExists(sysCode, infoCode, variant);
    if (exists != _exists) {
      setState(() {
        _exists = exists;
      });
    }
  }

  @override
  void dispose() {
    sysCodeCtrl.removeListener(_validate);
    infoCodeCtrl.removeListener(_validate);
    infoCodeVarCtrl.removeListener(_validate);
    sysCodeCtrl.dispose();
    infoCodeCtrl.dispose();
    infoCodeVarCtrl.dispose();
    infoNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActionDisabled = _exists || infoNameCtrl.text.trim().isEmpty;

    return AlertDialog(
      backgroundColor: QRHColors.secondaryBg,
      title: Text(widget.title, style: const TextStyle(color: QRHColors.textPrimary)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DialogField(controller: sysCodeCtrl, label: 'System Code (e.g. D00)', mdAbout: 'about_system_code.md'),
            DialogField(
              controller: infoCodeCtrl,
              label: 'Info Code (e.g. 001)',
              mdAbout: 'about_info_code.md',
              errorText: _exists ? 'Файл уже существует' : null,
            ),
            DialogField(
              controller: infoCodeVarCtrl,
              label: 'Info Code Variant (e.g. A)',
              mdAbout: 'about_info_code_variant.md',
              errorText: _exists ? 'Укажите другой вариант' : null,
            ),
            DialogField(controller: infoNameCtrl, label: 'Название (Info Name / Title)'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Отмена', style: TextStyle(color: QRHColors.danger)),
        ),
        TextButton(
          onPressed: isActionDisabled
              ? null
              : () {
                  Navigator.pop(context, {
                    'sysCode': sysCodeCtrl.text.trim(),
                    'infoCode': infoCodeCtrl.text.trim(),
                    'infoCodeVar': infoCodeVarCtrl.text.trim(),
                    'infoName': infoNameCtrl.text.trim(),
                  });
                },
          child: Text(
            widget.actionText,
            style: TextStyle(color: isActionDisabled ? QRHColors.textSecondary : QRHColors.success),
          ),
        ),
      ],
    );
  }
}
