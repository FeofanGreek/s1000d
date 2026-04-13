import 'package:flutter/material.dart';
import 'package:xml/xml.dart';
import '../../styles.dart';
import 'widgets/pm_node_widget.dart';

class PmViewer extends StatefulWidget {
  final XmlDocument document;
  final String fileName;
  final String? filePath; // null для веба

  const PmViewer({super.key, required this.document, required this.fileName, this.filePath});

  @override
  State<PmViewer> createState() => _PmViewerState();
}

class _PmViewerState extends State<PmViewer> {
  @override
  Widget build(BuildContext context) {
    // Ищем основной тег content
    final contentTags = widget.document.findAllElements('content');
    if (contentTags.isEmpty) {
      return Scaffold(
        backgroundColor: QRHColors.primaryBg,
        appBar: AppBar(title: const Text('Publication Module')),
        body: const Center(
          child: Text('Тег <content> не найден', style: TextStyle(color: QRHColors.danger, fontSize: 18)),
        ),
      );
    }

    final contentNode = contentTags.first;

    return Scaffold(
      backgroundColor: QRHColors.primaryBg,
      appBar: AppBar(title: const Text('Содержание (PM)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: contentNode.children
              .whereType<XmlElement>()
              .map((child) => PmNodeWidget(node: child, depth: 0))
              .toList(),
        ),
      ),
    );
  }
}