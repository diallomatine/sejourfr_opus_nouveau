import type {
    JourneyObjectifRefDto,
    JourneySerieDto,
    JourneyStepDetailDto,
    SkillSection,
} from "./types";
import type {BarTone} from "../app/_components/sejour/SejourKit";

/**
 * **Les phrases de l'écran d'une étape de séries** — le détail qui s'ouvre
 * quand on touche une étape d'entraînement de compréhension (CO/CE) ou une
 * étape civique dans le cycle du Plan.
 *
 * 🛑 **Miroir mot pour mot de
 * `mobile_sejourfr/lib/screens/plan/journey_etape_labels.dart`.** Un libellé qui
 * bouge, ce sont deux fichiers dans la même passe.
 *
 * 🛑 **Aucune de ces phrases n'est servie**, et aucune ne classe un nombre.
 * L'état d'une série se lit sur les deux faits **servis** `locked` et
 * `validee` ; `dernierScore` ne sert qu'à être **affiché**, jamais comparé à
 * `seuilReussite`. Un front qui comparerait un nombre à un seuil deviendrait
 * une seconde autorité sur « cette série est-elle réussie ? ».
 */

/* --------------------------------------------------------------- En-tête */

/**
 * Le sous-titre de l'en-tête : « Plan B2 », « Plan — Naturalisation ».
 *
 * 🛑 **Le libellé est SERVI** (`objectif.label`), jamais composé d'un `code` ni
 * d'une table de mentions recopiée ici. Seule la **tournure** se choisit sur
 * `kind` — un palier se colle au mot « Plan », une démarche se détache —
 * exactement comme `journeyTitle`, et **jamais** sur le module.
 *
 * `null` quand aucun objectif n'est déclaré : on n'écrit pas « Plan » tout seul.
 */
export function journeyEtapeObjectif(
    objectif: JourneyObjectifRefDto | null,
): string | null {
    if (!objectif) return null;
    return objectif.kind === "NIVEAU"
        ? `Plan ${objectif.label}`
        : `Plan — ${objectif.label}`;
}

/**
 * La pastille de gauche : « CO · B2 ».
 *
 * 🛑 **Elle ne dit que ce qui est servi** — le domaine, et le **libellé** de
 * l'objectif. Sans section (une étape civique n'en a pas) il n'y a pas de
 * domaine à nommer, donc pas de pastille ; sans objectif la pastille se réduit
 * au domaine. On ne comble ni l'un ni l'autre.
 */
export function journeyEtapeSectionPill(
    section: SkillSection | null,
    objectif: JourneyObjectifRefDto | null,
): string | null {
    if (!section) return null;
    return objectif ? `${section} · ${objectif.label}` : section;
}

/** La pastille de droite, quand l'étape est prioritaire. **`priorite` est servi.** */
export const JOURNEY_ETAPE_PRIORITE = "Priorité";

/* ----------------------------------------------------------- Progression */

/**
 * Le compteur en gros : « 0/2 séries ».
 *
 * 🛑 **`validees` et `quota` sont SERVIS**, tous les deux : l'écran ne recompte
 * rien — c'est le compteur du moteur, celui qui décide de clore l'étape.
 */
export function journeyEtapeCompteur(validees: number, quota: number): string {
    return `${validees}/${quota} série${quota > 1 ? "s" : ""}`;
}

/** Le repère de droite : « 16/20 minimum ». **`seuil` et `questions` sont servis.** */
export function journeyEtapeSeuil(seuil: number, questions: number): string {
    return `${seuil}/${questions} minimum`;
}

/** Ce qui se lit sous le repère. */
export const JOURNEY_ETAPE_SEUIL_SUB = "sur chacune";

/* ------------------------------------------------------------- Les séries */

/** L'intertitre de la liste. */
export const JOURNEY_ETAPE_LIST_TITLE = "À FAIRE";

/** « Série 1 » — l'index est **servi**. */
export function journeyEtapeSerieTitle(index: number): string {
    return `Série ${index}`;
}

/** Le repère carré de la carte. */
export function journeyEtapeSerieMark(index: number): string {
    return `${index}`;
}

/** « 16 min ». `null` quand la durée n'est pas servie — on n'en invente pas. */
export function journeyEtapeDuree(minutes: number | null): string | null {
    return minutes === null ? null : `${minutes} min`;
}

/** « 20 questions ». */
export function journeyEtapeQuestions(questions: number): string {
    return `${questions} question${questions > 1 ? "s" : ""}`;
}

/**
 * **Le badge d'état d'une série.**
 *
 * 🛑 **Il se lit sur `locked` et `validee`, dans cet ordre, et sur rien
 * d'autre.** « À refaire » n'est pas un jugement du score : c'est « jouée, pas
 * encore validée », deux faits servis. Le score n'entre jamais dans ce choix.
 *
 * 🛑 **« Réussie » est DÉFINITIF** : une série refaite et ratée garde ce badge,
 * parce que `validee` reste vrai côté serveur.
 */
export function journeyEtapeSerieState(serie: JourneySerieDto): {
    label: string;
    tone: BarTone;
} {
    if (serie.locked) return {label: "Verrouillée", tone: "muted"};
    if (serie.validee) return {label: "Réussie", tone: "ok"};
    if (serie.dernierAttemptId) return {label: "À refaire", tone: "warn"};
    return {label: "À faire", tone: "hot"};
}

/**
 * **Le bouton de la carte.**
 *
 * `precedente` est l'index de la série **servie** juste avant celle-ci —
 * jamais `index - 1` calculé ici : c'est la liste servie qui dit ce qui
 * précède. `null` (aucune précédente) laisse la phrase générique.
 */
export function journeyEtapeSerieCta(
    serie: JourneySerieDto,
    precedente: number | null,
): string {
    if (serie.locked) {
        return precedente === null
            ? "Verrouillée"
            : `Après la série ${precedente}`;
    }
    return serie.dernierAttemptId ? "Refaire la série" : "Commencer";
}

/** Le second accès d'une série déjà jouée : son corrigé. */
export const JOURNEY_ETAPE_SERIE_RESULT = "Voir mon résultat";

/** « Dernier score : 17/20 ». 🛑 **Affiché, jamais comparé.** */
export function journeyEtapeDernierScore(
    score: number | null,
    questions: number,
): string | null {
    return score === null ? null : `Dernier score : ${score}/${questions}`;
}

/* ----------------------------------------------------- Pied de l'écran */

/** Ce qui ouvre l'encart de validation. */
export const JOURNEY_ETAPE_VALIDATION_LEAD = "Validation :";

/** « 2 séries réussies à 16/20 minimum. » */
export function journeyEtapeValidation(
    quota: number,
    seuil: number,
    questions: number,
): string {
    return ` ${quota} série${quota > 1 ? "s" : ""} réussie${quota > 1 ? "s" : ""}`
        + ` à ${seuil}/${questions} minimum.`;
}

/**
 * La note de pied, **en compréhension ORALE seulement**.
 *
 * 🛑 **C'est une condition de passation, pas une déduction de route** : elle ne
 * s'écrit que sur `section === "CO"`, le fait servi.
 */
export const JOURNEY_ETAPE_CO_FOOT =
    "Audio écouté une seule fois • conditions proches du TCF";

/** `null` partout ailleurs qu'en compréhension orale. */
export function journeyEtapeFoot(section: SkillSection | null): string | null {
    return section === "CO" ? JOURNEY_ETAPE_CO_FOOT : null;
}

/* --------------------------------------------------------------- États */

export const JOURNEY_ETAPE_LOADING = "Chargement de l'étape…";

export const JOURNEY_ETAPE_ERROR = "Impossible de charger cette étape.";

export const JOURNEY_ETAPE_RETRY = "Réessayer";

export const JOURNEY_ETAPE_START_ERROR = "La série n'a pas pu démarrer. Réessayez.";

/** Le titre de l'écran quand rien n'est encore chargé — l'en-tête ne clignote pas. */
export const JOURNEY_ETAPE_TITLE_FALLBACK = "Votre étape";

/**
 * **Le verrou freemium de l'étape** : l'écran reste entier et lisible, seul le
 * geste est fermé (D-18, « on floute l'ACTION jamais le RÉSULTAT »).
 */
export const JOURNEY_ETAPE_LOCKED_NOTE =
    "Cette étape fait partie du parcours complet.";

/** Ce qu'un titre d'écran dit d'une étape dont le détail n'a pas encore répondu. */
export function journeyEtapeTitle(detail: JourneyStepDetailDto | undefined): string {
    return detail?.bloc.label ?? JOURNEY_ETAPE_TITLE_FALLBACK;
}
