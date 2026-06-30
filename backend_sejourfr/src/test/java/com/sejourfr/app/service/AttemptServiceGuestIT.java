package com.sejourfr.app.service;

import com.sejourfr.app.dto.AttemptResponse;
import com.sejourfr.app.dto.StartAttemptRequest;
import com.sejourfr.app.dto.SubmitAnswerRequest;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.AttemptQuestion;
import com.sejourfr.app.entity.ExamTemplate;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.AttemptQuestionManager;
import com.sejourfr.app.manager.ExamTemplateManager;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityNotFoundException;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.AccessDeniedException;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Démo guest (visiteur non authentifié) : tirages déterministes, verrous
 * d'accès (examens ciblés / séries 2+ réservés aux comptes), et accès sécurisé
 * par IP. DB réelle.
 */
class AttemptServiceGuestIT extends AbstractIntegrationTest {

    private static final String IP = "198.51.100.42";

    @Autowired AttemptService service;
    @Autowired TestData data;
    @Autowired AttemptManager attemptManager;
    @Autowired AttemptQuestionManager attemptQuestionManager;
    @Autowired ExamTemplateManager templateManager;

    private StartAttemptRequest req(AttemptType type, Module module, UUID templateId, UUID themeId,
                                    Difficulty difficulty, QuestionType qType, Integer lotNumero,
                                    QuestionType moduleExamType) {
        return new StartAttemptRequest(type, module, templateId, themeId,
                difficulty, qType, null, lotNumero, moduleExamType, null);
    }

    private ExamTemplate paidPublished() {
        ExamTemplate t = new ExamTemplate();
        t.setSlug("guest-paid-" + System.nanoTime());
        t.setModule(Module.TCF);
        t.setName("Payant");
        t.setDurationSeconds(5400);
        t.setTotalQuestions(20);
        t.setPassingScore(12);
        t.setFree(false);
        t.setPublished(true);
        t.setPosition(0);
        return templateManager.save(t);
    }

    @Test
    void guestDemoTraining_serieDeterministe_userNull_ipPosee() {
        AttemptResponse r = service.startGuestDemo(
                req(AttemptType.TRAINING, Module.CIVIQUE, null, null, null, null, null, null), IP);

        assertThat(r.totalQuestions()).isEqualTo(20);
        Attempt persisted = attemptManager.findById(r.id()).orElseThrow();
        assertThat(persisted.getUser()).isNull();
        assertThat(persisted.getClientIp()).isEqualTo(IP);
    }

    @Test
    void loadGuestAttempt_bonneIp_ok_mauvaiseIp_notFound() {
        AttemptResponse r = service.startGuestDemo(
                req(AttemptType.TRAINING, Module.CIVIQUE, null, null, null, null, null, null), IP);

        Attempt loaded = service.loadGuestAttempt(r.id(), IP);
        assertThat(loaded.getId()).isEqualTo(r.id());

        assertThatThrownBy(() -> service.loadGuestAttempt(r.id(), "10.0.0.1"))
                .isInstanceOf(EntityNotFoundException.class);
    }

    @Test
    void guestDemoMockExam_templateGratuit_ok() {
        ExamTemplate t = data.examTemplate(); // free, published, TCF

        AttemptResponse r = service.startGuestDemo(
                req(AttemptType.MOCK_EXAM, Module.TCF, t.getId(), null, null, null, null, null), IP);

        assertThat(r.totalQuestions()).isEqualTo(20);
        assertThat(r.examTemplateId()).isEqualTo(t.getId());
    }

    @Test
    void guestDemoMockExam_templatePayant_refuse() {
        ExamTemplate t = paidPublished();

        assertThatThrownBy(() -> service.startGuestDemo(
                req(AttemptType.MOCK_EXAM, Module.TCF, t.getId(), null, null, null, null, null), IP))
                .isInstanceOf(AccessDeniedException.class);
    }

    @Test
    void guestDemoMockExam_scopeTheme_refuse() {
        Theme theme = data.theme(Module.CIVIQUE, "guest-theme", "Guest thème");

        assertThatThrownBy(() -> service.startGuestDemo(
                req(AttemptType.MOCK_EXAM, Module.CIVIQUE, null, theme.getId(), null, null, null, null), IP))
                .isInstanceOf(AccessDeniedException.class);
    }

    @Test
    void guestDemoMockExam_scopeEpreuve_refuse() {
        assertThatThrownBy(() -> service.startGuestDemo(
                req(AttemptType.MOCK_EXAM, Module.TCF, null, null, null, null, null, QuestionType.CO), IP))
                .isInstanceOf(AccessDeniedException.class);
    }

    @Test
    void guestDemoMockExam_civiqueGlobal_config40() {
        AttemptResponse r = service.startGuestDemo(
                req(AttemptType.MOCK_EXAM, Module.CIVIQUE, null, null, null, null, null, null), IP);

        assertThat(r.totalQuestions()).isEqualTo(40);
        assertThat(r.timeLimitSeconds()).isEqualTo(45 * 60);
        assertThat(r.passThreshold()).isEqualTo(32);
    }

    @Test
    void guestLot1_civique_ok() {
        Theme theme = data.theme(Module.CIVIQUE, "guest-lot", "Guest lot");
        for (int i = 0; i < 25; i++) {
            data.question(theme);
        }

        AttemptResponse r = service.startGuestDemo(
                req(AttemptType.TRAINING, Module.CIVIQUE, null, theme.getId(), null, null, 1, null), IP);

        assertThat(r.totalQuestions()).isEqualTo(20);
        Attempt persisted = attemptManager.findById(r.id()).orElseThrow();
        assertThat(persisted.getUser()).isNull();
        assertThat(persisted.getLotNumero()).isEqualTo(1);
        assertThat(persisted.getLotThemeId()).isEqualTo(theme.getId());
    }

    @Test
    void guestLot_serie2_refuse() {
        Theme theme = data.theme(Module.CIVIQUE, "guest-lot2", "Guest lot 2");

        assertThatThrownBy(() -> service.startGuestDemo(
                req(AttemptType.TRAINING, Module.CIVIQUE, null, theme.getId(), null, null, 2, null), IP))
                .isInstanceOf(AccessDeniedException.class);
    }

    @Test
    void guestLot_tcfSansDifficulty_refuse() {
        assertThatThrownBy(() -> service.startGuestDemo(
                req(AttemptType.TRAINING, Module.TCF, null, null, null, QuestionType.CE, 1, null), IP))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void guestSubmitEtFinish_viaVariantesSansControleUser() {
        AttemptResponse started = service.startGuestDemo(
                req(AttemptType.TRAINING, Module.CIVIQUE, null, null, null, null, null, null), IP);
        Attempt attempt = service.loadGuestAttempt(started.id(), IP);
        List<AttemptQuestion> aqs = attemptQuestionManager.findByAttemptOrderedByPosition(started.id());
        UUID anyChoice = aqs.get(0).getQuestion().getChoices().get(0).getId();

        service.submitAnswerForAttempt(attempt, new SubmitAnswerRequest(aqs.get(0).getId(), List.of(anyChoice)));
        AttemptResponse finished = service.finishAttempt(attempt);

        assertThat(finished.finishedAt()).isNotNull();
    }
}
