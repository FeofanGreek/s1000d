import 'package:xml/xml.dart';

abstract class CrewItem {}

class CrewHeader extends CrewItem {
  String title;
  final XmlElement? titleNode;
  CrewHeader(this.title, {this.titleNode});
}

class CrewAttention extends CrewItem {
  final String type; // 'warning', 'caution', 'note'
  String text;
  final XmlElement node;

  CrewAttention({required this.type, required this.text, required this.node});
}

class CrewStep extends CrewItem {
  String challenge;
  String response;
  String? simpleText;
  String? referenceText;
  XmlElement? dmRefNode;
  List<String> crewMembers;
  int stateIndex;

  final XmlElement? challengeNode;
  final XmlElement? responseNode;
  XmlElement? groupNode;
  final XmlElement parentStepNode;

  CrewStep({
    required this.challenge,
    required this.response,
    this.simpleText,
    this.referenceText,
    this.dmRefNode,
    required this.crewMembers,
    required this.stateIndex,
    this.challengeNode,
    this.responseNode,
    this.groupNode,
    required this.parentStepNode,
  });
}
