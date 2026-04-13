import 'package:xml/xml.dart';

class _ExtractedPara {
  final String text;
  final int linesConsumed;
  _ExtractedPara(this.text, this.linesConsumed);
}

class S1000DMdParser {
  /// Парсит содержимое Markdown файла и возвращает структуру <content> для S1000D crewDrill
  static XmlElement parseToCrewContent(String markdownContent, String title) {
    final lines = markdownContent.split('\n');
    final contentElement = XmlElement(XmlName('content'));
    final crewElement = XmlElement(XmlName('crew'));
    final crewRefCardElement = XmlElement(XmlName('crewRefCard'));

    crewRefCardElement.children.add(XmlElement(XmlName('title'), [], [XmlText(title)]));

    XmlElement? currentDrill;
    XmlElement? currentTable;

    for (int i = 0; i < lines.length; i++) {
      var line = lines[i].trim();
      if (line.isEmpty) continue;

      if (line.startsWith('# ')) {
        // Мы уже берем title из первого заголовка для infoName,
        // но если в файле есть еще '# ' - обновим title самого crewRefCard.
        final parsedTitle = line.substring(2).trim();
        final titleNodes = crewRefCardElement.findElements('title');
        if (titleNodes.isNotEmpty) {
          titleNodes.first.children.clear();
          titleNodes.first.children.add(XmlText(parsedTitle));
        }
      } else if (line.startsWith('## ')) {
        // Заголовок 2 уровня - новый crewDrill
        currentDrill = XmlElement(XmlName('crewDrill'));
        currentDrill.children.add(XmlElement(XmlName('title'), [], [XmlText(line.substring(3).trim())]));
        crewRefCardElement.children.add(currentDrill);
      } else if (line.startsWith('***Примечание***')) {
        final notePara = _extractParaBlock(lines, i + 1);
        final note = XmlElement(XmlName('note'), [], [
          XmlElement(XmlName('notePara'), [], [XmlText(notePara.text)])
        ]);
        crewRefCardElement.children.add(XmlElement(XmlName('crewDrill'), [], [note]));
        i += notePara.linesConsumed;
      } else if (line.startsWith('***Внимание***')) {
        final warnPara = _extractParaBlock(lines, i + 1);
        final warn = XmlElement(XmlName('warning'), [], [
          XmlElement(XmlName('warningAndCautionPara'), [], [XmlText(warnPara.text)])
        ]);
        crewRefCardElement.children.add(XmlElement(XmlName('crewDrill'), [], [warn]));
        i += warnPara.linesConsumed;
      } else if (line.startsWith('***Осторожно***')) {
        final cautionPara = _extractParaBlock(lines, i + 1);
        final caution = XmlElement(XmlName('caution'), [], [
          XmlElement(XmlName('warningAndCautionPara'), [], [XmlText(cautionPara.text)])
        ]);
        crewRefCardElement.children.add(XmlElement(XmlName('crewDrill'), [], [caution]));
        i += cautionPara.linesConsumed;
      } else if (line.startsWith('|') && line.endsWith('|')) {
        // Строка таблицы
        if (line.contains('---')) {
          continue; // Разделитель таблицы
        }

        final columns = line.split('|').map((e) => e.trim()).toList();
        // columns[0] is empty because line starts with '|'
        // columns.last is empty because line ends with '|'
        
        // Header
        if (columns.length > 2 && columns[1].toLowerCase().contains('challenge')) {
          continue; // Пропускаем строку заголовков
        }

        if (columns.length >= 3) {
          if (currentDrill == null) {
            currentDrill = XmlElement(XmlName('crewDrill'));
            crewRefCardElement.children.add(currentDrill);
          }

          final stepElement = XmlElement(XmlName('crewDrillStep'));
          final crElement = XmlElement(XmlName('challengeAndResponse'));

          final challengeText = columns[1];
          final responseText = columns[2];

          crElement.children.add(XmlElement(XmlName('challenge'), [], [
            XmlElement(XmlName('para'), [], [XmlText(challengeText)])
          ]));

          final groupElement = XmlElement(XmlName('crewMemberGroup'));
          bool hasRoles = false;
          
          for (int colIndex = 3; colIndex < columns.length - 1; colIndex++) {
            final cellText = columns[colIndex];
            if (cellText.isNotEmpty) {
              hasRoles = true;
              final roleType = 'cm0$cellText'; // Если в ячейке "1", будет "cm01"
              groupElement.children.add(XmlElement(XmlName('crewMember'), [
                XmlAttribute(XmlName('crewMemberType'), roleType.length > 4 ? 'cm01' : roleType)
              ]));
            }
          }

          if (hasRoles) {
            crElement.children.add(groupElement);
          }

          if (responseText.isNotEmpty) {
            crElement.children.add(XmlElement(XmlName('response'), [], [
              XmlElement(XmlName('para'), [], [XmlText(responseText)])
            ]));
          }

          stepElement.children.add(crElement);
          currentDrill.children.add(stepElement);
        }
      } else {
        // Обычный текст - параграф в текущем drill
        if (currentDrill == null) {
          currentDrill = XmlElement(XmlName('crewDrill'));
          crewRefCardElement.children.add(currentDrill);
        }
        final stepElement = XmlElement(XmlName('crewDrillStep'));
        stepElement.children.add(XmlElement(XmlName('para'), [], [XmlText(line)]));
        currentDrill.children.add(stepElement);
      }
    }

    crewElement.children.add(crewRefCardElement);
    contentElement.children.add(crewElement);
    return contentElement;
  }

  /// Парсит содержимое Markdown файла и возвращает структуру <content> для S1000D description
  static XmlElement parseToDescriptionContent(String markdownContent, String title) {
    final lines = markdownContent.split('\n');
    final contentElement = XmlElement(XmlName('content'));
    final descElement = XmlElement(XmlName('description'));

    XmlElement? currentL0Para;
    XmlElement? currentL1Para;
    XmlElement? currentList;
    XmlElement? currentPara;

    // Утилита для получения текущего родителя для элементов
    XmlElement getCurrentParent() {
      return currentL1Para ?? currentL0Para ?? descElement;
    }

    for (int i = 0; i < lines.length; i++) {
      var line = lines[i].trim();
      if (line.isEmpty) {
        currentList = null; // сброс списка при пустой строке
        currentPara = null;
        continue;
      }

      if (line.startsWith('# ')) {
        currentL0Para = XmlElement(XmlName('levelledPara'));
        currentL0Para.children.add(XmlElement(XmlName('title'), [], [XmlText(line.substring(2).trim())]));
        descElement.children.add(currentL0Para);
        currentL1Para = null;
        currentList = null;
        currentPara = null;
      } else if (line.startsWith('## ')) {
        currentL1Para = XmlElement(XmlName('levelledPara'));
        currentL1Para.children.add(XmlElement(XmlName('title'), [], [XmlText(line.substring(3).trim())]));
        if (currentL0Para != null) {
          currentL0Para.children.add(currentL1Para);
        } else {
          descElement.children.add(currentL1Para);
        }
        currentList = null;
        currentPara = null;
      } else if (line.startsWith('***Примечание***')) {
        final notePara = _extractParaBlock(lines, i + 1);
        final note = XmlElement(XmlName('note'), [], [
          XmlElement(XmlName('notePara'), [], [XmlText(notePara.text)])
        ]);
        getCurrentParent().children.add(note);
        i += notePara.linesConsumed;
        currentList = null;
        currentPara = null;
      } else if (line.startsWith('***Внимание***')) {
        final warnPara = _extractParaBlock(lines, i + 1);
        final warn = XmlElement(XmlName('warning'), [], [
          XmlElement(XmlName('warningAndCautionPara'), [], [XmlText(warnPara.text)])
        ]);
        getCurrentParent().children.add(warn);
        i += warnPara.linesConsumed;
        currentList = null;
        currentPara = null;
      } else if (line.startsWith('***Осторожно***')) {
        final cautionPara = _extractParaBlock(lines, i + 1);
        final caution = XmlElement(XmlName('caution'), [], [
          XmlElement(XmlName('warningAndCautionPara'), [], [XmlText(cautionPara.text)])
        ]);
        getCurrentParent().children.add(caution);
        i += cautionPara.linesConsumed;
        currentList = null;
        currentPara = null;
      } else if (line.startsWith('- ') || line.startsWith('* ')) {
        if (currentList == null) {
          currentList = XmlElement(XmlName('sequentialList'));
          currentPara = XmlElement(XmlName('para'));
          currentPara.children.add(currentList);
          getCurrentParent().children.add(currentPara);
        }
        final itemText = line.substring(2).trim();
        currentList.children.add(
          XmlElement(XmlName('listItem'), [], [
            XmlElement(XmlName('para'), [], [XmlText(itemText)])
          ])
        );
      } else {
        // Обычный текст - параграф в текущем parent
        final p = XmlElement(XmlName('para'), [], [XmlText(line)]);
        getCurrentParent().children.add(p);
        currentList = null;
        currentPara = null;
      }
    }

    contentElement.children.add(descElement);
    return contentElement;
  }
  static _ExtractedPara _extractParaBlock(List<String> lines, int startIndex) {
    String text = '';
    int linesConsumed = 0;
    for (int i = startIndex; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        linesConsumed++;
        continue; // skip empty lines between header and text
      }
      if (line.startsWith('#') || line.startsWith('|') || line.startsWith('***')) {
        break; // New section
      }
      text += (text.isEmpty ? '' : ' ') + line;
      linesConsumed++;
      // Stop after parsing one block of text? The standard allows multiple lines,
      // but usually these notes are short blocks. Let's assume one paragraph.
      break; 
    }
    return _ExtractedPara(text, linesConsumed);
  }

}
