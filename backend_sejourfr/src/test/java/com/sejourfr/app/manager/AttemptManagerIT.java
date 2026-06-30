package com.sejourfr.app.manager;

import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.ExamTemplate;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AttemptMode;
import com.sejourfr.app.enums.AttemptStatus;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.Instant;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class AttemptManagerIT extends AbstractIntegrationTest {

    @Autowired
    private AttemptManager manager;

    @Autowired
    private TestData testData;

    @Test
    void saveAndFindById() {
        User user = testData.user();
        Attempt a = save(base(user));
        assertThat(a.getId()).isNotNull();
        assertThat(a.getStartedAt()).isNotNull();

        assertThat(manager.findById(a.getId())).isPresent();
    }

    @Test
    void findByIdAbsentReturnsEmpty() {
        assertThat(manager.findById(UUID.randomUUID())).isEmpty();
    }

    @Test
    void countByUserId() {
        User user = testData.user();
        User other = testData.user();
        save(base(user));
        save(base(user));
        save(base(other));

        assertThat(manager.countByUserId(user.getId())).isEqualTo(2);
        assertThat(manager.countByUserId(UUID.randomUUID())).isZero();
    }

    @Test
    void countByExamTemplateId() {
        User user = testData.user();
        ExamTemplate tpl = testData.examTemplate();
        Attempt a1 = base(user);
        a1.setType(AttemptType.MOCK_EXAM);
        a1.setExamTemplate(tpl);
        save(a1);
        Attempt a2 = base(user);
        a2.setType(AttemptType.MOCK_EXAM);
        a2.setExamTemplate(tpl);
        save(a2);
        // Attempt sans template → exclu.
        save(base(user));

        assertThat(manager.countByExamTemplateId(tpl.getId())).isEqualTo(2);
        assertThat(manager.countByExamTemplateId(UUID.randomUUID())).isZero();
    }

    @Test
    void deleteByUserId() {
        User user = testData.user();
        User other = testData.user();
        save(base(user));
        save(base(user));
        Attempt keep = save(base(other));

        int deleted = manager.deleteByUserId(user.getId());

        assertThat(deleted).isEqualTo(2);
        assertThat(manager.countByUserId(user.getId())).isZero();
        assertThat(manager.findById(keep.getId())).isPresent();   // l'autre user intact
    }

    @Test
    void findGuestByIdAndIpRequiresNullUserAndMatchingIp() {
        Attempt guest = base(null);
        guest.setClientIp("203.0.113.7");
        save(guest);

        // user non null mais même IP → ignoré.
        User user = testData.user();
        Attempt owned = base(user);
        owned.setClientIp("203.0.113.7");
        save(owned);

        assertThat(manager.findGuestByIdAndIp(guest.getId(), "203.0.113.7"))
                .map(Attempt::getId).contains(guest.getId());
        assertThat(manager.findGuestByIdAndIp(guest.getId(), "198.51.100.1")).isEmpty();
        assertThat(manager.findGuestByIdAndIp(owned.getId(), "203.0.113.7")).isEmpty();
    }

    @Test
    void findByUserFilteredByType() {
        User user = testData.user();
        Attempt training = save(base(user));
        Attempt mock = base(user);
        mock.setType(AttemptType.MOCK_EXAM);
        save(mock);

        List<Attempt> onlyMock = manager.findByUserFiltered(
                user.getId(), AttemptType.MOCK_EXAM, null, null, null, 10);
        assertThat(onlyMock).extracting(Attempt::getId).containsExactly(mock.getId());

        List<Attempt> both = manager.findByUserFiltered(user.getId(), null, null, null, null, 10);
        assertThat(both).extracting(Attempt::getId)
                .containsExactlyInAnyOrder(training.getId(), mock.getId());
    }

    @Test
    void findByUserFilteredByModuleExamQuestionTypeAndTheme() {
        User user = testData.user();
        UUID themeId = UUID.randomUUID();

        Attempt co = base(user);
        co.setType(AttemptType.MOCK_EXAM);
        co.setModuleExamQuestionType(QuestionType.CO);
        save(co);
        Attempt plain = save(base(user));
        Attempt themed = base(user);
        themed.setLotThemeId(themeId);
        save(themed);

        assertThat(manager.findByUserFiltered(user.getId(), null, null, QuestionType.CO, null, 10))
                .extracting(Attempt::getId).containsExactly(co.getId());
        assertThat(manager.findByUserFiltered(user.getId(), null, null, null, themeId, 10))
                .extracting(Attempt::getId).containsExactly(themed.getId());
        assertThat(plain.getId()).isNotNull();
    }

    @Test
    void findByUserFilteredOrdersDescAndCapsLimit() {
        User user = testData.user();
        Instant t0 = Instant.now().minus(3, ChronoUnit.HOURS);
        Attempt oldest = startedAt(base(user), t0);
        Attempt mid = startedAt(base(user), t0.plus(1, ChronoUnit.HOURS));
        Attempt newest = startedAt(base(user), t0.plus(2, ChronoUnit.HOURS));

        List<Attempt> capped = manager.findByUserFiltered(user.getId(), null, null, null, null, 2);
        assertThat(capped).extracting(Attempt::getId).containsExactly(newest.getId(), mid.getId());
        assertThat(capped).doesNotContain(oldest);
    }

    @Test
    void findLastFinishedByLotsKeepsMostRecentPerLot() {
        User user = testData.user();
        Instant t0 = Instant.now().minus(5, ChronoUnit.HOURS);

        // Lot 1 : deux attempts finis, on garde le plus récent.
        finishedLot(user, 1, t0, t0.plus(10, ChronoUnit.MINUTES));
        Attempt lot1Recent = finishedLot(user, 1, t0.plus(1, ChronoUnit.HOURS), t0.plus(70, ChronoUnit.MINUTES));
        // Lot 2 : un seul.
        Attempt lot2 = finishedLot(user, 2, t0, t0.plus(10, ChronoUnit.MINUTES));
        // Lot non terminé → exclu.
        Attempt unfinished = base(user);
        unfinished.setModule(Module.TCF);
        unfinished.setLotNumero(3);
        unfinished.setLotQuestionType(QuestionType.CO);
        unfinished.setLotDifficulty(Difficulty.B1);
        save(unfinished);
        // Difficulté différente → exclu.
        Attempt otherDiff = base(user);
        otherDiff.setModule(Module.TCF);
        otherDiff.setLotNumero(1);
        otherDiff.setLotQuestionType(QuestionType.CO);
        otherDiff.setLotDifficulty(Difficulty.B2);
        otherDiff.setFinishedAt(t0);
        save(otherDiff);

        Map<Integer, Attempt> map = manager.findLastFinishedByLots(
                user.getId(), Module.TCF, QuestionType.CO, Difficulty.B1);

        assertThat(map).containsOnlyKeys(1, 2);
        assertThat(map.get(1).getId()).isEqualTo(lot1Recent.getId());
        assertThat(map.get(2).getId()).isEqualTo(lot2.getId());
    }

    @Test
    void findLastFinishedByLotsCivique() {
        User user = testData.user();
        UUID themeId = UUID.randomUUID();
        Instant t0 = Instant.now().minus(5, ChronoUnit.HOURS);

        finishedLotCivique(user, themeId, 1, t0);
        Attempt recent = finishedLotCivique(user, themeId, 1, t0.plus(1, ChronoUnit.HOURS));
        // Autre thème → exclu.
        finishedLotCivique(user, UUID.randomUUID(), 1, t0);

        Map<Integer, Attempt> map = manager.findLastFinishedByLotsCivique(user.getId(), themeId);

        assertThat(map).containsOnlyKeys(1);
        assertThat(map.get(1).getId()).isEqualTo(recent.getId());
    }

    @Test
    void findSubAttemptsOrderedByStartedAt() {
        User user = testData.user();
        Attempt parent = base(user);
        parent.setEpreuve(EpreuveType.TCF_COMPLET);
        save(parent);
        Instant t0 = Instant.now().minus(2, ChronoUnit.HOURS);

        Attempt third = sub(parent, user, t0.plus(2, ChronoUnit.HOURS));
        Attempt first = sub(parent, user, t0);
        Attempt second = sub(parent, user, t0.plus(1, ChronoUnit.HOURS));
        // Sous-attempt d'un autre parent → exclu.
        Attempt otherParent = base(user);
        otherParent.setEpreuve(EpreuveType.TCF_COMPLET);
        save(otherParent);
        sub(otherParent, user, t0);

        List<Attempt> subs = manager.findSubAttempts(parent.getId());
        assertThat(subs).extracting(Attempt::getId)
                .containsExactly(first.getId(), second.getId(), third.getId());
    }

    @Test
    void findByIdWithParent() {
        User user = testData.user();
        Attempt parent = base(user);
        parent.setEpreuve(EpreuveType.TCF_COMPLET);
        save(parent);
        Attempt child = sub(parent, user, Instant.now());

        Optional<Attempt> found = manager.findByIdWithParent(child.getId());
        assertThat(found).isPresent();
        assertThat(found.get().getParentAttempt()).isNotNull();
        assertThat(found.get().getParentAttempt().getId()).isEqualTo(parent.getId());

        Attempt lonely = save(base(user));
        assertThat(manager.findByIdWithParent(lonely.getId()))
                .get().extracting(Attempt::getParentAttempt).isNull();
    }

    @Test
    void findByUserAndEpreuveFiltersOrdersAndCaps() {
        User user = testData.user();
        Instant t0 = Instant.now().minus(3, ChronoUnit.HOURS);
        Attempt older = completExam(user, t0);
        Attempt newer = completExam(user, t0.plus(1, ChronoUnit.HOURS));
        // Autre épreuve → exclue.
        save(base(user));

        List<Attempt> all = manager.findByUserAndEpreuve(user.getId(), EpreuveType.TCF_COMPLET, 10);
        assertThat(all).extracting(Attempt::getId).containsExactly(newer.getId(), older.getId());

        List<Attempt> capped = manager.findByUserAndEpreuve(user.getId(), EpreuveType.TCF_COMPLET, 1);
        assertThat(capped).extracting(Attempt::getId).containsExactly(newer.getId());
    }

    @Test
    void findActivityDatesDistinctDescending() {
        User user = testData.user();
        // Heures de milieu de journée UTC → date Europe/Paris non ambiguë.
        startedAt(base(user), instant("2025-01-15T08:00:00Z"));
        startedAt(base(user), instant("2025-01-15T12:00:00Z"));   // même jour
        startedAt(base(user), instant("2025-03-20T12:00:00Z"));

        List<LocalDate> dates = manager.findActivityDates(user.getId());

        assertThat(dates).containsExactly(
                LocalDate.of(2025, 3, 20), LocalDate.of(2025, 1, 15));
    }

    @Test
    void countFinishedMockExams() {
        User user = testData.user();
        Attempt finishedMock = base(user);
        finishedMock.setType(AttemptType.MOCK_EXAM);
        finishedMock.setFinishedAt(Instant.now());
        save(finishedMock);
        // Mock non terminé → exclu.
        Attempt openMock = base(user);
        openMock.setType(AttemptType.MOCK_EXAM);
        save(openMock);
        // Training terminé → exclu.
        Attempt finishedTraining = base(user);
        finishedTraining.setFinishedAt(Instant.now());
        save(finishedTraining);

        assertThat(manager.countFinishedMockExams(user.getId())).isEqualTo(1);
    }

    @Test
    void countProductionExamSessionsRequiresSlotAndSubmission() {
        User user = testData.user();

        // EE avec slot + soumission → compte.
        Attempt ee = base(user);
        ee.setType(AttemptType.MOCK_EXAM);
        ee.setEpreuve(EpreuveType.TCF_EE);
        ee.setSlotNumber(1);
        save(ee);
        testData.productionSubmission(ee, testData.productionTask(), user);

        // EO avec slot mais SANS soumission → exclu.
        Attempt eoNoSub = base(user);
        eoNoSub.setType(AttemptType.MOCK_EXAM);
        eoNoSub.setEpreuve(EpreuveType.TCF_EO);
        eoNoSub.setSlotNumber(1);
        save(eoNoSub);

        // EE avec soumission mais slot null → exclu.
        Attempt eeNoSlot = base(user);
        eeNoSlot.setEpreuve(EpreuveType.TCF_EE);
        save(eeNoSlot);
        testData.productionSubmission(eeNoSlot, testData.productionTask(), user);

        assertThat(manager.countProductionExamSessions(user.getId())).isEqualTo(1);
    }

    @Test
    void findLatestTcfWithCecrlLevel() {
        User user = testData.user();
        Instant t0 = Instant.now().minus(3, ChronoUnit.HOURS);

        Attempt older = base(user);
        older.setFinishedAt(t0);
        older.setCecrlLevel(NiveauCecrl.B1);
        save(older);
        Attempt newer = base(user);
        newer.setFinishedAt(t0.plus(1, ChronoUnit.HOURS));
        newer.setFinalCecrlLevel(NiveauCecrl.B2);
        save(newer);
        // TCF fini sans niveau → exclu.
        Attempt noLevel = base(user);
        noLevel.setFinishedAt(t0.plus(2, ChronoUnit.HOURS));
        save(noLevel);
        // Civique avec niveau → exclu (module).
        Attempt civique = base(user);
        civique.setModule(Module.CIVIQUE);
        civique.setEpreuve(EpreuveType.CIVIQUE);
        civique.setFinishedAt(t0.plus(2, ChronoUnit.HOURS));
        civique.setCecrlLevel(NiveauCecrl.B1);
        save(civique);

        Optional<Attempt> latest = manager.findLatestTcfWithCecrlLevel(user.getId());
        assertThat(latest).map(Attempt::getId).contains(newer.getId());
    }

    // ------------------------------------------------------------------------

    private Attempt base(User user) {
        Attempt a = new Attempt();
        a.setUser(user);
        a.setType(AttemptType.TRAINING);
        a.setModule(Module.TCF);
        a.setEpreuve(EpreuveType.TCF_CO);
        a.setMode(AttemptMode.ENTRAINEMENT);
        a.setStatus(AttemptStatus.EN_COURS);
        a.setStartedAt(Instant.now());
        return a;
    }

    private Attempt save(Attempt a) {
        return manager.save(a);
    }

    private Attempt startedAt(Attempt a, Instant startedAt) {
        a.setStartedAt(startedAt);
        return save(a);
    }

    private Attempt sub(Attempt parent, User user, Instant startedAt) {
        Attempt a = base(user);
        a.setParentAttempt(parent);
        a.setStartedAt(startedAt);
        return save(a);
    }

    private Attempt completExam(User user, Instant startedAt) {
        Attempt a = base(user);
        a.setType(AttemptType.MOCK_EXAM);
        a.setEpreuve(EpreuveType.TCF_COMPLET);
        a.setStartedAt(startedAt);
        return save(a);
    }

    private Attempt finishedLot(User user, int lot, Instant startedAt, Instant finishedAt) {
        Attempt a = base(user);
        a.setModule(Module.TCF);
        a.setLotNumero(lot);
        a.setLotQuestionType(QuestionType.CO);
        a.setLotDifficulty(Difficulty.B1);
        a.setStartedAt(startedAt);
        a.setFinishedAt(finishedAt);
        return save(a);
    }

    private Attempt finishedLotCivique(User user, UUID themeId, int lot, Instant finishedAt) {
        Attempt a = base(user);
        a.setModule(Module.CIVIQUE);
        a.setEpreuve(EpreuveType.CIVIQUE);
        a.setLotNumero(lot);
        a.setLotThemeId(themeId);
        a.setFinishedAt(finishedAt);
        return save(a);
    }

    private static Instant instant(String iso) {
        return Instant.parse(iso);
    }
}
