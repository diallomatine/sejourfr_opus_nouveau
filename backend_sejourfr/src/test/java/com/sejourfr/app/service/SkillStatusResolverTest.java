package com.sejourfr.app.service;

import com.sejourfr.app.entity.UserSkillAttempt;
import com.sejourfr.app.enums.SkillAttemptStatut;
import com.sejourfr.app.enums.SkillCriterionStatus;
import com.sejourfr.app.enums.SkillPromptStatus;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Les cinq regles de derivation du statut d'un sujet, plus le cas « analyse
 * acceptee mais pas encore aboutie ».
 *
 * <p>Le principe verifie ici : <b>on n'affiche jamais un verdict qu'on n'a
 * pas</b>. Toutes les situations sans jugement de critere retombent sur
 * {@code TREATED}, jamais sur {@code TO_REINFORCE} — qui serait faux et
 * decourageant.
 */
class SkillStatusResolverTest {

    private final SkillStatusResolver resolver = new SkillStatusResolver();

    @Test
    void noAttemptIsTodo() {
        assertThat(resolver.resolve(null)).isEqualTo(SkillPromptStatus.TODO);
    }

    @Test
    void productionWithoutAnalysisIsTreated() {
        UserSkillAttempt attempt = attempt(SkillAttemptStatut.RECORDED, false, null);

        assertThat(resolver.resolve(attempt)).isEqualTo(SkillPromptStatus.TREATED);
    }

    @Test
    void analysedAndValidatedIsValidated() {
        UserSkillAttempt attempt = attempt(
                SkillAttemptStatut.EVALUATED, true, SkillCriterionStatus.VALIDATED);

        assertThat(resolver.resolve(attempt)).isEqualTo(SkillPromptStatus.VALIDATED);
    }

    @Test
    void analysedAndPartialIsToReinforce() {
        UserSkillAttempt attempt = attempt(
                SkillAttemptStatut.EVALUATED, true, SkillCriterionStatus.PARTIAL);

        assertThat(resolver.resolve(attempt)).isEqualTo(SkillPromptStatus.TO_REINFORCE);
    }

    @Test
    void analysedAndNotValidatedIsToReinforce() {
        UserSkillAttempt attempt = attempt(
                SkillAttemptStatut.EVALUATED, true, SkillCriterionStatus.NOT_VALIDATED);

        assertThat(resolver.resolve(attempt)).isEqualTo(SkillPromptStatus.TO_REINFORCE);
    }

    @Test
    void failedAnalysisIsTreatedNotToReinforce() {
        // La panne vient de nous ou du fournisseur : on ne la fait pas payer au
        // candidat en le classant « à renforcer ».
        UserSkillAttempt attempt = attempt(SkillAttemptStatut.FAILED, true, null);

        assertThat(resolver.resolve(attempt)).isEqualTo(SkillPromptStatus.TREATED);
    }

    @Test
    void failedAnalysisIsTreatedEvenIfAVerdictWasPersistedBefore() {
        UserSkillAttempt attempt = attempt(
                SkillAttemptStatut.FAILED, true, SkillCriterionStatus.VALIDATED);

        assertThat(resolver.resolve(attempt)).isEqualTo(SkillPromptStatus.TREATED);
    }

    @Test
    void analysisInFlightIsTreated() {
        assertThat(resolver.resolve(attempt(SkillAttemptStatut.SUBMITTED, true, null)))
                .isEqualTo(SkillPromptStatus.TREATED);
        assertThat(resolver.resolve(attempt(SkillAttemptStatut.TRANSCRIBING, true, null)))
                .isEqualTo(SkillPromptStatus.TREATED);
        assertThat(resolver.resolve(attempt(SkillAttemptStatut.EVALUATING, true, null)))
                .isEqualTo(SkillPromptStatus.TREATED);
    }

    @Test
    void everyStatusButTodoCountsAsAttempted() {
        assertThat(SkillPromptStatus.TODO.isAttempted()).isFalse();
        assertThat(SkillPromptStatus.TREATED.isAttempted()).isTrue();
        assertThat(SkillPromptStatus.VALIDATED.isAttempted()).isTrue();
        assertThat(SkillPromptStatus.TO_REINFORCE.isAttempted()).isTrue();
    }

    private static UserSkillAttempt attempt(SkillAttemptStatut statut,
                                            boolean analysisRequested,
                                            SkillCriterionStatus criterion) {
        UserSkillAttempt attempt = new UserSkillAttempt();
        attempt.setStatut(statut);
        attempt.setAnalysisRequested(analysisRequested);
        attempt.setCriterionStatus(criterion);
        return attempt;
    }
}
