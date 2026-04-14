import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:xml/xml.dart';
import 'package:go_router/go_router.dart';
import '../../styles.dart';

class DescriptionViewer extends StatefulWidget {
  final XmlDocument document;
  final String fileName;
  final String? filePath;

  const DescriptionViewer({
    super.key, 
    required this.document, 
    required this.fileName,
    this.filePath,
  });

  @override
  State<DescriptionViewer> createState() => _DescriptionViewerState();
}

class _DescriptionViewerState extends State<DescriptionViewer> {
  bool _isEditMode = false;
  bool _hasChanges = false;

  Future<void> _saveChanges() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('В браузере сохранение локального файла недоступно.'),
          backgroundColor: QRHColors.warning,
        )
      );
      return;
    }

    if (widget.filePath != null) {
      try {
        final file = File(widget.filePath!);
        await file.writeAsString(widget.document.toXmlString());
        setState(() {
          _hasChanges = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Изменения успешно сохранены!'),
              backgroundColor: QRHColors.success,
            )
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка сохранения: $e'),
              backgroundColor: QRHColors.danger,
            )
          );
        }
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    final exit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: QRHColors.secondaryBg,
        title: const Text('Есть несохраненные изменения', style: TextStyle(color: QRHColors.textPrimary)),
        content: const Text('Вы уверены, что хотите выйти без сохранения?', style: TextStyle(color: QRHColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => context.pop(false), 
            child: const Text('Отмена', style: TextStyle(color: QRHColors.info))
          ),
          TextButton(
            onPressed: () => context.pop(true), 
            child: const Text('Выйти', style: TextStyle(color: QRHColors.danger))
          ),
        ],
      )
    );
    return exit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    // Ищем тег <description>, он может быть внутри <content>
    final descriptionTags = widget.document.findAllElements('description');
    if (descriptionTags.isEmpty) {
      return Scaffold(
        backgroundColor: QRHColors.primaryBg,
        appBar: AppBar(title: const Text('Description Data Module')),
        body: const Center(
          child: Text(
            'Тег <description> не найден',
            style: TextStyle(color: QRHColors.danger, fontSize: 18),
          ),
        ),
      );
    }

    final descriptionNode = descriptionTags.first;

    return PopScope(
      canPop: !_hasChanges,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: QRHColors.primaryBg,
        appBar: AppBar(
          title: const Text('Описание (Description)'),
          actions: [
            Row(
              children: [
                const Text('Редактировать', style: TextStyle(fontSize: 14, color: QRHColors.textPrimary)),
                Switch(
                  value: _isEditMode,
                  activeColor: QRHColors.success,
                  onChanged: (val) => setState(() => _isEditMode = val),
                ),
              ],
            ),
            if (_isEditMode)
              IconButton(
                icon: Icon(Icons.save, color: _hasChanges ? QRHColors.danger : QRHColors.textSecondary),
                onPressed: _hasChanges ? _saveChanges : null,
                tooltip: 'Сохранить',
              ),
            const SizedBox(width: 8),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: descriptionNode.children
                .whereType<XmlElement>()
                .map((child) => _buildNode(child, context, 0))
                .toList(),
          ),
        ),
      ),
    );
  }

  // Рекурсивный обход элементов. 
  // Флаг inListItem нужен, чтобы разрешить редактирование только в <listItem><para>
  Widget _buildNode(XmlElement node, BuildContext context, int depth, {bool inListItem = false}) {
    final name = node.name.local;

    switch (name) {
      case 'title':
        return Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
          child: Text(
            _cleanText(node.innerText),
            style: TextStyle(
              fontSize: depth == 0 ? 24 : (depth == 1 ? 20 : 18),
              fontWeight: FontWeight.bold,
              color: QRHColors.textPrimary,
            ),
          ),
        );

      case 'para':
        if (inListItem && _isEditMode) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: TextFormField(
              initialValue: _cleanText(node.innerText),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: QRHColors.info),
              maxLines: null,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.all(12),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: QRHColors.info)),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: QRHColors.borderColor)),
              ),
              onChanged: (val) {
                node.children.clear();
                node.children.add(XmlText(val));
                if (!_hasChanges) setState(() => _hasChanges = true);
              },
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            _cleanText(node.innerText),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: QRHColors.textSecondary,
                  height: 1.4,
                ),
          ),
        );

      case 'levelledPara':
        return Padding(
          padding: EdgeInsets.only(left: depth == 0 ? 0.0 : 16.0, top: 8.0, bottom: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: node.children
                .whereType<XmlElement>()
                .map((child) => _buildNode(child, context, depth + 1, inListItem: inListItem))
                .toList(),
          ),
        );

      case 'randomList':
      case 'sequentialList':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: node.children
                .whereType<XmlElement>()
                .map((child) => _buildNode(child, context, depth, inListItem: inListItem))
                .toList(),
          ),
        );

      case 'listItem':
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 8.0, right: 12.0),
                child: Icon(Icons.circle, size: 6, color: QRHColors.textTertiary),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: node.children
                      .whereType<XmlElement>()
                      .map((child) => _buildNode(child, context, depth, inListItem: true))
                      .toList(),
                ),
              ),
            ],
          ),
        );

      case 'note':
      case 'warning':
      case 'caution':
        return _buildAlertBox(node, context, name, depth, inListItem);

      case 'notePara':
      case 'warningPara':
      case 'cautionPara':
        return Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Text(
            _cleanText(node.innerText),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: QRHColors.textPrimary,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
          ),
        );

      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: node.children
              .whereType<XmlElement>()
              .map((child) => _buildNode(child, context, depth, inListItem: inListItem))
              .toList(),
        );
    }
  }

  Widget _buildAlertBox(XmlElement node, BuildContext context, String type, int depth, bool inListItem) {
    Color borderColor;
    Color bgColor;
    IconData icon;
    String headerText;

    if (type == 'warning') {
      borderColor = QRHColors.danger;
      bgColor = QRHColors.danger.withValues(alpha: 0.1);
      icon = Icons.warning_amber_rounded;
      headerText = 'ПРЕДУПРЕЖДЕНИЕ';
    } else if (type == 'caution') {
      borderColor = QRHColors.warning;
      bgColor = QRHColors.warning.withValues(alpha: 0.1);
      icon = Icons.report_problem_outlined;
      headerText = 'ВНИМАНИЕ';
    } else {
      borderColor = QRHColors.info;
      bgColor = QRHColors.accentBg;
      icon = Icons.info_outline;
      headerText = 'ПРИМЕЧАНИЕ';
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(left: BorderSide(color: borderColor, width: 4.0)),
        borderRadius: const BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: borderColor, size: 22),
              const SizedBox(width: 8),
              Text(
                headerText,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: borderColor,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...node.children
              .whereType<XmlElement>()
              .map((child) => _buildNode(child, context, depth, inListItem: inListItem))
              .toList(),
        ],
      ),
    );
  }

  String _cleanText(String text) {
    return text.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}
