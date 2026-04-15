import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:s1000d_validator/s1000d_validator.dart';

class ValidatorHelper {
  static S1000dValidator? _validator;

  static Future<S1000dValidator> getValidator() async {
    if (_validator != null) return _validator!;

    // Extract schemas to a local directory
    final docDir = await getApplicationDocumentsDirectory();
    final schemaDir = Directory('\${docDir.path}/schemas');
    if (!await schemaDir.exists()) {
      await schemaDir.create(recursive: true);
    }

    // Load Asset Manifest to find schemas (Flutter 3.x uses AssetManifest.bin or AssetManifest.json)
    String manifestContent;
    try {
      manifestContent = await rootBundle.loadString('AssetManifest.json');
    } catch (_) {
      try {
        final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
        final assets = manifest
            .listAssets()
            .where((path) => path.startsWith('assets/schemas/'))
            .toList();

        for (final assetPath in assets) {
          final fileName = assetPath.split('/').last;
          final file = File('${schemaDir.path}/$fileName');
          final byteData = await rootBundle.load(assetPath);
          await file.writeAsBytes(
            byteData.buffer.asUint8List(
              byteData.offsetInBytes,
              byteData.lengthInBytes,
            ),
          );
        }

        _validator = S1000dValidator(schemaDirectoryPath: schemaDir.path);
        await _validator!.initialize();
        return _validator!;
      } catch (e) {
        throw Exception('Failed to load assets: $e');
      }
    }
    // Basic regex extraction for asset paths (to support older flutter projects easily)
    final RegExp regex = RegExp(r'"(assets/schemas/[^"]+)"');
    final Iterable<Match> matches = regex.allMatches(manifestContent);

    for (final match in matches) {
      final assetPath = match.group(1)!;
      final fileName = assetPath.split('/').last;
      final file = File('\${schemaDir.path}/\$fileName');

      // Copy if it doesn't exist (or just copy always for updates)
      final byteData = await rootBundle.load(assetPath);
      await file.writeAsBytes(
        byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        ),
      );
    }

    _validator = S1000dValidator(schemaDirectoryPath: schemaDir.path);
    await _validator!.initialize();

    return _validator!;
  }
}
