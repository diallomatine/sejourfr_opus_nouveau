import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/repositories.dart';
import '../../core/models/enums.dart';
import '../../core/models/production_models.dart';
import 'production_catalog.dart';

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

/// Les modèles corrigés d'une tâche. Seul appel réellement porté par la tâche
/// (`/api/production-examples` exige `tacheNumero`) — d'où son provider à part,
/// gardé en vie : c'est du contenu éditorial pur, il ne périme jamais.
final taskExamplesProvider = FutureProvider.autoDispose
    .family<List<ProductionExampleDto>, TaskTrainingKey>((ref, key) async {
  final link = ref.keepAlive();
  try {
    return await ref.watch(productionRepositoryProvider).listExamples(
          epreuve: key.epreuve,
          tacheNumero: key.tacheNumero,
        );
  } catch (_) {
    link.close();
    rethrow;
  }
});

/// Contenu d'une tâche, **assemblé sans réseau** depuis le catalogue de
/// l'épreuve. Provider synchrone : changer de pastille T1/T2/T3 rend la liste
/// au premier frame, sans repasser par un état de chargement.
///
/// Les modèles sont lus en `valueOrNull` : leur compteur est un ornement du
/// lien « Exemples corrigés », il ne doit pas retenir l'affichage des sujets.
final taskTrainingProvider =
    Provider.autoDispose.family<AsyncValue<TaskTrainingData>, TaskTrainingKey>(
        (ref, key) {
  final examples = ref.watch(taskExamplesProvider(key)).valueOrNull ??
      const <ProductionExampleDto>[];
  return ref.watch(productionCatalogProvider(key.epreuve)).whenData(
        (catalog) => TaskTrainingData(
          subjects: catalog.tasksForTache(key.tacheNumero),
          examples: examples,
          lastByTaskId: catalog.lastByTaskId,
        ),
      );
});
