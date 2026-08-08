package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.AdminSkillDto;
import com.sejourfr.app.dto.AdminSkillPromptDto;
import com.sejourfr.app.dto.AdminSkillStatsDto;
import com.sejourfr.app.dto.SkillReferenceDto;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.SkillPrompt;
import com.sejourfr.app.entity.SkillReference;
import com.sejourfr.app.manager.UserSkillAttemptManager.SkillUsage;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * Mapper pur de la surface admin. Distinct de {@link SkillMapper} et
 * {@link SkillPromptMapper}, qui servent la vue CANDIDAT : celle-ci masque les
 * contenus desactives et ne montre jamais les references, celle-la montre tout
 * et ajoute {@code active} et les horodatages. Fusionner les deux aurait
 * demande un drapeau « je suis admin » dans chaque signature, et une erreur
 * d'appel aurait fuite des references a un candidat qui n'a pas encore produit.
 *
 * <p>Compteurs et agregats sont passes en parametres : ils se calculent en une
 * requete pour toute une page, les chercher ici en ferait une par ligne.
 */
@Component
@RequiredArgsConstructor
public class AdminSkillMapper {

    private final SkillReferenceMapper referenceMapper;

    public AdminSkillDto toDto(Skill skill, long promptCount) {
        return new AdminSkillDto(
                skill.getId(),
                skill.getSection(),
                skill.getTaskCode(),
                skill.getCode(),
                skill.getTitle(),
                skill.getDescription(),
                skill.getGeneralCriterion(),
                skill.getTargetLevel(),
                skill.getDisplayOrder(),
                skill.isActive(),
                promptCount,
                skill.getCreatedAt(),
                skill.getUpdatedAt());
    }

    /**
     * {@code skill} est passe explicitement pour rendre visible qu'il doit avoir
     * ete charge en amont (JOIN FETCH ou parent deja en main) : le lire depuis
     * la relation paresseuse ferait une requete de plus par sujet.
     *
     * <p>{@code references} arrive deja triee dans l'ordre pedagogique par le
     * manager — un tri alphabetique placerait « EXCELLENT » avant « EXPECTED ».
     */
    public AdminSkillPromptDto toPromptDto(SkillPrompt prompt,
                                           Skill skill,
                                           List<SkillReference> references,
                                           long attemptCount) {
        List<SkillReferenceDto> referenceDtos = references.stream()
                .map(referenceMapper::toDto)
                .toList();
        return new AdminSkillPromptDto(
                prompt.getId(),
                skill.getId(),
                skill.getCode(),
                prompt.getSection(),
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
                prompt.isActive(),
                referenceDtos,
                attemptCount,
                prompt.getCreatedAt(),
                prompt.getUpdatedAt());
    }

    /**
     * Statistiques d'une competence. Le taux de validation reste <b>nul</b> tant
     * qu'aucune tentative n'a ete analysee : « 0 % » se lirait « les candidats
     * echouent » la ou la verite est « personne n'a encore fait analyser ».
     */
    public AdminSkillStatsDto toStatsDto(Skill skill, long promptCount, SkillUsage usage) {
        Double validatedRate = usage.analysed() == 0
                ? null
                : (double) usage.validated() / usage.analysed();
        return new AdminSkillStatsDto(
                skill.getId(),
                skill.getCode(),
                skill.getTitle(),
                skill.getSection(),
                skill.getTaskCode(),
                promptCount,
                usage.attempts(),
                usage.analysed(),
                validatedRate);
    }
}
