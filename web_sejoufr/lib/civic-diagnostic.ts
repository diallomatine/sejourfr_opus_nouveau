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
import type {Tone} from "@/app/_components/sejour/SejourKit";
import type {CivicDiagnosticResultDto, CivicThemeState} from "./types";

/**
 * Le format OFFICIEL de l'examen — miroir de `CivicExamFormat` côté Java, où
 * ces deux nombres sont du **code** et non un réglage.
 *
 * 🛑 Ils ne servent qu'à l'écran **d'intro**, seul moment du parcours où aucune
 * session n'existe encore : dès qu'un résultat est servi, ce sont
 * `formatQuestions` et `seuilReussite` du DTO qui font foi, jamais ceux-ci.
 */
export const CIVIC_EXAM_QUESTIONS = 40;
export const CIVIC_EXAM_SEUIL_REUSSITE = 32;

/** Les thèmes du livret officiel. Structure de l'épreuve, pas un réglage. */
export const CIVIC_THEMES_COUNT = 5;

/**
 * Le **ton** d'un état de thème, dans le vocabulaire du kit.
 *
 * ⚠️ **`NON_EVALUE` n'a pas son ton.** Le kit (`Tone`) ne connaît que `ok` /
 * `warn` / `hot` : il manque une valeur neutre, et la brique est à ajouter des
 * deux côtés (web + Flutter). En attendant, on retombe sur `warn` — jamais
 * `hot`, qui dirait « raté », ni `ok`, qui dirait « acquis » —, et c'est le
 * **libellé servi** (« Non évalué ») qui porte le sens.
 */
/**
 * Ton du kit pour un état de thème SERVI.
 *
 * 🛑 `NON_EVALUE` rend `muted`, jamais `warn` : le serveur n'a pas mesuré ce
 * thème, il ne dit pas qu'il est fragile. Le faire tomber dans l'ambre faisait
 * afficher un verdict que personne n'a rendu — `null = inconnu, jamais
 * mauvais`. Miroir de `civicThemeTone` côté Flutter.
 */
export function kitTone(etat: CivicThemeState): Tone {
    switch (etat) {
        case "SOLIDE":
            return "ok";
        case "FAIBLE":
            return "hot";
        case "A_RENFORCER":
            return "warn";
        case "NON_EVALUE":
            return "muted";
    }
}

/* --------------------------------------------------------------- L'intro */

export const CIVIC_INTRO_KICKER = "Diagnostic";
export const CIVIC_INTRO_TITLE = "Examen civique";
export const CIVIC_INTRO_LEAD =
    "Découvrez les thèmes et notions que vous devez travailler en priorité.";

export const CIVIC_INTRO_STAT_QUESTIONS = "Questions";
export const CIVIC_INTRO_STAT_THEMES = "Thèmes évalués";
export const CIVIC_INTRO_STAT_SEUIL = "Seuil de réussite";

export const CIVIC_INTRO_THEMES_TITLE = "Les 5 thèmes du livret";
export const CIVIC_INTRO_SITUATIONS_NOTE =
    "Certaines questions sont des mises en situation, pour vérifier que vous "
    + "savez appliquer les règles à des cas concrets.";

/** La légende sous le CTA de l'intro. Le constat est gratuit, on le dit. */
export const CIVIC_INTRO_FREE_CAPTION = "Votre premier diagnostic est offert.";

/**
 * 🛑 Le diagnostic **n'est pas** un examen blanc (`20_` §4.1), et l'écran doit
 * le dire avant de commencer : sinon le candidat lit son résultat comme un
 * pronostic de réussite.
 */
export const CIVIC_DIAGNOSTIC_NOT_EXAM =
    "Ce n'est pas un examen blanc : il sert à repérer ce qu'il vous reste à travailler.";

export const CIVIC_DIAGNOSTIC_START_CTA = "Commencer mon diagnostic";

/**
 * Le tunnel **invité** (`V053`), en mots.
 *
 * 🛑 **La démarche est demandée AVANT le tirage**, et ce n'est pas un
 * formulaire de confort : c'est elle qui choisit les questions. Un candidat
 * naturalisation mesuré sur des questions de carte de séjour repartirait avec
 * un diagnostic flatteur et un plan incomplet.
 */
export const CIVIC_DIAGNOSTIC_GUEST_TITLE = "Quelle démarche préparez-vous ?";
/** 🛑 Promesse tenue par le serveur : aucun compte n'est demandé pour répondre. */
export const CIVIC_DIAGNOSTIC_GUEST_NOTE =
    "Pas besoin de compte pour commencer. Il ne vous sera demandé qu'au moment "
    + "de voir votre résultat.";
export const CIVIC_DIAGNOSTIC_GUEST_BADGE = "Sans compte";

/** Le résultat est ce qu'on échange contre le compte — dit sans détour. */
export const CIVIC_DIAGNOSTIC_GATE_EYEBROW = "Dernière étape";
export const CIVIC_DIAGNOSTIC_GATE_TITLE = "Vos réponses sont enregistrées";
export const CIVIC_DIAGNOSTIC_GATE_LEAD =
    "Créez votre compte gratuit pour voir votre résultat et votre plan. "
    + "Vos 40 réponses sont déjà en sécurité : elles vous suivent.";
export const CIVIC_DIAGNOSTIC_RESUME_CTA = "Reprendre";
export const CIVIC_DIAGNOSTIC_RESULT_CTA = "Voir mon résultat";
export const CIVIC_DIAGNOSTIC_PLAN_CTA = "Découvrir mon plan";

/** L'en-tête d'un diagnostic déjà ouvert (reprise). */
export const CIVIC_DIAGNOSTIC_EN_COURS_LABEL = "Votre diagnostic en cours";

/** Les trois démarches, dans l'ordre du livret. */
export const MENTION_LABEL: Record<string, string> = {
    CSP: "Carte de séjour pluriannuelle",
    CR: "Carte de résident",
    NAT: "Naturalisation",
};

/** « 12 sur 24 répondues ». Compté sur ce que le serveur a servi. */
export function progressionLabel(repondues: number, total: number): string {
    return `${repondues} sur ${total} répondue${repondues > 1 ? "s" : ""}`;
}

/* ------------------------------------------------------------- Le résultat */

export const CIVIC_RESULT_KICKER = "Examen civique";
export const CIVIC_RESULT_TITLE = "Votre diagnostic";
export const CIVIC_RESULT_BADGE = "Diagnostic terminé";
export const CIVIC_RESULT_SCORE_LABEL = "Bonnes réponses";
export const CIVIC_THEMES_TITLE = "Vos thèmes";

/**
 * La phrase sous le score.
 *
 * **Deux formulations, et la différence est de l'honnêteté :**
 *
 * - le diagnostic a posé **le format entier** (40 questions, comme l'épreuve) ⇒
 *   le score **est** le résultat, on ne projette rien et on ne dit surtout pas
 *   « correspond à environ » ;
 * - le catalogue était sous-doté sur cette mention et il en manque ⇒ on
 *   **projette**, et on le dit, parce qu'un report n'est pas une mesure.
 *
 * 🛑 `projection40` vient du serveur : ce fichier ne le recalcule pas. `null` ⇒
 * aucune phrase — « on n'a rien mesuré » ne se dit pas « vous auriez 0 ».
 */
export function perspectiveLine(r: CivicDiagnosticResultDto): string | null {
    if (r.projection40 === null) return null;
    if (r.posees === r.formatQuestions) {
        return `Votre résultat est directement comparable à l'examen : vos `
            + `${r.posees} questions sont au format de l'épreuve.`;
    }
    return `Votre résultat actuel correspond à environ ${r.projection40} / `
        + `${r.formatQuestions} sur un examen complet.`;
}

/**
 * L'encart de seuil.
 *
 * 🛑 **Aucune promesse de réussite.** On dit le seuil, jamais « vous êtes prêt »
 * ni « vous allez échouer ». La mention « estimation » n'apparaît que quand le
 * nombre affiché **est** une estimation : la coller sur un score complet ferait
 * douter d'une mesure exacte.
 */
export function thresholdLine(r: CivicDiagnosticResultDto): string {
    const seuil = `Seuil de référence : ${r.seuilReussite} / ${r.formatQuestions}.`;
    return r.posees === r.formatQuestions
        ? seuil
        : `${seuil} Il s'agit d'une estimation, pas d'une prédiction de réussite.`;
}

/** Le bloc des mises en situation (`20_` §4.5 bloc 3), verbatim. */
export const CIVIC_SITUATIONS_TITLE = "Mises en situation";
export const CIVIC_SITUATIONS_LABEL = "Application des règles";
export const CIVIC_SITUATIONS_TEXT =
    "Les mises en situation demandent d'appliquer les règles à un cas concret. "
    + "C'est souvent ce qui fait la différence à l'examen.";

/** « 4 réponses correctes sur 7 ». `null` quand aucune n'a été posée. */
export function situationsLine(r: CivicDiagnosticResultDto): string | null {
    if (r.situations.posees <= 0) return null;
    const {reussies, posees} = r.situations;
    return `${reussies} réponse${reussies > 1 ? "s" : ""} correcte`
        + `${reussies > 1 ? "s" : ""} sur ${posees}`;
}

/** Le titre du bloc 4, volontairement concret (`20_` §4.5). */
export const CIVIC_PRIORITES_TITLE = "Ce qui vous coûte le plus de points";

/**
 * 🛑 **Plafond d'AFFICHAGE, jamais un budget.** Le serveur classe *tous* les
 * thèmes sous l'objectif ; l'écran en montre trois et **compte** le reste.
 */
export const CIVIC_PRIORITES_VISIBLES = 3;

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
export const CIVIC_PLAN_TEASER_TITLE = "Votre plan Examen civique est prêt";

/**
 * « + 2 autres thèmes à consolider ».
 *
 * 🛑 **Un vrai nombre**, celui que le plafond d'affichage n'a pas montré —
 * jamais un « + d'autres » décoratif : le candidat doit pouvoir vérifier.
 * `null` quand la liste servie tient entière à l'écran.
 */
export function autresPrioritesLine(total: number): string | null {
    const reste = total - CIVIC_PRIORITES_VISIBLES;
    if (reste <= 0) return null;
    return `+ ${reste} autre${reste > 1 ? "s" : ""} thème${reste > 1 ? "s" : ""} à consolider`;
}

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
