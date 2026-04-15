import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../../styles.dart';
import 'dialog_field.dart';

class FileSettingsForm extends StatefulWidget {
  final TextEditingController sysCodeCtrl;
  final TextEditingController infoCodeCtrl;
  final TextEditingController infoCodeVarCtrl;
  final TextEditingController infoNameCtrl;
  final bool Function(String sysCode, String infoCode, String variant) isFileExists;
  final VoidCallback onValidationChanged;

  const FileSettingsForm({
    super.key,
    required this.sysCodeCtrl,
    required this.infoCodeCtrl,
    required this.infoCodeVarCtrl,
    required this.infoNameCtrl,
    required this.isFileExists,
    required this.onValidationChanged,
  });

  @override
  State<FileSettingsForm> createState() => FileSettingsFormState();
}

class FileSettingsFormState extends State<FileSettingsForm> {
  bool exists = false;
  String? _infoCodeHelperText;
  Color? _infoCodeHelperColor;

  final Map<String, String> _infoCategories = {
    '040: Аварийные ситуации': '040',
    '050: Сложные ситуации': '050',
    '030: Контрольные карты': '030',
    '060: Нормальная эксплуатация': '060',
    '020: Ограничения': '020',
    '005: ТМПО (MEL)': '005',
    '041: Описание (системы/КСЭИС/АСО)': '041',
    '001: Общие данные': '001',
  };

  @override
  void initState() {
    super.initState();
    widget.sysCodeCtrl.addListener(_validate);
    widget.infoCodeVarCtrl.addListener(_validate);
    widget.infoNameCtrl.addListener(_validate);
    _validate();
  }

  @override
  void dispose() {
    widget.sysCodeCtrl.removeListener(_validate);
    widget.infoCodeVarCtrl.removeListener(_validate);
    widget.infoNameCtrl.removeListener(_validate);
    super.dispose();
  }

  void _validate() {
    final sysCode = widget.sysCodeCtrl.text.trim().toUpperCase();
    final infoCode = widget.infoCodeCtrl.text.trim();
    final variant = widget.infoCodeVarCtrl.text.trim().toUpperCase();

    final newExists = widget.isFileExists(sysCode, infoCode, variant);

    String? helperText;
    Color? helperColor;

    if (infoCode.isNotEmpty) {
      if (infoCode == '040') {
        helperText = 'Категория: АВАРИЙНЫЕ';
        helperColor = QRHColors.danger;
      } else if (infoCode == '050') {
        helperText = 'Категория: СЛОЖНЫЕ';
        helperColor = Colors.orange;
      } else if (infoCode == '030') {
        helperText = 'Категория: КОНТРОЛЬНЫЕ КАРТЫ';
        helperColor = QRHColors.success;
      } else if (sysCode.startsWith('31') && infoCode == '041') {
        helperText = 'Категория: КСЭИС';
        helperColor = Colors.indigoAccent;
      } else if (sysCode.startsWith('25') && infoCode == '041') {
        helperText = 'Категория: АВАРИЙНО-СПАСАТЕЛЬНОЕ';
        helperColor = Colors.cyan;
      } else {
        helperText = 'Категория определена кодом $infoCode';
        helperColor = QRHColors.textSecondary;
      }
    }

    if (newExists != exists || helperText != _infoCodeHelperText || helperColor != _infoCodeHelperColor) {
      setState(() {
        exists = newExists;
        _infoCodeHelperText = helperText;
        _infoCodeHelperColor = helperColor;
      });
    }
    
    // Уведомляем родителя, что состояние валидации могло измениться
    widget.onValidationChanged();
  }

  bool get isValid {
    return !exists && widget.infoNameCtrl.text.trim().isNotEmpty && widget.infoCodeCtrl.text.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DialogField(
          controller: widget.sysCodeCtrl,
          label: 'System Code (SNS)',
          mdAbout: 'about_system_code.md',
          maxLength: 3,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
            TextInputFormatter.withFunction(
              (oldValue, newValue) => newValue.copyWith(text: newValue.text.toUpperCase()),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Info Code (Категория)', style: TextStyle(color: QRHColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _infoCategories.values.contains(widget.infoCodeCtrl.text) ? widget.infoCodeCtrl.text : null,
          dropdownColor: QRHColors.secondaryBg,
          style: const TextStyle(color: QRHColors.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: QRHColors.primaryBg,
            errorText: exists ? 'Такой файл уже есть измени (SNS) или Variant' : null,
            helperText: _infoCodeHelperText,
            helperStyle: TextStyle(color: _infoCodeHelperColor),
            border: const OutlineInputBorder(),
          ),
          items: _infoCategories.entries.map((e) {
            return DropdownMenuItem(value: e.value, child: Text(e.key));
          }).toList(),
          onChanged: (val) {
            setState(() {
              widget.infoCodeCtrl.text = val ?? '';
              _validate();
            });
          },
        ),
        const SizedBox(height: 16),
        DialogField(
          controller: widget.infoCodeVarCtrl,
          label: 'Variant',
          mdAbout: 'about_info_code_variant.md',
          maxLength: 1,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
            TextInputFormatter.withFunction(
              (oldValue, newValue) => newValue.copyWith(text: newValue.text.toUpperCase()),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DialogField(controller: widget.infoNameCtrl, label: 'Название документа (Title)'),
      ],
    );
  }
}