/**
 * **Les mots des écrans Plan et Entraînement des deux modules** (Navigation v2,
 * phase 4 — maquette `docs/redesign/sejourfr-navigation-web.html`, écrans
 * `#tcf-plan`, `#tcf-entrainement`, `#civique-plan`, `#civique-entrainement`).
 *
 * 🛑 **Textes éditoriaux de la maquette repris tels quels (R8)** ; toute valeur
 * qu'ils contiennent — niveau cible, nombre d'épreuves, de thèmes, de séries,
 * seuil — arrive en paramètre, lue sur un fait servi ou un miroir gelé
 * (`tcf-epreuves`, `civique-examen`). Rien ici ne classe un nombre.
 */
import {ACCUEIL_INCONNU} from "./accueil";
import {CIVIQUE_EXAM_QUESTIONS, CIVIQUE_EXAM_SEUIL} from "./civique-examen";
import {TCF_EPREUVES_OFFICIELLES} from "./tcf-epreuves";
import type {TargetLevel} from "./types";

/** Le nombre d'épreuves du TCF IRN (miroir gelé `tcf-epreuves`). */
export const MODULE_TCF_NB_EPREUVES = TCF_EPREUVES_OFFICIELLES.length;

export const MODULE_TCF_KICKER = "Préparation TCF IRN";
export const MODULE_CIVIQUE_KICKER = "Préparation civique";

/** « Voir le détail » — le CTA des bandeaux qui mènent à la Progression. */
export const MODULE_VOIR_DETAIL = "Voir le détail";

function pluriel(n: number, un: string, plusieurs: string): string {
    return n > 1 ? plusieurs : un;
}

/* ------------------------------------------------------- TCF · Mon plan */

export const PLAN_TCF_TITLE = "Mon plan";

export function planTcfSubtitle(cible: TargetLevel | null | undefined): string {
    const vers = cible ? `Votre parcours vers le ${cible}, étape par étape.` : "Votre parcours, étape par étape.";
    return `${vers} Le plan met en avant les épreuves qui demandent le plus de travail.`;
}

/** « Niveau actuel · B1 » — `null` ⇒ « — » (`null = inconnu`). */
export function planTcfChipActuel(actuel: string | null): string {
    return `Niveau actuel · ${actuel ?? ACCUEIL_INCONNU}`;
}

export function planTcfChipObjectif(cible: TargetLevel): string {
    return `Objectif · ${cible}`;
}


export const PLAN_TCF_HERO_LABEL = "Ma progression";

/** « Objectif : B2 dans les 4 compétences ». Sans cible : rien. */
export function planTcfHeroSub(cible: TargetLevel | null | undefined): string | null {
    return cible ? `Objectif : ${cible} dans les ${MODULE_TCF_NB_EPREUVES} compétences` : null;
}

/** « épreuves au B2 » — le mot sous le compteur `{n}/{nbEpreuves}`. */
export function planTcfHeroStatLabel(cible: TargetLevel | null | undefined): string {
    return cible ? `épreuves au ${cible}` : "épreuves à l'objectif";
}

/** « 1/4 ». */
export function planTcfHeroStat(auNiveau: number): string {
    return `${auNiveau}/${MODULE_TCF_NB_EPREUVES}`;
}

/* -------------------------------------------------------- Civique · Plan */

export const PLAN_CIVIQUE_TITLE = "Plan";
export const PLAN_CIVIQUE_SUBTITLE =
    "Suivez votre plan civique thème par thème et avancez selon vos priorités.";

/** « Objectif examen · 32/40 » — seuil et format de l'arrêté (miroir gelé). */
export const PLAN_CIVIQUE_BADGE_SEUIL = `Objectif examen · ${CIVIQUE_EXAM_SEUIL}/${CIVIQUE_EXAM_QUESTIONS}`;

export const PLAN_CIVIQUE_HERO_LABEL = "Progression globale";
export const PLAN_CIVIQUE_HERO_SUB = "Votre parcours avance thème par thème, dans le bon ordre.";
export const PLAN_CIVIQUE_HERO_STAT = "du parcours";

/** « {n} séries terminées » — `0` s'écrit, jamais un vide. */
export function seriesTermineesTitre(n: number): string {
    return `${n} ${pluriel(n, "série terminée", "séries terminées")}`;
}

export const PLAN_CIVIQUE_EXAM_LABEL = "Examen blanc";
export const PLAN_CIVIQUE_EXAM_TITLE = "Examen blanc civique";
/** Aucun examen blanc civique servi : l'invitation au premier. */
export const PLAN_CIVIQUE_EXAM_EMPTY =
    "Passez votre premier examen blanc pour situer votre préparation.";

/** « Votre dernier score : 29 / 40 ». */
export function planCiviqueDernierScore(score: string): string {
    return `Votre dernier score : ${score}`;
}

/* --------------------------------------------------------- Entraînement */

export const ENTRAINEMENT_TITLE = "Entraînement";

export const ENTRAINEMENT_TCF_SUBTITLE =
    "Travaillez chaque épreuve sans vous disperser. L'oral et l'écrit sont renforcés par l'analyse IA.";

/** « 4 épreuves ». */
export const ENTRAINEMENT_TCF_BADGE = `${MODULE_TCF_NB_EPREUVES} épreuves`;

export const ENTRAINEMENT_METRIC_CTA = "S'entraîner";

/** Hero « Entretien en temps réel » (D3-B) : texte statique de la maquette. */
export const ENTRETIEN_SECTION_TITLE = "Entretien en temps réel";
export const ENTRETIEN_LABEL = "Simulation d'entretien · IA";
export const ENTRETIEN_TITLE = "Entraînez-vous comme à l'examen";
export const ENTRETIEN_SUB =
    "Répondez à des consignes et des relances dans un format vivant : réactivité, aisance, confiance.";
export const ENTRETIEN_STAT = {value: "EO", label: "expression orale"} as const;
export const ENTRETIEN_CTA = "Lancer une simulation";

/** Le sous-titre civique, avec le nombre de thèmes servi (inconnu ⇒ sans nombre). */
export function entrainementCiviqueSubtitle(nbThemes: number | null): string {
    const themes = nbThemes && nbThemes > 0 ? `les ${nbThemes} thèmes officiels` : "les thèmes officiels";
    return `Travaillez librement ${themes}, sans perturber votre plan recommandé.`;
}

/** « 5 thèmes ». */
export function entrainementThemesBadge(n: number): string {
    return `${n} ${pluriel(n, "thème", "thèmes")}`;
}

/** « {terminées}/{total} séries ». */
export function entrainementSeriesBadge(terminees: number, total: number): string {
    return `${terminees}/${total} séries`;
}

/** Le CTA d'une carte de thème — vers son hub. */
export const ENTRAINEMENT_THEME_CTA = "Continuer";
