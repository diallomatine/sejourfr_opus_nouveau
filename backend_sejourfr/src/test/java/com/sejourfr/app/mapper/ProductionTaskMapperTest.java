package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.ProductionTaskDto;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;
import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class ProductionTaskMapperTest {

    private final ProductionTaskMapper mapper = new ProductionTaskMapper();

    @Test
    void toDto_mapsEveryField() {
        UUID id = UUID.randomUUID();
        ProductionTask task = new ProductionTask();
        task.setId(id);
        task.setEpreuve(EpreuveType.TCF_EE);
        task.setTacheNumero((short) 2);
        task.setNiveauCible("B1");
        task.setConsigne("Rédigez un message");
        task.setContexte("Vous écrivez à un ami");
        task.setDureeMaxSec(600);
        task.setDureeMinSec(120);
        task.setMotsMin(60);
        task.setMotsMax(120);

        ProductionTaskDto dto = mapper.toDto(task);

        assertThat(dto.id()).isEqualTo(id);
        assertThat(dto.epreuve()).isEqualTo(EpreuveType.TCF_EE);
        assertThat(dto.tacheNumero()).isEqualTo((short) 2);
        assertThat(dto.niveauCible()).isEqualTo("B1");
        assertThat(dto.consigne()).isEqualTo("Rédigez un message");
        assertThat(dto.contexte()).isEqualTo("Vous écrivez à un ami");
        assertThat(dto.dureeMaxSec()).isEqualTo(600);
        assertThat(dto.dureeMinSec()).isEqualTo(120);
        assertThat(dto.motsMin()).isEqualTo(60);
        assertThat(dto.motsMax()).isEqualTo(120);
    }

    @Test
    void toDto_nullTacheNumero_defaultsToZero() {
        ProductionTask task = new ProductionTask();
        task.setId(UUID.randomUUID());
        task.setEpreuve(EpreuveType.TCF_EO);
        task.setTacheNumero(null);
        task.setNiveauCible("A2");
        task.setConsigne("Présentez-vous");

        ProductionTaskDto dto = mapper.toDto(task);

        assertThat(dto.tacheNumero()).isEqualTo((short) 0);
        assertThat(dto.contexte()).isNull();
        assertThat(dto.dureeMaxSec()).isNull();
        assertThat(dto.motsMin()).isNull();
    }
}
