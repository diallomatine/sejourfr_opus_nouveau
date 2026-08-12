import '../../core/models/enums.dart';
import '../../core/models/production_models.dart';

/// Règles de LECTURE du résultat d'une tâche EE/EO : ce que l'écran ose
/// affirmer, et dans quels mots. Volontairement pures et sans Flutter, pour
/// être testables seules.
///
/// Miroir web : `web_sejoufr/lib/production-feedback.ts`. Ces chaînes ne
/// transitent pas par le réseau — chaque front en tient une copie écrite à la
/// main, donc elles sont **gelées par un test de chaque côté**.

/// Ce que le résultat d'une tâche annonce : **le niveau, affirmé**.
///
/// « Proche du niveau A2 » signifie « pas encore A2 » en français courant, alors
/// que le niveau EST A2 et que la pastille juste à côté le dit. Le plancher
/// garde son traitement propre : on n'est pas « proche » d'un niveau non
/// atteint, et on ne dit pas non plus à quelqu'un qu'il est « sous le A1 » — on
/// dit ce qui reste à faire.
String niveauAtteintLabel(NiveauCecrl niveau) =>
    niveau == NiveauCecrl.a1NonAtteint
        ? "Votre production n'atteint pas encore le niveau A1"
        : 'Votre production est au niveau ${niveau.displayName}';

/// Le niveau d'UNE tâche, tel qu'il s'affiche dans une liste : détail par tâche
/// du bilan de session, sujets déjà traités, historique.
///
/// C'est ce qui remplace la note /20 partout où elle décrivait une tâche isolée
/// (décision produit du 2026-08-08) : au TCF, un correcteur attribue un niveau
/// par tâche, jamais une note — le /20 ne porte que sur l'épreuve entière. Même
/// forme que la bande d'un critère ([BandeCritere.displayName]), pour qu'un
/// palier se lise pareil d'un écran à l'autre ; sauf le plancher, où « Niveau
/// A1 non atteint » se contredirait tout seul.
///
/// ⚠️ Contrat gelé, miroir mot pour mot de `tacheNiveauLabel` côté web.
String tacheNiveauLabel(NiveauCecrl niveau) =>
    niveau == NiveauCecrl.a1NonAtteint
        ? 'A1 non atteint'
        : 'Niveau ${niveau.displayName}';

/// Badge d'un sujet **rendu mais sans niveau affichable** (évaluation encore en
/// vol, ou antérieure au contrat v4).
///
/// ⚠️ Contrat gelé, miroir mot pour mot de `TACHE_TRAITEE_LABEL` côté web. Il
/// disait « Fait » ici et « Traité » là-bas — deux fronts, deux mots, pour le
/// même état. Le filtre de la liste de sujets dit « Traités » **des deux
/// côtés** : le badge s'aligne dessus. (Ne pas confondre avec
/// `SkillPromptStatus.treated` = « Fait », qui appartient au module Compétences
/// et reste, lui, gelé sur son propre libellé.)
const String kTacheTraiteeLabel = 'Traité';

/// Même famille, pour une ligne de bilan : la tâche est corrigée mais son
/// niveau n'est pas affichable. Miroir de `TACHE_EVALUEE_LABEL`.
const String kTacheEvalueeLabel = 'Évaluée';

/// Libellé autonome d'un cran, affichable **sans** le niveau (« Palier
/// solide »). Miroir au caractère près de `SituationDansNiveau.getLibelle()`
/// côté serveur et de `SITUATION_LIBELLES` côté web, gelé par test.
///
/// ⚠️ Règle de formulation : le haut de la bande A2 se dit « solide »,
/// **jamais** « presque B1 ». Aucun des trois crans ne nomme un manque — c'est
/// la contrepartie de la note masquée : le candidat doit voir qu'il progresse
/// **dans** son palier, sans aucun chiffre.
String situationLibelle(SituationDansNiveau situation) => switch (situation) {
      SituationDansNiveau.entreeDePalier => 'Palier atteint',
      SituationDansNiveau.palierConfirme => 'Palier confirmé',
      SituationDansNiveau.palierSolide => 'Palier solide',
    };

/// Adjectif seul, pour composer avec un niveau (« A2 solide »). Miroir de
/// `SituationDansNiveau.getQualificatif()`.
String situationQualificatif(SituationDansNiveau situation) =>
    switch (situation) {
      SituationDansNiveau.entreeDePalier => 'atteint',
      SituationDansNiveau.palierConfirme => 'confirmé',
      SituationDansNiveau.palierSolide => 'solide',
    };

/// Ce qu'on affiche du cran de progression.
class SituationView {
  const SituationView({
    required this.cran,
    required this.libelle,
    required this.libelleAvecNiveau,
  });

  final SituationDansNiveau cran;

  /// Forme autonome (« Palier solide »), pour un contexte où le niveau n'est
  /// pas déjà écrit à côté. Le hero, lui, affiche [libelleAvecNiveau].
  final String libelle;

  /// **Ce qui s'affiche au candidat** (« A2 solide »), conformément à
  /// `docs/notation-ia-eo-ee.md` §6.3 bis. Vient du serveur ; recomposé en
  /// dernier recours à partir du qualificatif.
  final String libelleAvecNiveau;
}

/// Le cran affichable, ou `null` quand il n'y a rien à situer.
///
/// Deux verrous : le cran ne s'affiche **jamais sans le niveau qu'il nuance**
/// (une position dans une bande qu'on ne nomme pas ne veut rien dire), et il
/// suit la même garde que [tacheNiveau] — pas de confiance, pas de niveau, donc
/// pas de situation non plus.
SituationView? situationView(EvaluationResult? evaluation) {
  final niveau = tacheNiveau(evaluation);
  final cran = evaluation?.situationDansNiveau;
  if (niveau == null || cran == null) return null;
  return SituationView(
    cran: cran,
    libelle: situationLibelle(cran),
    libelleAvecNiveau: evaluation?.situationDansNiveauLabel ??
        '${niveau.displayName} ${situationQualificatif(cran)}',
  );
}

// Les libellés du plan d'action ne vivent plus ici : ils sont **partagés avec
// le module Compétences**, qui rend exactement le même plan après un
// micro-exercice (`widgets/action_plan.dart` : `pourViserTitle`,
// `kActionPlanExempleTitle`, `kActionPlanReformulationsTitle`).
//
// Sont **supprimés** avec l'ancien bloc « la marche au-dessus » : son sur-titre,
// son titre (« Au niveau B2, votre réponse pourrait ressembler à ceci ») et son
// introduction (« Ce texte n'est pas le vôtre… »). Rien ne vérifie qu'un texte
// atteint le palier dont on l'étiquette, et un candidat qui a recopié un exemple
// annoncé B2 l'a vu noter B1. On garde l'objectif, qui lui est exact.

/// Sur-titre de la section qui **remplace** la version au niveau visé quand le
/// palier est déjà tenu.
///
/// Avant, cette section disparaissait sans un mot : depuis que
/// `version_amelioree` n'est plus affichée, le candidat qui réussit se
/// retrouvait sans aucun texte modèle et sans savoir pourquoi — sa réussite
/// avait exactement la même tête qu'une panne. Le serveur dit désormais
/// laquelle des deux c'est (`niveau_vise_atteint`), et on l'annonce.
///
/// ⚠️ « Objectif atteint » désignait ici le PALIER, et le même libellé sert de
/// titre au bandeau de tête de rapport ([ProductionResultsHero.objectifTitle])
/// pour dire que la CONSIGNE a été accomplie — deux sens différents sous les
/// mêmes mots. Vu en vrai : un candidat noté B1 qui vise B2 lisait « Objectif
/// atteint » en gros dans le bandeau, exact au sens de la consigne, trompeur
/// au sens du niveau. Le bandeau garde son texte (il est suivi du résumé de
/// consigne, le contexte lève l'ambiguïté) ; ce sur-titre-ci, lui, change.
///
/// ⚠️ Contrat gelé, miroir mot pour mot de `NIVEAU_VISE_ATTEINT_EYEBROW`
/// côté web.
const String kNiveauViseAtteintEyebrow = 'Palier visé';

/// Titre : la victoire, nommée par le palier. Volontairement **pas** la phrase
/// du hero ([niveauAtteintLabel] dit « Votre production est au niveau B2 ») —
/// deux blocs qui se recopient se lisent comme un bug d'affichage.
String niveauViseAtteintTitle(TargetLevel niveauVise) =>
    'Objectif ${niveauVise.wire} : vous y êtes';

/// Sous-titre : il **explique l'absence** de texte modèle, sans un chiffre de
/// barème ni un mot de manque, et dit où porter l'effort maintenant.
///
/// Il ne redit pas non plus ce que le palier ouvre comme démarche : le rappel
/// d'enjeu du hero ([demarcheRappel]) le fait déjà, à deux blocs d'écart.
const String kNiveauViseAtteintIntro =
    'Cette production tient le palier que vous visez. Il n\'y a donc pas de '
    "version d'un niveau supérieur à vous montrer ici : l'enjeu est maintenant "
    "de tenir ce niveau sur les trois tâches de l'épreuve.";

/// Le niveau **affichable** d'une tâche, ou `null` quand il n'y a rien
/// d'honnête à montrer : évaluation trop ancienne pour porter un niveau, ou
/// niveau sans sa confiance (garde-fou [EvaluationResult.hasNiveauObserve]).
///
/// Aucun front ne recalcule un niveau — il est dérivé serveur — donc l'absence
/// se dit (« Évaluée », « Fait »), elle ne se comble pas.
NiveauCecrl? tacheNiveau(EvaluationResult? evaluation) =>
    evaluation != null && evaluation.hasNiveauObserve
        ? evaluation.niveauObserve
        : null;

/// Règle de lecture derrière la pastille d'information du panneau de niveau.
///
/// Elle parlait de la **note** : depuis que le résultat d'une tâche n'en affiche
/// plus (au TCF, les correcteurs attribuent un niveau par tâche, jamais une note
/// — le /20 ne porte que sur l'épreuve entière), elle explique le **niveau**.
/// Laisser une info-bulle qui commente une note invisible serait pire que rien.
const String kNiveauPorteeTache =
    'Ce niveau est une estimation : il décrit ce que cette production démontre, '
    'sur les paliers du TCF. Il porte ici sur cette seule tâche — au TCF, le '
    "niveau d'une épreuve est établi sur vos trois tâches réunies.";

/// Repli quand le correcteur signale une confiance basse sans dire pourquoi :
/// une pastille seule laisse le candidat sans explication.
const String kConfianceSansRaison =
    'Une partie de votre production était difficile à analyser : ce niveau est '
    'à prendre avec prudence.';

/// Titre du conseil de fin de bilan.
///
/// ⚠️ Il **vouvoie**, comme tout le reste de la restitution
/// ([niveauAtteintLabel], [demarcheRappel], [kNiveauViseAtteintIntro]). Il
/// disait « Tes prochaines étapes » ici et sur le web, au-dessus d'un corps qui
/// vouvoyait côté web : deux registres dans le même encart. Miroir mot pour mot
/// de `BILAN_PROCHAINES_ETAPES_TITLE` côté web.
const String kBilanProchainesEtapesTitle = 'Vos prochaines étapes';

/// Le conseil affiché sous le bilan d'une session de production, dérivé du
/// niveau d'épreuve.
///
/// **Il vivait en double**, écrit à la main de chaque côté — et les deux copies
/// avaient divergé : registres opposés (le mobile tutoyait), paliers bas
/// formulés autrement, et surtout **une troisième et une quatrième copie de la
/// table démarche → palier**, celle-là même que `TargetProcedure` interdit de
/// réécrire dans un écran (seuils légaux du 1ᵉʳ janvier 2026). Ici la démarche
/// vient de [TargetLevel.demarcheLabel], comme partout ailleurs.
///
/// `null` (aucun niveau calculable) a son propre message : c'est le cas normal
/// d'un bilan dont l'IA n'a pas fini, et le dire vaut mieux que masquer le bloc.
///
/// ⚠️ Contrat gelé, miroir mot pour mot de `bilanProchainesEtapesMessage` côté
/// web.
String bilanProchainesEtapesMessage(NiveauCecrl? niveau) => switch (niveau) {
      NiveauCecrl.c1 || NiveauCecrl.c2 =>
        "Bravo, votre français est avancé. Le TCF IRN, lui, s'arrête au B2 : "
            'vous êtes au-dessus du palier le plus haut demandé.',
      NiveauCecrl.b2 =>
        'Excellent — niveau B2 sur cette épreuve, le palier demandé pour '
            '${TargetLevel.b2.demarcheLabel}. Il se juge sur les 4 épreuves '
            'sans moyenne : gardez ce niveau partout.',
      NiveauCecrl.b1 =>
        'Niveau B1 sur cette épreuve — le palier demandé pour '
            "${TargetLevel.b1.demarcheLabel}, à condition de l'atteindre aussi "
            'dans les 3 autres épreuves. Visez le B2 pour '
            '${TargetLevel.b2.demarcheLabel}.',
      NiveauCecrl.a2 =>
        'Niveau A2 sur cette épreuve — le palier demandé pour '
            "${TargetLevel.a2.demarcheLabel}, à condition de l'atteindre aussi "
            'dans les 3 autres épreuves. Visez le B1 pour '
            '${TargetLevel.b1.demarcheLabel}.',
      NiveauCecrl.a1 =>
        'Les bases sont là. Entraînez-vous régulièrement sur des productions '
            'plus complètes pour progresser vers le A2.',
      NiveauCecrl.a1NonAtteint =>
        'Reprenez les bases : des phrases courtes et correctes d\'abord. '
            'Chaque entraînement compte.',
      null =>
        "Dès que l'IA a évalué vos 3 tâches, votre niveau d'épreuve s'affiche "
            'ici avec des conseils ciblés.',
    };

/// Le rappel d'enjeu : le niveau obtenu, mis en face de la démarche visée.
class DemarcheRappel {
  const DemarcheRappel({required this.atteint, required this.text});

  /// La production atteint (ou dépasse) le niveau exigé par la démarche.
  final bool atteint;
  final String text;
}

/// Le vrai anti-découragement : relier le niveau obtenu à **ce que le candidat
/// est venu chercher**.
///
/// Un candidat qui vise la carte de séjour pluriannuelle et qui obtient A2 est
/// au niveau demandé — personne ne le lui disait, et il lisait sa note comme une
/// catastrophe scolaire. Les deux cas se traitent avec le même soin : la
/// réussite se dit clairement, l'objectif encore devant se dit sans dramatiser.
///
/// `null` quand le niveau visé est inconnu : **rien** vaut mieux qu'un message
/// générique qui parlerait d'une démarche que le candidat n'a pas choisie.
DemarcheRappel? demarcheRappel(TargetLevel? cible, NiveauCecrl? niveau) {
  if (cible == null || niveau == null) return null;
  final demande =
      'Le niveau ${cible.wire} est celui demandé pour ${cible.demarcheLabel}.';
  if (niveau.tcfPalierIndex >= cible.asNiveau.tcfPalierIndex) {
    return DemarcheRappel(
      atteint: true,
      text: "$demande Cette production l'atteint.",
    );
  }
  final constat = niveau == NiveauCecrl.a1NonAtteint
      ? "Cette production n'atteint pas encore le niveau A1"
      : 'Cette production est au niveau ${niveau.displayName}';
  return DemarcheRappel(
    atteint: false,
    text: '$demande $constat : continuez à vous entraîner.',
  );
}
