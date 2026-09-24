/**
 * Les **mots** de l'Accueil (« Où vous en êtes ») — **purs**, déclarés une fois
 * pour tout le web.
 *
 * ⚠️ **Élagué le 2026-09-24** : l'écran « Votre progression » (`/statistiques`),
 * « Vos résultats » d'une épreuve et d'un thème, et le bloc « Ce qui a bougé »
 * sont supprimés au profit des écrans de progression (`lib/progression.ts`).
 * Ce qui reste ici, l'Accueil, Réviser et le Plan le lisent encore.
 *
 * 🛑 **Le serveur n'expose que des faits** : un palier, un sens d'évolution, un
 * état. Les phrases vivent ici, **miroirs mot pour mot** de
 * `mobile_sejourfr/lib/screens/progres/progres_labels.dart`.
 *
 * 🛑 **Aucun pourcentage de progression vers un palier** : un palier CECRL
 * n'est pas une barre.
 */
import type {BarTone, LadderStep} from "@/app/_components/sejour/SejourKit";
import {
    cecrlIndex,
    CIVIC_THEME_STATE_LABEL,
    niveauCecrlShort,
} from "./types";
import type {
    CivicPlanThemeLigneDto,
    CivicThemeState,
    NiveauCecrl,
    ProgressCiviqueDto,
    ProgressEpreuveDto,
    StatutObjectif,
    TcfDomainProfileDto,
} from "./types";

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

/* ---------------------------------------------------------------------------
 * « Où vous en êtes » — la carte compacte d'une épreuve sur l'ACCUEIL
 * ------------------------------------------------------------------------- */

/**
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

/** Le dernier score civique, comparable au seuil. `null` s'il n'y en a aucun. */
export function progresCiviqueScore(civique: ProgressCiviqueDto): string | null {
    const dernier = civique.historique.at(-1);
    if (!dernier) return null;
    return `${dernier.bonnes} / ${dernier.posees} · seuil ${dernier.seuil} / ${dernier.format}`;
}

/** « 14 sept. » — une date courte, sans l'année. */
export function jourCourt(iso: string | null): string {
    if (!iso) return "—";
    return new Date(iso).toLocaleDateString("fr-FR", {day: "numeric", month: "short"});
}
