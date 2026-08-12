/// Progression d'un candidat sur les petits sujets d'**une compétence**, à
/// partir des seuls compteurs servis par le serveur.
///
/// Promue ici parce que **deux surfaces** la lisent maintenant :
/// « Réviser → Compétences » (`SkillDto` de `GET /api/skills`) et le Plan
/// (`LearningPlanSkill` / `LearningPlanPriority` de `GET /api/me/plan`). Le
/// propriétaire veut que les deux écrans parlent des mêmes compétences avec
/// les mêmes mots : une seule implémentation, deux appelants.
///
/// ⚠️ **Libellé gelé**, miroir mot pour mot du web (`competenceProgressLabel`,
/// `web_sejoufr/lib/skill-progress.ts`).
library;

/// « 2 réussis · 3 restants ». Aucun pourcentage, aucun agrégat inventé.
String skillProgressLabel({
  required int promptCount,
  required int attemptedCount,
  required int validatedCount,
}) {
  if (promptCount == 0) return 'Bientôt disponible';

  final attempted = attemptedCount.clamp(0, promptCount);
  if (attempted == 0) return '$promptCount à découvrir';

  final validated = validatedCount.clamp(0, attempted);
  final head = validated > 0
      ? '$validated réussi${validated > 1 ? 's' : ''}'
      : '$attempted commencé${attempted > 1 ? 's' : ''}';

  final remaining = promptCount - attempted;
  if (remaining == 0) return head;
  return '$head · $remaining restant${remaining > 1 ? 's' : ''}';
}

/// Part de sujets **traités** (pas validés — spec §12) sur 0..1.
double skillProgressValue({
  required int promptCount,
  required int attemptedCount,
}) =>
    promptCount == 0 ? 0 : (attemptedCount / promptCount).clamp(0.0, 1.0);
