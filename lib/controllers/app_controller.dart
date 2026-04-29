import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:xml/xml.dart';
import '../styles.dart';
import '../utils/s1000d_ident_and_status.dart';
import '../utils/s1000d_pm_builder.dart';
import '../utils/s1000d_md_parser.dart';
import '../ui/widgets/dialog_field.dart';
import '../ui/widgets/new_file_dialog.dart';
import '../ui/widgets/project_settings_form.dart';

class AppController with ChangeNotifier {
  Directory? workDir;

  // 1. КОНСТАНТЫ ПРОЕКТА (Переиспользуемые параметры)
  String modelIdentCode = 'MI171A3';
  String languageIsoCode = 'ru';
  String languageCountryIsoCode = 'RU';
  String techName = 'Ми-171А3';

  String partnerCode = 'GAZPR';
  String partnerName = 'ООО Авиапредприятие «Газпром авиа»';

  String dataDistribution = 'Документ предназначен для использования персоналом ООО Авиапредприятие «Газпром авиа».';
  String copyrightPara = 'Copyright (C) 2025 ООО Авиапредприятие «Газпром авиа»';

  // 2. ПАРАМЕТРЫ BREX (Обычно одни на весь проект)
  String brexInfoCode = '022';
  String brexLocation = 'D';

  Future<void> loadProject(Directory dir) async {
    workDir = dir;
    final file = File('${dir.path}/project.json');
    if (await file.exists()) {
      final jsonString = await file.readAsString();
      try {
        final data = jsonDecode(jsonString) as Map<String, dynamic>;

        modelIdentCode = data['modelIdentCode'] ?? modelIdentCode;
        languageIsoCode = data['languageIsoCode'] ?? languageIsoCode;
        languageCountryIsoCode = data['languageCountryIsoCode'] ?? languageCountryIsoCode;
        techName = data['techName'] ?? techName;
        partnerCode = data['partnerCode'] ?? partnerCode;
        partnerName = data['partnerName'] ?? partnerName;
        dataDistribution = data['dataDistribution'] ?? dataDistribution;
        copyrightPara = data['copyrightPara'] ?? copyrightPara;
        brexInfoCode = data['brexInfoCode'] ?? brexInfoCode;
        brexLocation = data['brexLocation'] ?? brexLocation;
      } catch (e) {
        debugPrint('Ошибка парсинга project.json: $e');
      }
    }
    notifyListeners();
  }

  Future<void> saveProjectSettings() async {
    if (workDir == null) return;

    final data = {
      'modelIdentCode': modelIdentCode,
      'languageIsoCode': languageIsoCode,
      'languageCountryIsoCode': languageCountryIsoCode,
      'techName': techName,
      'partnerCode': partnerCode,
      'partnerName': partnerName,
      'dataDistribution': dataDistribution,
      'copyrightPara': copyrightPara,
      'brexInfoCode': brexInfoCode,
      'brexLocation': brexLocation,
    };

    final file = File('${workDir!.path}/project.json');
    await file.writeAsString(jsonEncode(data));
    notifyListeners();
  }

  Future<void> applyProjectSettingsToFiles() async {
    if (workDir == null) return;

    try {
      final entities = await workDir!.list().toList();
      final xmlFiles = entities.whereType<File>().where((f) => f.path.toLowerCase().endsWith('.xml'));

      for (var file in xmlFiles) {
        try {
          final content = await file.readAsString();
          final document = XmlDocument.parse(content);
          bool changed = false;

          // Обновляем language
          final languageElements = document.findAllElements('language');
          if (languageElements.isNotEmpty) {
            final el = languageElements.first;
            if (el.getAttribute('countryIsoCode') != languageCountryIsoCode) {
              el.setAttribute('countryIsoCode', languageCountryIsoCode);
              changed = true;
            }
            if (el.getAttribute('languageIsoCode') != languageIsoCode) {
              el.setAttribute('languageIsoCode', languageIsoCode);
              changed = true;
            }
          }

          // Обновляем techName
          final techNameElements = document.findAllElements('techName');
          for (var el in techNameElements) {
            if (el.innerText != techName) {
              el.innerText = techName;
              changed = true;
            }
          }

          // Обновляем dataDistribution
          final dataDistElements = document.findAllElements('dataDistribution');
          for (var el in dataDistElements) {
            if (el.innerText != dataDistribution) {
              el.innerText = dataDistribution;
              changed = true;
            }
          }

          // Обновляем copyrightPara
          final copyElements = document.findAllElements('copyrightPara');
          for (var el in copyElements) {
            if (el.innerText != copyrightPara) {
              el.innerText = copyrightPara;
              changed = true;
            }
          }

          // Обновляем responsiblePartnerCompany
          final respPartnerElements = document.findAllElements('responsiblePartnerCompany');
          if (respPartnerElements.isNotEmpty) {
            final el = respPartnerElements.first;
            if (el.getAttribute('enterpriseCode') != partnerCode) {
              el.setAttribute('enterpriseCode', partnerCode);
              changed = true;
            }
            final entName = el.findElements('enterpriseName').firstOrNull;
            if (entName != null && entName.innerText != partnerName) {
              entName.innerText = partnerName;
              changed = true;
            }
          }

          // Обновляем originator
          final origElements = document.findAllElements('originator');
          if (origElements.isNotEmpty) {
            final el = origElements.first;
            if (el.getAttribute('enterpriseCode') != partnerCode) {
              el.setAttribute('enterpriseCode', partnerCode);
              changed = true;
            }
            final entName = el.findElements('enterpriseName').firstOrNull;
            if (entName != null && entName.innerText != partnerName) {
              entName.innerText = partnerName;
              changed = true;
            }
          }

          // Обновляем applic > displayText > simplePara
          final applicElements = document.findAllElements('applic');
          for (var applic in applicElements) {
            final displayTexts = applic.findElements('displayText');
            for (var dt in displayTexts) {
              final paras = dt.findElements('simplePara');
              if (paras.isNotEmpty && paras.first.innerText != techName) {
                 paras.first.innerText = techName;
                 changed = true;
              }
            }
          }

          // Обновляем brexDmRef
          final brexDmRefElements = document.findAllElements('brexDmRef');
          for (var brex in brexDmRefElements) {
             final dmRefIdent = brex.findAllElements('dmRefIdent').firstOrNull;
             final dmCode = dmRefIdent?.findAllElements('dmCode').firstOrNull;
             if (dmCode != null) {
                if (dmCode.getAttribute('modelIdentCode') != modelIdentCode) {
                   dmCode.setAttribute('modelIdentCode', modelIdentCode);
                   changed = true;
                }
                if (dmCode.getAttribute('infoCode') != brexInfoCode) {
                   dmCode.setAttribute('infoCode', brexInfoCode);
                   changed = true;
                }
                if (dmCode.getAttribute('itemLocationCode') != brexLocation) {
                   dmCode.setAttribute('itemLocationCode', brexLocation);
                   changed = true;
                }
             }
          }

          // Обновляем dmCode текущего документа
          final dmCodeElements = document.findAllElements('dmCode');
          for (var dmCode in dmCodeElements) {
             if (dmCode.getAttribute('modelIdentCode') != modelIdentCode) {
                 dmCode.setAttribute('modelIdentCode', modelIdentCode);
                 changed = true;
             }
          }

          if (changed) {
            await file.writeAsString(document.toXmlString(pretty: true));
          }
        } catch (e) {
          debugPrint('Ошибка при обновлении файла ${file.path}: $e');
        }
      }
    } catch (e) {
      debugPrint('Ошибка доступа к директории: $e');
    }
  }

  void closeProject() {
    workDir = null;
    notifyListeners();
  }

  // --- UI Методы ---

  Future<void> pickProject(BuildContext context) async {
    final String? selectedDirectory = await FilePicker.getDirectoryPath(dialogTitle: 'Выберите папку проекта');

    if (selectedDirectory != null) {
      if (!context.mounted) return;
      final dir = Directory(selectedDirectory);
      final projectFile = File('${dir.path}/project.json');

      if (await projectFile.exists()) {
        await loadProject(dir);
      } else {
        if (context.mounted) await showProjectSettingsDialog(context, dir);
      }
    }
  }

  Future<void> showProjectSettingsDialog(BuildContext context, Directory dir) async {
    final modelIdentCodeCtrl = TextEditingController(text: modelIdentCode);
    final languageIsoCodeCtrl = TextEditingController(text: languageIsoCode);
    final languageCountryIsoCodeCtrl = TextEditingController(text: languageCountryIsoCode);
    final techNameCtrl = TextEditingController(text: techName);
    final partnerCodeCtrl = TextEditingController(text: partnerCode);
    final partnerNameCtrl = TextEditingController(text: partnerName);
    final dataDistributionCtrl = TextEditingController(text: dataDistribution);
    final copyrightParaCtrl = TextEditingController(text: copyrightPara);
    final brexInfoCodeCtrl = TextEditingController(text: brexInfoCode);
    final brexLocationCtrl = TextEditingController(text: brexLocation);

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: QRHColors.secondaryBg,
          title: const Text('Настройки нового проекта', style: TextStyle(color: QRHColors.textPrimary)),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: ProjectSettingsForm(
                modelIdentCodeCtrl: modelIdentCodeCtrl,
                languageIsoCodeCtrl: languageIsoCodeCtrl,
                languageCountryIsoCodeCtrl: languageCountryIsoCodeCtrl,
                techNameCtrl: techNameCtrl,
                partnerCodeCtrl: partnerCodeCtrl,
                partnerNameCtrl: partnerNameCtrl,
                dataDistributionCtrl: dataDistributionCtrl,
                copyrightParaCtrl: copyrightParaCtrl,
                brexInfoCodeCtrl: brexInfoCodeCtrl,
                brexLocationCtrl: brexLocationCtrl,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => ctx.pop(false),
              child: const Text('Отмена', style: TextStyle(color: QRHColors.danger)),
            ),
            TextButton(
              onPressed: () => ctx.pop(true),
              child: const Text('Сохранить', style: TextStyle(color: QRHColors.success)),
            ),
          ],
        );
      },
    );

    if (result == true) {
      workDir = dir;
      modelIdentCode = modelIdentCodeCtrl.text;
      languageIsoCode = languageIsoCodeCtrl.text;
      languageCountryIsoCode = languageCountryIsoCodeCtrl.text;
      techName = techNameCtrl.text;
      partnerCode = partnerCodeCtrl.text;
      partnerName = partnerNameCtrl.text;
      dataDistribution = dataDistributionCtrl.text;
      copyrightPara = copyrightParaCtrl.text;
      brexInfoCode = brexInfoCodeCtrl.text;
      brexLocation = brexLocationCtrl.text;

      await saveProjectSettings();
    }
  }

  bool isDmCodeOccupied(String sysCode, String infoCode, String variant, {String diffCode = 'AAA'}) {
    if (workDir == null) return false;
    final prefix = 'DMC-$modelIdentCode-$diffCode-$sysCode-00-00-00AA-$infoCode$variant-A_';
    return workDir!.listSync().whereType<File>().any((f) {
      final name = f.path.split(Platform.pathSeparator).last;
      return name.startsWith(prefix);
    });
  }

  (String, String) getNextAvailableCodes(String sysCode, {String diffCode = 'AAA'}) {
    if (workDir == null) return ('001', 'A');

    final files = workDir!.listSync().whereType<File>().where((f) {
      final name = f.path.split(Platform.pathSeparator).last;
      return name.startsWith('DMC-$modelIdentCode-$diffCode-$sysCode-');
    }).toList();

    int maxInfoCode = 0;
    String maxVariant = 'A';

    for (final f in files) {
      final name = f.path.split(Platform.pathSeparator).last;
      final parts = name.split('-');
      if (parts.length > 8) {
        final infoCodeAndVariant = parts[8];
        if (infoCodeAndVariant.length >= 4) {
          final icStr = infoCodeAndVariant.substring(0, 3);
          final icvStr = infoCodeAndVariant.substring(3, 4);
          final ic = int.tryParse(icStr) ?? 0;
          if (ic > maxInfoCode) {
            maxInfoCode = ic;
            maxVariant = icvStr;
          } else if (ic == maxInfoCode && icvStr.compareTo(maxVariant) > 0) {
            maxVariant = icvStr;
          }
        }
      }
    }

    if (maxInfoCode == 0) return ('001', 'A');

    int nextIc = maxInfoCode + 1;
    return (nextIc.toString().padLeft(3, '0'), 'A');
  }

  Future<void> createNewXmlFile(BuildContext context) async {
    if (workDir == null) return;

    final defaultSysCode = 'D00';
    final (defaultInfoCode, defaultVariant) = getNextAvailableCodes(defaultSysCode, diffCode: 'AAA');

    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => NewFileDialog(
        title: 'Создать новый файл',
        actionText: 'Создать',
        initialSystemCode: defaultSysCode,
        initialInfoCode: defaultInfoCode,
        initialInfoCodeVariant: defaultVariant,
        initialInfoName: '',
        isFileExists: (sys, info, varCode) => isDmCodeOccupied(sys, info, varCode, diffCode: 'AAA'),
      ),
    );

    if (result != null && context.mounted) {
      final infoName = result['infoName']!;
      final sysCode = result['sysCode']!;
      final infoCode = result['infoCode']!;
      final infoCodeVar = result['infoCodeVar']!;

      final params = createChecklistParams(
        infoName: infoName,
        systemCode: sysCode,
        infoCode: infoCode,
        infoCodeVariant: infoCodeVar,
      );

      final identXml = createIdentAndStatusSection(params);

      final fullXmlString =
          '''<?xml version="1.0" encoding="UTF-8"?>
<dmodule xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:dc="http://www.purl.org/dc/elements/1.1/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:xlink="http://www.w3.org/1999/xlink" xsi:noNamespaceSchemaLocation="http://www.s1000d.org/S1000D_4-1/xml_schema_flat/crew.xsd">
$identXml
<content>
<crew>
<crewRefCard>
<title>${params.infoName}</title>
</crewRefCard>
</crew>
</content>
</dmodule>''';

      final fileName = params.getFileName();
      final filePath = '${workDir!.path}${Platform.pathSeparator}$fileName';
      final file = File(filePath);

      await file.writeAsString(fullXmlString);

      if (context.mounted) {
        final document = XmlDocument.parse(fullXmlString);
        context.push(
          '/crew_viewer',
          extra: {
            'document': document,
            'fileName': fileName,
            'filePath': filePath,
            'fileTitle': params.infoName,
          },
        );
      }
    }
  }

  Future<void> pickFile(BuildContext context) async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['xml'], withData: kIsWeb);

    if (result != null && result.files.isNotEmpty) {
      final platformFile = result.files.single;
      String content;

      if (kIsWeb) {
        content = utf8.decode(platformFile.bytes!);
      } else {
        if (platformFile.path != null) {
          content = await File(platformFile.path!).readAsString();
        } else {
          return;
        }
      }

      if (context.mounted) {
        context.push(
          '/xml_viewer',
          extra: {
            'xmlContent': content,
            'fileName': platformFile.name,
            'filePath': kIsWeb ? null : platformFile.path,
          },
        );
      }
    }
  }

  // --- ИМПОРТ ИЗ MARKDOWN ---
  Future<void> importMarkdownFile(BuildContext context, {bool isCrew = true}) async {
    if (workDir == null) return;

    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['md', 'txt'],
      withData: kIsWeb,
    );

    if (result != null && result.files.isNotEmpty) {
      final platformFile = result.files.single;
      String mdContent;

      if (kIsWeb) {
        mdContent = utf8.decode(platformFile.bytes!);
      } else {
        if (platformFile.path != null) {
          mdContent = await File(platformFile.path!).readAsString();
        } else {
          return;
        }
      }

      if (!context.mounted) return;

      // Спрашиваем метаданные для нового файла
      final defaultSysCode = 'D00';
      final (defaultInfoCode, defaultVariant) = getNextAvailableCodes(defaultSysCode, diffCode: 'AAA');

      final defaultName = platformFile.name.replaceAll(RegExp(r'\.(md|txt)$'), '');
      final firstHeader = mdContent
          .split("\n")
          .firstWhere((l) => l.trim().startsWith("# "), orElse: () => "")
          .replaceAll("#", "")
          .trim();
      final defaultInfoName = firstHeader.isNotEmpty ? firstHeader : defaultName;

      final dialogResult = await showDialog<Map<String, String>>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => NewFileDialog(
          title: 'Импорт из Markdown',
          actionText: 'Импорт',
          initialSystemCode: defaultSysCode,
          initialInfoCode: defaultInfoCode,
          initialInfoCodeVariant: defaultVariant,
          initialInfoName: defaultInfoName,
          isFileExists: (sys, info, varCode) => isDmCodeOccupied(sys, info, varCode, diffCode: 'AAA'),
        ),
      );

      if (dialogResult != null && context.mounted) {
        final infoName = dialogResult['infoName']!;
        final sysCode = dialogResult['sysCode']!;
        final infoCode = dialogResult['infoCode']!;
        final infoCodeVar = dialogResult['infoCodeVar']!;

        final params = createChecklistParams(
          infoName: infoName,
          systemCode: sysCode,
          infoCode: infoCode,
          infoCodeVariant: infoCodeVar,
          systemDiffCode: isCrew ? 'AAA' : 'A',
        );

        final identXml = createIdentAndStatusSection(params);
        final contentXml = isCrew
            ? S1000DMdParser.parseToCrewContent(mdContent, params.infoName)
            : S1000DMdParser.parseToDescriptionContent(mdContent, params.infoName);

        final schemaLocation = isCrew
            ? 'http://www.s1000d.org/S1000D_4-1/xml_schema_flat/crew.xsd'
            : 'http://www.s1000d.org/S1000D_4-1/xml_schema_flat/descript.xsd';

        final fullXmlString =
            '''<?xml version="1.0" encoding="UTF-8"?>
<dmodule xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:dc="http://www.purl.org/dc/elements/1.1/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:xlink="http://www.w3.org/1999/xlink" xsi:noNamespaceSchemaLocation="$schemaLocation">
$identXml
${contentXml.toXmlString(pretty: true)}
</dmodule>''';

        final fileName = params.getFileName();
        final filePath = '${workDir!.path}${Platform.pathSeparator}$fileName';
        final file = File(filePath);

        await file.writeAsString(fullXmlString);

        if (context.mounted) {
          final document = XmlDocument.parse(fullXmlString);
          if (isCrew) {
            context.push(
              '/crew_viewer',
              extra: {
                'document': document,
                'fileName': fileName,
                'filePath': filePath,
                'fileTitle': params.infoName,
              },
            );
          } else {
            context.push(
              '/description_viewer',
              extra: {
                'document': document,
                'fileName': fileName,
                'filePath': filePath,
              },
            );
          }
        }
      }
    }
  }

  // --- ГЕНЕРАЦИЯ ОГЛАВЛЕНИЯ (PMC) ---

  Future<void> openOrGenerateTOC(BuildContext context, bool rebuild) async {
    if (workDir == null) return;

    // Пытаемся найти существующий PMC (оглавление)
    File? tocFile;
    try {
      final entities = await workDir!.list().toList();
      for (var entity in entities) {
        if (entity is File) {
          final fileName = entity.uri.pathSegments.last;
          if (fileName.toUpperCase().startsWith('PMC-$modelIdentCode-') && fileName.toUpperCase().endsWith('.XML')) {
            tocFile = entity;
            break;
          }
        }
      }
    } catch (e) {
      debugPrint('Ошибка при поиске файла оглавления: $e');
    }

    if (!rebuild && tocFile != null && await tocFile.exists()) {
      // Файл существует, просто открываем его
      try {
        final content = await tocFile.readAsString();
        final document = XmlDocument.parse(content);
        if (context.mounted) {
          context.push(
            '/pm_viewer',
            extra: {
              'document': document,
              'fileName': tocFile.uri.pathSegments.last,
              'filePath': tocFile.path,
            },
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка при открытии оглавления: $e'), backgroundColor: QRHColors.danger),
          );
        }
      }
    } else {
      // Файла нет, генерируем новый
      if (context.mounted) {
        await generateTOC(context);
      }
    }
  }

  Future<void> generateTOC(BuildContext context, {bool openViewer = true}) async {
    if (workDir == null) return;
    print(workDir!.path);
    // Покажем лоадер, если файлов много
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final entities = await workDir!.list().toList();
      final xmlFiles = entities.whereType<File>().where((f) => f.path.toLowerCase().endsWith('.xml'));

      final Map<String, String> infoCategories = {
        '040': '040: Аварийные ситуации',
        '050': '050: Сложные ситуации',
        '030': '030: Контрольные карты',
        '060': '060: Нормальная эксплуатация',
        '020': '020: Ограничения',
        '005': '005: ТМПО (MEL)',
        '041': '041: Описание (системы/КСЭИС/АСО)',
        '001': '001: Общие данные',
      };

      final List<String> categoryOrder = [
        '040', '050', '030', '060', '020', '005', '041', '001'
      ];

      Map<String, List<XmlElement>> groupedRefs = {};

      for (var file in xmlFiles) {
        final fileName = file.uri.pathSegments.last;
        // Пропускаем PMC и другие не-DM файлы
        if (!fileName.toUpperCase().startsWith('DMC-')) continue;

        final content = await file.readAsString();
        final dmDoc = XmlDocument.parse(content);

        final dmIdent = dmDoc.findAllElements('dmIdent').firstOrNull;
        final dmTitle = dmDoc.findAllElements('dmTitle').firstOrNull;

        if (dmIdent != null) {
          final dmCode = dmIdent.findElements('dmCode').firstOrNull;
          final infoCode = dmCode?.getAttribute('infoCode') ?? '';

          final dmRef = XmlElement(XmlName('dmRef'), [], [
            XmlElement(XmlName('dmRefIdent'), [], [
              if (dmCode != null) dmCode.copy(),
              if (dmIdent.findElements('issueInfo').isNotEmpty) dmIdent.findElements('issueInfo').first.copy(),
              if (dmIdent.findElements('language').isNotEmpty) dmIdent.findElements('language').first.copy(),
            ]),
            XmlElement(XmlName('dmRefAddressItems'), [], [if (dmTitle != null) dmTitle.copy()]),
          ]);
          
          groupedRefs.putIfAbsent(infoCode, () => []).add(dmRef);
        }
      }

      List<XmlElement> pmEntries = [];

      // Добавляем главный заголовок PMC (опционально, но S1000D допускает вложенные pmEntry)
      for (var code in categoryOrder) {
        if (groupedRefs.containsKey(code)) {
          final refs = groupedRefs[code]!;

          // Сортировка ссылок внутри категории по имени файла (DM Code)
          refs.sort((a, b) {
            final aDmCode = a.findElements('dmRefIdent').firstOrNull?.findElements('dmCode').firstOrNull;
            final bDmCode = b.findElements('dmRefIdent').firstOrNull?.findElements('dmCode').firstOrNull;

            if (aDmCode == null && bDmCode == null) return 0;
            if (aDmCode == null) return 1;
            if (bDmCode == null) return -1;

            // Собираем коды в строку для лексикографического сравнения (подобно имени файла)
            final aStr = '${aDmCode.getAttribute('modelIdentCode')}-${aDmCode.getAttribute('systemDiffCode')}-${aDmCode.getAttribute('systemCode')}-${aDmCode.getAttribute('subSystemCode')}${aDmCode.getAttribute('subSubSystemCode')}-${aDmCode.getAttribute('assyCode')}-${aDmCode.getAttribute('disassyCode')}${aDmCode.getAttribute('disassyCodeVariant')}-${aDmCode.getAttribute('infoCode')}${aDmCode.getAttribute('infoCodeVariant')}-${aDmCode.getAttribute('itemLocationCode')}';
            final bStr = '${bDmCode.getAttribute('modelIdentCode')}-${bDmCode.getAttribute('systemDiffCode')}-${bDmCode.getAttribute('systemCode')}-${bDmCode.getAttribute('subSystemCode')}${bDmCode.getAttribute('subSubSystemCode')}-${bDmCode.getAttribute('assyCode')}-${bDmCode.getAttribute('disassyCode')}${bDmCode.getAttribute('disassyCodeVariant')}-${bDmCode.getAttribute('infoCode')}${bDmCode.getAttribute('infoCodeVariant')}-${bDmCode.getAttribute('itemLocationCode')}';

            return aStr.compareTo(bStr);
          });
          
          final pmEntry = XmlElement(XmlName('pmEntry'), [], [
            XmlElement(XmlName('pmEntryTitle'), [], [XmlText(infoCategories[code]!)]),
            ...refs,
          ]);
          pmEntries.add(pmEntry);
          groupedRefs.remove(code);
        }
      }

      if (groupedRefs.isNotEmpty) {
        for (var entry in groupedRefs.entries) {
          final refs = entry.value;

          refs.sort((a, b) {
            final aDmCode = a.findElements('dmRefIdent').firstOrNull?.findElements('dmCode').firstOrNull;
            final bDmCode = b.findElements('dmRefIdent').firstOrNull?.findElements('dmCode').firstOrNull;

            if (aDmCode == null && bDmCode == null) return 0;
            if (aDmCode == null) return 1;
            if (bDmCode == null) return -1;

            final aStr = '${aDmCode.getAttribute('modelIdentCode')}-${aDmCode.getAttribute('systemDiffCode')}-${aDmCode.getAttribute('systemCode')}-${aDmCode.getAttribute('subSystemCode')}${aDmCode.getAttribute('subSubSystemCode')}-${aDmCode.getAttribute('assyCode')}-${aDmCode.getAttribute('disassyCode')}${aDmCode.getAttribute('disassyCodeVariant')}-${aDmCode.getAttribute('infoCode')}${aDmCode.getAttribute('infoCodeVariant')}-${aDmCode.getAttribute('itemLocationCode')}';
            final bStr = '${bDmCode.getAttribute('modelIdentCode')}-${bDmCode.getAttribute('systemDiffCode')}-${bDmCode.getAttribute('systemCode')}-${bDmCode.getAttribute('subSystemCode')}${bDmCode.getAttribute('subSubSystemCode')}-${bDmCode.getAttribute('assyCode')}-${bDmCode.getAttribute('disassyCode')}${bDmCode.getAttribute('disassyCodeVariant')}-${bDmCode.getAttribute('infoCode')}${bDmCode.getAttribute('infoCodeVariant')}-${bDmCode.getAttribute('itemLocationCode')}';

            return aStr.compareTo(bStr);
          });

          final pmEntry = XmlElement(XmlName('pmEntry'), [], [
            XmlElement(XmlName('pmEntryTitle'), [], [XmlText('Прочее (Код: ${entry.key})')]),
            ...refs,
          ]);
          pmEntries.add(pmEntry);
        }
      }

      final pmIssuer = partnerCode; // Используем partnerCode как pmIssuer
      final pmNumber = '00001';
      final pmVolume = '00';

      final pmcXml = S1000DPmBuilder.buildPmXml(
        modelIdentCode: modelIdentCode,
        pmIssuer: pmIssuer,
        pmNumber: pmNumber,
        pmVolume: pmVolume,
        languageIsoCode: languageIsoCode,
        countryIsoCode: languageCountryIsoCode,
        issueNumber: '001',
        inWork: '00',
        techName: techName,
        pmTitle: 'Сводное оглавление проекта',
        partnerCode: partnerCode,
        partnerName: partnerName,
        dataDistribution: dataDistribution,
        copyrightPara: copyrightPara,
        brexHref: '', // Заглушка, можно тоже брать из params
        pmEntries: pmEntries,
      );

      final pmcFileName =
          'PMC-$modelIdentCode-$pmIssuer-$pmNumber-${pmVolume}_001-00_$languageIsoCode-$languageCountryIsoCode.XML';
      final pmcFilePath = '${workDir!.path}${Platform.pathSeparator}$pmcFileName';

      final pmcFile = File(pmcFilePath);
      await pmcFile.writeAsString(pmcXml);

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Закрыть лоадер

        if (openViewer) {
          final document = XmlDocument.parse(pmcXml);
          context.push(
            '/pm_viewer',
            extra: {
              'document': document,
              'fileName': pmcFileName,
              'filePath': pmcFilePath,
            },
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Закрыть лоадер
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка генерации оглавления: $e'), backgroundColor: QRHColors.danger));
      }
    }
  }

  // 3. ЛОГИКА ГЕНЕРАЦИИ (осталась прежней)
  IdentAndStatusSectionParams createChecklistParams({
    required String infoName,
    required String systemCode,
    required String infoCode,
    String? infoCodeVariant,
    String? systemDiffCode,
  }) {
    final now = DateTime.now();
    String autoIssueNumber = _calculateNextIssueNumber(systemCode, infoCode);

    return IdentAndStatusSectionParams(
      modelIdentCode: modelIdentCode,
      systemCode: systemCode,
      infoCode: infoCode,
      infoName: infoName,
      infoCodeVariant: infoCodeVariant ?? 'A',

      systemDiffCode: systemDiffCode ?? 'AAA',
      subSystemCode: '0',
      subSubSystemCode: '0',
      assyCode: '00',
      disassyCode: '00',
      disassyCodeVariant: 'AA',
      itemLocationCode: 'A',

      languageCountryIsoCode: languageCountryIsoCode,
      languageIsoCode: languageIsoCode,
      techName: techName,

      issueNumber: autoIssueNumber,
      inWork: '00',
      issueYear: now.year.toString(),
      issueMonth: now.month.toString().padLeft(2, '0'),
      issueDay: now.day.toString().padLeft(2, '0'),

      issueType: 'new',
      securityClassification: '01',
      dataDistribution: dataDistribution,
      copyrightPara: copyrightPara,
      partnerEnterpriseCode: partnerCode,
      partnerEnterpriseName: partnerName,
      originatorEnterpriseCode: partnerCode,
      originatorEnterpriseName: partnerName,
      applicText: techName,

      brexRefSystemDiffCode: 'AAA',
      brexRefSystemCode: 'D00',
      brexRefSubSystemCode: '0',
      brexRefSubSubSystemCode: '0',
      brexRefAssyCode: '00',
      brexRefDisassyCode: '00',
      brexRefDisassyCodeVariant: 'AA',
      brexRefInfoCode: brexInfoCode,
      brexRefInfoCodeVariant: 'A',
      brexRefItemLocationCode: brexLocation,

      verificationType: 'tabtop',
      skillLevelCode: 'sk01',
    );
  }

  String _calculateNextIssueNumber(String systemCode, String infoCode) {
    return '001';
  }
}
