package com.sejourfr.app.service;

import com.sejourfr.app.dto.AttemptResponse;
import com.sejourfr.app.dto.StartAttemptRequest;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.AccessDeniedException;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Démarrage d'attempts TRAINING (libre + lots). DB réelle : le tirage des
 * questions s'appuie sur le pool seedé par les migrations (civique + TCF).
 */
class AttemptServiceTrainingIT extends AbstractIntegrationTest {

    @Autowired AttemptService service;
    @Autowired TestData data;
    @Autowired AttemptManager attemptManager;

    private StartAttemptRequest training(Module module, UUID themeId, Difficulty difficulty,
                                         QuestionType qType, Integer size, Integer lotNumero) {
        return new StartAttemptRequest(AttemptType.TRAINING, module, null, themeId,
                difficulty, qType, size, lotNumero, null, null);
    }

    private void makePremium(User user) {
        data.userSubscription(user, data.plan());
    }

    @Test
    void startTraining_compteGratuit_tireLaSerieDemoDeTailleDemandee() {
        User user = data.user();

        AttemptResponse r = service.start(user.getId(), training(Module.CIVIQUE, null, null, null, 5, null));

        assertThat(r.type()).isEqualTo(AttemptType.TRAINING);
        assertThat(r.module()).isEqualTo(Module.CIVIQUE);
        assertThat(r.totalQuestions()).isEqualTo(5);
        assertThat(r.questions()).hasSize(5);
        assertThat(r.finishedAt()).isNull();
        assertThat(r.score()).isNull();
    }

    @Test
    void startTraining_compteGratuit_plafonneLaTailleAuMaxGratuit() {
        User user = data.user();

        // 50 demandé mais le plafond gratuit est 20.
        AttemptResponse r = service.start(user.getId(), training(Module.CIVIQUE, null, null, null, 50, null));

        assertThat(r.totalQuestions()).isEqualTo(20);
    }

    @Test
    void startTraining_premium_tireDansLePoolAleatoire() {
        User user = data.user();
        makePremium(user);

        AttemptResponse r = service.start(user.getId(), training(Module.CIVIQUE, null, null, null, 12, null));

        assertThat(r.totalQuestions()).isEqualTo(12);
        assertThat(r.questions()).hasSize(12);
    }

    @Test
    void startFromLot_tcfLot1_gratuit_ok() {
        User user = data.user();

        AttemptResponse r = service.start(user.getId(),
                training(Module.TCF, null, Difficulty.B1, QuestionType.CE, null, 1));

        assertThat(r.type()).isEqualTo(AttemptType.TRAINING);
        assertThat(r.module()).isEqualTo(Module.TCF);
        assertThat(r.totalQuestions()).isEqualTo(20);

        Attempt persisted = attemptManager.findById(r.id()).orElseThrow();
        assertThat(persisted.getLotNumero()).isEqualTo(1);
        assertThat(persisted.getLotDifficulty()).isEqualTo(Difficulty.B1);
        assertThat(persisted.getLotQuestionType()).isEqualTo(QuestionType.CE);
    }

    @Test
    void startFromLot_lot2_compteGratuit_refuse() {
        User user = data.user();

        assertThatThrownBy(() -> service.start(user.getId(),
                training(Module.TCF, null, Difficulty.B1, QuestionType.CE, null, 2)))
                .isInstanceOf(AccessDeniedException.class);
    }

    @Test
    void startFromLot_lot2_premium_ok() {
        User user = data.user();
        makePremium(user);

        AttemptResponse r = service.start(user.getId(),
                training(Module.TCF, null, Difficulty.B1, QuestionType.CE, null, 2));

        assertThat(r.totalQuestions()).isEqualTo(20);
        Attempt persisted = attemptManager.findById(r.id()).orElseThrow();
        assertThat(persisted.getLotNumero()).isEqualTo(2);
    }

    @Test
    void startFromLot_typeNonTraining_refuse() {
        User user = data.user();
        StartAttemptRequest req = new StartAttemptRequest(
                AttemptType.MOCK_EXAM, Module.TCF, null, null,
                Difficulty.B1, QuestionType.CE, null, 1, null, null);

        assertThatThrownBy(() -> service.start(user.getId(), req))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void startCiviqueLot_sansThemeId_refuse() {
        User user = data.user();

        assertThatThrownBy(() -> service.start(user.getId(),
                training(Module.CIVIQUE, null, null, null, null, 1)))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void startTcfLot_sansDifficulty_refuse() {
        User user = data.user();

        assertThatThrownBy(() -> service.start(user.getId(),
                training(Module.TCF, null, null, QuestionType.CE, null, 1)))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void startCiviqueLot_ok() {
        User user = data.user();
        Theme theme = data.theme(Module.CIVIQUE, "lot-theme", "Lot thème");
        for (int i = 0; i < 25; i++) {
            data.question(theme);
        }

        AttemptResponse r = service.start(user.getId(),
                training(Module.CIVIQUE, theme.getId(), null, null, null, 1));

        assertThat(r.totalQuestions()).isEqualTo(20);
        Attempt persisted = attemptManager.findById(r.id()).orElseThrow();
        assertThat(persisted.getLotNumero()).isEqualTo(1);
        assertThat(persisted.getLotThemeId()).isEqualTo(theme.getId());
    }
}
