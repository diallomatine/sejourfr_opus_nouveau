import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/repositories.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/enums.dart';
import '../../core/models/exam_slots.dart';

/// La grille **servie** des examens blancs d'une épreuve (`TCF_CO`, `TCF_CE`,
/// `TCF_STRUCTURE`, `TCF_EE`, `TCF_EO`, `TCF_COMPLET`, `CIVIQUE` pour les
/// examens globaux) : un `locked` par créneau.
///
/// 🛑 Le serveur décide du verrou (2026-09-24) : les écrans d'examens blancs le
/// lisent ici, jamais un rang ni l'accès du compte. Observe
/// [accesRevisionProvider] : après un achat, les cadenas se relisent. Tant que
/// la grille n'est pas arrivée, un créneau reste verrouillé
/// ([ExamSlots.isLocked]). Pendant des examens de thème civique :
/// `civiqueThemeExamSlotsProvider`.
final examSlotsProvider = FutureProvider.autoDispose
    .family<ExamSlots, EpreuveType>((ref, epreuve) {
  ref.watch(accesRevisionProvider);
  return ref.watch(attemptsRepositoryProvider).examSlots(epreuve);
});

/// Lecture synchrone d'un créneau pour un `build` : `watch`, jamais `read` (le
/// paywall est poussé au-dessus de l'écran, qui reste monté). Absent ⇒
/// verrouillé.
bool isExamSlotLocked(WidgetRef ref, EpreuveType epreuve, int slot) =>
    ref.watch(examSlotsProvider(epreuve)).valueOrNull?.isLocked(slot) ?? true;
