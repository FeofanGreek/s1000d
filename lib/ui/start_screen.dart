import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../styles.dart';
import '../controllers/app_controller.dart';
import 'widgets/action_button.dart';
import 'widgets/md_viewer_dialog.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final isProjectLoaded = controller.workDir != null;

    return Scaffold(
      backgroundColor: QRHColors.primaryBg,
      appBar: AppBar(
        title: Text(
          isProjectLoaded
              ? 'Проект: ${controller.techName} ${controller.workDir!.path.split(Platform.pathSeparator).last}'
              : 'S1000D Viewer',
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Помощь',
            onSelected: (String value) {
              _showMdAsset(context, value);
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(value: 'checklist_example.md', child: Text('Пример чек-листа')),
              const PopupMenuItem<String>(value: 'description_template.md', child: Text('Шаблон описания')),
              const PopupMenuItem<String>(value: 'user_manual.md', child: Text('Руководство пользователя')),
            ],
          ),
          if (isProjectLoaded) ...[
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Настройки проекта',
              onPressed: () => context.push('/project_settings'),
            ),
            IconButton(
              icon: const Icon(Icons.folder),
              tooltip: 'Открыть проект',
              onPressed: () => context.read<AppController>().pickProject(context),
            ),
            IconButton(
              icon: const Icon(Icons.format_list_numbered),
              tooltip: 'Открыть оглавление',
              onPressed: () => context.read<AppController>().openOrGenerateTOC(context, true),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Закрыть проект',
              onPressed: () => context.read<AppController>().closeProject(),
            ),
          ],
        ],
      ),
      body: Center(
        child: isProjectLoaded
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ActionButton(
                    icon: Icons.format_list_numbered,
                    label: 'Открыть оглавление',
                    color: QRHColors.textPrimary,
                    onPressed: () => context.read<AppController>().openOrGenerateTOC(context, false),
                  ),
                  const SizedBox(height: 16),
                  ActionButton(
                    icon: Icons.folder_open,
                    label: 'Открыть XML файл',
                    color: QRHColors.info,
                    onPressed: () => context.read<AppController>().pickFile(context),
                  ),
                  const SizedBox(height: 16),
                  ActionButton(
                    icon: Icons.add_box,
                    label: 'Создать XML файл (чек-лист)',
                    color: QRHColors.success,
                    onPressed: () => context.read<AppController>().createNewXmlFile(context),
                  ),
                  const SizedBox(height: 16),
                  ActionButton(
                    icon: Icons.checklist_rtl,
                    label: 'Импорт чеклиста из MD',
                    color: QRHColors.warning,
                    onPressed: () => context.read<AppController>().importMarkdownFile(context, isCrew: true),
                  ),
                  const SizedBox(height: 16),
                  ActionButton(
                    icon: Icons.description,
                    label: 'Импорт описания из MD',
                    color: QRHColors.warning,
                    onPressed: () => context.read<AppController>().importMarkdownFile(context, isCrew: false),
                  ),
                ],
              )
            : ActionButton(
                icon: Icons.folder,
                label: 'Открыть проект',
                color: QRHColors.textPrimary,
                backgroundColor: QRHColors.accentBg,
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                alignment: Alignment.center,
                onPressed: () => context.read<AppController>().pickProject(context),
              ),
      ),
    );
  }
}
