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

  /// Reference to parent CrewCondition if this step is inside a case
  CrewCondition? parentCondition;

  /// Reference to CrewCaseItem if this step is inside a case
  CrewCaseItem? parentCaseItem;

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
    this.parentCondition,
    this.parentCaseItem,
  });
}

class CrewDescription extends CrewItem {
  String title;
  String text;
  final XmlElement stepNode;
  final XmlElement? titleNode;
  final XmlElement? paraNode;

  CrewDescription({required this.title, required this.text, required this.stepNode, this.titleNode, this.paraNode});
}

class CrewCondition extends CrewItem {
  String title;
  String text;
  final XmlElement stepNode;
  final XmlElement? titleNode;
  final XmlElement? paraNode;
  final List<CrewCaseItem> cases;

  CrewCondition({
    required this.title,
    required this.text,
    required this.stepNode,
    this.titleNode,
    this.paraNode,
    required this.cases,
  });
}

class CrewFigure extends CrewItem {
  String title;
  String infoEntityIdent;
  final XmlElement stepNode;
  final XmlElement figureNode;
  final XmlElement graphicNode;
  final XmlElement? titleNode;

  CrewFigure({
    required this.title,
    required this.infoEntityIdent,
    required this.stepNode,
    required this.figureNode,
    required this.graphicNode,
    this.titleNode,
  });
}

class CrewCaseItem {
  String conditionText;
  String stepText;
  final XmlElement caseNode;
  final XmlElement caseCondNode;
  final XmlElement innerStepNode;
  final XmlElement? innerParaNode;

  /// CrewStep representation of this case's action (stepText part)
  late CrewStep asCrewStep;

  CrewCaseItem({
    required this.conditionText,
    required this.stepText,
    required this.caseNode,
    required this.caseCondNode,
    required this.innerStepNode,
    this.innerParaNode,
  });
}
