import 'package:flutter/material.dart';
import 'package:xml/xml.dart';
import '../../styles.dart';
import 'widgets/pm_node_widget.dart';

class PmViewer extends StatefulWidget {
  final XmlDocument document;
  final String fileName;
  final String? filePath; // null для веба

  const PmViewer({super.key, required this.document, required this.fileName, this.filePath});

  @override
  State<PmViewer> createState() => _PmViewerState();
}

class _PmViewerState extends State<PmViewer> {
  bool _isGridView = true;
  XmlElement? _selectedEntry;

  Widget _buildTile(BuildContext context, XmlElement entry) {
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

    final int count = entry.findAllElements('dmRef').length;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedEntry = entry;
        });
      },
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

  @override
  Widget build(BuildContext context) {
    final contentTags = widget.document.findAllElements('content');
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
      canPop: _selectedEntry == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        setState(() {
          _selectedEntry = null;
        });
      },
      child: Scaffold(
        backgroundColor: QRHColors.primaryBg,
        appBar: AppBar(
          title: Text(
            _selectedEntry == null
                ? 'Содержание (PM)'
                : (_selectedEntry!.findElements('pmEntryTitle').firstOrNull?.innerText ?? 'Раздел'),
          ),
          leading: _selectedEntry != null
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      _selectedEntry = null;
                    });
                  },
                )
              : null,
          actions: [
            if (_selectedEntry == null)
              IconButton(
                icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
                tooltip: _isGridView ? 'Списком' : 'Плиткой',
                onPressed: () {
                  setState(() {
                    _isGridView = !_isGridView;
                  });
                },
              ),
          ],
        ),
        body: _buildBody(contentNode, topLevelEntries),
      ),
    );
  }

  Widget _buildBody(XmlElement contentNode, List<XmlElement> topLevelEntries) {
    if (_selectedEntry != null) {
      // Детальный просмотр выбранного раздела
      final children = _selectedEntry!.children
          .whereType<XmlElement>()
          .where((e) => e.name.local != 'pmEntryTitle')
          .toList();

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children.map((child) => PmNodeWidget(node: child, depth: 0)).toList(),
        ),
      );
    }

    if (!_isGridView) {
      // Старый вид списком
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: contentNode.children
              .whereType<XmlElement>()
              .map((child) => PmNodeWidget(node: child, depth: 0))
              .toList(),
        ),
      );
    }

    // Вид плитками
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.9,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: topLevelEntries.length,
      itemBuilder: (context, index) {
        return _buildTile(context, topLevelEntries[index]);
      },
    );
  }
}
