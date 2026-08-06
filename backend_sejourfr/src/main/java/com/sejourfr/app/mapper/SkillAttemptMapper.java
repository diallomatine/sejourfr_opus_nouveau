package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.SkillAnalysisDto;
import com.sejourfr.app.dto.SkillAttemptDto;
import com.sejourfr.app.entity.UserSkillAttempt;
import com.sejourfr.app.enums.SkillCriterionStatus;
import com.sejourfr.app.service.ProductionAudioStorageService;
import com.sejourfr.app.service.competence.CompetenceAnalysisFields;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Map;

/**
 * Mapper {@link UserSkillAttempt} -&gt; {@link SkillAttemptDto}.
 *
 * <p>{@link #toDto} laisse {@code audioUrl} a {@code null} : la cle d'objet R2
 * brute ne doit jamais sortir du backend. {@link #toDtoWithSignedAudio} est la
 * seule variante qui expose l'audio, via une URL presignee a TTL court —
 * meme decoupage que {@code ProductionSubmissionMapper}, pour ne pas payer un
 * aller-retour R2 quand l'appelant n'a pas besoin d'ecouter.
 */
@Component
@RequiredArgsConstructor
public class SkillAttemptMapper {

    private final ProductionAudioStorageService audioStorage;

    public SkillAttemptDto toDto(UserSkillAttempt attempt) {
        return build(attempt, null);
    }

    /** Variante qui expose l'audio via une URL signee (TTL court). */
    public SkillAttemptDto toDtoWithSignedAudio(UserSkillAttempt attempt) {
        String key = attempt.getAudioObjectKey();
        if (key == null || key.isBlank()) {
            return build(attempt, null);
        }
        return build(attempt, audioStorage.presignGet(key));
    }

    private SkillAttemptDto build(UserSkillAttempt attempt, String audioUrl) {
        return new SkillAttemptDto(
                attempt.getId(),
                attempt.getSkillPrompt().getId(),
                attempt.getSkillPrompt().getCode(),
                attempt.getStatut(),
                attempt.isAnalysisRequested(),
                attempt.getWrittenProduction(),
                audioUrl,
                attempt.getAudioDurationSec(),
                attempt.getTranscript(),
                attempt.getWordsCount(),
                attempt.getSelfEvaluation(),
                attempt.getCriterionStatus(),
                toAnalysisDto(attempt),
                attempt.getErrorMessage(),
                attempt.getCreatedAt());
    }

    /**
     * Traduit le JSON persiste en DTO. Renvoie {@code null} tant qu'aucune
     * analyse n'a abouti — cas nominal du parcours gratuit, pas une erreur.
     *
     * <p>Le verdict expose est la colonne {@code criterion_status} et non la
     * cle {@code status} du JSON : c'est la colonne qui fait foi (c'est elle qui
     * derive le statut du sujet), et une seule source d'affichage evite qu'un
     * front lise une valeur et le calcul de progression une autre.
     */
    private SkillAnalysisDto toAnalysisDto(UserSkillAttempt attempt) {
        Map<String, Object> json = attempt.getAnalysisJson();
        if (json == null || json.isEmpty()) return null;
        SkillCriterionStatus status = attempt.getCriterionStatus() != null
                ? attempt.getCriterionStatus()
                : SkillCriterionStatus.parse(json.get(CompetenceAnalysisFields.STATUS));
        return new SkillAnalysisDto(
                status,
                text(json, CompetenceAnalysisFields.VERDICT),
                text(json, CompetenceAnalysisFields.SUCCESS_POINT),
                text(json, CompetenceAnalysisFields.IMPROVEMENT_PRIORITY),
                text(json, CompetenceAnalysisFields.IMPROVED_VERSION));
    }

    private static String text(Map<String, Object> json, String key) {
        Object raw = json.get(key);
        return raw == null ? null : raw.toString();
    }
}
