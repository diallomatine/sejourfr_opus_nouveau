/// Règles **pures** de l'écran de présentation du diagnostic : ce qu'il annonce
/// comme effort. Miroir mot pour mot de `web_sejoufr/lib/diagnostic.ts`
/// (`diagnosticWrittenMinutes`, `diagnosticOralMinutes`,
/// `diagnosticWrittenMeasureLabel`, `diagnosticOralMeasureLabel`).
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
int? diagnosticWrittenMinutes(DiagnosticExerciseView? exercise) {
  final words = _midpoint(exercise?.wordsMin, exercise?.wordsMax);
  if (words == null || words <= 0) return null;
  final minutes = (words / kDiagnosticWritingWordsPerMinute).round();
  return minutes < 1 ? 1 : minutes;
}

/// Minutes annoncées pour l'oral, dérivées du temps de parole servi.
int? diagnosticOralMinutes(DiagnosticExerciseView? exercise) {
  final seconds =
      _midpoint(exercise?.durationMinSeconds, exercise?.durationMaxSeconds);
  if (seconds == null || seconds <= 0) return null;
  final minutes = (seconds / 60).round();
  return minutes < 1 ? 1 : minutes;
}

/// La mesure de l'écrit : la fourchette de mots servie, puis le temps estimé.
/// `null` quand la base ne porte aucune borne — on n'invente pas un chiffre que
/// le sujet contredirait à l'écran suivant.
String? diagnosticWrittenMeasureLabel(DiagnosticExerciseView? exercise) {
  final min = exercise?.wordsMin;
  final max = exercise?.wordsMax;
  final words = min != null && max != null
      ? '$min à $max mots'
      : min != null
          ? '$min mots minimum'
          : max != null
              ? '$max mots maximum'
              : null;
  final minutes = diagnosticWrittenMinutes(exercise);
  final time = minutes == null ? null : 'environ $minutes min';
  final parts = [words, time].whereType<String>().toList();
  return parts.isEmpty ? null : parts.join(' · ');
}

/// La mesure de l'oral : son temps de parole, en clair.
String? diagnosticOralMeasureLabel(DiagnosticExerciseView? exercise) {
  final minutes = diagnosticOralMinutes(exercise);
  if (minutes == null) return null;
  return 'environ $minutes minute${minutes > 1 ? 's' : ''}';
}
