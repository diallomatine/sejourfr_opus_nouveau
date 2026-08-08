import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/repositories.dart';
import '../../core/models/enums.dart';
import '../../core/models/production_models.dart';

/// Catalogue d'une **épreuve** EE/EO : ses sujets (les 3 tâches confondues) et
/// les productions du candidat.
///
/// Les deux appels qui l'alimentent (`/api/production-tasks?epreuve=`,
/// `/api/users/me/production-submissions?epreuve=`) sont **portés par
/// l'épreuve**, pas par la tâche : les charger une fois par tâche revenait à
/// redemander trois fois la même chose. Le découpage par tâche est un filtre
/// local, ici et dans [TaskTrainingData].
class ProductionCatalog {
  ProductionCatalog({required this.tasks, required this.submissions});

  final List<ProductionTaskDto> tasks;

  /// Toutes les productions du candidat sur l'épreuve, ordre serveur.
  final List<ProductionSubmissionDto> submissions;

  /// Dernière production par sujet — ce qui fait qu'un sujet s'affiche « fait »
  /// avec sa note. Calculé une fois pour l'épreuve entière.
  late final Map<String, ProductionSubmissionDto> lastByTaskId = () {
    final byTask = <String, ProductionSubmissionDto>{};
    for (final s in submissions) {
      final id = s.productionTaskId;
      if (id == null) continue;
      final current = byTask[id];
      if (current == null || s.submittedAt.isAfter(current.submittedAt)) {
        byTask[id] = s;
      }
    }
    return byTask;
  }();

  List<ProductionTaskDto> tasksForTache(int tacheNumero) =>
      tasks.where((t) => t.tacheNumero == tacheNumero).toList();
}

/// Source unique du catalogue d'une épreuve, **gardée en vie pour la session**.
///
/// Les sujets sont du contenu éditorial stable ; les productions, elles,
/// bougent avec l'usage — d'où [invalidateProductionCatalog], appelé au retour
/// d'un flux qui a pu produire. Sans ce cache, chaque bascule de tâche ou de
/// mode relançait les deux appels.
///
/// L'échec n'est pas mis en cache : un « Réessayer » repart sur un appel neuf.
final productionCatalogProvider =
    FutureProvider.autoDispose.family<ProductionCatalog, EpreuveType>(
        (ref, epreuve) async {
  final link = ref.keepAlive();
  try {
    final repo = ref.watch(productionRepositoryProvider);
    final tasks = await repo.listTasks(epreuve: epreuve);
    final submissions = await repo.listMine(epreuve: epreuve, limit: 200);
    return ProductionCatalog(tasks: tasks, submissions: submissions);
  } catch (_) {
    link.close();
    rethrow;
  }
});

/// Recharge les sujets **et** les productions d'une épreuve. À appeler quand le
/// candidat vient de produire (retour d'un entraînement, d'un examen blanc) :
/// la progression affichée mentirait sinon.
void invalidateProductionCatalog(WidgetRef ref, EpreuveType epreuve) =>
    ref.invalidate(productionCatalogProvider(epreuve));
