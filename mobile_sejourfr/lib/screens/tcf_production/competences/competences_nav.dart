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

/// 🛑 **Le marqueur voyage jusqu'au SUJET**, pas seulement jusqu'à la fiche.
/// Sans lui, le CTA du Plan ouvrait un sujet qui s'annonçait « 1/15 » : le
/// périmètre de l'étape était perdu à la navigation, et l'enchaînement
/// débordait sur le 6ᵉ sujet de la compétence.
String competencePromptPath(
  TcfProductionModule module,
  String skillId,
  String promptId, {
  bool planStep = false,
}) {
  final path = '/tcf/${module.routeKey}/competences/$skillId/sujet/$promptId';
  return planStep ? '$path?$kPlanStepParam=$kPlanStepValue' : path;
}

/// Idem pour le résultat : c'est lui qui propose le sujet suivant, et il doit
/// savoir qu'il est dans une étape pour ne pas en sortir.
String competenceResultPath(
  TcfProductionModule module,
  String attemptId, {
  bool planStep = false,
}) {
  final path = '/tcf/${module.routeKey}/competences/resultat/$attemptId';
  return planStep ? '$path?$kPlanStepParam=$kPlanStepValue' : path;
}
