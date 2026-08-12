package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.SkillDto;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.enums.SkillMasteryState;
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
     * {@code locked} et {@code masteryState} sont passes, pas devines : la regle
     * d'acces appartient a {@code SkillAccessService}, l'etat de maitrise a
     * {@code SkillMasteryEngine}, et tous deux se resolvent une fois pour toute
     * une liste. Un mapper qui irait les chercher lui-meme rendrait une requete
     * par competence.
     */
    public SkillDto toDto(Skill skill,
                          int promptCount,
                          int attemptedCount,
                          int validatedCount,
                          int toReinforceCount,
                          SkillMasteryState masteryState,
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
                masteryState,
                locked);
    }
}
