import 'package:flutter/material.dart';
import 'package:xml/xml.dart';
import '../../../styles.dart';
import 'pm_dm_ref_widget.dart';

class PmNodeWidget extends StatelessWidget {
  final XmlElement node;
  final int depth;
  final bool isEditing;
  final ValueChanged<XmlElement>? onDelete;
  final String? languageFilter;

  const PmNodeWidget({
    super.key,
    required this.node,
    required this.depth,
    this.isEditing = false,
    this.onDelete,
    this.languageFilter,
  });

  @override
  Widget build(BuildContext context) {
    if (node.name.local == 'pmEntry') {
      // Предварительно фильтруем дочерние элементы
      final rawChildren = node.children.whereType<XmlElement>().where((e) => e.name.local != 'pmEntryTitle').toList();

      final filteredChildren = rawChildren.where((e) {
        if (languageFilter == null) return true;
        if (e.name.local == 'dmRef') {
          final langNode = e.findAllElements('language').firstOrNull;
          if (langNode == null) return false;
          final tag = '${langNode.getAttribute('languageIsoCode')}-${langNode.getAttribute('countryIsoCode')}';
          return tag == languageFilter;
        }
        return true; // pmEntry оставляем, они отфильтруются внутри
      }).toList();

      // Если после фильтрации в pmEntry ничего не осталось (и это не верхний уровень), скрываем его
      if (languageFilter != null && filteredChildren.isEmpty && depth > 0) {
        return const SizedBox.shrink();
      }

      final title = node.findElements('pmEntryTitle').firstOrNull?.innerText ?? 'Без заголовка';

      Color titleColor = QRHColors.textPrimary;
      if (depth == 0) {
        if (title.contains('040')) {
          titleColor = QRHColors.danger;
        } else if (title.contains('050')) {
          titleColor = QRHColors.caution;
        } else if (title.contains('030')) {
          titleColor = QRHColors.success;
        } else if (title.contains('041')) {
          titleColor = QRHColors.info;
        }
      }

      final childrenWidgets = filteredChildren
          .map(
            (e) => PmNodeWidget(
              node: e,
              depth: depth + 1,
              isEditing: isEditing,
              onDelete: onDelete,
              languageFilter: languageFilter,
            ),
          )
          .toList();

      return Padding(
        padding: EdgeInsets.only(top: depth == 0 ? 16.0 : 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 16.0 * depth, bottom: 8.0),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: depth == 0 ? 22 : 18,
                  fontWeight: FontWeight.bold,
                  color: depth == 0 ? titleColor : QRHColors.textSecondary,
                ),
              ),
            ),
            ...childrenWidgets,
          ],
        ),
      );
    } else if (node.name.local == 'dmRef') {
      if (languageFilter != null) {
        final langNode = node.findAllElements('language').firstOrNull;
        if (langNode != null) {
          final tag = '${langNode.getAttribute('languageIsoCode')}-${langNode.getAttribute('countryIsoCode')}';
          if (tag != languageFilter) return const SizedBox.shrink();
        }
      }
      return PmDmRefWidget(dmRef: node, depth: depth, isEditing: isEditing, onDelete: () => onDelete?.call(node));
    }

    // Fallback: render an error if node is unknown
    return Padding(
      padding: EdgeInsets.only(left: 16.0 * depth, top: 4.0),
      child: Text('Unknown node: ${node.name.local}', style: const TextStyle(color: Colors.red)),
    );
  }
}
