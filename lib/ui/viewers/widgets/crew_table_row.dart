import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/crew_viewer_controller.dart';
import '../../../styles.dart';
import '../models/crew_models.dart';

class CrewTableRowWidget extends StatelessWidget {
  final CrewTable item;

  const CrewTableRowWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CrewViewerController>();
    final isEditMode = controller.isEditMode;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isEditMode)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: item.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: QRHColors.textPrimary),
                      decoration: const InputDecoration(labelText: 'Заголовок таблицы', isDense: true),
                      onChanged: (val) => controller.updateTableTitle(item, val),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: QRHColors.danger, size: 20),
                    onPressed: () => controller.deleteItem(item),
                    tooltip: 'Удалить таблицу',
                  ),
                ],
              ),
            )
          else if (item.title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                item.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: QRHColors.info),
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(QRHColors.accentBg),
              border: TableBorder.all(color: QRHColors.borderColor),
              columns: item.header.asMap().entries.map((e) {
                final index = e.key;
                final value = e.value;
                return DataColumn(
                  label: isEditMode
                      ? SizedBox(
                          width: 100,
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: value,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                                  onChanged: (val) => controller.updateTableCell(item, -1, index, val, isHeader: true),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: QRHColors.danger, size: 14),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => controller.removeTableColumn(item, index),
                              ),
                            ],
                          ),
                        )
                      : Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
                );
              }).toList(),
              rows: item.rows.asMap().entries.map((rowEntry) {
                final rowIndex = rowEntry.key;
                final rowData = rowEntry.value;
                return DataRow(
                  cells: rowData.asMap().entries.map((colEntry) {
                    final colIndex = colEntry.key;
                    final cellValue = colEntry.value;
                    return DataCell(
                      isEditMode
                          ? TextFormField(
                              initialValue: cellValue,
                              style: const TextStyle(fontSize: 13),
                              decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                              onChanged: (val) => controller.updateTableCell(item, rowIndex, colIndex, val),
                            )
                          : Text(cellValue),
                    );
                  }).toList(),
                  onLongPress: isEditMode ? () => controller.removeTableRow(item, rowIndex) : null,
                );
              }).toList(),
            ),
          ),
          if (isEditMode)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => controller.addTableRow(item),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Добавить строку'),
                  ),
                  const SizedBox(width: 16),
                  TextButton.icon(
                    onPressed: () => controller.addTableColumn(item),
                    icon: const Icon(Icons.view_column, size: 16),
                    label: const Text('Добавить столбец'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
