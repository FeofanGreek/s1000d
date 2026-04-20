import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../styles.dart';
import '../models/crew_models.dart';
import '../../../controllers/crew_viewer_controller.dart';

class CrewConditionRow extends StatefulWidget {
  final CrewCondition item;

  const CrewConditionRow({super.key, required this.item});

  @override
  State<CrewConditionRow> createState() => _CrewConditionRowState();
}

class _CrewConditionRowState extends State<CrewConditionRow> {
  late TextEditingController _titleCtrl;
  late TextEditingController _textCtrl;
  final Map<CrewCaseItem, TextEditingController> _condCtrls = {};
  final Map<CrewCaseItem, TextEditingController> _stepCtrls = {};

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.item.title);
    _textCtrl = TextEditingController(text: widget.item.text);
    _initCaseCtrls();
  }

  void _initCaseCtrls() {
    for (var c in widget.item.cases) {
      if (!_condCtrls.containsKey(c)) {
        _condCtrls[c] = TextEditingController(text: c.conditionText);
      }
      if (!_stepCtrls.containsKey(c)) {
        _stepCtrls[c] = TextEditingController(text: c.stepText);
      }
    }
  }

  @override
  void didUpdateWidget(covariant CrewConditionRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.title != widget.item.title &&
        _titleCtrl.text != widget.item.title) {
      _titleCtrl.text = widget.item.title;
    }
    if (oldWidget.item.text != widget.item.text &&
        _textCtrl.text != widget.item.text) {
      _textCtrl.text = widget.item.text;
    }
    _initCaseCtrls();
    for (var c in widget.item.cases) {
      if (_condCtrls[c]?.text != c.conditionText) {
        _condCtrls[c]?.text = c.conditionText;
      }
      if (_stepCtrls[c]?.text != c.stepText) {
        _stepCtrls[c]?.text = c.stepText;
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _textCtrl.dispose();
    for (var ctrl in _condCtrls.values) {
      ctrl.dispose();
    }
    for (var ctrl in _stepCtrls.values) {
      ctrl.dispose();
    }
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
          border: Border.all(color: QRHColors.info),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                            hintText: 'Заголовок условия',
                          ),
                          onChanged: (val) =>
                              controller.updateConditionTitle(widget.item, val),
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
                          style: const TextStyle(
                            fontSize: 16,
                            color: QRHColors.textPrimary,
                          ),
                          maxLines: null,
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
                              controller.updateConditionText(widget.item, val),
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
            const SizedBox(height: 16),
            ...widget.item.cases.map((caseItem) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0, left: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: QRHColors.primaryBg,
                    border: Border.all(color: QRHColors.borderColor),
                    borderRadius: BorderRadius.circular(4),
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
                                controller: _condCtrls[caseItem],
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: QRHColors.info,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(),
                                  hintText: 'Условие (IF)',
                                ),
                                onChanged: (val) =>
                                    controller.updateCaseCond(caseItem, val),
                              )
                            else
                              Text(
                                caseItem.conditionText,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: QRHColors.info,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            const SizedBox(height: 4),
                            if (isEditMode)
                              TextFormField(
                                controller: _stepCtrls[caseItem],
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: QRHColors.textPrimary,
                                ),
                                maxLines: null,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(),
                                  hintText: 'Действие (THEN)',
                                ),
                                onChanged: (val) => controller
                                    .updateCaseStepText(caseItem, val),
                              )
                            else
                              Text(
                                caseItem.stepText,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: QRHColors.textPrimary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (isEditMode)
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: QRHColors.danger,
                          ),
                          onPressed: () => controller.removeConditionCase(
                            widget.item,
                            caseItem,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                ),
              );
            }),
            if (isEditMode)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => controller.addConditionCase(widget.item),
                  icon: const Icon(Icons.add, color: QRHColors.success),
                  label: const Text(
                    'Добавить условие',
                    style: TextStyle(color: QRHColors.success),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
