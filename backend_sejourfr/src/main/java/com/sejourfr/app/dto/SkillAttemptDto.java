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
 */
public record SkillAttemptDto(
        UUID id,
        UUID skillPromptId,
        String skillPromptCode,
        SkillAttemptStatut statut,
        boolean analysisRequested,
        String writtenProduction,
        /** URL R2 PRESIGNEE a TTL court, jamais la cle d'objet brute. */
        String audioUrl,
        Integer audioDurationSec,
        /** Transcription Whisper : uniquement a l'oral ET analyse demandee. */
        String transcript,
        Integer wordsCount,
        SkillSelfEvaluation selfEvaluation,
        SkillCriterionStatus criterionStatus,
        SkillAnalysisDto analysis,
        String errorMessage,
        Instant createdAt
) {
}
