import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/repositories.dart';
import '../../core/models/attempt_models.dart';
import '../../core/models/attempt_summary.dart';
import '../../core/models/enums.dart';

/// Source de vérité des providers partagés entre le hub TCF QCM
/// (`TcfQcmDetailScreen`) et sa page d'examens blancs. Miroir
/// d'`expression_hub_data.dart` côté EE/EO.

/// Historique des examens module QCM (MOCK_EXAM filtré par QuestionType).
/// Indexé par QuestionType pour partager le cache Riverpod entre les écrans.
final qcmExamsHistoryProvider = FutureProvider.autoDispose
    .family<List<AttemptSummary>, QuestionType>((ref, qt) {
  return ref.watch(attemptsRepositoryProvider).listMine(
        type: AttemptType.mockExam,
        module: AppModule.tcf,
        moduleExamQuestionType: qt,
        limit: 20,
      );
});
