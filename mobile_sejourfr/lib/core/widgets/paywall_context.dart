import '../models/billing_models.dart';
import '../models/diagnostic_models.dart';
import '../models/enums.dart';

/// La contextualisation du paywall (`10_` §5) — règles **pures**, déclarées une
/// fois pour tout le mobile.
///
/// > « Personnalisation obligatoire : niveau actuel, niveau cible, les 3
/// > priorités réelles, et la date d'examen si renseignée. **Un paywall sans
/// > ces éléments est un bug.** »
///
/// 🛑 **Mais un paywall qui MENT est pire qu'un paywall générique.** Chaque
/// élément est facultatif et se calcule sur ce que le serveur a réellement
/// servi : pas de Plan ⇒ pas de niveau ; aucune priorité ⇒ aucune liste ; pas
/// de date d'examen ⇒ pas de compte à rebours. On dégrade vers le message
/// générique, jamais vers une valeur inventée.
///
/// 🛑 **Rien n'est dérivé ici.** Niveaux, objectif et ordre des priorités
/// arrivent servis ; ce fichier ne fait que les mettre en mots.
///
/// Miroir de `web_sejoufr/lib/paywall-context.ts`.

/// Plafond d'affichage des priorités sur le paywall (`10_` §5).
const int kPaywallMaxPriorities = 3;

class PaywallContext {
  const PaywallContext({
    this.currentLevel,
    this.objectiveLevel,
    this.priorities = const [],
    this.examDate,
  });

  /// Palier mesuré aujourd'hui. `null` = pas encore mesuré.
  final NiveauCecrl? currentLevel;

  /// Palier visé. `null` = démarche non déclarée.
  final TargetLevel? objectiveLevel;

  /// Les priorités réelles, dans l'ordre servi. Jamais retriées.
  final List<LearningPlanPriority> priorities;

  /// Jour de l'examen déclaré. `null` = pas de date, réponse pleine.
  final DateTime? examDate;

  /// Le paywall a-t-il de quoi être personnalisé ? Sinon, message générique.
  bool get isContextualised =>
      currentLevel != null || objectiveLevel != null || priorities.isNotEmpty;
}

/// Assemble le contexte à partir de ce qui est **déjà chargé**.
///
/// L'absence de plan est un cas normal : l'écran qui ouvre le paywall n'a pas
/// forcément lu le Plan.
PaywallContext paywallContext({
  LearningPlan? plan,
  DateTime? examDate,
}) {
  // 🛑 L'ordre vient du serveur : la priorité courante d'abord, puis les
  // suivantes telles qu'il les a classées. Le front ne retrie jamais.
  final toutes = <LearningPlanPriority>[
    if (plan?.currentPriority != null) plan!.currentPriority!,
    ...?plan?.nextPriorities,
  ];
  return PaywallContext(
    currentLevel: plan?.cycle?.startingLevel,
    objectiveLevel: plan?.cycle?.objectiveLevel,
    priorities: toutes.take(kPaywallMaxPriorities).toList(growable: false),
    examDate: examDate,
  );
}

/// « Votre plan B2 est prêt » — ou sans palier quand la démarche est inconnue.
String paywallTitle(PaywallContext ctx) => ctx.objectiveLevel == null
    ? 'Votre plan est prêt'
    : 'Votre plan ${ctx.objectiveLevel!.name.toUpperCase()} est prêt';

/// « Vous êtes actuellement estimé B1. SejourFR a identifié les priorités à
/// travailler pour vous rapprocher de B2. »
String? paywallPitch(PaywallContext ctx) {
  final actuel = ctx.currentLevel?.wire;
  final objectif = ctx.objectiveLevel?.name.toUpperCase();
  if (actuel != null && objectif != null) {
    return 'Vous êtes actuellement estimé $actuel. SejourFR a identifié les '
        'priorités à travailler pour vous rapprocher de $objectif.';
  }
  if (objectif != null) {
    return 'SejourFR a identifié les priorités à travailler pour vous '
        'rapprocher de $objectif.';
  }
  if (actuel != null) {
    return 'Vous êtes actuellement estimé $actuel. SejourFR a identifié vos '
        'priorités.';
  }
  return null;
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
