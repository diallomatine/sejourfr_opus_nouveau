package com.sejourfr.app.dto;

import com.sejourfr.app.enums.SkillAttemptStatut;
import com.sejourfr.app.enums.SkillCriterionStatus;
import com.sejourfr.app.enums.SkillSelfEvaluation;

import java.time.Instant;
import java.util.UUID;

/**
 * Vue front d'une {@link com.sejourfr.app.entity.UserSkillAttempt}.
 *
 * <p>{@code analysis} reste nul tant que le pipeline n'a pas abouti, et
 * definitivement nul quand aucune analyse n'a ete demandee (statut
 * {@code RECORDED}) : c'est le cas nominal du parcours gratuit, pas une erreur.
 *
 * <p><b>Aucune URL audio</b> : l'enregistrement d'un candidat n'est pas
 * conserve. Ce que rend une production orale, c'est {@code transcript}.
 */
public record SkillAttemptDto(
        UUID id,
        UUID skillPromptId,
        String skillPromptCode,
        SkillAttemptStatut statut,
        boolean analysisRequested,
        String writtenProduction,
        /**
         * Duree de l'enregistrement, en secondes. C'est la seule trace qui
         * subsiste de l'audio : il n'est pas conserve, donc aucune URL n'est
         * servie et aucun ecran ne propose de se reecouter.
         */
        Integer audioDurationSec,
        /**
         * Transcription Whisper — <b>la production orale conservee</b>, ecrite
         * systematiquement des la soumission (analyse demandee ou non).
         */
        String transcript,
        Integer wordsCount,
        SkillSelfEvaluation selfEvaluation,
        SkillCriterionStatus criterionStatus,
        SkillAnalysisDto analysis,
        String errorMessage,
        Instant createdAt
) {
}
