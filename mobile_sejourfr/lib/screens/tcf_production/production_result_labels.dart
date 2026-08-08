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

/// Sur-titre de la section « version au niveau visé ». Elle ne montre **pas**
/// la production du candidat : elle montre la marche au-dessus. Le dire dès le
/// sur-titre est la seule protection contre la lecture « voilà ce que j'ai
/// écrit ».
const String kVersionCibleeEyebrow = 'La marche au-dessus';

/// Titre de la section : il nomme le niveau visé et emploie le conditionnel —
/// c'est un modèle possible, pas la seule bonne réponse.
String versionCibleeTitle(TargetLevel niveauVise) =>
    'Au niveau ${niveauVise.wire}, votre réponse pourrait ressembler à ceci';

/// Sous-titre : il **désamorce la confusion** (« ce n'est pas votre texte ») et
/// relie le niveau visé à la démarche du candidat.
///
/// Volontairement pas la phrase du rappel d'enjeu du hero ([demarcheRappel]) :
/// les deux blocs parlent de la même démarche, les répéter mot pour mot ferait
/// lire deux fois la même chose. Ici on nomme l'objectif, là-bas on dit où en
/// est la production.
String versionCibleeIntro(TargetLevel niveauVise) =>
    "Ce texte n'est pas le vôtre : c'est un modèle rédigé au niveau "
    '${niveauVise.wire}, celui qui ouvre ${niveauVise.demarcheLabel}.';

/// Intertitre des leviers. « Ce qui vous en sépare » et non « ce qui vous
/// manque » : on décrit une distance à parcourir, pas un déficit.
const String kVersionCibleeLeviersTitle = 'Ce qui vous en sépare';

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
