import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sejourfr_mobile/core/widgets/rich_paragraph_text.dart';

const _base = TextStyle(fontSize: 14);

void main() {
  group('inlineMarkdownSpans', () {
    test('un texte sans balisage donne un seul span au style de base', () {
      final spans = inlineMarkdownSpans('Bonne réponse', _base);
      expect(spans, hasLength(1));
      expect(spans.single.text, 'Bonne réponse');
      expect(spans.single.style, _base);
    });

    test('les astérisques ne sont jamais rendues telles quelles', () {
      final spans = inlineMarkdownSpans(
        '« De quelle couleur ? » porte sur **la couleur**.',
        _base,
      );
      final rendered = spans.map((s) => s.text).join();
      expect(rendered, isNot(contains('*')));
      expect(rendered, '« De quelle couleur ? » porte sur la couleur.');
    });

    test('le segment balisé passe en gras, le reste garde le style de base',
        () {
      final spans = inlineMarkdownSpans('avant **gras** après', _base);
      expect(spans.map((s) => s.text).toList(), ['avant ', 'gras', ' après']);
      expect(spans[1].style?.fontWeight, FontWeight.w700);
      expect(spans[0].style?.fontWeight, _base.fontWeight);
    });

    test('plusieurs segments gras sont tous traités', () {
      final spans = inlineMarkdownSpans('**un** et **deux**', _base);
      final bold = spans
          .where((s) => s.style?.fontWeight == FontWeight.w700)
          .map((s) => s.text)
          .toList();
      expect(bold, ['un', 'deux']);
    });

    test('une astérisque isolée reste du texte normal', () {
      final spans = inlineMarkdownSpans('2 * 3 = 6', _base);
      expect(spans.map((s) => s.text).join(), '2 * 3 = 6');
      expect(spans.every((s) => s.style?.fontWeight != FontWeight.w700), isTrue);
    });
  });
}
