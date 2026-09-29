package com.sejourfr.app.service;

import com.sejourfr.app.dto.ProductionExampleDto;
import com.sejourfr.app.entity.ProductionExample;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Lecture des exemples-modeles par (epreuve, tache) sur Postgres embarque (cf.
 * {@link ProductionExampleService}). Seed reel via {@link TestData}.
 */
class ProductionExampleServiceIT extends AbstractIntegrationTest {

    private static final Map<Short, Set<UUID>> SEEDED_EE_EXAMPLE_IDS = Map.of(
            (short) 1, Set.of(
                    UUID.fromString("a1f1e1d1-0001-4a01-9b01-1a1a1a1a0001"),
                    UUID.fromString("a1f1e1d1-0001-4a01-9b01-1a1a1a1a0002"),
                    UUID.fromString("a1f1e1d1-0001-4a01-9b01-1a1a1a1a0003")),
            (short) 2, Set.of(
                    UUID.fromString("a1f1e1d1-0002-4a02-9b02-2a2a2a2a0001"),
                    UUID.fromString("a1f1e1d1-0002-4a02-9b02-2a2a2a2a0002"),
                    UUID.fromString("a1f1e1d1-0002-4a02-9b02-2a2a2a2a0003")),
            (short) 3, Set.of(
                    UUID.fromString("a1f1e1d1-0003-4a03-9b03-3a3a3a3a0001"),
                    UUID.fromString("a1f1e1d1-0003-4a03-9b03-3a3a3a3a0002"),
                    UUID.fromString("a1f1e1d1-0003-4a03-9b03-3a3a3a3a0003"))
    );

    @Autowired
    private ProductionExampleService service;
    @Autowired
    private TestData data;

    @Test
    void listByEpreuveAndTache_retourne_les_exemples_de_la_categorie() {
        ProductionTask task = data.productionTask(EpreuveType.TCF_EE); // tacheNumero 1
        ProductionExample example = data.productionExample(task);

        List<ProductionExampleDto> result = service.listByEpreuveAndTache(EpreuveType.TCF_EE, (short) 1);

        assertThat(result).extracting(ProductionExampleDto::id).contains(example.getId());
    }

    @Test
    void exemplesEeSeedes_respectent_les_volumes_du_tcfIrn_et_le_plafondB2() {
        SEEDED_EE_EXAMPLE_IDS.forEach((tache, ids) -> {
            int minWords = tache == 1 ? 30 : 40;
            int maxWords = tache == 1 ? 60 : 90;
            List<ProductionExampleDto> seeded = service
                    .listByEpreuveAndTache(EpreuveType.TCF_EE, tache)
                    .stream()
                    .filter(example -> ids.contains(example.id()))
                    .toList();

            assertThat(seeded).hasSize(3).allSatisfy(example ->
                    assertThat(wordCount(example.contenu())).isBetween(minWords, maxWords));
            assertThat(seeded)
                    .extracting(ProductionExampleDto::niveauIndicatif)
                    .containsExactlyInAnyOrder("A2", "B1", "B2");
        });
    }

    @Test
    void listByEpreuveAndTache_epreuve_non_productive_refuse() {
        assertThatThrownBy(() -> service.listByEpreuveAndTache(EpreuveType.CIVIQUE, (short) 1))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void listByEpreuveAndTache_tacheNumero_hors_bornes_refuse() {
        assertThatThrownBy(() -> service.listByEpreuveAndTache(EpreuveType.TCF_EE, (short) 0))
                .isInstanceOf(BusinessException.class);
    }

    private static int wordCount(String text) {
        return text.trim().split("\\s+").length;
    }
}
