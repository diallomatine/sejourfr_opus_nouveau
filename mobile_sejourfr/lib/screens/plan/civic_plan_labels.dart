import '../../core/models/civic_plan_models.dart';

/// Les **mots** du plan civique (L10, `20_` §6) — **purs**, déclarés une fois
/// pour tout le mobile.
///
/// 🛑 **Le serveur n'expose que des faits** : un état de maîtrise, une boîte,
/// une échéance, un compte d'erreurs. Les phrases vivent ici, et sont des
/// **miroirs mot pour mot** de `web_sejoufr/lib/civic-plan.ts` : un libellé qui
/// bouge, ce sont deux fichiers dans la même passe.
///
/// ⚠️ `20_` §10 prévoyait un `civic_plan_item.reason_text` calculé serveur. Il
/// n'existe pas, et c'est délibéré : un texte composé côté serveur ne se relit
/// pas dans deux mises en page différentes.

const String kCivicPlanTitle = 'Mon plan — Examen civique';
const String kCivicPlanLead =
    'Votre préparation personnalisée à l\'Examen civique.';

/// Bloc 1 — l'objectif.
const String kCivicPlanResultTitle = 'Votre résultat au diagnostic';
const String kCivicPlanResultSeuil = 'Seuil de réussite';

/// Bloc 2 — à faire maintenant.
const String kCivicPlanNowTitle = 'À faire maintenant';
const String kCivicPlanNowCta = 'Commencer';

/// 🛑 Le verrou porte sur l'action, et le CTA le dit sans détour.
const String kCivicPlanLockedCta = 'Débloquer cette série';
const String kCivicPlanLockedNote =
    'Les séries ciblées font partie de l\'abonnement. Votre plan, lui, reste entier.';

/// Bloc 4 — les priorités.
const String kCivicPlanPrioritiesTitle = 'Vos priorités';
const String kCivicPlanWorkCta = 'Travailler';

/// Bloc 5 — révision d'entretien. 🛑 Jamais présentée comme une alerte.
const String kCivicPlanReviewTitle = 'À revoir bientôt';

/// Bloc 6 — ce qui est acquis.
const String kCivicPlanSolidTitle = 'Déjà solide';

/// Aucune priorité : ce n'est pas un vide, c'est un état.
const String kCivicPlanAllGoodTitle = 'Rien ne ressort comme prioritaire';
const String kCivicPlanAllGoodText =
    'Enchaînez sur un examen blanc pour vous mettre en conditions réelles.';

/// La note de grain — elle **dit** à quel niveau le plan travaille.
///
/// 🛑 Le plan ne fait pas semblant d'être plus précis qu'il ne l'est. Tant que
/// les questions ne sont pas taguées, il travaille thème par thème (`20_` §3.3,
/// phase 1) et l'écrit. `null` une fois que tout a basculé.
String? civicPlanGrainNote(CivicPlanGrainDto grain) {
  if (grain.courant == CivicPlanGrain.notion) return null;
  return 'Votre plan travaille thème par thème. Il deviendra plus précis, '
      'notion par notion, à mesure que le référentiel civique se complète.';
}

/// Ce que la liste ne montre pas. `null` quand elle montre tout — « + 0 autres »
/// est une phrase qui ne dit rien.
String? civicPlanAutresLabel(CivicPlan plan) {
  final reste = plan.autresPriorites;
  if (reste <= 0) return null;
  final nom = plan.grain.courant == CivicPlanGrain.notion ? 'notion' : 'thème';
  final s = reste > 1 ? 's' : '';
  return '+ $reste autre$s $nom$s à consolider';
}

/// L'ordre de grandeur d'une série. **Dérivé** de ce que le serveur sert :
/// raccourcir la série raccourcit la promesse, sans toucher un écran.
///
/// 🛑 Ordre de grandeur, jamais un chrono.
String civicSerieLabel(CivicPlanCible cible) {
  final minutes = (cible.dureeEstimeeSec / 60).round().clamp(1, 999);
  return '${cible.questionsSerie} questions ciblées · ~$minutes min';
}

/// **Pourquoi cette cible est là.** Une phrase, tirée des faits servis.
///
/// 🛑 **Jamais un reproche sur une absence de mesure.** Une cible que le
/// candidat n'a jamais touchée n'a rien raté : elle est « pas encore
/// travaillée », et ce n'est pas la même chose.
String civicPlanRaison(CivicPlanCible cible) {
  if (cible.erreursRecentes > 0) {
    final s = cible.erreursRecentes > 1 ? 's' : '';
    return '${cible.erreursRecentes} erreur$s récente$s';
  }
  if (cible.aRevoir) return 'À revoir pour ne pas l\'oublier';
  if (cible.reponses == 0) return 'Pas encore travaillé';
  if (cible.maitrise == CivicMaitrise.aTravailler) {
    return 'Fragile à la dernière tentative';
  }
  return 'En cours d\'acquisition';
}

/// Le ton d'une cible. 🛑 `nonEvaluee` n'a **pas** de couleur d'alerte : c'est
/// une absence de mesure, pas un échec.
enum CivicCibleTone { hot, warn, ok, muted }

CivicCibleTone civicCibleTone(CivicPlanCible cible) => switch (cible.maitrise) {
      CivicMaitrise.aTravailler =>
        cible.erreursRecentes > 0 ? CivicCibleTone.hot : CivicCibleTone.warn,
      CivicMaitrise.enProgression => CivicCibleTone.warn,
      CivicMaitrise.maitrisee => CivicCibleTone.ok,
      CivicMaitrise.nonEvaluee => CivicCibleTone.muted,
    };

/// « à revoir dans 2 jours ». `null` quand l'échéance est absente.
String? civicRevueLabel(CivicPlanCible cible, DateTime maintenant) {
  final revue = cible.prochaineRevue;
  if (revue == null) return null;
  final jours = revue.difference(maintenant).inHours / 24;
  final arrondi = jours.ceil();
  if (arrondi <= 0) return 'à revoir maintenant';
  return 'à revoir dans $arrondi jour${arrondi > 1 ? 's' : ''}';
}
