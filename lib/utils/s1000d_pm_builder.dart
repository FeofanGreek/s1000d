import 'package:xml/xml.dart' as xml;
import 'dart:io';

class S1000DPmBuilder {
  static String buildPmXml({
    required String modelIdentCode,
    required String pmIssuer,
    required String pmNumber,
    required String pmVolume,
    required String languageIsoCode,
    required String countryIsoCode,
    required String issueNumber,
    required String inWork,
    required String techName,
    required String pmTitle,
    required String partnerCode,
    required String partnerName,
    required String dataDistribution,
    required String copyrightPara,
    required String brexHref,
    required List<xml.XmlElement> pmEntries,
  }) {
    final now = DateTime.now();
    final year = now.year.toString();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');

    final builder = xml.XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    
    builder.element('pm', attributes: {
      'xmlns:xsi': 'http://www.w3.org/2001/XMLSchema-instance',
      'xmlns:dc': 'http://www.purl.org/dc/elements/1.1/',
      'xmlns:rdf': 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
      'xmlns:xlink': 'http://www.w3.org/1999/xlink',
      'xsi:noNamespaceSchemaLocation': 'http://www.s1000d.org/S1000D_4-1/xml_schema_flat/pm.xsd'
    }, nest: () {
      
      builder.element('identAndStatusSection', nest: () {
        builder.element('pmAddress', nest: () {
          builder.element('pmIdent', nest: () {
            builder.element('pmCode', attributes: {
              'modelIdentCode': modelIdentCode,
              'pmIssuer': pmIssuer,
              'pmNumber': pmNumber,
              'pmVolume': pmVolume,
            });
            builder.element('language', attributes: {
              'countryIsoCode': countryIsoCode,
              'languageIsoCode': languageIsoCode,
            });
            builder.element('issueInfo', attributes: {
              'issueNumber': issueNumber,
              'inWork': inWork,
            });
          });
          builder.element('pmAddressItems', nest: () {
            builder.element('issueDate', attributes: {
              'year': year,
              'month': month,
              'day': day,
            });
            builder.element('pmTitle', nest: () {
              builder.text(pmTitle);
            });
            builder.element('shortPmTitle', nest: () {
              builder.text(pmTitle); // Или сокращенное
            });
          });
        });

        builder.element('pmStatus', attributes: {'issueType': 'new'}, nest: () {
          builder.element('security', attributes: {'securityClassification': '01'});
          builder.element('dataRestrictions', nest: () {
            builder.element('restrictionInstructions', nest: () {
              builder.element('dataDistribution', nest: () {
                builder.text(dataDistribution);
              });
            });
            builder.element('restrictionInfo', nest: () {
              builder.element('copyright', nest: () {
                builder.element('copyrightPara', nest: () {
                  builder.text(copyrightPara);
                });
              });
            });
          });
          builder.element('responsiblePartnerCompany', attributes: {'enterpriseCode': partnerCode}, nest: () {
            builder.element('enterpriseName', nest: () {
              builder.text(partnerName);
            });
          });
          builder.element('originator', attributes: {'enterpriseCode': partnerCode}, nest: () {
            builder.element('enterpriseName', nest: () {
              builder.text(partnerName);
            });
          });
          builder.element('applic', nest: () {
            builder.element('displayText', nest: () {
              builder.element('simplePara', nest: () {
                builder.text(techName);
              });
            });
          });
          
          // Всегда добавляем brexDmRef (даже если brexHref пустой), 
          // так как он обязателен в схеме перед qualityAssurance
          builder.element('brexDmRef', nest: () {
             builder.element('dmRef', nest: () {
                builder.element('dmRefIdent', nest: () {
                  builder.element('dmCode', attributes: {
                     'modelIdentCode': modelIdentCode,
                     'systemDiffCode': 'AAA',
                     'systemCode': 'D00',
                     'subSystemCode': '0',
                     'subSubSystemCode': '0',
                     'assyCode': '00',
                     'disassyCode': '00',
                     'disassyCodeVariant': 'AA',
                     'infoCode': '022',
                     'infoCodeVariant': 'A',
                     'itemLocationCode': 'D'
                  });
                });
             });
          });

          builder.element('qualityAssurance', nest: () {
            builder.element('unverified');
          });
        });
      });

      builder.element('content', nest: () {
        for (var pmEntry in pmEntries) {
          builder.xml(pmEntry.toXmlString());
        }
      });

    });

    final document = builder.buildDocument();
    return document.toXmlString(pretty: true, indent: '\t');
  }
}
