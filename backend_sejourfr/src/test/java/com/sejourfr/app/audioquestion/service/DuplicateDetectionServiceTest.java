package com.sejourfr.app.audioquestion.service;

import com.sejourfr.app.audioquestion.config.AudioGenerationProperties;
import com.sejourfr.app.audioquestion.exception.DuplicateContentException;
import com.sejourfr.app.repository.MediaRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.anyDouble;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Verifie la logique de seuil anti-doublon : on delegue a {@code pg_trgm} cote
 * repo, mais le service doit passer le seuil configure et lever
 * {@link DuplicateContentException} uniquement si un transcript similaire existe.
 */
@ExtendWith(MockitoExtension.class)
class DuplicateDetectionServiceTest {

    @Mock
    private MediaRepository mediaRepository;

    private final AudioGenerationProperties props = new AudioGenerationProperties();

    private DuplicateDetectionService service() {
        return new DuplicateDetectionService(mediaRepository, props);
    }

    @Test
    void checkNotDuplicate_leve_si_un_transcript_similaire_existe() {
        when(mediaRepository.findSimilarTranscript(eq("B1"), eq("Bonjour Madame"), anyDouble()))
            .thenReturn(Optional.of("Bonjour Madame, comment allez-vous ?"));

        assertThatThrownBy(() -> service().checkNotDuplicate("Bonjour Madame", "B1"))
            .isInstanceOf(DuplicateContentException.class)
            .hasMessageContaining("B1");
    }

    @Test
    void checkNotDuplicate_ne_leve_pas_si_aucun_doublon() {
        when(mediaRepository.findSimilarTranscript(eq("A2"), eq("Texte inedit"), anyDouble()))
            .thenReturn(Optional.empty());

        assertThatCode(() -> service().checkNotDuplicate("Texte inedit", "A2"))
            .doesNotThrowAnyException();
    }

    @Test
    void checkNotDuplicate_transmet_le_seuil_configure_au_repo() {
        props.setDuplicateSimilarityThreshold(new BigDecimal("0.73"));
        when(mediaRepository.findSimilarTranscript(eq("B2"), eq("x"), anyDouble()))
            .thenReturn(Optional.empty());

        service().checkNotDuplicate("x", "B2");

        ArgumentCaptor<Double> threshold = ArgumentCaptor.forClass(Double.class);
        verify(mediaRepository).findSimilarTranscript(eq("B2"), eq("x"), threshold.capture());
        assertThat(threshold.getValue()).isEqualTo(0.73);
    }
}
