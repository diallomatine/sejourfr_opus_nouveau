package com.sejourfr.app.audioquestion.service;

import com.sejourfr.app.audioquestion.dto.GenerationLogDto;
import com.sejourfr.app.audioquestion.entity.AudioQuestionGenerationLog;
import com.sejourfr.app.audioquestion.entity.GenerationStatus;
import com.sejourfr.app.audioquestion.repository.AudioQuestionGenerationLogRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.util.UUID;

/** Liste paginee des logs d'audit, avec filtres optionnels par status et admin. */
@Service
public class AudioQuestionLogService {

    private final AudioQuestionGenerationLogRepository repository;

    public AudioQuestionLogService(AudioQuestionGenerationLogRepository repository) {
        this.repository = repository;
    }

    public Page<GenerationLogDto> findLogs(Pageable pageable, GenerationStatus status, UUID adminUserId) {
        Page<AudioQuestionGenerationLog> page;
        if (status != null && adminUserId != null) {
            page = repository.findByStatusAndAdminUserId(status, adminUserId, pageable);
        } else if (status != null) {
            page = repository.findByStatus(status, pageable);
        } else if (adminUserId != null) {
            page = repository.findByAdminUserId(adminUserId, pageable);
        } else {
            page = repository.findAll(pageable);
        }
        return page.map(this::toDto);
    }

    private GenerationLogDto toDto(AudioQuestionGenerationLog l) {
        return new GenerationLogDto(
            l.getId(),
            l.getQuestionId(),
            l.getAdminUserId(),
            l.getRequestedParams(),
            l.getPromptVersion(),
            l.getAnthropicModel(),
            l.getAnthropicInputTokens(),
            l.getAnthropicOutputTokens(),
            l.getAnthropicCacheReadTokens(),
            l.getAnthropicCostEur(),
            l.getAzureCharactersCount(),
            l.getAzureCostEur(),
            l.getR2ObjectKey(),
            l.getDurationMs(),
            l.getStatus(),
            l.getErrorMessage(),
            l.getCreatedAt()
        );
    }
}
