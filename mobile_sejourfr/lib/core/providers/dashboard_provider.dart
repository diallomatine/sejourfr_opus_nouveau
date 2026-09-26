import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/repositories.dart';
import '../auth/auth_controller.dart';
import '../models/dashboard_models.dart';
import '../../screens/plan/learning_plan_provider.dart';

/// Agrégat `GET /api/me/dashboard` partagé par Accueil, Réviser et Progrès.
/// autoDispose : revenir sur un onglet recrée le widget et refetch, ce qui
/// garde les stats fraîches après un entraînement.
final dashboardProvider =
    FutureProvider.autoDispose<DashboardSummary>((ref) async {
  // Un écran encore monté sous un autre (l'onglet Profil reste monté dans le
  // shell) doit se relire quand ce que l'agrégat résume change :
  // - le COMPTE — une inscription ou une connexion ne doit jamais servir les
  //   chiffres de la session d'avant ;
  // - l'objectif ;
  // - une MESURE du diagnostic (`learningPlanRevisionProvider`, incrémenté à
  //   chaque étape du parcours, fin d'analyse comprise) — sans lui, le Profil
  //   gardait « — » pour le niveau estimé jusqu'au redémarrage ;
  // - l'accès servi.
  ref.watch(compteIdProvider);
  ref.watch(compteObjectifProvider);
  ref.watch(learningPlanRevisionProvider);
  ref.watch(accesRevisionProvider);
  return ref.read(userContentRepositoryProvider).dashboard();
});
