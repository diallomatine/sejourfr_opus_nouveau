package com.sejourfr.app.dto;

import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.enums.ObservationConfidence;

import java.time.Instant;

/**
 * Un point de la <b>frise</b> d'une competence : ce qui a ete constate, quand,
 * et dans quoi.
 *
 * <p>C'est ce qui rend la progression comprehensible — « Diagnostic : priorite,
 * Entrainement : progres, Nouvelle tache : a renforcer, Examen blanc : solide »
 * dit infiniment plus au candidat qu'un pourcentage. Le score interne du moteur
 * n'y figure evidemment pas.
 *
 * <p>{@link #status} est le verdict <b>de cette production-la</b>
 * ({@code LearningPlanSkillStatus}), a ne pas confondre avec l'etat agrege de la
 * competence ({@code SkillMasteryState}) porte par {@code SkillDto}. Seules les
 * observations <b>probantes</b> figurent ici : un « pas observable dans cette
 * production » n'est pas une etape du parcours.
 */
public record SkillObservationPointDto(
        Instant observedAt,
        LearningPlanSourceType source,
        LearningPlanSkillStatus status,
        /** L'explication courte du correcteur, telle qu'elle a ete enregistree. */
        String explanation,
        ObservationConfidence confidence,
        /** {@code true} pour les deux productions du diagnostic initial : le point de depart. */
        boolean baseline
) {
}
