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

import {competenceHref, productionSectionLabel, skillTaskNumber} from "@/lib/diagnostic";
import {
    type LearningPlanDto,
    type NiveauCecrl,
    niveauCecrlLabel,
    type PlanCycleDto,
    type PlanDomainAssessmentDto,
    type PlanDomainDto,
    type PlanPathStepDto,
    type PlanSeanceItemDto,
    type PlanMasteryTransitionDto,
    SKILL_MASTERY_STATE_LABEL,
    SKILL_SECTION_LABEL,
    type SkillMasteryState,
    type SkillSection,
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
    "Rien à faire pour le moment : votre plan se réordonnera à votre prochaine production.";

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
            return `Série ciblée de ${item.exercise.questionCount} questions`;
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

/** L'eyebrow d'une ligne de séance : le domaine, et le palier travaillé quand
 *  il y en a un (compréhension seulement — l'expression n'en porte pas). */
export function planItemEyebrow(item: PlanSeanceItemDto): string {
    const domaine = item.section ? item.section : planDomainShort(itemEpreuve(item));
    return item.level ? `${domaine} · ${item.level}` : domaine;
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
/** Ce que le lien annonce quand l'accès n'est pas ouvert — un **verrou de
 *  navigation**, pas un contenu masqué : le Plan lui-même reste entier. */
export const PLAN_SKILLS_LOCKED_LABEL =
    "Référentiel réservé à l'abonnement. Ouvrir l'offre pour le débloquer.";

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
export function planSeanceItemDone(item: PlanSeanceItemDto, now: Date = new Date()): boolean {
    if (item.stepPromptCount > 0 && item.stepCompleted) return true;
    if (!item.lastActivityAt) return false;
    const activity = new Date(item.lastActivityAt);
    if (Number.isNaN(activity.getTime())) return false;
    return parisDay(activity) === parisDay(now);
}
