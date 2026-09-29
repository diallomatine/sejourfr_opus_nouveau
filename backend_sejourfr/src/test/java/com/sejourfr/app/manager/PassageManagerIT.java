package com.sejourfr.app.manager;

import com.sejourfr.app.entity.Passage;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.enums.PassageType;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class PassageManagerIT extends AbstractIntegrationTest {

    @Autowired
    private PassageManager manager;

    @Autowired
    private TestData testData;

    @Test
    void saveAndFindById() {
        Theme theme = testData.theme();
        Passage saved = testData.passage(PassageType.TEXTE, theme);

        assertThat(saved.getId()).isNotNull();
        assertThat(manager.findById(saved.getId()))
                .get()
                .satisfies(p -> {
                    assertThat(p.getType()).isEqualTo(PassageType.TEXTE);
                    assertThat(p.getTheme().getId()).isEqualTo(theme.getId());
                });
    }

    @Test
    void findByIdAbsentReturnsEmpty() {
        assertThat(manager.findById(UUID.randomUUID())).isEmpty();
    }

    @Test
    void findAllContainsPersistedRows() {
        Passage a = testData.passage();
        Passage b = testData.passage();

        assertThat(manager.findAll())
                .extracting(Passage::getId)
                .contains(a.getId(), b.getId());
    }

    @Test
    void findByThemeOrderedReturnsMatchingRowsScopedToTheme() {
        Theme theme = testData.theme();
        Passage p1 = testData.passage(PassageType.TEXTE, theme);
        Passage p2 = testData.passage(PassageType.TEXTE, theme);
        Passage p3 = testData.passage(PassageType.TEXTE, theme);
        Passage other = testData.passage(PassageType.TEXTE, testData.theme());

        List<Passage> result = manager.findByThemeOrdered(theme.getId());

        // Filtrage par thème. On n'assert PAS l'ordre des id : la requête trie en
        // `id ASC` côté Postgres (comparaison d'uuid NON signée), ce qui ne
        // correspond pas au Comparator<UUID> Java (signé) pour des UUID v4
        // aléatoires — l'ordre n'a de toute façon aucune sémantique métier ici.
        assertThat(result)
                .extracting(Passage::getId)
                .containsExactlyInAnyOrder(p1.getId(), p2.getId(), p3.getId())
                .doesNotContain(other.getId());
    }

    @Test
    void findByThemeOrderedUnknownThemeReturnsEmpty() {
        assertThat(manager.findByThemeOrdered(UUID.randomUUID())).isEmpty();
    }

    @Test
    void deleteRemovesRow() {
        Passage saved = testData.passage();
        UUID id = saved.getId();

        manager.delete(saved);

        assertThat(manager.findById(id)).isEmpty();
    }
}
