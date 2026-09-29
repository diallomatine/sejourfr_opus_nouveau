/**
 * Le bloc 6 du rapport court : **la prochaine action** (`10_` §8.2).
 *
 * > « [6. Prochaine action] **JAMAIS un simple « Retour »** »
 *
 * 🛑 **Rien n'est dérivé ici.** Le verdict (`SkillCriterionStatus`) arrive
 * **servi** par le serveur, qui l'a lui-même reçu du correcteur sous contrat.
 * Ce fichier ne fait que le mettre en mots et désigner l'action correspondante.
 * Aucun front ne classe un résultat en état pédagogique — c'est l'invariant du
 * dépôt, et il vaut ici comme ailleurs.
 *
 * 🛑 **Aucun niveau CECRL n'apparaît** dans ces phrases : `10_` §8.2 l'interdit
 * explicitement sur un exercice de deux phrases. Le palier, quand il est
 * mesuré, vit dans la carte de niveau, au-dessus.
 *
 * Miroir de
 * `mobile_sejourfr/lib/screens/tcf_production/competences/competence_next_action.dart`.
 */
import type {SkillCriterionStatus} from "./types";

/** Ce que la carte de fin propose. `SUJET_SUIVANT` est le défaut de travail. */
export type CompetenceNextKind = "REESSAYER" | "SUJET_SUIVANT" | "PLAN";

export interface CompetenceNextAction {
    /** Le titre de la carte. Il dit où en est le candidat, pas ce qu'il a raté. */
    title: string;
    /** Une phrase, jamais deux : c'est une porte de sortie, pas un cours. */
    hint: string;
    /** Le libellé du bouton principal. Jamais « Retour ». */
    cta: string;
    kind: CompetenceNextKind;
}

/**
 * @param status         le verdict servi pour cette tentative
 * @param hasNextPrompt  reste-t-il un sujet à traiter sur cette compétence ?
 *                       🛑 Sans sujet suivant, on ne propose pas d'en ouvrir
 *                       un : un bouton qui ne mène nulle part est pire qu'un
 *                       bouton absent.
 */
export function competenceNextAction(
    status: SkillCriterionStatus,
    hasNextPrompt: boolean,
): CompetenceNextAction {
    switch (status) {
        case "NOT_VALIDATED":
            // Le critère n'est pas atteint : on rejoue LE MÊME point, on ne
            // pousse pas vers la suite. Enchaîner un sujet de plus sur une
            // compétence non acquise empile des échecs.
            return {
                title: "Essayez encore une fois",
                hint: "Reprenez ce point précis : c'est en le rejouant qu'il s'installe.",
                cta: "S'entraîner sur ce point",
                kind: "REESSAYER",
            };
        case "PARTIAL":
            return hasNextPrompt
                ? {
                      title: "🎉 Cette compétence progresse",
                      hint: "Un sujet de plus sur la même compétence, et elle sera acquise.",
                      cta: "Passer au sujet suivant",
                      kind: "SUJET_SUIVANT",
                  }
                : {
                      title: "🎉 Cette compétence progresse",
                      hint: "Vous avez traité tous les sujets de cette compétence.",
                      cta: "Continuer mon plan",
                      kind: "PLAN",
                  };
        case "VALIDATED":
            return {
                title: "✅ Compétence maîtrisée",
                hint: "Votre plan vous emmène maintenant sur la priorité suivante.",
                cta: "Continuer mon plan",
                kind: "PLAN",
            };
    }
}
