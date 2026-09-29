import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Affiche un texte multi-paragraphes avec un rendu lisible : split sur
/// double saut de ligne, indentation des listes "- " ou "• ", espacement
/// homogène entre les paragraphes. Utilisé pour les passages TCF (CE), les
/// énoncés longs et les explications.
///
/// Les contenus rédigés côté admin/IA utilisent `**gras**` : on le rend en
/// gras au lieu d'afficher les astérisques (cf. [inlineMarkdownSpans]).
class RichParagraphText extends StatelessWidget {
  const RichParagraphText(
    this.text, {
    super.key,
    this.size = 14,
    this.color = AppColors.ink2,
    this.weight = FontWeight.w500,
    this.height = 1.55,
    this.paragraphSpacing = 10,
    this.textAlign = TextAlign.start,
  });

  final String text;
  final double size;
  final Color color;
  final FontWeight weight;
  final double height;
  final double paragraphSpacing;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final paragraphs = _splitParagraphs(text);
    if (paragraphs.isEmpty) return const SizedBox.shrink();

    final baseStyle = AppFonts.ui(
      size: size,
      color: color,
      weight: weight,
      height: height,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < paragraphs.length; i++) ...[
          _Paragraph(text: paragraphs[i], style: baseStyle, textAlign: textAlign),
          if (i != paragraphs.length - 1) SizedBox(height: paragraphSpacing),
        ],
      ],
    );
  }

  static List<String> _splitParagraphs(String raw) {
    final normalized = raw.replaceAll('\r\n', '\n').trim();
    if (normalized.isEmpty) return const [];
    return normalized
        .split(RegExp(r'\n\s*\n'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
  }
}

class _Paragraph extends StatelessWidget {
  const _Paragraph({
    required this.text,
    required this.style,
    required this.textAlign,
  });

  final String text;
  final TextStyle style;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    final allBullets =
        lines.length > 1 && lines.every(_isBulletLine);

    if (allBullets) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in lines) _BulletLine(text: _stripBullet(line), style: style),
        ],
      );
    }

    // Paragraphe normal : on respecte les sauts de ligne simples comme des
    // sauts de ligne textuels (et non comme de nouveaux paragraphes).
    return Text.rich(
      TextSpan(children: inlineMarkdownSpans(text, style)),
      textAlign: textAlign,
    );
  }

  static bool _isBulletLine(String line) {
    final t = line.trimLeft();
    if (t.isEmpty) return false;
    return t.startsWith('- ') ||
        t.startsWith('• ') ||
        t.startsWith('* ') ||
        RegExp(r'^\d+[\.\)]\s').hasMatch(t);
  }

  static String _stripBullet(String line) {
    final t = line.trimLeft();
    if (t.startsWith('- ') || t.startsWith('• ') || t.startsWith('* ')) {
      return t.substring(2).trim();
    }
    final m = RegExp(r'^\d+[\.\)]\s').firstMatch(t);
    if (m != null) return t.substring(m.end).trim();
    return t;
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2, right: 8, left: 2),
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: AppColors.blue,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: Text.rich(
              TextSpan(children: inlineMarkdownSpans(text, style)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Découpe un texte sur les marqueurs `**gras**` en `TextSpan`. Les contenus
/// (explications de questions, feedbacks IA) arrivent avec ce balisage : sans
/// ce découpage, le candidat lit les astérisques à l'écran.
List<TextSpan> inlineMarkdownSpans(String text, TextStyle style) {
  final spans = <TextSpan>[];
  final pattern = RegExp(r'\*\*(.+?)\*\*', dotAll: true);
  var index = 0;
  for (final match in pattern.allMatches(text)) {
    if (match.start > index) {
      spans.add(TextSpan(text: text.substring(index, match.start), style: style));
    }
    spans.add(TextSpan(
      text: match.group(1),
      style: style.copyWith(fontWeight: FontWeight.w700),
    ));
    index = match.end;
  }
  if (index < text.length) {
    spans.add(TextSpan(text: text.substring(index), style: style));
  }
  return spans.isEmpty ? [TextSpan(text: text, style: style)] : spans;
}
