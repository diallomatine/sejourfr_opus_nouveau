/**
 * **Les mots et les règles d'affichage de `/examens-blancs`** — Navigation v2,
 * phase 4 (maquette `#tcf-examens` / `#civique-examens`).
 *
 * 🛑 **Textes éditoriaux de la maquette repris tels quels (R8), valeurs
 * servies partout ailleurs (R3/R7).** Le nombre de créneaux est celui de la
 * grille servie (`slots.length`), le format de l'examen civique celui du
 * miroir gelé de l'arrêté (`lib/civique-examen.ts`), les épreuves du TCF
 * celles du miroir `lib/tcf-epreuves.ts`, la durée de l'examen complet celle de
 * la table unique `lib/exam-durations.ts`, le nombre de thèmes celui de la
 * liste servie. Aucune fonction ici ne classe un nombre.
 *
 * ⚠️ Miroir mobile attendu (segment Examens des deux modules) : mêmes mots.
 */
import {CIVIQUE_EXAM_QUESTIONS, CIVIQUE_EXAM_SEUIL} from "./civique-examen";
import {FULL_TCF_EXAM_INDICATIVE_SEC} from "./exam-durations";
import {PASS_MODULE_NAME, type PassModule} from "./passes";
import {tcfEpreuveMark} from "./progression";
import {TCF_EPREUVES_OFFICIELLES} from "./tcf-epreuves";

/* ------------------------------------------------------------ En-têtes */

/* Les kickers de module sont ceux de `lib/module-ecrans.ts`
   (`MODULE_TCF_KICKER` / `MODULE_CIVIQUE_KICKER`), communs aux écrans de
   module : on ne les recopie pas ici. */

export const EXAMENS_TCF_TITLE = "Examens blancs";
export const EXAMENS_TCF_SUBTITLE = "Des simulations complètes, dans les conditions réelles de l'épreuve.";

export const EXAMENS_CIVIQUE_TITLE = "Examens";
export const EXAMENS_CIVIQUE_SUBTITLE =
    "Testez l'ensemble des thèmes dans une simulation complète, en conditions réelles.";

/** La tuile « Terminés » : créneaux passés sur créneaux SERVIS ; grille pas
 *  encore lue ⇒ le compteur seul (miroir de `examsDoneValue`, mobile). */
export function examensTermines(faits: number, total: number | null): string {
    return total == null ? `${faits}` : `${faits}/${total}`;
}

export const EXAMENS_TERMINES_LABEL = "Terminés";

/** « Meilleur score · {taux} » — le taux servi du meilleur examen global. */
export function examensMeilleurScore(taux: string): string {
    return `Meilleur score · ${taux}`;
}

/* ------------------------------------------------------------ Bandeaux */

export const EXAMENS_TCF_HERO_LABEL = "Simulation réelle";
export const EXAMENS_TCF_HERO_TITLE = "Examen blanc complet";

/** La durée indicative de l'examen complet, en minutes (table unique). */
export const EXAMENS_TCF_MINUTES = Math.round(FULL_TCF_EXAM_INDICATIVE_SEC / 60);
export const EXAMENS_MINUTES_LABEL = "minutes";

/** « CO · CE · EE · EO » — les quatre épreuves officielles (miroir). */
export const EXAMENS_TCF_EPREUVES = TCF_EPREUVES_OFFICIELLES.map((e) => tcfEpreuveMark(e)).join(" · ");

/** La phrase du bandeau TCF : épreuves, durée indicative, puis la maquette. */
export const EXAMENS_TCF_HERO_SUB =
    `${EXAMENS_TCF_EPREUVES} · environ ${EXAMENS_TCF_MINUTES} min, avec niveau estimé et analyse IA à la clé.`;

export const EXAMENS_CIVIQUE_HERO_LABEL = "Conditions réelles";
export const EXAMENS_CIVIQUE_HERO_TITLE = "Examen blanc civique";
export const EXAMENS_QUESTIONS_LABEL = "questions";

/**
 * « 40 questions · les 5 thèmes · objectif de réussite : 32/40. » — format de
 * l'arrêté (miroir gelé) et nombre de thèmes servi ; inconnu ⇒ la mention
 * disparaît (miroir de `civiqueExamsHeroSub`, mobile).
 */
export function examensCiviqueHeroSub(nbThemes: number | null): string {
    const parts = [
        `${CIVIQUE_EXAM_QUESTIONS} questions`,
        ...(nbThemes && nbThemes > 0 ? [`les ${nbThemes} thèmes`] : []),
        `objectif de réussite : ${CIVIQUE_EXAM_SEUIL}/${CIVIQUE_EXAM_QUESTIONS}`,
    ];
    return `${parts.join(" · ")}.`;
}

/** Le CTA du bandeau TCF, sur le prochain créneau ouvert servi. */
export function examensTcfHeroCta(slot: number): string {
    return `Commencer l'examen ${slot}`;
}

/** Un examen en cours : le bandeau le reprend. */
export function examensTcfHeroResume(slot: number): string {
    return `Reprendre l'examen ${slot}`;
}

/** Tous les créneaux restants verrouillés : le bandeau ouvre l'offre. */
export const EXAMENS_TCF_HERO_PASS = "Voir le pass Intégral";

export const EXAMENS_CIVIQUE_HERO_CTA = "Lancer un examen blanc";
/** Tous les créneaux restants verrouillés : le bandeau civique ouvre l'offre. */
export const EXAMENS_CIVIQUE_HERO_PASS = `Voir le pass ${PASS_MODULE_NAME.CIVIQUE}`;

/* ------------------------------------------------------- Mes examens */

export const EXAMENS_LIST_TITLE = "Mes examens";
export const EXAMENS_CIVIQUE_LIST_TITLE = "Historique";

export const EXAMENS_STATUS_DONE = "Fait";
export const EXAMENS_STATUS_GO = "Commencer";
export const EXAMENS_STATUS_RESUME = "Reprendre";
export const EXAMENS_STATUS_LOCKED = "Verrouillé";

export const EXAMENS_META_OPEN = "Disponible";
export const EXAMENS_META_IN_PROGRESS = "En cours";
export const EXAMENS_META_PENDING = "Évaluation en cours…";
/** Un visiteur : le créneau s'ouvre avec un compte gratuit (`lockedLabel` historique). */
export const EXAMENS_META_GUEST_LOCKED = "Compte gratuit";

/** « Inclus dans le pass Intégral » — vocabulaire du dépôt (jamais « réservé aux abonnés »). */
export function examensMetaLocked(pass: PassModule): string {
    return `Inclus dans le pass ${PASS_MODULE_NAME[pass]}`;
}

/** « Examen 3 » / « Examen blanc 3 ». */
export function examenTcfTitre(slot: number): string {
    return `Examen ${slot}`;
}

export function examenCiviqueTitre(slot: number): string {
    return `Examen blanc ${slot}`;
}

/** « Terminé · niveau estimé B1 » (+ « · partiel »), sur le palier servi. */
export function examensMetaTcfTermine(niveau: string, partiel: boolean): string {
    return `Terminé · niveau estimé ${niveau}${partiel ? " · partiel" : ""}`;
}

/** « 29/40 · terminé » — score brut servi. Aucun « réussi » : aucun verdict
 *  de seuil n'est servi par créneau (parité mobile). */
export function examensMetaCiviqueTermine(score: string): string {
    return `${score} · terminé`;
}

/** La mention de l'examen offert d'un compte sans pass TCF. */
export function examensTcfOffert(slot: number): string {
    return `Examen ${slot} offert · expression écrite et orale évaluées une fois`;
}

/** Visiteur : « 20 examens · 1 offert sans compte » (créneaux ouverts servis). */
export function examensGuestOffre(total: number, ouverts: number): string {
    return `${total} examens · ${ouverts} offert${ouverts > 1 ? "s" : ""} sans compte`;
}

/** Le dépliant de la grille repliée. */
export function examensVoirSuite(from: number, to: number): string {
    return `Voir les examens ${from} à ${to}`;
}

export const EXAMENS_REDUIRE = "Réduire";

/** La feuille d'un examen déjà passé. */
export const EXAMENS_DONE_DETAIL = "Voir le rapport";
export const EXAMENS_DONE_RESUME = "Refaire l'examen";

export const EXAMENS_BLOCK_ERROR = "Vos examens n'ont pas pu être chargés.";
export const EXAMENS_RETRY = "Réessayer";

/* --------------------------------------------------------------- Règles */

/**
 * Le **prochain créneau à lancer** : le premier ouvert (verrou servi) et
 * encore vide. `null` quand il n'y en a pas — le CTA disparaît, il ne
 * devine rien.
 */
export function prochainCreneau(
    locks: ReadonlyArray<boolean>,
    passes: ReadonlyArray<unknown | null>,
): number | null {
    for (let i = 0; i < locks.length; i++) {
        if (!locks[i] && !passes[i]) return i + 1;
    }
    return null;
}

/** Combien de créneaux le serveur ouvre (verrou servi à `false`). */
export function creneauxOuverts(locks: ReadonlyArray<boolean>): number {
    return locks.filter((l) => !l).length;
}

/** Le premier créneau ouvert (l'examen offert d'un compte gratuit), ou `null`. */
export function premierCreneauOuvert(locks: ReadonlyArray<boolean>): number | null {
    const i = locks.findIndex((l) => !l);
    return i < 0 ? null : i + 1;
}

/**
 * La grille repliée : 8 créneaux, jamais moins que les examens passés + le
 * suivant (règle historique de `ExamsGrid`). Plafond d'AFFICHAGE seulement.
 */
export const EXAMENS_REPLIES = 8;

export function examensVisibles(total: number, passes: number, deplie: boolean): number {
    if (deplie) return total;
    return Math.min(total, Math.max(EXAMENS_REPLIES, Math.min(passes + 1, total)));
}
