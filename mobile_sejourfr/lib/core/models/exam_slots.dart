/// Une grille d'examens blancs, créneau par créneau — miroir de `ExamSlotsDto`
/// (`GET /api/exam-slots?epreuve=…`) et de `CivicThemeExamSlotsDto`
/// (`GET /api/themes/{themeId}/exam-slots`), qui servent tous deux la même
/// liste `slots: [{slot, locked}]`.
///
/// 🛑 **Le serveur décide du verrou** (2026-09-24) : les écrans lisent
/// [isLocked], ils ne le déduisent jamais du rang ni de l'accès du compte. Le
/// 403 du démarrage lit la même règle.
class ExamSlots {
  const ExamSlots({required this.locks});

  /// Créneau n → `locks[n]`.
  final Map<int, bool> locks;

  /// Un créneau absent (grille pas encore arrivée, borne dépassée) est
  /// verrouillé : on n'ouvre jamais par défaut.
  bool isLocked(int slot) => locks[slot] ?? true;

  factory ExamSlots.fromJson(Map<String, dynamic> json) => ExamSlots(
        locks: {
          for (final s in (json['slots'] as List<dynamic>? ?? const []))
            ((s as Map<String, dynamic>)['slot'] as num).toInt():
                s['locked'] as bool? ?? true,
        },
      );
}
