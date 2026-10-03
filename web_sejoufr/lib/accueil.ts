/**
 * **Les mots de l'Accueil** (Navigation v2, phase 3 — maquette `#accueil`).
 * Purs, déclarés une fois pour le web.
 *
 * 🛑 **Textes éditoriaux de la maquette repris tels quels (R8), valeurs
 * servies partout ailleurs (R3).** Aucune fonction ici ne classe un nombre en
 * état ni en niveau : elles posent des mots sur des faits servis — palier
 * estimé, niveau cible, statut d'épreuve, avancement du cycle, compteurs de
 * séries — ou sur les miroirs gelés existants (`civique-examen`,
 * `tcf-epreuves`).
 *
 * ⚠️ Miroir mobile : les libellés de l'Accueil Flutter (même phase) — un
 * libellé qui bouge, ce sont deux fichiers dans la même passe.
 */
import {CIVIQUE_EXAM_QUESTIONS, CIVIQUE_EXAM_SEUIL} from "./civique-examen";
import type {CivicNowVue} from "./civic-plan";
import {JOURNEY_NEEDS_OBJECTIVE_TITLE} from "./journey";
import type {PlanNowVue} from "./plan-domain";
import {TCF_EPREUVES_OFFICIELLES} from "./tcf-epreuves";
import {
    niveauCecrlShort,
    type JourneyCycleDto,
    type NiveauCecrl,
    type ProgressEpreuveDto,
    type TargetLevel,
} from "./types";

/** La valeur d'une mesure absente (`null = inconnu, jamais mauvais`). */
export const ACCUEIL_INCONNU = "—";

/* ------------------------------------------------------------ En-tête */

/** « Bonjour Prénom Nom » — le nom du compte, tel qu'il est servi. */
export function accueilBonjour(firstName?: string | null, lastName?: string | null): string {
    const nom = [firstName?.trim(), lastName?.trim()].filter(Boolean).join(" ");
    return nom ? `Bonjour ${nom}` : "Bonjour à vous";
}

/** Sous-titre statique de la maquette web (sa version longue). */
export const ACCUEIL_SUBTITLE =
    "Deux préparations, une seule application. Tout votre parcours, sans vous demander où aller.";

/* ------------------------------------------------------------ Sections */

export const ACCUEIL_NOW_TITLE = "À faire maintenant";
export const ACCUEIL_OBJECTIVES_TITLE = "Mes objectifs";

/** Les labels de module (maquette : `.label`, `.obj-pill`). */
export const ACCUEIL_TCF_LABEL = "TCF IRN";
export const ACCUEIL_CIVIQUE_LABEL = "Examen civique";

/* ------------------------------------------------- « À faire maintenant » */

export const ACCUEIL_TCF_CTA = "Continuer le TCF";
export const ACCUEIL_CIVIQUE_CTA = "Continuer le civique";

/** Le bloc ne s'est pas chargé : on le dit, le reste de l'écran reste là. */
export const ACCUEIL_BLOCK_ERROR = "Ce bloc n'a pas pu être chargé.";
export const ACCUEIL_RETRY = "Réessayer";

function joindre(parts: Array<string | null | undefined>): string | null {
    const kept = parts.filter((p): p is string => Boolean(p && p.trim()));
    return kept.length > 0 ? kept.join(" · ") : null;
}

/**
 * La méta de la carte TCF : `{type} · {durée}` — `kindLabel ?? subtitle`, puis
 * `minutesLabel`, servis. Une durée absente est masquée, jamais inventée.
 * Miroir de `homeActionMeta([kindLabel ?? subtitle, minutesLabel])` (mobile).
 */
export function accueilTcfActionMeta(vue: PlanNowVue): string | null {
    return joindre([vue.kindLabel ?? vue.subtitle, vue.minutesLabel]);
}

/**
 * La méta de la carte civique, **selon le type de l'étape servie** : un examen
 * de thème se dit « Examen blanc », une unité officielle se situe par son
 * thème, une cible du plan dérivé par sa série. Pas de méta figée.
 */
export function accueilCiviqueActionMeta(vue: CivicNowVue): string | null {
    return joindre([vue.subtitle, vue.meta]);
}

/* ------------------------------------------------------- « Mes objectifs » */

/** Le nombre d'épreuves du TCF IRN (miroir gelé `tcf-epreuves`). */
export const ACCUEIL_TCF_NB_EPREUVES = TCF_EPREUVES_OFFICIELLES.length;

/**
 * « Atteindre B2 partout » — le niveau cible est `AuthenticatedUser.targetLevel`.
 * Sans cible (compte sans démarche) : « Choisir mon objectif », jamais
 * « Atteindre — partout ». Miroir de `homeGoalText` / `kJourneyNeedsObjectiveTitle`.
 */
export function accueilTcfObjectifTitre(cible: TargetLevel | null | undefined): string {
    return cible ? `Atteindre ${cible} partout` : JOURNEY_NEEDS_OBJECTIVE_TITLE;
}

/** La méta de la ligne TCF (maquette mobile). */
export const ACCUEIL_TCF_OBJECTIF_META = "Progression vers l'objectif";

/** « B1 → B2 » : niveau actuel estimé (servi) → niveau cible. */
export function accueilTcfProgression(
    actuel: NiveauCecrl | null | undefined,
    cible: TargetLevel | null | undefined,
): string {
    const de = actuel ? niveauCecrlShort(actuel) : ACCUEIL_INCONNU;
    return `${de} → ${cible ?? ACCUEIL_INCONNU}`;
}

/** La description de la carte TCF : statique, sauf le niveau cible et le nombre d'épreuves. */
export function accueilTcfDescription(cible: TargetLevel | null | undefined): string {
    const vers = cible ? `au niveau ${cible}` : "à votre objectif";
    return `Compréhension orale, écrite et les deux expressions : votre plan vous mène ${vers} dans les ${ACCUEIL_TCF_NB_EPREUVES} épreuves.`;
}

/**
 * Combien d'épreuves sont **au niveau cible** : le statut servi
 * `TARGET_REACHED`, sur une épreuve **mesurée** (une épreuve sans palier ne
 * compte jamais), parmi les quatre officielles. On compte des états servis,
 * on n'en classe aucun.
 */
export function accueilEpreuvesAuNiveau(epreuves: readonly ProgressEpreuveDto[]): number {
    const officielles = new Set<string>(TCF_EPREUVES_OFFICIELLES);
    return epreuves.filter(
        (e) => officielles.has(e.epreuve) && e.niveau !== null && e.status === "TARGET_REACHED",
    ).length;
}

export const ACCUEIL_TCF_METRIC_PROGRESSION = "Progression";

/** « Épreuves au B2 ». */
export function accueilTcfMetricEpreuves(cible: TargetLevel | null | undefined): string {
    return cible ? `Épreuves au ${cible}` : "Épreuves à l'objectif";
}

/** « Cycle 2 » — `JourneyCycleDto.numero`, servi. */
export function accueilCycleLabel(cycle: JourneyCycleDto): string {
    return `Cycle ${cycle.numero}`;
}

export const ACCUEIL_TCF_METRIC_CYCLE = "En cours";

/**
 * La barre de la carte TCF (D4-B) : l'avancement du **cycle en cours**,
 * `etapesTerminees / etapesTotal`, servis. `null` sans cycle — pas de barre.
 */
export function accueilCycleRatio(cycle: JourneyCycleDto | null | undefined): number | null {
    if (!cycle || cycle.etapesTotal <= 0) return null;
    return cycle.etapesTerminees / cycle.etapesTotal;
}

export const ACCUEIL_CIVIQUE_OBJECTIF_TITRE = "Être prêt pour l'examen";

/** « Objectif : avoir 32/40 » — seuil et format de l'arrêté (miroir gelé). */
export const ACCUEIL_CIVIQUE_OBJECTIF_META =
    `Objectif : avoir ${CIVIQUE_EXAM_SEUIL}/${CIVIQUE_EXAM_QUESTIONS}`;

/** « 32/40 » — la métrique « Objectif examen ». */
export const ACCUEIL_CIVIQUE_SEUIL = `${CIVIQUE_EXAM_SEUIL}/${CIVIQUE_EXAM_QUESTIONS}`;

/**
 * La description de la carte civique : statique, sauf le nombre de thèmes,
 * lu sur la liste servie (`DashboardSummaryResponse.civique`). Inconnu ⇒ la
 * phrase ne compte pas.
 */
export function accueilCiviqueDescription(nbThemes: number | null): string {
    const themes = nbThemes && nbThemes > 0 ? `les ${nbThemes} thèmes officiels` : "les thèmes officiels";
    return `Révisez ${themes}, série par série, et validez votre préparation avec des examens blancs.`;
}

/** « 39 % » — le pourcentage d'`avancementSeriesCivique`, jamais vide (0 %). */
export function accueilPourcentage(pourcentage: number): string {
    return `${pourcentage} %`;
}

export const ACCUEIL_CIVIQUE_METRIC_PARCOURS = "Du parcours";
export const ACCUEIL_CIVIQUE_METRIC_SERIES = "Séries terminées";
export const ACCUEIL_CIVIQUE_METRIC_EXAMEN = "Objectif examen";

/** « {terminées}/{total} ». */
export function accueilSeries(terminees: number, total: number): string {
    return `${terminees}/${total}`;
}

/* ----------------------------------------- Carte de diagnostic en cours */

export const ACCUEIL_DIAGNOSTIC_LABEL = "Diagnostic en cours";
export const ACCUEIL_DIAGNOSTIC_TITLE_RESUME = "Reprenez votre diagnostic";
export const ACCUEIL_DIAGNOSTIC_TITLE_ANALYSIS = "Votre analyse est en préparation";
export const ACCUEIL_DIAGNOSTIC_RESUME_TEXT =
    "Continuez exactement à l'étape où vous vous êtes arrêté.";
export const ACCUEIL_DIAGNOSTIC_CTA_RESUME = "Reprendre mon diagnostic";
export const ACCUEIL_DIAGNOSTIC_CTA_ANALYSIS = "Voir l'analyse";

/* ------------------------------- Bandeau d'un compte sans démarche déclarée */

/** Miroirs de `kHomeParcoursBannerTitle` / `kHomeParcoursBannerText` (mobile). */
export const ACCUEIL_PARCOURS_BANNER_LABEL = "Démarche";
export const ACCUEIL_PARCOURS_BANNER_TITLE = "Choisissez votre parcours";
export const ACCUEIL_PARCOURS_BANNER_TEXT =
    "CSP, carte de résident ou naturalisation, pour personnaliser votre préparation.";
