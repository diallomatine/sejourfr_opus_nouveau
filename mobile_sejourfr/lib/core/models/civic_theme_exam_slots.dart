/// `GET /api/themes/{themeId}/exam-slots` — miroir de `CivicThemeExamSlotsDto`.
///
/// 🛑 Le `locked` est **servi** créneau par créneau (le créneau 1 de chaque
/// thème est offert à tous depuis le 2026-09-24, les suivants sont réservés
/// aux abonnés Civique) : ne jamais le déduire du rang.
class CivicThemeExamSlots {
  const CivicThemeExamSlots({required this.themeId, required this.locks});

  final String themeId;

  /// Créneau n → `locks[n]`. Un créneau absent est verrouillé.
  final Map<int, bool> locks;

  bool isLocked(int slot) => locks[slot] ?? true;

  factory CivicThemeExamSlots.fromJson(Map<String, dynamic> json) =>
      CivicThemeExamSlots(
        themeId: json['themeId'] as String,
        locks: {
          for (final s in (json['slots'] as List<dynamic>? ?? const []))
            ((s as Map<String, dynamic>)['slot'] as num).toInt():
                s['locked'] as bool? ?? true,
        },
      );
}
