import 'package:flutter/material.dart';
import 'package:xml/xml.dart';
import '../styles.dart';
import '../enums.dart';
import 'viewers/crew_viewer.dart';
import 'viewers/description_viewer.dart';
import 'viewers/pm_viewer.dart';

class XmlViewerScreen extends StatefulWidget {
  final String xmlContent;
  final String fileName;
  final String? filePath; // Только для десктопа/мобилок
  final String? fileTitle;

  const XmlViewerScreen({super.key, required this.xmlContent, required this.fileName, this.filePath, this.fileTitle});

  @override
  State<XmlViewerScreen> createState() => _XmlViewerScreenState();
}

class _XmlViewerScreenState extends State<XmlViewerScreen> {
  FileTypes? _fileType;
  XmlDocument? _document;
  String _errorMessage = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _parseXml();
  }

  void _parseXml() {
    try {
      final document = XmlDocument.parse(widget.xmlContent);
      String? schemaAttr;

      // Ищем тэг <dmodule>
      final dmoduleTags = document.findAllElements('dmodule');
      if (dmoduleTags.isNotEmpty) {
        final dmodule = dmoduleTags.first;
        schemaAttr = dmodule.getAttribute('xsi:noNamespaceSchemaLocation');
      } else {
        final pmTags = document.findAllElements('pm');
        if (pmTags.isNotEmpty) {
          final pm = pmTags.first;
          schemaAttr = pm.getAttribute('xsi:noNamespaceSchemaLocation');
        }
      }

      if (schemaAttr != null) {
        final typeString = schemaAttr.split('/').last.split('.')[0];
        FileTypes? detectedType;

        switch (typeString) {
          case 'crew':
            detectedType = FileTypes.crew;
            break;
          case 'descript':
            detectedType = FileTypes.description;
            break;
          case 'pm':
            detectedType = FileTypes.pm;
            break;
          default:
            _errorMessage = 'Неизвестный тип схемы: $typeString';
        }

        setState(() {
          _document = document;
          _fileType = detectedType;
          if (detectedType == null && _errorMessage.isEmpty) {
            _errorMessage = 'Не удалось определить тип файла';
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Тэг типа схемы или атрибут xsi:noNamespaceSchemaLocation не найден';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка чтения XML:\n$e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: QRHColors.primaryBg,
        appBar: AppBar(title: const Text('Анализ файла...')),
        body: const Center(child: CircularProgressIndicator(color: QRHColors.info)),
      );
    }

    if (_errorMessage.isNotEmpty || _fileType == null || _document == null) {
      return Scaffold(
        backgroundColor: QRHColors.primaryBg,
        appBar: AppBar(title: Text(widget.fileTitle ?? widget.fileName)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _errorMessage.isNotEmpty ? _errorMessage : 'Не удалось определить тип файла',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(color: QRHColors.danger),
            ),
          ),
        ),
      );
    }

    // Маршрутизируем в зависимости от типа файла
    switch (_fileType!) {
      case FileTypes.crew:
        return CrewViewer(
          document: _document!,
          fileName: widget.fileName,
          filePath: widget.filePath,
          fileTitle: widget.fileTitle,
        );
      case FileTypes.description:
        return DescriptionViewer(document: _document!, fileName: widget.fileName, filePath: widget.filePath);
      case FileTypes.pm:
        return PmViewer(document: _document!, fileName: widget.fileName, filePath: widget.filePath);
    }
  }
}
