/// Ce que l'offre et l'onboarding savent de la date d'examen — règles
/// **pures**, déclarées une fois pour tout le mobile.
///
/// 🛑 **Le paywall ne dit PLUS l'échéance** (demande du propriétaire,
/// 2026-09-20). Après l'en-tête personnalisé, les deux derniers bandeaux sont
/// partis — « Objectif B2 avant le … — il vous reste N jours. » et « Votre
/// examen est le … Le pass N couvre toute votre préparation. » — et avec eux
/// `PaywallContext`, `paywallContext`, `echeanceLine` et `passRecommande`, qui
/// ne servaient plus qu'à les composer. Ne pas les réintroduire : l'offre dit
/// le prix, pas l'échéance.
///
/// ⚠️ **Pas de miroir web pour tout ce fichier.** `web_sejoufr/lib/paywall-context.ts`
/// est **supprimé** — côté web, plus rien ne lisait ces règles. Ce qui reste
/// ici a ses propres lecteurs : [joursAvantExamen] et [formatJour] servent la
/// carte de date d'examen de l'onboarding (`target_path_screen.dart`), et
/// [passFromPrice] est le miroir de `passFromPrice` (`lib/passes.ts`).
library;

import '../models/billing_models.dart';

/// Jours restants avant l'examen. Date passée ⇒ `null`.
int? joursAvantExamen(DateTime? examDate, {DateTime? now}) {
  if (examDate == null) return null;
  final maintenant = now ?? DateTime.now();
  final jours = (examDate.difference(maintenant).inMinutes / (60 * 24)).ceil();
  return jours >= 0 ? jours : null;
}

/// **Le prix d'entrée d'un module** — le plus petit montant réellement vendu.
///
/// 🛑 **Dérivé du catalogue, jamais écrit.** C'est ce que rend « À partir de
/// X € » sur l'écran de déblocage du Plan : un chiffre en dur y vieillirait à
/// la première grille de prix. `null` quand le module ne vend rien (catalogue
/// injoignable, ou aucun pass actif) — l'écran n'affiche alors **aucune** ligne
/// de prix plutôt qu'un montant de repli.
///
/// Miroir de `passFromPrice` (`web_sejoufr/lib/passes.ts`).
double? passFromPrice(
  List<PlanPublicResponse>? plans,
  PlanModuleTarget module,
) =>
    passFromPlan(plans, module)?.price;

/// **Le pass dont [passFromPrice] affiche le prix** — le moins cher du module.
/// Sert à dire, dans la mesure du clic « Débloquer mon plan », quel pass et
/// quel montant le candidat avait sous les yeux. `null` dans les mêmes cas.
PlanPublicResponse? passFromPlan(
  List<PlanPublicResponse>? plans,
  PlanModuleTarget module,
) {
  if (plans == null) return null;
  final cible = module == PlanModuleTarget.civique
      ? ModuleAccess.civique
      : ModuleAccess.integral;
  PlanPublicResponse? min;
  for (final p in plans) {
    if (!p.isOneTime || p.moduleAccess != cible) continue;
    if (min == null || p.price < min.price) min = p;
  }
  return min;
}

/// « 18 octobre ». Le jour tel qu'il a été déclaré, sans fuseau appliqué.
String formatJour(DateTime d) {
  const mois = [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
  ];
  return '${d.day} ${mois[d.month - 1]}';
}
