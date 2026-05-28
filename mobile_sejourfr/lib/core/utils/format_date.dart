/// Formatage de dates et scores partagé par les écrans TCF (QCM + EE/EO).
/// Extraits en lot de refacto pour casser les doublons entre les hubs CO/CE
/// /Structure et leurs équivalents EE/EO.
library;

const List<String> _monthsAbbr = [
  'janv.',
  'févr.',
  'mars',
  'avril',
  'mai',
  'juin',
  'juil.',
  'août',
  'sept.',
  'oct.',
  'nov.',
  'déc.',
];

/// "12 mars 2026"
String formatLongDate(DateTime d) =>
    '${d.day} ${_monthsAbbr[d.month - 1]} ${d.year}';

/// "12/03/2026"
String formatShortDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Score décimal compact : entier si déjà entier, sinon une décimale avec
/// virgule (typographie FR). Ex: 17.0 → "17", 14.5 → "14,5".
String formatScore(double n) {
  if (n == n.truncateToDouble()) return n.toInt().toString();
  return n.toStringAsFixed(1).replaceAll('.', ',');
}
