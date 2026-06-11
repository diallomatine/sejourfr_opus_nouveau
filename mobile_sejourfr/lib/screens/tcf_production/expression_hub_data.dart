import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/repositories.dart';
import '../../core/models/enums.dart';
import '../../core/models/production_models.dart';

/// Session d'examen blanc TCF EE/EO : un attempt avec ses 3 (ou plus)
/// soumissions. Le niveau global d'une session n'est plus dérivé ici par tâche
/// — il est calculé côté backend et exposé via `production-bilan`.
class ExamSession {
  ExamSession({required this.attemptId, required this.submissions});

  final String attemptId;
  final List<ProductionSubmissionDto> submissions;

  DateTime get lastSubmittedAt => submissions
      .map((s) => s.submittedAt)
      .reduce((a, b) => a.isAfter(b) ? a : b);

  /// Toutes les soumissions ont une evaluation IA non nulle.
  bool get isFullyEvaluated =>
      submissions.every((s) => s.evaluation != null);

  /// Moyenne des notes sur 20 (null si aucune évaluation disponible).
  double? get avgScore {
    final notes = submissions
        .map((s) => s.evaluation?.noteSurVingt)
        .whereType<double>()
        .toList();
    if (notes.isEmpty) return null;
    return notes.reduce((a, b) => a + b) / notes.length;
  }
}

/// Vue agrégée du hub : compteur de sujets par tâche, sessions d'examen blanc
/// (≥ 3 soumissions) et entraînements libres (mono-tâche).
class HubData {
  const HubData(
      {required this.countByTache,
      required this.exams,
      required this.singles});

  final Map<int, int> countByTache;

  /// Sessions d'examen blanc, les plus récentes d'abord.
  final List<ExamSession> exams;

  /// Dernières productions en entraînement libre (single-task), récentes
  /// d'abord.
  final List<ProductionSubmissionDto> singles;
}

/// Source unique des données du hub EE/EO et de la page « Examens blancs ».
final expressionHubProvider = FutureProvider.autoDispose
    .family<HubData, EpreuveType>((ref, epreuve) async {
  final repo = ref.watch(productionRepositoryProvider);
  final tasks = await repo.listTasks(epreuve: epreuve);
  final countByTache = <int, int>{};
  for (final t in tasks) {
    countByTache[t.tacheNumero] = (countByTache[t.tacheNumero] ?? 0) + 1;
  }

  final subs = await repo.listMine(epreuve: epreuve, limit: 200);
  final byAttempt = <String, List<ProductionSubmissionDto>>{};
  for (final s in subs) {
    final id = s.attemptId;
    if (id == null) continue;
    byAttempt.putIfAbsent(id, () => []).add(s);
  }
  final exams = <ExamSession>[];
  final singles = <ProductionSubmissionDto>[];
  for (final entry in byAttempt.entries) {
    if (entry.value.length >= 3) {
      exams.add(ExamSession(attemptId: entry.key, submissions: entry.value));
    } else {
      singles.addAll(entry.value);
    }
  }
  exams.sort((a, b) => b.lastSubmittedAt.compareTo(a.lastSubmittedAt));
  singles.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
  return HubData(countByTache: countByTache, exams: exams, singles: singles);
});
