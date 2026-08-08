import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../models/enums.dart';

/// Palier TCF exigé par la démarche du candidat (CSP → A2, CR → B1, NAT → B2).
///
/// `null` tant que le parcours n'est pas choisi — et c'est volontaire : un écran
/// qui rappelle au candidat ce qu'il joue ne doit **rien** dire plutôt que de
/// deviner une démarche à sa place. Miroir de `tcfLevelFromProcedure` côté web,
/// **sans** le repli « B1 » de `resolveTcfLevel` (qui, lui, ne sert qu'à tirer
/// des sujets, pas à écrire une phrase au candidat).
final userTargetLevelProvider = Provider<TargetLevel?>((ref) {
  final auth = ref.watch(authControllerProvider);
  return auth is AuthAuthenticated
      ? auth.user.targetProcedure?.requiredLevel
      : null;
});
