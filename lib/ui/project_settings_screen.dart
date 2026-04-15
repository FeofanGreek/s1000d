import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../controllers/app_controller.dart';
import '../styles.dart';
import 'widgets/project_settings_form.dart';

class ProjectSettingsScreen extends StatefulWidget {
  const ProjectSettingsScreen({super.key});

  @override
  State<ProjectSettingsScreen> createState() => _ProjectSettingsScreenState();
}

class _ProjectSettingsScreenState extends State<ProjectSettingsScreen> {
  late final TextEditingController modelIdentCodeCtrl;
  late final TextEditingController languageIsoCodeCtrl;
  late final TextEditingController languageCountryIsoCodeCtrl;
  late final TextEditingController techNameCtrl;
  late final TextEditingController partnerCodeCtrl;
  late final TextEditingController partnerNameCtrl;
  late final TextEditingController dataDistributionCtrl;
  late final TextEditingController copyrightParaCtrl;
  late final TextEditingController brexInfoCodeCtrl;
  late final TextEditingController brexLocationCtrl;

  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final controller = context.read<AppController>();
    modelIdentCodeCtrl = TextEditingController(text: controller.modelIdentCode);
    languageIsoCodeCtrl = TextEditingController(text: controller.languageIsoCode);
    languageCountryIsoCodeCtrl = TextEditingController(text: controller.languageCountryIsoCode);
    techNameCtrl = TextEditingController(text: controller.techName);
    partnerCodeCtrl = TextEditingController(text: controller.partnerCode);
    partnerNameCtrl = TextEditingController(text: controller.partnerName);
    dataDistributionCtrl = TextEditingController(text: controller.dataDistribution);
    copyrightParaCtrl = TextEditingController(text: controller.copyrightPara);
    brexInfoCodeCtrl = TextEditingController(text: controller.brexInfoCode);
    brexLocationCtrl = TextEditingController(text: controller.brexLocation);

    void markChanged() {
      if (!_hasChanges) {
        setState(() {
          _hasChanges = true;
        });
      }
    }

    modelIdentCodeCtrl.addListener(markChanged);
    languageIsoCodeCtrl.addListener(markChanged);
    languageCountryIsoCodeCtrl.addListener(markChanged);
    techNameCtrl.addListener(markChanged);
    partnerCodeCtrl.addListener(markChanged);
    partnerNameCtrl.addListener(markChanged);
    dataDistributionCtrl.addListener(markChanged);
    copyrightParaCtrl.addListener(markChanged);
    brexInfoCodeCtrl.addListener(markChanged);
    brexLocationCtrl.addListener(markChanged);
  }

  @override
  void dispose() {
    modelIdentCodeCtrl.dispose();
    languageIsoCodeCtrl.dispose();
    languageCountryIsoCodeCtrl.dispose();
    techNameCtrl.dispose();
    partnerCodeCtrl.dispose();
    partnerNameCtrl.dispose();
    dataDistributionCtrl.dispose();
    copyrightParaCtrl.dispose();
    brexInfoCodeCtrl.dispose();
    brexLocationCtrl.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: QRHColors.secondaryBg,
        title: const Text('Несохраненные изменения', style: TextStyle(color: QRHColors.textPrimary)),
        content: const Text('Вы хотите выйти без сохранения изменений?', style: TextStyle(color: QRHColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Отмена', style: TextStyle(color: QRHColors.textPrimary)),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            child: const Text('Выйти', style: TextStyle(color: QRHColors.danger)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, dynamic result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: QRHColors.primaryBg,
        appBar: AppBar(
          title: const Text('Настройки проекта'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (!_hasChanges) {
                if (context.mounted) context.pop();
              } else {
                final shouldPop = await _onWillPop();
                if (shouldPop && context.mounted) {
                  context.pop();
                }
              }
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Сохранить',
              onPressed: _hasChanges ? () async {
                final appCtrl = context.read<AppController>();
                appCtrl.modelIdentCode = modelIdentCodeCtrl.text;
                appCtrl.languageIsoCode = languageIsoCodeCtrl.text;
                appCtrl.languageCountryIsoCode = languageCountryIsoCodeCtrl.text;
                appCtrl.techName = techNameCtrl.text;
                appCtrl.partnerCode = partnerCodeCtrl.text;
                appCtrl.partnerName = partnerNameCtrl.text;
                appCtrl.dataDistribution = dataDistributionCtrl.text;
                appCtrl.copyrightPara = copyrightParaCtrl.text;
                appCtrl.brexInfoCode = brexInfoCodeCtrl.text;
                appCtrl.brexLocation = brexLocationCtrl.text;

                await appCtrl.saveProjectSettings();
                await appCtrl.applyProjectSettingsToFiles();
                
                if (context.mounted) {
                  await appCtrl.generateTOC(context, openViewer: false);
                }
                
                setState(() {
                  _hasChanges = false;
                });
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Настройки сохранены и применены к файлам'), backgroundColor: QRHColors.success),
                  );
                  context.pop();
                }
              } : null,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ProjectSettingsForm(
            modelIdentCodeCtrl: modelIdentCodeCtrl,
            languageIsoCodeCtrl: languageIsoCodeCtrl,
            languageCountryIsoCodeCtrl: languageCountryIsoCodeCtrl,
            techNameCtrl: techNameCtrl,
            partnerCodeCtrl: partnerCodeCtrl,
            partnerNameCtrl: partnerNameCtrl,
            dataDistributionCtrl: dataDistributionCtrl,
            copyrightParaCtrl: copyrightParaCtrl,
            brexInfoCodeCtrl: brexInfoCodeCtrl,
            brexLocationCtrl: brexLocationCtrl,
          ),
        ),
      ),
    );
  }
}
