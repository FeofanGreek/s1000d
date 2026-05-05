import 'dart:io' show File, Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:xml/xml.dart';
import 'package:go_router/go_router.dart';
import '../styles.dart';
import '../ui/viewers/models/crew_models.dart';
import 'app_controller.dart';
import '../ui/widgets/file_settings_form.dart';

class CrewViewerController extends ChangeNotifier {
  final XmlDocument document;
  String fileName;
  String? filePath;
  String? fileTitle;

  final List<CrewItem> items = [];
  final List<bool> checkboxStates = [];

  bool isEditMode = false;
  bool hasChanges = false;

  CrewViewerController({required this.document, required this.fileName, this.filePath, this.fileTitle}) {
    parseCrewData();
  }

  void toggleEditMode(bool value) {
    isEditMode = value;
    notifyListeners();
  }

  void setCheckbox(int index, bool value) {
    if (index < checkboxStates.length) {
      checkboxStates[index] = value;
      notifyListeners();
    }
  }

  void parseCrewData() {
    items.clear();
    final oldCheckboxStates = List<bool>.from(checkboxStates);
    checkboxStates.clear();

    final crewRefCard = document.findAllElements('crewRefCard').firstOrNull;
    if (crewRefCard != null) {
      final mainTitleNode = crewRefCard.findElements('title').firstOrNull;
      if (mainTitleNode != null) {
        items.add(CrewHeader(cleanText(mainTitleNode.innerText), titleNode: mainTitleNode));
      }
      for (var child in crewRefCard.children) {
        if (child is XmlElement) {
          if (child.name.local == 'warning' || child.name.local == 'caution' || child.name.local == 'note') {
            final type = child.name.local;
            final text = extractNodeText(child, type == 'note' ? 'notePara' : 'warningAndCautionPara');

            items.add(CrewAttention(type: type, text: text, node: child));
          }
        }
      }
    }

    final drills = document.findAllElements('crewDrill');

    for (var drill in drills) {
      final titleNode = drill.findElements('title').firstOrNull ?? drill.findElements('name').firstOrNull;
      if (titleNode != null) {
        items.add(CrewHeader(cleanText(titleNode.innerText), titleNode: titleNode));
      }

      for (var child in drill.children) {
        if (child is XmlElement) {
          if (child.name.local == 'warning' || child.name.local == 'caution' || child.name.local == 'note') {
            final type = child.name.local;
            final text = extractNodeText(child, type == 'note' ? 'notePara' : 'warningAndCautionPara');

            items.add(CrewAttention(type: type, text: text, node: child));
          }
        }
      }

      final steps = drill.findAllElements('crewDrillStep');
      for (var step in steps) {
        if (step.parentElement?.name.local == 'case') continue;

        final caseElements = step.findElements('case').toList();
        if (caseElements.isNotEmpty) {
          final titleNode = step.findElements('title').firstOrNull;
          final paraNode = step.findElements('para').firstOrNull;

          final cases = <CrewCaseItem>[];
          for (var caseNode in caseElements) {
            final caseCondNode = caseNode.findElements('caseCond').firstOrNull;
            final innerStepNode = caseNode.findElements('crewDrillStep').firstOrNull;
            final stepText = innerStepNode != null ? extractNodeText(innerStepNode, 'para') : '';

            if (caseCondNode != null && innerStepNode != null) {
              final caseItem = CrewCaseItem(
                conditionText: extractNodeText(caseNode, 'caseCond'), // fallbacks to caseCond innerText
                stepText: stepText,
                caseNode: caseNode,
                caseCondNode: caseCondNode,
                innerStepNode: innerStepNode,
                innerParaNode: innerStepNode.findElements('para').firstOrNull,
              );

              final caseMembers = <String>[];
              final caseGroupNode = innerStepNode.findAllElements('crewMemberGroup').firstOrNull;
              if (caseGroupNode != null) {
                for (var member in caseGroupNode.findAllElements('crewMember')) {
                  final t = member.getAttribute('crewMemberType');
                  if (t != null) caseMembers.add(t);
                }
              }

              // Create a CrewStep representation for the case's action (stepText)
              // This allows CrewStepRow to be used for rendering the case step
              final caseCrewStep = CrewStep(
                challenge: '',
                response: '',
                simpleText: caseItem.stepText,
                crewMembers: caseMembers,
                stateIndex: -1, // Не участвует в глобальном стейте чекбоксов
                parentStepNode: innerStepNode,
                groupNode: caseGroupNode,
                parentCondition: null, // Will be set after CrewCondition is created
                parentCaseItem: caseItem,
              );

              caseItem.asCrewStep = caseCrewStep;
              cases.add(caseItem);
            }
          }

          final condition = CrewCondition(
            title: cleanText(titleNode?.innerText ?? ''),
            text: extractNodeText(step, 'para'),
            stepNode: step,
            titleNode: titleNode,
            paraNode: step.findElements('para').firstOrNull,
            cases: cases,
          );

          // Set parent condition reference in all case steps
          for (var caseItem in cases) {
            caseItem.asCrewStep.parentCondition = condition;
          }

          items.add(condition);
          continue;
        }

        final titleNode = step.findElements('title').firstOrNull;
        if (titleNode != null) {
          items.add(
            CrewDescription(
              title: cleanText(titleNode.innerText),
              text: extractNodeText(step, 'para'),
              stepNode: step,
              titleNode: titleNode,
              paraNode: step.findElements('para').firstOrNull,
            ),
          );
          continue; // Пропускаем остальную логику парсинга шагов
        }

        // Проверка на фигуру (изображение)
        final figureNode = step.findElements('figure').firstOrNull ?? step.parent?.findElements('figure').firstOrNull;
        if (figureNode != null) {
          final graphicNode = figureNode.findElements('graphic').firstOrNull;
          if (graphicNode != null) {
            final figTitleNode = figureNode.findElements('title').firstOrNull;
            items.add(
              CrewFigure(
                title: cleanText(figTitleNode?.innerText ?? ''),
                infoEntityIdent: graphicNode.getAttribute('infoEntityIdent') ?? '',
                stepNode: step,
                figureNode: figureNode,
                graphicNode: graphicNode,
                titleNode: figTitleNode,
              ),
            );
            continue; // Пропускаем остальную логику
          }
        }

        final cr = step.findAllElements('challengeAndResponse').firstOrNull;

        if (cr != null) {
          final challengeNode = cr.findAllElements('challenge').firstOrNull;
          final responseNode = cr.findAllElements('response').firstOrNull;
          final challenge = challengeNode != null ? extractNodeText(challengeNode, 'para') : '';
          final response = responseNode != null ? extractNodeText(responseNode, 'para') : '';

          final members = <String>[];
          final group =
              cr.findAllElements('crewMemberGroup').firstOrNull ?? step.findAllElements('crewMemberGroup').firstOrNull;

          if (group != null) {
            for (var member in group.findAllElements('crewMember')) {
              final t = member.getAttribute('crewMemberType');
              if (t != null) members.add(t);
            }
          }

          items.add(
            CrewStep(
              challenge: challenge,
              response: response,
              crewMembers: members,
              stateIndex: checkboxStates.length,
              challengeNode: challengeNode,
              responseNode: responseNode,
              groupNode: group,
              parentStepNode: step,
            ),
          );
          checkboxStates.add(
            checkboxStates.length < oldCheckboxStates.length ? oldCheckboxStates[checkboxStates.length] : false,
          );
        } else {
          final members = <String>[];
          final groupNode = step.findAllElements('crewMemberGroup').firstOrNull;
          if (groupNode != null) {
            for (var member in groupNode.findAllElements('crewMember')) {
              final t = member.getAttribute('crewMemberType');
              if (t != null) members.add(t);
            }
          }

          final paraWithDmRef = step.findElements('para').where((p) => p.findElements('dmRef').isNotEmpty).firstOrNull;
          if (paraWithDmRef != null) {
            final dmRefNode = paraWithDmRef.findElements('dmRef').first;
            String refText = '';
            for (var node in paraWithDmRef.children) {
              if (node == dmRefNode) break;
              if (node is XmlText) {
                refText += node.value;
              }
            }
            // Убираем двойные пробелы, но сохраняем начальные/конечные пробелы
            // чтобы можно было нормально редактировать текст в поле
            refText = refText.replaceAll(RegExp(r'  +'), ' ');

            items.add(
              CrewStep(
                challenge: '',
                response: '',
                referenceText: refText,
                dmRefNode: dmRefNode,
                crewMembers: members,
                groupNode: groupNode,
                stateIndex: checkboxStates.length,
                parentStepNode: step,
              ),
            );
            checkboxStates.add(
              checkboxStates.length < oldCheckboxStates.length ? oldCheckboxStates[checkboxStates.length] : false,
            );
          } else {
            final simpleText = extractNodeText(step, 'para');
            if (simpleText.isNotEmpty) {
              items.add(
                CrewStep(
                  challenge: '',
                  response: '',
                  simpleText: simpleText,
                  crewMembers: members,
                  groupNode: groupNode,
                  stateIndex: checkboxStates.length,
                  parentStepNode: step,
                ),
              );
              checkboxStates.add(
                checkboxStates.length < oldCheckboxStates.length ? oldCheckboxStates[checkboxStates.length] : false,
              );
            }
          }
        }
      }
    }
    notifyListeners();
  }

  String cleanText(String text) {
    return text.trim();
  }

  String extractNodeText(XmlElement parent, String childName) {
    final children = parent.children.whereType<XmlElement>().where((e) => e.name.local == childName).toList();
    if (children.isEmpty) {
      // Fallback
      return cleanText(parent.innerText);
    }
    return children.map((e) => cleanText(e.innerText)).join('\n');
  }

  Future<void> saveChanges(BuildContext context) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('В браузере сохранение локального файла недоступно.'),
          backgroundColor: QRHColors.warning,
        ),
      );
      return;
    }

    if (filePath != null) {
      try {
        final file = File(filePath!);
        await file.writeAsString(document.toXmlString(pretty: true, indent: ' '));
        hasChanges = false;
        notifyListeners();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Изменения успешно сохранены!'), backgroundColor: QRHColors.success),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Ошибка сохранения: $e'), backgroundColor: QRHColors.danger));
        }
      }
    }
  }

  Future<void> showFileSettingsDialog(BuildContext context) async {
    final appCtrl = context.read<AppController>();

    final dmCodeNode = document.findAllElements('dmCode').firstOrNull;
    final currentSysCode = dmCodeNode?.getAttribute('systemCode') ?? '';
    final currentInfoCode = dmCodeNode?.getAttribute('infoCode') ?? '';
    final currentVariant = dmCodeNode?.getAttribute('infoCodeVariant') ?? 'A';

    final titleNode = document.findAllElements('infoName').firstOrNull;
    final currentTitle = titleNode?.innerText ?? '';

    final sysCodeCtrl = TextEditingController(text: currentSysCode);
    final infoCodeCtrl = TextEditingController(text: currentInfoCode);
    final infoCodeVarCtrl = TextEditingController(text: currentVariant);
    final infoNameCtrl = TextEditingController(text: currentTitle);

    final formKey = GlobalKey<FileSettingsFormState>();
    bool isValid = true; // initially true because we open an existing valid file

    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            void onValidationChanged() {
              final newValid = formKey.currentState?.isValid ?? false;
              if (newValid != isValid) {
                setState(() => isValid = newValid);
              }
            }

            return AlertDialog(
              backgroundColor: QRHColors.secondaryBg,
              title: const Text('Настройки файла', style: TextStyle(color: QRHColors.textPrimary)),
              content: SingleChildScrollView(
                child: FileSettingsForm(
                  key: formKey,
                  sysCodeCtrl: sysCodeCtrl,
                  infoCodeCtrl: infoCodeCtrl,
                  infoCodeVarCtrl: infoCodeVarCtrl,
                  infoNameCtrl: infoNameCtrl,
                  isFileExists: (sys, info, varCode) {
                    if (sys == currentSysCode && info == currentInfoCode && varCode == currentVariant) {
                      return false;
                    }
                    return appCtrl.isDmCodeOccupied(sys, info, varCode, diffCode: 'AAA');
                  },
                  onValidationChanged: onValidationChanged,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => ctx.pop(),
                  child: const Text('Отмена', style: TextStyle(color: QRHColors.danger)),
                ),
                ElevatedButton(
                  onPressed: !isValid
                      ? null
                      : () {
                          ctx.pop({
                            'sysCode': sysCodeCtrl.text.trim().toUpperCase(),
                            'infoCode': infoCodeCtrl.text.trim(),
                            'infoCodeVar': infoCodeVarCtrl.text.trim().toUpperCase(),
                            'infoName': infoNameCtrl.text.trim(),
                          });
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: !isValid ? Colors.transparent : QRHColors.success.withValues(alpha: 0.2),
                  ),
                  child: Text(
                    'Сохранить',
                    style: TextStyle(color: !isValid ? QRHColors.textSecondary : QRHColors.success),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      final newSysCode = result['sysCode']!;
      final newInfoCode = result['infoCode']!;
      final newVariant = result['infoCodeVar']!;
      final newInfoName = result['infoName']!;

      bool xmlChanged = false;

      if (dmCodeNode != null) {
        if (currentSysCode != newSysCode) {
          dmCodeNode.setAttribute('systemCode', newSysCode);
          xmlChanged = true;
        }
        if (currentInfoCode != newInfoCode) {
          dmCodeNode.setAttribute('infoCode', newInfoCode);
          xmlChanged = true;
        }
        if (currentVariant != newVariant) {
          dmCodeNode.setAttribute('infoCodeVariant', newVariant);
          xmlChanged = true;
        }
      }

      final infoNameNodes = document.findAllElements('infoName');
      for (var node in infoNameNodes) {
        if (node.innerText != newInfoName) {
          node.innerText = newInfoName;
          xmlChanged = true;
        }
      }

      final titleNodes = document.findAllElements('title');
      if (titleNodes.isNotEmpty) {
        final mainTitle = titleNodes.first;
        if (mainTitle.innerText != newInfoName) {
          mainTitle.innerText = newInfoName;
          xmlChanged = true;
        }
      }

      if (xmlChanged) {
        hasChanges = true;
        fileTitle = newInfoName;

        if (filePath != null && !kIsWeb) {
          try {
            // Check if dmCode actually changed. If yes, calculate new file name and rename.
            if (currentSysCode != newSysCode || currentInfoCode != newInfoCode || currentVariant != newVariant) {
              final oldFile = File(filePath!);
              final params = appCtrl.createChecklistParams(
                infoName: newInfoName,
                systemCode: newSysCode,
                infoCode: newInfoCode,
                infoCodeVariant: newVariant,
                systemDiffCode: 'AAA', // Assuming crew diff code
              );

              final newFileName = params.getFileName();
              final dir = oldFile.parent;
              final newFilePath = '${dir.path}${Platform.pathSeparator}$newFileName';

              await oldFile.rename(newFilePath);

              fileName = newFileName;
              filePath = newFilePath;
            }
            // Now save the changes to the (possibly renamed) file
            if (context.mounted) {
              await saveChanges(context);
              if (context.mounted) {
                await appCtrl.generateTOC(context, openViewer: false);
              }
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Ошибка переименования/сохранения: $e'), backgroundColor: QRHColors.danger),
              );
            }
          }
        }

        notifyListeners();
      }
    }
  }

  Future<bool> onWillPop(BuildContext context) async {
    if (!hasChanges) return true;
    final exit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: QRHColors.secondaryBg,
        title: const Text('Есть несохраненные изменения', style: TextStyle(color: QRHColors.textPrimary)),
        content: const Text(
          'Вы уверены, что хотите выйти без сохранения?',
          style: TextStyle(color: QRHColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Отмена', style: TextStyle(color: QRHColors.info)),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            child: const Text('Выйти', style: TextStyle(color: QRHColors.danger)),
          ),
        ],
      ),
    );
    return exit ?? false;
  }

  void completeChecklist(BuildContext context) {
    final allChecked = checkboxStates.isNotEmpty && checkboxStates.every((state) => state);

    if (!allChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Внимание: не весь чеклист пройден!'),
          backgroundColor: QRHColors.warning,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Чеклист успешно завершен!'), backgroundColor: QRHColors.success));
  }

  void updateXmlNodeText(XmlElement? node, String newText) {
    if (node == null) return;

    final lines = newText.split('\n');

    // Для attention (warning, caution, note) обновляем текст напрямую в соответствующих параграфах
    if (node.name.local == 'warning' || node.name.local == 'caution' || node.name.local == 'note') {
      final paraName = node.name.local == 'note' ? 'notePara' : 'warningAndCautionPara';

      final existingParas = node.children.whereType<XmlElement>().where((e) => e.name.local == paraName).toList();
      for (var p in existingParas) {
        node.children.remove(p);
      }

      for (var line in lines) {
        if (line.isEmpty) {
          node.children.add(XmlElement(XmlName(paraName)));
        } else {
          node.children.add(XmlElement(XmlName(paraName), [], [XmlText(line)]));
        }
      }

      hasChanges = true;
      notifyListeners();
      return;
    }

    if (node.name.local == 'title' || node.name.local == 'name') {
      node.children.clear();
      node.children.add(XmlText(newText));
      hasChanges = true;
      notifyListeners();
      return;
    }

    final existingParas = node.children.whereType<XmlElement>().where((e) => e.name.local == 'para').toList();
    for (var p in existingParas) {
      node.children.remove(p);
    }

    // Осторожно удаляем только старые текстовые узлы, чтобы не затереть другие элементы, если они есть
    node.children.removeWhere((e) => e is XmlText && e.value.trim().isNotEmpty);

    for (var line in lines) {
      if (line.isEmpty) {
        node.children.add(XmlElement(XmlName('para')));
      } else {
        node.children.add(XmlElement(XmlName('para'), [], [XmlText(line)]));
      }
    }

    hasChanges = true;
    notifyListeners();
  }

  void removeCrewMember(CrewStep step, String cm) {
    step.crewMembers.remove(cm);
    final cmNode = step.groupNode
        ?.findAllElements('crewMember')
        .where((e) => e.getAttribute('crewMemberType') == cm)
        .firstOrNull;
    if (cmNode != null) {
      cmNode.parentElement?.children.remove(cmNode);
    }
    hasChanges = true;
    notifyListeners();
  }

  Future<void> showAddCrewMemberDialog(BuildContext context, CrewStep step) async {
    String? newCm;

    final Map<String, String> crewRoles = {
      'cm01': 'cm01 - КС (КВС)',
      'cm02': 'cm02 - 2/П (2-й пилот)',
      'cm03': 'cm03 - Б/П (Бортпроводник)',
      'cm04': 'cm04 - П/П (Пилотирующий пилот)',
      'cm05': 'cm05 - Н/П (Не пилотирующий пилот)',
      'cm06': 'cm06 - Э (Экипаж, КС+2/П)',
    };

    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: QRHColors.secondaryBg,
              title: const Text('Добавить роль', style: TextStyle(color: QRHColors.textPrimary)),
              content: DropdownButtonFormField<String>(
                value: newCm,
                dropdownColor: QRHColors.secondaryBg,
                style: const TextStyle(color: QRHColors.textPrimary),
                decoration: const InputDecoration(
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: QRHColors.borderColor)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: QRHColors.info)),
                ),
                hint: const Text('Выберите роль...', style: TextStyle(color: QRHColors.textTertiary)),
                items: crewRoles.entries.map((entry) {
                  return DropdownMenuItem<String>(value: entry.key, child: Text(entry.value));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    newCm = value;
                  });
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => ctx.pop(false),
                  child: const Text('Отмена', style: TextStyle(color: QRHColors.info)),
                ),
                TextButton(
                  onPressed: newCm != null ? () => ctx.pop(true) : null,
                  child: Text(
                    'Добавить',
                    style: TextStyle(color: newCm != null ? QRHColors.success : QRHColors.textSecondary),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (res == true && newCm != null) {
      if (!step.crewMembers.contains(newCm!)) {
        step.crewMembers.add(newCm!);
      }

      if (step.groupNode == null) {
        final newGroup = XmlElement(XmlName('crewMemberGroup'));
        final cr = step.challengeNode?.parentElement;
        if (cr != null) {
          final responseNode = cr.children.whereType<XmlElement>().where((e) => e.name.local == 'response').firstOrNull;
          if (responseNode != null) {
            final index = cr.children.indexOf(responseNode);
            cr.children.insert(index, newGroup);
          } else {
            cr.children.add(newGroup);
          }
          step.groupNode = newGroup;
        } else {
          step.parentStepNode.children.insert(0, newGroup);
          step.groupNode = newGroup;
        }
      }

      // Check if this crewMemberType already exists in XML before adding
      final existingXmlNode = step.groupNode?.children
          .whereType<XmlElement>()
          .where((e) => e.name.local == 'crewMember' && e.getAttribute('crewMemberType') == newCm!)
          .firstOrNull;

      if (existingXmlNode == null) {
        step.groupNode?.children.add(
          XmlElement(XmlName('crewMember'), [XmlAttribute(XmlName('crewMemberType'), newCm!)]),
        );
      }

      hasChanges = true;
      notifyListeners();
    }
  }

  void deleteItem(CrewItem item) {
    if (item is CrewStep) {
      final drill = item.parentStepNode.parentElement;
      item.parentStepNode.parent?.children.remove(item.parentStepNode);
      if (drill != null && drill.findElements('crewDrillStep').isEmpty && drill.findElements('title').isEmpty) {
        drill.parent?.children.remove(drill);
      }
    } else if (item is CrewFigure) {
      final drill = item.stepNode.parentElement;
      item.stepNode.parent?.children.remove(item.stepNode);
      if (drill != null && drill.findElements('crewDrillStep').isEmpty && drill.findElements('title').isEmpty) {
        drill.parent?.children.remove(drill);
      }
    } else if (item is CrewDescription) {
      final drill = item.stepNode.parentElement;
      item.stepNode.parentElement?.children.remove(item.stepNode);
      if (drill != null && drill.findElements('crewDrillStep').isEmpty && drill.findElements('title').isEmpty) {
        drill.parent?.children.remove(drill);
      }
    } else if (item is CrewCondition) {
      final drill = item.stepNode.parentElement;
      item.stepNode.parentElement?.children.remove(item.stepNode);
      if (drill != null && drill.findElements('crewDrillStep').isEmpty && drill.findElements('title').isEmpty) {
        drill.parent?.children.remove(drill);
      }
    } else if (item is CrewHeader) {
      item.titleNode?.parent?.children.remove(item.titleNode);
    } else if (item is CrewAttention) {
      final parent = item.node.parentElement;
      item.node.parentElement?.children.remove(item.node);
      if (parent != null && parent.name.local == 'crewDrill' && parent.children.whereType<XmlElement>().isEmpty) {
        parent.parentElement?.children.remove(parent);
      }
    }
    hasChanges = true;
    parseCrewData();
  }

  void addStep(VoidCallback onAdded) {
    final drills = document.findAllElements('crewDrill');
    XmlElement? parentNode;
    if (drills.isNotEmpty) {
      parentNode = drills.last.parentElement;
    } else {
      parentNode =
          document.findAllElements('crewRefCard').firstOrNull ??
          document.findAllElements('crew').firstOrNull ??
          document.rootElement;
    }

    if (parentNode != null) {
      final newDrill = XmlElement(XmlName('crewDrill'));
      final newStep = XmlElement(XmlName('crewDrillStep'));
      final newCR = XmlElement(XmlName('challengeAndResponse'));

      final challenge = XmlElement(XmlName('challenge'), [], [
        XmlElement(XmlName('para'), [], [XmlText('Новый вызов')]),
      ]);
      final response = XmlElement(XmlName('response'), [], [
        XmlElement(XmlName('para'), [], [XmlText('Новый ответ')]),
      ]);

      newCR.children.add(challenge);
      newCR.children.add(response);
      newStep.children.add(newCR);
      newDrill.children.add(newStep);

      parentNode.children.add(newDrill);

      hasChanges = true;
      parseCrewData();
      onAdded();
    }
  }

  void addDescription(VoidCallback onAdded) {
    isEditMode = true;
    final drills = document.findAllElements('crewDrill');
    XmlElement? parentNode;
    if (drills.isNotEmpty) {
      parentNode = drills.last.parentElement;
    } else {
      parentNode =
          document.findAllElements('crewRefCard').firstOrNull ??
          document.findAllElements('crew').firstOrNull ??
          document.rootElement;
    }

    if (parentNode != null) {
      final newDrill = XmlElement(XmlName('crewDrill'));
      final newStep = XmlElement(XmlName('crewDrillStep'));
      final title = XmlElement(XmlName('title'), [], [XmlText('Заголовок описания')]);
      final para = XmlElement(XmlName('para'), [], [XmlText('Текст описания')]);

      newStep.children.add(title);
      newStep.children.add(para);
      newDrill.children.add(newStep);

      parentNode.children.add(newDrill);

      hasChanges = true;
      parseCrewData();
      onAdded();
    }
  }

  void addAttention(String type, VoidCallback onAdded) {
    isEditMode = true;
    final refCard = document.findAllElements('crewRefCard').firstOrNull;
    if (refCard != null) {
      final node = XmlElement(XmlName(type));
      if (type == 'note') {
        node.children.add(XmlElement(XmlName('notePara'), [], [XmlText('Новое примечание')]));
      } else {
        node.children.add(XmlElement(XmlName('warningAndCautionPara'), [], [XmlText('Новое сообщение')]));
      }
      final drillNode = XmlElement(XmlName('crewDrill'), [], [node]);
      refCard.children.add(drillNode);
      hasChanges = true;
      parseCrewData();
      onAdded();
    }
  }

  void addHeader(VoidCallback onAdded) {
    isEditMode = true;
    final drills = document.findAllElements('crewDrill');
    XmlElement? parentNode;
    if (drills.isNotEmpty) {
      parentNode = drills.last.parentElement;
    } else {
      parentNode =
          document.findAllElements('crewRefCard').firstOrNull ??
          document.findAllElements('crew').firstOrNull ??
          document.rootElement;
    }

    if (parentNode != null) {
      final newDrill = XmlElement(XmlName('crewDrill'));
      final title = XmlElement(XmlName('title'), [], [XmlText('Новый заголовок')]);
      newDrill.children.add(title);
      parentNode.children.add(newDrill);

      hasChanges = true;
      parseCrewData();
      onAdded();
    }
  }

  void addCondition(VoidCallback onAdded) {
    isEditMode = true;
    final drills = document.findAllElements('crewDrill');
    XmlElement? parentNode;
    if (drills.isNotEmpty) {
      parentNode = drills.last.parentElement;
    } else {
      parentNode =
          document.findAllElements('crewRefCard').firstOrNull ??
          document.findAllElements('crew').firstOrNull ??
          document.rootElement;
    }

    if (parentNode != null) {
      final newDrill = XmlElement(XmlName('crewDrill'));
      final newStep = XmlElement(XmlName('crewDrillStep'));
      final title = XmlElement(XmlName('title'), [], [XmlText('Проверка состояния системы')]);
      final para = XmlElement(XmlName('para'), [], [XmlText('Выберите состояние индикатора:')]);

      final case1 = XmlElement(XmlName('case'), [], [
        XmlElement(XmlName('caseCond'), [], [XmlText('Если индикатор горит ЗЕЛЕНЫМ:')]),
        XmlElement(XmlName('crewDrillStep'), [], [
          XmlElement(XmlName('para'), [], [XmlText('Продолжайте выполнение взлета.')]),
        ]),
      ]);

      final case2 = XmlElement(XmlName('case'), [], [
        XmlElement(XmlName('caseCond'), [], [XmlText('Если индикатор горит КРАСНЫМ:')]),
        XmlElement(XmlName('crewDrillStep'), [], [
          XmlElement(XmlName('para'), [], [XmlText('Прекратите взлет.')]),
        ]),
      ]);

      newStep.children.add(title);
      newStep.children.add(para);
      newStep.children.add(case1);
      newStep.children.add(case2);
      newDrill.children.add(newStep);

      parentNode.children.add(newDrill);

      hasChanges = true;
      parseCrewData();
      onAdded();
    }
  }

  void addConditionCase(CrewCondition item) {
    final caseNode = XmlElement(XmlName('case'), [], [
      XmlElement(XmlName('caseCond'), [], [XmlText('Новое условие')]),
      XmlElement(XmlName('crewDrillStep'), [], [
        XmlElement(XmlName('para'), [], [XmlText('Действие')]),
      ]),
    ]);
    item.stepNode.children.add(caseNode);
    hasChanges = true;
    parseCrewData();
  }

  void removeConditionCase(CrewCondition item, CrewCaseItem caseItem) {
    item.stepNode.children.remove(caseItem.caseNode);
    hasChanges = true;
    parseCrewData();
  }

  void updateConditionTitle(CrewCondition item, String newTitle) {
    item.title = newTitle;
    updateXmlNodeText(item.titleNode, newTitle);
  }

  void updateConditionText(CrewCondition item, String newText) {
    item.text = newText;
    updateXmlNodeText(item.paraNode, newText);
  }

  void updateCaseCond(CrewCaseItem caseItem, String newText) {
    caseItem.conditionText = newText;
    updateXmlNodeText(caseItem.caseCondNode, newText);
  }

  void updateCaseStepText(CrewCaseItem caseItem, String newText) {
    caseItem.stepText = newText;
    // Update both the CrewCaseItem and its associated CrewStep
    if (caseItem.asCrewStep.simpleText != null) {
      caseItem.asCrewStep.simpleText = newText;
    }
    updateXmlNodeText(caseItem.innerParaNode, newText);
  }

  void updateHeaderTitle(CrewHeader item, String newTitle) {
    item.title = newTitle;
    updateXmlNodeText(item.titleNode, newTitle);
  }

  void updateDescriptionTitle(CrewDescription item, String newTitle) {
    item.title = newTitle;
    updateXmlNodeText(item.titleNode, newTitle);
  }

  void reorderItem(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    if (oldIndex == newIndex) return;

    final itemToMove = items[oldIndex];
    items.removeAt(oldIndex);
    items.insert(newIndex, itemToMove);

    // Определяем DOM узел, который нужно переместить
    XmlNode? nodeToMove;
    if (itemToMove is CrewStep) {
      nodeToMove = itemToMove.parentStepNode;
    } else if (itemToMove is CrewDescription) {
      nodeToMove = itemToMove.stepNode;
    } else if (itemToMove is CrewCondition) {
      nodeToMove = itemToMove.stepNode;
    } else if (itemToMove is CrewAttention) {
      nodeToMove = itemToMove.node;
    } else if (itemToMove is CrewHeader) {
      nodeToMove = itemToMove.titleNode;
    }

    if (nodeToMove != null && nodeToMove.parent != null) {
      // Удаляем из текущего места в DOM
      nodeToMove.parent!.children.remove(nodeToMove);

      // Ищем ближайший элемент ПОСЛЕ нового индекса, чтобы вставить перед ним
      XmlNode? targetNode;
      for (int i = newIndex + 1; i < items.length; i++) {
        final nextItem = items[i];
        if (nextItem is CrewStep) {
          targetNode = nextItem.parentStepNode;
        } else if (nextItem is CrewDescription) {
          targetNode = nextItem.stepNode;
        } else if (nextItem is CrewCondition) {
          targetNode = nextItem.stepNode;
        } else if (nextItem is CrewAttention) {
          targetNode = nextItem.node;
        } else if (nextItem is CrewHeader) {
          targetNode = nextItem.titleNode;
        }

        if (targetNode != null) break;
      }

      if (targetNode != null && targetNode.parent != null) {
        // Вставляем перед найденным targetNode
        final parent = targetNode.parent!;
        final index = parent.children.indexOf(targetNode);
        if (index != -1) {
          parent.children.insert(index, nodeToMove);
        } else {
          parent.children.add(nodeToMove);
        }
      } else {
        // Если элемента после нет, значит это конец списка. Вставляем в конец последнего drill.
        final drills = document.findAllElements('crewDrill');
        if (drills.isNotEmpty) {
          drills.last.children.add(nodeToMove);
        } else {
          document.rootElement.children.add(nodeToMove);
        }
      }

      hasChanges = true;
      notifyListeners();
    }
  }

  void updateDescriptionText(CrewDescription item, String newText) {
    item.text = newText;
    updateXmlNodeText(item.paraNode, newText);
  }

  void updateFigureTitle(CrewFigure item, String newTitle) {
    item.title = newTitle;
    updateXmlNodeText(item.titleNode, newTitle);
  }

  void updateReferenceText(CrewStep step, String newText) {
    step.referenceText = newText;
    final paraNode = step.dmRefNode?.parentElement;
    if (paraNode != null) {
      final dmRef = step.dmRefNode!;
      paraNode.children.clear();
      paraNode.children.add(XmlText(newText));
      paraNode.children.add(dmRef);
      hasChanges = true;
      notifyListeners();
    }
  }

  Future<void> addReference(BuildContext context, VoidCallback onAdded) async {
    final appCtrl = context.read<AppController>();
    if (appCtrl.workDir == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Проект не открыт.'), backgroundColor: QRHColors.danger));
      return;
    }

    // Покажем лоадер, пока собираем инфу о файлах
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    final entities = await appCtrl.workDir!.list().toList();
    final xmlFiles = entities.whereType<File>().where((f) => f.path.toLowerCase().endsWith('.xml')).toList();

    List<Map<String, dynamic>> fileData = [];
    for (var file in xmlFiles) {
      final fileName = file.uri.pathSegments.last;
      if (!fileName.toUpperCase().startsWith('DMC-')) continue;

      String infoName = 'Без названия';
      try {
        final content = await file.readAsString();
        final match = RegExp(r'<infoName[^>]*>(.*?)</infoName>', dotAll: true).firstMatch(content);
        if (match != null && match.group(1) != null) {
          infoName = match.group(1)!.trim();
        } else {
          final doc = XmlDocument.parse(content);
          final infoNameNode = doc.findAllElements('infoName').firstOrNull;
          if (infoNameNode != null) {
            infoName = infoNameNode.innerText.trim();
          }
        }
      } catch (_) {}

      fileData.add({'file': file, 'fileName': fileName, 'infoName': infoName});
    }

    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop(); // Закрываем лоадер
    } else {
      return;
    }

    File? selectedFile;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: QRHColors.secondaryBg,
        title: const Text('Выберите файл для ссылки', style: TextStyle(color: QRHColors.textPrimary)),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: fileData.length,
            itemBuilder: (context, index) {
              final data = fileData[index];
              return ListTile(
                title: Text(
                  data['infoName'],
                  style: const TextStyle(color: QRHColors.textPrimary, fontWeight: FontWeight.w500),
                ),
                subtitle: Text(data['fileName'], style: const TextStyle(color: QRHColors.textTertiary, fontSize: 12)),
                onTap: () {
                  selectedFile = data['file'];
                  Navigator.of(ctx).pop();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Отмена', style: TextStyle(color: QRHColors.danger)),
          ),
        ],
      ),
    );

    if (selectedFile == null) return;

    try {
      final content = await selectedFile!.readAsString();
      final dmDoc = XmlDocument.parse(content);
      final dmIdent = dmDoc.findAllElements('dmIdent').firstOrNull;
      final dmTitle = dmDoc.findAllElements('dmTitle').firstOrNull;

      if (dmIdent != null) {
        final dmCode = dmIdent.findElements('dmCode').firstOrNull;

        final dmRef = XmlElement(XmlName('dmRef'), [], [
          XmlElement(XmlName('dmRefIdent'), [], [
            if (dmCode != null) dmCode.copy(),
            if (dmIdent.findElements('issueInfo').isNotEmpty) dmIdent.findElements('issueInfo').first.copy(),
            if (dmIdent.findElements('language').isNotEmpty) dmIdent.findElements('language').first.copy(),
          ]),
          XmlElement(XmlName('dmRefAddressItems'), [], [if (dmTitle != null) dmTitle.copy()]),
        ]);

        final drills = document.findAllElements('crewDrill');
        XmlElement? parentNode;
        if (drills.isNotEmpty) {
          parentNode = drills.last.parentElement;
        } else {
          parentNode =
              document.findAllElements('crewRefCard').firstOrNull ??
              document.findAllElements('crew').firstOrNull ??
              document.rootElement;
        }

        if (parentNode != null) {
          final newDrill = XmlElement(XmlName('crewDrill'));
          final newStep = XmlElement(XmlName('crewDrillStep'));
          final para = XmlElement(XmlName('para'), [], [
            XmlText('Для получения дополнительной информации см. '),
            dmRef,
          ]);

          newStep.children.add(para);
          newDrill.children.add(newStep);
          parentNode.children.add(newDrill);

          hasChanges = true;
          parseCrewData();
          onAdded();
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка чтения файла: $e'), backgroundColor: QRHColors.danger));
      }
    }
  }

  Future<void> addFigure(BuildContext context, VoidCallback onAdded) async {
    final appCtrl = context.read<AppController>();
    if (appCtrl.workDir == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Проект не открыт.'), backgroundColor: QRHColors.danger));
      return;
    }

    try {
      final result = await FilePicker.pickFiles(type: FileType.image, allowMultiple: false);

      if (result != null && result.files.single.path != null) {
        final sourceFile = File(result.files.single.path!);

        // Генерация ICN имени
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final extension = sourceFile.path.split('.').last.toUpperCase();
        // Используем префикс модели из настроек проекта
        final icn = 'ICN-${appCtrl.modelIdentCode}-AAA-DA00000-A-00000-00000-A-$timestamp-01';
        final newFileName = '$icn.$extension';

        final destinationPath = '${appCtrl.workDir!.path}/$newFileName';
        await sourceFile.copy(destinationPath);

        // Добавление в XML
        final drills = document.findAllElements('crewDrill');
        XmlElement? parentNode;
        if (drills.isNotEmpty) {
          parentNode = drills.last.parentElement;
        } else {
          parentNode =
              document.findAllElements('crewRefCard').firstOrNull ??
              document.findAllElements('crew').firstOrNull ??
              document.rootElement;
        }

        if (parentNode != null) {
          final newDrill = XmlElement(XmlName('crewDrill'));
          final newStep = XmlElement(XmlName('crewDrillStep'));

          final figureNode = XmlElement(XmlName('figure'), [], [
            XmlElement(XmlName('title'), [], [XmlText('Новое изображение')]),
            XmlElement(XmlName('graphic'), [
              XmlAttribute(XmlName('infoEntityIdent'), icn),
              XmlAttribute(XmlName('reproductionHeight'), '100mm'),
              XmlAttribute(XmlName('reproductionWidth'), '150mm'),
            ]),
          ]);

          newStep.children.add(figureNode);
          newDrill.children.add(newStep);
          parentNode.children.add(newDrill);

          hasChanges = true;
          parseCrewData();
          onAdded();
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка вставки изображения: $e'), backgroundColor: QRHColors.danger));
      }
    }
  }

  void updateAttentionText(CrewAttention item, String newText) {
    item.text = newText;
    updateXmlNodeText(item.node, newText);
  }

  void updateStepChallenge(CrewStep step, String newText) {
    step.challenge = newText;
    updateXmlNodeText(step.challengeNode, newText);
  }

  void updateStepResponse(CrewStep step, String newText) {
    step.response = newText;
    updateXmlNodeText(step.responseNode, newText);
  }

  void updateSimpleText(CrewStep step, String newText) {
    step.simpleText = newText;
    // If this step is inside a case, also update the case's stepText
    if (step.parentCaseItem != null) {
      step.parentCaseItem!.stepText = newText;
    }
    updateXmlNodeText(step.parentStepNode, newText);
  }

  void update() {
    notifyListeners();
  }
}
