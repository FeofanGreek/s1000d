import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../styles.dart';
import '../models/crew_models.dart';
import '../../../controllers/crew_viewer_controller.dart';
import 'pm_dm_ref_widget.dart';

class CrewReferenceRow extends StatefulWidget {
  final CrewStep step;

  const CrewReferenceRow({super.key, required this.step});

  @override
  State<CrewReferenceRow> createState() => _CrewReferenceRowState();
}

class _CrewReferenceRowState extends State<CrewReferenceRow> {
  late TextEditingController _referenceCtrl;

  @override
  void initState() {
    super.initState();
    _referenceCtrl = TextEditingController(text: widget.step.referenceText ?? '');
  }

  @override
  void didUpdateWidget(covariant CrewReferenceRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step.referenceText != widget.step.referenceText && 
        _referenceCtrl.text != (widget.step.referenceText ?? '')) {
      _referenceCtrl.text = widget.step.referenceText ?? '';
    }
  }

  @override
  void dispose() {
    _referenceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CrewViewerController>();
    final isEditMode = controller.isEditMode;
    final textColor = QRHColors.textPrimary; // Ссылка не имеет чекбокса

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Основной контент ссылки
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isEditMode)
                  TextFormField(
                    controller: _referenceCtrl,
                    style: const TextStyle(fontSize: 16, color: QRHColors.info, height: 1.2),
                    maxLines: null,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) => controller.updateReferenceText(widget.step, val),
                  )
                else
                  Text(
                    widget.step.referenceText ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      color: textColor,
                    ),
                  ),
                const SizedBox(height: 4),
                if (widget.step.dmRefNode != null)
                  PmDmRefWidget(dmRef: widget.step.dmRefNode!, depth: 0),
              ],
            ),
          ),

          // Кнопка удаления в режиме редактирования (чекбокса нет)
          if (isEditMode)
            IconButton(
              icon: const Icon(Icons.delete, color: QRHColors.danger),
              onPressed: () => controller.deleteItem(widget.step),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}
