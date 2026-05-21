import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/repositories.dart';
import '../../core/models/full_tcf_exam.dart';

/// Provider centralisé du détail d'un examen blanc TCF complet.
///
/// Extrait du fichier d'écran pour pouvoir être invalidé depuis les autres
/// surfaces (runner CO/CE, bilan EE/EO) avant de revenir au hub de
/// progression. Sans cette invalidation, `context.go` réutilise le widget
/// existant et l'état du provider reste périmé — les épreuves récemment
/// terminées n'apparaîtraient pas comme Done.
final fullTcfExamProvider =
    FutureProvider.autoDispose.family<FullTcfExamResponse, String>(
        (ref, parentId) async {
  return ref.watch(fullTcfExamRepositoryProvider).get(parentId);
});
