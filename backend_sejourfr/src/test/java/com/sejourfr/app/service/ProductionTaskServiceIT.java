package com.sejourfr.app.service;

import com.sejourfr.app.dto.ProductionTaskDto;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Lecture du catalogue EO/EE sur Postgres embarque (cf.
 * {@link ProductionTaskService}) : filtres de validation + requetes reelles du
 * manager seedees via {@link TestData}.
 */
class ProductionTaskServiceIT extends AbstractIntegrationTest {

    @Autowired
    private ProductionTaskService service;
    @Autowired
    private TestData data;

    @Test
    void listActiveTasks_retourne_les_taches_actives_de_l_epreuve() {
        ProductionTask ee = data.productionTask(EpreuveType.TCF_EE);

        List<ProductionTaskDto> tasks = service.listActiveTasks(EpreuveType.TCF_EE, null, null);

        assertThat(tasks).extracting(ProductionTaskDto::id).contains(ee.getId());
        assertThat(tasks).allSatisfy(t -> assertThat(t.epreuve()).isEqualTo(EpreuveType.TCF_EE));
    }

    @Test
    void listActiveTasks_filtre_par_niveau_normalise_en_majuscules() {
        ProductionTask ee = data.productionTask(EpreuveType.TCF_EE); // niveauCible "B1"

        List<ProductionTaskDto> tasks = service.listActiveTasks(EpreuveType.TCF_EE, "b1", (short) 1);

        assertThat(tasks).extracting(ProductionTaskDto::id).contains(ee.getId());
    }

    @Test
    void listActiveTasks_epreuve_non_productive_refuse() {
        assertThatThrownBy(() -> service.listActiveTasks(EpreuveType.CIVIQUE, null, null))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void listActiveTasks_tacheNumero_hors_bornes_refuse() {
        assertThatThrownBy(() -> service.listActiveTasks(EpreuveType.TCF_EE, null, (short) 5))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void getActiveTask_renvoie_le_dto() {
        ProductionTask eo = data.productionTask(EpreuveType.TCF_EO);

        ProductionTaskDto dto = service.getActiveTask(eo.getId());

        assertThat(dto.id()).isEqualTo(eo.getId());
        assertThat(dto.epreuve()).isEqualTo(EpreuveType.TCF_EO);
        // Coherence CHECK V011 : EO porte une duree, pas de fourchette de mots.
        assertThat(dto.dureeMaxSec()).isNotNull();
        assertThat(dto.motsMin()).isNull();
    }

    @Test
    void getActiveTask_absente_renvoie_404() {
        assertThatThrownBy(() -> service.getActiveTask(UUID.randomUUID()))
                .isInstanceOf(NotFoundException.class);
    }
}
