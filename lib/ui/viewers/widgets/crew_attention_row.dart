import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../styles.dart';
import '../models/crew_models.dart';
import '../../../controllers/crew_viewer_controller.dart';

class CrewAttentionRow extends StatelessWidget {
  final CrewAttention item;

  const CrewAttentionRow({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CrewViewerController>();
    final isEditMode = controller.isEditMode;

    Color color;
    String label;
    IconData icon;
    switch (item.type) {
      case 'warning':
        color = QRHColors.danger;
        label = 'ВНИМАНИЕ';
        icon = Icons.warning_amber_rounded;
        break;
      case 'caution':
        color = QRHColors.warning;
        label = 'ОСТОРОЖНО';
        icon = Icons.pan_tool;
        break;
      default:
        color = QRHColors.info;
        label = 'ПРИМЕЧАНИЕ';
        icon = Icons.info_outline;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: color, width: 4)),
          color: color.withValues(alpha: 0.1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  if (isEditMode)
                    TextFormField(
                      initialValue: item.text,
                      style: const TextStyle(color: QRHColors.textPrimary),
                      maxLines: null,
                      decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                      onChanged: (val) => controller.updateAttentionText(item, val),
                    )
                  else
                    Text(item.text, style: const TextStyle(color: QRHColors.textPrimary)),
                ],
              ),
            ),
            if (isEditMode)
              IconButton(
                icon: const Icon(Icons.delete, color: QRHColors.danger),
                onPressed: () => controller.deleteItem(item),
              ),
          ],
        ),
      ),
    );
  }
}
