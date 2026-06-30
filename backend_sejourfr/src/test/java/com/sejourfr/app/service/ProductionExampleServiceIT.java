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

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Lecture des exemples-modeles par (epreuve, tache) sur Postgres embarque (cf.
 * {@link ProductionExampleService}). Seed reel via {@link TestData}.
 */
class ProductionExampleServiceIT extends AbstractIntegrationTest {

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
    void listByEpreuveAndTache_epreuve_non_productive_refuse() {
        assertThatThrownBy(() -> service.listByEpreuveAndTache(EpreuveType.CIVIQUE, (short) 1))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void listByEpreuveAndTache_tacheNumero_hors_bornes_refuse() {
        assertThatThrownBy(() -> service.listByEpreuveAndTache(EpreuveType.TCF_EE, (short) 0))
                .isInstanceOf(BusinessException.class);
    }
}
