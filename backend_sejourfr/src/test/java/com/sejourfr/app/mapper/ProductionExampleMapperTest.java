package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.ProductionExampleDto;
import com.sejourfr.app.entity.ProductionExample;
import com.sejourfr.app.enums.ExampleAudioStatus;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class ProductionExampleMapperTest {

    private final ProductionExampleMapper mapper = new ProductionExampleMapper();

    private ProductionExample base(UUID id) {
        ProductionExample e = new ProductionExample();
        e.setId(id);
        e.setTitre("Le boulanger");
        e.setResume("Un boulanger se présente");
        e.setContenu("Bonjour, je m'appelle…");
        e.setExplications("Structure claire");
        e.setAudioUrl("https://r2.example/ex.mp3");
        e.setPlanPoints(List.of("intro", "métier", "conclusion"));
        e.setNiveauIndicatif("B1");
        return e;
    }

    @Test
    void toDto_publishedAudio_exposesAudioUrl() {
        UUID id = UUID.randomUUID();
        ProductionExample e = base(id);
        e.setAudioStatus(ExampleAudioStatus.PUBLISHED);

        ProductionExampleDto dto = mapper.toDto(e);

        assertThat(dto.id()).isEqualTo(id);
        assertThat(dto.titre()).isEqualTo("Le boulanger");
        assertThat(dto.resume()).isEqualTo("Un boulanger se présente");
        assertThat(dto.contenu()).isEqualTo("Bonjour, je m'appelle…");
        assertThat(dto.explications()).isEqualTo("Structure claire");
        assertThat(dto.audioUrl()).isEqualTo("https://r2.example/ex.mp3");
        assertThat(dto.planPoints()).containsExactly("intro", "métier", "conclusion");
        assertThat(dto.niveauIndicatif()).isEqualTo("B1");
    }

    @Test
    void toDto_nonPublishedAudio_hidesAudioUrl() {
        ProductionExample e = base(UUID.randomUUID());
        e.setAudioStatus(ExampleAudioStatus.GENERATED);

        ProductionExampleDto dto = mapper.toDto(e);

        assertThat(dto.audioUrl()).isNull();
    }

    @Test
    void toDto_nullPlanPoints_becomesEmptyList() {
        ProductionExample e = base(UUID.randomUUID());
        e.setAudioStatus(ExampleAudioStatus.NONE);
        e.setPlanPoints(null);

        ProductionExampleDto dto = mapper.toDto(e);

        assertThat(dto.planPoints()).isEmpty();
        assertThat(dto.audioUrl()).isNull();
    }
}
