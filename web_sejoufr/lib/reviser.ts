/**
 * **Les phrases de l'écran Réviser** — TCF et civique, web et mobile.
 *
 * 🛑 **Miroir mot pour mot de `mobile_sejourfr/lib/screens/reviser/reviser_labels.dart`.**
 * Un libellé qui bouge, ce sont deux fichiers dans la même passe.
 *
 * ⚠️ **Une seule exception, et elle est documentée à sa déclaration** :
 * `reviserTitle` n'existe que sur le web, parce que les deux fronts n'entrent
 * pas dans cet écran par le même chemin.
 *
 * 🛑 **Rien n'est classé ici.** Chaque fonction ne fait que poser une phrase sur
 * des **faits servis** — le compteur de séries (`seriesDone` / `seriesTotal`),
 * la couverture d'une tâche (`taches[]`), le **niveau actuel d'une épreuve**
 * (`tcfDomainProfile`, l'autorité d'affichage), l'état d'un thème, la cible en
 * cours. Aucune ne dérive un état pédagogique ni un niveau CECRL d'un
 * pourcentage.
 *
 * 🛑 **L'ordre des cas EST la règle**, et il se lit de haut en bas dans chaque
 * fonction : ce qui est **mesuré** passe devant ce qui est **compté**, et
 * « pas encore travaillé » n'est dit qu'en dernier — jamais comme un verdict.
 */

import type {
    JourneyDto,
    CivicPlanGrain,
    CivicPlanThemeLigneDto,
    DashboardCategoryStat,
    LearningPlanDto,
    PlanDomainDto,
    PlanDomainTaskDto,
    SkillSection,
    TcfDomainProfileDto,
} from "./types";
import {niveauCecrlLabel} from "./types";
import {niveauActuelEpreuve} from "./progres";
import {planNowCard, type PlanDomainEpreuve, type PlanNowVue} from "./plan-domain";
import {CIVIQUE_LABEL, TCF_LABEL} from "./preparation";

/* ------------------------------------------------------------------ En-tête */

export const REVISER_TITLE = "Réviser";

/**
 * **Le titre de l'écran, côté WEB : le parcours lui-même.**
 *
 * 🛑 **Divergence VOULUE avec le mobile** (demande du propriétaire,
 * 2026-09-13), et c'est la même raison qui fait qu'il n'y a pas de bascule de
 * parcours ici : sur le web on arrive par **une entrée de la barre latérale**,
 * « TCF IRN » ou « Examen civique », donc le choix est déjà fait — un titre
 * « Réviser » ne disait plus dans lequel des deux on venait d'entrer, alors que
 * les deux écrans se ressemblent. Sur le mobile, Réviser est un **onglet de la
 * barre du bas** qui porte sa propre bascule : le titre y nomme l'onglet, et
 * `kReviserTitle` ne bouge pas.
 *
 * 🛑 **Les deux noms viennent de `lib/preparation.ts`**, la seule table de noms
 * de parcours du web — celle que lit déjà « Ma préparation ». Ne pas en écrire
 * une troisième copie : la barre latérale en tient déjà une en dur.
 */
export function reviserTitle(module: "TCF" | "CIVIQUE"): string {
    return module === "TCF" ? TCF_LABEL : CIVIQUE_LABEL;
}

export const REVISER_SUBTITLE_TCF =
    "Le test linguistique exigé pour la résidence et la naturalisation.";

export const REVISER_SUBTITLE_CIVIQUE =
    "Les thèmes officiels de l'Examen civique, travaillés notion par notion.";

export function reviserSubtitle(module: "TCF" | "CIVIQUE"): string {
    return module === "TCF" ? REVISER_SUBTITLE_TCF : REVISER_SUBTITLE_CIVIQUE;
}

/** « Les 4 épreuves » / « Les 5 thèmes » — le compte est **celui de la liste**. */
export function reviserSectionTitle(module: "TCF" | "CIVIQUE", count: number): string {
    return module === "TCF" ? `Les ${count} épreuves` : `Les ${count} thèmes`;
}

/* ------------------------------------- Structure de la langue, hors examen */

/**
 * 🛑 **Le TCF IRN comporte QUATRE épreuves.** La liste et les phrases du module
 * complémentaire vivent dans `lib/tcf-epreuves.ts` — elles servent aussi les
 * trois écrans `/entrainement/tcf/[code]`, donc elles ne sont pas propres à
 * Réviser.
 */
export {
    TCF_CODE_COMPLEMENTAIRE,
    TCF_COMPLEMENTAIRE_NOTE_REVISER as REVISER_RENFORCER_NOTE,
    TCF_COMPLEMENTAIRE_NOTE_TITLE as REVISER_RENFORCER_NOTE_TITLE,
    TCF_COMPLEMENTAIRE_SECTION_TITLE as REVISER_RENFORCER_TITLE,
    TCF_EPREUVES_OFFICIELLES,
} from "./tcf-epreuves";

/* ------------------------------- Reprendre là où vous vous êtes arrêté ----- */

export const REVISER_RESUME_LABEL = "Reprendre là où vous vous êtes arrêté";
export const REVISER_RESUME_CTA = "Continuer";

/**
 * **Le sur-titre de la carte de tête quand il n'y a RIEN à reprendre** — parce
 * que le diagnostic n'a pas encore été fait.
 *
 * 🛑 **La carte ne disparaît plus** (demande du propriétaire, 2026-09-13) :
 * « si le diagnostic n'est pas fait, dans la section Reprendre où vous vous êtes
 * arrêté, plutôt proposer de faire le diagnostic ». L'écran ouvrait sur sa liste
 * d'épreuves sans jamais nommer le geste qui débloque tout le reste.
 *
 * 🛑 **Aucune phrase de porte n'est écrite ici** : le titre, le texte, le
 * libellé du bouton et sa destination viennent de `planIndisponible`
 * (`lib/preparation.ts`), la **même autorité** que l'Accueil et que l'écran
 * Plan. C'est ce qui garantit que les trois écrans proposent le même geste —
 * « Faire mon diagnostic » côté TCF, « Faire mon diagnostic civique » côté
 * civique — et qu'un diagnostic **commencé** s'y reprend au lieu de se refaire.
 */
export const REVISER_DEPART_LABEL = "Votre point de départ";

/**
 * Ce que le Plan demande de faire **maintenant**, mis en mots.
 *
 * 🛑 **La source est le Plan, jamais un historique d'écran** — et c'est
 * `planNowCard` qui la décide, la **même autorité** que la carte « À faire
 * maintenant » du Plan (`ActionMaintenant`) et de l'Accueil
 * (`ActionPlanDuJour`), des deux côtés. Réviser lisait `seance.items[0]` puis
 * retombait sur `currentPriority` : une **mesure de domaine** qui n'ouvrait pas
 * la séance lui échappait, et l'écran annonçait la priorité pédagogique pendant
 * que le Plan, au même instant, demandait de compléter une mesure.
 *
 * `null` quand il n'y a rien à reprendre : pas de plan, aucune priorité servie,
 * rien à lancer, ou action **verrouillée** — un compte sans accès ne se voit pas
 * proposer de reprendre ce qu'il ne peut pas faire, il entre par la liste des
 * épreuves (arbitrage du propriétaire, 2026-09-12 : « on passe par Réviser pour
 * voir ce qu'on peut utiliser gratuitement »).
 */
export function reviserResumeTcf(
    plan: LearningPlanDto | null,
    journey: JourneyDto | null = null,
): ReviserResume | null {
    if (!plan) return null;
    /* 🛑 **Le parcours est passé jusqu'ici** : sans lui, Réviser retomberait sur
       la règle du Plan pendant que le Plan suivrait le parcours — la même
       contradiction, à un troisième écran. */
    const carte = planNowCard(plan, {journey});
    if (!carte || carte.locked) return null;
    // Rien à lancer — ni mesure, ni exercice : on ne propose pas un bouton mort.
    if (!carte.mesure && !carte.exercise) return null;
    return {
        title: carte.title,
        subtitle: carte.subtitle,
        section: carte.section,
        carte,
    };
}

export interface ReviserResume {
    title: string;
    subtitle: string | null;
    /** La section travaillée — c'est elle qui donne le pictogramme. Celle du
     *  domaine **réellement lancé**, mesure comprise. */
    section: SkillSection | null;
    /** **Ce que le bouton lance**, tel que le Plan l'a désigné. */
    carte: PlanNowVue;
}

/** « Le Parlement » et « Institutions · notion à travailler ». */
export function reviserResumeCivique(
    prochaine: {label: string; themeLabel: string; grain: CivicPlanGrain} | null,
): {title: string; subtitle: string} | null {
    if (!prochaine) return null;
    const grain = prochaine.grain === "NOTION" ? "notion" : "thème";
    return {
        title: prochaine.label,
        subtitle: `${prochaine.themeLabel} · ${grain} à travailler`,
    };
}

/* ---------------------------------------------------- Une épreuve du TCF --- */

export const REVISER_NOT_STARTED = "Pas encore travaillé";

/**
 * L'épreuve d'une section de compétences. `null` hors des quatre domaines du
 * Plan — c'est la même table que `PLAN_DOMAIN_SECTION`, lue à l'envers.
 */
export function sectionEpreuve(section: SkillSection | null | undefined): PlanDomainEpreuve | null {
    switch (section) {
        case "CO":
            return "TCF_CO";
        case "CE":
            return "TCF_CE";
        case "EE":
            return "TCF_EE";
        case "EO":
            return "TCF_EO";
        default:
            return null;
    }
}

/** Le domaine servi pour ce code de catégorie, ou `null` (Structure, civique). */
export function domainForCode(
    plan: LearningPlanDto | null,
    code: string,
): PlanDomainDto | null {
    switch (code) {
        case "TCF_CO":
        case "TCF_CE":
        case "TCF_EE":
        case "TCF_EO":
            return domainOf(plan, code);
        default:
            return null;
    }
}

function domainOf(plan: LearningPlanDto | null, epreuve: PlanDomainEpreuve): PlanDomainDto | null {
    return plan?.domaines?.find((d) => d.epreuve === epreuve) ?? null;
}

export function isProductionCode(code: string): boolean {
    return code === "TCF_EE" || code === "TCF_EO";
}

/**
 * La tâche **servie** comme courante sur ce domaine. `null` en compréhension,
 * et `null` quand le serveur ne la nomme pas — on n'en choisit jamais une.
 */
export function currentTache(domain: PlanDomainDto | null): PlanDomainTaskDto | null {
    if (!domain?.tacheCourante) return null;
    return domain.taches.find((t) => t.tacheNumero === domain.tacheCourante) ?? null;
}

/** « 2/10 séries » · « 3/8 compétences ». `null` quand il n'y a rien à compter. */
export function epreuveMeta(stat: DashboardCategoryStat, domain: PlanDomainDto | null): string | null {
    if (isProductionCode(stat.code)) {
        const tache = currentTache(domain);
        if (!tache || tache.totalSkills <= 0) return null;
        return `${tache.observedSkills}/${tache.totalSkills} compétences`;
    }
    if (stat.seriesTotal <= 0) return null;
    return `${stat.seriesDone}/${stat.seriesTotal} séries`;
}

/**
 * La ligne d'état d'une épreuve.
 *
 * Ordre des cas, et c'est la règle : une **production** annonce l'étape que le
 * Plan construit, sinon ce qui est acquis, sinon son niveau ; une épreuve de
 * **compréhension** annonce son niveau mesuré, sinon ses séries faites.
 *
 * 🛑 **Le niveau vient de `niveauActuelEpreuve`, l'autorité d'AFFICHAGE** — jamais de
 * `PlanDomainDto.niveau` (la lecture du Plan, qui voit les entraînements) ni de
 * `DashboardCategoryStat.level` (une troisième autorité, encore plus large).
 * `domain` ne sert plus qu'à ce que Réviser **compte** : la tâche courante et
 * les compétences acquises.
 */
export function epreuveStatus(
    stat: DashboardCategoryStat,
    domain: PlanDomainDto | null,
    profil: TcfDomainProfileDto | null,
): string {
    const niveau = niveauActuelEpreuve(profil, stat.code);
    if (isProductionCode(stat.code)) {
        const tache = currentTache(domain);
        if (tache && tache.observedSkills < tache.totalSkills) {
            return `Prochaine étape : Tâche ${tache.tacheNumero}`;
        }
        const acquises = domain?.solidSkillCount ?? 0;
        if (acquises > 0) {
            return `${acquises} compétence${acquises > 1 ? "s" : ""} acquise${acquises > 1 ? "s" : ""}`;
        }
        if (niveau) return `Niveau estimé : ${niveauCecrlLabel(niveau)}`;
        return REVISER_NOT_STARTED;
    }
    if (niveau) {
        return `Niveau estimé : ${niveauCecrlLabel(niveau)}`;
    }
    if (stat.seriesDone > 0) {
        return `${stat.seriesDone} série${stat.seriesDone > 1 ? "s" : ""} terminée${stat.seriesDone > 1 ? "s" : ""}`;
    }
    return REVISER_NOT_STARTED;
}

/**
 * La part remplie de l'anneau, entre 0 et 1.
 *
 * 🛑 **Ce n'est pas une note.** C'est une couverture — des séries parcourues,
 * des compétences observées —, et un anneau vide veut dire « pas encore
 * commencé », jamais « mauvais ».
 */
export function epreuveRatio(stat: DashboardCategoryStat, domain: PlanDomainDto | null): number {
    if (isProductionCode(stat.code)) {
        const tache = currentTache(domain);
        if (!tache || tache.totalSkills <= 0) return 0;
        return clamp01(tache.observedSkills / tache.totalSkills);
    }
    if (stat.seriesTotal <= 0) return 0;
    return clamp01(stat.seriesDone / stat.seriesTotal);
}

function clamp01(value: number): number {
    if (!Number.isFinite(value)) return 0;
    return Math.max(0, Math.min(1, value));
}

/* -------------------------------------------------- Un thème du civique --- */

/**
 * La ligne d'état d'un thème civique.
 *
 * 🛑 **Tout est lu sur la ligne servie** (`CivicPlanDto.themes`), jamais compté
 * dans `priorites` / `aRevoir` / `solides`, qui sont plafonnées à l'affichage.
 * Sans ligne servie — aucun diagnostic terminé — il n'y a rien à dire d'autre
 * que « pas encore travaillé ».
 */
export function themeStatus(
    ligne: CivicPlanThemeLigneDto | null,
    stat: DashboardCategoryStat,
): string {
    if (ligne?.enCours) return `En cours · ${ligne.enCours.label}`;
    if (ligne && ligne.maitrisees > 0) {
        const nom = ligne.grain === "NOTION" ? "notion" : "thème";
        const s = ligne.maitrisees > 1 ? "s" : "";
        return `${ligne.maitrisees} ${nom}${s} maîtrisée${s}`;
    }
    if ((ligne?.travaillees ?? 0) > 0 || stat.seriesDone > 0) return "À travailler";
    return REVISER_NOT_STARTED;
}

/** La ligne servie pour ce thème, cherchée par son id. */
export function themeLigneFor(
    themes: CivicPlanThemeLigneDto[] | null | undefined,
    themeId: string | null,
): CivicPlanThemeLigneDto | null {
    if (!themes || !themeId) return null;
    return themes.find((t) => t.themeId === themeId) ?? null;
}
