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

/// Bloc 4 — les priorités.
const String kCivicPlanPrioritiesTitle = 'Vos priorités';
/// Bloc 5 — révision d'entretien. 🛑 Jamais présentée comme une alerte.
const String kCivicPlanReviewTitle = 'À revoir bientôt';

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

/* --------------------------------------------- l'écran « Mon plan » (kit)   */

const String kCivicPlanTopKicker =
    'Votre préparation personnalisée à l\'Examen civique';
const String kCivicPlanTopKickerFree = 'Créé à partir de votre diagnostic';
const String kCivicPlanScreenTitle = 'Mon plan du jour';

/// Ce que fait le moteur. Le mot varie avec le **grain servi** : tant que les
/// questions ne sont pas taguées, le plan choisit un thème, pas une notion.
String civicPlanEngineLine(CivicPlanGrainDto grain) {
  final nom = grain.courant == CivicPlanGrain.notion ? 'notion' : 'thème';
  return 'Le plan choisit le prochain $nom selon vos résultats, puis réévalue '
      'après chaque séance.';
}

/// « 3 thèmes à renforcer » — compté sur les **états de thème servis**, jamais
/// sur un score. `null` quand rien n'est à renforcer : « 0 thème à renforcer »
/// se lit comme une panne alors que c'est une bonne nouvelle.
String? civicPlanThemesPill(CivicPlan plan) {
  final n = civicPlanThemesATravailler(plan).length;
  if (n == 0) return null;
  return '$n thème${n > 1 ? 's' : ''} à renforcer';
}

/// « 8 notions à consolider » — le plafond d'affichage **plus** le reste servi
/// (`autresPriorites`). Un plafond d'affichage n'est jamais un budget.
String? civicPlanCiblesPill(CivicPlan plan) {
  final n = plan.priorites.length + plan.autresPriorites;
  if (n == 0) return null;
  final nom = plan.grain.courant == CivicPlanGrain.notion ? 'notion' : 'thème';
  return '$n $nom${n > 1 ? 's' : ''} à consolider';
}

/// **Les thèmes du plan**, dédupliqués dans l'ordre servi (priorités d'abord,
/// puis les révisions, puis les acquis).
///
/// 🛑 Le thème et son état viennent du DTO (`themeId`, `etatDuTheme`) : aucun
/// pourcentage n'est classé ici, et aucun second appel au diagnostic n'est
/// nécessaire.
List<CivicPlanCible> civicPlanThemes(CivicPlan plan) {
  final vus = <String>{};
  final themes = <CivicPlanCible>[];
  for (final cible in [...plan.priorites, ...plan.aRevoir, ...plan.solides]) {
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

const String kCivicPlanThemesTitle = 'Thèmes à travailler';

/// Le libellé de l'encart bleu de la carte d'action.
///
/// ⚠️ « Objectif de cette séance » de la maquette n'est **pas servi** (aucun
/// `reason_text`) : on nomme ce qu'on sait dire, c'est-à-dire **pourquoi** cette
/// cible passe maintenant.
const String kCivicPlanNowWhy = 'Pourquoi maintenant';

const String kCivicPlanDoneTitle = 'Déjà travaillé et validé';
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

/// La ligne cochée d'une cible acquise.
String civicPlanDoneRow(CivicPlanCible cible) =>
    '${cible.label} — ${cible.maitrise.label}';

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

const String kCivicPlanExamCta = 'Faire un examen blanc';

/// Le badge de la carte d'action : son rang, pas le titre de la section.
const String kCivicPlanNowBadge = 'Priorité n°1';

/* ------------------------------------------------ Le parcours d'une cible */

/// **Les 5 étapes d'une notion**, du premier contact à la maîtrise tenue.
///
/// 🛑 Libellés **gelés** : le serveur sert l'ÉTAT de chaque étape
/// (`Cible.parcours`), jamais sa phrase. Miroir mot pour mot de
/// `CIVIC_PATH_LABELS` (`web_sejoufr/lib/civic-plan.ts`).
const List<String> kCivicPathLabels = <String>[
  'Comprendre l\'essentiel',
  'Première série ciblée',
  'Corriger vos confusions',
  'Série de validation',
  'Vérifier la maîtrise',
];

const String kCivicPathTitle = 'Votre parcours';

/// Le parcours d'une cible : l'état **servi** de chaque étape, habillé du
/// libellé gelé de son rang.
///
/// 🛑 **Rien n'est dérivé ici.** Une première version calculait ces états depuis
/// `boite` — un front qui classe un nombre en état pédagogique, ce que le dépôt
/// interdit. Le serveur les sert (`CivicLeitner.parcours`), l'écran les affiche.
List<SfPathStep> civicPath(CivicPlanCible cible) => <SfPathStep>[
      for (var i = 0;
          i < cible.parcours.length && i < kCivicPathLabels.length;
          i++)
        SfPathStep(
          label: kCivicPathLabels[i],
          state: switch (cible.parcours[i]) {
            CivicEtapeEtat.franchie => SfStepState.done,
            CivicEtapeEtat.enCours => SfStepState.now,
            CivicEtapeEtat.aVenir => SfStepState.todo,
          },
        ),
    ];

/// « Étape 3 / 5 » — le rang de l'étape en cours, lu sur ce qui est servi.
String civicPathCounter(CivicPlanCible cible) {
  final total = cible.parcours.length < kCivicPathLabels.length
      ? cible.parcours.length
      : kCivicPathLabels.length;
  final rang = cible.parcours.indexOf(CivicEtapeEtat.enCours) + 1;
  // Aucune étape en cours = tout est franchi : on annonce la fin du parcours.
  return 'Étape ${rang > 0 ? rang : total} / $total';
}

/* ------------------------------------------- « Progression détectée » */

const String kCivicChangesTitle = 'Progression détectée';

/// Ce qu'une transition **servie** raconte : « Le Parlement passe à En
/// progression ».
///
/// 🛑 Le verdict vient du serveur (`avant`, `apres`, `progres`) : cette
/// fonction ne compare rien, elle met en mots. Le libellé d'état est celui,
/// gelé, de [CivicMaitrise.label]. Miroir de `civicTransitionLabel` côté web.
String civicTransitionLabel(CivicPlanTransition t) =>
    '${t.label} passe à ${t.apres.label}';

/// « Votre prochaine étape : Le Gouvernement ».
String civicNextStepLabel(CivicPlanCibleRef ref) =>
    'Votre prochaine étape : ${ref.label}';
