import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../styles.dart';
import '../models/crew_models.dart';
import '../../../controllers/crew_viewer_controller.dart';

class CrewDescriptionRow extends StatefulWidget {
  final CrewDescription item;

  const CrewDescriptionRow({super.key, required this.item});

  @override
  State<CrewDescriptionRow> createState() => _CrewDescriptionRowState();
}

class _CrewDescriptionRowState extends State<CrewDescriptionRow> {
  late TextEditingController _titleCtrl;
  late TextEditingController _textCtrl;
  late FocusNode _textFocusNode;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.item.title);
    _textCtrl = TextEditingController(text: widget.item.text);
    _textFocusNode = FocusNode(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.tab) {
          final text = _textCtrl.text;
          final selection = _textCtrl.selection;

          if (selection.isValid) {
            // Вставляем символ табуляции на место выделения (или курсора)
            final newText = text.replaceRange(selection.start, selection.end, '\t');
            _textCtrl.value = TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(offset: selection.start + 1),
            );
            // Программное изменение текста не триггерит onChanged, поэтому вызываем сохранение явно
            if (mounted) {
              context.read<CrewViewerController>().updateDescriptionText(widget.item, newText);
            }
          }
          return KeyEventResult.handled; // Говорим Flutter, что мы обработали Tab
        }
        return KeyEventResult.ignored;
      },
    );
  }

  @override
  void didUpdateWidget(covariant CrewDescriptionRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.title != widget.item.title &&
        _titleCtrl.text != widget.item.title) {
      _titleCtrl.text = widget.item.title;
    }
    if (oldWidget.item.text != widget.item.text &&
        _textCtrl.text != widget.item.text) {
      _textCtrl.text = widget.item.text;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _textCtrl.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CrewViewerController>();
    final isEditMode = controller.isEditMode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: QRHColors.secondaryBg,
          border: Border.all(color: QRHColors.borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isEditMode)
                    TextFormField(
                      controller: _titleCtrl,
                      style: const TextStyle(
                        fontSize: 18,
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
                        hintText: 'Заголовок',
                      ),
                      onChanged: (val) =>
                          controller.updateDescriptionTitle(widget.item, val),
                    )
                  else
                    Text(
                      widget.item.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: QRHColors.textPrimary,
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (isEditMode)
                    TextFormField(
                      controller: _textCtrl,
                      focusNode: _textFocusNode,
                      style: const TextStyle(
                        fontSize: 16,
                        color: QRHColors.textPrimary,
                      ),
                      maxLines: null, // Поле будет расширяться
                      keyboardType: TextInputType.multiline,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(),
                        hintText: 'Текст описания',
                      ),
                      onChanged: (val) =>
                          controller.updateDescriptionText(widget.item, val),
                    )
                  else
                    Text(
                      widget.item.text,
                      style: const TextStyle(
                        fontSize: 16,
                        color: QRHColors.textPrimary,
                      ),
                    ),
                ],
              ),
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
      ),
    );
  }
}
