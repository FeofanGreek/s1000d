import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:go_router/go_router.dart';
import '../../styles.dart';

class MdViewerDialog extends StatelessWidget {
  final String title;
  final String mdContent;

  const MdViewerDialog({
    super.key,
    required this.title,
    required this.mdContent,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: QRHColors.secondaryBg,
      title: Text(title, style: const TextStyle(color: QRHColors.textPrimary)),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.7,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Markdown(
          data: mdContent,
          styleSheet: MarkdownStyleSheet(
            p: const TextStyle(color: QRHColors.textPrimary),
            h1: const TextStyle(color: QRHColors.textPrimary, fontWeight: FontWeight.bold),
            h2: const TextStyle(color: QRHColors.textPrimary, fontWeight: FontWeight.bold),
            h3: const TextStyle(color: QRHColors.textPrimary, fontWeight: FontWeight.bold),
            code: const TextStyle(backgroundColor: QRHColors.primaryBg, color: QRHColors.textPrimary),
            blockquoteDecoration: const BoxDecoration(
              color: QRHColors.primaryBg,
              border: Border(left: BorderSide(color: QRHColors.accentBg, width: 4)),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(),
          child: const Text('Закрыть', style: TextStyle(color: QRHColors.info)),
        ),
      ],
    );
  }
}
