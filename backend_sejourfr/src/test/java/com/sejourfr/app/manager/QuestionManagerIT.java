package com.sejourfr.app.manager;

import com.sejourfr.app.entity.Passage;
import com.sejourfr.app.entity.Question;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.specification.QuestionSpecifications;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.jpa.domain.Specification;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Set;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class QuestionManagerIT extends AbstractIntegrationTest {

    @Autowired
    private QuestionManager manager;

    @Autowired
    private TestData testData;

    @Test
    void saveAndFindById() {
        Theme theme = testData.theme(Module.TCF, "qSave", "Thème save");
        Question q = q(theme, Module.TCF, Difficulty.B1, QuestionType.CO, true, null);
        assertThat(q.getId()).isNotNull();
        assertThat(q.getCreatedAt()).isNotNull();   // @PrePersist

        assertThat(manager.findById(q.getId())).isPresent();
    }

    @Test
    void findByIdAbsentReturnsEmpty() {
        assertThat(manager.findById(UUID.randomUUID())).isEmpty();
    }

    @Test
    void findAllByIdReturnsOnlyKnownIds() {
        Theme theme = testData.theme(Module.TCF, "qAllById", "Thème allById");
        Question q1 = q(theme, Module.TCF, Difficulty.B1, QuestionType.CO, true, null);
        Question q2 = q(theme, Module.TCF, Difficulty.B1, QuestionType.CO, true, null);
        Question q3 = q(theme, Module.TCF, Difficulty.B1, QuestionType.CO, true, null);

        List<Question> found = manager.findAllById(List.of(q1.getId(), q2.getId(), UUID.randomUUID()));

        assertThat(found).extracting(Question::getId)
                .containsExactlyInAnyOrder(q1.getId(), q2.getId());
        assertThat(found).extracting(Question::getId).doesNotContain(q3.getId());
    }

    @Test
    void countByThemeAndActiveByTheme() {
        Theme theme = testData.theme(Module.TCF, "qCountTheme", "Thème count");
        q(theme, Module.TCF, Difficulty.B1, QuestionType.CO, true, null);
        q(theme, Module.TCF, Difficulty.B1, QuestionType.CO, true, null);
        q(theme, Module.TCF, Difficulty.B1, QuestionType.CO, false, null);   // inactive

        assertThat(manager.countByTheme(theme.getId())).isEqualTo(3);
        assertThat(manager.countActiveByTheme(theme.getId())).isEqualTo(2);
        assertThat(manager.countByTheme(UUID.randomUUID())).isZero();
    }

    @Test
    void countByPassage() {
        Passage passage = testData.passage();
        Theme theme = testData.theme(Module.CIVIQUE, "qPassage", "Thème passage");
        Question withPassage = q(theme, Module.CIVIQUE, Difficulty.CSP, QuestionType.CONNAISSANCE, true, null);
        withPassage.setPassage(passage);
        manager.save(withPassage);
        Question withPassage2 = q(theme, Module.CIVIQUE, Difficulty.CSP, QuestionType.CONNAISSANCE, true, null);
        withPassage2.setPassage(passage);
        manager.save(withPassage2);
        // Sans passage → exclu.
        q(theme, Module.CIVIQUE, Difficulty.CSP, QuestionType.CONNAISSANCE, true, null);

        assertThat(manager.countByPassage(passage.getId())).isEqualTo(2);
        assertThat(manager.countByPassage(UUID.randomUUID())).isZero();
    }

    @Test
    void countByModuleUsesDelta() {
        long beforeAll = manager.countByModule(Module.TCF);
        long beforeActive = manager.countByModuleAndActive(Module.TCF, true);
        long beforeInactive = manager.countByModuleAndActive(Module.TCF, false);
        Theme theme = testData.theme(Module.TCF, "qModule", "Thème module");

        q(theme, Module.TCF, Difficulty.B1, QuestionType.CO, true, null);
        q(theme, Module.TCF, Difficulty.B1, QuestionType.CO, true, null);
        q(theme, Module.TCF, Difficulty.B1, QuestionType.CO, false, null);

        assertThat(manager.countByModule(Module.TCF)).isEqualTo(beforeAll + 3);
        assertThat(manager.countByModuleAndActive(Module.TCF, true)).isEqualTo(beforeActive + 2);
        assertThat(manager.countByModuleAndActive(Module.TCF, false)).isEqualTo(beforeInactive + 1);
    }

    @Test
    void countActiveMatchingHonoursFiltersAndCoImage() {
        Theme theme = testData.theme(Module.TCF, "qMatching", "Thème matching");
        q(theme, Module.TCF, Difficulty.B1, QuestionType.CO, true, null);
        q(theme, Module.TCF, Difficulty.B1, QuestionType.CO, true, null);
        q(theme, Module.TCF, Difficulty.B1, QuestionType.CO_IMAGE, true, null);   // inclus par le filtre CO
        q(theme, Module.TCF, Difficulty.B1, QuestionType.CE, true, null);
        q(theme, Module.TCF, Difficulty.B1, QuestionType.CO, false, null);        // inactive → exclue

        // CO inclut CO_IMAGE → 2 CO + 1 CO_IMAGE.
        assertThat(manager.countActiveMatching(Module.TCF, theme.getId(), Difficulty.B1, QuestionType.CO))
                .isEqualTo(3);
        assertThat(manager.countActiveMatching(Module.TCF, theme.getId(), Difficulty.B1, QuestionType.CE))
                .isEqualTo(1);
        // Pas de filtre type/difficulty → toutes les actives du thème.
        assertThat(manager.countActiveMatching(Module.TCF, theme.getId(), null, null))
                .isEqualTo(4);
    }

    @Test
    void findDemoPoolIsDeterministicCappedAndOrdered() {
        Theme theme = testData.theme(Module.CIVIQUE, "qDemo", "Thème demo");
        for (int i = 0; i < 5; i++) {
            q(theme, Module.CIVIQUE, Difficulty.CSP, QuestionType.CONNAISSANCE, true, null);
        }

        List<Question> first = manager.findDemoPool(Module.CIVIQUE, 3);
        List<Question> second = manager.findDemoPool(Module.CIVIQUE, 3);

        assertThat(first).hasSizeLessThanOrEqualTo(3);
        // Déterministe : deux appels → même série, même ordre.
        assertThat(first).extracting(Question::getId)
                .containsExactlyElementsOf(second.stream().map(Question::getId).toList());
        assertThat(first).allMatch(Question::isActive);
        assertThat(first).allMatch(q -> q.getModule() == Module.CIVIQUE);
        assertOrderedByCreatedAtThenId(first);
    }

    @Test
    void findRandomFiltersPoolAndCaps() {
        Theme theme = testData.theme(Module.TCF, "qRandom", "Thème random");
        Question co1 = q(theme, Module.TCF, Difficulty.B1, QuestionType.CO, true, null);
        Question co2 = q(theme, Module.TCF, Difficulty.B1, QuestionType.CO, true, null);
        Question co3 = q(theme, Module.TCF, Difficulty.B1, QuestionType.CO, true, null);
        Question coImage = q(theme, Module.TCF, Difficulty.B1, QuestionType.CO_IMAGE, true, null);
        q(theme, Module.TCF, Difficulty.B1, QuestionType.CE, true, null);       // mauvais type
        q(theme, Module.TCF, Difficulty.A2, QuestionType.CO, true, null);       // mauvaise difficulté
        q(theme, Module.TCF, Difficulty.B1, QuestionType.CO, false, null);      // inactive
        Set<UUID> expected = Set.of(co1.getId(), co2.getId(), co3.getId(), coImage.getId());

        List<Question> all = manager.findRandom(Module.TCF, theme.getId(), Difficulty.B1, QuestionType.CO, 20);
        assertThat(all).extracting(Question::getId).containsExactlyInAnyOrderElementsOf(expected);
        assertThat(all).extracting(Question::getId).contains(coImage.getId());   // CO inclut CO_IMAGE

        List<Question> capped = manager.findRandom(Module.TCF, theme.getId(), Difficulty.B1, QuestionType.CO, 2);
        assertThat(capped).hasSize(2);
        assertThat(expected).containsAll(capped.stream().map(Question::getId).toList());
    }

    @Test
    void findRandomExcludingDropsExcludedIds() {
        Theme theme = testData.theme(Module.TCF, "qRandExcl", "Thème rand excl");
        Question a = q(theme, Module.TCF, Difficulty.B1, QuestionType.CO, true, null);
        Question b = q(theme, Module.TCF, Difficulty.B1, QuestionType.CO, true, null);
        Question c = q(theme, Module.TCF, Difficulty.B1, QuestionType.CO, true, null);
        Question d = q(theme, Module.TCF, Difficulty.B1, QuestionType.CO, true, null);

        List<Question> remaining = manager.findRandomExcluding(
                Module.TCF, theme.getId(), Difficulty.B1, QuestionType.CO, List.of(a.getId(), b.getId()), 20);
        assertThat(remaining).extracting(Question::getId)
                .containsExactlyInAnyOrder(c.getId(), d.getId());

        // excludeIds vide → bascule sur findRandom (pool complet).
        List<Question> full = manager.findRandomExcluding(
                Module.TCF, theme.getId(), Difficulty.B1, QuestionType.CO, List.of(), 20);
        assertThat(full).extracting(Question::getId)
                .containsExactlyInAnyOrder(a.getId(), b.getId(), c.getId(), d.getId());
    }

    @Test
    void findOrderedExcludingIsDeterministicAndExcludes() {
        Theme theme = testData.theme(Module.TCF, "qOrdExcl", "Thème ord excl");
        Instant t0 = Instant.now().minus(5, ChronoUnit.HOURS);
        Question q1 = q(theme, Module.TCF, Difficulty.B1, QuestionType.CE, true, t0);
        Question q2 = q(theme, Module.TCF, Difficulty.B1, QuestionType.CE, true, t0.plus(1, ChronoUnit.HOURS));
        Question q3 = q(theme, Module.TCF, Difficulty.B1, QuestionType.CE, true, t0.plus(2, ChronoUnit.HOURS));

        List<Question> ordered = manager.findOrderedExcluding(
                Module.TCF, theme.getId(), Difficulty.B1, QuestionType.CE, List.of(q2.getId()), 20);
        assertThat(ordered).extracting(Question::getId).containsExactly(q1.getId(), q3.getId());

        List<Question> full = manager.findOrderedExcluding(
                Module.TCF, theme.getId(), Difficulty.B1, QuestionType.CE, List.of(), 20);
        assertThat(full).extracting(Question::getId).containsExactly(q1.getId(), q2.getId(), q3.getId());
    }

    @Test
    void findLotQuestionsPaginatesOrderedPool() {
        Theme theme = testData.theme(Module.TCF, "qLot", "Thème lot");
        Instant t0 = Instant.now().minus(10, ChronoUnit.HOURS);
        for (int i = 0; i < 5; i++) {
            q(theme, Module.TCF, Difficulty.A2, QuestionType.STRUCTURE, true, t0.plus(i, ChronoUnit.MINUTES));
        }

        List<Question> lot1 = manager.findLotQuestions(Module.TCF, QuestionType.STRUCTURE, Difficulty.A2, 1, 2);
        List<Question> lot2 = manager.findLotQuestions(Module.TCF, QuestionType.STRUCTURE, Difficulty.A2, 2, 2);

        assertThat(lot1).hasSize(2);
        assertThat(lot2).hasSize(2);
        // Fenêtres disjointes.
        assertThat(lot1).extracting(Question::getId)
                .doesNotContainAnyElementsOf(lot2.stream().map(Question::getId).toList());
        // Ordre stable createdAt ASC, id ASC sur la concaténation des deux lots.
        List<Question> concat = java.util.stream.Stream.concat(lot1.stream(), lot2.stream()).toList();
        assertOrderedByCreatedAtThenId(concat);
    }

    @Test
    void findLotQuestionsCiviqueIsolatesByTheme() {
        Theme theme = testData.theme(Module.CIVIQUE, "qLotCiv", "Thème lot civique");
        Instant t0 = Instant.now().minus(10, ChronoUnit.HOURS);
        Question q1 = q(theme, Module.CIVIQUE, Difficulty.CSP, QuestionType.CONNAISSANCE, true, t0);
        Question q2 = q(theme, Module.CIVIQUE, Difficulty.CSP, QuestionType.CONNAISSANCE, true, t0.plus(1, ChronoUnit.MINUTES));
        Question q3 = q(theme, Module.CIVIQUE, Difficulty.CSP, QuestionType.CONNAISSANCE, true, t0.plus(2, ChronoUnit.MINUTES));
        Question q4 = q(theme, Module.CIVIQUE, Difficulty.CSP, QuestionType.CONNAISSANCE, true, t0.plus(3, ChronoUnit.MINUTES));

        List<Question> lot1 = manager.findLotQuestionsCivique(theme.getId(), 1, 2);
        List<Question> lot2 = manager.findLotQuestionsCivique(theme.getId(), 2, 2);

        assertThat(lot1).extracting(Question::getId).containsExactly(q1.getId(), q2.getId());
        assertThat(lot2).extracting(Question::getId).containsExactly(q3.getId(), q4.getId());
    }

    @Test
    void searchWithSpecifications() {
        Theme theme = testData.theme(Module.TCF, "qSearch", "Thème search");
        Question coActive = q(theme, Module.TCF, Difficulty.B1, QuestionType.CO, true, null);
        Question ceActive = q(theme, Module.TCF, Difficulty.B1, QuestionType.CE, true, null);
        Question coInactive = q(theme, Module.TCF, Difficulty.B1, QuestionType.CO, false, null);

        // Combo 1 : thème + actives → CO active + CE active.
        Specification<Question> activeInTheme = QuestionSpecifications.hasTheme(theme.getId())
                .and(QuestionSpecifications.hasActive(true));
        Page<Question> active = manager.search(activeInTheme, PageRequest.of(0, 10));
        assertThat(active.getContent()).extracting(Question::getId)
                .containsExactlyInAnyOrder(coActive.getId(), ceActive.getId());
        assertThat(active.getContent()).extracting(Question::getId).doesNotContain(coInactive.getId());

        // Combo 2 : thème + type CO → CO active + CO inactive (le filtre type est strict).
        Specification<Question> coInTheme = QuestionSpecifications.hasTheme(theme.getId())
                .and(QuestionSpecifications.hasType(QuestionType.CO));
        Page<Question> co = manager.search(coInTheme, PageRequest.of(0, 10));
        assertThat(co.getContent()).extracting(Question::getId)
                .containsExactlyInAnyOrder(coActive.getId(), coInactive.getId());
    }

    @Test
    void existsByIdAndDeleteById() {
        Theme theme = testData.theme(Module.TCF, "qDelete", "Thème delete");
        Question q = q(theme, Module.TCF, Difficulty.B1, QuestionType.CO, true, null);
        UUID id = q.getId();
        assertThat(manager.existsById(id)).isTrue();
        assertThat(manager.existsById(UUID.randomUUID())).isFalse();

        manager.deleteById(id);

        assertThat(manager.existsById(id)).isFalse();
        assertThat(manager.findById(id)).isEmpty();
    }

    // ------------------------------------------------------------------------

    private Question q(Theme theme, Module module, Difficulty difficulty,
                       QuestionType type, boolean active, Instant createdAt) {
        Question qn = new Question();
        qn.setModule(module);
        qn.setTheme(theme);
        qn.setDifficulty(difficulty);
        qn.setQuestionType(type);
        qn.setStatement("Énoncé " + UUID.randomUUID());
        qn.setActive(active);
        if (createdAt != null) qn.setCreatedAt(createdAt);
        return manager.save(qn);
    }

    private static void assertOrderedByCreatedAtThenId(List<Question> questions) {
        for (int i = 1; i < questions.size(); i++) {
            Question prev = questions.get(i - 1);
            Question cur = questions.get(i);
            int cmp = prev.getCreatedAt().compareTo(cur.getCreatedAt());
            assertThat(cmp).isLessThanOrEqualTo(0);
            if (cmp == 0) {
                assertThat(prev.getId().toString()).isLessThanOrEqualTo(cur.getId().toString());
            }
        }
    }
}
