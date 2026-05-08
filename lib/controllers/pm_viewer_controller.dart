import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:xml/xml.dart';
import '../styles.dart';
import '../utils/s1000d_utils.dart';
import 'app_controller.dart';

class PmViewerController extends ChangeNotifier {
  final String fileName;
  final String? filePath;

  XmlDocument _currentDocument;
  XmlDocument? _editingDocument;

  bool _isGridView = true;
  bool _isEditing = false;
  XmlElement? _selectedEntry;
  String? _selectedLanguageFilter;

  PmViewerController({required XmlDocument document, required this.fileName, this.filePath})
    : _currentDocument = document.copy();

  // Getters
  XmlDocument get document => _isEditing ? _editingDocument! : _currentDocument;
  bool get isGridView => _isGridView;
  bool get isEditing => _isEditing;
  XmlElement? get selectedEntry => _selectedEntry;
  String? get selectedLanguageFilter => _selectedLanguageFilter;

  // Actions
  void setLanguageFilter(String? lang) {
    _selectedLanguageFilter = lang;
    notifyListeners();
  }

  Set<String> get allProjectLanguages {
    final languages = <String>{};
    final allDmRefs = document.findAllElements('dmRef');
    for (final dmRef in allDmRefs) {
      final langNode = dmRef.findAllElements('language').firstOrNull;
      if (langNode != null) {
        final lang = langNode.getAttribute('languageIsoCode') ?? '';
        final country = langNode.getAttribute('countryIsoCode') ?? '';
        if (lang.isNotEmpty && country.isNotEmpty) {
          languages.add('$lang-$country');
        }
      }
    }
    return languages;
  }

  bool get isMultilingualIncomplete {
    final languages = allProjectLanguages;
    if (languages.length <= 1) return false;

    final allDmRefs = document.findAllElements('dmRef');
    for (final dmRef in allDmRefs) {
      if (getMissingLanguagesForDm(dmRef).isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  Set<String> getMissingLanguagesForDm(XmlElement dmRef) {
    final projectLanguages = allProjectLanguages;
    if (projectLanguages.length <= 1) return {};

    final dmCode = dmRef.findAllElements('dmCode').firstOrNull;
    if (dmCode == null) return {};

    // Собираем идентификатор файла без учета языка
    final baseId = _getDmBaseIdentifier(dmCode);

    final currentLangNode = dmRef.findAllElements('language').firstOrNull;
    final currentLang = currentLangNode != null
        ? '${currentLangNode.getAttribute('languageIsoCode')}-${currentLangNode.getAttribute('countryIsoCode')}'
        : '';

    final existingLanguagesForThisDm = <String>{};
    if (currentLang.isNotEmpty) existingLanguagesForThisDm.add(currentLang);

    // Ищем в документе другие dmRef с таким же идентификатором, но другими языками
    final allDmRefs = document.findAllElements('dmRef');
    for (final otherRef in allDmRefs) {
      if (otherRef == dmRef) continue;
      final otherDmCode = otherRef.findAllElements('dmCode').firstOrNull;
      if (otherDmCode != null && _getDmBaseIdentifier(otherDmCode) == baseId) {
        final otherLangNode = otherRef.findAllElements('language').firstOrNull;
        if (otherLangNode != null) {
          final otherLang =
              '${otherLangNode.getAttribute('languageIsoCode')}-${otherLangNode.getAttribute('countryIsoCode')}';
          existingLanguagesForThisDm.add(otherLang);
        }
      }
    }

    return projectLanguages.difference(existingLanguagesForThisDm);
  }

  String _getDmBaseIdentifier(XmlElement dmCode) {
    return '${dmCode.getAttribute('modelIdentCode')}-'
        '${dmCode.getAttribute('systemDiffCode')}-'
        '${dmCode.getAttribute('systemCode')}-'
        '${dmCode.getAttribute('subSystemCode')}${dmCode.getAttribute('subSubSystemCode')}-'
        '${dmCode.getAttribute('assyCode')}-'
        '${dmCode.getAttribute('disassyCode')}${dmCode.getAttribute('disassyCodeVariant')}-'
        '${dmCode.getAttribute('infoCode')}${dmCode.getAttribute('infoCodeVariant')}-'
        '${dmCode.getAttribute('itemLocationCode')}';
  }

  // Actions
  void setViewMode(bool gridView) {
    _isGridView = gridView;
    notifyListeners();
  }

  void toggleViewMode() {
    _isGridView = !_isGridView;
    notifyListeners();
  }

  void selectEntry(XmlElement? entry) {
    _selectedEntry = entry;
    notifyListeners();
  }

  void startEditing() {
    _isEditing = true;
    _editingDocument = _currentDocument.copy();
    if (_isGridView) {
      _isGridView = false;
    }
    notifyListeners();
  }

  void cancelEditing() {
    _isEditing = false;
    _editingDocument = null;
    notifyListeners();
  }

  Future<void> saveChanges(BuildContext context) async {
    if (_editingDocument == null || filePath == null || kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(kIsWeb ? 'Сохранение не поддерживается в веб-версии' : 'Не указан путь для сохранения файла.'),
          backgroundColor: QRHColors.danger,
        ),
      );
      return;
    }

    try {
      final file = File(filePath!);
      await file.writeAsString(_editingDocument!.toXmlString(pretty: true, indent: '  '));

      _currentDocument = _editingDocument!;
      _isEditing = false;
      _editingDocument = null;
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Файл успешно сохранен'), backgroundColor: QRHColors.success));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка сохранения файла: $e'), backgroundColor: QRHColors.danger));
      }
    }
  }

  Future<void> createTocForLanguage(BuildContext context, String langTag, AppController appController) async {
    final parts = langTag.split('-');
    final langIso = parts[0];
    final countryIso = parts[1];

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Генерация оглавления для $langTag...')));

      // Вызываем generateTOC с переопределением языка и номера 00002 для специфических PMC
      await appController.generateTOC(
        context,
        openViewer: false,
        overrideLanguageIso: langIso,
        overrideCountryIso: countryIso,
        pmNumberOverride: '00002',
      );
    }
  }

  void deleteNode(XmlElement nodeToDelete) {
    final parent = nodeToDelete.parent;
    if (parent != null) {
      parent.children.remove(nodeToDelete);
      notifyListeners();
    }
  }

  Future<void> addMissingLanguages(BuildContext context, XmlElement dmRef, AppController appController) async {
    final missingLangs = getMissingLanguagesForDm(dmRef);
    if (missingLangs.isEmpty || filePath == null) return;

    final workDirPath = appController.workDir?.path;
    if (workDirPath == null) return;

    // 1. Находим исходный файл на диске
    final prefix = S1000DUtils.buildDmcPrefixFromIdent(dmRef);
    final sourceFile = File('$workDirPath/$prefix');

    if (!await sourceFile.exists()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Исходный файл $prefix не найден на диске'), backgroundColor: QRHColors.danger),
        );
      }
      return;
    }

    try {
      final sourceContent = await sourceFile.readAsString();
      final sourceDoc = XmlDocument.parse(sourceContent);

      for (final langTag in missingLangs) {
        final parts = langTag.split('-');
        final langIso = parts[0];
        final countryIso = parts[1];

        // Копируем документ
        final newDoc = sourceDoc.copy();

        // 2. Меняем тег <language> внутри <dmIdent>
        final dmIdent = newDoc.findAllElements('dmIdent').firstOrNull;
        if (dmIdent != null) {
          final langNode = dmIdent.findElements('language').firstOrNull;
          if (langNode != null) {
            langNode.setAttribute('languageIsoCode', langIso);
            langNode.setAttribute('countryIsoCode', countryIso);
          }
        }

        // 3. Формируем новое имя файла
        final newPrefix = S1000DUtils.buildDmcPrefixFromIdent(dmIdent!);
        final newFile = File('$workDirPath/$newPrefix');

        // Сохраняем
        await newFile.writeAsString(newDoc.toXmlString(pretty: true, indent: '  '));
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Добавлено копий: ${missingLangs.length}'), backgroundColor: QRHColors.success),
        );
        // 4. Перегенерация оглавления
        await appController.openOrGenerateTOC(context, true);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка при создании копий: $e'), backgroundColor: QRHColors.danger));
      }
    }
  }

  Future<void> addFile(BuildContext context, AppController appController) async {
    final workDir = appController.workDir?.path;

    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xml'],
      initialDirectory: workDir,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final fileBytes = file.bytes;
    if (fileBytes == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Не удалось прочитать файл'), backgroundColor: QRHColors.danger));
      }
      return;
    }

    try {
      final dmContent = utf8.decode(fileBytes);
      final dmDocument = XmlDocument.parse(dmContent);

      final dmIdent = dmDocument.findAllElements('dmIdent').firstOrNull;
      if (dmIdent == null) throw Exception('<dmIdent> не найден в выбранном файле.');

      // Check for duplicates
      final newFilePrefix = S1000DUtils.buildDmcPrefixFromIdent(dmIdent);
      if (newFilePrefix.isNotEmpty) {
        final allExistingDmRefs = document.findAllElements('dmRef');
        for (final dmRef in allExistingDmRefs) {
          final dmRefIdent = dmRef.findElements('dmRefIdent').firstOrNull;
          if (dmRefIdent != null) {
            final existingPrefix = S1000DUtils.buildDmcPrefixFromIdent(dmRefIdent);
            if (existingPrefix == newFilePrefix) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Этот файл уже существует в оглавлении.'),
                    backgroundColor: QRHColors.warning,
                  ),
                );
              }
              return;
            }
          }
        }
      }

      final dmCodeNode = dmIdent.findElements('dmCode').firstOrNull;
      if (dmCodeNode == null) throw Exception('<dmCode> не найден.');

      final dmCodeAttrs = dmCodeNode.attributes.fold<Map<String, String>>({}, (map, attr) {
        map[attr.name.local] = attr.value;
        return map;
      });
      final infoCode = dmCodeAttrs['infoCode'];
      if (infoCode == null) throw Exception('Атрибут "infoCode" не найден в <dmCode>.');

      final dmTitleNode = dmDocument.findAllElements('dmTitle').firstOrNull;
      final techName = dmTitleNode?.findElements('techName').firstOrNull?.innerText ?? '';
      final infoName = dmTitleNode?.findElements('infoName').firstOrNull?.innerText ?? '';

      final builder = XmlBuilder();
      builder.element(
        'dmRef',
        nest: () {
          builder.element(
            'dmRefIdent',
            nest: () {
              builder.element('dmCode', attributes: dmCodeAttrs);
              final issueInfo = dmIdent.findElements('issueInfo').firstOrNull;
              if (issueInfo != null) {
                builder.element(
                  'issueInfo',
                  attributes: issueInfo.attributes.fold({}, (m, a) => m..[a.name.local] = a.value),
                );
              }
              final language = dmIdent.findElements('language').firstOrNull;
              if (language != null) {
                builder.element(
                  'language',
                  attributes: language.attributes.fold({}, (m, a) => m..[a.name.local] = a.value),
                );
              }
            },
          );
          builder.element(
            'dmRefAddressItems',
            nest: () {
              builder.element(
                'dmTitle',
                nest: () {
                  if (techName.isNotEmpty) builder.element('techName', nest: techName);
                  if (infoName.isNotEmpty) builder.element('infoName', nest: infoName);
                },
              );
            },
          );
        },
      );
      final newDmRefNode = builder.buildDocument().rootElement;

      final contentNode = document.findAllElements('content').first;
      XmlElement? targetPmEntry;
      for (final node in contentNode.children.whereType<XmlElement>()) {
        if (node.name.local == 'pmEntry') {
          final title = node.findElements('pmEntryTitle').firstOrNull?.innerText ?? '';
          if (title.contains(infoCode)) {
            targetPmEntry = node;
            break;
          }
        }
      }

      if (targetPmEntry != null) {
        targetPmEntry.children.add(newDmRefNode.copy());
      } else {
        final newPmEntryBuilder = XmlBuilder();
        final pmEntryTitle = '$infoCode - $infoName';
        newPmEntryBuilder.element(
          'pmEntry',
          nest: () {
            newPmEntryBuilder.element('pmEntryTitle', nest: pmEntryTitle);
            newPmEntryBuilder.xml(newDmRefNode.toXmlString());
          },
        );
        contentNode.children.add(newPmEntryBuilder.buildDocument().rootElement.copy());
      }

      // Sort
      final entries = contentNode.children.whereType<XmlElement>().toList();
      entries.sort((a, b) {
        final titleA = a.findElements('pmEntryTitle').firstOrNull?.innerText ?? '';
        final titleB = b.findElements('pmEntryTitle').firstOrNull?.innerText ?? '';
        return titleA.compareTo(titleB);
      });
      contentNode.children.clear();
      contentNode.children.addAll(entries);

      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Файл успешно добавлен'), backgroundColor: QRHColors.success));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка добавления файла: $e'), backgroundColor: QRHColors.danger));
      }
    }
  }
}
