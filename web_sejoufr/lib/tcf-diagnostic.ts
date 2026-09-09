/**
 * Règles d'affichage du diagnostic TCF 4 épreuves — **pures**, déclarées une
 * fois pour tout le web.
 *
 * 🛑 Le serveur n'expose que des **faits** (état d'une section, niveau, rang
 * d'une priorité). Les phrases vivent ici, et sont des **miroirs mot pour mot**
 * de `mobile_sejourfr/lib/screens/diagnostic_tcf/tcf_diagnostic_labels.dart` :
 * un libellé qui bouge, ce sont deux fichiers dans la même passe.
 *
 * 🛑 Ce fichier ne **dérive** aucun état pédagogique : `etat` et `niveau`
 * arrivent servis. Il ne fait que les mettre en mots.
 */
import type {
    EpreuveType,
    NiveauCecrl,
    TcfDiagnosticDto,
    TcfDiagnosticSectionDto,
    TcfDiagnosticSectionState,
} from "./types";

/** Titre de la page. « Diagnostic TCF », jamais « examen blanc » (`10_` §4.1). */
export const TCF_DIAGNOSTIC_TITLE = "Diagnostic TCF";
export const TCF_DIAGNOSTIC_SUBTITLE =
    "4 épreuves, à faire séparément quand vous voulez.";

/** Le résultat n'arrive qu'à la fin — c'est dit avant, pas découvert après. */
export const TCF_DIAGNOSTIC_RESULT_NOTE =
    "Votre résultat complet s'affichera une fois les 4 sections terminées.";

/**
 * Une section commencée se termine d'une traite (`10_` §4.2). L'écran le dit
 * **avant** de lancer, pas après.
 */
export const TCF_DIAGNOSTIC_SECTION_WARNING =
    "Une fois commencée, cette section se termine d'une traite.";

/** Le micro est annoncé avant l'oral, jamais demandé par surprise. */
export const TCF_DIAGNOSTIC_MIC_WARNING = "Cette section utilise votre micro.";

export const TCF_DIAGNOSTIC_ESTIMATION_NOTE =
    "Estimation SejourFR, non officielle.";

const SECTION_CTA: Record<TcfDiagnosticSectionState, string> = {
    A_FAIRE: "Commencer",
    EN_COURS: "Reprendre",
    TERMINEE: "Terminée",
};

/** Le bouton dit ce qui va se passer. */
export function sectionCtaLabel(etat: TcfDiagnosticSectionState): string {
    return SECTION_CTA[etat];
}

const SECTION_ETAT: Record<TcfDiagnosticSectionState, string> = {
    A_FAIRE: "À faire",
    EN_COURS: "En cours",
    TERMINEE: "Terminée",
};

export function sectionEtatLabel(etat: TcfDiagnosticSectionState): string {
    return SECTION_ETAT[etat];
}

/** « 2 sections sur 4 terminées ». Compté sur ce que le serveur a servi. */
export function progressionLabel(d: TcfDiagnosticDto): string {
    const faites = d.sections.filter((s) => s.etat === "TERMINEE").length;
    const total = d.sections.length;
    return `${faites} section${faites > 1 ? "s" : ""} sur ${total} terminée${
        faites > 1 ? "s" : ""
    }`;
}

/** Toutes les sections existantes sont closes ⇒ le résultat est demandable. */
export function resultatDisponible(d: TcfDiagnosticDto): boolean {
    const existantes = d.sections.filter((s) => s.attemptId !== null);
    if (existantes.length === 0) return false;
    return existantes.every((s) => s.etat === "TERMINEE");
}

/**
 * Le délai de reprise est passé.
 *
 * 🛑 **Ce n'est PAS une perte.** Les sections réalisées comptent toujours et le
 * résultat se calcule sur elles ; les autres restent « non évaluée ». Le
 * message doit le dire, jamais alarmer.
 */
export const TCF_DIAGNOSTIC_REPRISE_ECOULEE =
    "Le délai de reprise est écoulé. Nous calculerons votre résultat sur les sections terminées.";

/**
 * Une section absente du diagnostic (mode dégradé : aucun contenu disponible).
 *
 * 🛑 Le candidat ne doit **jamais** voir qu'il manque du contenu (`00_` §7.4) :
 * on la nomme « non évaluée », comme une épreuve qu'il n'a pas passée.
 */
export function sectionIndisponible(s: TcfDiagnosticSectionDto): boolean {
    return s.attemptId === null;
}

/**
 * Le niveau d'une épreuve, ou la mention **non évaluée**.
 *
 * 🛑 `null` = inconnu, jamais un palier plancher. Afficher « A1 » sur une
 * épreuve non passée serait un verdict que personne n'a rendu.
 */
export const NIVEAU_NON_EVALUE = "Non évaluée";

/** Le décompte de jours restants, calculé à l'affichage et jamais persisté. */
export function joursRestants(expiresAt: string, now: Date = new Date()): number {
    const fin = new Date(expiresAt).getTime();
    const reste = fin - now.getTime();
    return Math.max(0, Math.ceil(reste / (24 * 60 * 60 * 1000)));
}

/**
 * Où mène le bouton d'une section.
 *
 * 🛑 **Aucun écran de passation n'est créé pour le diagnostic** : les QCM vont
 * sur le runner de session existant, les productions sur la session EE/EO
 * existante. Un second parcours de passation divergerait du premier.
 */
export function sectionHref(
    epreuve: EpreuveType,
    attemptId: string,
    sessionId: string,
): string {
    const suffix = `?tcfDiagnosticId=${sessionId}`;
    switch (epreuve) {
        case "TCF_CO":
        case "TCF_CE":
            return `/sessions/${attemptId}${suffix}`;
        case "TCF_EE":
            return `/entrainement/tcf/ee/session/${attemptId}${suffix}`;
        case "TCF_EO":
            return `/entrainement/tcf/eo/session/${attemptId}${suffix}`;
        default:
            return `/sessions/${attemptId}${suffix}`;
    }
}

/** Le libellé d'un niveau servi, ou la mention « non évaluée ». */
export function niveauOuNonEvalue(
    niveau: NiveauCecrl | null,
    label: (n: NiveauCecrl) => string,
): string {
    return niveau === null ? NIVEAU_NON_EVALUE : label(niveau);
}
