import 'dart:io' show Directory, File, FileSystemEntity;
import 'dart:convert' show utf8;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xml/xml.dart';
import '../../../controllers/app_controller.dart';
import '../../../styles.dart';
import '../../xml_viewer_screen.dart';

class PmDmRefWidget extends StatelessWidget {
  final XmlElement dmRef;
  final int depth;

  const PmDmRefWidget({super.key, required this.dmRef, required this.depth});

  @override
  Widget build(BuildContext context) {
    // В S1000D структура такая: dmRef -> dmRefIdent -> dmCode
    final dmRefIdent = dmRef.findElements('dmRefIdent').firstOrNull;
    final dmCode = dmRefIdent?.findElements('dmCode').firstOrNull;

    if (dmCode == null) {
      // Ищем глобально на всякий случай, если структура немного другая
      final fallbackDmCode = dmRef.findAllElements('dmCode').firstOrNull;
      if (fallbackDmCode == null) {
        return Padding(
          padding: EdgeInsets.only(left: 16.0 * depth),
          child: const Text('Ошибка: тег <dmCode> не найден внутри <dmRef>', style: TextStyle(color: Colors.red)),
        );
      }
    }

    final prefix = _buildDmcPrefix(dmRef);

    // В S1000D структура: dmRef -> dmRefAddressItems -> dmTitle -> techName / infoName
    final dmRefAddressItems = dmRef.findElements('dmRefAddressItems').firstOrNull;
    final dmTitle = dmRefAddressItems?.findElements('dmTitle').firstOrNull;

    final techName =
        ''; //(dmTitle?.findElements('techName').firstOrNull ?? dmRef.findAllElements('techName').firstOrNull)?.innerText;
    final infoName =
        (dmTitle?.findElements('infoName').firstOrNull ?? dmRef.findAllElements('infoName').firstOrNull)?.innerText;

    String title = [techName, infoName].where((e) => e != null && e.isNotEmpty).join(' - ');
    if (title.isEmpty) title = prefix;

    return Padding(
      padding: EdgeInsets.only(left: 16.0 * depth, top: 4.0, bottom: 8.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openDm(context, prefix, title),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2.0),
                  child: Icon(Icons.description, color: QRHColors.info, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(color: QRHColors.info, fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      if (title != prefix)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(prefix, style: const TextStyle(color: QRHColors.textTertiary, fontSize: 12)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Формируем стандартный префикс файла DMC-
  String _buildDmcPrefix(XmlElement dmRef) {
    final dmRefIdent = dmRef.findElements('dmRefIdent').firstOrNull;
    final dmCode = dmRefIdent?.findElements('dmCode').firstOrNull ?? dmRef.findAllElements('dmCode').firstOrNull;
    if (dmCode == null) return '';

    final model = dmCode.getAttribute('modelIdentCode') ?? '';
    final sdc = dmCode.getAttribute('systemDiffCode') ?? '';
    final sc = dmCode.getAttribute('systemCode') ?? '';
    final ssc = dmCode.getAttribute('subSystemCode') ?? '';
    final sssc = dmCode.getAttribute('subSubSystemCode') ?? '';
    final ac = dmCode.getAttribute('assyCode') ?? '';
    final dc = dmCode.getAttribute('disassyCode') ?? '';
    final dcv = dmCode.getAttribute('disassyCodeVariant') ?? '';
    final ic = dmCode.getAttribute('infoCode') ?? '';
    final icv = dmCode.getAttribute('infoCodeVariant') ?? '';
    final ilc = dmCode.getAttribute('itemLocationCode') ?? '';

    final issueInfo =
        dmRefIdent?.findElements('issueInfo').firstOrNull ?? dmRef.findAllElements('issueInfo').firstOrNull;
    final issueNumber = issueInfo?.getAttribute('issueNumber') ?? '001';
    final inWork = issueInfo?.getAttribute('inWork') ?? '00';

    final language = dmRefIdent?.findElements('language').firstOrNull ?? dmRef.findAllElements('language').firstOrNull;
    final langIso = language?.getAttribute('languageIsoCode') ?? 'ru';
    final countryIso = language?.getAttribute('countryIsoCode') ?? 'RU';

    return 'DMC-$model-$sdc-$sc-$ssc$sssc-$ac-$dc$dcv-$ic$icv-${ilc}_$issueNumber-${inWork}_$langIso-$countryIso.XML';
  }

  // Универсальное открытие файла (Web + Desktop)
  Future<void> _openDm(BuildContext context, String prefix, String fileTitle) async {
    // 1. Для веба мы всегда просим выбрать файл (папки не поддерживаются)
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Выберите целевой файл $prefix... вручную.'),
          backgroundColor: QRHColors.warning,
          duration: const Duration(seconds: 3),
        ),
      );

      final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['xml'], withData: true);

      if (result != null && result.files.isNotEmpty) {
        final platformFile = result.files.firstWhere(
          (file) =>
              file.name.toUpperCase() == prefix.toUpperCase() ||
              (file.name.toUpperCase().startsWith(
                    prefix.toUpperCase().replaceAll(RegExp(r'_[0-9]{3}-[0-9]{2}_[A-Z]{2}-[A-Z]{2}\.XML$'), ''),
                  ) &&
                  file.name.toLowerCase().endsWith('.xml')),
          orElse: () => result.files.first,
        );

        final content = utf8.decode(platformFile.bytes!);
        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => XmlViewerScreen(
                fileTitle: fileTitle,
                xmlContent: content,
                fileName: platformFile.name,
                filePath: null,
              ),
            ),
          );
        }
      }
      return;
    }

    // 2. Для macOS/Desktop: запрашиваем папку, чтобы получить права Sandbox
    // final String? selectedDirectory = await FilePicker.getDirectoryPath(
    //   dialogTitle: 'Выберите папку с файлами проекта (для предоставления доступа)',
    // );
    final controller = context.read<AppController>();
    String? selectedDirectory = controller.workDir?.path;

    if (selectedDirectory == null) return; // Пользователь отменил

    final dir = Directory(selectedDirectory);
    File? targetFile;

    try {
      final List<FileSystemEntity> entities = await dir.list().toList();

      for (var entity in entities) {
        if (entity is File) {
          final filename = entity.uri.pathSegments.last;
          if (filename.toUpperCase() == prefix.toUpperCase() ||
              (filename.toUpperCase().startsWith(
                    prefix.toUpperCase().replaceAll(RegExp(r'_[0-9]{3}-[0-9]{2}_[A-Z]{2}-[A-Z]{2}\.XML$'), ''),
                  ) &&
                  filename.toLowerCase().endsWith('.xml'))) {
            targetFile = entity;
            break;
          }
        }
      }
    } catch (e) {
      debugPrint('Ошибка доступа: Скорее всего, нет прав на чтение папки. $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка доступа: $e'), backgroundColor: QRHColors.danger));
      }
      return;
    }

    if (!context.mounted) return;

    final resolvedFile = targetFile;
    if (resolvedFile != null) {
      final content = await resolvedFile.readAsString();
      if (!context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => XmlViewerScreen(
            xmlContent: content,
            fileName: resolvedFile.uri.pathSegments.last,
            filePath: resolvedFile.path,
            fileTitle: fileTitle,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Файл $prefix... не найден в выбранной папке\n${dir.path}'),
          backgroundColor: QRHColors.danger,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}
