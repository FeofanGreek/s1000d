import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xml/xml.dart';
import 'package:go_router/go_router.dart';
import '../../styles.dart';
import '../../../controllers/crew_viewer_controller.dart';
import 'models/crew_models.dart';
import 'widgets/crew_step_row.dart';
import 'widgets/crew_attention_row.dart';
import '../../../utils/validator_helper.dart';

class CrewViewer extends StatelessWidget {
  final XmlDocument document;
  final String fileName;
  final String? filePath;
  final String? fileTitle;

  const CrewViewer({super.key, required this.document, required this.fileName, this.filePath, required this.fileTitle});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          CrewViewerController(document: document, fileName: fileName, filePath: filePath, fileTitle: fileTitle),
      child: const _CrewViewerContent(),
    );
  }
}

class _CrewViewerContent extends StatelessWidget {
  const _CrewViewerContent();

  Future<void> _validateDocument(BuildContext context, CrewViewerController controller) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final validator = await ValidatorHelper.getValidator();
      final xmlString = controller.document.toXmlString(pretty: true);
      final result = await validator.validateString(xmlString);

      if (!context.mounted) return;
      Navigator.pop(context);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            result.isValid ? '✓ Валиден' : '✗ Ошибки валидации',
            style: TextStyle(color: result.isValid ? Colors.green : Colors.red),
          ),
          content: SingleChildScrollView(
            child: Text(result.toString(), style: const TextStyle(fontFamily: 'monospace')),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.verified_user),
              tooltip: 'Проверить S1000D',
              onPressed: () => _validateDocument(context, controller),
            ),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Закрыть')),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      print(e);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e', style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CrewViewerController>();
    final isEditMode = controller.isEditMode;

    if (controller.items.isEmpty && !isEditMode) {
      return Scaffold(
        backgroundColor: QRHColors.primaryBg,
        appBar: AppBar(
          title: Text(controller.fileTitle ?? 'Crew Data Module'),
          actions: [
            IconButton(
              icon: const Icon(Icons.verified_user),
              tooltip: 'Проверить S1000D',
              onPressed: () => _validateDocument(context, controller),
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Настройки файла',
              onPressed: () => controller.showFileSettingsDialog(context),
            ),
            Row(
              children: [
                const Text('Редактировать', style: TextStyle(fontSize: 14, color: QRHColors.textPrimary)),
                Switch(value: isEditMode, activeThumbColor: QRHColors.success, onChanged: controller.toggleEditMode),
              ],
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Center(
          child: Row(
            spacing: 10,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Тело документа пусто, начните с добавления "Заголовка"',
                style: TextStyle(color: QRHColors.danger, fontSize: 18),
              ),
              FloatingActionButton(
                heroTag: 'add_header',
                onPressed: controller.addHeader,
                backgroundColor: QRHColors.info,
                mini: true,
                child: const Icon(Icons.title, color: QRHColors.primaryBg),
              ),
            ],
          ),
        ),
      );
    }

    final allChecked = controller.checkboxStates.isNotEmpty && controller.checkboxStates.every((state) => state);

    return PopScope(
      canPop: !controller.hasChanges,
      onPopInvokedWithResult: (didPop, res) async {
        if (didPop) return;
        final shouldPop = await controller.onWillPop(context);
        if (shouldPop && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: QRHColors.primaryBg,
        appBar: AppBar(
          title: Text(controller.fileTitle ?? 'Чеклист экипажа (Crew)'),
          actions: [
            IconButton(
              icon: const Icon(Icons.verified_user),
              tooltip: 'Проверить S1000D',
              onPressed: () => _validateDocument(context, controller),
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Настройки файла',
              onPressed: () => controller.showFileSettingsDialog(context),
            ),
            Row(
              children: [
                const Text('Редактировать', style: TextStyle(fontSize: 14, color: QRHColors.textPrimary)),
                Switch(value: isEditMode, activeThumbColor: QRHColors.success, onChanged: controller.toggleEditMode),
              ],
            ),
            if (isEditMode)
              IconButton(
                icon: Icon(Icons.save, color: controller.hasChanges ? QRHColors.danger : QRHColors.textSecondary),
                onPressed: controller.hasChanges ? () => controller.saveChanges(context) : null,
                tooltip: 'Сохранить',
              ),
            const SizedBox(width: 8),
          ],
        ),
        body: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          itemCount: controller.items.length,
          separatorBuilder: (context, index) {
            if (controller.items[index] is CrewHeader ||
                (index + 1 < controller.items.length && controller.items[index + 1] is CrewHeader)) {
              return const SizedBox(height: 8);
            }
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Divider(color: QRHColors.dividerColor.withValues(alpha: 0.5), height: 1),
            );
          },
          itemBuilder: (context, index) {
            final item = controller.items[index];
            if (item is CrewHeader) {
              return Padding(
                padding: const EdgeInsets.only(top: 16.0, bottom: 8.0, left: 16.0, right: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: isEditMode
                          ? TextFormField(
                              initialValue: item.title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: QRHColors.textPrimary,
                              ),
                              decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                              onChanged: (val) => controller.updateHeaderTitle(item, val),
                            )
                          : Text(
                              item.title,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: QRHColors.info),
                            ),
                    ),
                    if (isEditMode)
                      IconButton(
                        icon: const Icon(Icons.delete, color: QRHColors.danger),
                        onPressed: () => controller.deleteItem(item),
                      ),
                  ],
                ),
              );
            } else if (item is CrewAttention) {
              return CrewAttentionRow(item: item);
            } else if (item is CrewStep) {
              return CrewStepRow(step: item);
            }
            return const SizedBox.shrink();
          },
        ),
        floatingActionButton: isEditMode
            ? Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FloatingActionButton(
                    heroTag: 'add_warning',
                    onPressed: () => controller.addAttention('warning'),
                    backgroundColor: QRHColors.danger,
                    mini: true,
                    child: const Icon(Icons.warning, color: QRHColors.primaryBg),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    heroTag: 'add_caution',
                    onPressed: () => controller.addAttention('caution'),
                    backgroundColor: QRHColors.warning,
                    mini: true,
                    child: const Icon(Icons.pan_tool, color: QRHColors.primaryBg),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    heroTag: 'add_note',
                    onPressed: () => controller.addAttention('note'),
                    backgroundColor: QRHColors.info,
                    mini: true,
                    child: const Icon(Icons.info_outline, color: QRHColors.primaryBg),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    heroTag: 'add_step',
                    onPressed: controller.addStep,
                    backgroundColor: QRHColors.success,
                    child: const Icon(Icons.add, color: QRHColors.primaryBg),
                  ),
                ],
              )
            : null,
        bottomNavigationBar: isEditMode
            ? const SizedBox.shrink()
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed: () => controller.completeChecklist(context),
                    icon: Icon(allChecked ? Icons.check_circle : Icons.playlist_add_check),
                    label: Text(allChecked ? 'ЧЕКЛИСТ ВЫПОЛНЕН' : 'ОТМЕТИТЬ ВЫПОЛНЕНИЕ ЧЕКЛИСТА'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: allChecked ? QRHColors.success : QRHColors.info,
                      foregroundColor: QRHColors.primaryBg,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
