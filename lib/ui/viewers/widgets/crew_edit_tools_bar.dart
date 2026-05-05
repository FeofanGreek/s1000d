import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../styles.dart';
import '../../../../controllers/crew_viewer_controller.dart';

class CrewEditToolsBar extends StatelessWidget {
  final VoidCallback onItemAdded;

  const CrewEditToolsBar({super.key, required this.onItemAdded});

  Widget _buildToolButton({
    required VoidCallback onPressed,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ActionChip(
        avatar: Icon(icon, color: color, size: 18),
        label: Text(label),
        backgroundColor: QRHColors.primaryBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: QRHColors.borderColor),
        ),
        onPressed: onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CrewViewerController>();

    return SafeArea(
      child: Container(
        height: 60,
        decoration: const BoxDecoration(
          color: QRHColors.primaryBg,
          border: Border(
            top: BorderSide(color: QRHColors.borderColor),
          ),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildToolButton(
                onPressed: () => controller.addStep(onItemAdded),
                color: QRHColors.success,
                icon: Icons.add,
                label: 'Шаг',
              ),
              _buildToolButton(
                onPressed: () => controller.addCondition(onItemAdded),
                color: Colors.purple,
                icon: Icons.alt_route,
                label: 'IF ELSE',
              ),
              _buildToolButton(
                onPressed: () => controller.addDescription(onItemAdded),
                color: QRHColors.info,
                icon: Icons.article,
                label: 'Описание',
              ),
              _buildToolButton(
                onPressed: () => controller.addReference(context, onItemAdded),
                color: QRHColors.warning,
                icon: Icons.link,
                label: 'Ссылка',
              ),
              _buildToolButton(
                onPressed: () => controller.addFigure(context, onItemAdded),
                color: Colors.blueAccent,
                icon: Icons.image,
                label: 'Изображение',
              ),
              _buildToolButton(
                onPressed: () => controller.addAttention('warning', onItemAdded),
                color: QRHColors.danger,
                icon: Icons.warning,
                label: 'Внимание',
              ),
              _buildToolButton(
                onPressed: () => controller.addAttention('caution', onItemAdded),
                color: QRHColors.warning,
                icon: Icons.pan_tool,
                label: 'Осторожно',
              ),
              _buildToolButton(
                onPressed: () => controller.addAttention('note', onItemAdded),
                color: QRHColors.info,
                icon: Icons.info_outline,
                label: 'Примечание',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
