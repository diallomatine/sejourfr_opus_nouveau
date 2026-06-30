package com.sejourfr.app.manager;

import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.SubmissionStatut;
import com.sejourfr.app.repository.ProductionTaskRepository;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class ProductionSubmissionManagerIT extends AbstractIntegrationTest {

    private static final String NIVEAU = "B2";

    @Autowired
    private ProductionSubmissionManager manager;

    @Autowired
    private AttemptManager attemptManager;

    @Autowired
    private ProductionTaskRepository taskRepository;

    @Autowired
    private TestData testData;

    private ProductionTask task(EpreuveType epreuve, short tache) {
        ProductionTask t = new ProductionTask();
        t.setEpreuve(epreuve);
        t.setNiveauCible(NIVEAU);
        t.setTacheNumero(tache);
        t.setConsigne("Consigne " + UUID.randomUUID());
        t.setActive(true);
        // Contrainte chk_prod_task_audio_text_coherence (V011) : TCF_EO porte une
        // durée (mots NULL), TCF_EE porte une fourchette de mots (durée NULL).
        if (epreuve == EpreuveType.TCF_EO) {
            t.setDureeMinSec(60);
            t.setDureeMaxSec(180);
        } else {
            t.setMotsMin(120);
            t.setMotsMax(180);
        }
        return taskRepository.save(t);
    }

    private Attempt examAttempt(User user) {
        Attempt a = testData.attempt(user);
        a.setSlotNumber(1);
        return attemptManager.save(a);
    }

    private Attempt fullExamChild(User user) {
        Attempt parent = testData.attempt(user);
        parent.setEpreuve(EpreuveType.TCF_COMPLET);
        attemptManager.save(parent);
        Attempt child = testData.attempt(user);
        child.setEpreuve(EpreuveType.TCF_EE);
        child.setParentAttempt(parent);
        return attemptManager.save(child);
    }

    private ProductionSubmission submission(Attempt attempt, ProductionTask task, User user,
                                            Instant submittedAt, SubmissionStatut statut) {
        ProductionSubmission s = testData.productionSubmission(attempt, task, user);
        s.setSubmittedAt(submittedAt);
        s.setStatut(statut);
        return manager.save(s);
    }

    @Test
    void findByIdAbsentReturnsEmpty() {
        assertThat(manager.findById(UUID.randomUUID())).isEmpty();
    }

    @Test
    void saveAndFindById() {
        ProductionSubmission saved = testData.productionSubmission();

        assertThat(saved.getId()).isNotNull();
        assertThat(manager.findById(saved.getId())).isPresent();
    }

    @Test
    void findByAttemptIdOrdersBySubmittedAtAsc() {
        User user = testData.user();
        Attempt attempt = testData.attempt(user);
        ProductionTask t = task(EpreuveType.TCF_EE, (short) 1);
        Instant base = Instant.now().truncatedTo(ChronoUnit.SECONDS);
        ProductionSubmission later = submission(attempt, t, user, base.minus(10, ChronoUnit.SECONDS), SubmissionStatut.SUBMITTED);
        ProductionSubmission earlier = submission(attempt, t, user, base.minus(30, ChronoUnit.SECONDS), SubmissionStatut.SUBMITTED);
        ProductionSubmission otherAttempt = submission(testData.attempt(user), t, user, base, SubmissionStatut.SUBMITTED);

        List<ProductionSubmission> result = manager.findByAttemptId(attempt.getId());

        assertThat(result)
                .extracting(ProductionSubmission::getId)
                .containsExactly(earlier.getId(), later.getId())
                .doesNotContain(otherAttempt.getId());
    }

    @Test
    void countByUserAndEpreuve() {
        User user = testData.user();
        Attempt attempt = testData.attempt(user);
        ProductionTask ee = task(EpreuveType.TCF_EE, (short) 1);
        ProductionTask eo = task(EpreuveType.TCF_EO, (short) 1);
        Instant now = Instant.now();
        submission(attempt, ee, user, now, SubmissionStatut.SUBMITTED);
        submission(attempt, ee, user, now, SubmissionStatut.SUBMITTED);
        submission(attempt, eo, user, now, SubmissionStatut.SUBMITTED);
        submission(testData.attempt(), ee, testData.user(), now, SubmissionStatut.SUBMITTED);

        assertThat(manager.countByUserAndEpreuve(user.getId(), EpreuveType.TCF_EE)).isEqualTo(2);
        assertThat(manager.countByUserAndEpreuve(user.getId(), EpreuveType.TCF_EO)).isEqualTo(1);
        assertThat(manager.countByUserAndEpreuve(UUID.randomUUID(), EpreuveType.TCF_EE)).isZero();
    }

    @Test
    void countTrainingExcludesExamAndFullExamSubmissions() {
        User user = testData.user();
        ProductionTask ee = task(EpreuveType.TCF_EE, (short) 1);
        Instant now = Instant.now();
        submission(testData.attempt(user), ee, user, now, SubmissionStatut.SUBMITTED);          // training
        submission(examAttempt(user), ee, user, now, SubmissionStatut.SUBMITTED);                // exam slot
        submission(fullExamChild(user), ee, user, now, SubmissionStatut.SUBMITTED);              // full-exam child

        assertThat(manager.countByUserAndEpreuve(user.getId(), EpreuveType.TCF_EE)).isEqualTo(3);
        assertThat(manager.countTrainingByUserAndEpreuve(user.getId(), EpreuveType.TCF_EE)).isEqualTo(1);
    }

    @Test
    void hasFullExamProductionSubmission() {
        User withFullExam = testData.user();
        ProductionTask ee = task(EpreuveType.TCF_EE, (short) 1);
        submission(fullExamChild(withFullExam), ee, withFullExam, Instant.now(), SubmissionStatut.SUBMITTED);

        User trainingOnly = testData.user();
        submission(testData.attempt(trainingOnly), ee, trainingOnly, Instant.now(), SubmissionStatut.SUBMITTED);

        assertThat(manager.hasFullExamProductionSubmission(withFullExam.getId())).isTrue();
        assertThat(manager.hasFullExamProductionSubmission(trainingOnly.getId())).isFalse();
    }

    @Test
    void findRecentByUserOrdersDescAndRespectsLimit() {
        User user = testData.user();
        Attempt attempt = testData.attempt(user);
        ProductionTask t = task(EpreuveType.TCF_EE, (short) 1);
        Instant base = Instant.now().truncatedTo(ChronoUnit.SECONDS);
        ProductionSubmission oldest = submission(attempt, t, user, base.minus(30, ChronoUnit.SECONDS), SubmissionStatut.SUBMITTED);
        ProductionSubmission middle = submission(attempt, t, user, base.minus(20, ChronoUnit.SECONDS), SubmissionStatut.SUBMITTED);
        ProductionSubmission newest = submission(attempt, t, user, base.minus(10, ChronoUnit.SECONDS), SubmissionStatut.SUBMITTED);

        assertThat(manager.findRecentByUser(user.getId(), 10))
                .extracting(ProductionSubmission::getId)
                .containsExactly(newest.getId(), middle.getId(), oldest.getId());

        assertThat(manager.findRecentByUser(user.getId(), 2))
                .extracting(ProductionSubmission::getId)
                .containsExactly(newest.getId(), middle.getId());
    }

    @Test
    void findRecentByUserAndEpreuveFiltersAndOrders() {
        User user = testData.user();
        Attempt attempt = testData.attempt(user);
        ProductionTask ee = task(EpreuveType.TCF_EE, (short) 1);
        ProductionTask eo = task(EpreuveType.TCF_EO, (short) 1);
        Instant base = Instant.now().truncatedTo(ChronoUnit.SECONDS);
        ProductionSubmission eeOld = submission(attempt, ee, user, base.minus(30, ChronoUnit.SECONDS), SubmissionStatut.SUBMITTED);
        ProductionSubmission eeNew = submission(attempt, ee, user, base.minus(10, ChronoUnit.SECONDS), SubmissionStatut.SUBMITTED);
        ProductionSubmission eoSub = submission(attempt, eo, user, base.minus(5, ChronoUnit.SECONDS), SubmissionStatut.SUBMITTED);

        List<ProductionSubmission> result = manager.findRecentByUserAndEpreuve(user.getId(), EpreuveType.TCF_EE, 10);

        assertThat(result)
                .extracting(ProductionSubmission::getId)
                .containsExactly(eeNew.getId(), eeOld.getId())
                .doesNotContain(eoSub.getId());
    }

    @Test
    void findLatestPerTaskKeepsMostRecentPerTacheNumero() {
        User user = testData.user();
        Attempt attempt = testData.attempt(user);
        ProductionTask tache1 = task(EpreuveType.TCF_EE, (short) 1);
        ProductionTask tache2 = task(EpreuveType.TCF_EE, (short) 2);
        Instant base = Instant.now().truncatedTo(ChronoUnit.SECONDS);
        submission(attempt, tache1, user, base.minus(30, ChronoUnit.SECONDS), SubmissionStatut.SUBMITTED);
        ProductionSubmission tache1Latest = submission(attempt, tache1, user, base.minus(5, ChronoUnit.SECONDS), SubmissionStatut.SUBMITTED);
        ProductionSubmission tache2Only = submission(attempt, tache2, user, base.minus(20, ChronoUnit.SECONDS), SubmissionStatut.SUBMITTED);

        List<ProductionSubmission> result = manager.findLatestPerTask(user.getId(), EpreuveType.TCF_EE, NIVEAU);

        assertThat(result)
                .extracting(ProductionSubmission::getId)
                .containsExactly(tache1Latest.getId(), tache2Only.getId());
    }

    @Test
    void findByStatutOrderedBySubmittedAt() {
        User user = testData.user();
        Attempt attempt = testData.attempt(user);
        ProductionTask t = task(EpreuveType.TCF_EE, (short) 1);
        Instant base = Instant.now().truncatedTo(ChronoUnit.SECONDS);
        ProductionSubmission later = submission(attempt, t, user, base.minus(10, ChronoUnit.SECONDS), SubmissionStatut.EVALUATING);
        ProductionSubmission earlier = submission(attempt, t, user, base.minus(30, ChronoUnit.SECONDS), SubmissionStatut.EVALUATING);
        ProductionSubmission otherStatus = submission(attempt, t, user, base, SubmissionStatut.EVALUATED);

        List<ProductionSubmission> result = manager.findByStatutOrderedBySubmittedAt(SubmissionStatut.EVALUATING);

        assertThat(result)
                .extracting(ProductionSubmission::getId)
                .containsExactly(earlier.getId(), later.getId())
                .doesNotContain(otherStatus.getId());
    }
}
