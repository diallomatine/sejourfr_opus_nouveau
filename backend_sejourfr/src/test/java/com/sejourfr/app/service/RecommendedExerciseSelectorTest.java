package com.sejourfr.app.service;

import com.sejourfr.app.dto.PlanRecommendedExerciseDto;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.SkillPrompt;
import com.sejourfr.app.entity.UserSkillAttempt;
import com.sejourfr.app.enums.SkillAttemptStatut;
import com.sejourfr.app.enums.SkillCriterionStatus;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.manager.SkillPromptManager;
import com.sejourfr.app.manager.UserSkillAttemptManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyCollection;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class RecommendedExerciseSelectorTest {

    private SkillPromptManager promptManager;
    private UserSkillAttemptManager attemptManager;
    private RecommendedExerciseSelector selector;
    private final UUID userId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        promptManager = mock(SkillPromptManager.class);
        attemptManager = mock(UserSkillAttemptManager.class);
        selector = new RecommendedExerciseSelector(
                promptManager, attemptManager, new SkillStatusResolver());
    }

    @Test
    void proposeLePremierSujetJamaisTente() {
        Skill skill = skill(SkillSection.EE);
        SkillPrompt first = prompt(skill, (short) 1);
        SkillPrompt second = prompt(skill, (short) 2);
        SkillPrompt third = prompt(skill, (short) 3);
        stub(skill, List.of(first, second, third), Map.of(
                first.getId(), attempt(first, SkillCriterionStatus.VALIDATED, minutesAgo(10)),
                second.getId(), attempt(second, SkillCriterionStatus.VALIDATED, minutesAgo(5))));

        assertThat(selector.select(userId, skill))
                .get().extracting(PlanRecommendedExerciseDto::skillPromptId)
                .isEqualTo(third.getId());
    }

    @Test
    void toutTenteRenvoieLeSujetAReenforcerLePlusAncien() {
        Skill skill = skill(SkillSection.EE);
        SkillPrompt first = prompt(skill, (short) 1);
        SkillPrompt second = prompt(skill, (short) 2);
        SkillPrompt third = prompt(skill, (short) 3);
        stub(skill, List.of(first, second, third), Map.of(
                // Le rang 1 est le plus ancien de tous, mais il est validé : ce
                // n'est pas lui qu'il faut refaire.
                first.getId(), attempt(first, SkillCriterionStatus.VALIDATED, minutesAgo(90)),
                second.getId(), attempt(second, SkillCriterionStatus.NOT_VALIDATED, minutesAgo(10)),
                third.getId(), attempt(third, SkillCriterionStatus.PARTIAL, minutesAgo(60))));

        assertThat(selector.select(userId, skill))
                .get().extracting(PlanRecommendedExerciseDto::skillPromptId)
                .isEqualTo(third.getId());
    }

    @Test
    void toutTenteSansSujetAReenforcerRenvoieLeSujetTenteLePlusAnciennement() {
        Skill skill = skill(SkillSection.EE);
        SkillPrompt first = prompt(skill, (short) 1);
        SkillPrompt second = prompt(skill, (short) 2);
        stub(skill, List.of(first, second), Map.of(
                first.getId(), attempt(first, SkillCriterionStatus.VALIDATED, minutesAgo(5)),
                second.getId(), attempt(second, SkillCriterionStatus.VALIDATED, minutesAgo(80))));

        assertThat(selector.select(userId, skill))
                .get().extracting(PlanRecommendedExerciseDto::skillPromptId)
                .isEqualTo(second.getId());
    }

    @Test
    void sansSujetActifAucunExerciceNestInvente() {
        Skill skill = skill(SkillSection.EE);
        stub(skill, List.of(), Map.of());

        assertThat(selector.select(userId, skill)).isEmpty();
    }

    @Test
    void laDureeOraleSuitLeTempsDeParoleConseilleEtSonRepli() {
        Skill skill = skill(SkillSection.EO);
        SkillPrompt mesure = prompt(skill, (short) 1);
        mesure.setRecommendedDurationSeconds(45);
        SkillPrompt sansDonnee = prompt(skill, (short) 2);

        assertThat(RecommendedExerciseSelector.estimatedMinutes(mesure, SkillSection.EO))
                .isEqualTo(3);
        assertThat(RecommendedExerciseSelector.estimatedMinutes(sansDonnee, SkillSection.EO))
                .isEqualTo(5);
    }

    @Test
    void laDureeEcriteSuitLaFourchetteDeMotsEtSonRepli() {
        Skill skill = skill(SkillSection.EE);
        SkillPrompt fourchette = prompt(skill, (short) 1);
        fourchette.setRecommendedMinWords(40);
        fourchette.setRecommendedMaxWords(80);
        SkillPrompt uneSeuleBorne = prompt(skill, (short) 2);
        uneSeuleBorne.setRecommendedMaxWords(30);
        SkillPrompt sansDonnee = prompt(skill, (short) 3);

        // (40 + 80) / 2 = 60 mots à 12 mots/minute.
        assertThat(RecommendedExerciseSelector.estimatedMinutes(fourchette, SkillSection.EE))
                .isEqualTo(5);
        assertThat(RecommendedExerciseSelector.estimatedMinutes(uneSeuleBorne, SkillSection.EE))
                .isEqualTo(3);
        assertThat(RecommendedExerciseSelector.estimatedMinutes(sansDonnee, SkillSection.EE))
                .isEqualTo(4);
    }

    @Test
    void laDureeNestJamaisNulle() {
        Skill skill = skill(SkillSection.EO);
        SkillPrompt tresCourt = prompt(skill, (short) 1);
        tresCourt.setRecommendedDurationSeconds(1);

        assertThat(RecommendedExerciseSelector.estimatedMinutes(tresCourt, SkillSection.EO))
                .isEqualTo(1);
    }

    @Test
    void lExerciceRenvoyePorteLaDureeDuSujetRetenu() {
        Skill skill = skill(SkillSection.EO);
        SkillPrompt only = prompt(skill, (short) 1);
        only.setRecommendedDurationSeconds(30);
        stub(skill, List.of(only), Map.of());

        assertThat(selector.select(userId, skill))
                .get().extracting(PlanRecommendedExerciseDto::estimatedMinutes)
                .isEqualTo(2);
    }

    private void stub(Skill skill, List<SkillPrompt> prompts,
                      Map<UUID, UserSkillAttempt> latestByPrompt) {
        Map<UUID, List<SkillPrompt>> bySkill = new LinkedHashMap<>();
        bySkill.put(skill.getId(), prompts);
        when(promptManager.findActiveBySkillIds(anyCollection())).thenReturn(bySkill);
        when(attemptManager.findLatestPerPromptBySkillIds(eq(userId), anyCollection()))
                .thenReturn(new LinkedHashMap<>(latestByPrompt));
    }

    private static Instant minutesAgo(int minutes) {
        return Instant.now().minusSeconds(minutes * 60L);
    }

    private static Skill skill(SkillSection section) {
        Skill skill = new Skill();
        skill.setId(UUID.randomUUID());
        skill.setCode(section == SkillSection.EO ? "EO1-C1" : "EE1-C1");
        skill.setTitle("Compétence de test");
        skill.setSection(section);
        skill.setActive(true);
        return skill;
    }

    private static SkillPrompt prompt(Skill skill, short displayOrder) {
        SkillPrompt prompt = new SkillPrompt();
        prompt.setId(UUID.randomUUID());
        prompt.setSkill(skill);
        prompt.setSection(skill.getSection());
        prompt.setTitle("Sujet " + displayOrder);
        prompt.setDisplayOrder(displayOrder);
        prompt.setActive(true);
        return prompt;
    }

    private static UserSkillAttempt attempt(
            SkillPrompt prompt, SkillCriterionStatus criterion, Instant createdAt) {
        UserSkillAttempt attempt = new UserSkillAttempt();
        attempt.setId(UUID.randomUUID());
        attempt.setSkillPrompt(prompt);
        attempt.setAnalysisRequested(true);
        attempt.setStatut(SkillAttemptStatut.EVALUATED);
        attempt.setCriterionStatus(criterion);
        attempt.setCreatedAt(createdAt);
        return attempt;
    }

    /** Garde-fou : la compétence absente ne doit pas faire échouer la lecture. */
    @Test
    void uneCompetenceNulleNeCasseRien() {
        assertThat(selector.select(userId, null)).isEqualTo(Optional.empty());
        assertThat(selector.selectAll(userId, List.of())).isEmpty();
        verifyNoInteraction();
    }

    private void verifyNoInteraction() {
        org.mockito.Mockito.verify(promptManager, org.mockito.Mockito.never())
                .findActiveBySkillIds(any());
    }
}
