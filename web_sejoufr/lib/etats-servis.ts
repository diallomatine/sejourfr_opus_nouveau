/**
 * **Un état SERVI mis en mots et en ton** pour les primitives Navigation v2
 * (`Metric`, `LevelRow`, `Badge`, `ThemeCard`…) — la seule table du web.
 *
 * 🛑 **Rien n'est classé ici.** Chaque fonction traduit un état que le serveur a
 * déjà décidé (`StatutObjectif`, `CivicThemeState`, statut de bloc de cycle) ;
 * aucune ne regarde un nombre. `null = inconnu, jamais mauvais` : une épreuve
 * sans palier mesuré se dit « Non évalué », au ton neutre — jamais « À
 * renforcer ».
 *
 * Miroir mobile : `etatEpreuveTcf` / `etatThemeCivique` (`progres_labels.dart`,
 * type `SfState`) — un libellé qui bouge ici
 * bouge là-bas dans la même passe.
 */
import {toneToStateTone, type ServedState, type StateTone, type Tone} from "@/app/_components/sejour/SejourKit";
import {kitTone} from "./civic-diagnostic";
import {
    CIVIC_THEME_STATE_LABEL,
    type CivicThemeState,
    type ProgressEpreuveDto,
    type StatutObjectif,
} from "./types";

/** Le ton du kit historique (`ok | warn | hot | muted`) lu dans la palette v2. */
export function etatTon(tone: Tone): StateTone {
    return toneToStateTone[tone];
}

/** Le libellé d'une épreuve qu'aucune mesure n'a encore située. */
export const ETAT_NON_EVALUE = "Non évalué";

const STATUT_OBJECTIF: Record<StatutObjectif, ServedState> = {
    TARGET_REACHED: {label: "Objectif atteint", tone: "success"},
    CLOSE_TO_TARGET: {label: "Proche de l'objectif", tone: "warning"},
    TO_REINFORCE: {label: "À renforcer", tone: "danger"},
};

/**
 * L'état d'une épreuve TCF face à l'objectif : `ProgressEpreuveDto.status`,
 * servi par `GET /api/me/progress`.
 *
 * 🛑 Le statut est servi même sans mesure (`TO_REINFORCE` par défaut) : c'est
 * le **palier** (`niveau`) qui dit si l'épreuve a été mesurée. Sans palier ⇒
 * « Non évalué ». Sans démarche déclarée (`status` nul) ⇒ aucun état.
 */
export function etatEpreuveTcf(epreuve: ProgressEpreuveDto | null | undefined): ServedState | null {
    if (!epreuve) return null;
    if (epreuve.niveau === null) return {label: ETAT_NON_EVALUE, tone: "neutral"};
    return epreuve.status ? STATUT_OBJECTIF[epreuve.status] : null;
}

/** L'état servi d'un thème civique (`CivicThemeState`), au ton de `kitTone`. */
export function etatThemeCivique(etat: CivicThemeState): ServedState {
    return {label: CIVIC_THEME_STATE_LABEL[etat], tone: etatTon(kitTone(etat))};
}
