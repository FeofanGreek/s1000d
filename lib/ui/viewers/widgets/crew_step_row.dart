import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../styles.dart';
import '../models/crew_models.dart';
import '../../../controllers/crew_viewer_controller.dart';
import 'dashed_line.dart';

class CrewStepRow extends StatefulWidget {
  final CrewStep step;

  const CrewStepRow({super.key, required this.step});

  @override
  State<CrewStepRow> createState() => _CrewStepRowState();
}

class _CrewStepRowState extends State<CrewStepRow> {
  late TextEditingController _challengeCtrl;
  late TextEditingController _responseCtrl;

  @override
  void initState() {
    super.initState();
    _challengeCtrl = TextEditingController(text: widget.step.challenge);
    _responseCtrl = TextEditingController(text: widget.step.response);
  }

  @override
  void didUpdateWidget(covariant CrewStepRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step.challenge != widget.step.challenge && _challengeCtrl.text != widget.step.challenge) {
      _challengeCtrl.text = widget.step.challenge;
    }
    if (oldWidget.step.response != widget.step.response && _responseCtrl.text != widget.step.response) {
      _responseCtrl.text = widget.step.response;
    }
  }

  @override
  void dispose() {
    _challengeCtrl.dispose();
    _responseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CrewViewerController>();
    final isEditMode = controller.isEditMode;
    final isChecked = widget.step.stateIndex < controller.checkboxStates.length
        ? controller.checkboxStates[widget.step.stateIndex]
        : false;
    final textColor = isChecked ? QRHColors.textTertiary : QRHColors.textPrimary;
    final secondaryTextColor = isChecked ? QRHColors.textTertiary : QRHColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxTextWidth = constraints.maxWidth * 0.4;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- Challenge (Вызов) ---
              if (widget.step.challenge.isNotEmpty || isEditMode)
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxTextWidth),
                  child: isEditMode
                      ? TextFormField(
                          controller: _challengeCtrl,
                          style: const TextStyle(fontSize: 16, color: QRHColors.info, fontWeight: FontWeight.bold, height: 1.2),
                          maxLines: null,
                          textAlignVertical: TextAlignVertical.center,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.clear, color: QRHColors.textSecondary),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              onPressed: () {
                                _challengeCtrl.clear();
                                controller.updateStepChallenge(widget.step, '');
                              },
                            ),
                          ),
                          onChanged: (val) => controller.updateStepChallenge(widget.step, val),
                        )
                      : Text(
                          widget.step.challenge,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: textColor,
                            decoration: isChecked ? TextDecoration.lineThrough : null,
                          ),
                        ),
                ),

              // --- Divider (Точечная линия) ---
              if (widget.step.challenge.isNotEmpty && widget.step.response.isNotEmpty && !isEditMode)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: DashedLine(color: isChecked ? QRHColors.dividerColor : QRHColors.textTertiary),
                  ),
                ),

              if (isEditMode) const Expanded(child: SizedBox(width: 16)),

              // --- Простой текст (если нет challenge/response) ---
              if (widget.step.simpleText != null)
                Expanded(
                  child: Text(
                    widget.step.simpleText!,
                    style: TextStyle(
                      fontSize: 16,
                      color: textColor,
                      decoration: isChecked ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),

              // --- Response (Ответ) ---
              if (widget.step.response.isNotEmpty || isEditMode)
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxTextWidth),
                  child: isEditMode
                      ? TextFormField(
                          controller: _responseCtrl,
                          style: const TextStyle(fontSize: 16, color: QRHColors.info, height: 1.2),
                          maxLines: null,
                          textAlign: TextAlign.right,
                          textAlignVertical: TextAlignVertical.center,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.clear, color: QRHColors.textSecondary),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              onPressed: () {
                                _responseCtrl.clear();
                                controller.updateStepResponse(widget.step, '');
                              },
                            ),
                          ),
                          onChanged: (val) => controller.updateStepResponse(widget.step, val),
                        )
                      : Text(
                          widget.step.response,
                          style: TextStyle(
                            fontSize: 16,
                            color: secondaryTextColor,
                            decoration: isChecked ? TextDecoration.lineThrough : null,
                          ),
                          textAlign: TextAlign.right,
                        ),
                ),

              const SizedBox(width: 8),
              // --- Chips (Типы экипажа) ---
              if (widget.step.crewMembers.isNotEmpty || isEditMode) ...[
                const SizedBox(width: 8),
                Wrap(
                  spacing: 4.0,
                  children: [
                    ...widget.step.crewMembers.map(
                      (cm) => isEditMode
                          ? Chip(
                              label: Text(
                                cm.toUpperCase(),
                                style: const TextStyle(fontSize: 10, color: QRHColors.textPrimary),
                              ),
                              onDeleted: () => controller.removeCrewMember(widget.step, cm),
                              deleteIcon: const Icon(Icons.close, size: 14),
                              backgroundColor: QRHColors.accentBg,
                              padding: EdgeInsets.zero,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            )
                          : Container(
                              margin: const EdgeInsets.only(right: 4.0),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isChecked ? QRHColors.accentBg : QRHColors.info.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isChecked ? QRHColors.dividerColor : QRHColors.info.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Text(
                                cm.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isChecked ? QRHColors.textTertiary : QRHColors.info,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
                    if (isEditMode)
                      InkWell(
                        onTap: () => controller.showAddCrewMemberDialog(context, widget.step),
                        child: Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            border: Border.all(color: QRHColors.info),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '+',
                            style: TextStyle(color: QRHColors.info, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              // --- Checkbox (Отметка) ---
              if (!isEditMode)
                Checkbox(
                  value: isChecked,
                  onChanged: (val) => controller.setCheckbox(widget.step.stateIndex, val ?? false),
                  activeColor: QRHColors.success,
                  checkColor: QRHColors.primaryBg,
                  side: const BorderSide(color: QRHColors.textTertiary, width: 2),
                )
              else
                IconButton(
                  icon: const Icon(Icons.delete, color: QRHColors.danger),
                  onPressed: () => controller.deleteItem(widget.step),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          );
        },
      ),
    );
  }
}
