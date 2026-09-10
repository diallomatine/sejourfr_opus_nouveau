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
import {niveauCecrlLabel} from "./types";
import type {
    NiveauEvolution,
    ProgressActiviteDto,
    ProgressCiviqueDto,
    ProgressCompetencesDto,
    ProgressEpreuveDto,
    ProgressTcfDto,
} from "./types";

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

/** État vide (`30_` §7). */
export const PROGRES_VIDE_TEXT =
    "Votre progression s'affichera après votre premier diagnostic.";

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
    switch (epreuve.evolution) {
        case "HAUSSE":
            return epreuve.niveauInitial
                ? `↑ depuis ${niveauCecrlLabel(epreuve.niveauInitial)}`
                : "↑";
        case "BAISSE":
            return epreuve.niveauInitial
                ? `↓ depuis ${niveauCecrlLabel(epreuve.niveauInitial)}`
                : "↓";
        case "STABLE":
            return "=";
        case "INCONNUE":
            return null;
    }
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
