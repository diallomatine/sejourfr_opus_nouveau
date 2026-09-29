package com.sejourfr.app.service;

import com.sejourfr.app.config.StorageProperties;
import com.sejourfr.app.dto.StoredFile;
import com.sejourfr.app.exception.BusinessException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.mock.web.MockMultipartFile;

import java.nio.file.Files;
import java.nio.file.Path;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class LocalFileStorageServiceTest {

    @TempDir
    Path tempDir;

    private StorageProperties properties;
    private LocalFileStorageService service;

    @BeforeEach
    void setUp() {
        properties = new StorageProperties();
        properties.getLocal().setRoot(tempDir.toString());
        properties.getLocal().setPublicBaseUrl("http://localhost:8080/files");
        service = new LocalFileStorageService(properties);
        service.init();
    }

    private MockMultipartFile png(byte[] bytes) {
        return new MockMultipartFile("file", "photo.png", "image/png", bytes);
    }

    @Test
    void storeWritesFileAndReturnsMetadata() {
        StoredFile stored = service.store(png(new byte[]{1, 2, 3, 4, 5}));

        assertThat(stored.storageKey()).matches("\\d{4}/\\d{2}/.+-photo\\.png");
        assertThat(stored.publicUrl())
                .isEqualTo("http://localhost:8080/files/" + stored.storageKey());
        assertThat(stored.contentType()).isEqualTo("image/png");
        assertThat(stored.sizeBytes()).isEqualTo(5L);
        assertThat(stored.originalFilename()).isEqualTo("photo.png");

        Path written = tempDir.resolve(stored.storageKey());
        assertThat(Files.exists(written)).isTrue();
    }

    @Test
    void storeRejectsEmptyFile() {
        assertThatThrownBy(() -> service.store(new MockMultipartFile("file", new byte[0])))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("vide");
    }

    @Test
    void storeRejectsFileTooLarge() {
        properties.setMaxFileSizeBytes(2);
        assertThatThrownBy(() -> service.store(png(new byte[]{1, 2, 3, 4})))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("volumineux");
    }

    @Test
    void storeRejectsDisallowedContentType() {
        MockMultipartFile txt = new MockMultipartFile("file", "x.txt", "text/plain", new byte[]{1});
        assertThatThrownBy(() -> service.store(txt))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("non autorise");
    }

    @Test
    void storeRejectsNullContentType() {
        MockMultipartFile noType = new MockMultipartFile("file", "x.png", null, new byte[]{1});
        assertThatThrownBy(() -> service.store(noType))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("Content-Type manquant");
    }

    @Test
    void storeSanitizesUnsafeFilename() {
        MockMultipartFile evil = new MockMultipartFile(
                "file", "../../evil name.png", "image/png", new byte[]{1});
        StoredFile stored = service.store(evil);

        assertThat(stored.originalFilename()).isEqualTo("evil_name.png");
        assertThat(stored.storageKey()).endsWith("-evil_name.png");
        assertThat(stored.storageKey()).doesNotContain("..");
    }

    @Test
    void deleteRemovesStoredFile() {
        StoredFile stored = service.store(png(new byte[]{9, 9}));
        Path written = tempDir.resolve(stored.storageKey());
        assertThat(Files.exists(written)).isTrue();

        service.delete(stored.storageKey());
        assertThat(Files.exists(written)).isFalse();
    }

    @Test
    void deleteWithBlankKeyIsNoop() {
        service.delete("");
        service.delete(null);
        // Aucune exception attendue.
    }
}
