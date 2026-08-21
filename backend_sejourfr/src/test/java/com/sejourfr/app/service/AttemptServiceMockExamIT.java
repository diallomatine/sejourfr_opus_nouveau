package com.sejourfr.app.service;

import com.sejourfr.app.dto.AttemptResponse;
import com.sejourfr.app.dto.StartAttemptRequest;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.ExamTemplate;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.ExamTemplateManager;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityNotFoundException;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.AccessDeniedException;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Démarrage d'attempts MOCK_EXAM : examen civique global/thématique, examen
 * module TCF (CO/CE), examen template. DB réelle (pool seedé).
 */
class AttemptServiceMockExamIT extends AbstractIntegrationTest {

    @Autowired AttemptService service;
    @Autowired TestData data;
    @Autowired AttemptManager attemptManager;
    @Autowired ExamTemplateManager templateManager;

    private void makePremium(User user) {
        data.userSubscription(user, data.plan());
    }

    private StartAttemptRequest mock(Module module, UUID themeId, UUID templateId,
                                     QuestionType moduleExamType, Integer slot) {
        return new StartAttemptRequest(AttemptType.MOCK_EXAM, module, templateId, themeId,
                null, null, null, null, moduleExamType, slot, null);
    }

    private ExamTemplate template(Module module, boolean free, boolean published) {
        ExamTemplate t = new ExamTemplate();
        t.setSlug("tpl-" + System.nanoTime());
        t.setModule(module);
        t.setName("Examen blanc");
        t.setDurationSeconds(5400);
        t.setTotalQuestions(20);
        t.setPassingScore(12);
        t.setFree(free);
        t.setPublished(published);
        t.setPosition(0);
        return templateManager.save(t);
    }

    @Test
    void civiqueFullMockExam_config40Questions_2700s_seuil32() {
        User user = data.user();
        makePremium(user); // slot 3 : au-dela du slot 1 offert

        AttemptResponse r = service.start(user.getId(), mock(Module.CIVIQUE, null, null, null, 3));

        assertThat(r.type()).isEqualTo(AttemptType.MOCK_EXAM);
        assertThat(r.totalQuestions()).isEqualTo(40);
        assertThat(r.timeLimitSeconds()).isEqualTo(45 * 60);
        assertThat(r.passThreshold()).isEqualTo(32);

        Attempt persisted = attemptManager.findById(r.id()).orElseThrow();
        assertThat(persisted.getSlotNumber()).isEqualTo(3);
        assertThat(persisted.getLotThemeId()).isNull();
    }

    @Test
    void civiqueThemeExam_config20Questions_1200s_seuil16_scopeTheme() {
        User user = data.user();
        Theme theme = data.theme(Module.CIVIQUE, "exam-theme", "Examen thème");
        for (int i = 0; i < 25; i++) {
            data.question(theme);
        }

        AttemptResponse r = service.start(user.getId(), mock(Module.CIVIQUE, theme.getId(), null, null, null));

        assertThat(r.totalQuestions()).isEqualTo(20);
        assertThat(r.timeLimitSeconds()).isEqualTo(20 * 60);
        assertThat(r.passThreshold()).isEqualTo(16);
        assertThat(r.themeId()).isEqualTo(theme.getId());
    }

    @Test
    void tcfGlobalMockExam_legacy_60Questions_5400s() {
        User user = data.user();

        AttemptResponse r = service.start(user.getId(), mock(Module.TCF, null, null, null, null));

        assertThat(r.totalQuestions()).isEqualTo(60);
        assertThat(r.timeLimitSeconds()).isEqualTo(90 * 60);
        assertThat(r.passThreshold()).isNull();
        assertThat(r.module()).isEqualTo(Module.TCF);
    }

    @Test
    void moduleExamCO_premium_25Questions_1200s() {
        User user = data.user();
        makePremium(user);

        AttemptResponse r = service.start(user.getId(), mock(Module.TCF, null, null, QuestionType.CO, null));

        assertThat(r.totalQuestions()).isEqualTo(25);
        assertThat(r.timeLimitSeconds()).isEqualTo(20 * 60);
        assertThat(r.moduleExamQuestionType()).isEqualTo(QuestionType.CO);
    }

    @Test
    void moduleExamCE_premium_25Questions_2100s() {
        User user = data.user();
        makePremium(user);

        AttemptResponse r = service.start(user.getId(), mock(Module.TCF, null, null, QuestionType.CE, null));

        assertThat(r.totalQuestions()).isEqualTo(25);
        assertThat(r.timeLimitSeconds()).isEqualTo(35 * 60);
    }

    @Test
    void moduleExam_slot1_compteGratuit_autorise() {
        User user = data.user();

        AttemptResponse r = service.start(user.getId(), mock(Module.TCF, null, null, QuestionType.CO, 1));

        assertThat(r.totalQuestions()).isEqualTo(25);
        assertThat(r.moduleExamQuestionType()).isEqualTo(QuestionType.CO);
    }

    @Test
    void moduleExam_slot2_compteGratuit_refuse() {
        User user = data.user();

        assertThatThrownBy(() -> service.start(user.getId(), mock(Module.TCF, null, null, QuestionType.CO, 2)))
                .isInstanceOf(AccessDeniedException.class);
    }

    @Test
    void moduleExam_questionTypeInvalide_refuse() {
        User user = data.user();
        makePremium(user);

        assertThatThrownBy(() -> service.start(user.getId(),
                mock(Module.TCF, null, null, QuestionType.CONNAISSANCE, null)))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void moduleExam_moduleCivique_refuse() {
        User user = data.user();
        makePremium(user);

        assertThatThrownBy(() -> service.start(user.getId(),
                mock(Module.CIVIQUE, null, null, QuestionType.CO, null)))
                .isInstanceOf(BusinessException.class);
    }

    // ------------------------------------------------------------------------
    // Verrou freemium de la branche legacy (examens civiques globaux / de thème
    // / TCF 60 Q) — elle ne contrôlait RIEN : un compte gratuit pouvait lancer
    // n'importe quel slot en illimité (le verrou n'existait que côté client).
    // ------------------------------------------------------------------------

    @Test
    void civiqueFullMockExam_slot1_compteGratuit_autorise() {
        User user = data.user();

        AttemptResponse r = service.start(user.getId(), mock(Module.CIVIQUE, null, null, null, 1));

        assertThat(r.totalQuestions()).isEqualTo(40);
    }

    @Test
    void civiqueFullMockExam_sansSlot_compteGratuit_autorise() {
        User user = data.user();

        AttemptResponse r = service.start(user.getId(), mock(Module.CIVIQUE, null, null, null, null));

        assertThat(r.totalQuestions()).isEqualTo(40);
    }

    @Test
    void civiqueFullMockExam_slot2_compteGratuit_refuse() {
        User user = data.user();

        assertThatThrownBy(() -> service.start(user.getId(), mock(Module.CIVIQUE, null, null, null, 2)))
                .isInstanceOf(AccessDeniedException.class);
    }

    @Test
    void civiqueFullMockExam_slot20_compteGratuit_refuse() {
        User user = data.user();

        assertThatThrownBy(() -> service.start(user.getId(), mock(Module.CIVIQUE, null, null, null, 20)))
                .isInstanceOf(AccessDeniedException.class);
    }

    @Test
    void civiqueThemeExam_slot2_compteGratuit_refuse() {
        User user = data.user();
        Theme theme = data.theme(Module.CIVIQUE, "exam-theme-lock", "Examen thème verrouillé");
        for (int i = 0; i < 25; i++) {
            data.question(theme);
        }

        assertThatThrownBy(() -> service.start(user.getId(),
                mock(Module.CIVIQUE, theme.getId(), null, null, 2)))
                .isInstanceOf(AccessDeniedException.class);
    }

    @Test
    void tcfGlobalMockExam_slot2_compteGratuit_refuse() {
        User user = data.user();

        assertThatThrownBy(() -> service.start(user.getId(), mock(Module.TCF, null, null, null, 2)))
                .isInstanceOf(AccessDeniedException.class);
    }

    @Test
    void civiqueFullMockExam_slot2_premium_autorise() {
        User user = data.user();
        makePremium(user);

        AttemptResponse r = service.start(user.getId(), mock(Module.CIVIQUE, null, null, null, 2));

        assertThat(r.totalQuestions()).isEqualTo(40);
        assertThat(attemptManager.findById(r.id()).orElseThrow().getSlotNumber()).isEqualTo(2);
    }

    // ------------------------------------------------------------------------
    // Bornes du slotNumber (1..20) — 999 et -3 étaient acceptés et persistés,
    // et un slot <= 0 passait même sous le verrou `slot > 1`.
    // ------------------------------------------------------------------------

    @Test
    void mockExam_slotHorsBorne_refuse() {
        User user = data.user();
        makePremium(user);

        assertThatThrownBy(() -> service.start(user.getId(), mock(Module.CIVIQUE, null, null, null, 999)))
                .isInstanceOf(BusinessException.class);
        assertThatThrownBy(() -> service.start(user.getId(), mock(Module.CIVIQUE, null, null, null, -3)))
                .isInstanceOf(BusinessException.class);
        assertThatThrownBy(() -> service.start(user.getId(), mock(Module.CIVIQUE, null, null, null, 0)))
                .isInstanceOf(BusinessException.class);
    }

    /**
     * L'épreuve fine doit refléter le sous-module joué. Elle n'était jamais
     * posée : le @PrePersist d'Attempt retombait sur TCF_CO pour TOUT le TCF,
     * et un examen de compréhension écrite ressortait « TCF_CO » dans
     * {@code GET /api/me/attempts} — donc « Compréhension orale » à l'écran.
     */
    @Test
    void moduleExam_poseLEpreuveDuSousModule() {
        User user = data.user();
        makePremium(user);

        AttemptResponse co = service.start(user.getId(), mock(Module.TCF, null, null, QuestionType.CO, null));
        AttemptResponse ce = service.start(user.getId(), mock(Module.TCF, null, null, QuestionType.CE, null));
        AttemptResponse st = service.start(user.getId(),
                mock(Module.TCF, null, null, QuestionType.STRUCTURE, null));

        assertThat(epreuveOf(co.id())).isEqualTo(EpreuveType.TCF_CO);
        assertThat(epreuveOf(ce.id())).isEqualTo(EpreuveType.TCF_CE);
        assertThat(epreuveOf(st.id())).isEqualTo(EpreuveType.TCF_STRUCTURE);
    }

    /** Même cause, même correctif, sur les séries d'entraînement TCF. */
    @Test
    void lotTcf_poseLEpreuveDuSousModule() {
        User user = data.user();
        AttemptResponse ce = service.start(user.getId(),
                new StartAttemptRequest(AttemptType.TRAINING, Module.TCF, null, null,
                        Difficulty.A2, QuestionType.CE, null, 1, null, null, null));

        assertThat(epreuveOf(ce.id())).isEqualTo(EpreuveType.TCF_CE);
    }

    private EpreuveType epreuveOf(UUID attemptId) {
        return attemptManager.findById(attemptId).orElseThrow().getEpreuve();
    }

    @Test
    void moduleExam_slotHorsBorne_refuse() {
        User user = data.user();
        makePremium(user);

        assertThatThrownBy(() -> service.start(user.getId(),
                mock(Module.TCF, null, null, QuestionType.CO, 999)))
                .isInstanceOf(BusinessException.class);
        assertThatThrownBy(() -> service.start(user.getId(),
                mock(Module.TCF, null, null, QuestionType.CO, -3)))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void moduleExam_slot20_premium_autorise() {
        User user = data.user();
        makePremium(user);

        AttemptResponse r = service.start(user.getId(), mock(Module.TCF, null, null, QuestionType.CO, 20));

        assertThat(r.totalQuestions()).isEqualTo(25);
    }

    @Test
    void startFromTemplate_slotHorsBorne_refuse() {
        User user = data.user();
        ExamTemplate t = data.examTemplate();

        assertThatThrownBy(() -> service.start(user.getId(), mock(Module.TCF, null, t.getId(), null, 999)))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void startFromTemplate_templateGratuitPublie_compteGratuit_ok() {
        User user = data.user();
        ExamTemplate t = data.examTemplate(); // TCF, free, published, 20 questions

        AttemptResponse r = service.start(user.getId(), mock(Module.TCF, null, t.getId(), null, null));

        assertThat(r.type()).isEqualTo(AttemptType.MOCK_EXAM);
        assertThat(r.totalQuestions()).isEqualTo(20);
        assertThat(r.timeLimitSeconds()).isEqualTo(5400);
        assertThat(r.examTemplateId()).isEqualTo(t.getId());
    }

    @Test
    void startFromTemplate_nonPublie_refuse() {
        User user = data.user();
        ExamTemplate t = template(Module.TCF, true, false);

        assertThatThrownBy(() -> service.start(user.getId(), mock(Module.TCF, null, t.getId(), null, null)))
                .isInstanceOf(AccessDeniedException.class);
    }

    @Test
    void startFromTemplate_payant_compteGratuit_refuse() {
        User user = data.user();
        ExamTemplate t = template(Module.TCF, false, true);

        assertThatThrownBy(() -> service.start(user.getId(), mock(Module.TCF, null, t.getId(), null, null)))
                .isInstanceOf(AccessDeniedException.class);
    }

    @Test
    void startFromTemplate_payant_premium_ok() {
        User user = data.user();
        makePremium(user);
        ExamTemplate t = template(Module.TCF, false, true);

        AttemptResponse r = service.start(user.getId(), mock(Module.TCF, null, t.getId(), null, null));

        assertThat(r.totalQuestions()).isEqualTo(20);
        assertThat(r.examTemplateId()).isEqualTo(t.getId());
    }

    @Test
    void start_templateIntrouvable_lanceNotFound() {
        User user = data.user();

        assertThatThrownBy(() -> service.start(user.getId(),
                mock(Module.TCF, null, UUID.randomUUID(), null, null)))
                .isInstanceOf(EntityNotFoundException.class);
    }
}
