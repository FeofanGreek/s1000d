import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../styles.dart';
import '../models/crew_models.dart';
import '../../../controllers/crew_viewer_controller.dart';
import '../../../controllers/app_controller.dart';

class CrewFigureRow extends StatefulWidget {
  final CrewFigure item;

  const CrewFigureRow({super.key, required this.item});

  @override
  State<CrewFigureRow> createState() => _CrewFigureRowState();
}

class _CrewFigureRowState extends State<CrewFigureRow> {
  late TextEditingController _titleCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.item.title);
  }

  @override
  void didUpdateWidget(covariant CrewFigureRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.title != widget.item.title &&
        _titleCtrl.text != widget.item.title) {
      _titleCtrl.text = widget.item.title;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CrewViewerController>();
    final appCtrl = context.watch<AppController>();
    final isEditMode = controller.isEditMode;

    String imagePath = '';
    if (appCtrl.workDir != null) {
      imagePath = '${appCtrl.workDir!.path}/${widget.item.infoEntityIdent}';
      if (!imagePath.toUpperCase().endsWith('.JPG') &&
          !imagePath.toUpperCase().endsWith('.PNG')) {
        // Fallback to checking extensions if missing in ICN
        final dir = appCtrl.workDir!;
        final files = dir.listSync().whereType<File>();
        final match = files
            .where((f) => f.path.contains(widget.item.infoEntityIdent))
            .firstOrNull;
        if (match != null) {
          imagePath = match.path;
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: QRHColors.secondaryBg,
          border: Border.all(color: QRHColors.borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: isEditMode
                      ? TextFormField(
                          controller: _titleCtrl,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: QRHColors.textPrimary,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(),
                            hintText: 'Подпись к изображению',
                          ),
                          onChanged: (val) =>
                              controller.updateFigureTitle(widget.item, val),
                        )
                      : widget.item.title.isNotEmpty
                      ? Text(
                          widget.item.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: QRHColors.textPrimary,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                if (isEditMode) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete, color: QRHColors.danger),
                    onPressed: () => controller.deleteItem(widget.item),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: imagePath.isNotEmpty && File(imagePath).existsSync()
                  ? Image.file(
                      File(imagePath),
                      fit: BoxFit.contain,
                      errorBuilder: (ctx, err, stack) =>
                          _buildErrorPlaceholder(),
                    )
                  : _buildErrorPlaceholder(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      width: double.infinity,
      height: 150,
      color: Colors.grey.withValues(alpha: 0.1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.broken_image, size: 48, color: Colors.grey),
          const SizedBox(height: 8),
          Text(
            'Изображение не найдено\n${widget.item.infoEntityIdent}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
