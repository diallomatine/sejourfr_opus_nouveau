/**
 * **Les phrases des trois écrans d'expression** — détail de l'épreuve, détail
 * d'une tâche, fiche d'une compétence.
 *
 * 🛑 **Miroir mot pour mot de
 * `mobile_sejourfr/lib/screens/tcf_production/expression_labels.dart`.**
 * Un libellé qui bouge, ce sont deux fichiers dans la même passe.
 *
 * 🛑 **Rien n'est classé ici.** Chaque fonction pose une phrase sur des **faits
 * servis** : `masteryState` (dérivé par `SkillMasteryEngine`),
 * `skills.target_level` (le référentiel), les compteurs de sujets, et
 * `estimatedMinutes` (dérivé par `ExerciseDuration`). Aucune ne décide d'un état
 * pédagogique ni d'un palier.
 *
 * ## Les deux décisions que ce fichier applique (arbitrage du 2026-09-12)
 *
 * 🛑 **« Acquise » ≠ « Série terminée », et on dit les deux.**
 * - **Acquise** ⇔ `masteryState === "SOLID"`, c'est-à-dire transfert **prouvé
 *   sur une production complète** : le moteur exige au moins une observation
 *   contextualisée, jamais des micro-exercices seuls.
 * - **Série terminée** ⇔ tous les sujets du périmètre sont validés. C'est ce
 *   que le candidat a **fait**, pas ce qui est **prouvé**.
 * Les confondre reproduirait le défaut que le dépôt nomme « NON FRAGILE ≠ PLUS
 * RIEN À APPRENDRE ».
 *
 * 🛑 **Aucun palier CECRL ne s'affiche à côté d'« Acquis »** (arbitrage du
 * 2026-09-13). `skills.target_level` est notre palier **pédagogique interne** —
 * France Éducation international n'en rattache aucun à une tâche. « Acquis · A2 »
 * se lirait « vous avez cette compétence au niveau A2 », ce que le serveur ne
 * peut pas dire : `learning_plan_observations` ne porte **aucun niveau**, et
 * `ProgressionStateKey` interdit un `level` sur un `PRODUCTIVE_SKILL`. Le palier
 * ne s'affiche plus que comme **« Niveau visé »**, une fois, en tête de tâche.
 */

import type {
    LearningPlanDto,
    SkillDto,
    SkillMasteryState,
    SkillPromptSummaryDto,
    SkillSection,
} from "./types";

/* ------------------------------------------------- Acquis ⇄ série terminée */

export const EXPRESSION_ACQUIS = "Acquis";
export const EXPRESSION_EN_COURS = "En cours";
export const EXPRESSION_A_FAIRE = "À faire";
export const EXPRESSION_A_DECOUVRIR = "À découvrir";
export const EXPRESSION_SERIE_TERMINEE = "Série terminée";

/** Une compétence est acquise **quand le moteur l'a prouvée**, et pas avant. */
export function estAcquise(skill: {masteryState: SkillMasteryState | null}): boolean {
    return skill.masteryState === "SOLID";
}

/**
 * La pastille d'une ligne de compétence : « Acquis », « En cours », « À faire ».
 *
 * 🛑 **Sans palier** — cf. l'en-tête de ce fichier. Le serveur sait dire « cette
 * compétence est solide », jamais « tu l'as au A2 mais pas au B2 ».
 */
export function competenceBadge(skill: SkillDto): {label: string; tone: "acquis" | "encours" | "afaire"} {
    if (estAcquise(skill)) return {label: EXPRESSION_ACQUIS, tone: "acquis"};
    return skill.attemptedCount > 0
        ? {label: EXPRESSION_EN_COURS, tone: "encours"}
        : {label: EXPRESSION_A_FAIRE, tone: "afaire"};
}

/**
 * La ligne d'état sous le titre d'une compétence.
 *
 * L'ordre des cas **est** la règle : ce qui est **prouvé** passe devant ce qui
 * est **fait**, et « à découvrir » n'est dit qu'en dernier — jamais comme un
 * reproche.
 */
export function competenceStatus(skill: SkillDto): string {
    if (estAcquise(skill)) return EXPRESSION_ACQUIS;
    if (skill.promptCount > 0 && skill.attemptedCount >= skill.promptCount) {
        return `${EXPRESSION_SERIE_TERMINEE} · ${skill.validatedCount}/${skill.promptCount}`;
    }
    if (skill.attemptedCount > 0) {
        return `${EXPRESSION_EN_COURS} · ${skill.validatedCount}/${skill.promptCount} réussis`;
    }
    return EXPRESSION_A_DECOUVRIR;
}

/* ----------------------------------------------------------- Une tâche --- */

/**
 * « 3/8 compétences acquises » — **et `SOLID` seulement**.
 *
 * 🛑 Ni une compétence simplement observée, ni une série 5/5 ne comptent : le
 * compteur dit ce qui est **prouvé**. C'est de l'arithmétique sur un
 * `masteryState` **servi**, jamais une règle de classement rejouée ici.
 */
export function acquisesLabel(skills: readonly SkillDto[]): string {
    const acquises = skills.filter(estAcquise).length;
    const total = skills.length;
    // 🛑 Le pluriel suit le TOTAL, jamais le compteur : « 0/8 compétence
    // acquise » se lit comme une faute, et c'est bien « sur huit compétences »
    // que porte le nom. Même règle pour « 0/5 exercices réussis ».
    const s = total > 1 ? "s" : "";
    return `${acquises}/${total} compétence${s} acquise${s}`;
}

/** Le badge d'une tâche. `null` tant que rien n'y a été travaillé. */
export function tacheBadge(skills: readonly SkillDto[]): string | null {
    if (skills.length === 0) return null;
    // 🛑 « Acquis » sur une tâche n'a de sens que si les 8 le sont : à 3/8 le
    // badge contredirait le compteur affiché juste à côté.
    if (skills.every(estAcquise)) return EXPRESSION_ACQUIS;
    return skills.some((s) => s.attemptedCount > 0) ? EXPRESSION_EN_COURS : null;
}

/**
 * « NIVEAU VISÉ B1 » — le palier **pédagogique** de la tâche, dit comme tel.
 *
 * 🛑 **Deux formulations écartées, et pour deux raisons différentes.**
 * - La maquette porte « OBJECTIF B2 » sur la Tâche 1, qui est une tâche A2 :
 *   posé là, il laisse croire que la réussir vaut B2. L'objectif personnel vit
 *   sur l'écran **global** de l'épreuve, pas sur une tâche.
 * - « PALIER A2 » a été écarté à son tour (2026-09-13) : il se lit comme un
 *   palier **officiel** du TCF IRN, or France Éducation international ne
 *   rattache aucun niveau CECRL à une tâche.
 *
 * « Niveau visé » est la formule que `docs/notation-ia-eo-ee.md` impose déjà aux
 * écrans de production, et elle dit exactement ce que c'est.
 */
export function niveauViseBadge(targetLevel: string): string {
    return `Niveau visé ${targetLevel}`;
}

/* ------------------------------------------------- Une fiche de compétence */

export const EXPRESSION_LEARNING_POINTS_TITLE = "Vous allez apprendre à :";
export const EXPRESSION_COMPETENCE_ACQUISE = "Compétence acquise";
export const EXPRESSION_COMPETENCE_EN_COURS = "Compétence en cours";
export const EXPRESSION_COMPETENCE_A_DECOUVRIR = "Compétence à découvrir";

/**
 * L'eyebrow de la carte de tête d'une compétence.
 *
 * 🛑 **Trois états, et le troisième n'est pas un détail.** « Compétence en
 * cours » posé sur une compétence où rien n'a jamais été fait annonçait un
 * travail entamé qui n'existait pas — le cas est devenu la norme après la
 * bascule V3, qui a renouvelé les sujets de dix-neuf compétences. `masteryState`
 * et `attemptedCount` sont tous deux **servis** : on ne classe rien ici.
 */
export function competenceEyebrow(skill: SkillDto): string {
    if (estAcquise(skill)) return EXPRESSION_COMPETENCE_ACQUISE;
    if (skill.masteryState === null && skill.attemptedCount === 0) {
        return EXPRESSION_COMPETENCE_A_DECOUVRIR;
    }
    return EXPRESSION_COMPETENCE_EN_COURS;
}

/**
 * « 5 petits sujets · ≈ 4 min chacun ».
 *
 * 🛑 **« chacun », et c'est tout l'enjeu** : les 5 sujets d'une étape font une
 * quinzaine de minutes, pas cinq. Annoncer « ≈ 5 min » comme durée de séance
 * serait faux (arbitrage du 2026-09-12).
 *
 * La minute vient de `estimatedMinutes`, **servi** par `ExerciseDuration`. On
 * retient la **médiane** des sujets du périmètre : une moyenne serait tirée par
 * le sujet le plus long, et la valeur doit décrire le cas courant.
 */
export function sujetsMeta(prompts: readonly SkillPromptSummaryDto[]): string | null {
    if (prompts.length === 0) return null;
    const compte = `${prompts.length} petit${prompts.length > 1 ? "s" : ""} sujet${prompts.length > 1 ? "s" : ""}`;
    const minutes = [...prompts].map((p) => p.estimatedMinutes).filter((m) => m > 0).sort((a, b) => a - b);
    if (minutes.length === 0) return compte;
    return `${compte} · ≈ ${minutes[Math.floor(minutes.length / 2)]} min chacun`;
}

/**
 * Le CTA de la fiche d'une compétence — **il dit ce qui va réellement se
 * passer**.
 *
 * 🛑 Le périmètre terminé, « Continuer la séance » serait incohérent : il n'y a
 * plus rien à continuer. On propose alors de **retravailler**, ce qui est le
 * seul geste que les écrans existants savent faire — aucune logique métier
 * nouvelle n'est inventée ici.
 */
export function competenceCta(
    prompts: readonly SkillPromptSummaryDto[],
    opts: {locked: boolean},
): string {
    if (opts.locked) return EXPRESSION_CTA_LOCKED;
    const reste = prompts.filter((p) => p.status === "TODO").length;
    if (reste === 0) return prompts.length === 0 ? EXPRESSION_CTA_START : EXPRESSION_CTA_REDO;
    return reste === prompts.length ? EXPRESSION_CTA_START : EXPRESSION_CTA_CONTINUE;
}

export const EXPRESSION_CTA_START = "Commencer la séance";
export const EXPRESSION_CTA_CONTINUE = "Continuer la séance";
export const EXPRESSION_CTA_REDO = "Retravailler cette compétence";
export const EXPRESSION_CTA_LOCKED = "Voir l'abonnement Intégral";

/** « 0 restants » / « 3 restants » — ce qu'il reste à faire dans le périmètre. */
export function restantsLabel(prompts: readonly SkillPromptSummaryDto[]): string {
    const reste = prompts.filter((p) => p.status === "TODO").length;
    return `${reste} restant${reste > 1 ? "s" : ""}`;
}

/* ----------------------------------------------- « Recommandé pour vous » */



/** « Votre progression vers l'objectif B2 ». `null` sans objectif déclaré. */
export function progressionVersObjectif(objectif: string | null | undefined): string | null {
    return objectif ? `Votre progression vers l'objectif ${objectif}` : null;
}

/* ------------------------------------- La recommandation VIENT DU PLAN --- */

/**
 * **La compétence que le Plan recommande sur CETTE épreuve.**
 *
 * 🛑 **Jamais l'ordre du catalogue** (arbitrage du propriétaire, 2026-09-12).
 * L'écran cherchait la première compétence non terminée du référentiel : un
 * choix de catalogue, pas un choix pédagogique. On lit désormais le Plan, dans
 * l'ordre où lui-même range ses décisions :
 *
 *   1. `seance.items` — la séance du jour, déjà ordonnée par le serveur ;
 *   2. `currentPriority` — la priorité n°1 ;
 *   3. `nextPriorities` — les suivantes, dans l'ordre servi.
 *
 * 🛑 **Aucun repli artificiel.** Le Plan classe les **quatre** domaines par
 * urgence : un candidat dont la priorité n°1 est en compréhension n'a rien à
 * recommander ici. On rend alors `null` et **la carte disparaît** — retomber sur
 * « la première case libre » recommanderait autre chose que le Plan.
 *
 * 🛑 **Rien n'est compté ici** : les compteurs d'étape (« 2/5 exercices
 * réussis ») arrivent servis.
 */
export interface ExpressionRecommendation {
    skillId: string;
    /** `EE2-C3` — sert à composer l'adresse de la fiche (`competenceHref`). */
    skillCode: string;
    section: SkillSection;
    title: string;
    taskCode: string | null;
    /** Compteurs de l'ÉTAPE, servis par le Plan. */
    validated: number;
    total: number;
    locked: boolean;
}


/** `"EE2-C3"` → `"EE2"`. Un code inattendu rend `null` plutôt qu'une tâche inventée. */
function taskCodeOf(skillCode: string | null | undefined): string | null {
    const match = /^(EE|EO)[1-3]/.exec(skillCode ?? "");
    return match ? match[0] : null;
}
