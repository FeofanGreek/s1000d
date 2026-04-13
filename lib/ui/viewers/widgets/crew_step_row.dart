import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../styles.dart';
import '../models/crew_models.dart';
import '../../../controllers/crew_viewer_controller.dart';
import 'dashed_line.dart';

class CrewStepRow extends StatelessWidget {
  final CrewStep step;

  const CrewStepRow({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CrewViewerController>();
    final isEditMode = controller.isEditMode;
    final isChecked = step.stateIndex < controller.checkboxStates.length 
        ? controller.checkboxStates[step.stateIndex] 
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
              if (step.challenge.isNotEmpty || isEditMode)
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxTextWidth),
                  child: isEditMode
                      ? TextFormField(
                          initialValue: step.challenge,
                          style: const TextStyle(fontSize: 16, color: QRHColors.info, fontWeight: FontWeight.bold),
                          maxLines: null,
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.all(8),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (val) => controller.updateStepChallenge(step, val),
                        )
                      : Text(
                          step.challenge,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: textColor,
                            decoration: isChecked ? TextDecoration.lineThrough : null,
                          ),
                        ),
                ),

              // --- Chips (Типы экипажа) ---
              if (step.crewMembers.isNotEmpty || isEditMode) ...[
                const SizedBox(width: 8),
                Wrap(
                  spacing: 4.0,
                  children: [
                    ...step.crewMembers.map(
                      (cm) => isEditMode
                          ? Chip(
                              label: Text(
                                cm.toUpperCase(),
                                style: const TextStyle(fontSize: 10, color: QRHColors.textPrimary),
                              ),
                              onDeleted: () => controller.removeCrewMember(step, cm),
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
                        onTap: () => controller.showAddCrewMemberDialog(context, step),
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

              // --- Divider (Точечная линия) ---
              if (step.challenge.isNotEmpty && step.response.isNotEmpty && !isEditMode)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: DashedLine(color: isChecked ? QRHColors.dividerColor : QRHColors.textTertiary),
                  ),
                ),

              if (isEditMode) const Expanded(child: SizedBox(width: 16)),

              // --- Простой текст (если нет challenge/response) ---
              if (step.simpleText != null)
                Expanded(
                  child: Text(
                    step.simpleText!,
                    style: TextStyle(
                      fontSize: 16,
                      color: textColor,
                      decoration: isChecked ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),

              // --- Response (Ответ) ---
              if (step.response.isNotEmpty || isEditMode)
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxTextWidth),
                  child: isEditMode
                      ? TextFormField(
                          initialValue: step.response,
                          style: const TextStyle(fontSize: 16, color: QRHColors.info),
                          maxLines: null,
                          textAlign: TextAlign.right,
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.all(8),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (val) => controller.updateStepResponse(step, val),
                        )
                      : Text(
                          step.response,
                          style: TextStyle(
                            fontSize: 16,
                            color: secondaryTextColor,
                            decoration: isChecked ? TextDecoration.lineThrough : null,
                          ),
                          textAlign: TextAlign.right,
                        ),
                ),

              const SizedBox(width: 8),

              // --- Checkbox (Отметка) ---
              if (!isEditMode)
                Checkbox(
                  value: isChecked,
                  onChanged: (val) => controller.setCheckbox(step.stateIndex, val ?? false),
                  activeColor: QRHColors.success,
                  checkColor: QRHColors.primaryBg,
                  side: const BorderSide(color: QRHColors.textTertiary, width: 2),
                )
              else
                IconButton(
                  icon: const Icon(Icons.delete, color: QRHColors.danger),
                  onPressed: () => controller.deleteItem(step),
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
