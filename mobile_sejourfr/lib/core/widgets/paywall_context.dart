import '../models/billing_models.dart';
import '../models/diagnostic_models.dart';
import '../models/enums.dart';

/// Ce que l'offre sait de l'échéance du candidat — règles **pures**, déclarées
/// une fois pour tout le mobile.
///
/// 🛑 **L'en-tête personnalisé a été SUPPRIMÉ** (demande du propriétaire,
/// 2026-09-20). « Votre plan B2 est prêt », le pitch, les trois priorités
/// réelles, les bénéfices du plan et `PaywallOrigin` — qui ne servait qu'à
/// décider de leur affichage — sont partis **avec leur seul lecteur** : la
/// promesse est désormais dite **une fois**, sur l'écran de transition
/// `/plan/debloquer`, et la répéter sur l'écran suivant la disait deux fois de
/// suite. Ne pas les réintroduire ici.
///
/// Ce qui reste ne parle **pas du plan** : la date d'examen déclarée et le pass
/// le plus court qui la couvre. Ce sont les deux faits qui aident à **choisir
/// une durée**, et c'est bien le rôle d'un écran d'offre.
///
/// 🛑 **Rien n'est dérivé ici.** L'objectif arrive servi ; ce fichier ne fait
/// que le mettre en mots.
///
/// Miroir de `web_sejoufr/lib/paywall-context.ts`.
class PaywallContext {
  const PaywallContext({this.objectiveLevel, this.examDate});

  /// Palier visé. `null` = démarche non déclarée.
  final TargetLevel? objectiveLevel;

  /// Jour de l'examen déclaré. `null` = pas de date, réponse pleine.
  final DateTime? examDate;
}

/// Assemble le contexte à partir de ce qui est **déjà chargé**.
///
/// L'absence de plan est un cas normal : l'écran qui ouvre l'offre n'a pas
/// forcément lu le Plan.
PaywallContext paywallContext({
  LearningPlan? plan,
  DateTime? examDate,
}) {
  return PaywallContext(
    objectiveLevel: plan?.cycle?.objectiveLevel,
    examDate: examDate,
  );
}

/// Jours restants avant l'examen. Date passée ⇒ `null`.
int? joursAvantExamen(DateTime? examDate, {DateTime? now}) {
  if (examDate == null) return null;
  final maintenant = now ?? DateTime.now();
  final jours = (examDate.difference(maintenant).inMinutes / (60 * 24)).ceil();
  return jours >= 0 ? jours : null;
}

/// « Objectif B2 avant le 18 octobre — il vous reste 39 jours. »
String? echeanceLine(PaywallContext ctx, {DateTime? now}) {
  final jours = joursAvantExamen(ctx.examDate, now: now);
  if (jours == null) return null;
  final objectif = ctx.objectiveLevel == null
      ? 'Examen'
      : 'Objectif ${ctx.objectiveLevel!.name.toUpperCase()} avant';
  final reste = jours == 0
      ? 'c\'est aujourd\'hui.'
      : 'il vous reste $jours jour${jours > 1 ? 's' : ''}.';
  return '$objectif le ${formatJour(ctx.examDate!)} — $reste';
}

/// Le pass recommandé et sa phrase, ou `null`.
///
/// Le levier propre aux pass (`50_` §3.4) : **aligner la durée sur
/// l'échéance**.
///
/// 🛑 On ne recommande **que** ce que le catalogue propose réellement, et
/// seulement un pass qui **couvre** l'échéance : promettre une couverture qu'un
/// pass ne tient pas serait pire que se taire.
({PlanPublicResponse plan, String phrase})? passRecommande(
  PaywallContext ctx,
  List<PlanPublicResponse>? plans, {
  DateTime? now,
}) {
  final jours = joursAvantExamen(ctx.examDate, now: now);
  if (jours == null || plans == null || plans.isEmpty) return null;

  // Le plus COURT des pass qui couvrent l'échéance : on répond au besoin, on ne
  // pousse pas au plus cher.
  final couvrants = plans
      .where((p) => p.isOneTime && p.durationDays >= jours)
      .toList(growable: false)
    ..sort((a, b) => a.durationDays.compareTo(b.durationDays));

  if (couvrants.isEmpty) return null;
  final choisi = couvrants.first;
  return (
    plan: choisi,
    phrase: 'Votre examen est le ${formatJour(ctx.examDate!)}. '
        'Le pass ${passDurationLabel(choisi.durationDays)} couvre toute votre '
        'préparation.',
  );
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
) {
  if (plans == null) return null;
  final cible = module == PlanModuleTarget.civique
      ? ModuleAccess.civique
      : ModuleAccess.integral;
  final passes = plans
      .where((p) => p.isOneTime && p.moduleAccess == cible)
      .toList(growable: false);
  if (passes.isEmpty) return null;
  var min = passes.first.price;
  for (final p in passes) {
    if (p.price < min) min = p.price;
  }
  return min;
}

/// « 2 mois », « 7 jours », « 1 an ». Miroir de `passDurationLabel` côté web.
String passDurationLabel(int days) {
  if (days <= 0) return '';
  if (days % 365 == 0) {
    final y = days ~/ 365;
    return y == 1 ? '1 an' : '$y ans';
  }
  if (days >= 30 && days % 30 == 0) return '${days ~/ 30} mois';
  if (days % 7 == 0) return days == 7 ? '7 jours' : '${days ~/ 7} semaines';
  return '$days jours';
}

/// « 18 octobre ». Le jour tel qu'il a été déclaré, sans fuseau appliqué.
String formatJour(DateTime d) {
  const mois = [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
  ];
  return '${d.day} ${mois[d.month - 1]}';
}
