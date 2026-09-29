package com.sejourfr.app.dto;

import java.util.List;
import java.util.Objects;

/**
 * Synthèse légère de la paire EE/EO, dérivée et bornée côté serveur.
 *
 * @param priorities        les priorités retenues, <b>plafonnées à 3</b> — règle
 *                          produit du diagnostic, à ne pas confondre avec le
 *                          nombre réel de compétences fragiles.
 * @param exempleCible      avant / après de la production ÉCRITE, produit par un
 *                          second appel LLM best-effort. <b>{@code null} est un
 *                          cas normal</b> : bloc absent ⇒ les fronts ne rendent
 *                          rien.
 * @param fragileSkillCount combien de compétences <b>distinctes</b> les deux
 *                          productions ont réellement montrées fragiles :
 *                          observation effective ({@code observed}) et statut
 *                          {@code PRIORITY} ou {@code TO_REINFORCE}, dédoublonnées
 *                          par code de compétence sur {@code written.skills} +
 *                          {@code oral.skills}. <b>Ce compte n'est pas plafonné</b>,
 *                          à la différence de {@code priorities} : c'est lui, et
 *                          lui seul, qui fait le « + N autres » des fronts. Le
 *                          calculer côté front donnerait deux nombres divergents
 *                          pour la même chose. {@code 0} est un état normal ⇒
 *                          aucun bloc « + N autres ».
 * @param solidSkillCount   idem pour les compétences observées {@code SOLID} —
 *                          le compte réel des points forts. {@code strengths},
 *                          lui, est plafonné à 3 <b>à l'écriture</b> du résumé et
 *                          ne peut donc porter aucun compteur.
 */
public record DiagnosticResultDto(
        DiagnosticProductionResultDto written,
        DiagnosticProductionResultDto oral,
        List<String> strengths,
        List<DiagnosticSkillObservationDto> priorities,
        String mainPriorityExplanation,
        PlanRecommendedExerciseDto nextAction,
        DiagnosticExempleCibleDto exempleCible,
        int fragileSkillCount,
        int solidSkillCount
) {
    public DiagnosticResultDto {
        // Critère d'acceptation du parcours : un résultat terminé donne
        // toujours une action immédiatement réalisable dans le catalogue.
        Objects.requireNonNull(nextAction, "nextAction");
    }
}
