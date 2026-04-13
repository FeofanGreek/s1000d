import 'package:xml/xml.dart' as xml;

/// Параметры для создания блока identAndStatusSection
class IdentAndStatusSectionParams {
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
  String issueYear;
  String issueMonth;
  String issueDay;

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
  String brexRefModelIdentCode = '';
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
  String brexRefHref = '';

  // Quality Assurance параметры
  final String verificationType;

  // Skill Level параметры
  final String skillLevelCode;

  IdentAndStatusSectionParams({
    required this.modelIdentCode,
    this.systemDiffCode = 'AAA',
    this.systemCode = 'D00',
    required this.subSystemCode,
    required this.subSubSystemCode,
    required this.assyCode,
    required this.disassyCode,
    required this.disassyCodeVariant,
    required this.infoCode,
    required this.infoCodeVariant,
    required this.itemLocationCode,
    required this.languageCountryIsoCode,
    required this.languageIsoCode,
    required this.issueNumber,
    required this.inWork,
    required this.issueYear,
    required this.issueMonth,
    required this.issueDay,
    required this.techName,
    required this.infoName,
    required this.issueType,
    required this.securityClassification,
    required this.dataDistribution,
    required this.copyrightPara,
    required this.partnerEnterpriseCode,
    required this.partnerEnterpriseName,
    required this.originatorEnterpriseCode,
    required this.originatorEnterpriseName,
    required this.applicText,
    required this.brexRefSystemDiffCode,
    required this.brexRefSystemCode,
    required this.brexRefSubSystemCode,
    required this.brexRefSubSubSystemCode,
    required this.brexRefAssyCode,
    required this.brexRefDisassyCode,
    required this.brexRefDisassyCodeVariant,
    required this.brexRefInfoCode,
    required this.brexRefInfoCodeVariant,
    required this.brexRefItemLocationCode,
    required this.verificationType,
    required this.skillLevelCode,
    String? providedBrexRefHref,
  }) {
    brexRefModelIdentCode = modelIdentCode;
    
    if (providedBrexRefHref != null && providedBrexRefHref.isNotEmpty) {
      brexRefHref = providedBrexRefHref;
    } else {
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
      brexRefHref = 'URN:S1000D:$brexDmCode';
    }
  }

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
}

/// Функция для создания XML блока identAndStatusSection
String createIdentAndStatusSection(IdentAndStatusSectionParams params) {
  final builder = xml.XmlBuilder();

  builder.element(
    'identAndStatusSection',
    nest: () {
      // dmAddress
      builder.element(
        'dmAddress',
        nest: () {
          // dmIdent
          builder.element(
            'dmIdent',
            nest: () {
              // dmCode
              builder.element(
                'dmCode',
                attributes: {
                  'modelIdentCode': params.modelIdentCode,
                  'systemDiffCode': params.systemDiffCode,
                  'systemCode': params.systemCode,
                  'subSystemCode': params.subSystemCode,
                  'subSubSystemCode': params.subSubSystemCode,
                  'assyCode': params.assyCode,
                  'disassyCode': params.disassyCode,
                  'disassyCodeVariant': params.disassyCodeVariant,
                  'infoCode': params.infoCode,
                  'infoCodeVariant': params.infoCodeVariant,
                  'itemLocationCode': params.itemLocationCode,
                },
              );

              // language
              builder.element(
                'language',
                attributes: {
                  'countryIsoCode': params.languageCountryIsoCode,
                  'languageIsoCode': params.languageIsoCode,
                },
              );

              // issueInfo
              builder.element('issueInfo', attributes: {'issueNumber': params.issueNumber, 'inWork': params.inWork});
            },
          );

          // dmAddressItems
          builder.element(
            'dmAddressItems',
            nest: () {
              // issueDate
              builder.element(
                'issueDate',
                attributes: {'year': params.issueYear, 'month': params.issueMonth, 'day': params.issueDay},
              );

              // dmTitle
              builder.element(
                'dmTitle',
                nest: () {
                  builder.element(
                    'techName',
                    nest: () {
                      builder.text(params.techName);
                    },
                  );
                  builder.element(
                    'infoName',
                    nest: () {
                      builder.text(params.infoName);
                    },
                  );
                },
              );
            },
          );
        },
      );

      // dmStatus
      builder.element(
        'dmStatus',
        attributes: {'issueType': params.issueType},
        nest: () {
          // security
          builder.element('security', attributes: {'securityClassification': params.securityClassification});

          // dataRestrictions
          builder.element(
            'dataRestrictions',
            nest: () {
              builder.element(
                'restrictionInstructions',
                nest: () {
                  builder.element(
                    'dataDistribution',
                    nest: () {
                      builder.text(params.dataDistribution);
                    },
                  );
                },
              );

              builder.element(
                'restrictionInfo',
                nest: () {
                  builder.element(
                    'copyright',
                    nest: () {
                      builder.element(
                        'copyrightPara',
                        nest: () {
                          builder.text(params.copyrightPara);
                        },
                      );
                    },
                  );
                },
              );
            },
          );

          // responsiblePartnerCompany
          builder.element(
            'responsiblePartnerCompany',
            attributes: {'enterpriseCode': params.partnerEnterpriseCode},
            nest: () {
              builder.element(
                'enterpriseName',
                nest: () {
                  builder.text(params.partnerEnterpriseName);
                },
              );
            },
          );

          // originator
          builder.element(
            'originator',
            attributes: {'enterpriseCode': params.originatorEnterpriseCode},
            nest: () {
              builder.element(
                'enterpriseName',
                nest: () {
                  builder.text(params.originatorEnterpriseName);
                },
              );
            },
          );

          // applic
          builder.element(
            'applic',
            nest: () {
              builder.element(
                'displayText',
                nest: () {
                  builder.element(
                    'simplePara',
                    nest: () {
                      builder.text(params.applicText);
                    },
                  );
                },
              );
            },
          );

          // brexDmRef
          builder.element(
            'brexDmRef',
            nest: () {
              builder.element(
                'dmRef',
                attributes: {
                  'xlink:type': 'simple',
                  'xlink:actuate': 'onRequest',
                  'xlink:show': 'replace',
                  'xlink:href': params.brexRefHref,
                },
                nest: () {
                  builder.element(
                    'dmRefIdent',
                    nest: () {
                      builder.element(
                        'dmCode',
                        attributes: {
                          'modelIdentCode': params.brexRefModelIdentCode,
                          'systemDiffCode': params.brexRefSystemDiffCode,
                          'systemCode': params.brexRefSystemCode,
                          'subSystemCode': params.brexRefSubSystemCode,
                          'subSubSystemCode': params.brexRefSubSubSystemCode,
                          'assyCode': params.brexRefAssyCode,
                          'disassyCode': params.brexRefDisassyCode,
                          'disassyCodeVariant': params.brexRefDisassyCodeVariant,
                          'infoCode': params.brexRefInfoCode,
                          'infoCodeVariant': params.brexRefInfoCodeVariant,
                          'itemLocationCode': params.brexRefItemLocationCode,
                        },
                      );
                    },
                  );
                },
              );
            },
          );

          // qualityAssurance
          builder.element(
            'qualityAssurance',
            nest: () {
              builder.element('firstVerification', attributes: {'verificationType': params.verificationType});
            },
          );

          // skillLevel
          builder.element('skillLevel', attributes: {'skillLevelCode': params.skillLevelCode});
        },
      );
    },
  );

  final document = builder.buildDocument();
  return document.toXmlString(pretty: true);
}

/// Пример использования
void main() {
  final params = IdentAndStatusSectionParams(
    // DMCode параметры
    modelIdentCode: 'MI171A3',
    systemDiffCode: 'AAA',
    systemCode: 'D00',
    subSystemCode: '0',
    subSubSystemCode: '0',
    assyCode: '00',
    disassyCode: '00',
    disassyCodeVariant: 'AA',
    infoCode: '001',
    infoCodeVariant: 'A',
    itemLocationCode: 'A',

    // Language параметры
    languageCountryIsoCode: 'RU',
    languageIsoCode: 'ru',

    // Issue Info параметры
    issueNumber: '001',
    inWork: '00',

    // Issue Date параметры
    issueYear: DateTime.now().year.toString(),
    issueMonth: DateTime.now().month.toString().padLeft(2, '0'),
    issueDay: DateTime.now().day.toString().padLeft(2, '0'),

    // Title параметры
    techName: 'Ми-171А3',
    infoName: 'Контрольный осмотр ВП при внешнем осмотре вертолета',

    // DM Status параметры
    issueType: 'new',
    securityClassification: '01',

    // Data Restrictions параметры
    dataDistribution: 'Документ предназначен для использования персоналом ООО Авиапредприятие «Газпром авиа».',
    copyrightPara: 'Copyright (C) 2025 ООО Авиапредприятие «Газпром авиа»',

    // Partner Company параметры
    partnerEnterpriseCode: 'GAZPR',
    partnerEnterpriseName: 'ООО Авиапредприятие «Газпром авиа»',

    // Originator параметры
    originatorEnterpriseCode: 'GAZPR',
    originatorEnterpriseName: 'ООО Авиапредприятие «Газпром авиа»',

    // Applic параметры
    applicText: 'Вертолет Ми-171А3',

    // BREX DM Ref параметры
    brexRefSystemDiffCode: 'AAA',
    brexRefSystemCode: 'D00',
    brexRefSubSystemCode: '0',
    brexRefSubSubSystemCode: '0',
    brexRefAssyCode: '00',
    brexRefDisassyCode: '00',
    brexRefDisassyCodeVariant: 'AA',
    brexRefInfoCode: '022',
    brexRefInfoCodeVariant: 'A',
    brexRefItemLocationCode: 'D',
    // providedBrexRefHref: 'URN:S1000D:DMC-MI171A3-AAA-D00-00-00-00AA-022A-D', // Можно передать или сгенерируется само

    // Quality Assurance параметры
    verificationType: 'tabtop',

    // Skill Level параметры
    skillLevelCode: 'sk01',
  );

  print('Сгенерированное имя файла: ${params.getFileName()}');
  print('BREX Href: ${params.brexRefHref}\n');

  final xmlString = createIdentAndStatusSection(params);
  print(xmlString);
}
