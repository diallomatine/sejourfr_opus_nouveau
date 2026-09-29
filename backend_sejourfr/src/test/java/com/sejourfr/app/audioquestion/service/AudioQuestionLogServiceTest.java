package com.sejourfr.app.audioquestion.service;

import com.sejourfr.app.audioquestion.dto.GenerationLogDto;
import com.sejourfr.app.audioquestion.entity.AudioQuestionGenerationLog;
import com.sejourfr.app.audioquestion.entity.GenerationStatus;
import com.sejourfr.app.audioquestion.repository.AudioQuestionGenerationLogRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Liste paginee des logs d'audit : on verifie que chaque combinaison de filtres
 * route vers la bonne methode du repo et que le mapping vers {@link GenerationLogDto}
 * preserve les champs cles.
 */
@ExtendWith(MockitoExtension.class)
class AudioQuestionLogServiceTest {

    @Mock private AudioQuestionGenerationLogRepository repository;

    @InjectMocks private AudioQuestionLogService service;

    private final Pageable pageable = PageRequest.of(0, 20);

    private AudioQuestionGenerationLog log(UUID questionId, UUID adminId) {
        AudioQuestionGenerationLog l = new AudioQuestionGenerationLog();
        l.setId(UUID.randomUUID());
        l.setQuestionId(questionId);
        l.setAdminUserId(adminId);
        l.setStatus(GenerationStatus.SUCCESS);
        l.setAnthropicModel("claude-test");
        return l;
    }

    @Test
    void findLogs_filtre_status_et_admin() {
        UUID adminId = UUID.randomUUID();
        AudioQuestionGenerationLog l = log(UUID.randomUUID(), adminId);
        when(repository.findByStatusAndAdminUserId(GenerationStatus.SUCCESS, adminId, pageable))
            .thenReturn(new PageImpl<>(List.of(l)));

        Page<GenerationLogDto> page = service.findLogs(pageable, GenerationStatus.SUCCESS, adminId);

        assertThat(page.getContent()).hasSize(1);
        GenerationLogDto dto = page.getContent().get(0);
        assertThat(dto.id()).isEqualTo(l.getId());
        assertThat(dto.adminUserId()).isEqualTo(adminId);
        assertThat(dto.status()).isEqualTo(GenerationStatus.SUCCESS);
        assertThat(dto.anthropicModel()).isEqualTo("claude-test");
        verify(repository, never()).findAll(pageable);
    }

    @Test
    void findLogs_filtre_status_seul() {
        when(repository.findByStatus(GenerationStatus.FAILED_DUPLICATE, pageable))
            .thenReturn(new PageImpl<>(List.of(log(null, UUID.randomUUID()))));

        Page<GenerationLogDto> page = service.findLogs(pageable, GenerationStatus.FAILED_DUPLICATE, null);

        assertThat(page.getContent()).hasSize(1);
        verify(repository).findByStatus(GenerationStatus.FAILED_DUPLICATE, pageable);
    }

    @Test
    void findLogs_filtre_admin_seul() {
        UUID adminId = UUID.randomUUID();
        when(repository.findByAdminUserId(adminId, pageable))
            .thenReturn(new PageImpl<>(List.of(log(null, adminId))));

        service.findLogs(pageable, null, adminId);

        verify(repository).findByAdminUserId(adminId, pageable);
    }

    @Test
    void findLogs_sans_filtre_renvoie_tout() {
        when(repository.findAll(pageable)).thenReturn(new PageImpl<>(List.of(log(null, UUID.randomUUID()))));

        service.findLogs(pageable, null, null);

        verify(repository).findAll(pageable);
    }
}
