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
 * celui des sujets d'expression (`subjectsDone` / `subjectsTotal`), la tâche
 * courante (`taches[]`), le **niveau actuel d'une épreuve**
 * (`tcfDomainProfile`, l'autorité d'affichage), l'état d'un thème, la cible en
 * cours. Aucune ne dérive un état pédagogique ni un niveau CECRL d'un
 * pourcentage.
 *
 * 🛑 **L'ordre des cas EST la règle**, et il se lit de haut en bas dans chaque
 * fonction : ce qui est **mesuré** passe devant ce qui est **compté**, et
 * « pas encore travaillé » n'est dit qu'en dernier — jamais comme un verdict.
 */

import type {
    CivicPlanThemeLigneDto,
    DashboardCategoryStat,
    LearningPlanDto,
    PlanDomainDto,
    PlanDomainTaskDto,
    TcfDomainProfileDto,
} from "./types";
import {niveauCecrlLabel} from "./types";
import {niveauActuelEpreuve} from "./progres";
import type {PlanDomainEpreuve} from "./plan-domain";

/* ------------------------------------------------------------------ En-tête */

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

/* --------------------------------------- Recommandé par votre plan ----- */

/**
 * **Le sur-titre de la carte de recommandation du Plan** (`PlanEpreuveReco`).
 *
 * 🛑 Il **nomme le Plan** (demande du propriétaire, 2026-09-20) : ce que la
 * carte annonce est **désigné par le Plan**, pas par un historique d'écran.
 * La carte de reprise en tête de l'écran Entraînement est **retirée**
 * (2026-10-03, « on a le plan juste à côté ») ; le libellé ne sert plus
 * qu'au Plan.
 */
export const REVISER_RESUME_LABEL = "Recommandé par votre plan";

/* ---------------------------------------------------- Une épreuve du TCF --- */

export const REVISER_NOT_STARTED = "Pas encore travaillé";

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

/**
 * « 2/10 séries » · « 3/40 sujets ». `null` quand il n'y a rien à compter.
 *
 * 🛑 **Sert aussi les 5 thèmes civiques** (demande du propriétaire,
 * 2026-09-26) : même carte, même « N/M séries », même anneau que CO/CE — le
 * décompte `seriesDone` / `seriesTotal` du thème, servi par `/api/me/dashboard`.
 *
 * Une épreuve d'expression compte ses **sujets servis** (`subjectsDone` /
 * `subjectsTotal`, ses 3 tâches confondues) — jamais un décompte refait ici.
 * Le pluriel suit le total : « 1/40 sujets ». Miroir mot pour mot du mobile
 * (`epreuveMeta`, `reviser_labels.dart`).
 */
export function epreuveMeta(stat: DashboardCategoryStat): string | null {
    if (isProductionCode(stat.code)) {
        const total = stat.subjectsTotal ?? 0;
        if (total <= 0) return null;
        return `${stat.subjectsDone ?? 0}/${total} sujets`;
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
 * **L'avancement du parcours civique, en séries** — la fonction UNIQUE du web
 * (X4-A, Navigation v2, brief §6). Miroir exact :
 * `avancementSeriesCivique` de `mobile_sejourfr/lib/screens/reviser/reviser_labels.dart`.
 *
 * `pourcentage = floor(Σ seriesDone / Σ seriesTotal × 100)`, sur les thèmes
 * servis par `GET /api/me/dashboard` (`DashboardSummaryResponse.civique`).
 *
 * - Une série **terminée** = au moins un passage fini, quel que soit le score
 *   (D5-A amendé) ; le total compte **toutes** les séries du thème,
 *   verrouillées comprises, toutes mentions confondues (X4 : les lots civiques
 *   ne sont pas filtrés par mention côté serveur). Les deux compteurs sont
 *   servis, rien n'est recompté ici.
 * - `floor` : jamais 100 % tant qu'il reste une série. Total nul ⇒ 0 %.
 *
 * 🛑 **Ce n'est pas une note ni un état** : c'est une couverture. Aucun écran ne la classe en niveau ni en ton.
 * Restreinte à un thème, passer `[stat]`.
 */
export interface AvancementSeriesCivique {
    pourcentage: number;
    terminees: number;
    total: number;
}

export function avancementSeriesCivique(
    themes: readonly DashboardCategoryStat[],
): AvancementSeriesCivique {
    let terminees = 0;
    let total = 0;
    for (const theme of themes) {
        terminees += theme.seriesDone < 0 ? 0 : theme.seriesDone;
        total += theme.seriesTotal < 0 ? 0 : theme.seriesTotal;
    }
    if (total <= 0) return {pourcentage: 0, terminees, total: 0};
    const faites = terminees > total ? total : terminees;
    return {pourcentage: Math.floor((faites * 100) / total), terminees: faites, total};
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
