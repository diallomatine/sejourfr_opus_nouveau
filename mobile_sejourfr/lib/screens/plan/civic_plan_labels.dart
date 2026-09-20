import '../../core/models/civic_diagnostic_models.dart';
import '../../core/models/civic_plan_models.dart';
import '../../core/widgets/sejour/sejour_kit.dart';

/// Les **mots** du plan civique (L10, `20_` §6) — **purs**, déclarés une fois
/// pour tout le mobile.
///
/// 🛑 **Le serveur n'expose que des faits** : un état de maîtrise, une boîte,
/// une échéance, un compte d'erreurs. Les phrases vivent ici, et sont des
/// **miroirs mot pour mot** de `web_sejoufr/lib/civic-plan.ts` : un libellé qui
/// bouge, ce sont deux fichiers dans la même passe.
///
/// ⚠️ **Le miroir porte sur le TEXTE, pas sur l'inventaire** (P8.7, 2026-09-20).
/// La refonte du plan civique abonné (D-50) a vidé cet écran de ses sections
/// dérivées, et chaque front a supprimé **ce que lui ne lit plus** : l'écran
/// gratuit du mobile garde trois helpers que le web n'a jamais montrés
/// ([civicPlanAutresLabel], [kCivicPlanLockedCta], [CivicCibleTone]), ils vivent
/// donc désormais côté Dart seulement. Ce n'est pas un oubli de parité : c'est
/// une divergence de l'écran **gratuit**, antérieure à cette passe, et aucun
/// libellé partagé n'a bougé.
///
/// ⚠️ `20_` §10 prévoyait un `civic_plan_item.reason_text` calculé serveur. Il
/// n'existe pas, et c'est délibéré : un texte composé côté serveur ne se relit
/// pas dans deux mises en page différentes.

/// Bloc 2 — à faire maintenant.
const String kCivicPlanNowTitle = 'À faire maintenant';
const String kCivicPlanNowCta = 'Commencer';

/// 🛑 Le verrou porte sur l'action, et le CTA le dit sans détour.
const String kCivicPlanLockedCta = 'Débloquer cette série';
const String kCivicPlanLockedNote =
    'Les séries ciblées font partie de l\'abonnement. Votre plan, lui, reste entier.';

/// Bloc 4 — les priorités. 🛑 Ne subsiste que sur l'écran **gratuit** : le plan
/// d'un abonné lit le cycle (D-50 §2), qui est l'autorité de l'ordre.
const String kCivicPlanPrioritiesTitle = 'Vos priorités';

/// Le geste d'une cible ou d'une unité, hors carte d'action. Miroir de
/// `CIVIC_PLAN_WORK_CTA` (`web_sejoufr/lib/civic-plan.ts`).
const String kCivicPlanWorkCta = 'Travailler';

/// Bloc 5 — révision d'entretien. 🛑 Jamais présentée comme une alerte.
const String kCivicPlanReviewTitle = 'À revoir bientôt';

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

/// « à revoir dans 2 jours ». `null` quand l'échéance est absente.
String? civicRevueLabel(CivicPlanCible cible, DateTime maintenant) {
  final revue = cible.prochaineRevue;
  if (revue == null) return null;
  final jours = revue.difference(maintenant).inHours / 24;
  final arrondi = jours.ceil();
  if (arrondi <= 0) return 'à revoir maintenant';
  return 'à revoir dans $arrondi jour${arrondi > 1 ? 's' : ''}';
}

/* --------------------------------------------- l'écran « Mon plan » (kit)   */

const String kCivicPlanTopKicker =
    'Votre préparation personnalisée à l\'Examen civique';
const String kCivicPlanTopKickerFree = 'Créé à partir de votre diagnostic';
const String kCivicPlanScreenTitle = 'Mon plan du jour';

/// **Les thèmes du plan**, dédupliqués dans l'ordre servi (priorités d'abord,
/// puis les révisions, puis les acquis).
///
/// 🛑 Le thème et son état viennent du DTO (`themeId`, `etatDuTheme`) : aucun
/// pourcentage n'est classé ici, et aucun second appel au diagnostic n'est
/// nécessaire.
List<CivicPlanCible> civicPlanThemes(CivicPlan plan) {
  final vus = <String>{};
  final themes = <CivicPlanCible>[];
  for (final cible in [...plan.prioritesVisibles, ...plan.aRevoirVisibles, ...plan.solides]) {
    if (cible.themeId.isEmpty || !vus.add(cible.themeId)) continue;
    themes.add(cible);
  }
  return themes;
}

/// Les thèmes **mesurés et non solides**.
///
/// 🛑 Un thème `NON_EVALUE` en est **exclu** : il n'a pas été raté, il n'a pas
/// été mesuré — le ranger parmi les faiblesses reproduirait V040/V041/V042.
List<CivicPlanCible> civicPlanThemesATravailler(CivicPlan plan) =>
    civicPlanThemes(plan)
        .where((cible) =>
            cible.etatDuTheme == CivicThemeState.aRenforcer ||
            cible.etatDuTheme == CivicThemeState.faible)
        .toList(growable: false);

/// Le ton d'un état de thème **servi**.
CivicCibleTone civicThemeTone(CivicThemeState etat) => switch (etat) {
      CivicThemeState.solide => CivicCibleTone.ok,
      CivicThemeState.aRenforcer => CivicCibleTone.warn,
      CivicThemeState.faible => CivicCibleTone.hot,
      CivicThemeState.nonEvalue => CivicCibleTone.muted,
    };

/// Le ton de la **jauge** d'un thème, sur les cartes « Où vous en êtes ».
///
/// 🛑 Il **dérive** de [civicThemeTone], il ne reclasse pas l'état : une
/// seconde table finirait par colorer autrement le même thème d'un écran à
/// l'autre. Miroir web : `civicBarTone` (`lib/civic-plan.ts`).
SfBarTone civicThemeBarTone(CivicThemeState etat) =>
    switch (civicThemeTone(etat)) {
      CivicCibleTone.ok => SfBarTone.ok,
      CivicCibleTone.warn => SfBarTone.warn,
      CivicCibleTone.hot => SfBarTone.hot,
      CivicCibleTone.muted => SfBarTone.muted,
    };

/* ⚠️ **`civicThemeJauge` est SUPPRIMÉE** (2026-09-19). Elle rendait le
   remplissage d'une jauge continue à quatre positions fixes (0 · 0,3 · 0,6 · 1)
   pour la ligne de thème de l'Accueil. Cette ligne rend désormais son état avec
   le **même cran segmenté que l'échelle TCF**, et les crans sont les valeurs
   mesurées de l'enum servi — `accueilEchelonsCivique`
   (`screens/progres/progres_labels.dart`). Son dernier lecteur et sa primitive
   (`SfProgressMini`) partent dans la même passe. Miroir web : `civicBarJauge`,
   supprimée aussi. */

const String kCivicPlanThemesTitle = 'Thèmes à travailler';

/// Le libellé de l'encart bleu de la carte d'action.
///
/// ⚠️ « Objectif de cette séance » de la maquette n'est **pas servi** (aucun
/// `reason_text`) : on nomme ce qu'on sait dire, c'est-à-dire **pourquoi** cette
/// cible passe maintenant.
const String kCivicPlanNowWhy = 'Pourquoi maintenant';

const String kCivicPlanReviewPill = 'Révision courte';

/// La ligne d'une révision d'entretien. 🛑 **La boîte Leitner ne s'affiche
/// jamais** : on dit la maîtrise servie et l'échéance.
String civicPlanReviewText(CivicPlanCible cible, DateTime maintenant) {
  final revue = civicRevueLabel(cible, maintenant);
  final base = '${cible.maitrise.label}.';
  return revue == null
      ? '$base Une courte révision est prévue pour vérifier qu\'elle tient '
          'encore.'
      : '$base Une courte révision est prévue $revue, pour vérifier qu\'elle '
          'tient encore.';
}

/* ------------------------------------------- le plan d'un compte sans pass  */

const String kCivicPlanResultLabel = 'Votre diagnostic';

/// Le repère sous le score. Quand le diagnostic porte déjà le **format de
/// l'examen**, ce n'est plus une estimation : c'est le résultat.
String civicPlanResultNote(CivicPlanResultat resultat) {
  final seuil = 'seuil de réussite ${resultat.seuil} / ${resultat.format}';
  return resultat.posees == resultat.format
      ? 'Votre résultat, au format de l\'examen · $seuil'
      : 'Mesuré sur ${resultat.posees} questions · $seuil';
}

const String kCivicPlanFirstStepTitle = 'Votre première étape est prête';

/// Ce que le Pass Civique ouvre **sur cette étape**, dans l'ordre de la
/// maquette.
const List<String> kCivicPlanStepLocks = <String>[
  'Fiche essentielle',
  'Questions ciblées',
  'Explications de vos erreurs',
  'Suivi de maîtrise',
  'Révisions au bon moment',
];

const String kCivicPlanUnlockHeroTitle =
    'Passez du diagnostic à la progression';
const String kCivicPlanUnlockHeroText =
    'Votre diagnostic vous montre quoi réviser. Avec le Pass Civique, votre '
    'plan vous accompagne thème par thème jusqu\'à ce qu\'ils soient maîtrisés.';

const String kCivicPassTitle = 'Pass Civique';
const String kCivicPassSubtitle = 'Paiement unique · aucun renouvellement';

/// Les deux durées réellement vendues. 🛑 **Aucun prix ici** : les tarifs
/// viennent du store et ne se lisent que sur l'écran d'offre, seule porte
/// d'achat de l'app.
enum CivicPassDuree {
  troisMois('3 mois'),
  unAn('1 an');

  const CivicPassDuree(this.label);

  final String label;
}

const String kCivicPlanUnlockCta = 'Débloquer mon plan';

String civicPlanUnlockCaption(CivicPassDuree duree) =>
    '$kCivicPassTitle · ${duree.label} · paiement unique';

const String kCivicPassNote =
    'Le tarif est celui du Pass Civique, pas un abonnement mensuel. Vous le '
    'choisissez à l\'écran suivant.';

/* ⚠️ **SUPPRIMÉS par la refonte du plan civique abonné** (P8.7, D-50,
   2026-09-20), avec leur dernier lecteur — « refonte = suppression immédiate de
   l'ancien » :

   - `kCivicPathLabels` / `kCivicPathTitle` / `civicPath` / `civicPathCounter`
     — le « parcours de la notion ». Il illustrait la cible du plan **dérivé**,
     et « À faire maintenant » lit désormais le **cycle** : les cinq étapes du
     Leitner n'ont plus d'écran où se poser.
   - `kCivicChangesTitle` / `civicTransitionLabel` / `civicNextStepLabel` —
     « Progression détectée ». Le TCF l'a retirée le 2026-09-19 : elle redisait
     les blocs du cycle en moins précis.
   - `civicPlanEngineLine`, `civicPlanThemesPill`, `civicPlanCiblesPill` — la
     carte de contexte, que la bande objectif remplace (D-50 §1). C'est aussi la
     2ᵉ occurrence de `DETTE-P1` qui disparaît : mobile disait « 4 thèmes /
     17 notions » et web « 17 à consolider / 3 à revoir », même carte, faits
     différents.
   - `kCivicPlanDoneTitle` / `civicPlanDoneRow` (« Déjà travaillé et validé »),
     `kCivicPlanAllGoodTitle` / `_Text` et `kCivicPlanExamCta` (l'état « rien
     d'urgent », que le cycle dit mieux), `kCivicPlanNowBadge` (le rang, qui
     n'avait de sens que sur la carte d'un abonné), `civicCibleTone` (la
     fonction ; l'enum [CivicCibleTone] reste, dix lecteurs).

   🛑 `CivicPlan.changements` et `Cible.parcours` restent **servis** et restent
   dans le modèle : c'est l'affichage qui part, pas le contrat.  */
