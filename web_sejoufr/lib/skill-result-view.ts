// Règles de lecture de l'écran de résultat d'un petit sujet (module
// « Compétences TCF »).
//
// Elles vivent ici, pures et testées, pour la même raison que
// `lib/production-feedback.ts` : ce sont des décisions produit, pas de la mise
// en page. Deux d'entre elles ont été inversées par le client :
//
//   1. **l'analyse IA est le contenu principal**, dépliée sans clic — c'est le
//      retour que le candidat vient de mériter, il n'a pas à le déverrouiller ;
//   2. **les références comparatives sont repliées**, ouvrables à la demande —
//      elles servent à se comparer *après* avoir lu son propre retour.
//
// Le bandeau « Analyse IA du critère » ne subsiste donc que lorsqu'il n'y a
// rien à déplier : quota épuisé, production enregistrée sans analyse, analyse
// en échec. Un bandeau qui disparaîtrait dans ces cas-là ne dirait jamais au
// candidat ce qu'il rate.

/** Ce que l'écran de résultat rend à la place du retour IA. */
export type SkillResultAnalysisView =
    /** Analyse (ou transcription) en vol : indicateur d'attente. */
    | "PENDING"
    /** Analyse disponible : rendue **dépliée**, sans bandeau ni bouton. */
    | "ANALYSIS"
    /** Le pipeline a échoué : bandeau + relance de l'analyse. */
    | "FAILED"
    /** Analyses offertes épuisées : bandeau + offre. */
    | "LOCKED"
    /** Produite sans analyse alors qu'il en restait : bandeau + refaire. */
    | "MISSING";

/** Action portée par le bouton du bandeau, `null` quand il n'y a pas de
 *  bandeau (cas nominal et attente). */
export type SkillResultBannerAction = "RETRY" | "PAYWALL" | "REQUEST";

/**
 * `true` quand l'écran doit rendre le bandeau plutôt que le retour lui-même.
 * Un seul endroit décide, pour que le libellé et l'action ne puissent pas
 * diverger de ce qui est effectivement affiché.
 */
export function skillResultHasBanner(view: SkillResultAnalysisView): boolean {
    return view === "FAILED" || view === "LOCKED" || view === "MISSING";
}

/**
 * Ce que fait le bouton du bandeau. `null` = pas de bandeau : dans le cas
 * nominal l'analyse est là, dépliée, et il n'y a rien à déverrouiller.
 */
export function skillResultBannerAction(
    view: SkillResultAnalysisView,
): SkillResultBannerAction | null {
    switch (view) {
        case "FAILED":
            return "RETRY";
        case "LOCKED":
            return "PAYWALL";
        case "MISSING":
            return "REQUEST";
        default:
            return null;
    }
}

/**
 * Arbitre ce que montre la zone de retour IA.
 *
 * Priorités, dans l'ordre : l'attente (rien n'est encore décidé), puis
 * **l'analyse dès qu'elle existe** — la montrer vaut toujours mieux qu'un
 * bandeau, y compris sur une tentative marquée en échec après un premier
 * essai réussi —, puis l'échec, puis le verrou de quota.
 *
 * `analysisAllowed` est vrai tant que le quota d'analyses offertes n'est pas
 * épuisé (et toujours vrai pour un abonné, ou tant que le quota n'a pas été
 * chargé) : c'est ce qui distingue « tu n'y as plus droit » de « ta production
 * est partie sans analyse ».
 */
export function skillResultAnalysisView(input: {
    pending: boolean;
    hasAnalysis: boolean;
    failed: boolean;
    analysisAllowed: boolean;
}): SkillResultAnalysisView {
    if (input.hasAnalysis) return "ANALYSIS";
    if (input.pending) return "PENDING";
    if (input.failed) return "FAILED";
    return input.analysisAllowed ? "MISSING" : "LOCKED";
}

/**
 * Le retour de l'IA s'ouvre **déplié**. Déclaré ici plutôt qu'en dur dans le
 * composant : c'est la décision qu'on veut voir casser un test le jour où
 * quelqu'un la reinverse.
 */
export const ANALYSIS_OPEN_BY_DEFAULT = true;

/**
 * Les trois productions de référence s'ouvrent **repliées**. Elles restent à
 * un clic, avec une action explicite dans les deux sens.
 */
export const REFERENCES_OPEN_BY_DEFAULT = false;

/**
 * ...**sauf quand il n'y a pas d'analyse à lire** (quota épuisé, production
 * rendue sans analyse, analyse en échec) : les références sont alors le SEUL
 * retour de l'écran, et les replier laisserait le candidat devant une page qui
 * ne lui apprend rien. Parité mot pour mot avec le mobile.
 */
export function referencesOpenByDefault(view: SkillResultAnalysisView): boolean {
    return view === "ANALYSIS" ? REFERENCES_OPEN_BY_DEFAULT : true;
}
