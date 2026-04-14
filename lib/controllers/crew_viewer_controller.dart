import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:xml/xml.dart';
import 'package:go_router/go_router.dart';
import '../styles.dart';
import '../ui/viewers/models/crew_models.dart';

class CrewViewerController extends ChangeNotifier {
  final XmlDocument document;
  final String fileName;
  final String? filePath;
  final String? fileTitle;

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
            final paraNode = child.findAllElements(type == 'note' ? 'notePara' : 'warningAndCautionPara').firstOrNull;
            final text = cleanText(paraNode?.innerText ?? child.innerText);
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
            final paraNode = child.findAllElements(type == 'note' ? 'notePara' : 'warningAndCautionPara').firstOrNull;
            final text = cleanText(paraNode?.innerText ?? child.innerText);
            items.add(CrewAttention(type: type, text: text, node: child));
          }
        }
      }

      final steps = drill.findAllElements('crewDrillStep');
      for (var step in steps) {
        final cr = step.findAllElements('challengeAndResponse').firstOrNull;

        if (cr != null) {
          final challengeNode = cr.findAllElements('challenge').firstOrNull;
          final responseNode = cr.findAllElements('response').firstOrNull;
          final challenge = cleanText(challengeNode?.innerText ?? '');
          final response = cleanText(responseNode?.innerText ?? '');

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
          final simpleText = cleanText(step.innerText);
          if (simpleText.isNotEmpty) {
            items.add(
              CrewStep(
                challenge: '',
                response: '',
                simpleText: simpleText,
                crewMembers: [],
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
    notifyListeners();
  }

  String cleanText(String text) {
    return text.trim().replaceAll(RegExp(r'\s+'), ' ');
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
    final para = node.findAllElements('para').firstOrNull;
    if (para != null) {
      para.children.clear();
      para.children.add(XmlText(newText));
    } else {
      if (node.name.local == 'title' || node.name.local == 'name') {
        node.children.clear();
        node.children.add(XmlText(newText));
      } else {
        node.children.clear();
        node.children.add(XmlElement(XmlName('para'), [], [XmlText(newText)]));
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
      step.crewMembers.add(newCm!);

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
        }
      }

      step.groupNode?.children.add(
        XmlElement(XmlName('crewMember'), [XmlAttribute(XmlName('crewMemberType'), newCm!)]),
      );

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

  void addStep() {
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
    }
  }

  void addAttention(String type) {
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
    }
  }

  void addHeader() {
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
    }
  }

  void updateHeaderTitle(CrewHeader item, String newTitle) {
    item.title = newTitle;
    updateXmlNodeText(item.titleNode, newTitle);
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

  void update() {
    notifyListeners();
  }
}
