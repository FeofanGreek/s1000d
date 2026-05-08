import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xml/xml.dart';
import '../../controllers/app_controller.dart';
import '../../controllers/pm_viewer_controller.dart';
import '../../styles.dart';
import 'widgets/pm_node_widget.dart';

class PmViewer extends StatelessWidget {
  final XmlDocument document;
  final String fileName;
  final String? filePath;

  const PmViewer({super.key, required this.document, required this.fileName, this.filePath});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PmViewerController(document: document, fileName: fileName, filePath: filePath),
      child: const _PmViewerBody(),
    );
  }
}

class _PmViewerBody extends StatelessWidget {
  const _PmViewerBody();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PmViewerController>();
    final appController = context.read<AppController>();

    final documentToShow = controller.document;
    final contentTags = documentToShow.findAllElements('content');

    if (contentTags.isEmpty) {
      return Scaffold(
        backgroundColor: QRHColors.primaryBg,
        appBar: AppBar(title: const Text('Publication Module')),
        body: const Center(
          child: Text('Тег <content> не найден', style: TextStyle(color: QRHColors.danger, fontSize: 18)),
        ),
      );
    }

    final contentNode = contentTags.first;
    final topLevelEntries = contentNode.children
        .whereType<XmlElement>()
        .where((e) => e.name.local == 'pmEntry')
        .toList();

    return PopScope(
      canPop: controller.selectedEntry == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        controller.selectEntry(null);
      },
      child: Scaffold(
        backgroundColor: QRHColors.primaryBg,
        appBar: AppBar(
          title: Text(
            controller.selectedEntry == null
                ? 'Содержание (PM)'
                : (controller.selectedEntry!.findElements('pmEntryTitle').firstOrNull?.innerText ?? 'Раздел'),
          ),
          leading: controller.selectedEntry != null
              ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => controller.selectEntry(null))
              : null,
          actions: [
            if (controller.isMultilingualIncomplete)
              const Tooltip(
                message: 'В оглавлении отсутствуют копии файлов на некоторых языках',
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Icon(Icons.warning_amber_rounded, color: QRHColors.warning),
                ),
              ),
            if (controller.selectedEntry == null)
              if (controller.isEditing) ...[
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Отмена',
                  onPressed: () => controller.cancelEditing(),
                ),
                IconButton(
                  icon: const Icon(Icons.save),
                  tooltip: 'Сохранить',
                  onPressed: () => controller.saveChanges(context),
                ),
              ] else
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Редактировать',
                  onPressed: () => controller.startEditing(),
                ),
            if (controller.selectedEntry == null && !controller.isEditing)
              IconButton(
                icon: Icon(controller.isGridView ? Icons.view_list : Icons.grid_view),
                tooltip: controller.isGridView ? 'Списком' : 'Плиткой',
                onPressed: () => controller.toggleViewMode(),
              ),
          ],
        ),
        floatingActionButton: controller.isEditing
            ? FloatingActionButton(
                onPressed: () => controller.addFile(context, appController),
                child: const Icon(Icons.add),
              )
            : null,
        body: Column(
          children: [
            if (controller.selectedEntry == null) _buildLanguageFilter(context, controller, appController),
            Expanded(child: _buildBody(context, controller, contentNode, topLevelEntries)),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageFilter(BuildContext context, PmViewerController controller, AppController appController) {
    final languages = controller.allProjectLanguages;
    if (languages.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      color: QRHColors.secondaryBg.withValues(alpha: 0.5),
      child: Row(
        children: [
          const Icon(Icons.filter_list, color: QRHColors.textSecondary, size: 20),
          const SizedBox(width: 8),
          const Text('Язык:', style: TextStyle(color: QRHColors.textSecondary)),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Все'),
                    selected: controller.selectedLanguageFilter == null,
                    onSelected: (val) => controller.setLanguageFilter(null),
                  ),
                  ...languages.map((lang) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: ChoiceChip(
                        label: Text(lang),
                        selected: controller.selectedLanguageFilter == lang,
                        onSelected: (val) => controller.setLanguageFilter(val ? lang : null),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          if (controller.selectedLanguageFilter != null) ...[
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () =>
                  controller.createTocForLanguage(context, controller.selectedLanguageFilter!, appController),
              icon: const Icon(Icons.format_list_numbered, size: 18),
              label: Text('Создать PMC для ${controller.selectedLanguageFilter}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: QRHColors.info.withValues(alpha: 0.2),
                foregroundColor: QRHColors.info,
              ),
            ),
          ] else ...[
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () => appController.generateAllTOCs(context),
              icon: const Icon(Icons.library_add, size: 18),
              label: const Text('Обновить все оглавления'),
              style: ElevatedButton.styleFrom(
                backgroundColor: QRHColors.success.withValues(alpha: 0.2),
                foregroundColor: QRHColors.success,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    PmViewerController controller,
    XmlElement contentNode,
    List<XmlElement> topLevelEntries,
  ) {
    final filter = controller.selectedLanguageFilter;

    // Вспомогательная функция для фильтрации dmRefs
    bool shouldShowNode(XmlElement node) {
      if (filter == null) return true;
      if (node.name.local == 'pmEntry') {
        // Показываем pmEntry, если внутри есть хоть один подходящий dmRef (рекурсивно)
        return node.findAllElements('dmRef').any((ref) {
          final langNode = ref.findAllElements('language').firstOrNull;
          if (langNode == null) return false;
          final tag = '${langNode.getAttribute('languageIsoCode')}-${langNode.getAttribute('countryIsoCode')}';
          return tag == filter;
        });
      }
      if (node.name.local == 'dmRef') {
        final langNode = node.findAllElements('language').firstOrNull;
        if (langNode == null) return false;
        final tag = '${langNode.getAttribute('languageIsoCode')}-${langNode.getAttribute('countryIsoCode')}';
        return tag == filter;
      }
      return true;
    }

    if (controller.selectedEntry != null) {
      final children = controller.selectedEntry!.children
          .whereType<XmlElement>()
          .where((e) => e.name.local != 'pmEntryTitle')
          .where(shouldShowNode)
          .toList();

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children
              .map(
                (child) => PmNodeWidget(
                  node: child,
                  depth: 0,
                  isEditing: controller.isEditing,
                  onDelete: (node) => controller.deleteNode(node),
                  languageFilter: filter,
                ),
              )
              .toList(),
        ),
      );
    }

    if (!controller.isGridView) {
      final children = contentNode.children.whereType<XmlElement>().where(shouldShowNode).toList();

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children
              .map(
                (child) => PmNodeWidget(
                  node: child,
                  depth: 0,
                  isEditing: controller.isEditing,
                  onDelete: (node) => controller.deleteNode(node),
                  languageFilter: filter,
                ),
              )
              .toList(),
        ),
      );
    }

    final filteredTopLevel = topLevelEntries.where(shouldShowNode).toList();

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.9,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: filteredTopLevel.length,
      itemBuilder: (context, index) {
        return _buildTile(context, controller, filteredTopLevel[index]);
      },
    );
  }

  Widget _buildTile(BuildContext context, PmViewerController controller, XmlElement entry) {
    final title = entry.findElements('pmEntryTitle').firstOrNull?.innerText ?? 'Без заголовка';

    Color color = QRHColors.textPrimary;
    if (title.contains('040')) {
      color = QRHColors.danger;
    } else if (title.contains('050')) {
      color = QRHColors.caution;
    } else if (title.contains('030')) {
      color = QRHColors.success;
    } else if (title.contains('041')) {
      color = QRHColors.info;
    }

    // При расчете количества файлов в плитке тоже учитываем фильтр
    final filter = controller.selectedLanguageFilter;
    final int count = entry.findAllElements('dmRef').where((ref) {
      if (filter == null) return true;
      final langNode = ref.findAllElements('language').firstOrNull;
      if (langNode == null) return false;
      final tag = '${langNode.getAttribute('languageIsoCode')}-${langNode.getAttribute('countryIsoCode')}';
      return tag == filter;
    }).length;

    return InkWell(
      onTap: () => controller.selectEntry(entry),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: QRHColors.accentBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_special, size: 48, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const Spacer(),
            Text('$count файлов', style: const TextStyle(color: QRHColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
