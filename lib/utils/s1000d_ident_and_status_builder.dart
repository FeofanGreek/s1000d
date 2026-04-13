import 'package:xml/xml.dart' as xml;

/// Класс для работы с identAndStatusSection в S1000D документах
class S1000DIdentAndStatusBuilder {
  // DMCode параметры
  final String modelIdentCode;
  final String systemDiffCode;
  final String systemCode;
  final String subSystemCode;
  final String subSubSystemCode;
  final String assyCode;
  final String disassyCode;
  final String disassyCodeVariant;
  final String infoCode;
  final String infoCodeVariant;
  final String itemLocationCode;

  // Language параметры
  final String languageCountryIsoCode;
  final String languageIsoCode;

  // Issue Info параметры
  final String issueNumber;
  final String inWork;

  // Issue Date параметры
  final String issueYear;
  final String issueMonth;
  final String issueDay;

  // Title параметры
  final String techName;
  final String infoName;

  // DM Status параметры
  final String issueType;
  final String securityClassification;

  // Data Restrictions параметры
  final String dataDistribution;
  final String copyrightPara;

  // Partner Company параметры
  final String partnerEnterpriseCode;
  final String partnerEnterpriseName;

  // Originator параметры
  final String originatorEnterpriseCode;
  final String originatorEnterpriseName;

  // Applic параметры
  final String applicText;

  // BREX DM Ref параметры
  final String brexRefModelIdentCode;
  final String brexRefSystemDiffCode;
  final String brexRefSystemCode;
  final String brexRefSubSystemCode;
  final String brexRefSubSubSystemCode;
  final String brexRefAssyCode;
  final String brexRefDisassyCode;
  final String brexRefDisassyCodeVariant;
  final String brexRefInfoCode;
  final String brexRefInfoCodeVariant;
  final String brexRefItemLocationCode;
  final String? brexRefHref;

  // Quality Assurance параметры
  final String verificationType;

  // Skill Level параметры
  final String skillLevelCode;

  S1000DIdentAndStatusBuilder({
    required this.modelIdentCode,
    required this.systemDiffCode,
    required this.systemCode,
    this.subSystemCode = '0',
    this.subSubSystemCode = '0',
    this.assyCode = '00',
    this.disassyCode = '00',
    required this.disassyCodeVariant,
    required this.infoCode,
    required this.infoCodeVariant,
    required this.itemLocationCode,
    this.languageCountryIsoCode = 'RU',
    this.languageIsoCode = 'ru',
    required this.issueNumber,
    this.inWork = '00',
    required this.issueYear,
    required this.issueMonth,
    required this.issueDay,
    required this.techName,
    required this.infoName,
    this.issueType = 'new',
    this.securityClassification = '01',
    required this.dataDistribution,
    required this.copyrightPara,
    required this.partnerEnterpriseCode,
    required this.partnerEnterpriseName,
    required this.originatorEnterpriseCode,
    required this.originatorEnterpriseName,
    required this.applicText,
    required this.brexRefModelIdentCode,
    required this.brexRefSystemDiffCode,
    required this.brexRefSystemCode,
    required this.brexRefInfoCode,
    required this.brexRefInfoCodeVariant,
    required this.brexRefItemLocationCode,
    this.brexRefHref,
    this.brexRefSubSystemCode = '0',
    this.brexRefSubSubSystemCode = '0',
    this.brexRefAssyCode = '00',
    this.brexRefDisassyCode = '00',
    this.brexRefDisassyCodeVariant = 'AA',
    this.verificationType = 'tabtop',
    this.skillLevelCode = 'sk01',
  });

  /// Формирует строку базового имени DM (например: DMC-MI171A3-AAA-D00-00-00-00AA-002A-A)
  static String buildDmCodeString({
    required String modelIdentCode,
    required String systemDiffCode,
    required String systemCode,
    String subSystemCode = '0',
    String subSubSystemCode = '0',
    String assyCode = '00',
    String disassyCode = '00',
    required String disassyCodeVariant,
    required String infoCode,
    required String infoCodeVariant,
    required String itemLocationCode,
  }) {
    return 'DMC-$modelIdentCode-$systemDiffCode-$systemCode-$subSystemCode$subSubSystemCode-$assyCode-$disassyCode$disassyCodeVariant-$infoCode$infoCodeVariant-$itemLocationCode';
  }

  /// Фабрика для получения имени файла с учетом версии и языка (например: DMC-MI171A3-AAA-D00-00-00-00AA-002A-A_001-00_ru-RU.XML)
  String getFileName() {
    final dmCodeStr = buildDmCodeString(
      modelIdentCode: modelIdentCode,
      systemDiffCode: systemDiffCode,
      systemCode: systemCode,
      subSystemCode: subSystemCode,
      subSubSystemCode: subSubSystemCode,
      assyCode: assyCode,
      disassyCode: disassyCode,
      disassyCodeVariant: disassyCodeVariant,
      infoCode: infoCode,
      infoCodeVariant: infoCodeVariant,
      itemLocationCode: itemLocationCode,
    );
    return '${dmCodeStr}_${issueNumber}-${inWork}_${languageIsoCode}-${languageCountryIsoCode}.XML';
  }

  /// Автогенерация URN для BREX
  String get computedBrexRefHref {
    if (brexRefHref != null && brexRefHref!.isNotEmpty) {
      return brexRefHref!;
    }
    final brexDmCode = buildDmCodeString(
      modelIdentCode: brexRefModelIdentCode,
      systemDiffCode: brexRefSystemDiffCode,
      systemCode: brexRefSystemCode,
      subSystemCode: brexRefSubSystemCode,
      subSubSystemCode: brexRefSubSubSystemCode,
      assyCode: brexRefAssyCode,
      disassyCode: brexRefDisassyCode,
      disassyCodeVariant: brexRefDisassyCodeVariant,
      infoCode: brexRefInfoCode,
      infoCodeVariant: brexRefInfoCodeVariant,
      itemLocationCode: brexRefItemLocationCode,
    );
    return 'URN:S1000D:$brexDmCode';
  }

  /// Метод для сборки XML из параметров
  xml.XmlElement build() {
    return xml.XmlElement(
      xml.XmlName('identAndStatusSection'),
      [],
      [
        _buildDmAddress(),
        _buildDmStatus(),
      ],
    );
  }

  /// Построить dmAddress элемент
  xml.XmlElement _buildDmAddress() {
    return xml.XmlElement(
      xml.XmlName('dmAddress'),
      [],
      [
        _buildDmIdent(),
        _buildDmAddressItems(),
      ],
    );
  }

  /// Построить dmIdent элемент
  xml.XmlElement _buildDmIdent() {
    return xml.XmlElement(
      xml.XmlName('dmIdent'),
      [],
      [
        _buildDmCode(
          modelIdentCode,
          systemDiffCode,
          systemCode,
          subSystemCode,
          subSubSystemCode,
          assyCode,
          disassyCode,
          disassyCodeVariant,
          infoCode,
          infoCodeVariant,
          itemLocationCode,
        ),
        _buildLanguage(),
        _buildIssueInfo(),
      ],
    );
  }

  /// Построить dmCode элемент
  xml.XmlElement _buildDmCode(
    String modelCode,
    String sysDiffCode,
    String sysCode,
    String subSysCode,
    String subSubSysCode,
    String assyCode,
    String disAssyCode,
    String disAssyCodeVar,
    String infCode,
    String infCodeVar,
    String itemLocCode,
  ) {
    return xml.XmlElement(
      xml.XmlName('dmCode'),
      [
        xml.XmlAttribute(xml.XmlName('modelIdentCode'), modelCode),
        xml.XmlAttribute(xml.XmlName('systemDiffCode'), sysDiffCode),
        xml.XmlAttribute(xml.XmlName('systemCode'), sysCode),
        xml.XmlAttribute(xml.XmlName('subSystemCode'), subSysCode),
        xml.XmlAttribute(xml.XmlName('subSubSystemCode'), subSubSysCode),
        xml.XmlAttribute(xml.XmlName('assyCode'), assyCode),
        xml.XmlAttribute(xml.XmlName('disassyCode'), disAssyCode),
        xml.XmlAttribute(xml.XmlName('disassyCodeVariant'), disAssyCodeVar),
        xml.XmlAttribute(xml.XmlName('infoCode'), infCode),
        xml.XmlAttribute(xml.XmlName('infoCodeVariant'), infCodeVar),
        xml.XmlAttribute(xml.XmlName('itemLocationCode'), itemLocCode),
      ],
    );
  }

  /// Построить language элемент
  xml.XmlElement _buildLanguage() {
    return xml.XmlElement(
      xml.XmlName('language'),
      [
        xml.XmlAttribute(xml.XmlName('countryIsoCode'), languageCountryIsoCode),
        xml.XmlAttribute(xml.XmlName('languageIsoCode'), languageIsoCode),
      ],
    );
  }

  /// Построить issueInfo элемент
  xml.XmlElement _buildIssueInfo() {
    return xml.XmlElement(
      xml.XmlName('issueInfo'),
      [
        xml.XmlAttribute(xml.XmlName('issueNumber'), issueNumber),
        xml.XmlAttribute(xml.XmlName('inWork'), inWork),
      ],
    );
  }

  /// Построить dmAddressItems элемент
  xml.XmlElement _buildDmAddressItems() {
    return xml.XmlElement(
      xml.XmlName('dmAddressItems'),
      [],
      [
        xml.XmlElement(
          xml.XmlName('issueDate'),
          [
            xml.XmlAttribute(xml.XmlName('year'), issueYear),
            xml.XmlAttribute(xml.XmlName('month'), issueMonth),
            xml.XmlAttribute(xml.XmlName('day'), issueDay),
          ],
        ),
        _buildDmTitle(),
      ],
    );
  }

  /// Построить dmTitle элемент
  xml.XmlElement _buildDmTitle() {
    return xml.XmlElement(
      xml.XmlName('dmTitle'),
      [],
      [
        xml.XmlElement(
          xml.XmlName('techName'),
          [],
          [xml.XmlText(techName)],
        ),
        xml.XmlElement(
          xml.XmlName('infoName'),
          [],
          [xml.XmlText(infoName)],
        ),
      ],
    );
  }

  /// Построить dmStatus элемент
  xml.XmlElement _buildDmStatus() {
    return xml.XmlElement(
      xml.XmlName('dmStatus'),
      [xml.XmlAttribute(xml.XmlName('issueType'), issueType)],
      [
        _buildSecurity(),
        _buildDataRestrictions(),
        _buildResponsiblePartnerCompany(),
        _buildOriginator(),
        _buildApplic(),
        _buildBrexDmRef(),
        _buildQualityAssurance(),
        _buildSkillLevel(),
      ],
    );
  }

  /// Построить security элемент
  xml.XmlElement _buildSecurity() {
    return xml.XmlElement(
      xml.XmlName('security'),
      [
        xml.XmlAttribute(
          xml.XmlName('securityClassification'),
          securityClassification,
        ),
      ],
    );
  }

  /// Построить dataRestrictions элемент
  xml.XmlElement _buildDataRestrictions() {
    return xml.XmlElement(
      xml.XmlName('dataRestrictions'),
      [],
      [
        xml.XmlElement(
          xml.XmlName('restrictionInstructions'),
          [],
          [
            xml.XmlElement(
              xml.XmlName('dataDistribution'),
              [],
              [xml.XmlText(dataDistribution)],
            ),
          ],
        ),
        xml.XmlElement(
          xml.XmlName('restrictionInfo'),
          [],
          [
            xml.XmlElement(
              xml.XmlName('copyright'),
              [],
              [
                xml.XmlElement(
                  xml.XmlName('copyrightPara'),
                  [],
                  [xml.XmlText(copyrightPara)],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// Построить responsiblePartnerCompany элемент
  xml.XmlElement _buildResponsiblePartnerCompany() {
    return xml.XmlElement(
      xml.XmlName('responsiblePartnerCompany'),
      [xml.XmlAttribute(xml.XmlName('enterpriseCode'), partnerEnterpriseCode)],
      [
        xml.XmlElement(
          xml.XmlName('enterpriseName'),
          [],
          [xml.XmlText(partnerEnterpriseName)],
        ),
      ],
    );
  }

  /// Построить originator элемент
  xml.XmlElement _buildOriginator() {
    return xml.XmlElement(
      xml.XmlName('originator'),
      [xml.XmlAttribute(xml.XmlName('enterpriseCode'), originatorEnterpriseCode)],
      [
        xml.XmlElement(
          xml.XmlName('enterpriseName'),
          [],
          [xml.XmlText(originatorEnterpriseName)],
        ),
      ],
    );
  }

  /// Построить applic элемент
  xml.XmlElement _buildApplic() {
    return xml.XmlElement(
      xml.XmlName('applic'),
      [],
      [
        xml.XmlElement(
          xml.XmlName('displayText'),
          [],
          [
            xml.XmlElement(
              xml.XmlName('simplePara'),
              [],
              [xml.XmlText(applicText)],
            ),
          ],
        ),
      ],
    );
  }

  /// Построить brexDmRef элемент
  xml.XmlElement _buildBrexDmRef() {
    return xml.XmlElement(
      xml.XmlName('brexDmRef'),
      [],
      [
        xml.XmlElement(
          xml.XmlName('dmRef'),
          [
            xml.XmlAttribute(xml.XmlName('xlink:type'), 'simple'),
            xml.XmlAttribute(xml.XmlName('xlink:actuate'), 'onRequest'),
            xml.XmlAttribute(xml.XmlName('xlink:show'), 'replace'),
            xml.XmlAttribute(xml.XmlName('xlink:href'), computedBrexRefHref),
          ],
          [
            xml.XmlElement(
              xml.XmlName('dmRefIdent'),
              [],
              [
                _buildDmCode(
                  brexRefModelIdentCode,
                  brexRefSystemDiffCode,
                  brexRefSystemCode,
                  brexRefSubSystemCode,
                  brexRefSubSubSystemCode,
                  brexRefAssyCode,
                  brexRefDisassyCode,
                  brexRefDisassyCodeVariant,
                  brexRefInfoCode,
                  brexRefInfoCodeVariant,
                  brexRefItemLocationCode,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// Построить qualityAssurance элемент
  xml.XmlElement _buildQualityAssurance() {
    return xml.XmlElement(
      xml.XmlName('qualityAssurance'),
      [],
      [
        xml.XmlElement(
          xml.XmlName('firstVerification'),
          [xml.XmlAttribute(xml.XmlName('verificationType'), verificationType)],
        ),
      ],
    );
  }

  /// Построить skillLevel элемент
  xml.XmlElement _buildSkillLevel() {
    return xml.XmlElement(
      xml.XmlName('skillLevel'),
      [xml.XmlAttribute(xml.XmlName('skillLevelCode'), skillLevelCode)],
    );
  }

  /// Получить строку XML с красивым форматированием
  String toXmlString({bool pretty = true}) {
    final document = xml.XmlDocument([build()]);
    return document.toXmlString(pretty: pretty);
  }
}

// Пример использования
void main() {
  final builder = S1000DIdentAndStatusBuilder(
    modelIdentCode: 'MI171A3',
    systemDiffCode: 'AAA',
    systemCode: 'D00',
    disassyCodeVariant: 'AA',
    infoCode: '001',
    infoCodeVariant: 'A',
    itemLocationCode: 'A',
    issueNumber: '001',
    issueYear: '2025',
    issueMonth: '07',
    issueDay: '04',
    techName: 'Ми-171А3',
    infoName: 'Контрольный осмотр ВП при внешнем осмотре вертолета',
    dataDistribution:
        'Документ предназначен для использования персоналом ООО Авиапредприятие «Газпром авиа».',
    copyrightPara: 'Copyright (C) 2025 ООО Авиапредприятие «Газпром авиа»',
    partnerEnterpriseCode: 'GAZPR',
    partnerEnterpriseName: 'ООО Авиапредприятие «Газпром авиа»',
    originatorEnterpriseCode: 'GAZPR',
    originatorEnterpriseName: 'ООО Авиапредприятие «Газпром авиа»',
    applicText: 'Вертолет Ми-171А3',
    brexRefModelIdentCode: 'MI171A3',
    brexRefSystemDiffCode: 'AAA',
    brexRefSystemCode: 'D00',
    brexRefInfoCode: '022',
    brexRefInfoCodeVariant: 'A',
    brexRefItemLocationCode: 'D',
    // brexRefHref можно больше не передавать, он сформируется сам
  );

  print('Имя файла: ${builder.getFileName()}');
  print('\nXML:');
  final xmlString = builder.toXmlString();
  print(xmlString);
}
