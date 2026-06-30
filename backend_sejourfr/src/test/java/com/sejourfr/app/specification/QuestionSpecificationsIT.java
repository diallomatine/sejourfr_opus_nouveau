package com.sejourfr.app.specification;

import com.sejourfr.app.entity.Question;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.repository.QuestionRepository;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.jpa.domain.Specification;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Intégration réelle (Postgres embarqué) de {@link QuestionSpecifications}.
 * Les prédicats sont exercés via {@code findAll(spec)} pour valider le SQL.
 * Combinaison via {@link Specification#allOf} comme {@code QuestionService}.
 *
 * <p>La table {@code questions} est seedée par Flyway → assertions tolérantes
 * (filtrage sur les ids créés via {@code contains}/{@code doesNotContain},
 * jamais de total exact). Pour les dimensions où la portée est restreinte à un
 * {@link Theme} fraîchement créé, on combine avec {@code hasTheme} afin de
 * borner le jeu de résultats aux lignes du test et faire des assertions
 * exactes.</p>
 */
class QuestionSpecificationsIT extends AbstractIntegrationTest {

    @Autowired
    private QuestionRepository repository;

    @Autowired
    private TestData testData;

    private Question question(Theme theme, Module module, Difficulty difficulty,
                             QuestionType type, boolean active, String statement) {
        Question q = testData.question(theme);
        q.setModule(module);
        q.setDifficulty(difficulty);
        q.setQuestionType(type);
        q.setActive(active);
        q.setStatement(statement);
        return repository.save(q);
    }

    /** Borne les résultats au thème du test → assertions exactes possibles. */
    private List<Question> findInTheme(Theme theme, Specification<Question> spec) {
        return repository.findAll(Specification.allOf(
                QuestionSpecifications.hasTheme(theme.getId()), spec));
    }

    @Test
    void hasModuleFiltersByModule() {
        Theme theme = testData.theme();
        Question tcf = question(theme, Module.TCF, Difficulty.B1, QuestionType.CO, true, "tcf");
        Question civique = question(theme, Module.CIVIQUE, Difficulty.CSP, QuestionType.CONNAISSANCE, true, "civ");

        assertThat(findInTheme(theme, QuestionSpecifications.hasModule(Module.TCF)))
                .extracting(Question::getId)
                .containsExactly(tcf.getId())
                .doesNotContain(civique.getId());
    }

    @Test
    void hasModuleNullAddsNoPredicate() {
        Theme theme = testData.theme();
        Question tcf = question(theme, Module.TCF, Difficulty.B1, QuestionType.CO, true, "tcf");
        Question civique = question(theme, Module.CIVIQUE, Difficulty.CSP, QuestionType.CONNAISSANCE, true, "civ");

        assertThat(findInTheme(theme, QuestionSpecifications.hasModule(null)))
                .extracting(Question::getId)
                .containsExactlyInAnyOrder(tcf.getId(), civique.getId());
    }

    @Test
    void hasThemeFiltersByThemeAndNullMatchesAll() {
        Theme themeA = testData.theme();
        Theme themeB = testData.theme();
        Question a = question(themeA, Module.CIVIQUE, Difficulty.CSP, QuestionType.CONNAISSANCE, true, "a");
        Question b = question(themeB, Module.CIVIQUE, Difficulty.CSP, QuestionType.CONNAISSANCE, true, "b");

        assertThat(repository.findAll(QuestionSpecifications.hasTheme(themeA.getId())))
                .extracting(Question::getId)
                .containsExactly(a.getId())
                .doesNotContain(b.getId());
        // null → pas de prédicat → couvre les deux (table seedée → contains)
        assertThat(repository.findAll(QuestionSpecifications.hasTheme(null)))
                .extracting(Question::getId).contains(a.getId(), b.getId());
    }

    @Test
    void hasDifficultyFiltersByDifficultyAndNullMatchesAll() {
        Theme theme = testData.theme();
        Question b1 = question(theme, Module.TCF, Difficulty.B1, QuestionType.CO, true, "b1");
        Question b2 = question(theme, Module.TCF, Difficulty.B2, QuestionType.CO, true, "b2");

        assertThat(findInTheme(theme, QuestionSpecifications.hasDifficulty(Difficulty.B1)))
                .extracting(Question::getId)
                .containsExactly(b1.getId())
                .doesNotContain(b2.getId());
        assertThat(findInTheme(theme, QuestionSpecifications.hasDifficulty(null)))
                .extracting(Question::getId)
                .containsExactlyInAnyOrder(b1.getId(), b2.getId());
    }

    @Test
    void hasTypeIsPreciseAndDoesNotIncludeCoImage() {
        Theme theme = testData.theme();
        Question co = question(theme, Module.TCF, Difficulty.B1, QuestionType.CO, true, "co");
        Question coImage = question(theme, Module.TCF, Difficulty.B1, QuestionType.CO_IMAGE, true, "coimg");
        Question ce = question(theme, Module.TCF, Difficulty.B1, QuestionType.CE, true, "ce");

        // hasType(CO) est précis : n'inclut PAS CO_IMAGE (≠ findRandom côté repo)
        assertThat(findInTheme(theme, QuestionSpecifications.hasType(QuestionType.CO)))
                .extracting(Question::getId)
                .containsExactly(co.getId())
                .doesNotContain(coImage.getId(), ce.getId());
        // null → tout le thème
        assertThat(findInTheme(theme, QuestionSpecifications.hasType(null)))
                .extracting(Question::getId)
                .containsExactlyInAnyOrder(co.getId(), coImage.getId(), ce.getId());
    }

    @Test
    void hasActiveFiltersByActiveAndNullMatchesAll() {
        Theme theme = testData.theme();
        Question active = question(theme, Module.CIVIQUE, Difficulty.CSP, QuestionType.CONNAISSANCE, true, "on");
        Question inactive = question(theme, Module.CIVIQUE, Difficulty.CSP, QuestionType.CONNAISSANCE, false, "off");

        assertThat(findInTheme(theme, QuestionSpecifications.hasActive(false)))
                .extracting(Question::getId)
                .containsExactly(inactive.getId())
                .doesNotContain(active.getId());
        assertThat(findInTheme(theme, QuestionSpecifications.hasActive(true)))
                .extracting(Question::getId)
                .containsExactly(active.getId())
                .doesNotContain(inactive.getId());
        assertThat(findInTheme(theme, QuestionSpecifications.hasActive(null)))
                .extracting(Question::getId)
                .containsExactlyInAnyOrder(active.getId(), inactive.getId());
    }

    @Test
    void statementContainsIsCaseInsensitiveAndNullOrBlankAddsNoPredicate() {
        Theme theme = testData.theme();
        String token = "ZEBRAMARKER" + System.nanoTime();
        Question match = question(theme, Module.CIVIQUE, Difficulty.CSP, QuestionType.CONNAISSANCE, true,
                "Enonce avec " + token + " dedans");
        Question other = question(theme, Module.CIVIQUE, Difficulty.CSP, QuestionType.CONNAISSANCE, true,
                "Enonce sans marqueur");

        // recherche en minuscules sur un énoncé en majuscules
        assertThat(findInTheme(theme, QuestionSpecifications.statementContains(token.toLowerCase())))
                .extracting(Question::getId)
                .containsExactly(match.getId())
                .doesNotContain(other.getId());
        assertThat(findInTheme(theme, QuestionSpecifications.statementContains("   ")))
                .extracting(Question::getId)
                .containsExactlyInAnyOrder(match.getId(), other.getId());
        assertThat(findInTheme(theme, QuestionSpecifications.statementContains(null)))
                .extracting(Question::getId)
                .containsExactlyInAnyOrder(match.getId(), other.getId());
    }

    @Test
    void allOfCombinesAllFiltersLikeService() {
        Theme theme = testData.theme();
        String token = "combomarker" + System.nanoTime();

        Question hit = question(theme, Module.TCF, Difficulty.B1, QuestionType.CO, true, "ok " + token);
        // chaque near-miss diffère par exactement un critère
        Question wrongModule = question(theme, Module.CIVIQUE, Difficulty.B1, QuestionType.CO, true, "x " + token);
        Question wrongDiff = question(theme, Module.TCF, Difficulty.B2, QuestionType.CO, true, "x " + token);
        Question wrongType = question(theme, Module.TCF, Difficulty.B1, QuestionType.CE, true, "x " + token);
        Question coImage = question(theme, Module.TCF, Difficulty.B1, QuestionType.CO_IMAGE, true, "x " + token);
        Question inactive = question(theme, Module.TCF, Difficulty.B1, QuestionType.CO, false, "x " + token);
        Question wrongText = question(theme, Module.TCF, Difficulty.B1, QuestionType.CO, true, "sans marqueur");

        Specification<Question> spec = Specification.allOf(
                QuestionSpecifications.hasModule(Module.TCF),
                QuestionSpecifications.hasTheme(theme.getId()),
                QuestionSpecifications.hasDifficulty(Difficulty.B1),
                QuestionSpecifications.hasType(QuestionType.CO),
                QuestionSpecifications.hasActive(true),
                QuestionSpecifications.statementContains(token));

        assertThat(repository.findAll(spec))
                .extracting(Question::getId)
                .containsExactly(hit.getId())
                .doesNotContain(wrongModule.getId(), wrongDiff.getId(), wrongType.getId(),
                        coImage.getId(), inactive.getId(), wrongText.getId());
    }
}
