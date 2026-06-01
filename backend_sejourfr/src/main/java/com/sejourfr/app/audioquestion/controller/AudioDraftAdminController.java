package com.sejourfr.app.audioquestion.controller;

import com.sejourfr.app.audioquestion.dto.AudioDraftDto;
import com.sejourfr.app.audioquestion.dto.BatchGenerationResultDto;
import com.sejourfr.app.audioquestion.dto.RejectDraftRequest;
import com.sejourfr.app.audioquestion.service.AudioDraftService;
import com.sejourfr.app.dto.PageResponse;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.security.CurrentUser;
import jakarta.validation.Valid;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.util.Map;
import java.util.UUID;

/**
 * Endpoints admin du workflow batch de generation audio (drafts).
 * Securite : /api/admin/** -> hasRole("ADMIN") via SecurityConfig.
 */
@RestController
@RequestMapping("/api/admin/audio-drafts")
public class AudioDraftAdminController {

    private final AudioDraftService draftService;
    private final CurrentUser currentUser;

    public AudioDraftAdminController(AudioDraftService draftService, CurrentUser currentUser) {
        this.draftService = draftService;
        this.currentUser = currentUser;
    }

    @PostMapping("/batch-generate")
    public BatchGenerationResultDto batchGenerate(
            @RequestParam(required = false) Difficulty difficulty) {
        return draftService.generateBatchAudio(difficulty);
    }

    @GetMapping("/pending-review")
    public PageResponse<AudioDraftDto> pendingReview(
            @RequestParam(required = false) Difficulty difficulty,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.ASC) Pageable pageable) {
        return PageResponse.from(draftService.listPendingReview(difficulty, pageable));
    }

    @GetMapping("/pending-review/count")
    public Map<String, Long> pendingReviewCount(
            @RequestParam(required = false) Difficulty difficulty) {
        return Map.of("count", draftService.countPendingReview(difficulty));
    }

    @PostMapping("/{id}/validate")
    public AudioDraftDto validate(@PathVariable UUID id) {
        return draftService.validateDraft(id, currentUser.getId());
    }

    @PostMapping(value = "/{id}/image", consumes = org.springframework.http.MediaType.MULTIPART_FORM_DATA_VALUE)
    public AudioDraftDto replaceImage(
            @PathVariable UUID id,
            @RequestPart("file") MultipartFile file) {
        return draftService.replaceDraftImage(id, file);
    }

    @PostMapping("/{id}/reject")
    public AudioDraftDto reject(
            @PathVariable UUID id,
            @Valid @RequestBody RejectDraftRequest request) {
        return draftService.rejectDraft(id, request.reason(), currentUser.getId());
    }
}
