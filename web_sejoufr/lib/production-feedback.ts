// Règles de LECTURE d'une évaluation de production EE/EO. Volontairement pures
// et sans dépendance React : ce sont les décisions qui rendent l'écran de
// restitution honnête (quel niveau on ose afficher, où se lit une note sur
// l'échelle du TCF, ce qu'on regroupe), et elles doivent être testables seules.
//
// Miroir mobile : `mobile_sejourfr/lib/screens/tcf_production/`.

import type {
    BandeCritere,
    ConfianceEvaluation,
    EeAccomplishment,
    EeAccomplishmentPoint,
    NiveauCecrl,
    ObjectifAccomplissement,
} from "./types";

// ---------------------------------------------------------------------------
// Échelle du TCF
// ---------------------------------------------------------------------------

/** Une bande de l'échelle officielle du TCF IRN sur les épreuves d'expression.
 *  `min`/`max` sont des bornes incluses, en points sur 20. */
export interface TcfNoteBand {
    niveau: NiveauCecrl;
    /** Libellé court affiché sous la bande. */
    label: string;
    min: number;
    max: number;
}

/**
 * La table officielle du TCF, telle quelle. Notre note **est** celle du TCF
 * depuis la grille v6 : il n'y a rien à convertir, seulement à faire lire.
 * C'est tout l'enjeu de l'écran — un 4,5/20 n'est pas un échec scolaire, c'est
 * un A2.
 */
export const TCF_NOTE_BANDS: readonly TcfNoteBand[] = [
    {niveau: "A1_NON_ATTEINT", label: "A1 non atteint", min: 0, max: 0},
    {niveau: "A1", label: "A1", min: 1, max: 1},
    {niveau: "A2", label: "A2", min: 2, max: 5},
    {niveau: "B1", label: "B1", min: 6, max: 9},
    {niveau: "B2", label: "B2", min: 10, max: 20},
];

/** Plage d'une bande, telle qu'on l'écrit sous l'échelle (« 2-5 », « 0 »). */
export function tcfBandRange(band: TcfNoteBand): string {
    return band.min === band.max ? String(band.min) : `${band.min}-${band.max}`;
}

export interface TcfScalePosition {
    /** Index dans {@link TCF_NOTE_BANDS}. */
    bandIndex: number;
    /** Position du curseur, en % de la largeur totale de l'échelle. */
    percent: number;
}

/**
 * Où poser le curseur d'une note sur l'échelle.
 *
 * Les bandes sont dessinées à largeur ÉGALE : à l'échelle réelle, « B2 »
 * occuperait la moitié de la barre et « A1 non atteint » serait illisible. Le
 * curseur se place donc dans SA bande, proportionnellement à la plage, et reste
 * inséré de 10 % de chaque côté pour qu'il soit toujours sans ambiguïté dans la
 * bonne case (une note pile au seuil, comme 2/20, tomberait sinon sur la
 * frontière).
 *
 * La bande retenue est la DERNIÈRE dont le minimum est atteint : c'est la même
 * lecture que le serveur (`>= 10 → B2`, `>= 6 → B1`, …), donc une note à
 * décimale entre deux bandes (5,5) reste dans la bande basse, comme le niveau
 * calculé côté backend.
 */
export function tcfScalePosition(note: number | null | undefined): TcfScalePosition | null {
    if (note == null || !Number.isFinite(note)) return null;
    const clamped = Math.max(0, Math.min(20, note));
    let bandIndex = 0;
    for (let i = 0; i < TCF_NOTE_BANDS.length; i++) {
        if (clamped >= TCF_NOTE_BANDS[i].min) bandIndex = i;
    }
    const band = TCF_NOTE_BANDS[bandIndex];
    const next = TCF_NOTE_BANDS[bandIndex + 1];
    const upper = next ? next.min : band.max + 1;
    const fraction =
        band.min === band.max
            ? 0.5
            : Math.min(1, Math.max(0, (clamped - band.min) / (upper - band.min)));
    const width = 100 / TCF_NOTE_BANDS.length;
    return {bandIndex, percent: (bandIndex + 0.1 + fraction * 0.8) * width};
}

/**
 * Teinte d'un palier du TCF. **Le rouge n'en fait pas partie**, et pas
 * seulement sur les badges : l'identité visuelle réserve le Rouge France aux
 * CTA critiques, et aucun palier atteint n'est une faute — un A1 est un
 * résultat. La progression est donc ambre (jusqu'à A2, « à consolider »), bleu
 * (B1), vert (B2).
 */
export type TcfTone = "amber" | "blue" | "green";

/** Teinte telle qu'un affichage la consomme : `"neutral"` quand il n'y a pas
 *  (encore) de note à teinter. Une production non évaluée n'est pas un échec —
 *  elle est grise, jamais rouge. */
export type TcfNoteTone = TcfTone | "neutral";

/**
 * Teinte d'un palier, dérivée du **niveau** et de rien d'autre.
 *
 * Surtout pas de la position dans {@link TCF_NOTE_BANDS} : indexer par rang
 * ferait glisser silencieusement toutes les couleurs le jour où un palier
 * s'ajoute, sans la moindre erreur de compilation. Le `switch` exhaustif, lui,
 * refuse de compiler tant qu'un niveau n'a pas sa teinte.
 */
export function tcfNiveauTone(niveau: NiveauCecrl): TcfTone {
    switch (niveau) {
        case "B2":
        case "C1":
        case "C2":
            return "green";
        case "B1":
            return "blue";
        case "A2":
        case "A1":
        case "A1_NON_ATTEINT":
            return "amber";
    }
}

/**
 * Teinte d'une note, dérivée de son palier TCF et de rien d'autre.
 *
 * Un seuil « sur 20 » n'a aucun sens ici : 12/20 vaut B2, le niveau le plus
 * haut de l'examen — le colorer en rouge, c'est peindre la meilleure note
 * possible en échec. La note est donc située sur l'échelle
 * ({@link tcfScalePosition}) puis teintée par son niveau
 * ({@link tcfNiveauTone}), sans seconde table.
 *
 * `"neutral"` quand il n'y a rien à teinter (production pas encore évaluée) :
 * un emplacement qui doit être coloré de toute façon — le grand chiffre du
 * hero — le rend en gris, comme le mobile.
 */
export function tcfNoteTone(note: number | null | undefined): TcfNoteTone {
    const position = tcfScalePosition(note);
    if (!position) return "neutral";
    return tcfNiveauTone(TCF_NOTE_BANDS[position.bandIndex].niveau);
}

/**
 * Bande qualitative d'un critère d'une évaluation **ancienne** — celles d'avant
 * que le serveur ne renvoie `bande`, seules à ne porter qu'une note.
 *
 * Depuis la grille v6, un critère se note sur la **même échelle du TCF** (celle
 * sur laquelle nous exprimons nos estimations) que la
 * note globale : sa bande se lit donc sur {@link TCF_NOTE_BANDS}, exactement
 * comme le serveur la calcule aujourd'hui (`BandeCritere.of`, bornes 10 / 6 /
 * 2). D'où l'absence de tout seuil propre : un critère à 12 est un B2, pas un
 * échec, et il ne doit pas s'afficher autrement qu'un critère moderne à 12.
 *
 * Une note nulle ou absente n'est pas une performance faible mais l'absence de
 * performance (hors-sujet, « en deçà du A1 ») : `NON_EVALUABLE`, même lecture
 * que le serveur.
 */
export function critereBandeFromNote(note: number | null | undefined): BandeCritere {
    const position = note != null && note > 0 ? tcfScalePosition(note) : null;
    if (!position) return "NON_EVALUABLE";
    switch (TCF_NOTE_BANDS[position.bandIndex].niveau) {
        case "B2":
        case "C1":
        case "C2":
            return "TRES_BONNE_MAITRISE";
        case "B1":
            return "SATISFAISANT";
        case "A2":
            return "EN_COURS_ACQUISITION";
        case "A1":
        case "A1_NON_ATTEINT":
            return "FRAGILE";
    }
}

// ---------------------------------------------------------------------------
// Niveau et confiance
// ---------------------------------------------------------------------------

/**
 * Garde-fou produit, porté ici et nulle part ailleurs : **on n'annonce jamais
 * un niveau sans savoir ce qu'il vaut**. Sans confiance, l'écran retombe sur la
 * note seule.
 */
export function canShowNiveau(
    niveau: NiveauCecrl | null | undefined,
    confiance: ConfianceEvaluation | null | undefined,
): boolean {
    return niveau != null && confiance != null;
}

/**
 * Une confiance HAUTE est le cas normal : l'afficher n'apprend rien au candidat
 * et sème le doute sur une évaluation qui n'en mérite pas. On ne montre la
 * confiance (et ses raisons) que lorsqu'elle nuance vraiment le résultat.
 */
export function shouldShowConfiance(confiance: ConfianceEvaluation | null | undefined): boolean {
    return confiance != null && confiance !== "HAUTE";
}

// ---------------------------------------------------------------------------
// Objectif de la tâche
// ---------------------------------------------------------------------------

export type ObjectifTone = "done" | "partial" | "missed";

export interface ObjectifPresentation {
    /** Le verdict, seul et capitalisé : il se lit sous l'eyebrow « OBJECTIF DE
     *  LA TÂCHE », pas au fil d'une phrase. */
    label: string;
    tone: ObjectifTone;
}

/** Null quand l'évaluation ne porte pas de verdict (toutes celles d'avant la
 *  grille v8) : le bandeau n'est alors pas rendu du tout. */
export function objectifPresentation(
    objectif: ObjectifAccomplissement | null | undefined,
): ObjectifPresentation | null {
    switch (objectif) {
        case "ATTEINT":
            return {label: "Atteint", tone: "done"};
        case "PARTIELLEMENT_ATTEINT":
            return {label: "Partiellement atteint", tone: "partial"};
        case "NON_ATTEINT":
            return {label: "Non atteint", tone: "missed"};
        default:
            return null;
    }
}

// ---------------------------------------------------------------------------
// Accomplissement détaillé
// ---------------------------------------------------------------------------

/** Les trois groupes de la check-list de consigne (parité mobile). Un manque
 *  exigé et une piste ignorée ne se lisent pas pareil : la seconde n'enlève
 *  aucun point, les mélanger fait paniquer pour rien. */
export interface AccomplishmentGroups {
    traites: EeAccomplishmentPoint[];
    manquesObligatoires: EeAccomplishmentPoint[];
    pistesNonAbordees: EeAccomplishmentPoint[];
}

export function groupAccomplishment(
    acc: EeAccomplishment | null | undefined,
): AccomplishmentGroups {
    const oublies = acc?.pointsOublies ?? [];
    return {
        traites: acc?.pointsTraites ?? [],
        manquesObligatoires: oublies.filter((p) => p.obligatoire),
        pistesNonAbordees: oublies.filter((p) => !p.obligatoire),
    };
}

/** Ce que résume le bandeau « Ce qui marche » : les points **obligatoires**
 *  traités sur ceux qui étaient demandés. */
export interface TreatedPointsSummary {
    done: number;
    total: number;
    libelles: string[];
}

/**
 * Compteur du bandeau « Ce qui marche ».
 *
 * Les pistes sont exclues **des deux côtés** : ne pas traiter une piste
 * n'enlève aucun point, l'inclure au dénominateur ferait lire « 3/5 » à une
 * consigne entièrement remplie. `null` quand la consigne n'exigeait rien
 * d'identifiable (évaluations antérieures aux rubriques v8) — le bandeau se
 * rabat alors sur le compte de points forts.
 */
export function treatedPointsSummary(
    acc: EeAccomplishment | null | undefined,
): TreatedPointsSummary | null {
    if (!acc) return null;
    const groups = groupAccomplishment(acc);
    const traites = groups.traites.filter((p) => p.obligatoire);
    const total = traites.length + groups.manquesObligatoires.length;
    if (total === 0) return null;
    return {done: traites.length, total, libelles: traites.map((p) => p.libelle)};
}

/** Découpage d'un texte autour du passage à surligner. */
export interface HighlightSplit {
    before: string;
    match: string;
    after: string;
}

/**
 * Repère dans la production la phrase visée par la priorité n° 1.
 *
 * **Première occurrence exacte, et rien d'autre** : si le correcteur a recomposé
 * la phrase, on ne surligne rien plutôt que de désigner le mauvais passage. Un
 * repère faux coûte plus cher que pas de repère.
 */
export function splitHighlight(
    texte: string,
    cible: string | null | undefined,
): HighlightSplit | null {
    const needle = (cible ?? "").trim();
    if (!needle) return null;
    const start = texte.indexOf(needle);
    if (start < 0) return null;
    return {
        before: texte.slice(0, start),
        match: texte.slice(start, start + needle.length),
        after: texte.slice(start + needle.length),
    };
}

export function hasAccomplishmentDetail(groups: AccomplishmentGroups): boolean {
    return (
        groups.traites.length +
            groups.manquesObligatoires.length +
            groups.pistesNonAbordees.length >
        0
    );
}

// ---------------------------------------------------------------------------
// Bilan d'épreuve : ce qu'on écrit à la place du niveau global
// ---------------------------------------------------------------------------

/** Attente normale : le pipeline IA tourne encore sur au moins une tâche. */
export const BILAN_NIVEAU_PENDING_LABEL = "Évaluation en cours…";

/** Une correction a échoué de notre côté. Le serveur suspend alors le niveau
 *  d'épreuve — il ne compte pas 0 une tâche que le candidat a bien rendue
 *  (`ProductionSubmissionService.bilan`, garde `anyFailed`). L'annoncer « en
 *  cours » était donc faux ET sans fin : rien ne tourne, c'est une relance qui
 *  débloque le niveau. Vécu le 2026-08-06 sur un examen blanc EO dont deux
 *  tâches sur trois avaient échoué. Miroir mobile : `BilanHero.needsRetry`. */
export const BILAN_NIVEAU_RETRY_LABEL = "Évaluation à relancer";

/** Texte du badge « Niveau global » tant qu'aucun niveau n'est calculable. */
export function bilanNiveauPendingLabel(anyFailed: boolean): string {
    return anyFailed ? BILAN_NIVEAU_RETRY_LABEL : BILAN_NIVEAU_PENDING_LABEL;
}
