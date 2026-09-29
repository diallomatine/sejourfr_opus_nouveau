import 'package:flutter_test/flutter_test.dart';
import 'package:sejourfr_mobile/core/utils/format_date.dart';

void main() {
  group('formatLongDate', () {
    test('les mois accentués le restent', () {
      expect(formatLongDate(DateTime(2026, 8, 4)), '4 août 2026');
      expect(formatLongDate(DateTime(2026, 2, 1)), '1 févr. 2026');
      expect(formatLongDate(DateTime(2026, 12, 25)), '25 déc. 2026');
    });
  });

  group('formatLongDateTime', () {
    test('ajoute l\'heure locale sur deux chiffres', () {
      final d = DateTime(2026, 8, 4, 7, 5);
      expect(formatLongDateTime(d), '4 août 2026 · 07:05');
    });

    test('convertit en heure locale avant formatage', () {
      final utc = DateTime.utc(2026, 8, 4, 12, 30);
      final local = utc.toLocal();
      expect(
        formatLongDateTime(utc),
        '${formatLongDate(local)} '
        '· ${local.hour.toString().padLeft(2, '0')}'
        ':${local.minute.toString().padLeft(2, '0')}',
      );
    });
  });

  group('formatScore', () {
    test('entier sans décimale, décimal avec virgule française', () {
      expect(formatScore(17), '17');
      expect(formatScore(14.5), '14,5');
    });
  });
}
