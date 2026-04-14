import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  String? _infoCodeHelperText;
  Color? _infoCodeHelperColor;

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

    String? helperText;
    Color? helperColor;

    if (infoCode.isNotEmpty) {
      final codeInt = int.tryParse(infoCode);
      if (codeInt != null) {
        if (codeInt >= 1 && codeInt <= 99) {
          helperText = 'Аварийные процедуры / Описание';
          helperColor = QRHColors.danger;
        } else if (codeInt >= 100 && codeInt <= 199) {
          helperText = 'Обычные операции';
          helperColor = QRHColors.success;
        } else if (codeInt >= 200 && codeInt <= 299) {
          helperText = 'Проверки и осмотры';
          helperColor = QRHColors.info;
        } else if (codeInt >= 500 && codeInt <= 599) {
          helperText = 'Сборка и установка';
          helperColor = QRHColors.info;
        } else if (codeInt >= 700 && codeInt <= 799) {
          helperText = 'Разборка и демонтаж';
          helperColor = QRHColors.info;
        } else {
          helperText = 'Иная информация';
          helperColor = QRHColors.textSecondary;
        }
      }
    }

    if (exists != _exists || helperText != _infoCodeHelperText || helperColor != _infoCodeHelperColor) {
      setState(() {
        _exists = exists;
        _infoCodeHelperText = helperText;
        _infoCodeHelperColor = helperColor;
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
            DialogField(
              controller: sysCodeCtrl,
              label: 'System Code (e.g. D00)',
              mdAbout: 'about_system_code.md',
              regExpPattern: RegExp(r'^[A-Z0-9]{2,3}$'),
              regExpErrorText: 'Формат: 2-3 символа (A-Z, 0-9)',
              maxLength: 3,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]'))],
            ),
            DialogField(
              controller: infoCodeCtrl,
              label: 'Info Code (e.g. 001)',
              mdAbout: 'about_info_code.md',
              errorText: _exists ? 'Файл уже существует' : null,
              helperText: _infoCodeHelperText,
              helperColor: _infoCodeHelperColor,
              regExpPattern: RegExp(r'^[A-Z0-9]{3}$'),
              regExpErrorText: 'Формат: 3 символа (A-Z, 0-9)',
              maxLength: 3,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]'))],
            ),
            DialogField(
              controller: infoCodeVarCtrl,
              label: 'Info Code Variant (e.g. A)',
              mdAbout: 'about_info_code_variant.md',
              errorText: _exists ? 'Укажите другой вариант' : null,
              regExpPattern: RegExp(r'^[A-Z0-9]{1}$'),
              regExpErrorText: 'Формат: 1 символ (A-Z, 0-9)',
              maxLength: 1,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]'))],
            ),
            DialogField(controller: infoNameCtrl, label: 'Название (Info Name / Title)'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(),
          child: const Text('Отмена', style: TextStyle(color: QRHColors.danger)),
        ),
        TextButton(
          onPressed: isActionDisabled
              ? null
              : () {
                  context.pop({
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
