/**
 * Règles d'affichage du diagnostic **civique** — **pures**, déclarées une fois
 * pour tout le web.
 *
 * 🛑 Le serveur n'expose que des **faits** (un état de thème, un compte, une
 * projection). Les phrases vivent ici, et sont des **miroirs mot pour mot** de
 * `mobile_sejourfr/lib/screens/diagnostic_civique/civic_diagnostic_labels.dart` :
 * un libellé qui bouge, ce sont deux fichiers dans la même passe.
 *
 * 🛑 Ce fichier ne **dérive** aucun état pédagogique : `etat` et `projection40`
 * arrivent servis. Il ne fait que les mettre en mots.
 */
import type {
    CivicDiagnosticResultDto,
    CivicThemeState,
    Difficulty,
} from "./types";

export const CIVIC_DIAGNOSTIC_TITLE = "Mon diagnostic — Examen civique";
/**
 * 🛑 Le nombre de questions n'est **pas** écrit ici : il est servi
 * (`total` / `formatQuestions`). Le figer dans une phrase reproduirait
 * exactement le piège de la table des paliers en six copies.
 */
export function civicDiagnosticSubtitle(total: number): string {
    return `${total} questions, comme à l'examen, réparties sur les 5 thèmes.`;
}

/**
 * 🛑 Le diagnostic **n'est pas** un examen blanc (`20_` §4.1), et l'écran doit
 * le dire avant de commencer : sinon le candidat lit son résultat comme un
 * pronostic de réussite.
 */
export const CIVIC_DIAGNOSTIC_NOT_EXAM =
    "Ce n'est pas un examen blanc : il sert à repérer ce qu'il vous reste à travailler.";

export const CIVIC_DIAGNOSTIC_START_CTA = "Commencer mon diagnostic";
export const CIVIC_DIAGNOSTIC_RESUME_CTA = "Reprendre";
export const CIVIC_DIAGNOSTIC_RESULT_CTA = "Voir mon résultat";
export const CIVIC_DIAGNOSTIC_PLAN_CTA = "Découvrir mon plan";
export const CIVIC_DIAGNOSTIC_REVOIR_CTA = "Revoir mes réponses";

/** Le badge de mention affiché en tête du résultat (`20_` §4.5). */
export const MENTION_LABEL: Record<string, string> = {
    CSP: "Carte de séjour pluriannuelle",
    CR: "Carte de résident",
    NAT: "Naturalisation",
};

export function mentionBadge(mention: Difficulty): string {
    return MENTION_LABEL[mention] ?? mention;
}

/** « 12 sur 24 répondues ». Compté sur ce que le serveur a servi. */
export function progressionLabel(repondues: number, total: number): string {
    return `${repondues} sur ${total} répondue${repondues > 1 ? "s" : ""}`;
}

/**
 * La phrase sous le score.
 *
 * **Deux formulations, et la différence est de l'honnêteté :**
 *
 * - le diagnostic a posé **le format entier** (40 questions, comme l'épreuve) ⇒
 *   le score **est** le résultat, on ne projette rien et on ne dit surtout pas
 *   « soit environ » ;
 * - le catalogue était sous-doté sur cette mention et il en manque ⇒ on
 *   **projette**, et on le dit, parce qu'un report n'est pas une mesure.
 *
 * 🛑 `projection40` vient du serveur : ce fichier ne le recalcule pas. `null` ⇒
 * aucune phrase — « on n'a rien mesuré » ne se dit pas « vous auriez 0 ».
 *
 * 🛑 **Aucune promesse de réussite.** On dit le seuil, jamais « vous êtes prêt »
 * ni « vous allez échouer ».
 */
export function projectionLine(r: CivicDiagnosticResultDto): string | null {
    if (r.projection40 === null) return null;
    const seuil = `Le seuil de réussite est de ${r.seuilReussite}.`;
    if (r.posees === r.formatQuestions) {
        return seuil;
    }
    return `Soit environ ${r.projection40} / ${r.formatQuestions} à l'examen. ${seuil}`;
}

/** La pastille d'un thème. `NON_EVALUE` n'a **pas** de couleur d'alerte. */
export function themeTone(etat: CivicThemeState): "ok" | "warn" | "hot" | "muted" {
    switch (etat) {
        case "SOLIDE":
            return "ok";
        case "A_RENFORCER":
            return "warn";
        case "FAIBLE":
            return "hot";
        case "NON_EVALUE":
            return "muted";
    }
}

/** Le bloc des mises en situation (`20_` §4.5 bloc 3), verbatim. */
export const CIVIC_SITUATIONS_TITLE = "Mises en situation";
export const CIVIC_SITUATIONS_TEXT =
    "Les mises en situation demandent d'appliquer les règles à un cas concret. "
    + "C'est souvent ce qui fait la différence à l'examen.";

/** « 8 sur 12 réussies ». `null` quand aucune n'a été posée (mode dégradé). */
export function situationsLine(r: CivicDiagnosticResultDto): string | null {
    if (r.situations.posees <= 0) return null;
    return `${r.situations.reussies} sur ${r.situations.posees} réussie`
        + `${r.situations.reussies > 1 ? "s" : ""}`;
}

/** Le titre du bloc 4, volontairement concret (`20_` §4.5). */
export const CIVIC_PRIORITES_TITLE = "Ce qui vous coûte le plus de points";

/**
 * La rassurance (`20_` §4.5 bloc 5) — et elle doit être **vraie**.
 *
 * 🛑 `null` quand aucun thème n'est solide : « 0 thème est déjà solide » serait
 * une phrase de consolation qui sonne faux au pire moment.
 */
export const CIVIC_RASSURANCE_TITLE = "Vous n'avez pas besoin de tout réviser";

export function rassuranceText(r: CivicDiagnosticResultDto): string | null {
    const solides = r.themes.filter((t) => t.etat === "SOLIDE").length;
    if (solides <= 0) return null;
    return `${solides} thème${solides > 1 ? "s sont déjà solides" : " est déjà solide"}. `
        + "Votre plan se concentrera sur ce qui vous fait perdre le plus de points.";
}

/** Le teaser du plan (`20_` §4.5 bloc 6). */
export const CIVIC_PLAN_TEASER_TITLE = "Votre plan de révision est prêt";

/**
 * Le paramètre que le runner reçoit quand la série appartient à un diagnostic
 * civique.
 *
 * 🛑 **Sa seule fonction est le RETOUR** — exactement comme
 * `TCF_DIAGNOSTIC_PARAM`. Sans lui, le candidat termine ses 40 questions et
 * atterrit sur le bilan de série générique, très loin de son diagnostic : c'est
 * précisément ce qui a été constaté à l'usage. Il ne change **rien d'autre** :
 * ni la passation, ni la correction, ni le décompte.
 *
 * Miroir de `kCivicDiagnosticParam` côté mobile.
 */
export const CIVIC_DIAGNOSTIC_PARAM = "civicDiagnosticId";

/** L'accueil du diagnostic civique. */
export const CIVIC_DIAGNOSTIC_HUB_HREF = "/diagnostic-civique";

/**
 * Où le runner renvoie à la fin d'un diagnostic civique : **le résultat**, pas
 * l'accueil.
 *
 * 🛑 Différence assumée avec le TCF, et elle vient de la forme : le diagnostic
 * TCF a quatre sections, donc terminer l'une d'elles ramène au hub qui montre
 * les trois autres. Le civique n'en a **qu'une** — le renvoyer à un accueil qui
 * lui redemanderait de cliquer « Voir mon résultat » ajouterait une étape à un
 * parcours terminé.
 */
export function civicDiagnosticResultHref(sessionId: string): string {
    return `/diagnostic-civique/${sessionId}/resultat`;
}
