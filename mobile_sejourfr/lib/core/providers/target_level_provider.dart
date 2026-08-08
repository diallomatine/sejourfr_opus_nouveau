import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../models/enums.dart';

/// **Le palier TCF réellement visé** par le candidat :
/// `max(exigé par sa démarche, niveau déclaré)`.
///
/// La démarche fait **plancher** — la naturalisation exige le B2 depuis le
/// 1ᵉʳ janvier 2026, donc un compte `NAT` portant un `targetLevel` hérité à B1
/// vise bel et bien B2. Sans ce plancher, l'écran de résultat félicitait le
/// candidat d'un objectif qu'il n'avait pas et ne le tirait jamais vers le
/// niveau dont sa procédure a besoin.
///
/// `null` tant que rien n'est connu — et c'est volontaire : un écran qui
/// rappelle au candidat ce qu'il joue ne doit **rien** dire plutôt que de
/// deviner une démarche à sa place. Miroir de `niveauViseTcf` côté web, **sans**
/// le repli « B1 » de `resolveTcfLevel` (qui, lui, ne sert qu'à tirer des
/// sujets, pas à écrire une phrase au candidat).
final userTargetLevelProvider = Provider<TargetLevel?>((ref) {
  final auth = ref.watch(authControllerProvider);
  if (auth is! AuthAuthenticated) return null;
  return TargetProcedure.niveauVise(
    auth.user.targetProcedure,
    auth.user.targetLevel,
  );
});
