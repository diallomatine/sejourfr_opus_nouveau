package com.sejourfr.app.support;

import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.ExamTemplate;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.entity.Question;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.MediaType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.PassageType;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Prouve que chaque fabrique de {@link TestData} persiste réellement son entité
 * sur le Postgres embarqué : chaque INSERT doit satisfaire toutes les contraintes
 * NOT NULL et toutes les FK du schéma Flyway réel. Un id (ou une PK) non nul
 * après l'appel = la ligne est en base.
 */
class TestDataFactoryIT extends AbstractIntegrationTest {

    @Autowired
    private TestData data;

    @PersistenceContext
    private EntityManager em;

    /**
     * Force l'écriture des INSERT différés par {@code repository.save()} : sans
     * ce flush, les contraintes (NOT NULL, FK, CHECK) ne sont jamais évaluées car
     * la transaction est rollback à la fin du test — un INSERT invalide passerait
     * inaperçu. Avec le flush, toute violation fait échouer le test concerné.
     */
    @AfterEach
    void flushToValidateConstraints() {
        em.flush();
    }

    @Test
    void user() {
        assertThat(data.user().getId()).isNotNull();
    }

    @Test
    void admin() {
        assertThat(data.admin().getId()).isNotNull();
    }

    @Test
    void theme() {
        assertThat(data.theme().getId()).isNotNull();
    }

    @Test
    void media() {
        assertThat(data.media().getId()).isNotNull();
        assertThat(data.media(MediaType.AUDIO).getId()).isNotNull();
    }

    @Test
    void passage() {
        assertThat(data.passage().getId()).isNotNull();
        Theme theme = data.theme();
        assertThat(data.passage(PassageType.DIALOGUE, theme).getId()).isNotNull();
    }

    @Test
    void question() {
        Question q = data.question();
        assertThat(q.getId()).isNotNull();
        assertThat(q.getChoices()).hasSize(2);
        assertThat(q.getChoices().get(0).getId()).isNotNull();
    }

    @Test
    void choice() {
        assertThat(data.choice().getId()).isNotNull();
    }

    @Test
    void attempt() {
        assertThat(data.attempt().getId()).isNotNull();
    }

    @Test
    void attemptQuestion() {
        assertThat(data.attemptQuestion().getId()).isNotNull();
    }

    @Test
    void answer() {
        assertThat(data.answer().getId()).isNotNull();
    }

    @Test
    void plan() {
        assertThat(data.plan().getId()).isNotNull();
    }

    @Test
    void userSubscription() {
        assertThat(data.userSubscription().getId()).isNotNull();
    }

    @Test
    void productionTask() {
        assertThat(data.productionTask().getId()).isNotNull();
        assertThat(data.productionTask(EpreuveType.TCF_EO).getId()).isNotNull();
    }

    @Test
    void productionSubmission() {
        assertThat(data.productionSubmission().getId()).isNotNull();
    }

    @Test
    void productionExample() {
        assertThat(data.productionExample().getId()).isNotNull();
    }

    @Test
    void examTemplate() {
        assertThat(data.examTemplate().getId()).isNotNull();
    }

    @Test
    void examTemplateRule() {
        assertThat(data.examTemplateRule().getId()).isNotNull();
    }

    @Test
    void conversation() {
        assertThat(data.conversation().getId()).isNotNull();
    }

    @Test
    void message() {
        assertThat(data.message().getId()).isNotNull();
    }

    @Test
    void refreshToken() {
        assertThat(data.refreshToken().getJti()).isNotNull();
    }

    @Test
    void passwordResetToken() {
        assertThat(data.passwordResetToken().getId()).isNotNull();
    }

    @Test
    void emailChangeToken() {
        assertThat(data.emailChangeToken().getId()).isNotNull();
    }

    @Test
    void processedExternalEvent() {
        assertThat(data.processedExternalEvent().getEventId()).isNotNull();
    }

    @Test
    void userQuestionStatus() {
        assertThat(data.userQuestionStatus().getId()).isNotNull();
    }

    @Test
    void aiEvaluation() {
        assertThat(data.aiEvaluation().getId()).isNotNull();
    }

    @Test
    void transcription() {
        assertThat(data.transcription().getId()).isNotNull();
    }

    @Test
    void humanCalibrationNote() {
        assertThat(data.humanCalibrationNote().getId()).isNotNull();
    }

    @Test
    void realtimeSession() {
        assertThat(data.realtimeSession().getId()).isNotNull();
    }

    @Test
    void audioQuestionDraft() {
        assertThat(data.audioQuestionDraft().getId()).isNotNull();
    }

    @Test
    void audioQuestionGenerationLog() {
        assertThat(data.audioQuestionGenerationLog().getId()).isNotNull();
    }

    @Test
    void socialIdentity() {
        assertThat(data.socialIdentity().email()).isNotNull();
    }

    @Test
    void parameterizedParentsAreReused() {
        User u = data.user();
        Attempt a = data.attempt(u);
        assertThat(a.getUser().getId()).isEqualTo(u.getId());

        ProductionTask task = data.productionTask();
        ProductionSubmission sub = data.productionSubmission(a, task, u);
        assertThat(sub.getAttempt().getId()).isEqualTo(a.getId());
        assertThat(sub.getProductionTask().getId()).isEqualTo(task.getId());

        ExamTemplate tpl = data.examTemplate();
        assertThat(data.examTemplateRule(tpl).getExamTemplate().getId()).isEqualTo(tpl.getId());

        assertThat(data.audioQuestionDraft(data.theme(Module.TCF, "co", "CO")).getId()).isNotNull();
    }
}
