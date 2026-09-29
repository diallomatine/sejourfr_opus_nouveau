import '../../core/models/diagnostic_models.dart';
import '../../core/utils/paris_day.dart';

/// Le verrou d'un item de séance, **lu**, jamais décidé.
///
/// ⚠ Le serveur publie `locked` à trois endroits — sur l'item, sur l'exercice
/// recommandé et sur le jalon. La ligne est verrouillée dès que l'un des trois
/// le dit ; le rang de l'item n'entre **jamais** dans le calcul. Ne pas
/// réintroduire un « à partir du 2ᵉ, cadenas » côté client : la maquette le
/// dessine comme ça parce que son bouchon n'a pas de serveur, pas parce que
/// c'est la règle.
bool planSeanceItemLocked(PlanSeanceItem item) =>
    item.locked ||
    (item.exercise?.locked ?? false) ||
    (item.milestone?.locked ?? false);

/// **Cette ligne de séance est-elle déjà faite ?** — le pendant Dart de
/// `planSeanceItemDone` (`web_sejoufr/lib/plan-domain.ts`), **miroir mot pour
/// mot**.
///
/// 🛑 **Le serveur sert un FAIT, jamais un booléen « fait aujourd'hui »** : il
/// n'a pas d'horloge dans la construction de la séance, et une réponse figée à
/// la lecture serait fausse le lendemain. C'est donc au front de comparer
/// `lastActivityAt` à **sa** journée courante, en **Europe/Paris** — jamais en
/// heure de l'appareil, sinon deux candidats du même compte verraient deux
/// séances différentes selon l'endroit d'où ils ouvrent l'app.
///
/// Deux façons d'être faite, et la première ne dépend d'aucune date : l'étape
/// est **bouclée** (ses sujets tous traités), ou la compétence a été travaillée
/// **aujourd'hui**.
bool planSeanceItemDone(PlanSeanceItem item, {DateTime? now}) {
  if (item.stepPromptCount > 0 && item.stepCompleted) return true;
  final activity = item.lastActivityAt;
  if (activity == null) return false;
  return sameParisDay(activity, now ?? DateTime.now());
}

/// **La mesure de domaine qui ouvre la séance**, s'il y en a une.
///
/// 🛑 Un item `A_EVALUER` ne porte **aucun exercice** : c'est une mesure, et
/// c'est le seul cas où le bouton principal du Plan ne lance pas l'étape. Le
/// candidat a produit sur ce domaine et le correcteur n'a rien pu y observer —
/// tout ce qui suivrait travaillerait à l'aveugle.
///
/// ⚠️ **Miroir du web** (`ActionMaintenant`, `LearningPlanView.tsx`) : le
/// backend peut servir une action que la carte doit savoir exécuter, et aucun
/// des deux fronts ne doit rester sans chemin pour elle.
/// 🛑 **Le fait lu est `assessment`, jamais l'absence d'exercice.** Un **jalon**
/// n'a pas non plus d'`exercise` côté mobile (il vit dans `milestone`) : le
/// tester par `exercise == null` rendait un examen blanc de jalon sous le nom
/// d'une mesure. Côté web, l'union discriminée l'interdit par construction —
/// ici c'est ce test qui en tient lieu.
PlanSeanceItem? planSeanceMesure(LearningPlan plan) {
  for (final item in plan.seance.items) {
    if (!planSeanceItemDone(item) && item.assessment != null) return item;
  }
  return null;
}
