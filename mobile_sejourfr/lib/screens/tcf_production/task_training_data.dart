import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/repositories.dart';
import '../../core/models/enums.dart';
import '../../core/models/production_models.dart';

/// Clé de lecture d'une tâche : (épreuve, numéro de tâche).
class TaskTrainingKey {
  const TaskTrainingKey({required this.epreuve, required this.tacheNumero});

  final EpreuveType epreuve;
  final int tacheNumero;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskTrainingKey &&
          other.epreuve == epreuve &&
          other.tacheNumero == tacheNumero;

  @override
  int get hashCode => Object.hash(epreuve, tacheNumero);
}

/// Contenu d'une tâche : ses sujets, ses modèles, et la dernière production du
/// candidat pour chaque sujet.
class TaskTrainingData {
  const TaskTrainingData({
    required this.subjects,
    required this.examples,
    required this.lastByTaskId,
  });

  final List<ProductionTaskDto> subjects;
  final List<ProductionExampleDto> examples;
  final Map<String, ProductionSubmissionDto> lastByTaskId;

  int get doneCount =>
      subjects.where((t) => lastByTaskId[t.id] != null).length;

  /// Progression de la tâche, 0-100. `0` sur une tâche sans sujet publié.
  double get percent =>
      subjects.isEmpty ? 0 : (doneCount / subjects.length) * 100;
}

/// Source unique du contenu d'une tâche — partagée par l'écran d'entraînement
/// et l'écran des modèles, qui affichaient chacun leur propre chargement.
final taskTrainingProvider = FutureProvider.autoDispose
    .family<TaskTrainingData, TaskTrainingKey>((ref, key) async {
  final repo = ref.watch(productionRepositoryProvider);
  final all = await repo.listTasks(epreuve: key.epreuve);
  final subjects = all.where((t) => t.tacheNumero == key.tacheNumero).toList();
  final examples = await repo.listExamples(
      epreuve: key.epreuve, tacheNumero: key.tacheNumero);
  final subs = await repo.listMine(epreuve: key.epreuve, limit: 200);
  final lastByTaskId = <String, ProductionSubmissionDto>{};
  for (final s in subs) {
    final tid = s.productionTaskId;
    if (tid == null) continue;
    final cur = lastByTaskId[tid];
    if (cur == null || s.submittedAt.isAfter(cur.submittedAt)) {
      lastByTaskId[tid] = s;
    }
  }
  return TaskTrainingData(
      subjects: subjects, examples: examples, lastByTaskId: lastByTaskId);
});
