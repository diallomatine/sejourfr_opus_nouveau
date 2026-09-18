/**
 * Le **Plan adaptatif** : ce que les écrans disent des quatre domaines du TCF,
 * du cycle de palier, de la séance et de ce qui a changé.
 *
 * 🛑 **Le serveur expose des FAITS, jamais des phrases** (`PlanDomainDto`,
 * `PlanCycleDto`, `PlanSeanceDto`, `PlanRecentChangesDto`). Les libellés vivent
 * donc ici, **déclarés une seule fois pour tout le web** — c'est la recopie
 * d'une chaîne dans un composant qui avait fait diverger le web du mobile.
 *
 * 🛑 **Aucune règle métier ici.** L'ordre des domaines, l'urgence, le palier
 * bloquant, l'exercice désigné et le verrou viennent du serveur : ce module ne
 * fait que **traduire**, jamais décider. Les deux pièges du contrat, rappelés
 * une dernière fois :
 *
 * 1. une **série ciblée** est un `TRAINING` — elle ne rend jamais un domaine
 *    « évalué », c'est `domainesAEvaluer` qui dit par quoi le mesurer ;
 * 2. `domaines` est **déjà trié** par le serveur — on ne retrie pas.
 */

import {
    competenceHref,
    PLAN_MILESTONE_PILL,
    productionSectionLabel,
    skillTaskNumber,
} from "@/lib/diagnostic";
import {journeyStepSubtitle, journeyStepTitle} from "@/lib/journey";
import {
    type JourneyDto,
    type JourneyStepDto,
    type LearningPlanDto,
    type LearningPlanPriorityDto,
    type LearningPlanSkillStatus,
    type NiveauCecrl,
    niveauCecrlLabel,
    PLAN_ACTION_NATURE_LABEL,
    PLAN_SKILL_STEP_STATE_LABEL,
    type PlanExerciseKind,
    type PlanSkillStepState,
    type PlanActionNature,
    type PlanCycleDto,
    type PlanDomainAssessmentDto,
    type PlanDomainDto,
    type PlanDomainLevelDto,
    type PlanDomainSkillDto,
    type PlanDomainTaskDto,
    type PlanRecentChangesDto,
    type PlanSeanceAssessmentItemDto,
    type PlanSeanceItemDto,
    type PlanSkillExerciseDto,
    type PlanMasteryTransitionDto,
    SKILL_MASTERY_STATE_LABEL,
    SKILL_SECTION_LABEL,
    type SkillMasteryState,
    type SkillSection,
    type SkillTaskCode,
    type TargetLevel,
} from "@/lib/types";

/** Les quatre épreuves que le Plan suit. Alias local : le tapuscrit complet
 *  (`Extract<EpreuveType, …>`) est illisible en signature. */
export type PlanDomainEpreuve = PlanDomainDto["epreuve"];

/** Épreuve → domaine de compétence. C'est ce qui permet de réutiliser
 *  `SKILL_SECTION_LABEL` et `productionSectionLabel` au lieu d'écrire une
 *  seconde table de libellés de domaine. */
export const PLAN_DOMAIN_SECTION: Record<PlanDomainEpreuve, SkillSection> = {
    TCF_CO: "CO",
    TCF_CE: "CE",
    TCF_EO: "EO",
    TCF_EE: "EE",
};

/** Segment d'URL d'un domaine (`/plan/domaine/co`). Le pendant exact de
 *  `PLAN_DOMAIN_SECTION`, en minuscules. */
export function planDomainSlug(epreuve: PlanDomainEpreuve): string {
    return PLAN_DOMAIN_SECTION[epreuve].toLowerCase();
}

/** Le slug d'URL inverse. `null` sur un segment inconnu — l'écran rend alors
 *  un « domaine introuvable », jamais un domaine par défaut. */
export function planDomainFromSlug(slug: string): PlanDomainEpreuve | null {
    const wanted = slug.trim().toUpperCase();
    const found = (Object.keys(PLAN_DOMAIN_SECTION) as PlanDomainEpreuve[])
        .find((epreuve) => PLAN_DOMAIN_SECTION[epreuve] === wanted);
    return found ?? null;
}

/** Nom complet du domaine (« Compréhension orale »). */
export function planDomainLabel(epreuve: PlanDomainEpreuve): string {
    return SKILL_SECTION_LABEL[PLAN_DOMAIN_SECTION[epreuve]];
}

/** Repère court d'un domaine, pour les eyebrows et les pastilles (« CO »). */
export function planDomainShort(epreuve: PlanDomainEpreuve): string {
    return PLAN_DOMAIN_SECTION[epreuve];
}

/** Fiche d'un domaine dans le Plan. */
export function planDomainHref(epreuve: PlanDomainEpreuve): string {
    return `/plan/domaine/${planDomainSlug(epreuve)}`;
}

/** Un domaine de compréhension se travaille en séries ciblées, un domaine
 *  d'expression en petits sujets et en productions. Deux familles, jamais
 *  déduites d'un champ nul. */
export function isComprehension(section: SkillSection): section is "CO" | "CE" {
    return section === "CO" || section === "CE";
}

/* --------------------------------------------------------------- libellés */

/** Ce qu'on lit sous le nom d'un domaine. 🛑 « Pas encore évaluée » n'est pas un
 *  défaut : `evaluated === false` veut dire *inconnu*, jamais *mauvais*. */
export const PLAN_DOMAIN_NOT_EVALUATED = "Pas encore évaluée";

export function planDomainLevelLine(domain: PlanDomainDto): string {
    if (!domain.evaluated || !domain.niveau) return PLAN_DOMAIN_NOT_EVALUATED;
    return `Niveau estimé ${niveauCecrlLabel(domain.niveau)}`;
}

/** Combien de domaines sont réellement mesurés. **Le compte se lit sur le
 *  cycle**, jamais sur la longueur de `domainesAEvaluer` : trois surfaces qui
 *  compteraient chacune de leur côté finiraient par se contredire. */
export function planProfileCountLabel(cycle: PlanCycleDto): string {
    const {domainsEvaluated: n, domainsExpected: total} = cycle;
    return `${n} domaine${n > 1 ? "s" : ""} sur ${total} évalué${n > 1 ? "s" : ""}`;
}

/** Titre de l'écran. `objectiveLevel` peut être `null` — le candidat n'a
 *  déclaré ni démarche ni palier — et on n'invente **jamais** « B2 » à sa
 *  place. */
export function planTitle(cycle: PlanCycleDto): string {
    return cycle.objectiveLevel ? `Mon plan vers le ${cycle.objectiveLevel}` : "Mon plan";
}


/** La phrase de tête : d'où l'on part, ce que le cycle construit. Composée de
 *  faits servis, sans aucun chiffre écrit ici. */
export function planCycleLine(cycle: PlanCycleDto): string {
    const from = cycle.startingLevel ? niveauCecrlLabel(cycle.startingLevel) : null;
    if (!from) return `Votre plan construit d'abord votre ${cycle.targetLevel}.`;
    return `Niveau estimé ${from} · votre plan construit d'abord votre ${cycle.targetLevel}.`;
}

/** Ce qu'annonce l'état du cycle, en une phrase. Les quatre états sont servis
 *  par le serveur et se disent au candidat, pas en jargon. */
export const PLAN_CYCLE_STATE_TEXT: Record<PlanCycleDto["state"], string> = {
    BUILDING_BASELINE:
        "Il manque des mesures : complétez votre profil pour que le plan cible les bons paliers.",
    TRAINING: "Votre entraînement cible les compétences qui bloquent le palier en cours.",
    READY_FOR_GATE_MOCK:
        "Le travail de ce palier est fait : il reste à le confirmer par un examen blanc TCF complet.",
    TARGET_STABILIZATION:
        "Votre objectif est atteint sur les domaines mesurés : on entretient et on remesure.",
};

/* ------------------------------------------------------------------ chemin */







/* ------------------------------------------------------- ma progression */

/**
 * **« Ma progression »** — l'écran de suivi adossé au Plan.
 *
 * ⚠️ **À ne pas confondre avec `/statistiques`**, qui reste et garde sa propre
 * entrée : celui-là répond à « quels thèmes ai-je révisés, combien de séries
 * ai-je jouées ? », celui-ci à « où j'en suis sur les quatre domaines du TCF,
 * et à quelle distance de mon objectif ? ».
 */
export const PLAN_PROGRESS_HREF = "/plan/progression";

/** Le libellé de l'action qui ouvre l'écran, et son titre quand l'objectif
 *  n'est pas connu. */
export const PLAN_PROGRESS_TITLE_SHORT = "Ma progression";

/**
 * Le titre de l'écran.
 *
 * 🛑 **`objectiveLevel` est NULLABLE et aucun front n'invente « B2 »** : sans
 * démarche déclarée, le titre se lit simplement « Ma progression ». La maquette
 * l'écrit en dur, ce qui retirerait son A2 à un dossier CSP.
 */
export function planProgressTitle(cycle: PlanCycleDto): string {
    return cycle.objectiveLevel
        ? `${PLAN_PROGRESS_TITLE_SHORT} vers le ${cycle.objectiveLevel}`
        : PLAN_PROGRESS_TITLE_SHORT;
}

export const PLAN_PROGRESS_TEXT =
    "Ce que vos passages ont mesuré, domaine par domaine, et ce que votre plan en construit.";

/* Les deux étiquettes de la carte de tête. */
export const PLAN_PROGRESS_LEVEL_LABEL = "Niveau estimé";
export const PLAN_PROGRESS_OBJECTIVE_LABEL = "Objectif";

/** Ce que porte la carte de tête quand rien n'a encore été mesuré. *null =
 *  inconnu, jamais mauvais* : on ne pose pas « A1 » à la place. */
export const PLAN_PROGRESS_LEVEL_UNKNOWN = "Pas encore mesuré";

/** La phrase d'un domaine jamais mesuré, sur cet écran. Elle dit une **absence
 *  de mesure**, jamais une faiblesse. */
export const PLAN_PROGRESS_DOMAIN_EMPTY =
    "Aucun passage réel sur ce domaine pour l'instant : son niveau reste inconnu tant qu'il n'a pas été mesuré.";

/**
 * La note de pied de l'écran.
 *
 * ⚠️ Elle ne parle **pas** de pourcentages, contrairement à la maquette : le
 * score interne du moteur de maîtrise n'est exposé à aucun front, et l'écran
 * affiche des **états**, pas des chiffres. Écrire « les pourcentages sont une
 * maîtrise interne » sous un écran qui n'en montre aucun serait faux.
 */
export const PLAN_PROGRESS_NOTE =
    "Estimation d'entraînement SejourFR, non officielle : elle situe votre travail, elle ne remplace pas le résultat du TCF.";

/** La ligne sous le nom d'un domaine : son niveau estimé, et le palier qu'il
 *  travaille quand le serveur en désigne un. */
export function planDomainProgressLine(domain: PlanDomainDto): string {
    const base = planDomainLevelLine(domain);
    return domain.evaluated && domain.blockingLevel
        ? `${base} · travaille le ${domain.blockingLevel}`
        : base;
}

/** « 3 / 8 compétences observées ». **Ce n'est pas une note** : une compétence
 *  non observée est une compétence que le candidat n'a pas encore eu
 *  l'occasion de montrer, et le dénominateur vient de la base. */
export function planTaskObservedLabel(tache: PlanDomainTaskDto): string {
    return `${tache.observedSkills} / ${tache.totalSkills} compétences observées`;
}

/** Le repère d'un palier de compréhension hors de sa fiche : ce qu'il est, et
 *  s'il bloque la suite. */
export const PLAN_PROGRESS_BLOCKING_LEVEL = "Palier bloquant";

export function planLevelRowMeta(palier: PlanDomainLevelDto): string {
    return palier.blocking ? PLAN_PROGRESS_BLOCKING_LEVEL : `Palier ${palier.niveau}`;
}

/* ------------------------------------------------------ compléter le profil */

/** 🛑 La phrase que la séance ne doit jamais laisser croire l'inverse : une
 *  série ciblée entraîne, elle ne mesure pas. */
export const PLAN_COMPLETE_PROFILE_NOTE =
    "Les séries ciblées font progresser vos compétences, mais ne remplacent pas un examen blanc : c'est lui qui donne un niveau au domaine.";

/** Par quoi mesurer ce domaine — le CTA nomme le parcours réel, jamais un
 *  contenu inventé.
 *
 *  🛑 **Le même geste sur les quatre épreuves**, parce que c'est la même chose
 *  qui se lance : un examen blanc (de module en CO/CE, de production en EE/EO). */
export function planAssessmentCta(_assessment: PlanDomainAssessmentDto): string {
    return "Passer l'examen blanc";
}

/** Le parcours **réel** qu'ouvre une mesure, nommé tel quel. Aucun contenu
 *  n'est créé : les deux natures existent déjà. */
export function planAssessmentNature(assessment: PlanDomainAssessmentDto): string {
    return `Examen blanc n°${assessment.slotNumber ?? 1}`;
}

/** Le repère factuel de la ligne : la nature du passage et sa durée quand elle
 *  en a une (l'expression orale se chronomètre tâche par tâche — on n'écrit
 *  alors aucune minute). */
export function planAssessmentMeta(assessment: PlanDomainAssessmentDto): string {
    const nature = planAssessmentNature(assessment);
    return assessment.estimatedMinutes
        ? `${nature} · ≈ ${assessment.estimatedMinutes} min`
        : nature;
}

/* ------------------------------------------------------------ lignes fermées

   Ce que porte une ligne verrouillée, dit **net**. Le contenu réel part sous
   `PlanBlur`, donc hors de l'arbre d'accessibilité : sans ces deux phrases, la
   ligne n'aurait plus de nom accessible du tout. Elles ne divulguent rien de ce
   que le flou cache — elles disent qu'il y a quelque chose et comment l'ouvrir,
   ce qui reste vrai pour tout le monde.

   🛑 Déclarées ici, jamais recopiées dans un composant : la fiche d'un domaine
   liste les mêmes priorités que le Plan et doit les fermer de la même façon. */

export const PLAN_LOCKED_SEANCE_LABEL =
    "Entraînement réservé à l'abonnement. Ouvrir l'offre pour le débloquer.";
export const PLAN_LOCKED_PRIORITY_LABEL =
    "Priorité réservée à l'abonnement. Ouvrir l'offre pour la débloquer.";

/* ------------------------------------------------------------------ séance */

export const PLAN_SEANCE_TITLE = "Aujourd'hui";
export const PLAN_SEANCE_WHY_CTA = "Pourquoi cette séance ?";
export const PLAN_SEANCE_WHY_TITLE = "Pourquoi cette séance ?";
export const PLAN_SEANCE_WHY_CLOSE = "J'ai compris";
/** La phrase de tête du « pourquoi » : ce que la séance EST, et ce qu'elle
 *  n'est pas. Aucune date n'intervient nulle part — une compétence entrée dans
 *  la séance y reste tant qu'elle n'est pas réussie. */
export const PLAN_SEANCE_META_HINT =
    "Votre séance reprend, dans l'ordre, les actions que votre plan a déjà désignées : rien n'est tiré au hasard, et rien ne disparaît d'un jour à l'autre.";
export const PLAN_SEANCE_EMPTY =
    "Rien à faire pour le moment : votre prochaine étape se décide à votre prochaine production.";
/** Les deux états du bouton principal — **miroirs mot pour mot du mobile**
 *  (`kPlanSeanceStart`, `kPlanSeanceRestart`). « Refaire » ne remet rien à
 *  zéro : il relance la première ligne de la séance. */
export const PLAN_SEANCE_START = "Commencer ma séance";
export const PLAN_SEANCE_RESTART = "Refaire ma séance";
/** Ce que dit un bouton pendant qu'un parcours s'ouvre. Déclaré une fois : il
 *  était recopié sur les quatre surfaces qui démarrent une action du Plan. */
export const PLAN_STARTING = "Démarrage…";

/** La ligne de tête de la séance : combien d'entraînements, combien de temps. */
export function planSeanceMeta(items: number, minutes: number): string {
    if (items === 0) return "Aucun entraînement pour l'instant";
    return `${items} entraînement${items > 1 ? "s" : ""} · environ ${minutes} min`;
}

/**
 * **Le titre d'une ligne de mesure.** Elle ne porte aucune compétence : ce
 * qu'on vient mesurer, c'est une **épreuve entière**, et son nom est donc celui
 * du domaine.
 *
 * ⚠️ **Miroir mot pour mot du mobile** (`planAssessmentTitle`,
 * `plan_labels.dart`) — ces chaînes ne transitent pas par le réseau, chaque
 * front en tient sa copie.
 */
export const PLAN_ASSESSMENT_ITEM_TITLE: Record<PlanDomainEpreuve, string> = {
    TCF_EE: "Compléter mon évaluation d'expression écrite",
    TCF_EO: "Compléter mon évaluation d'expression orale",
    TCF_CO: "Compléter mon évaluation de compréhension orale",
    TCF_CE: "Compléter mon évaluation de compréhension écrite",
};

export function planAssessmentItemTitle(assessment: PlanDomainAssessmentDto): string {
    return PLAN_ASSESSMENT_ITEM_TITLE[assessment.epreuve];
}

/* Les quatre « pourquoi » d'une ligne, déclarés une fois.

   🛑 Aucun ne nomme une faute : `A_EVALUER` dit qu'il manque une **mesure**,
   `A_ACQUERIR` qu'il reste quelque chose à **apprendre** — et surtout **pas**
   qu'il y aurait quelque chose à réparer.

   ⚠️ Les deux premiers sont des **miroirs mot pour mot du mobile**
   (`kPlanSeanceAssessmentLine`, `kPlanAcquisitionNote`). Le mobile les rend une
   fois par séance, dans sa feuille de justification ; le web les rend sur la
   ligne concernée, dans la modale « Pourquoi cette séance ? ». Mêmes phrases,
   deux surfaces qui n'ont pas la même forme. */
export const PLAN_REASON_A_EVALUER =
    "Une de vos productions n'a pas pu être analysée : votre séance commence par la mesurer, "
    + "sinon tout ce qui suit avance à l'aveugle.";
export const PLAN_REASON_A_ACQUERIR =
    "Nouvelle compétence de votre palier : vous ne l'avez encore jamais travaillée.";
export const PLAN_REASON_A_VERIFIER =
    "Assez travaillée en exercice ciblé : il reste à le prouver sur une vraie tâche, en situation.";
export const PLAN_REASON_MILESTONE =
    "Un cran au-dessus des étapes : venez prouver ce qui est déjà acquis.";

/** Ce qu'est l'entraînement d'une étape. **Au pluriel** : une étape n'est pas
 *  un sujet, c'est une série de cinq — le singulier faisait croire à une action
 *  unique là où le Plan en demande cinq. Miroir mot pour mot du mobile
 *  (`planExerciseKindLabel`). */
export const PLAN_MICRO_TRAINING_NATURE = "Sujets ciblés";

/**
 * **Ce qu'est une action du Plan**, en trois mots — déclarée ici parce que deux
 * surfaces la demandent : une ligne de séance et la carte « À faire
 * maintenant », qui ne porte aucun `PlanSeanceItemDto`.
 *
 * ⚠️ Miroir mot pour mot du mobile (`planExerciseKindLabel`).
 */
export function planExerciseKindLabel(
    kind: PlanExerciseKind,
    questionCount: number | null,
): string {
    switch (kind) {
        case "MICRO_TRAINING":
            return PLAN_MICRO_TRAINING_NATURE;
        case "REASSESSMENT":
            return "Vérification en situation";
        case "TARGETED_QCM_SERIES":
            return planSeriesLabel(questionCount);
        case "EPREUVE_MOCK_EXAM":
            return "Examen blanc d'épreuve";
        case "FULL_TCF_MOCK_EXAM":
            return "Examen blanc TCF complet";
    }
}

/* --------------------------------------------- la carte « À faire maintenant » */

/**
 * Le titre de la carte quand la série est terminée. 🛑 Il nomme **l'action**,
 * pas la compétence : c'est ce qui fait voir au premier coup d'œil que la carte
 * a changé de nature alors que le nom de la compétence, lui, n'a pas bougé.
 */
export const PLAN_NOW_VERIFY_TITLE = "Valider cette compétence";
export const PLAN_NOW_VERIFY_TEXT =
    "Mettez maintenant cette compétence en pratique dans une réponse complète.";

export const PLAN_NOW_CTA_START = "Commencer";
export const PLAN_NOW_CTA_CONTINUE = "Continuer";
export const PLAN_NOW_CTA_DISCOVER = "Découvrir";
export const PLAN_NOW_CTA_VERIFY = "Faire la vérification";
export const PLAN_NOW_CTA_MEASURE = "Compléter la mesure";

/**
 * Ce que dit le bouton quand l'étape annoncée est **verrouillée** : il ne lance
 * pas l'entraînement, il ouvre l'offre.
 *
 * ⚠️ Miroir mot pour mot du mobile (`kPlanNowLockedCta`), qui portait déjà ce
 * libellé — le web n'en avait aucun parce qu'il n'affichait aucun bouton.
 */
export const PLAN_NOW_CTA_LOCKED = "Débloquer cet entraînement";

/**
 * Ce que dit le bouton de la carte d'action.
 *
 * 🛑 **Rien n'est déduit d'un pourcentage** : la vérification se lit sur la
 * nature **servie**, et « Commencer » / « Continuer » ne départagent qu'un
 * compteur servi à zéro ou non — un nombre affiché, pas un état classé ici.
 *
 * ⚠️ Miroir mot pour mot du mobile (`planNowCta`).
 */
export function planNowCta(
    priority: LearningPlanPriorityDto | null,
    verifier: boolean,
    mesure: boolean,
): string {
    /* 🛑 **Une mesure se nomme sans aucune priorité.** Le parcours peut
       désigner un examen alors que le Plan n'a plus rien à prioriser — c'est
       même le cas quand tout a été travaillé —, et exiger une priorité ici
       faisait disparaître la carte. */
    if (mesure) return PLAN_NOW_CTA_MEASURE;
    if (verifier) return PLAN_NOW_CTA_VERIFY;
    if (!priority) return PLAN_NOW_CTA_START;
    if (priority.nature === "A_ACQUERIR") return PLAN_NOW_CTA_DISCOVER;
    return priority.stepAttemptedCount > 0 ? PLAN_NOW_CTA_CONTINUE : PLAN_NOW_CTA_START;
}

/**
 * Les deux lignes de la carte d'action, **distinctes**.
 *
 * 1. le **constat** — ce que le correcteur a observé, préfixé de **l'action**
 *    que le Plan demande (« À renforcer : le lien de cause à effet reste peu
 *    développé. »), et sans préfixe sur une vérification ;
 * 2. la **progression** — « Progression : 3/5 sujets réalisés ».
 *
 * 🛑 Elles étaient **concaténées** en une seule phrase, où l'état et le
 * compteur se lisaient comme la suite du constat. Deux faits différents, deux
 * lignes.
 *
 * 🛑 La nature passe avant les compteurs : sur une compétence à acquérir,
 * « 0/5 » se lirait comme un retard alors qu'il n'y avait rien à traiter.
 *
 * ⚠️ Miroir mot pour mot du mobile (`planNowLines`).
 */
export function planNowLines(priority: LearningPlanPriorityDto): string[] {
    const lines: string[] = [];
    if (priority.nature === "A_ACQUERIR") {
        lines.push(PLAN_REASON_A_ACQUERIR);
    } else if (priority.explanation) {
        /* 🛑 **Le préfixe nomme l'ACTION de l'étape, pas un état mesuré.** Il
           lisait `masteryState`, donc « Priorité : … » juste sous la pastille
           « Priorité n°1 » — la répétition même qu'on cherchait à supprimer, et
           un mot qui ne dit rien de ce qu'il y a à faire.

           🛑 **Rien n'est fabriqué ici** : `nature` est servie et son libellé
           est le miroir gelé de l'enum `PlanActionNature` (`SkillLabelsTest`),
           comme tous les libellés d'enum du dépôt.

           **Pas de préfixe sur une vérification** : la carte porte déjà
           « Valider cette compétence » et l'encart « Vérification en
           situation » ; « À vérifier : <une faiblesse> » serait une troisième
           redite, et surtout ferait dire au constat autre chose que ce qu'il
           dit — le constat décrit une fragilité observée, pas l'action. */
        lines.push(priority.nature === "A_VERIFIER"
            ? priority.explanation
            : `${PLAN_ACTION_NATURE_LABEL[priority.nature]} : ${priority.explanation}`);
    } else if (priority.readyForReassessment) {
        lines.push(PLAN_REASON_A_VERIFIER);
    }
    if (priority.nature !== "A_ACQUERIR" && priority.stepPromptCount > 0) {
        lines.push(
            `Progression : ${priority.stepAttemptedCount}/${priority.stepPromptCount} sujets réalisés`,
        );
    }
    return lines;
}

/**
 * **L'identité d'une étape** : son épreuve et son repère — « Compréhension
 * orale · Niveau B2 », « Expression écrite · Tâche 1 ».
 *
 * 🛑 C'est le **titre** de la carte « À faire maintenant » depuis le
 * 2026-09-18 : on dit d'abord où l'on travaille, l'intitulé de la compétence
 * vient dessous. Sans repère servi, l'épreuve seule — jamais un « · » orphelin.
 *
 * ⚠️ Miroir mot pour mot du mobile (`planNowIdentite`, `plan_labels.dart`).
 */
export function planNowIdentite(
    priority: LearningPlanPriorityDto,
    repere: string | null,
): string {
    const domaine = productionSectionLabel(priority.section);
    return repere ? `${domaine} · ${repere}` : domaine;
}

/** La pastille de la carte d'action, hors mesure. ⚠️ Le mobile écrit
 *  « Priorité 1 » (`planPriorityRankTag(1)`) : divergence de forme antérieure,
 *  laissée telle quelle — chaque front garde sa copie. */
export const PLAN_NOW_PRIORITY_BADGE = "Priorité n°1";
/** L'intitulé de l'encart d'une carte de vérification. */
export const PLAN_NOW_VERIFY_OBJECTIVE_LABEL = "Vérification en situation";

/**
 * **La mesure de domaine qui ouvre la séance**, s'il y en a une.
 *
 * 🛑 Un item `A_EVALUER` ne porte **aucun exercice** : c'est une mesure, et
 * c'est le seul cas où le bouton principal du Plan ne lance pas l'étape. Le
 * candidat a produit sur ce domaine et le correcteur n'a rien pu y observer —
 * tout ce qui suivrait travaillerait à l'aveugle.
 *
 * ⚠️ Miroir mot pour mot du mobile (`planSeanceMesure`, `plan_seance_state.dart`),
 * où le fait lu est `assessment` : ici l'union discriminée l'interdit par
 * construction.
 */
export function planSeanceMesure(plan: LearningPlanDto): PlanSeanceAssessmentItemDto | null {
    return plan.seance.items.find(
        (item): item is PlanSeanceAssessmentItemDto =>
            !planSeanceItemDone(item) && item.exercise === null,
    ) ?? null;
}

/** Ce que la carte « À faire maintenant » **annonce**. */
export type PlanNowNature =
    /** Une **mesure de domaine** : le correcteur n'a rien pu observer, et tout
     *  ce qui suivrait travaillerait à l'aveugle. */
    | "MESURE"
    /** L'étape est terminée : le Plan demande une **vérification en situation**. */
    | "VERIFICATION"
    /** Le cas courant : l'étape de la priorité n°1. */
    | "ETAPE"
    /**
     * 🛑 **Le parcours a désigné une étape dont l'action ne se résout pas.**
     * La carte nomme alors **cette étape-là**, sans bouton — et **jamais** une
     * autre compétence ni un autre examen.
     *
     * Elle existe parce que le repli silencieux sur `plan.currentPriority`
     * annonçait l'étape du parcours et lançait autre chose : le candidat lisait
     * « Tâche 2 » et atterrissait sur la compétence que le Plan priorisait ce
     * jour-là. Deux causes connues, toutes deux transitoires : une compétence
     * dont le transfert vient d'être prouvé (le Plan l'a sortie de ses
     * priorités, le parcours clôturera son étape au prochain entraînement), et
     * une compétence hors de la fenêtre d'affichage des priorités.
     */
    | "INDISPONIBLE";

/**
 * **Le geste de la carte** — la seule autorité sur « que se passe-t-il quand on
 * la touche ».
 *
 * 🛑 **Un écran ne redéduit jamais ce geste d'un `locked`.** Les six surfaces
 * qui portent cette carte (Plan, Accueil, Réviser, web et mobile) lisent ce
 * champ ; recalculer « verrouillé ⇒ offre » de chaque côté est exactement ce
 * qui avait laissé le Plan muet sur une étape verrouillée pendant que le mobile
 * y ouvrait déjà l'offre.
 *
 * - `LANCER` : la carte démarre ce qu'elle annonce (mesure ou exercice) ;
 * - `DEBLOQUER` : l'étape annoncée est **fermée** — le geste ouvre le paywall
 *   (spec §7 / D-18 : « le tap ouvre la popup *Débloquer mon plan* ») ;
 * - `AUCUN` : rien ne se résout, la carte **nomme** l'étape et s'arrête là.
 *
 * ⚠️ Miroir mot pour mot du mobile (`PlanNowGeste`, `plan_now_card.dart`).
 */
export type PlanNowGeste = "LANCER" | "DEBLOQUER" | "AUCUN";

/** L'identité **complète** de la carte : ce qu'elle montre, et ce qu'elle lance. */
export interface PlanNowVue {
    nature: PlanNowNature;
    /** 🛑 **Ce que le geste fait**, décidé ici et nulle part ailleurs. */
    geste: PlanNowGeste;
    /**
     * **La mesure que le bouton LANCE**, `null` sinon. Elle reste servie même
     * sur un plan gratuit, où la carte ne la nomme pas : c'est elle qui décide
     * du verrou comme du démarrage (`usePlanAssessment`).
     */
    mesure: PlanSeanceAssessmentItemDto | null;
    /** `null` sur la seule nature `INDISPONIBLE` : il n'y a **rien** à lancer,
     *  et nommer la priorité du Plan désignerait une autre compétence. */
    priority: LearningPlanPriorityDto | null;
    /** L'exercice de la priorité — celui que la carte lance **hors mesure**. */
    exercise: PlanSkillExerciseDto | null;
    /**
     * 🛑 **Le domaine réellement lancé**, c'est-à-dire l'icône de la carte. Elle
     * empruntait celle de la priorité : le candidat lisait une tâche
     * d'expression orale et atterrissait dans l'examen blanc de compréhension
     * orale de la mesure.
     *
     * `null` sur une étape de diagnostic, qui ne travaille aucun domaine.
     * ⚠️ Miroir du mobile (`PlanNowCard.section`), nullable depuis toujours.
     */
    section: SkillSection | null;
    /** Le repère de la priorité (« Tâche 2 », « Palier B1 »). `null` quand la
     *  carte ne porte aucune priorité. */
    repere: string | null;
    title: string;
    subtitle: string;
    /** `null` sur un plan gratuit : sa carte constate, elle ne classe pas. */
    badge: string | null;
    objectiveLabel: string | null;
    objective: string | null;
    /** « ≈ 4 min » ou « 5 petits sujets · ≈ 4 min chacun ». `null` quand aucune
     *  durée n'est servie — jamais un chiffre inventé. */
    minutesLabel: string | null;
    /** La nature de l'exercice lancé. `null` sur une mesure : le sous-titre
     *  porte déjà le parcours réel. */
    kindLabel: string | null;
    /** Le constat, ligne par ligne — jamais concaténé. */
    lines: string[];
    cta: string;
    /** Le verrou **lu**, jamais déduit d'un rang. */
    locked: boolean;
}

/**
 * **La carte d'une étape dont l'action ne se résout pas.**
 *
 * 🛑 Elle nomme **l'étape que le parcours a désignée**, et rien d'autre : c'est
 * tout son objet. Pas de bouton, pas de repli sur la priorité du Plan — lancer
 * une autre compétence que celle qu'on affiche est exactement la contradiction
 * que le parcours a été écrit pour fermer.
 *
 * Le titre et le sous-titre viennent des **libellés du parcours**
 * (`lib/journey.ts`), la même autorité que la timeline : la carte et la ligne
 * de la timeline disent donc mot pour mot la même chose.
 */
function carteIndisponible(etape: JourneyStepDto, free: boolean): PlanNowVue {
    /* 🛑 Un compte **sans accès** n'a rien à lancer de toute façon : le geste
       est l'offre, même quand l'action de l'étape ne se résout pas. Sinon, une
       étape ouverte mais sans exercice reste **sans geste** — on ne lui fait
       pas ouvrir un paywall qui ne la débloquerait pas. */
    const verrou = free || etape.locked;
    return {
        nature: "INDISPONIBLE",
        geste: verrou ? "DEBLOQUER" : "AUCUN",
        mesure: null,
        priority: null,
        exercise: null,
        section: etape.section
            ?? (etape.examType ? PLAN_DOMAIN_SECTION[etape.examType as PlanDomainEpreuve] : null),
        repere: null,
        title: journeyStepTitle(etape),
        subtitle: journeyStepSubtitle(etape) ?? "",
        badge: null,
        objectiveLabel: null,
        objective: null,
        minutesLabel: null,
        kindLabel: null,
        lines: [PLAN_NOW_UNAVAILABLE_TEXT],
        cta: verrou ? PLAN_NOW_CTA_LOCKED : PLAN_NOW_CTA_START,
        /* Le verrou **servi** de l'étape, pas une déduction : une étape
           indisponible peut être verrouillée par ailleurs, et l'écran doit
           continuer à le dire. */
        locked: etape.locked,
    };
}

/**
 * Ce que lit le candidat quand l'action de son étape ne se résout pas.
 *
 * 🛑 **Aucune promesse de délai** : les deux causes connues se referment à la
 * prochaine évaluation, et c'est tout ce qu'on peut affirmer.
 *
 * ⚠️ Miroir mot pour mot du mobile (`kPlanNowUnavailableText`).
 */
export const PLAN_NOW_UNAVAILABLE_TEXT =
    "Cette étape n'a pas d'exercice disponible pour l'instant. Votre prochaine évaluation la remettra à jour.";

/**
 * La priorité du Plan qui porte la compétence de cette étape — **son action**.
 *
 * 🛑 Le rapprochement se fait sur `skillCode`, pas sur `skillId` : c'est le
 * code qui est stable et lisible des deux côtés, et c'est lui que le parcours
 * sert.
 *
 * `null` est un cas **normal** : étape d'examen (elle n'a pas de compétence),
 * ou compétence que le Plan ne priorise plus.
 */
function journeyPriorityDe(
    plan: LearningPlanDto,
    etape: JourneyStepDto,
): LearningPlanPriorityDto | null {
    if (etape.type !== "TRAIN_SKILL" || !etape.skillCode) return null;
    const toutes = [plan.currentPriority, ...plan.nextPriorities].filter(
        (item): item is LearningPlanPriorityDto => item !== null,
    );
    return toutes.find((item) => item.skillCode === etape.skillCode) ?? null;
}

/**
 * La mesure que lance une étape d'examen — **la ligne de la séance** si elle y
 * est, sinon celle que **l'étape porte**.
 *
 * 🛑 Les deux viennent du **même** resolver serveur
 * (`PlanDomainAssessmentResolver`) : on ne compose aucune action, on retrouve
 * celle qui est déjà servie. La séance passe devant parce qu'elle porte en plus
 * les compteurs et le verrou de sa ligne.
 *
 * ⚠️ **Ce second chemin lisait `domainesAEvaluer`** jusqu'au 2026-09-17, et
 * c'était faux : cette liste ne contient que les épreuves **jamais mesurées**,
 * alors que le point d'étape d'un lot porte toujours sur une épreuve **déjà**
 * mesurée — c'est elle qui a créé le lot. Aucune action ne se résolvait donc
 * pour le cas le plus courant du parcours.
 *
 * `null` = étape d'entraînement, ou étape d'examen servie par un backend
 * antérieur au champ `assessment`.
 */
function journeyMesureDe(
    plan: LearningPlanDto,
    etape: JourneyStepDto,
): PlanSeanceAssessmentItemDto | null {
    if (etape.type !== "SECTION_EXAM" || !etape.examType) return null;
    const dansLaSeance = plan.seance.items.find(
        (item): item is PlanSeanceAssessmentItemDto =>
            item.exercise === null && item.assessment.epreuve === etape.examType,
    );
    if (dansLaSeance) return dansLaSeance;
    const assessment = etape.assessment;
    if (!assessment) return null;
    /* Une mesure n'a ni compétence, ni palier, ni état de maîtrise, ni étape :
       tous ces champs sont **structurellement** nuls sur une ligne de mesure,
       exactement comme le serveur les sert dans la séance. Rien n'est inventé
       ici — seule l'enveloppe est reconstituée. */
    return {
        nature: "A_EVALUER",
        exercise: null,
        assessment,
        skillId: null,
        skillCode: null,
        title: null,
        section: null,
        level: null,
        masteryState: null,
        stepPromptCount: 0,
        stepAttemptedCount: 0,
        stepValidatedCount: 0,
        stepCompleted: false,
        readyForReassessment: false,
        /* 🛑 Une mesure n'est **jamais** verrouillée : le slot offert est ouvert
           à tout compte inscrit, et `PlanDomainAssessmentResolver` ne sert
           aucun `locked` pour cette raison exacte. */
        locked: false,
        lastActivityAt: null,
    };
}

/**
 * **Ce qu'une ligne du cycle LANCE** — l'action de l'étape, résolue par les
 * mêmes autorités que la carte « À faire maintenant ».
 *
 * 🛑 **GARDE-FOU du 2026-09-17, appliqué ligne par ligne** : une ligne ne lance
 * **jamais** autre chose que l'étape qu'elle annonce. `null` quand rien ne se
 * résout — l'écran nomme alors l'étape **sans bouton**, exactement comme la
 * nature `INDISPONIBLE` de la carte.
 *
 * 🛑 **Aucune règle nouvelle ici** : `journeyPriorityDe` et `journeyMesureDe`
 * sont les deux résolutions que `planNowCard` emploie déjà. Cette fonction les
 * expose pour une étape **quelconque** du cycle, au lieu de la seule étape
 * courante — le Plan en affiche désormais toutes.
 *
 * ⚠️ Miroir mot pour mot du mobile (`planStepAction`, `plan_now_card.dart`).
 */
export interface PlanStepAction {
    /** La mesure à lancer (`usePlanAssessment`), `null` sur une compétence. */
    mesure: PlanSeanceAssessmentItemDto | null;
    /** L'exercice à lancer (`usePlanExercise`), `null` sur un examen. */
    exercise: PlanSkillExerciseDto | null;
    /** La priorité qui porte l'exercice — son état de maîtrise sert la mesure
     *  d'audience du lanceur. `null` sur une mesure. */
    priority: LearningPlanPriorityDto | null;
}

export function planStepAction(
    plan: LearningPlanDto,
    etape: JourneyStepDto,
): PlanStepAction | null {
    const mesure = journeyMesureDe(plan, etape);
    if (mesure) return {mesure, exercise: null, priority: null};
    const priority = journeyPriorityDe(plan, etape);
    const exercise = priority?.recommendedExercise ?? null;
    if (!priority || !exercise) return null;
    return {mesure: null, exercise, priority};
}

/**
 * **La carte « À faire maintenant » d'un plan TCF**, ou `null` quand le serveur
 * n'a désigné aucune priorité (l'écran affiche alors son état vide).
 *
 * 🛑 **Une seule autorité pour les SIX sites d'appel** — le Plan, l'Accueil et
 * **Réviser**, web et mobile. La règle « une MESURE passe devant tout le
 * reste » vivait dans `ActionMaintenant` et `_nowCard` ; les deux cartes
 * d'Accueil (`ActionPrincipale`, `_actionTcf`) ne l'avaient **jamais** reçue et
 * lisaient `currentPriority` seule. Sur les mêmes données, l'Accueil annonçait
 * « Raconter brièvement une expérience passée · VOTRE PRIORITÉ DU JOUR »
 * pendant que le Plan annonçait « Compléter mon évaluation de compréhension
 * écrite · À ÉVALUER » : deux « à faire maintenant » contradictoires pour le
 * même candidat, au même instant.
 *
 * ⚠️ **La carte « Reprendre là où vous vous êtes arrêté » de Réviser en dérive
 * aussi** (`reviserResumeTcf`, `lib/reviser.ts`) : elle lisait
 * `seance.items[0]` puis retombait sur `currentPriority`, donc une mesure qui
 * n'ouvrait pas la séance lui échappait — troisième écran, même contradiction.
 *
 * 🛑 **Rien n'est décidé ici** : la précédence de la mesure, la nature de
 * l'action, les minutes et le verrou sont tous **servis**. Cette fonction ne
 * fait que choisir *laquelle* des deux identités la carte porte.
 *
 * ⚠️ `free` n'a **pas** de pendant Dart : le plan gratuit y est une carte à
 * part (`_freeStepCard`), là où le web rend les deux avec le même `NowCard`.
 * Sur un plan gratuit la carte **constate** — elle ne nomme pas la mesure et ne
 * porte ni pastille, ni méta, ni constat. Son seul geste est l'offre
 * (`geste === "DEBLOQUER"`, spec §7 / D-18) : elle ne lance aucun
 * entraînement.
 */
export function planNowCard(
    plan: LearningPlanDto,
    {free = false, journey = null}: {free?: boolean; journey?: JourneyDto | null} = {},
): PlanNowVue | null {
    /* 🛑 **LE PARCOURS DÉCIDE QUELLE ÉTAPE, LE PLAN FOURNIT COMMENT LA LANCER**
       (décision A18, `docs/decisions-autonomes-parcours-tcf.md`).

       `JourneyStepDto` porte l'identité d'une étape — et **aucune action à
       lancer**. Le catalogue d'actions vit chez ses autorités : le petit sujet
       précis chez `RecommendedExerciseSelector`, « par quoi mesurer une
       épreuve » chez `PlanDomainAssessmentResolver` (arbitré le 2026-09-16).
       Les recopier dans le parcours en ferait un second moteur, ce que la
       spec §0.4 interdit.

       Donc : le parcours **désigne**, le Plan **exécute**. C'est ce qui rend la
       carte identique sur les six sites d'appel sans dupliquer une règle. */
    const etape = journey?.current ?? null;
    const duParcours = etape ? journeyPriorityDe(plan, etape) : null;
    /* 🛑 **Le parcours a déjà appliqué la précédence** (R12 : une épreuve non
       mesurée passe après les lots, et son étape est à sa position). On ne
       rejoue donc PAS `planSeanceMesure`, qui ferait passer une mesure devant
       l'étape que le parcours vient de désigner — deux règles de précédence
       pour une seule carte. */
    const mesure = etape ? journeyMesureDe(plan, etape) : planSeanceMesure(plan);

    /* 🛑 **GARDE-FOU : on ne lance JAMAIS autre chose que l'étape annoncée.**
       Quand le parcours désigne une étape dont l'action ne se résout pas, cette
       fonction retombait sur `plan.currentPriority` : la carte annonçait
       l'étape du parcours et ouvrait la compétence que le Plan priorisait ce
       jour-là. Deux causes, toutes deux transitoires — une compétence que le
       Plan ne priorise plus (son transfert vient d'être prouvé) et une
       compétence hors de la fenêtre d'affichage des priorités. Dans les deux
       cas, la carte nomme **cette étape-là**, sans bouton. */
    if (etape && !duParcours && !mesure) return carteIndisponible(etape, free);

    const priority = duParcours ?? plan.currentPriority;
    if (!priority && !mesure) return null;

    const exercise = priority?.recommendedExercise ?? null;
    /* 🛑 Le verrou se lit sur ce que la carte LANCE — la mesure réelle, même
       quand un plan gratuit ne la nomme pas. */
    const locked = mesure
        ? planSeanceItemLocked(mesure)
        : (priority!.locked || exercise?.locked === true);

    /* 🛑 **Le geste, décidé une seule fois pour les six surfaces** (spec §7,
       D-18) : une étape fermée ne se lance pas, elle **ouvre l'offre**. Un
       compte sans accès y passe toujours — son Plan est un constat, et c'est
       `JourneyState.LOCKED` permanent qui est l'effet voulu. */
    const geste: PlanNowGeste = free || locked
        ? "DEBLOQUER"
        : mesure || exercise
            ? "LANCER"
            : "AUCUN";

    /* ⚠️ **`planSkillTargetLevel`, comme le mobile** (correctif de parité du
       2026-09-18) : cette carte lisait `planSkillLevel`, les paliers de
       compréhension seuls, pendant que le mobile lisait le palier porté par la
       compétence. Deux lectures pour la même ligne, désormais promue au TITRE
       de la carte. Et le mot est « **Niveau** », celui du reste du produit —
       « Palier » est le vocabulaire des règles, pas celui du candidat. */
    const level = priority ? planSkillTargetLevel(plan, priority.skillId) : null;
    const tache = priority ? skillTaskNumber(priority.skillCode) : null;
    const repere = !priority
        ? null
        : isComprehension(priority.section)
            ? level ? `Niveau ${level}` : productionSectionLabel(priority.section)
            : planTaskBadge(tache ?? 1);

    /* 🛑 **La carte de vérification est une AUTRE carte.** Le nom de la
       compétence ne change pas quand la série se termine : si seuls le bouton
       et son libellé changeaient, le candidat lirait « rien n'a bougé » alors
       que l'action a changé de nature. Elle se lit sur la nature **servie**,
       jamais sur un compteur. */
    const mesureCard = free ? null : mesure;
    const verifier = mesureCard === null
        && priority?.nature === "A_VERIFIER"
        && exercise?.kind === "REASSESSMENT";

    const minutes = mesureCard ? planItemMinutes(mesureCard) : exercise?.estimatedMinutes ?? null;
    /* « chacun » : les minutes sont celles d'UN sujet, pas de la série entière —
       sans lui, « 5 sujets · ≈ 6 min » promettait six minutes pour les cinq.
       ⚠️ La nature est testée avec les compteurs (miroir du mobile) : une série
       ciblée de compréhension porte elle aussi un `stepPromptCount`, et sans ce
       test elle annonçait « 5 petits sujets » qu'elle ne contient pas. */
    const minutesLabel = free || minutes === null
        ? null
        : mesureCard === null
            && !verifier
            && (priority?.stepPromptCount ?? 0) > 0
            && exercise?.kind === "MICRO_TRAINING"
            ? `${priority?.stepPromptCount} petits sujets · ≈ ${minutes} min chacun`
            : `≈ ${minutes} min`;

    if (mesureCard) {
        return {
            nature: "MESURE",
            geste,
            mesure,
            priority,
            exercise,
            section: PLAN_DOMAIN_SECTION[mesureCard.assessment.epreuve],
            repere,
            title: planAssessmentItemTitle(mesureCard.assessment),
            subtitle: planAssessmentNature(mesureCard.assessment),
            /* 🛑 Une mesure n'est pas la priorité n°1 : sa pastille dit sa
               **nature** servie, celle que le serveur a posée sur l'item. */
            badge: PLAN_ACTION_NATURE_LABEL.A_EVALUER,
            objectiveLabel: null,
            objective: null,
            minutesLabel,
            kindLabel: null,
            /* Sur une mesure, le constat de la priorité parlerait d'une AUTRE
               compétence que celle que le bouton ouvre. */
            lines: [PLAN_REASON_A_EVALUER],
            cta: geste === "DEBLOQUER" ? PLAN_NOW_CTA_LOCKED : planNowCta(priority, false, true),
            locked,
        };
    }

    /* Plus de mesure et plus de priorité : il n'y a rien à annoncer, et l'écran
       affiche son état vide. */
    if (!priority) return null;

    return {
        nature: verifier ? "VERIFICATION" : "ETAPE",
        geste,
        mesure,
        priority,
        exercise,
        section: priority.section,
        repere,
        /* 🛑 **L'ÉPREUVE en titre, la compétence en sous-titre** (demande du
           propriétaire, 2026-09-18). Les deux étaient inversés : le candidat
           lisait d'abord « Comprendre l'implicite et les nuances à l'oral » —
           un intitulé de référentiel, long, sur deux lignes — et devait
           descendre pour savoir de quelle épreuve il s'agissait. Il sait
           maintenant **où** il travaille avant de lire **quoi**.

           🛑 **Le nom de la compétence ne se répète pas trois fois** : il vit
           en sous-titre, et sur la vérification il passe sous le titre — qui
           nomme alors l'ACTION, et c'est le seul cas où l'ordre s'inverse. */
        title: verifier ? PLAN_NOW_VERIFY_TITLE : planNowIdentite(priority, repere),
        subtitle: verifier
            ? `${priority.title}${tache === null ? "" : ` · Tâche ${tache} complète`}`
            : priority.title,
        badge: free ? null : PLAN_NOW_PRIORITY_BADGE,
        objectiveLabel: verifier && !free ? PLAN_NOW_VERIFY_OBJECTIVE_LABEL : null,
        objective: verifier && !free ? PLAN_NOW_VERIFY_TEXT : null,
        minutesLabel,
        kindLabel: free || !exercise
            ? null
            : planExerciseKindLabel(
                exercise.kind,
                exercise.kind === "TARGETED_QCM_SERIES" ? exercise.questionCount : null,
            ),
        lines: free ? [] : planNowLines(priority),
        cta: geste === "DEBLOQUER" ? PLAN_NOW_CTA_LOCKED : planNowCta(priority, verifier, false),
        locked,
    };
}

/** Ce que fait un item, en trois mots — la **nature de l'action**, lue sur
 *  `exercise.kind` et jamais devinée d'un identifiant nul. Sur une **mesure**,
 *  c'est le parcours réel qu'on nomme (diagnostic, production, examen blanc). */
export function planItemNature(item: PlanSeanceItemDto): string {
    if (item.exercise === null) return planAssessmentNature(item.assessment);
    return planExerciseKindLabel(
        item.exercise.kind,
        item.exercise.kind === "TARGETED_QCM_SERIES" ? item.exercise.questionCount : null,
    );
}

/** La ligne meta d'un item : sa nature et sa durée. **Une mesure sans durée**
 *  (le diagnostic, une production — rien n'y est chronométré par épreuve)
 *  n'affiche aucune minute plutôt qu'un chiffre inventé. */
export function planItemMeta(item: PlanSeanceItemDto): string {
    const minutes = planItemMinutes(item);
    return minutes === null ? planItemNature(item) : `${planItemNature(item)} · ${minutes} min`;
}

/** Les minutes d'un item, ou `null` quand la durée n'est pas une donnée
 *  d'examen. Servies par le serveur, jamais recalculées. */
export function planItemMinutes(item: PlanSeanceItemDto): number | null {
    if (item.exercise !== null) return item.exercise.estimatedMinutes;
    return item.assessment.estimatedMinutes;
}

/** Le titre d'une ligne de séance. Ni un jalon ni une mesure n'ont de titre
 *  côté serveur (le bloc compétence y est nul) : le jalon se nomme par sa
 *  nature, la mesure par son domaine. */
export function planItemTitle(item: PlanSeanceItemDto): string {
    if (item.exercise === null) return planAssessmentItemTitle(item.assessment);
    return item.title ?? planItemNature(item);
}

/** À quelle épreuve rattacher un item — pour son icône et sa couleur. Une
 *  mesure et un jalon portent leur `epreuve`, un exercice de compétence sa
 *  `section`. */
export function itemEpreuve(item: PlanSeanceItemDto): PlanDomainEpreuve {
    if (item.exercise === null) return item.assessment.epreuve;
    if (item.exercise.kind === "EPREUVE_MOCK_EXAM") {
        return item.exercise.epreuve === "TCF_EO" ? "TCF_EO" : "TCF_EE";
    }
    if (item.exercise.kind === "FULL_TCF_MOCK_EXAM") return "TCF_CO";
    const section = item.section ?? item.exercise.section;
    switch (section) {
        case "CO": return "TCF_CO";
        case "CE": return "TCF_CE";
        case "EO": return "TCF_EO";
        default: return "TCF_EE";
    }
}

/**
 * La ligne « pourquoi » d'un item : **des faits servis**, jamais un jugement.
 *
 * 🛑 **L'ordre des branches est celui des trois natures**, pas celui des
 * champs : une compétence **à acquérir** se dit « rien n'a été constaté ici »,
 * jamais un compteur d'étape à zéro qui se lirait comme un retard. C'est la
 * distinction que cet écran doit rendre lisible.
 */
/**
 * **Pourquoi cette séance ?**, composé des **faits servis** : ce que la séance
 * est, ce qui la fait commencer par une mesure, pourquoi une compétence jamais
 * travaillée y figure, et ce qui la fera bouger.
 *
 * ⚠️ **Miroir mot pour mot du mobile** (`planSeanceRationale`,
 * `plan_labels.dart`). Le web n'affichait que la phrase de tête et l'état du
 * cycle : les quatre raisons qui suivent — dont celle qui distingue « acquérir »
 * de « renforcer » — n'existaient que sur téléphone.
 *
 * 🛑 **La priorité n°1 n'est nommée que si elle est accessible** : l'écrire en
 * clair sous un rideau posé deux blocs plus haut le démentirait.
 */
export function planSeanceRationale(plan: LearningPlanDto): string[] {
    const items = plan.seance.items;
    if (items.length === 0) return [PLAN_SEANCE_EMPTY];

    const lines: string[] = [PLAN_SEANCE_META_HINT];

    const priority = plan.currentPriority;
    if (priority && !priority.locked) {
        lines.push(
            `Votre priorité n°1 est « ${priority.title} » : c'est elle qui ouvre votre séance, `
            + "parce que c'est elle qui vous fera progresser le plus vite.",
        );
    }

    if (items.some((item) => item.nature === "A_EVALUER")) lines.push(PLAN_REASON_A_EVALUER);
    if (items.some((item) => item.nature === "A_ACQUERIR")) lines.push(PLAN_SEANCE_ACQUISITION_LINE);
    if (items.some((item) => item.section !== null && isComprehension(item.section))) {
        lines.push(
            "Vos séries de compréhension ne mesurent pas un domaine : elles entraînent la "
            + "compétence exacte qui bloque votre palier. C'est un examen blanc qui mesure un "
            + "domaine.",
        );
    }
    if (items.some((item) => item.readyForReassessment)) {
        lines.push(
            "Une de vos étapes est terminée : le Plan vous demande maintenant de le prouver sur "
            + "une vraie tâche, pas sur un exercice ciblé.",
        );
    }

    lines.push(
        "Cette séance est recalculée à chaque nouveau résultat. Rien n'y est périmé par le temps "
        + "qui passe : c'est ce que vous faites qui la fait avancer.",
    );
    return lines;
}

/** Pourquoi une compétence **jamais travaillée** figure dans la séance — la
 *  forme « une fois par séance », distincte de `PLAN_REASON_A_ACQUERIR` qui
 *  qualifie **une** ligne. Miroir de `kPlanSeanceAcquisitionLine`. */
export const PLAN_SEANCE_ACQUISITION_LINE =
    "Certaines lignes portent des compétences que vous n'avez encore jamais travaillées : "
    + "il n'y a rien à y réparer, elles font partie du palier que votre plan construit.";

export function planItemReason(item: PlanSeanceItemDto): string {
    if (item.nature === "A_EVALUER") return PLAN_REASON_A_EVALUER;
    if (item.nature === "A_ACQUERIR") return PLAN_REASON_A_ACQUERIR;
    if (item.exercise.kind === "EPREUVE_MOCK_EXAM" || item.exercise.kind === "FULL_TCF_MOCK_EXAM") {
        return PLAN_REASON_MILESTONE;
    }
    if (item.readyForReassessment) return PLAN_REASON_A_VERIFIER;
    const état = item.masteryState ? SKILL_MASTERY_STATE_LABEL[item.masteryState] : null;
    if (item.stepPromptCount > 0) {
        const compteur = `${item.stepAttemptedCount} sujet${item.stepAttemptedCount > 1 ? "s" : ""} sur ${item.stepPromptCount} traité${item.stepAttemptedCount > 1 ? "s" : ""}`;
        return état ? `${état} · ${compteur}` : compteur;
    }
    const palier = item.level ? `Palier ${item.level}` : planDomainLabel(itemEpreuve(item));
    return état ? `${palier} · ${état}` : palier;
}

/* --------------------------------------------------------- ce qui a changé */

export const PLAN_RECENT_NEW_PRIORITY = "Nouvelle priorité";

/** Le bandeau de tête, quand quelque chose a bougé — **miroir mot pour mot du
 *  mobile** (`kPlanBannerLabel`, `planBannerText`). Il dit qu'il s'est passé
 *  quelque chose ; la section « ce qui a changé » dit quoi. */
export const PLAN_BANNER_LABEL = "Plan actualisé";

export function planBannerText(changes: PlanRecentChangesDto): string {
    const moves = changes.transitions.length;
    if (moves === 0) return "une nouvelle priorité a été désignée";
    return `${moves} compétence${moves > 1 ? "s" : ""} ${moves > 1 ? "ont" : "a"} changé d'état`;
}

/** Une transition, dite au candidat. **Le sens de la marche vient du serveur**
 *  (`progress`) : aucun front ne code l'ordre des quatre états. */
export function planTransitionLine(transition: PlanMasteryTransitionDto): string {
    const avant = SKILL_MASTERY_STATE_LABEL[transition.before];
    const après = SKILL_MASTERY_STATE_LABEL[transition.after];
    return `${avant} → ${après}`;
}

/* ------------------------------------------------------------- navigation */

/**
 * Où mène une **compétence** du Plan.
 *
 * 🛑 `competenceHref` ne vaut que pour l'**expression** : elle dérive le numéro
 * de tâche du code (`EE1-C3`), et une compétence de compréhension (`CO-B1`) n'en
 * a aucun — l'URL fabriquée pointerait sur une page de tâche qui n'existe pas.
 * La compréhension ouvre donc la **fiche de son domaine**, seul écran qui la
 * décrive.
 */
export function planSkillHref(
    skill: {skillId: string; skillCode: string; section: SkillSection},
    options: {planStep?: boolean} = {},
): string {
    if (isComprehension(skill.section)) {
        return planDomainHref(skill.section === "CO" ? "TCF_CO" : "TCF_CE");
    }
    return competenceHref(skill, options);
}

/**
 * **« Toutes mes compétences »** — l'index du référentiel, ouvert depuis
 * « Mes priorités ».
 *
 * Il ne crée aucun écran concurrent : chaque ligne y renvoie vers un parcours
 * **déjà livré** — les huit compétences d'une tâche (« Réviser → épreuve →
 * Compétences ») en expression, la fiche du domaine en compréhension.
 */
export const PLAN_SKILLS_HREF = "/plan/competences";
/**
 * Le titre de la page — et, ici seulement, **aussi le libellé de l'action** qui
 * l'ouvre depuis « Mes priorités » (`AllSkillsLink`).
 *
 * ⚠️ **Divergence VOULUE avec le mobile, arbitrée le 2026-08-21 : ne pas
 * « aligner ».** L'action s'appelle « Toutes mes compétences » ici et
 * « Tout voir » sur mobile (`kPlanPrioritiesAll`, `screens/plan/plan_labels.dart`,
 * qui porte la même note). Ce n'est pas une copie qui a dérivé : les deux
 * maquettes diffèrent réellement, et la place à l'écran non plus — la colonne du
 * web tient la forme longue, un lien de fin de section sur une largeur de
 * téléphone la tronquerait ou pousserait le compteur hors du bandeau.
 *
 * Ce qui **doit** rester identique des deux côtés, et l'est : le **titre de la
 * page d'arrivée**. Le contrat, c'est la destination ; le reste n'est qu'un
 * libellé d'action.
 */
export const PLAN_SKILLS_TITLE = "Toutes mes compétences";
export const PLAN_SKILLS_TEXT =
    "Expression : 6 tâches, 8 compétences chacune, observées à partir de vos productions. "
    + "Compréhension : trois paliers par domaine, mesurés sur vos séries de questions.";
/** Le repère d'une compétence : son code et son domaine, plus le numéro de
 *  tâche quand elle en a un. */
export function planSkillMeta(skill: {skillCode: string; section: SkillSection}): string {
    const domaine = productionSectionLabel(skill.section);
    const task = skillTaskNumber(skill.skillCode);
    return task ? `${skill.skillCode} · ${domaine} — Tâche ${task}` : `${skill.skillCode} · ${domaine}`;
}

/* ------------------------------------------------------------- recherches */

/** Le palier travaillé par une compétence de compréhension, retrouvé dans les
 *  domaines **servis** — jamais dérivé de son code. `null` en expression, ou
 *  quand la compétence n'est pas dans les paliers publiés. */
export function planSkillLevel(plan: LearningPlanDto, skillId: string): TargetLevel | null {
    for (const domain of plan.domaines) {
        for (const palier of domain.paliers) {
            if (palier.skillId === skillId) return palier.niveau;
        }
    }
    return null;
}

/** Le domaine d'une épreuve dans le Plan servi. `undefined` est impossible en
 *  pratique (les quatre sont toujours là) mais reste traité par l'appelant. */
export function findDomain(
    plan: LearningPlanDto,
    epreuve: PlanDomainEpreuve,
): PlanDomainDto | undefined {
    return plan.domaines.find((domain) => domain.epreuve === epreuve);
}

/** Par quoi mesurer ce domaine, s'il reste à mesurer. */
export function findAssessment(
    plan: LearningPlanDto,
    epreuve: PlanDomainEpreuve,
): PlanDomainAssessmentDto | undefined {
    return plan.domainesAEvaluer.find((item) => item.epreuve === epreuve);
}

/** Toutes les priorités actives, courante en tête — la liste que « Mes
 *  priorités » numérote. Le serveur en sert au plus trois et **dans l'ordre** :
 *  on ne trie pas. */
export function planActivePriorities(plan: LearningPlanDto) {
    return [
        ...(plan.currentPriority ? [plan.currentPriority] : []),
        ...plan.nextPriorities,
    ];
}

/**
 * Un état de maîtrise **servi** mis en clair, ou `null` quand rien n'a été
 * observé — on n'invente pas un état pour une compétence que le serveur n'a
 * jamais vue.
 *
 * Renommée depuis `masteryLabel` le 2026-08-23 : ce nom désignait aussi, dans
 * la maquette et sur le mobile, une fonction qui **classait un pourcentage**.
 * Les deux ont été supprimées (moteur de progression V4.2, §25 bis.4) ; celle-ci
 * ne calcule rien — elle traduit un enum reçu — et son nouveau nom le dit.
 */
export function masteryStateLabel(state: SkillMasteryState | null): string | null {
    return state ? SKILL_MASTERY_STATE_LABEL[state] : null;
}

/** Niveau lisible, `null` compris. Centralisé pour que « inconnu » se dise
 *  partout pareil. */
export function levelLabel(level: NiveauCecrl | null): string | null {
    return level ? niveauCecrlLabel(level) : null;
}

/* ------------------------------------------------------- coches de séance */

/**
 * **La clé de liste d'un item de séance, stable à travers un recalcul du Plan.**
 *
 * On prend la **compétence**, pas le sujet : quand le candidat termine un petit
 * sujet, le serveur désigne le suivant dans la même compétence — la clé du
 * sujet changerait et React remonterait la ligne pour rien. Un jalon n'a pas de
 * compétence : il s'identifie par son épreuve et son slot. Une **mesure** non
 * plus : elle s'identifie par le domaine qu'elle vient observer.
 */
export function planSeanceItemKey(item: PlanSeanceItemDto): string {
    if (item.exercise === null) {
        return `assess:${item.assessment.epreuve}:${item.assessment.kind}`;
    }
    const skillId = item.skillId ?? ("skillId" in item.exercise ? item.exercise.skillId : null);
    if (skillId) return `skill:${skillId}`;
    if (item.exercise.kind === "EPREUVE_MOCK_EXAM" || item.exercise.kind === "FULL_TCF_MOCK_EXAM") {
        return `exam:${item.exercise.epreuve}:${item.exercise.slotNumber}`;
    }
    return `kind:${item.exercise.kind}`;
}

/**
 * **Le jour civil d'une date, à Paris.** `"2026-08-21"`.
 *
 * L'`Intl` du navigateur porte la base de fuseaux : aucune règle d'heure d'été
 * n'est écrite ici, et un candidat qui consulte son Plan depuis un autre fuseau
 * lit la même journée que le serveur — qui compte, lui aussi, en Europe/Paris
 * (`FenetreMesure.PARIS`).
 */
function parisDay(date: Date): string {
    return date.toLocaleDateString("en-CA", {timeZone: "Europe/Paris"});
}

/**
 * **Cette ligne de la séance est-elle faite ?**
 *
 * Deux faits **servis**, aucun marqueur local : l'étape est bouclée
 * (`stepCompleted` sur ses cinq sujets), **ou** la dernière activité sur la
 * compétence tombe aujourd'hui (**Europe/Paris**).
 *
 * 🛑 C'est le front qui compare, jamais le serveur : la séance ne dépend
 * d'aucune date, et un booléen figé à la lecture serait faux le lendemain. Mais
 * la **donnée**, elle, vient du compte — la coche survit donc à un
 * rechargement et se retrouve à l'identique sur mobile
 * (`planSeanceItemDone`, même règle, même ordre).
 */
/**
 * **Le verrou d'une ligne de séance, LU** — jamais déduit de son rang.
 *
 * Le serveur le publie à deux endroits : sur l'item et sur l'exercice qu'il
 * porte. La ligne est fermée dès que l'un des deux le dit — **miroir du mobile**
 * (`planSeanceItemLocked`, `plan_seance_state.dart`), qui lisait déjà les deux
 * quand le web ne lisait que le premier.
 *
 * 🛑 Ne pas réintroduire un « à partir de la 2ᵉ, cadenas » : la maquette le
 * dessine ainsi parce que son bouchon n'a pas de serveur.
 */
export function planSeanceItemLocked(item: PlanSeanceItemDto): boolean {
    return item.locked || (item.exercise?.locked ?? false);
}

export function planSeanceItemDone(item: PlanSeanceItemDto, now: Date = new Date()): boolean {
    if (item.stepPromptCount > 0 && item.stepCompleted) return true;
    if (!item.lastActivityAt) return false;
    const activity = new Date(item.lastActivityAt);
    if (Number.isNaN(activity.getTime())) return false;
    return parisDay(activity) === parisDay(now);
}

/* ------------------------------------------------ épreuve → tâche → lignes
 *
 * L'écran Plan ne présente plus « Aujourd'hui » ni « Mes priorités » comme deux
 * listes plates : les lignes sont **groupées par épreuve puis par tâche**, dans
 * des encarts rétractables. Fermé, un encart dit **où** le candidat travaille ;
 * ouvert, il déroule **ce qu'il y a à y faire**.
 *
 * 🛑 **Aucune règle métier n'est ajoutée ici** : l'ordre des lignes reste celui
 * du serveur, le regroupement ne fait que rassembler des lignes **consécutives
 * ou non** sous la tâche qu'elles portent déjà, et il ne réordonne jamais les
 * groupes — le premier groupe est celui de la première ligne servie.
 */

/**
 * **Le titre éditorial des 6 tâches d'expression.**
 *
 * ⚠️ **Miroir manuel de l'enum serveur `SkillTaskCode`** : le référentiel des
 * 6 tâches est **officiel et figé**, il vit dans le code Java (jamais en base)
 * — et le serveur n'expose **pas** ce titre dans les DTO du Plan. Chaque front
 * en tient donc sa copie, comme pour les libellés d'états ; un titre qui bouge,
 * ce sont autant de fichiers à changer dans la même passe.
 *
 * 🛑 **Identiques au mot près à ceux du mobile.** Ne jamais recopier une de ces
 * chaînes dans un composant.
 */
export const SKILL_TASK_TITLE: Record<SkillTaskCode, string> = {
    EE1: "Écrire un message court",
    EE2: "Raconter une expérience",
    EE3: "Donner son opinion",
    EO1: "Entretien dirigé : parler de soi",
    EO2: "Jeu de rôle : demander et obtenir des informations",
    EO3: "Exprimer et développer un point de vue",
};

/** La tâche que porte un code de compétence (`EE2-C3` → `EE2`). `null` sur une
 *  compétence de compréhension (`CO-B1`), qui n'appartient à aucune tâche, et
 *  sur un jalon ou une mesure, qui n'ont pas de compétence. */
export function skillTaskCode(skillCode: string | null | undefined): SkillTaskCode | null {
    if (!skillCode) return null;
    const match = skillCode.match(/^(EE|EO)([1-3])/);
    return match ? (`${match[1]}${match[2]}` as SkillTaskCode) : null;
}

/** Le titre éditorial de la tâche d'un code de compétence, `null` en
 *  compréhension. */
export function skillTaskTitle(skillCode: string | null | undefined): string | null {
    const code = skillTaskCode(skillCode);
    return code ? SKILL_TASK_TITLE[code] : null;
}

/** La pastille d'une tâche, telle qu'elle s'affiche fermée. */
export function planTaskBadge(tacheNumero: number): string {
    return `Tâche ${tacheNumero}`;
}

/** « Tâche 2 — Raconter une expérience » : le repère complet d'une compétence
 *  d'expression. `null` en compréhension, qui se repère par son palier. */
export function planTaskLabel(skillCode: string | null | undefined): string | null {
    const code = skillTaskCode(skillCode);
    if (!code) return null;
    return `${planTaskBadge(Number(code.charAt(2)))} — ${SKILL_TASK_TITLE[code]}`;
}

/** Le repère d'un encart **sans tâche** : la compréhension travaille un niveau,
 *  une mesure ouvre un parcours (`planAssessmentNature`), un jalon est un jalon.
 *  `null` quand aucun de ces trois faits n'est servi — **on n'invente alors
 *  aucun repère**, et la pastille ne s'affiche pas. */
export function planGroupLevelContext(level: string): string {
    return `Niveau ${level}`;
}

/** L'en-tête d'un encart : de quelle épreuve il relève, et sur quoi il porte. */
export interface PlanGroupHead {
    key: string;
    epreuve: PlanDomainEpreuve;
    /** Nom complet de l'épreuve — « Expression écrite ». */
    label: string;
    /** 1, 2 ou 3 en expression ; `null` en compréhension, sur une mesure et sur
     *  un jalon. C'est lui qui décide de la teinte de la pastille. */
    taskNumber: number | null;
    /** Titre éditorial de la tâche, `null` quand il n'y a pas de tâche. */
    taskTitle: string | null;
    /** Ce que porte la pastille quand il n'y a pas de tâche. `null` quand rien
     *  ne le dit : la pastille ne s'affiche alors pas. */
    context: string | null;
}

function planGroupHead(item: {
    key: string;
    epreuve: PlanDomainEpreuve;
    skillCode: string | null;
    context: string | null;
}): PlanGroupHead {
    const code = skillTaskCode(item.skillCode);
    return {
        key: item.key,
        epreuve: item.epreuve,
        label: planDomainLabel(item.epreuve),
        taskNumber: code ? Number(code.charAt(2)) : null,
        taskTitle: code ? SKILL_TASK_TITLE[code] : null,
        context: item.context,
    };
}

/* -------------------------------------------------------- séance groupée */

export interface PlanSeanceGroupRow {
    key: string;
    item: PlanSeanceItemDto;
    /** Lu sur des **faits servis** (`planSeanceItemDone`), jamais un marqueur local. */
    done: boolean;
    /** Lu sur le `locked` du serveur (`planSeanceItemLocked`), **jamais** déduit
     *  du rang de la ligne. */
    locked: boolean;
}

export interface PlanSeanceGroup extends PlanGroupHead {
    rows: PlanSeanceGroupRow[];
    /** Somme des durées **servies** des lignes du groupe. */
    minutes: number;
    /** Toutes les lignes sont faites : l'encart s'estompe et se coche. */
    done: boolean;
    /** Toutes les lignes sont fermées par le serveur : l'encart porte un cadenas
     *  **à la place du chevron** et ne se déplie pas. */
    locked: boolean;
}

/**
 * La séance, groupée par épreuve puis par tâche.
 *
 * L'expression se groupe par **tâche** (les 8 compétences d'une tâche s'y
 * retrouvent ensemble), la compréhension par **(domaine, palier)** — elle n'a
 * aucune tâche. Une **mesure** et un **jalon** font chacun leur propre groupe :
 * ni l'un ni l'autre ne porte de compétence.
 */
export function planSeanceGroups(
    items: PlanSeanceItemDto[],
    now: Date = new Date(),
): PlanSeanceGroup[] {
    const groups: PlanSeanceGroup[] = [];
    for (const item of items) {
        const epreuve = itemEpreuve(item);
        const task = skillTaskCode(item.skillCode);
        let key: string;
        let context: string | null;
        if (task) {
            key = `task:${task}`;
            context = null;
        } else if (item.exercise === null) {
            key = `assess:${epreuve}`;
            context = planAssessmentNature(item.assessment);
        } else if (
            item.exercise.kind === "EPREUVE_MOCK_EXAM"
            || item.exercise.kind === "FULL_TCF_MOCK_EXAM"
        ) {
            key = `exam:${epreuve}`;
            context = PLAN_MILESTONE_PILL;
        } else {
            key = `level:${epreuve}:${item.level ?? "-"}`;
            context = item.level ? planGroupLevelContext(item.level) : null;
        }

        let group = groups.find((candidate) => candidate.key === key);
        if (!group) {
            group = {
                ...planGroupHead({key, epreuve, skillCode: item.skillCode, context}),
                rows: [],
                minutes: 0,
                done: true,
                locked: true,
            };
            groups.push(group);
        }
        const row: PlanSeanceGroupRow = {
            key: planSeanceItemKey(item),
            item,
            done: planSeanceItemDone(item, now),
            locked: planSeanceItemLocked(item),
        };
        group.rows.push(row);
        group.minutes += planItemMinutes(item) ?? 0;
        group.done = group.done && row.done;
        group.locked = group.locked && row.locked;
    }
    return groups;
}

/** Le résumé d'un encart de séance, fermé : la tâche, combien d'entraînements,
 *  combien de temps. */
export function planSeanceGroupSummary(group: PlanSeanceGroup): string {
    const count = `${group.rows.length} entraînement${group.rows.length > 1 ? "s" : ""}`;
    /* ⚠️ Une mesure n'a pas de durée (diagnostic, production : rien n'y est
       chronométré par épreuve) : un encart qui n'en contient que des mesures
       totalise 0 et n'affiche alors **aucune** minute — jamais « 0 min ».
       Miroir du mobile (`planSeanceGroupSummary`). */
    const minutes = group.minutes > 0 ? `${group.minutes} min` : null;
    return [group.taskTitle, count, minutes].filter(Boolean).join(" · ");
}

/** La ligne de tête de « Aujourd'hui » pour un compte dont **tout** est ouvert :
 *  combien d'épreuves, combien d'entraînements, combien de temps.
 *
 *  ⚠️ `epreuves` compte des **épreuves distinctes**, jamais des encarts : deux
 *  tâches d'une même épreuve font deux encarts et une seule épreuve. Miroir du
 *  mobile (`planSeanceHeaderMeta`). */
export function planSeanceGroupedMeta(epreuves: number, items: number, minutes: number): string {
    return `${epreuves} épreuve${epreuves > 1 ? "s" : ""} · ${items} entraînement${items > 1 ? "s" : ""} `
        + `· environ ${minutes} min`;
}

/**
 * La même ligne quand une partie de la séance est fermée.
 *
 * 🛑 **Le compte est VRAI** : il se lit sur les lignes que le serveur a
 * réellement laissées ouvertes, jamais sur une constante de maquette — une
 * compétence de rang 2 peut être ouverte (celle de la première place du Plan
 * l'est toujours).
 */
export function planSeanceFreeMeta(open: number, items: number, minutes: number): string {
    return `${open} entraînement${open > 1 ? "s" : ""} gratuit${open > 1 ? "s" : ""} sur ${items} `
        + `· environ ${minutes} min`;
}

/** Ce que dit le bouton d'une ligne ouverte de la séance, et ce que lit un
 *  lecteur d'écran sur une ligne déjà faite. */
export const PLAN_SEANCE_ROW_START = "Commencer";
export const PLAN_SEANCE_ROW_DONE_LABEL = "Déjà travaillé";

/** La ligne de contexte d'un encart ouvert : la tâche en toutes lettres, ou ce
 *  sur quoi porte le groupe quand il n'y a pas de tâche. */
export function planGroupContextLine(head: PlanGroupHead): string {
    if (head.taskNumber === null || head.taskTitle === null) {
        return head.context ?? planDomainLabel(head.epreuve);
    }
    return `${planTaskBadge(head.taskNumber)} — ${head.taskTitle}`;
}

/** L'épreuve d'un domaine de compétence — le pendant de `PLAN_DOMAIN_SECTION`. */
export function planSectionEpreuve(section: SkillSection): PlanDomainEpreuve {
    switch (section) {
        case "CO": return "TCF_CO";
        case "CE": return "TCF_CE";
        case "EO": return "TCF_EO";
        default: return "TCF_EE";
    }
}

/**
 * Le palier que le référentiel porte sur une compétence.
 *
 * Lu sur `domaines[].skills[]` — la liste **uniforme** des quatre domaines —,
 * avec repli sur les paliers de compréhension. `null` quand rien ne le publie :
 * *null = inconnu, jamais mauvais*, et aucun palier n'est fabriqué.
 */
export function planSkillTargetLevel(plan: LearningPlanDto, skillId: string): TargetLevel | null {
    for (const domain of plan.domaines) {
        for (const skill of domain.skills ?? []) {
            if (skill.skillId === skillId) return skill.targetLevel;
        }
    }
    return planSkillLevel(plan, skillId);
}

/** « Série ciblée de 20 questions » — la taille est **décidée serveur**. Sans
 *  elle, on ne l'invente pas. Miroir mot pour mot du mobile
 *  (`planSeriesLabel`). */
export function planSeriesLabel(questionCount: number | null): string {
    return questionCount === null
        ? "Série ciblée de compréhension"
        : `Série ciblée de ${questionCount} questions`;
}

/* -------------------------------------------------- parcours d'une tâche */



/**
 * Une étape d'un parcours **de tâche** ou **civique**, telle que le kit la rend.
 *
 * ⚠️ **À ne pas confondre avec `JourneyStepDto`** : celui-là est une étape du
 * **parcours TCF** (la file servie par `/api/me/plan/journey`). Ce type-ci ne
 * décrit plus que le parcours civique — le parcours de tâche a été supprimé le
 * 2026-09-17 avec le bloc « Votre parcours — Tâche X » (spec §11).
 */
export type PlanPathStep = {
    label: string;
    state: "done" | "verify" | "doing" | "now" | "todo";
    pill?: string;
};

/**
 * L'**apparence** d'un état d'étape dans le kit. Elle ne décide rien : l'état
 * arrive servi, cette table dit seulement quelle forme lui donner.
 *
 * 🛑 `SERIE_TERMINEE` n'est **pas** `done` : la coche verte dit « acquis », et
 * une série finie sans preuve en situation ne l'est pas. `A_VERIFIER` a sa
 * forme propre — c'est le seul état qui appelle une action d'une autre nature.
 *
 * ⚠️ Miroir de `planStepKitState` (`mobile .../screens/plan/plan_step_state.dart`).
 */
export function planStepKitState(state: PlanSkillStepState): PlanPathStep["state"] {
    switch (state) {
        case "ACQUIS": return "done";
        case "A_VERIFIER": return "verify";
        case "SERIE_TERMINEE": return "doing";
        case "MAINTENANT": return "now";
        case "EN_COURS": return "doing";
        case "A_VENIR": return "todo";
    }
}

/**
 * Le libellé d'un état d'étape, **avec sa progression réelle** quand elle
 * éclaire quelque chose : « Série terminée · 5/5 », « En cours · 2/5 ».
 *
 * 🛑 Le libellé vient de l'enum servi ; seuls les **nombres** s'y ajoutent, et
 * ce sont ceux que le serveur a comptés. Aucun état n'est déduit ici.
 *
 * 🛑 Aucun palier CECRL ne s'y accroche : « Acquis · B1 » n'existe pas. Le
 * palier d'une compétence est notre palier **pédagogique interne** et s'affiche
 * à part, « Niveau visé B1 ».
 *
 * ⚠️ Miroir de `planStepStateLabel` (mobile).
 */
export function planStepStateLabel(skill: {
    stepState: PlanSkillStepState;
    stepPromptCount: number;
    stepAttemptedCount: number;
}): string {
    const label = PLAN_SKILL_STEP_STATE_LABEL[skill.stepState];
    const compteur = `${skill.stepAttemptedCount}/${skill.stepPromptCount}`;
    if (skill.stepPromptCount === 0) return label;
    if (skill.stepState === "SERIE_TERMINEE") return `${label} · ${compteur}`;
    if (skill.stepState === "EN_COURS") return `${label} · ${compteur}`;
    return label;
}

/** La pastille d'une ligne de parcours. `undefined` sur « À venir » : une ligne
 *  que rien n'a encore touchée n'a rien à annoncer. */
function planStepStatePill(skill: PlanDomainSkillDto): string | undefined {
    return skill.stepState === "A_VENIR" ? undefined : planStepStateLabel(skill);
}
