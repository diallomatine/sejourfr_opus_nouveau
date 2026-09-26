/// Règles **pures** de l'écran de présentation du diagnostic : ce qu'il annonce
/// comme effort. Miroir mot pour mot de `web_sejoufr/lib/diagnostic.ts`
/// (`diagnosticWrittenMinutes`, `diagnosticOralMinutes`,
/// `diagnosticWrittenMeasureLabel`, `diagnosticOralMeasureLabel`,
/// `diagnosticWordRangeLabel`).
///
/// ⚠️ `diagnosticBudgetLabel` — « Diagnostic express · ~N min » — a été
/// **retirée des deux côtés** le 2026-08-21 : la présentation n'annonce plus un
/// budget unique en tête, mais **un budget par variante** sur sa carte
/// (« ≈ N min »). Ne pas la réintroduire ici seule : ce fichier ne vaut que
/// tant que son miroir web existe.
///
/// Tout se dérive des sujets servis (`wordsMin/Max`, `durationMin/MaxSeconds`) :
/// un chiffre écrit en dur ici mentirait dès la première correction de sujet.
library;

import '../../core/models/diagnostic_models.dart';

/// Vitesse de rédaction retenue pour convertir une fourchette de mots en
/// minutes sur l'écran de présentation, et **seulement là**. Ordre de grandeur
/// assumé (toujours précédé de « environ »), jamais un engagement : rien dans
/// le parcours ne chronomètre le candidat sur cette valeur.
const int kDiagnosticWritingWordsPerMinute = 40;

double? _midpoint(int? min, int? max) {
  if (min != null && max != null) return (min + max) / 2;
  return (min ?? max)?.toDouble();
}

/// Minutes annoncées pour l'écrit, dérivées de la fourchette de mots servie.
int? diagnosticWrittenMinutes(DiagnosticExerciseView? exercise) =>
    diagnosticWrittenMinutesFor(exercise?.wordsMin, exercise?.wordsMax);

/// Même règle, sur des **bornes nues** — ce que porte le format du diagnostic,
/// qui n'a ni sujet ni consigne. Extrait à sa 2ᵉ surface (l'Accueil).
int? diagnosticWrittenMinutesFor(int? wordsMin, int? wordsMax) {
  final words = _midpoint(wordsMin, wordsMax);
  if (words == null || words <= 0) return null;
  final minutes = (words / kDiagnosticWritingWordsPerMinute).round();
  return minutes < 1 ? 1 : minutes;
}

/// Minutes annoncées pour l'oral, dérivées du temps de parole servi.
int? diagnosticOralMinutes(DiagnosticExerciseView? exercise) =>
    diagnosticOralMinutesFor(
        exercise?.durationMinSeconds, exercise?.durationMaxSeconds);

/// Même règle, sur des **bornes nues**.
int? diagnosticOralMinutesFor(int? secondsMin, int? secondsMax) {
  final seconds = _midpoint(secondsMin, secondsMax);
  if (seconds == null || seconds <= 0) return null;
  final minutes = (seconds / 60).round();
  return minutes < 1 ? 1 : minutes;
}

/// Le temps annoncé pour les productions du diagnostic : l'écrit, plus l'oral
/// s'il existe. `null` quand aucune borne n'est servie — on n'invente pas une
/// durée. Miroir de `diagnosticExpressionMinutes` (`web_sejoufr/lib/diagnostic.ts`).
int? diagnosticExpressionMinutes(
  DiagnosticExerciseView? written,
  DiagnosticExerciseView? oral,
) {
  final total = (diagnosticWrittenMinutes(written) ?? 0) +
      (diagnosticOralMinutes(oral) ?? 0);
  return total > 0 ? total : null;
}

/// La mesure de l'écrit : la fourchette de mots servie, puis le temps estimé.
/// `null` quand la base ne porte aucune borne — on n'invente pas un chiffre que
/// le sujet contredirait à l'écran suivant.
String? diagnosticWrittenMeasureLabel(DiagnosticExerciseView? exercise) {
  final words = diagnosticWordRangeLabel(exercise);
  final minutes = diagnosticWrittenMinutes(exercise);
  final time = minutes == null ? null : 'environ $minutes min';
  final parts = [words, time].whereType<String>().toList();
  return parts.isEmpty ? null : parts.join(' · ');
}

/// « 80 à 300 mots » — la fourchette de l'écrit, **telle que le sujet la sert**
/// (`wordsMin` / `wordsMax`, les bornes mêmes qui acceptent ou refusent la
/// copie côté serveur). Seule mise en mots de la fourchette du diagnostic : la
/// présentation et la zone de saisie de l'écrit la lisent ici. `null` sans
/// borne — on n'invente pas un chiffre. Miroir de `diagnosticWordRangeLabel`
/// (`web_sejoufr/lib/diagnostic.ts`).
String? diagnosticWordRangeLabel(DiagnosticExerciseView? exercise) {
  final min = exercise?.wordsMin;
  final max = exercise?.wordsMax;
  if (min != null && max != null) return '$min à $max mots';
  if (min != null) return '$min mots minimum';
  if (max != null) return '$max mots maximum';
  return null;
}

/// La mesure de l'oral : son temps de parole, en clair.
String? diagnosticOralMeasureLabel(DiagnosticExerciseView? exercise) {
  final minutes = diagnosticOralMinutes(exercise);
  if (minutes == null) return null;
  return 'environ $minutes minute${minutes > 1 ? 's' : ''}';
}
