package com.sejourfr.app.audioquestion.service;

import com.sejourfr.app.audioquestion.config.AudioGenerationProperties;
import com.sejourfr.app.audioquestion.entity.GenerationStatus;
import com.sejourfr.app.audioquestion.exception.RateLimitExceededException;
import com.sejourfr.app.audioquestion.repository.AudioQuestionGenerationLogRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class GenerationRateLimiterTest {

    @Mock
    private AudioQuestionGenerationLogRepository logRepository;

    private final AudioGenerationProperties props = new AudioGenerationProperties();
    private final UUID adminId = UUID.randomUUID();

    private GenerationRateLimiter limiter() {
        return new GenerationRateLimiter(logRepository, props);
    }

    @Test
    void checkAllowed_quota_desactive_ne_consulte_pas_le_repo() {
        props.setRateLimitPerMinute(0);

        assertThatCode(() -> limiter().checkAllowed(adminId))
            .doesNotThrowAnyException();
        verifyNoInteractions(logRepository);
    }

    @Test
    void checkAllowed_sous_le_quota_passe() {
        props.setRateLimitPerMinute(10);
        when(logRepository.countByAdminUserIdAndStatusAndCreatedAtAfter(
            eq(adminId), eq(GenerationStatus.SUCCESS), any(Instant.class)
        )).thenReturn(9L);

        assertThatCode(() -> limiter().checkAllowed(adminId))
            .doesNotThrowAnyException();
    }

    @Test
    void checkAllowed_au_quota_leve_rate_limit_exceeded() {
        props.setRateLimitPerMinute(10);
        when(logRepository.countByAdminUserIdAndStatusAndCreatedAtAfter(
            eq(adminId), eq(GenerationStatus.SUCCESS), any(Instant.class)
        )).thenReturn(10L);
        // Pas de plus ancien connu -> retombe sur oneMinuteAgo -> retryAfter clampe a 1s.
        when(logRepository.findOldestRecentSuccessAt(eq(adminId), any(Instant.class)))
            .thenReturn(Optional.empty());

        assertThatThrownBy(() -> limiter().checkAllowed(adminId))
            .isInstanceOf(RateLimitExceededException.class)
            .hasMessageContaining("Quota de 10")
            .extracting(e -> ((RateLimitExceededException) e).getRetryAfterSeconds())
            .isEqualTo(1L);
    }

    @Test
    void checkAllowed_calcule_retry_after_depuis_le_plus_ancien_succes() {
        props.setRateLimitPerMinute(5);
        when(logRepository.countByAdminUserIdAndStatusAndCreatedAtAfter(
            eq(adminId), eq(GenerationStatus.SUCCESS), any(Instant.class)
        )).thenReturn(5L);
        // Plus ancien succes il y a ~10s -> il reste ~50s avant qu'il sorte de la fenetre.
        when(logRepository.findOldestRecentSuccessAt(eq(adminId), any(Instant.class)))
            .thenReturn(Optional.of(Instant.now().minusSeconds(10)));

        assertThatThrownBy(() -> limiter().checkAllowed(adminId))
            .isInstanceOf(RateLimitExceededException.class)
            .satisfies(e -> {
                long retry = ((RateLimitExceededException) e).getRetryAfterSeconds();
                assertThat(retry).isBetween(40L, 60L);
            });
    }
}
