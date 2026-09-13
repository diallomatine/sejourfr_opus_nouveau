package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.SkillPromptDto;
import com.sejourfr.app.dto.SkillPromptSummaryDto;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.SkillPrompt;
import com.sejourfr.app.enums.SkillPromptStatus;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.util.ExerciseDuration;
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
     *
     * <p>{@code lastAttemptAt} et {@code lastAttemptId} viennent de la
     * <b>meme</b> tentative — celle qui a servi a deriver {@code status}. Les
     * chercher ici couterait une requete par sujet.
     */
    public SkillPromptSummaryDto toSummaryDto(SkillPrompt prompt,
                                              SkillPromptStatus status,
                                              int attemptCount,
                                              Instant lastAttemptAt,
                                              UUID lastAttemptId,
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
                estimatedMinutes(prompt),
                status,
                attemptCount,
                lastAttemptAt,
                lastAttemptId,
                locked);
    }

    /**
     * Le temps qu'un sujet demande, en minutes.
     *
     * <p>🛑 <b>{@link ExerciseDuration} et rien d'autre</b> : c'est deja
     * l'autorite du Plan pour la meme question, et deux formules auraient fini
     * par annoncer deux temps differents pour le meme exercice. L'epreuve se lit
     * sur la <b>section du sujet</b> (EO ⇒ temps de parole, EE ⇒ fourchette de
     * mots), jamais sur la nullite d'une colonne.
     */
    private int estimatedMinutes(SkillPrompt prompt) {
        return prompt.getSection() == SkillSection.EO
                ? ExerciseDuration.oral(prompt.getRecommendedDurationSeconds())
                : ExerciseDuration.written(
                        prompt.getRecommendedMinWords(), prompt.getRecommendedMaxWords());
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
                // Nul impossible en pratique — seule une competence
                // d'EXPRESSION porte des sujets, et la base exige alors une
                // tache. On ne deréférence pas pour autant : la colonne est
                // nullable depuis V039, et un NPE ici couterait l'ecran de
                // production entier.
                skill.getTaskCode() == null ? null : skill.getTaskCode().getTitle(),
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
