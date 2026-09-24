/**
 * Les **mots** de l'écran Progrès (T28, `30_` §7) — **purs**, déclarés une fois
 * pour tout le web.
 *
 * 🛑 **Le serveur n'expose que des faits** : un palier, un sens d'évolution, un
 * compte de jours. Les phrases vivent ici, et sont des **miroirs mot pour mot**
 * de `mobile_sejourfr/lib/screens/progres/progres_labels.dart`.
 *
 * 🛑 **Deux règles de la spec que ce fichier fait respecter**, et qui sont plus
 * faciles à violer qu'à tenir :
 *
 * - **aucun pourcentage de progression vers un palier.** Un palier CECRL n'est
 *   pas une barre : « 68 % vers le B2 » n'a aucun sens mesurable et se lit
 *   pourtant comme une promesse ;
 * - **aucune gamification.** L'activité se dit en jours travaillés, sans record
 *   à battre et sans rien à perdre. Un compteur qu'on peut casser transforme
 *   une mesure en dette.
 */
import type {
    BarTone,
    ChartPoint,
    ChartRung,
    LadderStep,
    TrendTone,
} from "@/app/_components/sejour/SejourKit";
import {EPREUVE_PRESENTATION} from "./exam-durations";
import {PLAN_DOMAIN_SECTION, planDomainSlug} from "./plan-domain";
import {
    cecrlIndex,
    CIVIC_THEME_STATE_LABEL,
    niveauCecrlLabel,
    niveauCecrlShort,
    SOURCE_EVALUATION_LABEL,
} from "./types";
import type {
    CivicThemeState,
    EpreuveType,
    EvaluationQualifianteDto,
    NiveauCecrl,
    NiveauEvolution,
    ProgressActiviteDto,
    ProgressCiviqueDto,
    ProgressCompetencesDto,
    ProgressEpreuveDto,
    ProgressTcfDto,
    StatutObjectif,
    TcfDomainProfileDto,
} from "./types";
import type {CivicPlanThemeLigneDto} from "./types";

export const PROGRES_TITLE = "Ce qui a bougé";
export const PROGRES_LEAD =
    "Votre mouvement depuis votre diagnostic — pas un tableau de bord.";

/** Bloc 1 — le niveau. */
export const PROGRES_NIVEAU_TITLE = "Votre niveau";

/** Bloc 2 — par épreuve. */
export const PROGRES_EPREUVES_TITLE = "Par épreuve";

/** Bloc 3 — les compétences. */
export const PROGRES_COMPETENCES_TITLE = "Vos compétences";
export const PROGRES_COMPETENCES_LOCKED =
    "Le détail de vos compétences tenues fait partie de l'abonnement. "
    + "Vos compteurs, eux, restent les vôtres.";

/** Bloc 4 — l'activité. */
export const PROGRES_ACTIVITE_TITLE = "Votre activité";

/** Bloc 5 — l'historique. 🛑 Un LIEN, pas une seconde liste. */
export const PROGRES_HISTORIQUE_TITLE = "Vos rapports";
export const PROGRES_HISTORIQUE_TEXT =
    "Vos examens et vos productions restent consultables.";

export const PROGRES_CIVIQUE_TITLE = "Examen civique";

/**
 * Le détail par thème du civique.
 *
 * 🛑 Le libellé d'un état vient de `CIVIC_THEME_STATE_LABEL` et son ton de
 * `kitTone` (`lib/civic-diagnostic.ts`) : ce sont les **autorités déjà en
 * place** pour cet enum, employées aussi par le Plan et le rapport de
 * diagnostic. Une seconde table finirait par nommer autrement le même état.
 */
export const PROGRES_CIVIQUE_THEMES_TITLE = "Par thème";

/** État vide (`30_` §7). */
export const PROGRES_VIDE_TEXT =
    "Votre progression s'affichera après votre premier diagnostic.";

/**
 * L'écran a-t-il **vraiment** l'écran vide ?
 *
 * 🛑 **Ce n'est plus `!tcf.disponible && !civique.disponible`** (2026-09-16) :
 * depuis que les 4 épreuves sont servies indépendamment du diagnostic
 * 4 épreuves, un candidat dont la CO est mesurée par un examen de module a de
 * quoi remplir le bloc « Par épreuve ». Garder l'ancienne condition aurait
 * affiché « votre progression s'affichera après votre premier diagnostic »
 * juste au-dessus de sa progression.
 *
 * 🛑 **Rien n'est classé ici** : on lit trois faits servis — deux booléens et
 * la présence d'un palier.
 */
export function progresEcranVide(
    tcf: ProgressTcfDto,
    civique: ProgressCiviqueDto,
): boolean {
    return !tcf.disponible
        && !civique.disponible
        && tcf.epreuves.every((e) => e.niveau === null);
}

/**
 * Le niveau et son objectif. 🛑 **Aucun pourcentage** : on nomme deux paliers,
 * on ne trace pas une barre entre eux.
 *
 * `null` quand rien n'est mesuré — « — » se suffit, et « inconnu » ne se dit
 * jamais « &lt; A1 ».
 */
export function progresNiveauLabel(tcf: ProgressTcfDto): string | null {
    if (!tcf.niveauActuel) return null;
    const actuel = niveauCecrlLabel(tcf.niveauActuel);
    return tcf.objectif ? `${actuel} → objectif ${niveauCecrlLabel(tcf.objectif)}` : actuel;
}

/**
 * Le marqueur d'évolution d'une épreuve.
 *
 * 🛑 **`INCONNUE` ne rend rien** — surtout pas « = ». Une épreuve non comparable
 * n'a ni progressé ni tenu, et lui donner le signe de la stabilité déguiserait
 * une absence de mesure en bonne nouvelle.
 *
 * 🛑 **`BAISSE` se dit.** La masquer rendrait la mesure de progression
 * invendable : c'est précisément ce qu'une réévaluation promet de mesurer.
 */
export function progresEvolutionLabel(epreuve: ProgressEpreuveDto): string | null {
    const fleche = progresEvolutionFleche(epreuve.evolution);
    if (!fleche) return null;
    if (!epreuve.niveauInitial || epreuve.evolution === "STABLE") return fleche;
    return `${fleche} depuis ${niveauCecrlLabel(epreuve.niveauInitial)}`;
}

/**
 * Le **glyphe seul** du marqueur d'évolution — la flèche de la bande des
 * paliers, où la phrase entière ne tient pas.
 *
 * 🛑 **Une seule table de flèches** : `progresEvolutionLabel` en dérive. Deux
 * jeux de signes finiraient par ne plus dire la même chose du même fait servi,
 * sur deux blocs du même écran.
 *
 * 🛑 **`INCONNUE` ne rend rien** — surtout pas le signe de la stabilité.
 *
 * Miroir mobile : `progresEvolutionFleche`.
 */
export function progresEvolutionFleche(evolution: NiveauEvolution): string | null {
    if (evolution === "HAUSSE") return "↑";
    if (evolution === "BAISSE") return "↓";
    if (evolution === "STABLE") return "=";
    return null;
}

/**
 * Le ton de la flèche, pour le kit.
 *
 * 🛑 Il **lit** le sens servi, il ne le déduit d'aucune série de paliers.
 * Miroir mobile : `progresEvolutionTrendTone`.
 */
export function progresEvolutionTrendTone(evolution: NiveauEvolution): TrendTone {
    if (evolution === "HAUSSE") return "up";
    if (evolution === "BAISSE") return "down";
    return "flat";
}

/** Le ton du marqueur. `INCONNUE` et `STABLE` restent **neutres**. */
export function progresEvolutionTone(
    evolution: NiveauEvolution,
): "up" | "down" | "flat" {
    if (evolution === "HAUSSE") return "up";
    if (evolution === "BAISSE") return "down";
    return "flat";
}

/** « B2 » ou « Non évaluée ». 🛑 Jamais « A1 » pour une absence de mesure. */
export function progresEpreuveNiveau(epreuve: ProgressEpreuveDto): string {
    return epreuve.niveau ? niveauCecrlLabel(epreuve.niveau) : "Non évaluée";
}

/**
 * Libellés **gelés** du statut d'une épreuve face à l'objectif (spec V2 §2),
 * miroirs mot pour mot de `kProgresStatutLabel` côté mobile.
 *
 * 🛑 Le statut est **servi** : ce fichier ne fait que poser un mot dessus. Aucun
 * front ne compare deux paliers CECRL.
 */
const PROGRES_STATUT_LABEL: Record<StatutObjectif, string> = {
    TARGET_REACHED: "Objectif atteint",
    CLOSE_TO_TARGET: "Proche de l'objectif",
    TO_REINFORCE: "À renforcer",
};

/**
 * Le statut d'une épreuve, dit au candidat.
 *
 * 🛑 **Une épreuve jamais mesurée ne se dit PAS « à renforcer »** : le serveur
 * la range bien dans `TO_REINFORCE`, mais son `niveau` vaut `null` et c'est ce
 * qu'il faut lire — « À évaluer ». Fondre les deux cas dans le même mot
 * rejouerait l'incident V040/V041/V042, où une absence de mesure était devenue
 * un verdict.
 *
 * `null` quand aucune démarche n'est déclarée : sans objectif, rien à situer.
 */
export function progresStatutLabel(epreuve: ProgressEpreuveDto): string | null {
    if (!epreuve.status) return null;
    if (!epreuve.niveau) return NON_MESURE_LABEL;
    return PROGRES_STATUT_LABEL[epreuve.status];
}

/**
 * Le mot d'une chose **jamais mesurée** — épreuve sans palier, thème civique
 * `NON_EVALUE`.
 *
 * 🛑 **Un seul endroit** : il vit sur la pastille d'une carte d'accueil, sur le
 * statut d'une épreuve de Progrès et sur les thèmes civiques. Recopié, il
 * finirait par diverger d'une surface à l'autre — et c'est le mot qui empêche
 * une absence de mesure de se lire comme un verdict (V040/V041/V042). Miroir
 * mobile : `kNonMesureLabel`.
 */
export const NON_MESURE_LABEL = "À évaluer";

/** Le ton du statut. `null` (jamais mesuré, ou sans objectif) reste **neutre**. */
export function progresStatutTone(
    epreuve: ProgressEpreuveDto,
): "ok" | "warn" | "hot" | "muted" {
    if (!epreuve.status || !epreuve.niveau) return "muted";
    if (epreuve.status === "TARGET_REACHED") return "ok";
    if (epreuve.status === "CLOSE_TO_TARGET") return "warn";
    return "hot";
}

/* ---------------------------------------------------------------------------
 * L'AUTORITÉ D'AFFICHAGE du niveau d'une épreuve
 * ------------------------------------------------------------------------- */

/**
 * **Le niveau ACTUEL d'une épreuve, tel qu'il est AFFICHÉ partout.**
 *
 * 🛑 **L'autorité d'affichage, et elle seule** : `tcfDomainProfile` publie le
 * niveau de `TcfProfileService.levelProfileAccueil` — la **moyenne des ≤ 3
 * derniers examens qualifiants** —, exactement ce que disent l'Accueil, le
 * Profil, le Diagnostic et Réviser. Les écrans de suivi lisaient
 * `DashboardCategoryStat.level`, une **troisième** autorité (le dernier niveau
 * CECRL de n'importe quelle soumission, **entraînements compris**) : un
 * candidat dont la seule trace EO était un entraînement de trois minutes y
 * lisait un palier pendant que tous les autres écrans disaient « à évaluer ».
 * → `docs/decisions/diagnostic.md`, 2026-09-16.
 *
 * 🛑 **`null` = pas mesuré, jamais un plancher** : la ligne retombe alors sur
 * ce que son écran sait **compter**.
 *
 * Le code de catégorie **est** la valeur de `epreuve` pour les quatre
 * épreuves : aucune table de correspondance n'est écrite ici. `TCF_STRUCTURE`
 * et les thèmes civiques n'y figurent pas — ils rendent `null`, ce qui est
 * exact : aucun palier CECRL ne leur est servi.
 *
 * 🛑 **Miroir de `niveauActuelEpreuve` côté mobile**
 * (`screens/progres/progres_labels.dart`).
 */
export function niveauActuelEpreuve(
    profil: TcfDomainProfileDto | null,
    code: string,
): NiveauCecrl | null {
    return profil?.domaines.find((d) => d.epreuve === code)?.niveau ?? null;
}

/** 🛑 Miroir mobile : `kSuiviSansExamenLabel`. */
export const SUIVI_SANS_EXAMEN_LABEL = "Pas encore d'examen";

/**
 * La ligne de niveau d'une épreuve sur un écran de **suivi chiffré**
 * (`/statistiques`, écran Progrès) — jamais sur un écran de constat.
 *
 * 🛑 **Non mesurée ⇒ aucun palier inventé.** On ne dit pas « À évaluer » ici,
 * qui est le mot d'un constat (l'Accueil) : on dit ce qui **manque à
 * compter** — aucun examen qualifiant n'a encore été passé.
 */
export function suiviNiveauLabel(niveau: NiveauCecrl | null): string {
    return niveau
        ? `Niveau estimé ${niveauCecrlLabel(niveau)}`
        : SUIVI_SANS_EXAMEN_LABEL;
}

/* ---------------------------------------------------------------------------
 * « Où vous en êtes » — la carte compacte d'une épreuve sur l'ACCUEIL
 * ------------------------------------------------------------------------- */

/**
 * 🛑 **Une seule dérivation pour les deux écrans.** Progrès dit « où vous en
 * êtes face à l'objectif » ; l'Accueil dit la même chose **plus ce qu'il faut
 * faire**. Deux tables auraient fini par nommer différemment le même statut
 * servi, sur deux écrans que le candidat voit dans la même minute — c'est le
 * défaut le plus cher du dépôt.
 *
 * 🛑 **Rien n'est classé ici.** Les deux seuls faits lus sont **servis** :
 * `status` (dérivé par `StatutObjectifResolver`) et `evolution` (dérivé par
 * `TcfDiagnosticProgressionResolver`). Aucun nombre n'entre, aucun palier n'est
 * comparé à un autre.
 *
 * 🛑 **Miroir mot pour mot de `AccueilEpreuveEtat` côté mobile**
 * (`screens/progres/progres_labels.dart`).
 */
export type AccueilEpreuveEtat =
    /**
     * Jamais mesurée. 🛑 Elle ne se dit **jamais** « à renforcer » : le serveur
     * la range bien dans `TO_REINFORCE`, mais son niveau vaut `null` et c'est
     * ce qu'il faut lire (V040/V041/V042).
     */
    | "A_EVALUER"
    /**
     * Mesurée, et le palier a **monté** depuis la première mesure. 🛑 Ce cas
     * passe **avant** le statut : dire « à renforcer » à quelqu'un qui vient de
     * progresser lui cache la seule bonne nouvelle qu'il a.
     */
    | "EN_PROGRESSION"
    /** Au niveau visé, ou au-dessus. */
    | "SOLIDE"
    /** Un cran sous l'objectif. */
    | "PROCHE"
    /** Mesurée, et loin de l'objectif. */
    | "A_RENFORCER"
    /** Mesurée, mais aucune démarche déclarée : rien vers quoi situer. */
    | "SANS_OBJECTIF";

/** L'état d'une épreuve **sur l'Accueil**, dans l'ordre où il se décide. */
export function accueilEpreuveEtat(epreuve: ProgressEpreuveDto): AccueilEpreuveEtat {
    if (!epreuve.niveau) return "A_EVALUER";
    if (epreuve.evolution === "HAUSSE") return "EN_PROGRESSION";
    if (!epreuve.status) return "SANS_OBJECTIF";
    if (epreuve.status === "TARGET_REACHED") return "SOLIDE";
    if (epreuve.status === "CLOSE_TO_TARGET") return "PROCHE";
    return "A_RENFORCER";
}

/**
 * La phrase courte de la carte. `null` = rien à dire, pas « rien à faire ».
 *
 * 🛑 `PROCHE` et `A_RENFORCER` reprennent **les libellés gelés** de
 * `PROGRES_STATUT_LABEL` : même statut servi, même mot, d'un écran à l'autre.
 */
export function accueilEpreuveStatut(epreuve: ProgressEpreuveDto): string | null {
    switch (accueilEpreuveEtat(epreuve)) {
        case "A_EVALUER":
            return "Pas encore évaluée";
        case "EN_PROGRESSION":
            return "En progression";
        case "SOLIDE":
            return "Solide, à maintenir";
        case "PROCHE":
            return PROGRES_STATUT_LABEL.CLOSE_TO_TARGET;
        case "A_RENFORCER":
            return PROGRES_STATUT_LABEL.TO_REINFORCE;
        case "SANS_OBJECTIF":
            return null;
    }
}

/**
 * La pastille de niveau. « À évaluer » quand rien n'a été mesuré.
 *
 * 🛑 `niveauCecrlShort` et jamais un troncage maison : `A1_NON_ATTEINT` se rend
 * « &lt;A1 », pas « A1 ».
 */
export function accueilEpreuveBadge(epreuve: ProgressEpreuveDto): string {
    return epreuve.niveau ? niveauCecrlShort(epreuve.niveau) : NON_MESURE_LABEL;
}

/**
 * Ce que la carte propose de faire.
 *
 * 🛑 **Dérivé de l'état, jamais un texte fixe** : une épreuve jamais mesurée ne
 * propose pas de « voir » des résultats qui n'existent pas, et une épreuve qui
 * monte propose de continuer plutôt que de relire.
 */
export function accueilEpreuveCta(epreuve: ProgressEpreuveDto): string {
    const etat = accueilEpreuveEtat(epreuve);
    if (etat === "A_EVALUER") return "Évaluer mon niveau";
    if (etat === "EN_PROGRESSION") return "Continuer";
    return "Voir mes résultats";
}

/**
 * La carte mène-t-elle à un **exercice** plutôt qu'aux résultats ?
 *
 * 🛑 Le chemin d'un exercice est celui du Plan, jamais un second : c'est la
 * fiche du domaine qui porte les lanceurs.
 */
export function accueilEpreuveOuvreLExercice(epreuve: ProgressEpreuveDto): boolean {
    const etat = accueilEpreuveEtat(epreuve);
    return etat === "A_EVALUER" || etat === "EN_PROGRESSION";
}

/**
 * Le ton du statut — la pastille colorée devant l'état, sur la ligne d'épreuve.
 *
 * ⚠️ Il ne teinte plus de jauge depuis le 2026-09-16 : `accueilEpreuveJauge`
 * est **supprimée**, l'échelle CECRL ayant pris la place du rail. Une jauge à
 * cinq positions fixes disait la même chose que le mot juste à côté ; l'échelle,
 * elle, situe un palier servi.
 */
export function accueilEpreuveTon(epreuve: ProgressEpreuveDto): BarTone {
    switch (accueilEpreuveEtat(epreuve)) {
        case "A_EVALUER":
        case "SANS_OBJECTIF":
            return "muted";
        case "EN_PROGRESSION":
            return "now";
        case "SOLIDE":
            return "ok";
        case "PROCHE":
            return "warn";
        case "A_RENFORCER":
            return "hot";
    }
}

/* ---------------------------------------------------------------------------
 * L'ÉCHELLE CECRL d'une ligne d'épreuve (maquette du propriétaire, 2026-09-16)
 * ------------------------------------------------------------------------- */

/**
 * Les **quatre crans** de l'échelle : A1 · A2 · B1 · B2.
 *
 * 🛑 **L'échelle s'arrête à B2**, comme partout ailleurs dans le produit : le
 * profil TCF IRN ne délivre jamais au-delà, et l'échelle du bilan n'affiche
 * déjà que A1 → B2. ⚠️ La maquette du propriétaire en montrait **six**, C1 et
 * C2 compris, grisés et hors d'atteinte — il a **tranché pour la règle** le
 * 2026-09-16, en cours de passe : deux paliers que la notation ne rend jamais
 * n'ont rien à faire sur l'échelle d'un candidat.
 *
 * 🛑 **Ce n'est pas une seconde autorité** : la position d'un palier se lit par
 * `cecrlIndex` (`lib/types.ts`), la même que le rail des bilans — d'où le
 * rabattement de C1/C2 sur B2 pour relire un historique sans mentir.
 */
export const ACCUEIL_ECHELLE_CECRL: readonly NiveauCecrl[] = ["A1", "A2", "B1", "B2"];

/**
 * Les quatre crans d'une épreuve, **composés** pour le kit.
 *
 * 🛑 **Rien n'est classé ici** : on pose deux paliers **servis** — celui de
 * l'épreuve et l'objectif de la démarche — sur une échelle fixe, par
 * `cecrlIndex`. Aucun nombre n'entre, aucune note n'est convertie.
 *
 * 🛑 **`A1_NON_ATTEINT` n'allume AUCUN cran** (`cecrlIndex` rend -1) : le
 * candidat n'a atteint aucun des quatre paliers, et allumer A1 lui annoncerait
 * celui qu'il n'a justement pas. La pastille dit « &lt;A1 » et l'échelle reste
 * vide — on ne ment jamais vers le haut. ⚠️ Ce **n'est pas** le rendu d'une
 * épreuve non mesurée : la ligne garde son fond blanc, son repère plein et ses
 * crans pleins mais éteints, là où une épreuve à évaluer passe en contour.
 *
 * Miroir mobile : `accueilEchelons`.
 */
export function accueilEchelons(
    epreuve: ProgressEpreuveDto,
    objectif: NiveauCecrl | null,
): LadderStep[] {
    const atteint = epreuve.niveau ? cecrlIndex(epreuve.niveau) : -1;
    const vise = objectif ? cecrlIndex(objectif) : -1;
    return ACCUEIL_ECHELLE_CECRL.map((niveau, rang) => ({
        label: niveauCecrlShort(niveau),
        state: rang <= atteint ? "done" : rang === vise ? "target" : "empty",
        current: rang === atteint,
        goal: rang === vise,
    }));
}

/**
 * Ce que l'échelle dit à un lecteur d'écran — elle est rendue en `role="img"`,
 * ses libellés sont décoratifs.
 *
 * 🛑 **« &lt;A1 » se DIT**, il ne se lit pas : « Niveau inférieur à A1 ».
 */
export function accueilEchelleLabel(
    epreuve: ProgressEpreuveDto,
    objectif: NiveauCecrl | null,
): string {
    const niveau = epreuve.niveau;
    const debut = !niveau
        ? "Non évaluée"
        : niveau === "A1_NON_ATTEINT"
            ? "Niveau inférieur à A1"
            : `Niveau ${niveauCecrlShort(niveau)}`;
    return objectif ? `${debut}, objectif ${niveauCecrlShort(objectif)}` : debut;
}

/**
 * Le compteur du bandeau d'objectif — « 3 / 4 » et ses pastilles.
 *
 * 🛑 **On compte des mesures, on n'en classe aucune** : le seul fait lu est la
 * présence d'un `niveau` servi. Le total est la liste servie elle-même, jamais
 * un « 4 » écrit en dur — c'est le serveur qui décide combien d'épreuves il
 * publie, et c'est lui qui pose le nombre de pastilles.
 *
 * ⚠️ **Remplace `accueilEvalueesLabel`** (2026-09-16) : la maquette v2 rend le
 * compte, les pastilles et le mot séparément — une chaîne « 3 / 4 évaluées »
 * ne se découpe pas.
 *
 * Miroir mobile : `accueilEvaluees`.
 */
export function accueilEvaluees(
    epreuves: ProgressEpreuveDto[],
): {faites: number; total: number} | null {
    if (epreuves.length === 0) return null;
    return {
        faites: epreuves.filter((e) => e.niveau !== null).length,
        total: epreuves.length,
    };
}

/** Le mot sous le compteur du bandeau. Miroir mobile : `kAccueilEvalueesCaption`. */
export const ACCUEIL_EVALUEES_CAPTION = "évaluées";

/**
 * Le compteur du bandeau **civique** — les thèmes réellement mesurés.
 *
 * 🛑 **Même geste qu'en TCF, sur la seule donnée que le civique sert** : on
 * compte les thèmes dont l'`etat` n'est pas `NON_EVALUE`, et le total est la
 * liste servie. Aucun « 5 » n'est écrit ici, et rien n'est classé — `etat`
 * arrive du moteur civique.
 *
 * Miroir mobile : `accueilEvaluesCivique`.
 */
export function accueilEvaluesCivique(
    themes: CivicPlanThemeLigneDto[],
): {faites: number; total: number} | null {
    if (themes.length === 0) return null;
    return {
        faites: themes.filter((t) => t.etat !== "NON_EVALUE").length,
        total: themes.length,
    };
}

/**
 * Le mot sous le compteur civique — on compte des **thèmes**, au masculin.
 * Miroir mobile : `kAccueilEvaluesCaptionCivique`.
 */
export const ACCUEIL_EVALUES_CAPTION_CIVIQUE = "évalués";

/* ----------------------------------------- L'échelle d'un thème civique --- */

/**
 * **Les crans d'un thème civique** — les états **mesurés** de `CivicThemeState`,
 * du plus fragile au plus tenu.
 *
 * 🛑 **Ce n'est ni une échelle CECRL, ni un objectif, ni un palier** : le
 * civique n'en sert aucun (`docs/regles/progression.md`, arbitrage du
 * 2026-09-16). C'est l'**enum servi lui-même**, posé à plat : le nombre de
 * crans est le nombre d'états que le moteur civique peut rendre, moins
 * `NON_EVALUE` — qui n'est pas un cran mais une absence de mesure.
 *
 * 🛑 **Aucun nombre n'entre ici.** Le front ne classe pas un ratio en état : il
 * reçoit `etat` servi et lit son rang dans cette table.
 *
 * Miroir mobile : `kAccueilEchelleCivique`.
 */
export const ACCUEIL_ECHELLE_CIVIQUE: readonly CivicThemeState[] = [
    "FAIBLE",
    "A_RENFORCER",
    "SOLIDE",
];

/** Le rang d'un état **servi** sur cette échelle. `-1` = aucune mesure. */
function civicEtatRang(etat: CivicThemeState): number {
    return ACCUEIL_ECHELLE_CIVIQUE.indexOf(etat);
}

/**
 * Les crans d'un thème, **composés** pour le kit — le même `LevelLadder` que
 * les quatre épreuves du TCF.
 *
 * ⚠️ **Il remplace la jauge continue** (`ProgressMini`, supprimée le
 * 2026-09-19, demande du propriétaire) : « afficher le cran de la même manière
 * que le TCF ». Le codage visuel ne change pas de sens — les quatre positions
 * fixes de l'ancienne jauge (0 · 0,3 · 0,6 · 1) étaient déjà les quatre états
 * servis, ce sont maintenant des segments.
 *
 * 🛑 **Aucun cran d'objectif** : `goal` est toujours faux et aucun cran ne passe
 * en `target`. Le civique ne sert pas d'objectif, et en peindre un serait
 * inventer une cible que personne n'a posée.
 *
 * Miroir mobile : `accueilEchelonsCivique`.
 */
export function accueilEchelonsCivique(etat: CivicThemeState): LadderStep[] {
    const atteint = civicEtatRang(etat);
    return ACCUEIL_ECHELLE_CIVIQUE.map((valeur, rang) => ({
        label: CIVIC_THEME_STATE_LABEL[valeur],
        state: rang <= atteint ? "done" : "empty",
        current: rang === atteint,
        goal: false,
    }));
}

/**
 * Ce que l'échelle d'un thème dit à un lecteur d'écran — elle est rendue en
 * `role="img"`, ses libellés sont décoratifs.
 *
 * 🛑 **Le libellé servi, jamais une phrase de plus** : « Non évalué » se dit
 * tel quel, et surtout pas « faible ».
 *
 * Miroir mobile : `accueilEchelleLabelCivique`.
 */
export function accueilEchelleLabelCivique(etat: CivicThemeState): string {
    return CIVIC_THEME_STATE_LABEL[etat];
}

/**
 * « 4 compétences maîtrisées sur 11 travaillées ».
 *
 * `null` quand rien n'a jamais été observé : « 0 sur 0 » ne dit rien.
 */
export function progresCompetencesLabel(
    competences: ProgressCompetencesDto,
): string | null {
    if (competences.travaillees <= 0) return null;
    const m = competences.maitrisees;
    return `${m} compétence${m > 1 ? "s" : ""} maîtrisée${m > 1 ? "s" : ""} `
        + `sur ${competences.travaillees} travaillée${competences.travaillees > 1 ? "s" : ""}`;
}

/**
 * « 12 jours travaillés sur les 28 derniers ».
 *
 * 🛑 La fenêtre vient du **serveur** : aucun écran n'écrit « 30 » en dur, donc
 * aucun ne peut mentir sur ce qu'il compte.
 */
export function progresActiviteLabel(activite: ProgressActiviteDto): string {
    const j = activite.joursActifs;
    return `${j} jour${j > 1 ? "s" : ""} travaillé${j > 1 ? "s" : ""} `
        + `sur les ${activite.fenetreJours} derniers`;
}

/**
 * La régularité, dite sans jugement : combien de semaines portent au moins une
 * séance. 🛑 Ni objectif, ni série à tenir — c'est un constat.
 */
export function progresRegulariteLabel(activite: ProgressActiviteDto): string | null {
    const actives = activite.semaines.filter((s) => s.jours > 0).length;
    if (activite.semaines.length === 0) return null;
    if (actives === 0) return null;
    return `${actives} semaine${actives > 1 ? "s" : ""} sur ${activite.semaines.length} `
        + "avec au moins une séance";
}

/**
 * « 3 notions tenues sur 12 travaillées », ou « thèmes » tant que le tagging
 * n'a pas basculé.
 *
 * 🛑 L'écran **nomme** ce qu'il compte : le plan civique ne se dit jamais plus
 * précis qu'il ne l'est.
 */
export function progresCiviqueLabel(civique: ProgressCiviqueDto): string | null {
    if (civique.travaillees <= 0) return null;
    const nom = civique.grainNotion ? "notion" : "thème";
    const m = civique.maitrisees;
    return `${m} ${nom}${m > 1 ? "s" : ""} tenu${m > 1 ? "s" : ""} `
        + `sur ${civique.travaillees} travaillé${civique.travaillees > 1 ? "s" : ""}`;
}

/** Le dernier score civique, comparable au seuil. `null` s'il n'y en a aucun. */
export function progresCiviqueScore(civique: ProgressCiviqueDto): string | null {
    const dernier = civique.historique.at(-1);
    if (!dernier) return null;
    return `${dernier.bonnes} / ${dernier.posees} · seuil ${dernier.seuil} / ${dernier.format}`;
}

/** Où mènent les rapports (bloc 5). 🛑 L'existant, jamais une seconde liste. */
export const PROGRES_HISTORIQUE_HREF = "/historique";

/* ===========================================================================
 * L'ÉCRAN « VOTRE PROGRESSION » — la progression GLOBALE (`/statistiques`)
 * (template `docs/progression/ecran_progression_normal.html`, 2026-09-19)
 * =========================================================================== */

/**
 * 🛑 **À ne pas confondre avec `PROGRES_TITLE`** (« Ce qui a bougé », le bloc
 * de mouvement) ni avec « Ma progression » (`/plan/progression`, l'historique
 * des cycles). Celui-ci est le titre de l'écran lui-même.
 */
export const PROGRESSION_EYEBROW = "TCF IRN";
export const PROGRESSION_TITLE = "Votre progression";
export const PROGRESSION_LEAD = "Suivez votre niveau réel, examen après examen.";

/* ------------------------------------------------- le bandeau d'objectif -- */

export const PROGRESSION_HERO_LABEL = "Vers votre objectif";
export const PROGRESSION_HERO_META = "Niveau mesuré par vos examens";

/** Les quatre épreuves nommées par l'unique table du web. */
type ProgressionEpreuve = keyof typeof EPREUVE_PRESENTATION;

/**
 * L'épreuve, quand c'en est une des quatre du TCF. `null` sur le civique, la
 * structure de la langue ou un conteneur d'examen — on n'invente alors ni nom
 * ni repère. Miroir mobile : `planDomainSection`.
 */
export function progressionEpreuve(epreuve: EpreuveType): ProgressionEpreuve | null {
    return Object.hasOwn(EPREUVE_PRESENTATION, epreuve)
        ? (epreuve as ProgressionEpreuve)
        : null;
}

/**
 * Le nom d'une épreuve. 🛑 **Une seule table** : `EPREUVE_PRESENTATION`, celle
 * que le bloc de mouvement emploie déjà. Miroir mobile :
 * `EpreuveType.displayLabel`.
 */
export function progressionNom(epreuve: EpreuveType): string {
    const domaine = progressionEpreuve(epreuve);
    return domaine ? EPREUVE_PRESENTATION[domaine].label : epreuve;
}

/**
 * Le repère court d'une épreuve (« CO »). 🛑 `PLAN_DOMAIN_SECTION`, l'autorité
 * déjà en place — jamais un second découpage du code servi.
 */
export function progressionMark(epreuve: EpreuveType): string {
    const domaine = progressionEpreuve(epreuve);
    return domaine ? PLAN_DOMAIN_SECTION[domaine] : epreuve;
}

/** « Vos résultats » d'une épreuve — l'écran existant, jamais un nouveau. */
export function progressionResultatsHref(epreuve: EpreuveType): string | null {
    const domaine = progressionEpreuve(epreuve);
    return domaine ? `/historique/epreuve/${planDomainSlug(domaine)}` : null;
}

/**
 * « Objectif B1 ». `null` sans démarche déclarée.
 *
 * 🛑 `niveauCecrlShort` et jamais un troncage maison : `A1_NON_ATTEINT` se rend
 * « &lt;A1 ».
 */
export function progressionObjectifPill(objectif: NiveauCecrl | null): string | null {
    return objectif ? `Objectif ${niveauCecrlShort(objectif)}` : null;
}

/** Les deux nombres du compteur, tels que `accueilEvaluees` les sert. */
type Compte = {faites: number; total: number} | null;

/**
 * « 2 épreuves sur 4 ».
 *
 * 🛑 **De l'arithmétique d'AFFICHAGE, jamais une classification** : les deux
 * nombres sont servis (`accueilEvaluees` ne fait que compter la présence d'un
 * palier), et le total est la liste servie elle-même — aucun « 4 » n'est écrit
 * ici. `null` quand le serveur n'en publie aucune : on n'annonce alors aucun
 * chiffre. Miroir mobile : `progressionMesureesLabel`.
 */
export function progressionMesureesLabel(compte: Compte): string | null {
    if (!compte || compte.total <= 0) return null;
    const n = compte.faites;
    return `${n} épreuve${n > 1 ? "s" : ""} sur ${compte.total}`;
}

/**
 * La part parcourue du rail. `null` ⇒ pas de rail.
 *
 * 🛑 **Ce n'est PAS un pourcentage de progression vers un palier** — règle que
 * le dépôt interdit et qui tient toujours : c'est la part des épreuves
 * **mesurées**, la lecture du compteur que `progressionMesureesLabel` écrit
 * déjà en mots.
 */
export function progressionMesureesPart(compte: Compte): number | null {
    return !compte || compte.total <= 0 ? null : compte.faites / compte.total;
}

/** « 50 % ». `null` quand l'un des deux nombres n'est pas servi. */
export function progressionMesureesPourcent(compte: Compte): string | null {
    const part = progressionMesureesPart(compte);
    return part == null ? null : `${Math.round(part * 100)} %`;
}

/**
 * Le palier d'une épreuve sur la bande et sur sa ligne.
 *
 * 🛑 **« — » et jamais « A1 »** : `null` = inconnu, jamais mauvais.
 */
export function progressionPalier(epreuve: ProgressEpreuveDto): string {
    return epreuve.niveau ? niveauCecrlShort(epreuve.niveau) : "—";
}

/* ------------------------------------------------------ « Votre évolution » */

export const PROGRESSION_COURBE_TITLE = "Votre évolution";
export const PROGRESSION_COURBE_SUB = "Basée uniquement sur vos examens";
export const PROGRESSION_NIVEAU_ACTUEL_LABEL = "Niveau actuel";

/** Le lien du pied de la courbe, vers « Vos résultats » de l'épreuve. */
export const PROGRESSION_VOIR_LABEL = "Voir";

export const PROGRESSION_COURBE_VIDE_TITLE = "Aucune mesure pour l'instant";

/**
 * Le pied de la courbe quand rien n'a encore été mesuré. 🛑 Le titre est
 * `SUIVI_SANS_EXAMEN_LABEL`, le mot déjà en place pour « aucun examen
 * qualifiant » sur un écran de suivi : on n'en écrit pas un second.
 */
export const PROGRESSION_SANS_EXAMEN_TEXT =
    "Passez une épreuve complète pour mesurer votre niveau.";

/**
 * 🛑 **Elle nomme l'épreuve** : le template écrit « une épreuve complète
 * d'expression orale », donc la phrase suit l'onglet ouvert.
 */
export function progressionCourbeVideText(epreuve: EpreuveType): string {
    return `Une épreuve complète de ${progressionNom(epreuve).toLowerCase()} `
        + "fera apparaître votre évolution ici.";
}

/**
 * Le pied « Examen blanc · 15 sept. » — provenance **servie** et date servie.
 *
 * 🛑 `null` quand rien n'a été mesuré. Une date absente n'est pas inventée : la
 * provenance seule se suffit. Miroir mobile : `progressionDerniereMesure`.
 */
export function progressionDerniereMesure(
    derniere: EvaluationQualifianteDto | null,
): string | null {
    if (!derniere) return null;
    const jour = jourLong(derniere.mesureA);
    const source = SOURCE_EVALUATION_LABEL[derniere.source];
    return jour ? `${source} · ${jour}` : source;
}

/* --------------------------------------------------------- « Vos épreuves » */

export const PROGRESSION_EPREUVES_TITLE = "Vos épreuves";
export const PROGRESSION_EPREUVES_SUB = "Niveau + tendance récente";

/**
 * L'intitulé sous le palier d'une ligne : « actuel » quand il y a une mesure,
 * « niveau » quand il n'y en a pas — comme le template.
 */
export function progressionPalierCaption(epreuve: ProgressEpreuveDto): string {
    return epreuve.niveau ? "actuel" : "niveau";
}

/**
 * La suite des paliers d'une épreuve — « A2 → B1 → B1 ».
 *
 * 🛑 **Rien n'est interprété et rien n'est retrié** : les paliers arrivent
 * **servis** (`GET /api/me/progress/tcf/{epreuve}/historique`) et on les lit du
 * plus ancien au plus récent, le sens de lecture que la courbe emploie déjà.
 * Aucun palier n'est comparé à un autre : la tendance, elle, est servie
 * (`evolution`) et se lit ailleurs sur la même ligne.
 *
 * `null` quand l'historique est vide — l'appelant dit alors ce qui **manque à
 * compter** (`SUIVI_SANS_EXAMEN_LABEL`), jamais un palier inventé.
 *
 * Miroir mobile : `progressionSerieLabel`.
 */
export function progressionSerieLabel(
    servies: EvaluationQualifianteDto[],
): string | null {
    if (servies.length === 0) return null;
    return [...servies].reverse().map((e) => niveauCecrlShort(e.niveau)).join(" → ");
}

/* ===========================================================================
 * LA COURBE D'UNE ÉPREUVE — échelle, points et dates
 *
 * 🛑 **Extrait à sa 2ᵉ surface** (2026-09-19) : « Vos résultats »
 * (`EpreuveHistoriqueView`) et « Votre progression » (`/statistiques`)
 * dessinent la MÊME courbe à partir de la MÊME liste servie. Deux copies
 * auraient fini par ne plus situer un palier à la même hauteur.
 * =========================================================================== */

/**
 * L'échelle de paliers du profil TCF IRN, du plus bas au plus haut.
 *
 * 🛑 **Indexée par `cecrlIndex`**, l'autorité déjà en place : C1 et C2 y sont
 * rabattus sur B2, comme partout ailleurs dans le produit.
 */
const ECHELLE = ["<A1", "A1", "A2", "B1", "B2"] as const;

/** Sa position dans `ECHELLE` (0 = « <A1 »). */
function rang(niveau: NiveauCecrl | null): number {
    return cecrlIndex(niveau) + 1;
}

/**
 * L'échelle **affichée**, du haut vers le bas.
 *
 * 🛑 **Elle suit les données servies**, elle ne les rabat pas : une mesure en
 * dessous de A2 ouvre l'échelle vers le bas. La fenêtre minimale est A2 → B2,
 * celle de la maquette — trois lignes, l'amplitude utile du TCF IRN.
 */
export function echelleAffichee(rangs: number[]): string[] {
    const bas = Math.min(2, ...rangs);
    const haut = Math.max(4, ...rangs);
    const ladder: string[] = [];
    for (let i = haut; i >= bas; i -= 1) ladder.push(ECHELLE[i]);
    return ladder;
}

/** « 14 sept. 2026 ». `null` quand le serveur n'a pas de date. */
export function jourLong(iso: string | null): string | null {
    if (!iso) return null;
    return new Date(iso).toLocaleDateString("fr-FR", {
        day: "numeric", month: "short", year: "numeric",
    });
}

/** « 14 sept. » — l'abscisse de la courbe, où l'année ne tient pas. */
export function jourCourt(iso: string | null): string {
    if (!iso) return "—";
    return new Date(iso).toLocaleDateString("fr-FR", {day: "numeric", month: "short"});
}

/**
 * **La courbe d'une épreuve, prête pour le kit** : son échelle et ses points.
 *
 * 🛑 `servies` arrive dans l'**ordre servi** (la plus récente d'abord) et n'est
 * pas retriée : on la lit à l'envers parce qu'une courbe se lit du plus ancien
 * au plus récent. Aucune interpolation, aucune moyenne — un point par
 * évaluation servie.
 *
 * Miroir mobile : `progresCourbe`.
 */
export function progresCourbe(
    servies: EvaluationQualifianteDto[],
    objectif: NiveauCecrl | null,
): {rungs: ChartRung[]; points: ChartPoint[]} {
    const chronologie = [...servies].reverse();
    const rangs = chronologie.map((e) => rang(e.niveau));
    if (objectif) rangs.push(rang(objectif));
    const ladder = echelleAffichee(rangs);
    const haut = ECHELLE.indexOf(ladder[0] as (typeof ECHELLE)[number]);
    /* 🛑 **Les paliers CECRL sont RÉGULIÈREMENT espacés**, et c'est cette
       fonction — pas la brique — qui le dit : un cran par palier, à hauteur
       égale. La brique reçoit des hauteurs, elle n'en invente aucune, ce qui la
       rend réutilisable par une échelle de valeurs (`civiqueThemeCourbe`). */
    const crans = Math.max(ladder.length - 1, 1);
    const hauteur = (r: number) => (ladder.length > 1 ? (haut - r) / crans : 0.5);
    return {
        rungs: ladder.map((label, i) => ({
            label,
            at: ladder.length > 1 ? i / crans : 0.5,
        })),
        points: chronologie.map((e) => ({
            date: jourCourt(e.mesureA),
            level: niveauCecrlShort(e.niveau),
            at: hauteur(rang(e.niveau)),
        })),
    };
}

/* ===========================================================================
 * « VOS RÉSULTATS » D'UN THÈME CIVIQUE — l'écran ouvert depuis l'Accueil
 *
 * 🛑 **Aucun palier, aucun objectif CECRL** : le civique se mesure en thèmes et
 * en scores face à un seuil, jamais en paliers (`docs/regles/progression.md`).
 * Ce qui est servi, et rien de plus : l'`etat` du thème (`CivicThemeState`,
 * rendu par `CIVIC_THEME_STATE_LABEL`) et ses examens blancs, avec pour chacun
 * son score, son total de questions et son seuil de réussite.
 *
 * Miroirs mobile : les mêmes noms dans `progres_labels.dart`.
 * =========================================================================== */

export const THEME_RESULTATS_TITLE = "Vos résultats";

/** Le héros : le dernier score servi, face au seuil servi avec lui. */
export const THEME_RESULTATS_HERO_LABEL = "Dernier résultat";
export const THEME_RESULTATS_SEUIL_LABEL = "Seuil de réussite";

/**
 * Ce qui compte dans cet écran, dit au candidat plutôt que deviné par lui.
 *
 * 🛑 **Formulée pour rester vraie quand la liste est vide**, et pour ne rien
 * promettre que le serveur ne serve : les séries d'entraînement et le
 * diagnostic civique sont exclus par la requête elle-même
 * (`AttemptRepository.findByUserFiltered`).
 */
export const THEME_RESULTATS_LEAD =
    "Vos examens blancs sur ce thème, et votre score face au seuil de réussite. "
    + "Vos séries d'entraînement et votre diagnostic n'y figurent pas.";

/* ------------------------------------------------------------- la courbe -- */

export const THEME_RESULTATS_COURBE_TITLE = "Votre évolution";
export const THEME_RESULTATS_COURBE_SUB = "Touchez un point pour voir l'examen.";

/** La phrase qui remplace la courbe quand un seul examen a été passé. */
export const THEME_RESULTATS_COURBE_UN_POINT =
    "Un seul examen pour l'instant : la courbe se dessinera au prochain.";

/* --------------------------------------------------------- l'historique -- */

export const THEME_RESULTATS_LISTE_TITLE = "Historique";

/** « 3 examens blancs ». 🛑 On compte des lignes servies, rien d'autre. */
export function themeResultatsCountLabel(n: number): string {
    return `${n} examen${n > 1 ? "s" : ""} blanc${n > 1 ? "s" : ""}`;
}

/**
 * 🛑 **Une absence de mesure se DIT** — jamais un `0 / 20`, jamais un état
 * pédagogique inventé.
 */
export const THEME_RESULTATS_VIDE = "Pas encore d'examen sur ce thème.";
export const THEME_RESULTATS_VIDE_AIDE =
    "Votre premier examen blanc de ce thème apparaîtra ici dès qu'il sera terminé.";

export const THEME_RESULTATS_ERREUR =
    "Vos résultats n'ont pas pu être chargés. Réessayez dans un instant.";

/** « Examen blanc 3 » — le slot servi, rien de plus. */
export function themeResultatsExamenTitle(slot: number | null): string {
    return slot == null ? "Examen blanc" : `Examen blanc ${slot}`;
}

/** « 17 / 20 » — deux nombres servis, mis côte à côte. */
export function themeResultatsScore(score: number, total: number): string {
    return `${score} / ${total}`;
}

/** « Seuil de réussite : 16 / 20. » — le seuil SERVI avec cet examen-là. */
export function themeResultatsSeuilDetail(seuil: number, total: number): string {
    return `Seuil de réussite : ${seuil} / ${total}.`;
}

/**
 * Le score comparé au seuil, **deux nombres servis** — pas un état pédagogique
 * ni un palier. C'est l'information utile d'un examen civique, et la même
 * comparaison que `ExamReport` et la grille d'examens font déjà.
 *
 * `null` quand aucun seuil n'est servi (attempt antérieur au champ) : on ne
 * conclut rien sans la barre.
 */
export function themeResultatsVerdict(
    score: number,
    seuil: number | null,
): string | null {
    if (seuil == null) return null;
    return score >= seuil ? "Au-dessus du seuil." : "Sous le seuil de réussite.";
}

/**
 * Le repli d'une ligne dont le serveur ne sert **aucun** seuil (attempt
 * antérieur au champ). 🛑 On dit l'absence, on n'invente pas la barre.
 */
export const THEME_RESULTATS_SANS_SEUIL =
    "Cet examen ne porte pas de seuil de réussite.";

/** Ce que la liste compte, et ce qu'elle ne compte pas. */
export const THEME_RESULTATS_PORTEE_TITLE = "Ce qui compte ici :";
export const THEME_RESULTATS_PORTEE_TEXT =
    " vos examens blancs de ce thème et leur seuil de réussite. Un thème civique "
    + "n'a aucun niveau CECRL — c'est votre score face au seuil qui compte.";

/** Le lien de pied : c'est là qu'on PASSE un examen, pas qu'on le relit. */
export const THEME_RESULTATS_EXAMENS_LABEL = "Passer un examen blanc";

/* ------------------------------------------------------ l'échelle servie -- */

/** Un examen blanc de thème, réduit aux trois nombres dont la courbe a besoin. */
export type ThemeMesure = {
    /** ISO servi, ou `null` — `jourCourt` en fait « — ». */
    date: string | null;
    score: number;
    total: number;
    /** `null` quand le serveur n'a pas de seuil sur cet attempt. */
    seuil: number | null;
};

/**
 * **La courbe d'un thème civique, prête pour le kit** : son échelle et ses
 * points, sur la MÊME brique que le TCF (`LevelChart`).
 *
 * 🛑 **L'échelle est SERVIE, pas fabriquée** : le maximum est le
 * `totalQuestions` des examens servis, le seuil leur `passThreshold`. Les deux
 * nombres du format de thème (20 / 16) ne sont écrits nulle part ici — ils
 * viennent de `AttemptService`, avec chaque examen.
 *
 * 🛑 **Les crans portent leur hauteur RÉELLE** : `16` se pose à 20 % du haut
 * d'un cadre `0 → 20`, pas au milieu. C'est exactement pourquoi `ChartRung`
 * prend un `at` plutôt qu'un rang.
 *
 * 🛑 **Le seuil n'est dessiné que s'il est le MÊME sur tous les examens
 * servis** : deux seuils différents sur une même courbe ne se lisent pas, et en
 * choisir un serait une invention.
 *
 * 🛑 `mesures` arrive dans l'**ordre servi** (la plus récente d'abord, `ORDER BY
 * a.startedAt DESC`) et n'est pas retriée : on la lit à l'envers parce qu'une
 * courbe se lit du plus ancien au plus récent. Aucune interpolation, aucune
 * moyenne — un point par examen servi, donc **un seul examen ⇒ un seul point**.
 *
 * Miroir mobile : `civiqueThemeCourbe`.
 */
export function civiqueThemeCourbe(
    mesures: ThemeMesure[],
): {rungs: ChartRung[]; points: ChartPoint[]} {
    if (mesures.length === 0) return {rungs: [], points: []};
    const chronologie = [...mesures].reverse();
    const max = Math.max(...chronologie.map((m) => m.total));
    if (max <= 0) return {rungs: [], points: []};
    const seuils = [...new Set(
        chronologie.map((m) => m.seuil).filter((s): s is number => s != null),
    )];
    const seuil = seuils.length === 1 && seuils[0] > 0 && seuils[0] < max
        ? seuils[0]
        : null;
    return {
        rungs: [
            {label: String(max), at: 0},
            ...(seuil == null
                ? []
                : [{label: String(seuil), at: (max - seuil) / max, seuil: true}]),
            {label: "0", at: 1},
        ],
        points: chronologie.map((m) => ({
            date: jourCourt(m.date),
            level: themeResultatsScore(m.score, m.total),
            at: Math.min(Math.max((max - m.score) / max, 0), 1),
        })),
    };
}
