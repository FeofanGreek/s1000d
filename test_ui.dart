import 'dart:io';
import 'package:xml/xml.dart';

void main() {
  final file = File('/Users/koldashev/gazprom/output_xml/PMC-MI171A3-GAZPROM-00001-00_001-00_ru-RU.xml');
  final doc = XmlDocument.parse(file.readAsStringSync());
  
  final contentNode = doc.findAllElements('content').first;
  
  for (var node in contentNode.children.whereType<XmlElement>()) {
    if (node.name.local == 'pmEntry') {
      final children = node.children
          .whereType<XmlElement>()
          .where((e) => e.name.local != 'pmEntryTitle')
          .toList();
      
      print('pmEntry Title: ${node.findElements('pmEntryTitle').firstOrNull?.innerText}');
      print('Children count to process: ${children.length}');
      
      for (var child in children) {
        if (child.name.local == 'dmRef') {
          final dmCode = child.findAllElements('dmCode').firstOrNull;
          if (dmCode == null) {
            print('dmCode is null!');
            continue;
          }
          final model = dmCode.getAttribute('modelIdentCode') ?? '';
          final ic = dmCode.getAttribute('infoCode') ?? '';
          final prefix = 'DMC-$model-...-$ic-...XML';
          
          final techName = child.findAllElements('techName').firstOrNull?.innerText;
          final infoName = child.findAllElements('infoName').firstOrNull?.innerText;
          
          final titleParts = [techName, infoName].where((e) => e != null && e.isNotEmpty).toList();
          final title = titleParts.join(' - ');
          print('  -> RENDER dmRef: title="$title" prefix="$prefix"');
        } else {
          print('  -> RENDER other: ${child.name.local}');
        }
      }
    }
  }
}
