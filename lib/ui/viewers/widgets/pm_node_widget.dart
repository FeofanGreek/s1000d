import 'package:flutter/material.dart';
import 'package:xml/xml.dart';
import '../../../styles.dart';
import 'pm_dm_ref_widget.dart';

class PmNodeWidget extends StatelessWidget {
  final XmlElement node;
  final int depth;

  const PmNodeWidget({super.key, required this.node, required this.depth});

  @override
  Widget build(BuildContext context) {
    if (node.name.local == 'pmEntry') {
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

      // Выбираем дочерние элементы, исключая сам pmEntryTitle
      final children = node.children
          .whereType<XmlElement>()
          .where((e) => e.name.local != 'pmEntryTitle')
          .map((e) => PmNodeWidget(node: e, depth: depth + 1))
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
            ...children,
          ],
        ),
      );
    } else if (node.name.local == 'dmRef') {
      return PmDmRefWidget(dmRef: node, depth: depth);
    }

    // Fallback: render an error if node is unknown
    return Padding(
      padding: EdgeInsets.only(left: 16.0 * depth, top: 4.0),
      child: Text('Unknown node: ${node.name.local}', style: const TextStyle(color: Colors.red)),
    );
  }
}