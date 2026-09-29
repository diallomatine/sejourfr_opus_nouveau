package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.PassageDto;
import com.sejourfr.app.entity.Media;
import com.sejourfr.app.entity.Passage;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.enums.MediaType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.PassageType;
import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class PassageMapperTest {

    private final PassageMapper mapper = new PassageMapper();

    @Test
    void toDto_withThemeAndMedia_mapsEveryField() {
        UUID passageId = UUID.randomUUID();
        UUID themeId = UUID.randomUUID();
        UUID mediaId = UUID.randomUUID();

        Theme theme = new Theme();
        theme.setId(themeId);
        theme.setName("Compréhension");
        theme.setModule(Module.TCF);
        theme.setCode("CO");

        Media media = new Media();
        media.setId(mediaId);
        media.setType(MediaType.AUDIO);
        media.setUrl("https://r2.example/p.mp3");

        Passage p = new Passage();
        p.setId(passageId);
        p.setType(PassageType.DIALOGUE);
        p.setContent("Un dialogue entre deux personnes.");
        p.setTheme(theme);
        p.setMedia(media);

        PassageDto dto = mapper.toDto(p, 9L);

        assertThat(dto.id()).isEqualTo(passageId);
        assertThat(dto.type()).isEqualTo(PassageType.DIALOGUE);
        assertThat(dto.content()).isEqualTo("Un dialogue entre deux personnes.");
        assertThat(dto.themeId()).isEqualTo(themeId);
        assertThat(dto.themeName()).isEqualTo("Compréhension");
        assertThat(dto.mediaId()).isEqualTo(mediaId);
        assertThat(dto.mediaUrl()).isEqualTo("https://r2.example/p.mp3");
        assertThat(dto.mediaType()).isEqualTo(MediaType.AUDIO);
        assertThat(dto.questionCount()).isEqualTo(9L);
    }

    @Test
    void toDto_nullThemeAndMedia_yieldNullAssociations() {
        Passage p = new Passage();
        p.setId(UUID.randomUUID());
        p.setType(PassageType.TEXTE);
        p.setContent("Texte sans média ni thème.");

        PassageDto dto = mapper.toDto(p, 0L);

        assertThat(dto.themeId()).isNull();
        assertThat(dto.themeName()).isNull();
        assertThat(dto.mediaId()).isNull();
        assertThat(dto.mediaUrl()).isNull();
        assertThat(dto.mediaType()).isNull();
        assertThat(dto.questionCount()).isZero();
    }
}
