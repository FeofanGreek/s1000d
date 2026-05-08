import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../styles.dart';
import 'dialog_field.dart';

class ProjectSettingsForm extends StatelessWidget {
  final TextEditingController modelIdentCodeCtrl;
  final TextEditingController techNameCtrl;
  final TextEditingController partnerCodeCtrl;
  final TextEditingController partnerNameCtrl;
  final TextEditingController dataDistributionCtrl;
  final TextEditingController copyrightParaCtrl;
  final TextEditingController brexInfoCodeCtrl;
  final TextEditingController brexLocationCtrl;

  const ProjectSettingsForm({
    super.key,
    required this.modelIdentCodeCtrl,
    required this.techNameCtrl,
    required this.partnerCodeCtrl,
    required this.partnerNameCtrl,
    required this.dataDistributionCtrl,
    required this.copyrightParaCtrl,
    required this.brexInfoCodeCtrl,
    required this.brexLocationCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DialogField(
          controller: modelIdentCodeCtrl,
          label: 'Model Ident Code (e.g. MI171A3)',
          mdAbout: 'about_model_ident_code.md',
          regExpPattern: RegExp(r'^[A-Z0-9]{2,14}$'),
          regExpErrorText: 'Формат: 2-14 символов (A-Z, 0-9)',
          maxLength: 14,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]'))],
        ),
        DialogField(controller: techNameCtrl, label: 'Tech Name', mdAbout: 'about_tech_name.md'),
        DialogField(controller: partnerCodeCtrl, label: 'Partner Code', mdAbout: 'about_parthner_code.md'),
        DialogField(controller: partnerNameCtrl, label: 'Partner Name', mdAbout: 'about_parthner_name.md'),
        DialogField(
          controller: dataDistributionCtrl,
          label: 'Data Distribution',
          mdAbout: 'about_data_distribution.md',
        ),
        DialogField(controller: copyrightParaCtrl, label: 'Copyright Para'),
        DialogField(
          controller: brexInfoCodeCtrl,
          label: 'BREX Info Code (e.g. 022)',
          mdAbout: 'about_brex_info_code.md',
          regExpPattern: RegExp(r'^[A-Z0-9]{3}$'),
          regExpErrorText: 'Формат: 3 символа (A-Z, 0-9)',
          maxLength: 3,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]'))],
        ),
        DialogField(
          controller: brexLocationCtrl,
          label: 'BREX Location (e.g. D)',
          mdAbout: 'about_brex_location.md',
          regExpPattern: RegExp(r'^[ABCDT]$'),
          regExpErrorText: 'Формат: 1 символ (A, B, C, D, T)',
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[ABCDT]'))],
        ),
      ],
    );
  }
}
