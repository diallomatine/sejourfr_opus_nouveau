import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/repositories.dart';
import '../models/enums.dart';
import '../models/lot_models.dart';

/// Clé du family `lotsProvider` TCF : un (questionType, difficulty) identifie
/// un pool. Le module est implicite (TCF).
class LotsKey {
  const LotsKey({required this.questionType, required this.difficulty});

  final QuestionType questionType;
  final Difficulty difficulty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LotsKey &&
          other.questionType == questionType &&
          other.difficulty == difficulty;

  @override
  int get hashCode => Object.hash(questionType, difficulty);
}

/// Charge les lots TCF d'un (questionType, difficulty) donné. autoDispose →
/// si l'utilisateur quitte les écrans qui l'observent, le cache est libéré.
final lotsProvider =
    FutureProvider.autoDispose.family<List<LotDto>, LotsKey>((ref, key) {
  return ref.watch(lotsRepositoryProvider).list(
        module: AppModule.tcf,
        questionType: key.questionType,
        difficulty: key.difficulty,
      );
});

/// Charge les lots Civique d'un thème (15 Q par lot). Family indexée par
/// `themeId` (String). autoDispose pour libérer le cache au quit de l'écran.
final civiqueLotsProvider =
    FutureProvider.autoDispose.family<List<LotDto>, String>((ref, themeId) {
  return ref.watch(lotsRepositoryProvider).listCivique(themeId: themeId);
});
