package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.SkillDto;
import com.sejourfr.app.entity.Skill;
import org.springframework.stereotype.Component;

/**
 * Mapper pur {@link Skill} -&gt; {@link SkillDto}. Les compteurs de progression
 * sont passes en parametres : ils dependent du candidat courant et se calculent
 * en une seule requete pour toute une liste — les faire chercher ici
 * declencherait une requete par competence.
 */
@Component
public class SkillMapper {

    /**
     * {@code locked} est passe, pas devine : la regle d'acces appartient a
     * {@code SkillAccessService} et se resout une fois pour toute une liste.
     */
    public SkillDto toDto(Skill skill,
                          int promptCount,
                          int attemptedCount,
                          int validatedCount,
                          int toReinforceCount,
                          boolean locked) {
        return new SkillDto(
                skill.getId(),
                skill.getSection(),
                skill.getTaskCode(),
                skill.getCode(),
                skill.getTitle(),
                skill.getDescription(),
                skill.getGeneralCriterion(),
                skill.getTargetLevel(),
                skill.getDisplayOrder(),
                promptCount,
                attemptedCount,
                validatedCount,
                toReinforceCount,
                locked);
    }
}
