import 'dart:io';
import 'package:xml/xml.dart';

void main() {
  final file = File('/Users/koldashev/gazprom/output_xml/PMC-MI171A3-GAZPROM-00001-00_001-00_ru-RU.xml');
  final doc = XmlDocument.parse(file.readAsStringSync());
  
  final contentNode = doc.findAllElements('content').first;
  print('Content children count: ${contentNode.children.whereType<XmlElement>().length}');
  
  for (var node in contentNode.children.whereType<XmlElement>()) {
    print('Node: ${node.name.local}');
    if (node.name.local == 'pmEntry') {
      final children = node.children.whereType<XmlElement>();
      print('  pmEntry children count: ${children.length}');
      for (var child in children) {
        if (child.name.local == 'dmRef') {
            final dmCode = child.findAllElements('dmCode').firstOrNull;
            print('    dmRef has dmCode: ${dmCode != null}');
            final techName = child.findAllElements('techName').firstOrNull?.innerText;
            final infoName = child.findAllElements('infoName').firstOrNull?.innerText;
            print('    techName: $techName, infoName: $infoName');
        } else {
            print('    Child: ${child.name.local}');
        }
      }
    }
  }
}
