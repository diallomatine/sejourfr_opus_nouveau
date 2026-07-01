package com.sejourfr.app.service;

import com.sejourfr.app.dto.MediaCreateFromUrlRequest;
import com.sejourfr.app.dto.MediaDto;
import com.sejourfr.app.enums.MediaType;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.support.AbstractIntegrationTest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class MediaServiceIT extends AbstractIntegrationTest {

    @Autowired
    private MediaService mediaService;

    @Test
    void createFromUrlThenGetById() {
        MediaDto created = mediaService.createFromUrl(new MediaCreateFromUrlRequest(
                MediaType.AUDIO, "https://cdn.example/clip.mp3", 90, "alt"));

        assertThat(created.id()).isNotNull();
        assertThat(created.type()).isEqualTo(MediaType.AUDIO);
        assertThat(created.url()).isEqualTo("https://cdn.example/clip.mp3");
        assertThat(created.durationSec()).isEqualTo(90);
        assertThat(created.altText()).isEqualTo("alt");

        MediaDto fetched = mediaService.getById(created.id());
        assertThat(fetched.url()).isEqualTo("https://cdn.example/clip.mp3");
    }

    @Test
    void getByIdAbsentThrowsNotFound() {
        assertThatThrownBy(() -> mediaService.getById(UUID.randomUUID()))
                .isInstanceOf(NotFoundException.class);
    }

    @Test
    void deleteRemovesUrlMedia() {
        // URL externe : storageKey null → pas d'appel storage à la suppression.
        MediaDto created = mediaService.createFromUrl(new MediaCreateFromUrlRequest(
                MediaType.IMAGE, "https://cdn.example/img.png", null, null));
        mediaService.delete(created.id());

        assertThatThrownBy(() -> mediaService.getById(created.id()))
                .isInstanceOf(NotFoundException.class);
    }

    @Test
    void deleteAbsentThrowsNotFound() {
        assertThatThrownBy(() -> mediaService.delete(UUID.randomUUID()))
                .isInstanceOf(NotFoundException.class);
    }
}
