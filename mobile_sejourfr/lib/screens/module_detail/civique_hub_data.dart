import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/repositories.dart';
import '../../core/models/attempt_models.dart';
import '../../core/models/attempt_summary.dart';
import '../../core/models/enums.dart';
import '../../core/models/question_models.dart';

/// Source de vérité des providers partagés entre le hub Civique d'un thème
/// (`CiviqueThemeDetailScreen`) et sa page d'examens blancs
/// (`CiviqueThemeExamsScreen`). Miroir de `qcm_hub_data.dart` côté TCF QCM.

/// Pool des thèmes civique (réutilisé par les deux écrans pour récupérer
/// le `ThemeDto` à partir du `themeId` passé en path param).
final civiqueThemesProvider = FutureProvider.autoDispose<List<ThemeDto>>((ref) {
  return ref.watch(themesRepositoryProvider).list(module: AppModule.civique);
});

/// Historique des examens civique scopés à un thème (20 Q de ce thème,
/// 20 min, seuil 16/20). Filtre côté backend via `?themeId=...` qui
/// regarde la colonne `lot_theme_id` de l'attempt.
final civiqueThemeExamsHistoryProvider =
    FutureProvider.autoDispose.family<List<AttemptSummary>, String>((ref, themeId) {
  return ref.watch(attemptsRepositoryProvider).listMine(
        type: AttemptType.mockExam,
        module: AppModule.civique,
        themeId: themeId,
        limit: 30,
      );
});
