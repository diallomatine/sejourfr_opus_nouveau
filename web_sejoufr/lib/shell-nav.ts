/**
 * **La navigation du shell connecté (Navigation v2) — quelle entrée est
 * active, et ce que dit le fil d'Ariane.** Autorité unique, pure.
 *
 * 🛑 **Les URL actuelles restent canoniques** (X5-A, 2026-10-03) : chaque
 * entrée de la barre latérale est une route existante, le module voyage dans
 * le CHEMIN (`/progression/tcf`, `/entrainement/tcf/**`) ou dans `?module=`
 * (`/plan`, `/entrainement`, `/examens-blancs`), lu par `moduleDeLUrl` — le
 * seul mécanisme de sélection de module du web.
 *
 * Correspondance (AUDIT §6.1) :
 * - `/dashboard` → Accueil ;
 * - `/plan/**` → Plan du module de `?module=` (TCF quand l'URL se tait : c'est
 *   le défaut d'affichage de `PlanModules` et de toutes les sous-adresses du
 *   Plan, qui n'écrivent `?module=` qu'en civique) ;
 * - `/entrainement` → Entraînement du module de `?module=` (civique quand
 *   l'URL se tait : c'est ce que la page affiche) ;
 * - `/entrainement/tcf/**` → Entraînement TCF ; `/entrainement/civique/**` et
 *   `/diagnostic-civique/**` → Entraînement civique ;
 * - `/examens-blancs` → Examens du module de `?module=` (TCF quand l'URL se
 *   tait) ; `/examens-blancs/tcf/**` → Examens TCF ;
 * - `/progression/tcf/**` · `/progression/civique/**` → Progression ;
 * - `/profil/**`, `/favoris`, `/aide`, `/parcours` → Profil ;
 * - tout le reste (`/sessions/**`, `/paiement/**`, `/diagnostic`, la fiche
 *   d'un gabarit `/examens-blancs/[slug]`) → aucune entrée.
 */
import {CIVIQUE_EXAM_QUESTIONS, CIVIQUE_EXAM_SEUIL} from "./civique-examen";
import {moduleDeLUrl, type ParcoursModule} from "./module-switch";
import {progressionTaux} from "./progression";
import {avancementSeriesCivique} from "./reviser";
import {TCF_EPREUVES_OFFICIELLES} from "./tcf-epreuves";
import {
    niveauCecrlShort,
    type DashboardCategoryStat,
    type NiveauCecrl,
    type TargetLevel,
} from "./types";

export type ShellItem =
    | "accueil"
    | "plan"
    | "entrainement"
    | "examens"
    | "progression"
    | "profil";

export interface ShellActive {
    /** Le module de l'entrée active ; `null` hors bloc de module. */
    module: ParcoursModule | null;
    /** L'entrée active ; `null` quand aucune ne correspond. */
    item: ShellItem | null;
}

type Params = {get(name: string): string | null} | null | undefined;

const NONE: ShellActive = {module: null, item: null};

function sous(pathname: string, prefix: string): boolean {
    return pathname === prefix || pathname.startsWith(`${prefix}/`);
}

export function shellActive(pathname: string | null, search: Params): ShellActive {
    if (!pathname) return NONE;
    const demande = moduleDeLUrl(search);

    if (sous(pathname, "/dashboard")) return {module: null, item: "accueil"};

    if (sous(pathname, "/plan")) return {module: demande ?? "TCF", item: "plan"};

    if (pathname === "/entrainement") {
        return {module: demande === "TCF" ? "TCF" : "CIVIQUE", item: "entrainement"};
    }
    if (sous(pathname, "/entrainement/tcf")) return {module: "TCF", item: "entrainement"};
    if (sous(pathname, "/entrainement/civique") || sous(pathname, "/diagnostic-civique")) {
        return {module: "CIVIQUE", item: "entrainement"};
    }

    if (pathname === "/examens-blancs") return {module: demande ?? "TCF", item: "examens"};
    if (sous(pathname, "/examens-blancs/tcf")) return {module: "TCF", item: "examens"};

    if (sous(pathname, "/progression/tcf")) return {module: "TCF", item: "progression"};
    if (sous(pathname, "/progression/civique")) return {module: "CIVIQUE", item: "progression"};

    if (
        sous(pathname, "/profil") ||
        sous(pathname, "/favoris") ||
        sous(pathname, "/aide") ||
        sous(pathname, "/parcours")
    ) {
        return {module: null, item: "profil"};
    }
    return NONE;
}

/* ------------------------------------------------------------- Libellés */

export const SHELL_BRAND_TAG = "TCF IRN · Examen civique";
export const SHELL_GROUP_OVERVIEW = "Vue d'ensemble";
export const SHELL_GROUP_ACCOUNT = "Compte";
export const SHELL_MODULE_TITLE: Record<ParcoursModule, string> = {
    TCF: "TCF IRN",
    CIVIQUE: "Examen civique",
};

/**
 * Le libellé d'une entrée — D1-A : « Plan / Entraînement / Examens »
 * partout, le TCF gardant « Mon plan » et « Examens blancs » (maquette).
 */
export function shellItemLabel(item: ShellItem, module: ParcoursModule | null): string {
    switch (item) {
        case "accueil":
            return "Accueil";
        case "plan":
            return module === "TCF" ? "Mon plan" : "Plan";
        case "entrainement":
            return "Entraînement";
        case "examens":
            return module === "TCF" ? "Examens blancs" : "Examens";
        case "progression":
            return "Progression";
        case "profil":
            return "Profil";
    }
}

/** L'adresse d'une entrée de module — les URL actuelles (X5-A). */
export function shellModuleHref(item: ShellItem, module: ParcoursModule): string {
    switch (item) {
        case "plan":
            return `/plan?module=${module}`;
        case "entrainement":
            return `/entrainement?module=${module}`;
        case "examens":
            return `/examens-blancs?module=${module}`;
        case "progression":
            return module === "TCF" ? "/progression/tcf" : "/progression/civique";
        default:
            return "/dashboard";
    }
}

export const SHELL_MODULE_ITEMS: readonly ShellItem[] = [
    "plan",
    "entrainement",
    "examens",
    "progression",
];

/* ------------------------------------------------------- Fil d'Ariane */

export interface ShellCrumb {
    /** La section (« TCF IRN », « Examen civique », « Compte », « Accueil »). */
    section: string | null;
    /** La page courante. */
    page: string;
    /** Le module qui colore la page ; `null` ⇒ encre. */
    module: ParcoursModule | null;
}

/** Les adresses RACINES d'une entrée : la page y prend le libellé du menu. */
function estRacine(pathname: string, item: ShellItem): boolean {
    switch (item) {
        case "accueil":
            return pathname === "/dashboard";
        case "plan":
            return pathname === "/plan";
        case "entrainement":
            return pathname === "/entrainement";
        case "examens":
            return pathname === "/examens-blancs";
        case "progression":
            return pathname === "/progression/tcf" || pathname === "/progression/civique";
        case "profil":
            return pathname === "/profil";
    }
}

/**
 * Le fil d'Ariane `SejourFR / {Section} / {Page}`.
 *
 * Sur l'adresse racine d'une entrée, la page porte le libellé du menu (« Mon
 * plan », « Vue d'ensemble » pour l'Accueil — maquette) ; sur un sous-écran,
 * le titre de la page (`titre`, posé par la page ou par `lib/app-bar.ts`).
 */
export function shellCrumb(pathname: string | null, search: Params, titre: string): ShellCrumb {
    const {module, item} = shellActive(pathname, search);
    if (!item || !pathname) return {section: null, page: titre, module: null};
    const racine = estRacine(pathname, item);
    if (item === "accueil") {
        return {section: "Accueil", page: racine ? SHELL_GROUP_OVERVIEW : titre, module: null};
    }
    if (item === "profil") {
        return {section: SHELL_GROUP_ACCOUNT, page: racine ? "Profil" : titre, module: null};
    }
    return {
        section: module ? SHELL_MODULE_TITLE[module] : null,
        page: racine ? shellItemLabel(item, module) : titre,
        module,
    };
}

/** Initiales d'un nom (« AM »), « ? » sans rien. */
export function shellInitials(firstName?: string | null, lastName?: string | null, email?: string | null): string {
    const a = firstName?.trim()?.[0] ?? "";
    const b = lastName?.trim()?.[0] ?? "";
    const initiales = `${a}${b}`.toUpperCase();
    if (initiales) return initiales;
    return email?.trim()?.[0]?.toUpperCase() ?? "?";
}

/* ------------------------------------------------------------- Tails */

/**
 * Les faits que la barre latérale met en forme — tous lus dans des caches
 * PARTAGÉS (aucune lecture propre à la navigation) : le résumé de l'Accueil
 * (`dashboardApi.summaryCached`), les deux progressions
 * (`progressionApi.tcf|civique`, data-cache) et `AuthenticatedUser`.
 * `undefined` = pas encore arrivé (aucun tail), `null` = servi vide.
 */
export interface ShellNavFacts {
    /** `AuthenticatedUser.targetLevel` — seule source du niveau cible (X13). */
    cible: TargetLevel | null | undefined;
    /** `DashboardSummaryResponse.estimatedTcfLevel`. */
    niveauActuel: NiveauCecrl | null | undefined;
    /** Palier du dernier examen blanc COMPLET (`examensComplets.dernier.niveau`). */
    dernierExamenComplet: NiveauCecrl | null | undefined;
    /** Les thèmes servis par le résumé (`DashboardSummaryResponse.civique`). */
    themesCivique: readonly DashboardCategoryStat[] | undefined;
    /** Taux du meilleur examen civique global (`global.meilleur.taux`). */
    meilleurTauxCivique: number | null | undefined;
}

export interface ShellNavTails {
    tcfSub: string;
    civiqueSub: string;
    tails: Record<ParcoursModule, Partial<Record<ShellItem, string>>>;
}

function pluriel(n: number, mot: string): string {
    return `${n} ${mot}${n > 1 ? "s" : ""}`;
}

/**
 * Sous-titres des blocs de module et tails des entrées. Une valeur absente ⇒
 * pas de tail : on n'invente rien (R3/R4).
 */
export function shellNavTails(f: ShellNavFacts): ShellNavTails {
    const nbEpreuves = TCF_EPREUVES_OFFICIELLES.length;
    const nbThemes = f.themesCivique?.length ?? 0;

    const tcf: Partial<Record<ShellItem, string>> = {
        entrainement: pluriel(nbEpreuves, "épreuve"),
    };
    if (f.cible && f.niveauActuel !== undefined) {
        tcf.plan = `${niveauCecrlShort(f.niveauActuel)} → ${f.cible}`;
    }
    if (f.dernierExamenComplet) tcf.examens = niveauCecrlShort(f.dernierExamenComplet);
    if (f.niveauActuel) tcf.progression = niveauCecrlShort(f.niveauActuel);

    const civique: Partial<Record<ShellItem, string>> = {};
    if (f.themesCivique) {
        const avancement = avancementSeriesCivique(f.themesCivique);
        civique.plan = `${avancement.pourcentage} %`;
        civique.progression = pluriel(avancement.terminees, "série");
    }
    if (nbThemes > 0) civique.entrainement = pluriel(nbThemes, "thème");
    const meilleur = progressionTaux(f.meilleurTauxCivique ?? null);
    if (meilleur) civique.examens = meilleur;

    const tcfSub = [f.cible ? `Objectif ${f.cible}` : null, pluriel(nbEpreuves, "épreuve")]
        .filter(Boolean)
        .join(" · ");
    const civiqueSub = [
        `Objectif ${CIVIQUE_EXAM_SEUIL}/${CIVIQUE_EXAM_QUESTIONS}`,
        nbThemes > 0 ? pluriel(nbThemes, "thème") : null,
    ]
        .filter(Boolean)
        .join(" · ");

    return {tcfSub, civiqueSub, tails: {TCF: tcf, CIVIQUE: civique}};
}
