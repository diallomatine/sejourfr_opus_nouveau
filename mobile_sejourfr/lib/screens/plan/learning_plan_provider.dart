import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/repositories.dart';
import '../../core/models/diagnostic_models.dart';

/// Signal léger émis par les activités susceptibles de modifier le Plan.
/// Contrairement à `ref.invalidate(learningPlanProvider)`, l'incrément ne
/// démarre aucun appel réseau quand l'écran Plan n'est pas monté.
final learningPlanRevisionProvider = StateProvider<int>((ref) => 0);

final learningPlanProvider = FutureProvider.autoDispose<LearningPlan>((ref) {
  ref.watch(learningPlanRevisionProvider);
  return ref.watch(learningPlanRepositoryProvider).get();
});
