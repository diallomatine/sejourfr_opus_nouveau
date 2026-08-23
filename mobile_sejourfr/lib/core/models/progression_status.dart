/// **Le seul vocabulaire d'état pédagogique du mobile** — miroir de
/// `ProgressionStatus` (backend, moteur de progression V4.2 §13, §25 bis.3).
///
/// 🛑 **Le front ne calcule aucun état, aucun niveau CECRL, aucun seuil**
/// (invariant I42). Cet enum se lit dans un DTO servi, jamais d'un pourcentage :
/// le libellé et le ton arrivent avec lui, ils ne se déduisent pas ici. Les
/// valeurs de repli présentes ci-dessous ne sont là que pour un rendu offline
/// cohérent — elles recopient le contrat, elles ne l'inventent pas.
///
/// Les six états doivent tous être rendus. Une UI qui n'en gère que quatre est
/// non conforme : `watch` et `readyForReassessment` sont précisément ceux qui
/// portent la valeur pédagogique du produit, et ce sont les premiers qu'on perd
/// en recopiant un ancien vocabulaire.
library;

enum ProgressionStatus {
  /// Jamais mesuré directement. **Pas de pourcentage affiché** : un palier sans
  /// preuve directe vaut `null`, jamais 0 % (§18.6, invariant I41).
  notEvaluated('NOT_EVALUATED', 'À évaluer', ProgressionTone.neutral),

  /// Des preuves existent, sous le seuil d'entrée en progression.
  fragile('FRAGILE', 'À renforcer', ProgressionTone.danger),

  /// Score et confiance suffisants pour progresser.
  progressing('PROGRESSING', 'En progression', ProgressionTone.primary),

  /// Prêt à être vérifié sur une vraie tâche — EE/EO uniquement.
  readyForReassessment(
      'READY_FOR_REASSESSMENT', 'Prêt à vérifier', ProgressionTone.accent),

  /// Palier ou compétence confirmé.
  solid('SOLID', 'Acquis', ProgressionTone.success),

  /// Un acquis contredit une fois : vérification ciblée prioritaire.
  watch('WATCH', 'À vérifier', ProgressionTone.warn);

  const ProgressionStatus(this.wire, this.fallbackLabel, this.tone);

  final String wire;

  /// Le libellé **servi** fait foi ; celui-ci ne sert qu'à défaut.
  final String fallbackLabel;

  final ProgressionTone tone;

  static ProgressionStatus fromWire(String value) =>
      ProgressionStatus.values.firstWhere(
        (status) => status.wire == value,
        orElse: () => ProgressionStatus.notEvaluated,
      );
}

/// Le ton visuel d'un état — **dérivé de l'état, jamais d'un nombre**.
///
/// Rappel charte : le rouge est réservé aux CTA critiques et aux signaux
/// d'urgence. Seul `danger` l'utilise ; les autres prennent le bleu, le vert ou
/// l'ambre.
enum ProgressionTone { neutral, danger, primary, accent, success, warn }
