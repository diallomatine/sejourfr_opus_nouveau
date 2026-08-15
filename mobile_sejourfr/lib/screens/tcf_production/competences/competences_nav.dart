import '../../plan/plan_step_labels.dart';
import '../tcf_production_module.dart';

/// Construction des chemins du module « Compétences ». Les patterns vivent
/// dans `AppRoutes` ; ici on les instancie, en un seul endroit, pour que les
/// quatre écrans ne recollent pas la même chaîne chacun de leur côté. L'entrée
/// du module (la liste) vit dans `production_nav.dart` : c'est un mode du
/// parcours, pas un écran propre aux compétences.
/// [planStep] ajoute le marqueur `?etape=1` : ouverte **depuis le Plan**, la
/// compétence s'affiche à l'échelle de son **étape** (les 5 sujets, « 2/5 »),
/// pas de la compétence entière (« 1/15 ») — cf. `screens/plan/plan_step_labels
/// .dart`. Sans le marqueur, comportement strictement inchangé.
String competenceDetailPath(
  TcfProductionModule module,
  String skillId, {
  bool planStep = false,
}) {
  final path = '/tcf/${module.routeKey}/competences/$skillId';
  return planStep ? '$path?$kPlanStepParam=$kPlanStepValue' : path;
}

String competencePromptPath(
  TcfProductionModule module,
  String skillId,
  String promptId,
) =>
    '/tcf/${module.routeKey}/competences/$skillId/sujet/$promptId';

String competenceResultPath(TcfProductionModule module, String attemptId) =>
    '/tcf/${module.routeKey}/competences/resultat/$attemptId';
