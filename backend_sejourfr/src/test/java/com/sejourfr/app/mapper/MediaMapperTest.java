package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.MediaDto;
import com.sejourfr.app.entity.Media;
import com.sejourfr.app.enums.MediaType;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class MediaMapperTest {

    private final MediaMapper mapper = new MediaMapper();

    @Test
    void toDto_mapsEveryField() {
        UUID id = UUID.randomUUID();
        Instant created = Instant.parse("2026-01-02T03:04:05Z");
        Media m = new Media();
        m.setId(id);
        m.setType(MediaType.AUDIO);
        m.setUrl("https://r2.example/audio.mp3");
        m.setOriginalFilename("audio.mp3");
        m.setContentType("audio/mpeg");
        m.setSizeBytes(123456L);
        m.setDurationSec(42);
        m.setAltText("description");
        m.setCreatedAt(created);

        MediaDto dto = mapper.toDto(m);

        assertThat(dto.id()).isEqualTo(id);
        assertThat(dto.type()).isEqualTo(MediaType.AUDIO);
        assertThat(dto.url()).isEqualTo("https://r2.example/audio.mp3");
        assertThat(dto.originalFilename()).isEqualTo("audio.mp3");
        assertThat(dto.contentType()).isEqualTo("audio/mpeg");
        assertThat(dto.sizeBytes()).isEqualTo(123456L);
        assertThat(dto.durationSec()).isEqualTo(42);
        assertThat(dto.altText()).isEqualTo("description");
        assertThat(dto.createdAt()).isEqualTo(created);
    }

    @Test
    void toDto_nullableFields_passthrough() {
        Media m = new Media();
        m.setId(UUID.randomUUID());
        m.setType(MediaType.IMAGE);

        MediaDto dto = mapper.toDto(m);

        assertThat(dto.url()).isNull();
        assertThat(dto.originalFilename()).isNull();
        assertThat(dto.contentType()).isNull();
        assertThat(dto.sizeBytes()).isNull();
        assertThat(dto.durationSec()).isNull();
        assertThat(dto.altText()).isNull();
        assertThat(dto.createdAt()).isNull();
        assertThat(dto.type()).isEqualTo(MediaType.IMAGE);
    }
}
