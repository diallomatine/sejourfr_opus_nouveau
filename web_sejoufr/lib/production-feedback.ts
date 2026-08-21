// Règles de LECTURE d'une évaluation de production EE/EO. Volontairement pures
// et sans dépendance React : ce sont les décisions qui rendent l'écran de
// restitution honnête (quel niveau on ose afficher, où se lit une note sur
// l'échelle du TCF, ce qu'on regroupe), et elles doivent être testables seules.
//
// Miroir mobile : `mobile_sejourfr/lib/screens/tcf_production/`.

import type {
    BandeCritere,
    ConfianceEvaluation,
    EeAccomplishment,
    EeAccomplishmentPoint,
    EvaluationResultDto,
    NiveauCecrl,
    ObjectifAccomplissement,
    SituationDansNiveau,
    TargetLevel,
} from "./types";

// ---------------------------------------------------------------------------
// Échelle du TCF
// ---------------------------------------------------------------------------

/** Une bande de l'échelle officielle du TCF IRN sur les épreuves d'expression.
 *  `min`/`max` sont des bornes incluses, en points sur 20. */
export interface TcfNoteBand {
    niveau: NiveauCecrl;
    /** Libellé court affiché sous la bande. */
    label: string;
    min: number;
    max: number;
}

/**
 * La table officielle du TCF, telle quelle. Notre note **est** celle du TCF
 * depuis la grille v6 : il n'y a rien à convertir, seulement à faire lire.
 * C'est tout l'enjeu de l'écran — un 4,5/20 n'est pas un échec scolaire, c'est
 * un A2.
 */
export const TCF_NOTE_BANDS: readonly TcfNoteBand[] = [
    {niveau: "A1_NON_ATTEINT", label: "A1 non atteint", min: 0, max: 0},
    {niveau: "A1", label: "A1", min: 1, max: 1},
    {niveau: "A2", label: "A2", min: 2, max: 5},
    {niveau: "B1", label: "B1", min: 6, max: 9},
    {niveau: "B2", label: "B2", min: 10, max: 20},
];

/**
 * Palier d'une note sur l'échelle du TCF : la DERNIÈRE bande dont le minimum est
 * atteint — même lecture que le serveur (`>= 10 → B2`, `>= 6 → B1`, …), donc une
 * note à décimale entre deux bandes (5,5) reste dans la bande basse, comme le
 * niveau calculé côté backend.
 *
 * `null` quand il n'y a pas de note exploitable : ne rien conclure est moins
 * faux que retomber sur l'index 0 et **inventer** un « A1 non atteint ».
 *
 * ⚠️ Cette fonction ne sert plus qu'à **teinter** et à relire une bande de
 * critère ancienne. Plus rien n'affiche une note de tâche : miroir de
 * `TcfNoteScale.bandIndexFor` côté mobile.
 */
export function tcfBandIndex(note: number | null | undefined): number | null {
    if (note == null || !Number.isFinite(note)) return null;
    const clamped = Math.max(0, Math.min(20, note));
    let bandIndex = 0;
    for (let i = 0; i < TCF_NOTE_BANDS.length; i++) {
        if (clamped >= TCF_NOTE_BANDS[i].min) bandIndex = i;
    }
    return bandIndex;
}

/**
 * Rang d'un niveau sur l'échelle du TCF IRN (0 = A1 non atteint … 4 = B2).
 *
 * C'est lui qui situe le palier atteint sur la barre du hero et qui compare le
 * niveau obtenu au niveau visé par la démarche. Les valeurs historiques C1/C2
 * sont rabattues sur le plafond B2 de l'examen. Miroir de
 * `NiveauCecrl.tcfPalierIndex` côté mobile.
 */
export function tcfPalierIndex(niveau: NiveauCecrl): number {
    switch (niveau) {
        case "A1_NON_ATTEINT":
            return 0;
        case "A1":
            return 1;
        case "A2":
            return 2;
        case "B1":
            return 3;
        case "B2":
        case "C1":
        case "C2":
            return 4;
    }
}

/**
 * Teinte d'un palier du TCF. **Le rouge n'en fait pas partie**, et pas
 * seulement sur les badges : l'identité visuelle réserve le Rouge France aux
 * CTA critiques, et aucun palier atteint n'est une faute — un A1 est un
 * résultat. La progression est donc ambre (jusqu'à A2, « à consolider »), bleu
 * (B1), vert (B2).
 */
export type TcfTone = "amber" | "blue" | "green";

/** Teinte telle qu'un affichage la consomme : `"neutral"` quand il n'y a pas
 *  (encore) de palier à teinter. Une production non évaluée n'est pas un échec —
 *  elle est grise, jamais rouge. */
export type TcfNoteTone = TcfTone | "neutral";

/**
 * Teinte d'un palier, dérivée du **niveau** et de rien d'autre.
 *
 * Surtout pas de la position dans {@link TCF_NOTE_BANDS} : indexer par rang
 * ferait glisser silencieusement toutes les couleurs le jour où un palier
 * s'ajoute, sans la moindre erreur de compilation. Le `switch` exhaustif, lui,
 * refuse de compiler tant qu'un niveau n'a pas sa teinte.
 */
export function tcfNiveauTone(niveau: NiveauCecrl): TcfTone {
    switch (niveau) {
        case "B2":
        case "C1":
        case "C2":
            return "green";
        case "B1":
            return "blue";
        case "A2":
        case "A1":
        case "A1_NON_ATTEINT":
            return "amber";
    }
}

/**
 * Teinte d'un résultat de tâche, `"neutral"` quand il n'y a pas de palier.
 *
 * Une teinte ne se dérive plus jamais d'une note : rien n'affiche plus la note
 * d'une tâche, et un seuil « sur 20 » n'avait de toute façon aucun sens ici —
 * 12/20 vaut B2, le niveau le plus haut de l'examen, le colorer en rouge
 * revenait à peindre la meilleure note possible en échec. Une production pas
 * encore évaluée est grise, jamais rouge.
 */
export function tacheNiveauTone(niveau: NiveauCecrl | null | undefined): TcfNoteTone {
    return niveau == null ? "neutral" : tcfNiveauTone(niveau);
}

/**
 * Bande qualitative d'un critère d'une évaluation **ancienne** — celles d'avant
 * que le serveur ne renvoie `bande`, seules à ne porter qu'une note.
 *
 * Depuis la grille v6, un critère se note sur la **même échelle du TCF** (celle
 * sur laquelle nous exprimons nos estimations) que la
 * note globale : sa bande se lit donc sur {@link TCF_NOTE_BANDS}, exactement
 * comme le serveur la calcule aujourd'hui (`BandeCritere.of`, bornes 10 / 6 /
 * 2). D'où l'absence de tout seuil propre : un critère à 12 est un B2, pas un
 * échec, et il ne doit pas s'afficher autrement qu'un critère moderne à 12.
 *
 * Une note nulle ou absente n'est pas une performance faible mais l'absence de
 * performance (hors-sujet, « en deçà du A1 ») : `NON_EVALUABLE`, même lecture
 * que le serveur.
 */
export function critereBandeFromNote(note: number | null | undefined): BandeCritere {
    const index = note != null && note > 0 ? tcfBandIndex(note) : null;
    if (index == null) return "NON_EVALUABLE";
    switch (TCF_NOTE_BANDS[index].niveau) {
        case "B2":
        case "C1":
        case "C2":
            return "TRES_BONNE_MAITRISE";
        case "B1":
            return "SATISFAISANT";
        case "A2":
            return "EN_COURS_ACQUISITION";
        case "A1":
        case "A1_NON_ATTEINT":
            return "FRAGILE";
    }
}

// ---------------------------------------------------------------------------
// Niveau et confiance
// ---------------------------------------------------------------------------

/**
 * La production a-t-elle été jugée **inexploitable** par les contrôles
 * déterministes du serveur (vide, quasi vide, langue non française, recopiage
 * de la consigne) ? Aucun correcteur n'a alors été appelé : il n'y a ni note,
 * ni niveau, ni `scores_criteres` — seulement des **raisons**.
 *
 * ⚠️ **Le fait se lit sur `evaluabilite`, jamais sur la nullité d'un autre
 * champ.** Une évaluation ancienne peut n'avoir ni niveau ni confiance sans
 * être inexploitable pour autant : déduire ce fait d'un trou reviendrait à
 * annoncer « rien à observer » sur un rapport parfaitement valide.
 *
 * Un backend antérieur au champ ne le sert pas : l'absence vaut donc
 * `EVALUABLE`, jamais l'inverse.
 */
export function productionNonEvaluable(
    evaluation: Pick<EvaluationResultDto, "evaluabilite"> | null | undefined,
): boolean {
    return evaluation?.evaluabilite === "NON_EVALUABLE";
}

/**
 * Garde-fou produit, porté ici et nulle part ailleurs : **on n'annonce jamais
 * un niveau sans savoir ce qu'il vaut**. Sans confiance, l'écran n'annonce rien.
 */
export function canShowNiveau(
    niveau: NiveauCecrl | null | undefined,
    confiance: ConfianceEvaluation | null | undefined,
): boolean {
    return niveau != null && confiance != null;
}

/**
 * Le niveau **affichable** d'une tâche, ou `null` quand il n'y a rien
 * d'honnête à montrer : évaluation trop ancienne pour porter un niveau, ou
 * niveau sans sa confiance ({@link canShowNiveau}).
 *
 * Aucun front ne recalcule un niveau — il est dérivé serveur — donc l'absence
 * se dit (« Évaluée », « Traité »), elle ne se comble pas.
 */
export function tacheNiveau(
    evaluation: Pick<EvaluationResultDto, "niveauObserve" | "confiance"> | null | undefined,
): NiveauCecrl | null {
    if (!evaluation) return null;
    return canShowNiveau(evaluation.niveauObserve, evaluation.confiance)
        ? evaluation.niveauObserve
        : null;
}

/**
 * Le niveau d'UNE tâche, tel qu'il s'affiche dans une liste : détail par tâche
 * du bilan de session, sujets déjà traités, historique.
 *
 * C'est ce qui remplace la note /20 partout où elle décrivait une tâche isolée
 * (décision produit du 2026-08-08) : au TCF, un correcteur attribue un niveau
 * par tâche, jamais une note — le /20 ne porte que sur l'épreuve entière. Même
 * forme que la bande d'un critère (`bandeCritereLabel`), pour qu'un palier se
 * lise pareil d'un écran à l'autre ; sauf le plancher, où « Niveau A1 non
 * atteint » se contredirait tout seul.
 *
 * ⚠️ Contrat gelé, miroir mot pour mot de `tacheNiveauLabel` côté mobile.
 */
export function tacheNiveauLabel(niveau: NiveauCecrl): string {
    return niveau === "A1_NON_ATTEINT" ? "A1 non atteint" : `Niveau ${niveau}`;
}

/**
 * Badge d'un sujet **rendu mais sans niveau affichable** (évaluation encore en
 * vol, ou antérieure au contrat v4).
 *
 * ⚠️ Contrat gelé, miroir mot pour mot de `kTacheTraiteeLabel` côté mobile, qui
 * disait « Fait » — deux fronts, deux mots, pour le même état. Le filtre de la
 * liste de sujets dit « Traités » **des deux côtés** : le badge s'aligne dessus.
 * (Ne pas confondre avec `SkillPromptStatus.TREATED` = « Fait », qui appartient
 * au module Compétences et reste, lui, gelé sur son propre libellé.)
 */
export const TACHE_TRAITEE_LABEL = "Traité";

/** Même famille, pour une ligne de bilan : la tâche est corrigée mais son
 *  niveau n'est pas affichable. Miroir de `kTacheEvalueeLabel`. */
export const TACHE_EVALUEE_LABEL = "Évaluée";

/**
 * Même famille encore, mais un état **différent** : la production a été rendue
 * et il n'y avait **rien à observer** ({@link productionNonEvaluable}).
 *
 * ⚠️ Ne pas la confondre avec {@link TACHE_EVALUEE_LABEL}, qui dit « corrigée,
 * mais trop ancienne pour porter un niveau ». Ici la correction n'a jamais eu
 * lieu : aucun appel au correcteur n'a été émis. Écrire « Évaluée » sur cette
 * ligne laissait croire à un verdict, et rendait le détail incompréhensible.
 *
 * ⚠️ Contrat gelé, miroir mot pour mot de `kTacheNonEvaluableLabel` côté
 * mobile.
 */
export const TACHE_NON_EVALUABLE_LABEL = "Non analysée";

// ---------------------------------------------------------------------------
// Situation dans le palier
// ---------------------------------------------------------------------------

/**
 * Libellé autonome d'un cran, affichable **sans** le niveau (« Palier solide »).
 * Miroir au caractère près de `SituationDansNiveau.getLibelle()` côté serveur,
 * gelé par test des deux côtés.
 *
 * ⚠️ Règle de formulation : le haut de la bande A2 se dit « solide », **jamais**
 * « presque B1 ». Aucun des trois crans ne nomme un manque — c'est la
 * contrepartie de la note masquée : le candidat doit voir qu'il progresse
 * **dans** son palier, sans aucun chiffre.
 */
export const SITUATION_LIBELLES: Record<SituationDansNiveau, string> = {
    ENTREE_DE_PALIER: "Palier atteint",
    PALIER_CONFIRME: "Palier confirmé",
    PALIER_SOLIDE: "Palier solide",
};

/** Adjectif seul, pour composer avec un niveau (« A2 solide »). Miroir de
 *  `SituationDansNiveau.getQualificatif()`. */
export const SITUATION_QUALIFICATIFS: Record<SituationDansNiveau, string> = {
    ENTREE_DE_PALIER: "atteint",
    PALIER_CONFIRME: "confirmé",
    PALIER_SOLIDE: "solide",
};

export interface SituationView {
    cran: SituationDansNiveau;
    /** Forme autonome (« Palier solide »), pour un contexte où le niveau n'est
     *  pas déjà écrit à côté. Le hero, lui, affiche `libelleAvecNiveau`. */
    libelle: string;
    /** **Ce qui s'affiche au candidat** (« A2 solide »), conformément à
     *  `docs/notation-ia-eo-ee.md` §6.3 bis. Vient du serveur ; recomposé en
     *  dernier recours à partir du qualificatif. */
    libelleAvecNiveau: string;
}

/**
 * Ce qu'on affiche du cran de progression, ou `null` quand il n'y a rien à
 * situer.
 *
 * Deux verrous : le cran ne s'affiche **jamais sans le niveau qu'il nuance**
 * (une position dans une bande qu'on ne nomme pas ne veut rien dire), et il
 * suit la garde `canShowNiveau` — pas de confiance, pas de niveau, donc pas de
 * situation non plus.
 */
export function situationView(
    evaluation:
        | Pick<
              EvaluationResultDto,
              "niveauObserve" | "confiance" | "situationDansNiveau" | "situationDansNiveauLabel"
          >
        | null
        | undefined,
): SituationView | null {
    const niveau = tacheNiveau(evaluation);
    const cran = evaluation?.situationDansNiveau ?? null;
    if (!niveau || !cran) return null;
    return {
        cran,
        libelle: SITUATION_LIBELLES[cran],
        libelleAvecNiveau:
            evaluation?.situationDansNiveauLabel ?? `${niveau} ${SITUATION_QUALIFICATIFS[cran]}`,
    };
}

/**
 * Une confiance HAUTE est le cas normal : l'afficher n'apprend rien au candidat
 * et sème le doute sur une évaluation qui n'en mérite pas. On ne montre la
 * confiance (et ses raisons) que lorsqu'elle nuance vraiment le résultat.
 */
export function shouldShowConfiance(confiance: ConfianceEvaluation | null | undefined): boolean {
    return confiance != null && confiance !== "HAUTE";
}

/**
 * Ce que le résultat d'une tâche annonce : **le niveau, affirmé**.
 *
 * « Proche du niveau A2 » signifie « pas encore A2 » en français courant, alors
 * que le niveau EST A2 et que la pastille juste à côté le dit. Le plancher garde
 * son traitement propre : on n'est pas « proche » d'un niveau non atteint, et on
 * ne dit pas non plus à quelqu'un qu'il est « sous le A1 » — on dit ce qui reste
 * à faire.
 *
 * ⚠️ Contrat gelé, miroir mot pour mot de `ProductionResultsHero.levelLabel`
 * côté mobile.
 */
export function niveauAtteintLabel(niveau: NiveauCecrl): string {
    return niveau === "A1_NON_ATTEINT"
        ? "Votre production n'atteint pas encore le niveau A1"
        : `Votre production est au niveau ${niveau}`;
}

/**
 * Règle de lecture derrière la pastille d'information du panneau de niveau.
 *
 * Elle parlait de la **note** : depuis que le résultat d'une tâche n'en affiche
 * plus (au TCF, les correcteurs attribuent un niveau par tâche, jamais une note
 * — le /20 ne porte que sur l'épreuve entière), elle explique le **niveau**.
 * Laisser une info-bulle qui commente une note invisible serait pire que rien.
 */
export const NIVEAU_PORTEE_TACHE =
    "Ce niveau est une estimation : il décrit ce que cette production démontre, sur les " +
    "paliers du TCF. Il porte ici sur cette seule tâche — au TCF, le niveau d'une épreuve " +
    "est établi sur vos trois tâches réunies.";

/**
 * Ce que chaque palier du TCF ouvre comme démarche. Seuils en vigueur au
 * 1ᵉʳ janvier 2026.
 *
 * ⚠️ **Une seule table, ici.** C'est une donnée légale, pas une tournure : la
 * recopier dans un écran, c'est garantir qu'une des copies ne bougera pas le
 * jour où les seuils bougeront. Miroir de `TargetLevel.demarcheLabel` côté
 * mobile. Tout texte qui nomme une démarche passe par elle
 * ({@link demarcheRappel}, {@link bilanProchainesEtapesMessage}).
 */
const DEMARCHE_PAR_NIVEAU: Record<TargetLevel, string> = {
    A2: "la carte de séjour pluriannuelle",
    B1: "la carte de résident",
    B2: "la naturalisation",
};

export interface DemarcheRappel {
    /** La production atteint (ou dépasse) le niveau exigé par la démarche. */
    atteint: boolean;
    text: string;
}

/**
 * Le vrai anti-découragement : relier le niveau obtenu à **ce que le candidat
 * est venu chercher**.
 *
 * Un candidat qui vise la carte de séjour pluriannuelle et qui obtient A2 est au
 * niveau demandé — personne ne le lui disait, et il lisait sa note comme une
 * catastrophe scolaire. Les deux cas se traitent avec le même soin : la réussite
 * se dit clairement, l'objectif encore devant se dit sans dramatiser.
 *
 * `null` quand le niveau visé est inconnu : **rien** vaut mieux qu'un message
 * générique qui parlerait d'une démarche que le candidat n'a pas choisie.
 */
export function demarcheRappel(
    targetLevel: TargetLevel | null | undefined,
    niveau: NiveauCecrl | null | undefined,
): DemarcheRappel | null {
    if (!targetLevel || !niveau) return null;
    const demande = `Le niveau ${targetLevel} est celui demandé pour ${DEMARCHE_PAR_NIVEAU[targetLevel]}.`;
    if (tcfPalierIndex(niveau) >= tcfPalierIndex(targetLevel)) {
        return {atteint: true, text: `${demande} Cette production l'atteint.`};
    }
    const constat =
        niveau === "A1_NON_ATTEINT"
            ? "Cette production n'atteint pas encore le niveau A1"
            : `Cette production est au niveau ${niveau}`;
    return {atteint: false, text: `${demande} ${constat} : continuez à vous entraîner.`};
}

// ---------------------------------------------------------------------------
// Plan d'action vers le niveau visé
//
// ⚠️ Les libellés de ce bloc ne vivent plus ici : ils sont **partagés avec le
// module Compétences**, qui rend exactement le même plan après un
// micro-exercice (`skill-ui/ActionPlan` : `pourViserTitle`,
// `ACTION_PLAN_EXEMPLE_TITLE`, `ACTION_PLAN_REFORMULATIONS_TITLE`).
//
// Sont **supprimés** avec l'ancien bloc « la marche au-dessus » : son sur-titre,
// son titre (« Au niveau B2, votre réponse pourrait ressembler à ceci ») et son
// introduction (« Ce texte n'est pas le vôtre : c'est un modèle rédigé au niveau
// B2… »). Rien ne vérifie qu'un texte atteint le palier dont on l'étiquette, et
// un candidat qui a recopié un exemple annoncé B2 l'a vu noter B1. On garde
// l'objectif — « Pour viser B2 » —, qui lui est exact.
// ---------------------------------------------------------------------------

/**
 * `true` quand le plan d'action peut encore arriver, donc quand il faut
 * continuer de poller et l'annoncer au candidat.
 *
 * Le plan (`version_ciblee`) et son cas exclusif (`niveau_vise_atteint`)
 * viennent d'un **second appel LLM**, lancé par le serveur *après* que la
 * correction est persistée et la soumission passée à `EVALUATED` — hors
 * transaction, pour qu'il ne puisse jamais retarder ni faire échouer la
 * correction. Un écran qui s'arrête net sur `EVALUATED` s'affiche donc sans
 * plan alors qu'il arrive dix à quinze secondes plus tard : le candidat devait
 * sortir puis revenir. Durée du sursis : `ACTION_PLAN_GRACE_MS`
 * (`app/_components/skill-ui/ActionPlan`), commune avec le résultat d'un
 * micro-exercice, qui attend exactement le même bloc.
 *
 * ⚠️ `observedInFlight` — l'écran a vu la correction dans un statut non final
 * depuis son ouverture — est ce qui interdit d'attendre sur un rapport **rouvert
 * plus tard** : là, plus rien ne tourne côté serveur, le plan est déjà persisté
 * ou définitivement absent. Sans cette condition, une correction de trois jours
 * afficherait « on prépare tes conseils » pendant quinze secondes pour rien.
 *
 * L'absence de plan reste un cas **normal** (objectif déjà atteint sans que le
 * serveur l'ait dit, oral dégradé, second appel muet ou refusé) : à la fin du
 * sursis on rend l'écran tel quel, sans message, sans erreur.
 */
export function productionActionPlanMayStillArrive(input: {
    evaluated: boolean;
    /** La correction s'est terminée sous les yeux du candidat. */
    observedInFlight: boolean;
    hasVersionCiblee: boolean;
    hasNiveauViseAtteint: boolean;
}): boolean {
    return (
        input.evaluated &&
        input.observedInFlight &&
        !input.hasVersionCiblee &&
        !input.hasNiveauViseAtteint
    );
}

// ---------------------------------------------------------------------------
// Niveau visé déjà atteint
// ---------------------------------------------------------------------------

/**
 * Sur-titre de la section qui **remplace** la version au niveau visé quand le
 * palier est déjà tenu.
 *
 * Avant, cette section disparaissait sans un mot : depuis que
 * `version_amelioree` n'est plus affichée, le candidat qui réussit se retrouvait
 * sans aucun texte modèle et sans savoir pourquoi — sa réussite avait exactement
 * la même tête qu'une panne. Le serveur dit désormais laquelle des deux c'est
 * (`niveau_vise_atteint`), et on l'annonce.
 *
 * ⚠️ « Objectif atteint » désignait ici le PALIER, et le même libellé sert de
 * titre au bandeau de tête de rapport (`ProductionResultsHero.objectifTitle`
 * côté mobile, `objectifTitle` du hero côté web) pour dire que la CONSIGNE a
 * été accomplie — deux sens différents sous les mêmes mots. Vu en vrai : un
 * candidat noté B1 qui vise B2 lisait « Objectif atteint » en gros dans le
 * bandeau, exact au sens de la consigne, trompeur au sens du niveau. Le
 * bandeau garde son texte (il est suivi du résumé de consigne, le contexte
 * lève l'ambiguïté) ; ce sur-titre-ci, lui, change.
 *
 * ⚠️ Contrat gelé, miroir mot pour mot de `kNiveauViseAtteintEyebrow` côté mobile.
 */
export const NIVEAU_VISE_ATTEINT_EYEBROW = "Palier visé";

/**
 * Titre : la victoire, nommée par le palier. Volontairement **pas** la phrase du
 * hero (`niveauAtteintLabel` dit « Votre production est au niveau B2 ») — deux
 * blocs qui se recopient se lisent comme un bug d'affichage.
 */
export function niveauViseAtteintTitle(niveauVise: TargetLevel): string {
    return `Objectif ${niveauVise} : vous y êtes`;
}

/**
 * Sous-titre : il **explique l'absence** de texte modèle, sans un chiffre de
 * barème ni un mot de manque, et dit où porter l'effort maintenant.
 *
 * Il ne redit pas non plus ce que le palier ouvre comme démarche : le rappel
 * d'enjeu du hero (`demarcheRappel`) le fait déjà, à deux blocs d'écart.
 */
export const NIVEAU_VISE_ATTEINT_INTRO =
    "Cette production tient le palier que vous visez. Il n'y a donc pas de version d'un " +
    "niveau supérieur à vous montrer ici : l'enjeu est maintenant de tenir ce niveau sur " +
    "les trois tâches de l'épreuve.";

// ---------------------------------------------------------------------------
// Objectif de la tâche
// ---------------------------------------------------------------------------

export type ObjectifTone = "done" | "partial" | "missed";

export interface ObjectifPresentation {
    /** Le verdict, seul et capitalisé : il se lit sous l'eyebrow « OBJECTIF DE
     *  LA TÂCHE », pas au fil d'une phrase. */
    label: string;
    tone: ObjectifTone;
}

/** Null quand l'évaluation ne porte pas de verdict (toutes celles d'avant la
 *  grille v8) : le bandeau n'est alors pas rendu du tout. */
export function objectifPresentation(
    objectif: ObjectifAccomplissement | null | undefined,
): ObjectifPresentation | null {
    switch (objectif) {
        case "ATTEINT":
            return {label: "Atteint", tone: "done"};
        case "PARTIELLEMENT_ATTEINT":
            return {label: "Partiellement atteint", tone: "partial"};
        case "NON_ATTEINT":
            return {label: "Non atteint", tone: "missed"};
        default:
            return null;
    }
}

// ---------------------------------------------------------------------------
// Accomplissement détaillé
// ---------------------------------------------------------------------------

/** Les trois groupes de la check-list de consigne (parité mobile). Un manque
 *  exigé et une piste ignorée ne se lisent pas pareil : la seconde n'enlève
 *  aucun point, les mélanger fait paniquer pour rien. */
export interface AccomplishmentGroups {
    traites: EeAccomplishmentPoint[];
    manquesObligatoires: EeAccomplishmentPoint[];
    pistesNonAbordees: EeAccomplishmentPoint[];
}

/** Ne sert plus qu'à {@link treatedPointsSummary} depuis le retrait de « Voir
 *  l'analyse complète » : `pistesNonAbordees` n'est plus rendu nulle part (une
 *  piste n'enlève aucun point), mais reste séparé ici — c'est exactement ce qui
 *  garantit qu'aucune piste ne se glisse dans la fraction ni dans la liste des
 *  points oubliés. */
export function groupAccomplishment(
    acc: EeAccomplishment | null | undefined,
): AccomplishmentGroups {
    const oublies = acc?.pointsOublies ?? [];
    return {
        traites: acc?.pointsTraites ?? [],
        manquesObligatoires: oublies.filter((p) => p.obligatoire),
        pistesNonAbordees: oublies.filter((p) => !p.obligatoire),
    };
}

/** Ce que résume le bandeau « Ce qui marche » : les points **obligatoires**
 *  traités sur ceux qui étaient demandés. */
export interface TreatedPointsSummary {
    done: number;
    total: number;
    libelles: string[];
    /** Les points **exigés** non traités. Ils vivent dans le même dépliant que
     *  `libelles` depuis le retrait de « Voir l'analyse complète » (contrat
     *  v15/v9) : sans eux, le candidat lit « 2/3 points traités » sans jamais
     *  savoir lequel manque — or c'est celui-là qui lui coûte des points. */
    oublies: string[];
}

/**
 * Compteur du bandeau « Ce qui marche ».
 *
 * Les pistes sont exclues **des deux côtés** : ne pas traiter une piste
 * n'enlève aucun point, l'inclure au dénominateur ferait lire « 3/5 » à une
 * consigne entièrement remplie. `null` quand la consigne n'exigeait rien
 * d'identifiable (évaluations antérieures aux rubriques v8) — le bandeau se
 * rabat alors sur le compte de points forts.
 */
export function treatedPointsSummary(
    acc: EeAccomplishment | null | undefined,
): TreatedPointsSummary | null {
    if (!acc) return null;
    const groups = groupAccomplishment(acc);
    const traites = groups.traites.filter((p) => p.obligatoire);
    const total = traites.length + groups.manquesObligatoires.length;
    if (total === 0) return null;
    return {
        done: traites.length,
        total,
        libelles: traites.map((p) => p.libelle),
        oublies: groups.manquesObligatoires.map((p) => p.libelle),
    };
}

/** Découpage d'un texte autour du passage à surligner. */
export interface HighlightSplit {
    before: string;
    match: string;
    after: string;
}

/**
 * Repère dans la production la phrase visée par la priorité n° 1.
 *
 * **Première occurrence exacte, et rien d'autre** : si le correcteur a recomposé
 * la phrase, on ne surligne rien plutôt que de désigner le mauvais passage. Un
 * repère faux coûte plus cher que pas de repère.
 */
export function splitHighlight(
    texte: string,
    cible: string | null | undefined,
): HighlightSplit | null {
    const needle = (cible ?? "").trim();
    if (!needle) return null;
    const start = texte.indexOf(needle);
    if (start < 0) return null;
    return {
        before: texte.slice(0, start),
        match: texte.slice(start, start + needle.length),
        after: texte.slice(start + needle.length),
    };
}

// ---------------------------------------------------------------------------
// Bilan d'épreuve : ce qu'on écrit à la place du niveau global
// ---------------------------------------------------------------------------

/** Attente normale : le pipeline IA tourne encore sur au moins une tâche. */
export const BILAN_NIVEAU_PENDING_LABEL = "Évaluation en cours…";

/** Une correction a échoué de notre côté. Le serveur suspend alors le niveau
 *  d'épreuve — il ne compte pas 0 une tâche que le candidat a bien rendue
 *  (`ProductionSubmissionService.bilan`, garde `anyFailed`). L'annoncer « en
 *  cours » était donc faux ET sans fin : rien ne tourne, c'est une relance qui
 *  débloque le niveau. Vécu le 2026-08-06 sur un examen blanc EO dont deux
 *  tâches sur trois avaient échoué. Miroir mobile : `BilanHero.needsRetry`. */
export const BILAN_NIVEAU_RETRY_LABEL = "Évaluation à relancer";

/** Texte du badge « Niveau global » tant qu'aucun niveau n'est calculable. */
export function bilanNiveauPendingLabel(anyFailed: boolean): string {
    return anyFailed ? BILAN_NIVEAU_RETRY_LABEL : BILAN_NIVEAU_PENDING_LABEL;
}

/**
 * Titre du conseil de fin de bilan.
 *
 * ⚠️ Il **vouvoie**, comme tout le reste de la restitution
 * (`niveauAtteintLabel`, `demarcheRappel`, `NIVEAU_VISE_ATTEINT_INTRO`). Il
 * disait « Tes prochaines étapes » au-dessus d'un corps qui vouvoyait : deux
 * registres dans le même encart. Miroir mot pour mot de
 * `kBilanProchainesEtapesTitle` côté mobile.
 */
export const BILAN_PROCHAINES_ETAPES_TITLE = "Vos prochaines étapes";

/**
 * Le conseil affiché sous le bilan d'une session de production, dérivé du
 * niveau d'épreuve.
 *
 * **Il vivait en double**, écrit à la main de chaque côté — et les deux copies
 * avaient divergé : registres opposés (le mobile tutoyait), paliers bas
 * formulés autrement, et surtout **une troisième et une quatrième copie de la
 * table démarche → palier**, celle-là même que `TargetProcedure` interdit de
 * réécrire dans un écran (seuils légaux du 1ᵉʳ janvier 2026). Ici la démarche
 * vient de {@link DEMARCHE_PAR_NIVEAU}, comme partout ailleurs.
 *
 * `null` (aucun niveau calculable) a son propre message : c'est le cas normal
 * d'un bilan dont l'IA n'a pas fini, et le dire vaut mieux que masquer le bloc.
 *
 * ⚠️ Contrat gelé, miroir mot pour mot de `bilanProchainesEtapesMessage` côté
 * mobile.
 */
export function bilanProchainesEtapesMessage(niveau: NiveauCecrl | null | undefined): string {
    switch (niveau) {
        case "C1":
        case "C2":
            return (
                "Bravo, votre français est avancé. Le TCF IRN, lui, s'arrête au B2 : vous êtes " +
                "au-dessus du palier le plus haut demandé."
            );
        case "B2":
            return (
                `Excellent — niveau B2 sur cette épreuve, le palier demandé pour ` +
                `${DEMARCHE_PAR_NIVEAU.B2}. Il se juge sur les 4 épreuves sans moyenne : ` +
                "gardez ce niveau partout."
            );
        case "B1":
            return (
                `Niveau B1 sur cette épreuve — le palier demandé pour ${DEMARCHE_PAR_NIVEAU.B1}, ` +
                "à condition de l'atteindre aussi dans les 3 autres épreuves. Visez le B2 pour " +
                `${DEMARCHE_PAR_NIVEAU.B2}.`
            );
        case "A2":
            return (
                `Niveau A2 sur cette épreuve — le palier demandé pour ${DEMARCHE_PAR_NIVEAU.A2}, ` +
                "à condition de l'atteindre aussi dans les 3 autres épreuves. Visez le B1 pour " +
                `${DEMARCHE_PAR_NIVEAU.B1}.`
            );
        case "A1":
            return (
                "Les bases sont là. Entraînez-vous régulièrement sur des productions plus " +
                "complètes pour progresser vers le A2."
            );
        case "A1_NON_ATTEINT":
            return (
                "Reprenez les bases : des phrases courtes et correctes d'abord. Chaque " +
                "entraînement compte."
            );
        default:
            return (
                "Dès que l'IA a évalué vos 3 tâches, votre niveau d'épreuve s'affiche ici avec " +
                "des conseils ciblés."
            );
    }
}
