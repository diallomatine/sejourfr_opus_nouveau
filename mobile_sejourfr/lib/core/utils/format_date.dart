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

/// "12 mars 2026 · 14:05" (heure locale)
String formatLongDateTime(DateTime d) {
  final local = d.toLocal();
  final h = local.hour.toString().padLeft(2, '0');
  final m = local.minute.toString().padLeft(2, '0');
  return '${formatLongDate(local)} · $h:$m';
}

/// L'intervalle de deux dates — « 4–16 sept. 2026 », « 28 août – 3 sept. 2026 »,
/// « 18 déc. 2025 – 4 janv. 2026 ».
///
/// 🛑 **L'année ne se répète pas** quand elle est la même des deux côtés, et le
/// mois non plus : c'est ce qui rend l'intervalle lisible sur un téléphone.
///
/// Miroir web : `journeyHistoryDates` (`lib/journey.ts`).
String formatDateRange(DateTime debut, DateTime fin) {
  final a = debut.toLocal();
  final b = fin.toLocal();
  final memeAnnee = a.year == b.year;
  if (memeAnnee && a.month == b.month) {
    return '${a.day}\u2013${formatLongDate(b)}';
  }
  final gauche = memeAnnee
      ? '${a.day} ${_monthsAbbr[a.month - 1]}'
      : formatLongDate(a);
  return '$gauche \u2013 ${formatLongDate(b)}';
}

/// "12/03/2026"
String formatShortDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Score décimal compact : entier si déjà entier, sinon une décimale avec
/// virgule (typographie FR). Ex: 17.0 → "17", 14.5 → "14,5".
String formatScore(double n) {
  if (n == n.truncateToDouble()) return n.toInt().toString();
  return n.toStringAsFixed(1).replaceAll('.', ',');
}
