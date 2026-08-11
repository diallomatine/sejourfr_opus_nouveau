package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.SkillPromptDto;
import com.sejourfr.app.dto.SkillPromptSummaryDto;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.SkillPrompt;
import com.sejourfr.app.enums.SkillPromptStatus;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.UUID;

/**
 * Mapper pur pour les petits sujets. Le statut, les compteurs et les
 * identifiants de navigation sont fournis par le service : ils dependent du
 * candidat courant et se calculent pour toute une liste a la fois.
 *
 * <p>Ni {@link #toSummaryDto} ni {@link #toDto} ne renvoient les references :
 * elles ont leur propre route, gardee, et ne sont revelees qu'apres la
 * production.
 */
@Component
public class SkillPromptMapper {

    /**
     * Carte de sujet dans la liste d'une competence. {@code locked} est
     * <b>passe</b>, resolu une seule fois pour les sujets de l'ecran : la
     * regle d'acces appartient a {@code SkillAccessService}.
     */
    public SkillPromptSummaryDto toSummaryDto(SkillPrompt prompt,
                                              SkillPromptStatus status,
                                              int attemptCount,
                                              Instant lastAttemptAt,
                                              boolean locked) {
        return new SkillPromptSummaryDto(
                prompt.getId(),
                prompt.getCode(),
                prompt.getTitle(),
                prompt.getUniqueCriterion(),
                prompt.getDifficultyLevel(),
                prompt.getDisplayOrder(),
                prompt.getRecommendedMinWords(),
                prompt.getRecommendedMaxWords(),
                prompt.getRecommendedDurationSeconds(),
                status,
                attemptCount,
                lastAttemptAt,
                locked);
    }

    /**
     * Sujet complet pour l'ecran de production. {@code skill} est passe
     * explicitement pour rendre visible qu'il doit avoir ete charge en amont
     * (JOIN FETCH) : le lire depuis la relation paresseuse ferait une requete
     * de plus a chaque appel.
     */
    public SkillPromptDto toDto(SkillPrompt prompt,
                                Skill skill,
                                int skillPromptCount,
                                SkillPromptStatus status,
                                int attemptCount,
                                Instant lastAttemptAt,
                                UUID lastAttemptId,
                                UUID nextPromptId,
                                boolean locked) {
        return new SkillPromptDto(
                prompt.getId(),
                skill.getId(),
                skill.getCode(),
                skill.getTitle(),
                skillPromptCount,
                skill.getDescription(),
                skill.getGeneralCriterion(),
                skill.getTargetLevel(),
                prompt.getSection(),
                skill.getTaskCode(),
                skill.getTaskCode().getTitle(),
                prompt.getCode(),
                prompt.getTitle(),
                prompt.getContext(),
                prompt.getInstruction(),
                prompt.getUniqueCriterion(),
                prompt.getChecklist(),
                prompt.getConstraintTags(),
                prompt.getAnswerStarter(),
                prompt.getTip(),
                prompt.getRecommendedMinWords(),
                prompt.getRecommendedMaxWords(),
                prompt.getRecommendedDurationSeconds(),
                prompt.getDifficultyLevel(),
                prompt.getDisplayOrder(),
                status,
                attemptCount,
                lastAttemptAt,
                lastAttemptId,
                nextPromptId,
                locked);
    }
}
