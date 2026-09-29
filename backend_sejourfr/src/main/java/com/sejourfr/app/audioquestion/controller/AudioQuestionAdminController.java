package com.sejourfr.app.audioquestion.controller;

import com.sejourfr.app.audioquestion.dto.GenerateAudioQuestionRequest;
import com.sejourfr.app.audioquestion.dto.GenerationLogDto;
import com.sejourfr.app.audioquestion.dto.QuestionPreviewDto;
import com.sejourfr.app.audioquestion.dto.ValidationResultDto;
import com.sejourfr.app.audioquestion.entity.GenerationStatus;
import com.sejourfr.app.audioquestion.service.AudioQuestionGenerationService;
import com.sejourfr.app.audioquestion.service.AudioQuestionLifecycleService;
import com.sejourfr.app.audioquestion.service.AudioQuestionLogService;
import com.sejourfr.app.dto.PageResponse;
import com.sejourfr.app.security.CurrentUser;
import jakarta.validation.Valid;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

/**
 * Endpoints admin de la pipeline audio CO.
 * Securite : protege globalement par SecurityConfig (hasRole("ADMIN") sur /api/admin/**).
 */
@RestController
@RequestMapping("/api/admin/audio-questions")
public class AudioQuestionAdminController {

    private final AudioQuestionGenerationService generationService;
    private final AudioQuestionLifecycleService lifecycleService;
    private final AudioQuestionLogService logService;
    private final CurrentUser currentUser;

    public AudioQuestionAdminController(
            AudioQuestionGenerationService generationService,
            AudioQuestionLifecycleService lifecycleService,
            AudioQuestionLogService logService,
            CurrentUser currentUser) {
        this.generationService = generationService;
        this.lifecycleService = lifecycleService;
        this.logService = logService;
        this.currentUser = currentUser;
    }

    @PostMapping("/generate")
    public QuestionPreviewDto generate(@Valid @RequestBody GenerateAudioQuestionRequest request) {
        return generationService.generate(request, currentUser.getId());
    }

    @GetMapping("/{id}/preview")
    public QuestionPreviewDto preview(@PathVariable UUID id) {
        return lifecycleService.preview(id);
    }

    @PatchMapping("/{id}/validate")
    public ValidationResultDto validate(@PathVariable UUID id) {
        return lifecycleService.validate(id, currentUser.getId());
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void reject(@PathVariable UUID id) {
        lifecycleService.reject(id, currentUser.getId());
    }

    @GetMapping("/generation-logs")
    public PageResponse<GenerationLogDto> logs(
            @PageableDefault(size = 20, sort = "createdAt") Pageable pageable,
            @RequestParam(required = false) GenerationStatus status,
            @RequestParam(required = false) UUID adminUserId) {
        return PageResponse.from(logService.findLogs(pageable, status, adminUserId));
    }
}
