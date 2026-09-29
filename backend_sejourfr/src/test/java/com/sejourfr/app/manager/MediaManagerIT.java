package com.sejourfr.app.manager;

import com.sejourfr.app.entity.Media;
import com.sejourfr.app.enums.MediaType;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class MediaManagerIT extends AbstractIntegrationTest {

    @Autowired
    private MediaManager mediaManager;

    @Autowired
    private TestData testData;

    @Test
    void saveAndFindById() {
        Media saved = testData.media(MediaType.AUDIO);
        assertThat(saved.getId()).isNotNull();
        assertThat(saved.getCreatedAt()).isNotNull();   // @PrePersist

        Optional<Media> found = mediaManager.findById(saved.getId());
        assertThat(found).isPresent();
        assertThat(found.get().getType()).isEqualTo(MediaType.AUDIO);
    }

    @Test
    void findByIdAbsentReturnsEmpty() {
        assertThat(mediaManager.findById(UUID.randomUUID())).isEmpty();
    }

    @Test
    void deleteRemovesRow() {
        Media m = testData.media();
        UUID id = m.getId();
        assertThat(mediaManager.findById(id)).isPresent();

        mediaManager.delete(m);

        assertThat(mediaManager.findById(id)).isEmpty();
    }
}
