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
import {
    type LearningPlanDto,
    type LearningPlanPriorityDto,
    type LearningPlanSkillStatus,
    type NiveauCecrl,
    niveauCecrlLabel,
    PLAN_ACTION_NATURE_LABEL,
    type PlanActionNature,
    type PlanCycleDto,
    type PlanDomainAssessmentDto,
    type PlanDomainDto,
    type PlanDomainLevelDto,
    type PlanDomainTaskDto,
    type PlanPathStepDto,
    type PlanRecentChangesDto,
    type PlanSeanceItemDto,
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

/** Intertitre du chemin, même prudence sur l'objectif inconnu. */
export function planPathTitle(cycle: PlanCycleDto): string {
    return cycle.objectiveLevel ? `Mon chemin vers le ${cycle.objectiveLevel}` : "Mon chemin";
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

/** Titre d'une étape du chemin. Le serveur donne `kind` + `level` ; la
 *  formulation appartient au front. */
export function planPathStepTitle(step: PlanPathStepDto): string {
    if (step.kind === "COMPLETE_PROFILE") return "Compléter mon profil";
    if (step.kind === "STABILIZE") return "Tenir mon niveau en conditions d'examen";
    return `Construire mon ${step.level}`;
}

/** Le repère sous le titre : où en est cette étape, et sur quoi elle porte. */
export function planPathStepMeta(step: PlanPathStepDto, cycle: PlanCycleDto): string {
    const état = step.status === "DONE" ? "terminé" : step.status === "UPCOMING" ? "à venir" : null;
    if (step.kind === "COMPLETE_PROFILE") {
        const base = `${cycle.domainsEvaluated} / ${cycle.domainsExpected} domaines`;
        return état ? `${base} · ${état}` : base;
    }
    const base = step.kind === "STABILIZE"
        ? "Examens blancs"
        : `Palier ${step.level}`;
    return état ? `${base} · ${état}` : base;
}

export const PLAN_PATH_CURRENT_BADGE = "En cours";

/**
 * **Comment un palier se confirme.** C'est le cœur du parcours : on ne change
 * pas de niveau parce qu'on a fini des exercices, mais parce qu'un **examen
 * blanc complet** l'a confirmé en conditions réelles.
 *
 * 🛑 **Rien n'est déduit ici** : la phrase ne s'affiche que sur une étape de
 * palier (`BUILD_LEVEL`) **pas encore terminée**, et sa variante « maintenant »
 * se lit sur l'état servi (`READY_FOR_GATE_MOCK`) — jamais sur un calcul du
 * front. Une étape déjà franchie ne dit rien : le serveur ne publie pas
 * *comment* elle l'a été, et l'inventer serait faux.
 *
 * Miroir mot pour mot de `planPathStepNote` côté mobile.
 */
export function planPathStepNote(step: PlanPathStepDto, cycle: PlanCycleDto): string | null {
    if (step.kind !== "BUILD_LEVEL") return null;
    if (step.status === "DONE") return null;
    if (step.status === "CURRENT" && cycle.state === "READY_FOR_GATE_MOCK") {
        return PLAN_GATE_READY;
    }
    return PLAN_GATE_RULE;
}

export const PLAN_GATE_RULE = "Ce palier se confirme par un examen blanc complet.";
export const PLAN_GATE_READY =
    "Vous y êtes : un examen blanc complet peut maintenant confirmer ce palier.";

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

export const PLAN_COMPLETE_PROFILE_TITLE = "Compléter mon profil";
export const PLAN_COMPLETE_PROFILE_TEXT =
    "Un domaine se mesure sur un vrai passage, pas sur un entraînement. Votre profil se précise à chaque épreuve passée.";
/** 🛑 La phrase que la séance ne doit jamais laisser croire l'inverse : une
 *  série ciblée entraîne, elle ne mesure pas. */
export const PLAN_COMPLETE_PROFILE_NOTE =
    "Les séries ciblées font progresser vos compétences, mais ne remplacent pas un examen blanc : c'est lui qui donne un niveau au domaine.";

/** Par quoi mesurer ce domaine — le CTA nomme le parcours réel, jamais un
 *  contenu inventé. */
export function planAssessmentCta(assessment: PlanDomainAssessmentDto): string {
    if (assessment.kind === "DIAGNOSTIC") return "Faire mon diagnostic";
    if (assessment.kind === "PRODUCTION") return "Faire une production";
    return "Passer l'examen blanc";
}

/** Le parcours **réel** qu'ouvre une mesure, nommé tel quel. Aucun contenu
 *  n'est créé : chacune de ces trois natures existe déjà. */
export function planAssessmentNature(assessment: PlanDomainAssessmentDto): string {
    if (assessment.kind === "DIAGNOSTIC") return "Diagnostic";
    if (assessment.kind === "PRODUCTION") return "Production complète";
    return `Examen blanc n°${assessment.slotNumber ?? 1}`;
}

/** Le repère factuel de la ligne : la nature du passage et sa durée quand elle
 *  en a une (le diagnostic et une production ne sont pas chronométrés par
 *  épreuve — on n'écrit alors aucune minute). */
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

/** Ce que fait un item, en trois mots — la **nature de l'action**, lue sur
 *  `exercise.kind` et jamais devinée d'un identifiant nul. Sur une **mesure**,
 *  c'est le parcours réel qu'on nomme (diagnostic, production, examen blanc). */
export function planItemNature(item: PlanSeanceItemDto): string {
    if (item.exercise === null) return planAssessmentNature(item.assessment);
    switch (item.exercise.kind) {
        case "MICRO_TRAINING":
            return "Petit sujet ciblé";
        case "REASSESSMENT":
            return "Vérification en situation";
        case "TARGETED_QCM_SERIES":
            return planSeriesLabel(item.exercise.questionCount);
        case "EPREUVE_MOCK_EXAM":
            return "Examen blanc d'épreuve";
        case "FULL_TCF_MOCK_EXAM":
            return "Examen blanc TCF complet";
    }
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

/** Un état de maîtrise en clair, ou `null` quand rien n'a été observé — on
 *  n'invente pas un état pour une compétence que le serveur n'a jamais vue. */
export function masteryLabel(state: SkillMasteryState | null): string | null {
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

/* ----------------------------------------------------- priorités groupées */

/**
 * Une ligne d'un encart de « Mes priorités ».
 *
 * ⚠️ **Elle ne vient plus forcément d'une priorité.** Un encart porte
 * **toutes** les compétences de sa tâche (ou de son palier) : celles que le
 * Plan demande de travailler **et** celles qui ont seulement été observées,
 * *solides comprises*. C'est ce qui permet à son résumé de dire « 1 priorité ·
 * 2 à renforcer · 3 solides » — et au candidat de voir qu'il a de quoi
 * travailler sans qu'une seconde section vienne redire la même chose ailleurs.
 *
 * 🛑 **Une compétence jamais observée et sans nature n'est PAS une ligne** :
 * elle n'est ni un acquis ni une action, et la compter gonflerait le résumé
 * d'un travail que le Plan ne demande pas.
 */
export interface PlanPriorityGroupRow {
    skillId: string;
    skillCode: string;
    title: string;
    section: SkillSection;
    /** La priorité servie quand cette ligne en est une — **elle seule** porte
     *  `recommendedExercise` et les compteurs d'étape. `null` sur une
     *  compétence seulement observée : rien n'y est demandé. */
    priority: LearningPlanPriorityDto | null;
    /** Ce que la pastille annonce, et ce que le résumé de l'encart compte. */
    status: PlanRowStatus;
    /** Palier porté par le référentiel — celui qu'annonce « À acquérir · B1 ».
     *  `null` quand il n'est pas publié : on n'en invente pas. */
    level: TargetLevel | null;
    /** Le `locked` du serveur, jamais le rang de la ligne. 🛑 Une compétence
     *  **solide** n'est jamais verrouillée à l'affichage : c'est une mesure du
     *  candidat, pas une action fermée. */
    locked: boolean;
}

export interface PlanPriorityGroup extends PlanGroupHead {
    /** **Toutes** les lignes du groupe, jamais tronquées ici : le plafond
     *  d'affichage vit au point d'appel, à côté du compteur qu'il alimente —
     *  sinon le « + N autres » serait faux par construction. */
    rows: PlanPriorityGroupRow[];
    /** Toutes les lignes sont fermées : l'encart porte un cadenas et mène à
     *  l'offre au lieu de se déplier. */
    locked: boolean;
}

/** La clé d'un encart : une **tâche** en expression, un couple (domaine,
 *  palier) en compréhension. Une seule règle, partagée par les deux passes de
 *  `planPriorityGroups` — deux copies rangeraient la même compétence dans deux
 *  encarts différents. */
function planPriorityGroupKey(
    epreuve: PlanDomainEpreuve,
    skillCode: string,
    level: TargetLevel | null,
): string {
    const task = skillTaskCode(skillCode);
    return task ? `task:${task}` : `level:${epreuve}:${level ?? "-"}`;
}

/** Le verrou d'affichage d'une ligne : celui du serveur, sauf sur une
 *  compétence **solide** — on floute l'action pas encore accessible, jamais le
 *  résultat mesuré. */
function planRowLocked(locked: boolean, status: PlanRowStatus): boolean {
    return locked && status !== "SOLIDE";
}

/**
 * Les priorités, groupées par épreuve puis par tâche — même règle que la
 * séance, mêmes en-têtes. L'ordre des priorités reste **celui du serveur**.
 *
 * **Deux passes, et une seule ouvre des encarts.** La première pose un encart
 * par tâche (ou par palier) réellement priorisée, dans l'ordre servi ; la
 * seconde y verse les autres compétences du même groupe, lues sur
 * `domaines[].skills` — la liste **complète** du référentiel, à ne pas
 * confondre avec `observedSkills`, plafonné à huit toutes épreuves confondues
 * et donc incapable de garnir un encart. Aucun encart n'est ouvert par la
 * seconde passe : « Mes priorités » listerait alors les six tâches.
 */
export function planPriorityGroups(
    plan: LearningPlanDto,
    priorities: LearningPlanPriorityDto[],
): PlanPriorityGroup[] {
    const groups: PlanPriorityGroup[] = [];
    const placed = new Set<string>();

    for (const priority of priorities) {
        const epreuve = planSectionEpreuve(priority.section);
        const task = skillTaskCode(priority.skillCode);
        const level = planSkillTargetLevel(plan, priority.skillId);
        const key = planPriorityGroupKey(epreuve, priority.skillCode, level);
        const context = task || !level ? null : planGroupLevelContext(level);

        let group = groups.find((candidate) => candidate.key === key);
        if (!group) {
            group = {
                ...planGroupHead({key, epreuve, skillCode: priority.skillCode, context}),
                rows: [],
                locked: true,
            };
            groups.push(group);
        }
        const status = planRowStatus(priority);
        group.rows.push({
            skillId: priority.skillId,
            skillCode: priority.skillCode,
            title: priority.title,
            section: priority.section,
            priority,
            status,
            level,
            locked: planRowLocked(priority.locked, status),
        });
        placed.add(priority.skillId);
    }

    /* L'ordre du référentiel, tel que le serveur l'a servi : `domaines` est
       déjà trié par urgence, et `skills` par tâche puis rang d'affichage. On ne
       retrie rien. */
    for (const domain of plan.domaines) {
        for (const skill of domain.skills ?? []) {
            if (placed.has(skill.skillId)) continue;
            /* Ni observée, ni demandée : ce n'est ni un acquis ni une action. */
            if (skill.observedAt === null && skill.nature === null) continue;
            const key = planPriorityGroupKey(domain.epreuve, skill.skillCode, skill.targetLevel);
            const group = groups.find((candidate) => candidate.key === key);
            if (!group) continue;
            const status = planRowStatus(skill);
            group.rows.push({
                skillId: skill.skillId,
                skillCode: skill.skillCode,
                title: skill.title,
                section: skill.section,
                priority: null,
                status,
                level: skill.targetLevel,
                locked: planRowLocked(skill.locked, status),
            });
            placed.add(skill.skillId);
        }
    }

    for (const group of groups) {
        group.locked = group.rows.every((row) => row.locked);
    }
    return groups;
}

/** Combien de lignes un encart déroule avant de renvoyer vers la fiche de son
 *  domaine. **C'est un plafond d'AFFICHAGE**, pas une troncature des données :
 *  le groupe garde toutes ses lignes, et le « + N autres » se calcule dessus. */
export const PLAN_PRIORITY_ROWS_VISIBLE = 6;

/** « + 3 autres compétences ». 🛑 Le nombre est **vrai**, calculé sur le
 *  contenu réel du groupe ; `0` ⇒ l'appelant n'affiche rien du tout. */
export function planGroupMoreLabel(count: number): string {
    return `+ ${count} autre${count > 1 ? "s" : ""} compétence${count > 1 ? "s" : ""}`;
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

/**
 * **Le statut d'affichage d'une ligne de priorité** — une vue de deux faits
 * servis, jamais un jugement neuf.
 *
 * La **nature** dit ce qu'il y a à faire ; l'**état agrégé** dit où en est la
 * compétence. Une fragilité que le moteur tient déjà pour `SOLID` se dit
 * « solide », celle qu'il tient pour la plus bloquante se dit « priorité » :
 * c'est ce qui permet à un encart fermé de résumer ses lignes — « 1 priorité ·
 * 2 à renforcer » — sans les déplier.
 *
 * 🛑 **Aucune des deux sources n'est réinterprétée** : une acquisition n'a rien
 * d'observé et reste « à acquérir » quoi qu'il arrive, une vérification reste
 * « à vérifier », une mesure reste « à évaluer ».
 *
 * ⚠️ **Miroir du mobile** (`PlanRowStatus`, `planRowStatus`) : l'ordre de
 * déclaration EST l'ordre du résumé — ce qui bloque, ce qui se répare, ce qui
 * s'apprend, ce qui se prouve, ce qui tient, ce qui manque d'être mesuré.
 */
export type PlanRowStatus =
    | "PRIORITE"
    | "A_RENFORCER"
    | "A_ACQUERIR"
    | "A_VERIFIER"
    | "SOLIDE"
    | "A_EVALUER";

const PLAN_ROW_STATUS_ORDER: readonly PlanRowStatus[] = [
    "PRIORITE",
    "A_RENFORCER",
    "A_ACQUERIR",
    "A_VERIFIER",
    "SOLIDE",
    "A_EVALUER",
];

/** Les libellés sont **empruntés**, jamais recopiés : « Priorité » et
 *  « Solide » viennent de `SKILL_MASTERY_STATE_LABEL`, les quatre autres de
 *  `PLAN_ACTION_NATURE_LABEL`. Un libellé qui bouge côté serveur bouge ici sans
 *  que personne y touche. */
export const PLAN_ROW_STATUS_LABEL: Record<PlanRowStatus, string> = {
    PRIORITE: SKILL_MASTERY_STATE_LABEL.PRIORITY,
    A_RENFORCER: PLAN_ACTION_NATURE_LABEL.A_RENFORCER,
    A_ACQUERIR: PLAN_ACTION_NATURE_LABEL.A_ACQUERIR,
    A_VERIFIER: PLAN_ACTION_NATURE_LABEL.A_VERIFIER,
    SOLIDE: SKILL_MASTERY_STATE_LABEL.SOLID,
    A_EVALUER: PLAN_ACTION_NATURE_LABEL.A_EVALUER,
};

export function planRowStatus(skill: {
    nature: PlanActionNature | null;
    status: LearningPlanSkillStatus | null;
    masteryState: SkillMasteryState | null;
}): PlanRowStatus {
    switch (skill.nature) {
        case "A_EVALUER": return "A_EVALUER";
        case "A_ACQUERIR": return "A_ACQUERIR";
        case "A_VERIFIER": return "A_VERIFIER";
        case "A_RENFORCER":
            if (skill.masteryState === "SOLID") return "SOLIDE";
            if (skill.masteryState === "PRIORITY") return "PRIORITE";
            return skill.status === "PRIORITY" ? "PRIORITE" : "A_RENFORCER";
        default:
            /* Aucune action demandée : la ligne dit alors ce qui a été
               **mesuré**. L'état agrégé prime sur le verdict d'une seule
               production — c'est lui que la fiche de la compétence affiche. */
            if (skill.masteryState === "SOLID") return "SOLIDE";
            if (skill.masteryState === "PRIORITY") return "PRIORITE";
            if (skill.status === "SOLID") return "SOLIDE";
            return skill.status === "PRIORITY" ? "PRIORITE" : "A_RENFORCER";
    }
}

/** Le libellé complet d'une pastille. « À acquérir » y **ajoute son palier
 *  cible** — c'est le seul statut qui désigne un palier à venir plutôt qu'un
 *  constat, et sans lui le candidat ne sait pas ce qu'il apprend. Sans palier
 *  servi, on ne le nomme pas. */
export function planRowStatusLabel(status: PlanRowStatus, level: TargetLevel | null): string {
    return status === "A_ACQUERIR" && level
        ? `${PLAN_ROW_STATUS_LABEL[status]} · ${level}`
        : PLAN_ROW_STATUS_LABEL[status];
}

/* Les formes comptées du résumé : « 1 priorité · 2 priorités ». Les quatre
   natures s'écrivent déjà avec « à » et ne varient pas — leur forme comptée est
   donc leur libellé en bas de casse, comme sur mobile. */
function plannedStatusWord(status: PlanRowStatus, count: number): string {
    if (status === "PRIORITE") return count > 1 ? "priorités" : "priorité";
    if (status === "SOLIDE") return count > 1 ? "solides" : "solide";
    return PLAN_ROW_STATUS_LABEL[status].toLowerCase();
}

/** « 1 priorité · 2 à renforcer ». **Ordre figé** par `PLAN_ROW_STATUS_ORDER` ;
 *  un statut absent ne s'écrit pas. */
export function planRowStatusSummary(statuses: PlanRowStatus[]): string {
    return PLAN_ROW_STATUS_ORDER
        .map((status) => {
            const count = statuses.filter((candidate) => candidate === status).length;
            return count === 0 ? null : `${count} ${plannedStatusWord(status, count)}`;
        })
        .filter(Boolean)
        .join(" · ");
}

/** Le résumé d'un encart de priorités, fermé : la tâche, puis ce qu'elle
 *  contient. */
export function planPriorityGroupSummary(group: PlanPriorityGroup): string {
    const statuses = group.rows.map((row) => row.status);
    return [group.taskTitle, planRowStatusSummary(statuses)].filter(Boolean).join(" · ");
}

/* Les deux intertitres d'un encart de priorités ouvert. */
export const PLAN_GROUP_ASIDE_TITLE = "Où je travaille";
export const PLAN_GROUP_ROWS_TITLE = "Ce que je dois améliorer";

/* Ce que dit une ligne de priorité sous son titre. Aucune ne nomme une faute :
   une compétence **à acquérir** dit ce qu'elle est, une compétence de
   compréhension dit par quoi elle se travaille. */
export const PLAN_PRIORITY_ROW_NEW = "Nouvelle compétence de votre palier";
export const PLAN_PRIORITY_ROW_PROMPTS = "Petits sujets ciblés";

export function planPriorityRowMeta(row: PlanPriorityGroupRow): string {
    const {priority, level} = row;
    if (row.status === "A_ACQUERIR") {
        return level ? `Nouvelle compétence du palier ${level}` : PLAN_PRIORITY_ROW_NEW;
    }
    /* 🛑 La branche se décide sur la **famille** de la compétence, jamais sur la
       présence d'un exercice : une compétence CO/CE n'a **aucun** `skill_prompt`
       (le contrat l'interdit), donc retomber sur les compteurs de sujets lui
       ferait afficher « Petits sujets ciblés » — un parcours qui n'existe pas
       pour elle. Miroir du mobile (`_PriorityRow.sub`). */
    if (isComprehension(row.section)) {
        const exercise = priority?.recommendedExercise ?? null;
        return planSeriesLabel(
            exercise && exercise.kind === "TARGETED_QCM_SERIES" ? exercise.questionCount : null,
        );
    }
    /* Une compétence seulement observée n'a **aucun** compteur d'étape servi :
       on dit par quoi elle se travaille, on n'invente pas de « 0 / 5 ». */
    if (priority && priority.stepPromptCount > 0) {
        return `${priority.stepAttemptedCount} / ${priority.stepPromptCount} petits sujets`;
    }
    return PLAN_PRIORITY_ROW_PROMPTS;
}

/** « Série ciblée de 20 questions » — la taille est **décidée serveur**. Sans
 *  elle, on ne l'invente pas. Miroir mot pour mot du mobile
 *  (`planSeriesLabel`). */
export function planSeriesLabel(questionCount: number | null): string {
    return questionCount === null
        ? "Série ciblée de compréhension"
        : `Série ciblée de ${questionCount} questions`;
}

/* Le bouton d'un encart de priorités ouvert — il vise la **première ligne non
   solide** du groupe. Trois libellés, parce que trois actions différentes :
   lancer une série, découvrir ce qu'on n'a jamais travaillé, ou reprendre une
   compétence déjà observée. */
export const PLAN_PRIORITY_CTA_SERIES = "Faire une série ciblée";
export const PLAN_PRIORITY_CTA_DISCOVER = "Découvrir cette compétence";
export const PLAN_PRIORITY_CTA_WORK = "Travailler cette compétence";
export const PLAN_PRIORITY_CTA_UNLOCK = "Débloquer cette compétence";

export function planPriorityGroupCta(row: PlanPriorityGroupRow): string {
    if (row.locked) return PLAN_PRIORITY_CTA_UNLOCK;
    if (isComprehension(row.section)) return PLAN_PRIORITY_CTA_SERIES;
    return row.status === "A_ACQUERIR" ? PLAN_PRIORITY_CTA_DISCOVER : PLAN_PRIORITY_CTA_WORK;
}

/**
 * La ligne que vise le bouton d'un encart : la **première non solide**.
 *
 * 🛑 **Un groupe entièrement solide n'a pas de bouton** (`null`) : tout y est
 * acquis, il n'y a rien à y faire — proposer « Travailler cette compétence »
 * sur une compétence solide renverrait le candidat sur du travail déjà prouvé.
 * Les priorités venant en tête du groupe, la ligne visée en est presque
 * toujours une ; une compétence seulement observée peut la porter, et elle
 * ouvre alors simplement sa fiche.
 */
export function planPriorityGroupAction(group: PlanPriorityGroup): PlanPriorityGroupRow | null {
    return group.rows.find((row) => row.status !== "SOLIDE") ?? null;
}
