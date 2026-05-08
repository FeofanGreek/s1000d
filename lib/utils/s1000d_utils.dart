import 'package:xml/xml.dart';

class S1000DUtils {
  /// Формирует стандартный префикс файла DMC- на основе dmRefIdent или dmIdent
  static String buildDmcPrefixFromIdent(XmlElement ident) {
    final dmCode = ident.findElements('dmCode').firstOrNull ?? ident.findAllElements('dmCode').firstOrNull;
    if (dmCode == null) return '';

    final model = dmCode.getAttribute('modelIdentCode') ?? '';
    final sdc = dmCode.getAttribute('systemDiffCode') ?? '';
    final sc = dmCode.getAttribute('systemCode') ?? '';
    final ssc = dmCode.getAttribute('subSystemCode') ?? '';
    final sssc = dmCode.getAttribute('subSubSystemCode') ?? '';
    final ac = dmCode.getAttribute('assyCode') ?? '';
    final dc = dmCode.getAttribute('disassyCode') ?? '';
    final dcv = dmCode.getAttribute('disassyCodeVariant') ?? '';
    final ic = dmCode.getAttribute('infoCode') ?? '';
    final icv = dmCode.getAttribute('infoCodeVariant') ?? '';
    final ilc = dmCode.getAttribute('itemLocationCode') ?? '';

    final issueInfo = ident.findElements('issueInfo').firstOrNull ?? ident.findAllElements('issueInfo').firstOrNull;
    final issueNumber = issueInfo?.getAttribute('issueNumber') ?? '001';
    final inWork = issueInfo?.getAttribute('inWork') ?? '00';

    final language = ident.findElements('language').firstOrNull ?? ident.findAllElements('language').firstOrNull;
    final langIso = language?.getAttribute('languageIsoCode') ?? 'ru';
    final countryIso = language?.getAttribute('countryIsoCode') ?? 'RU';

    return 'DMC-$model-$sdc-$sc-$ssc$sssc-$ac-$dc$dcv-$ic$icv-${ilc}_$issueNumber-${inWork}_$langIso-$countryIso.XML';
  }
}
