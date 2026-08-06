import '../tcf_production_module.dart';

/// Construction des chemins du module « Compétences ». Les patterns vivent
/// dans `AppRoutes` ; ici on les instancie, en un seul endroit, pour que les
/// quatre écrans ne recollent pas la même chaîne chacun de leur côté.
String competencesListPath(TcfProductionModule module, int tacheNumero) =>
    '/tcf/${module.routeKey}/tache/$tacheNumero/competences';

String competenceDetailPath(TcfProductionModule module, String skillId) =>
    '/tcf/${module.routeKey}/competences/$skillId';

String competencePromptPath(
  TcfProductionModule module,
  String skillId,
  String promptId,
) =>
    '/tcf/${module.routeKey}/competences/$skillId/sujet/$promptId';

String competenceResultPath(TcfProductionModule module, String attemptId) =>
    '/tcf/${module.routeKey}/competences/resultat/$attemptId';
