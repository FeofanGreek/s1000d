import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../styles.dart';
import 'file_settings_form.dart';

class NewFileDialog extends StatefulWidget {
  final String title;
  final String actionText;
  final String initialSystemCode;
  final String initialInfoCode;
  final String initialInfoCodeVariant;
  final String initialInfoName;
  final String initialLanguageIsoCode;
  final String initialLanguageCountryIsoCode;
  final String initialIssueNumber;
  final String initialInWork;
  final String modelIdentCode;
  final bool Function(String sysCode, String infoCode, String variant) isFileExists;

  const NewFileDialog({
    super.key,
    required this.title,
    required this.actionText,
    required this.initialSystemCode,
    required this.initialInfoCode,
    required this.initialInfoCodeVariant,
    required this.initialInfoName,
    required this.initialLanguageIsoCode,
    required this.initialLanguageCountryIsoCode,
    this.initialIssueNumber = '001',
    this.initialInWork = '00',
    required this.modelIdentCode,
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
  late TextEditingController languageIsoCodeCtrl;
  late TextEditingController languageCountryIsoCodeCtrl;
  late TextEditingController issueNumberCtrl;
  late TextEditingController inWorkCtrl;

  final GlobalKey<FileSettingsFormState> _formKey = GlobalKey<FileSettingsFormState>();
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    sysCodeCtrl = TextEditingController(text: widget.initialSystemCode);
    infoCodeCtrl = TextEditingController(text: widget.initialInfoCode);
    infoCodeVarCtrl = TextEditingController(text: widget.initialInfoCodeVariant);
    infoNameCtrl = TextEditingController(text: widget.initialInfoName);
    languageIsoCodeCtrl = TextEditingController(text: widget.initialLanguageIsoCode);
    languageCountryIsoCodeCtrl = TextEditingController(text: widget.initialLanguageCountryIsoCode);
    issueNumberCtrl = TextEditingController(text: widget.initialIssueNumber);
    inWorkCtrl = TextEditingController(text: widget.initialInWork);
  }

  void _onValidationChanged() {
    final isValid = _formKey.currentState?.isValid ?? false;
    if (isValid != _isValid) {
      setState(() {
        _isValid = isValid;
      });
    }
  }

  @override
  void dispose() {
    sysCodeCtrl.dispose();
    infoCodeCtrl.dispose();
    infoCodeVarCtrl.dispose();
    infoNameCtrl.dispose();
    languageIsoCodeCtrl.dispose();
    languageCountryIsoCodeCtrl.dispose();
    issueNumberCtrl.dispose();
    inWorkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: QRHColors.secondaryBg,
      title: Text(widget.title, style: const TextStyle(color: QRHColors.textPrimary)),
      content: SingleChildScrollView(
        child: FileSettingsForm(
          key: _formKey,
          sysCodeCtrl: sysCodeCtrl,
          infoCodeCtrl: infoCodeCtrl,
          infoCodeVarCtrl: infoCodeVarCtrl,
          infoNameCtrl: infoNameCtrl,
          languageIsoCodeCtrl: languageIsoCodeCtrl,
          languageCountryIsoCodeCtrl: languageCountryIsoCodeCtrl,
          issueNumberCtrl: issueNumberCtrl,
          inWorkCtrl: inWorkCtrl,
          modelIdentCode: widget.modelIdentCode,
          isFileExists: widget.isFileExists,
          onValidationChanged: _onValidationChanged,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(),
          child: const Text('Отмена', style: TextStyle(color: QRHColors.danger)),
        ),
        ElevatedButton(
          onPressed: !_isValid
              ? null
              : () {
                  context.pop({
                    'sysCode': sysCodeCtrl.text.trim().toUpperCase(),
                    'infoCode': infoCodeCtrl.text.trim(),
                    'infoCodeVar': infoCodeVarCtrl.text.trim().toUpperCase(),
                    'infoName': infoNameCtrl.text.trim(),
                    'languageIsoCode': languageIsoCodeCtrl.text.trim().toLowerCase(),
                    'languageCountryIsoCode': languageCountryIsoCodeCtrl.text.trim().toUpperCase(),
                    'issueNumber': issueNumberCtrl.text.trim(),
                    'inWork': inWorkCtrl.text.trim(),
                  });
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: !_isValid ? Colors.transparent : QRHColors.success.withValues(alpha: 0.2),
          ),
          child: Text(
            widget.actionText,
            style: TextStyle(color: !_isValid ? QRHColors.textSecondary : QRHColors.success),
          ),
        ),
      ],
    );
  }
}
