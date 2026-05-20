package com.sejourfr.app.controller;

import com.sejourfr.app.dto.PageResponse;
import com.sejourfr.app.dto.QuestionDto;
import com.sejourfr.app.dto.QuestionStatusUpdate;
import com.sejourfr.app.dto.QuestionWriteRequest;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.service.QuestionService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.net.URI;
import java.util.UUID;

@RestController
@RequestMapping("/api/admin/questions")
@RequiredArgsConstructor
public class AdminQuestionController {

    private final QuestionService questionService;

    @GetMapping
    public PageResponse<QuestionDto> search(
            @RequestParam(required = false) Module module,
            @RequestParam(required = false) UUID themeId,
            @RequestParam(required = false) Difficulty difficulty,
            @RequestParam(required = false) QuestionType type,
            @RequestParam(required = false) Boolean active,
            @RequestParam(required = false) String search,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        return PageResponse.from(questionService.search(module, themeId, difficulty, type, active, search, pageable));
    }

    @GetMapping("/{id}")
    public QuestionDto getById(@PathVariable UUID id) {
        return questionService.getById(id);
    }

    @PostMapping
    public ResponseEntity<QuestionDto> create(@Valid @RequestBody QuestionWriteRequest req) {
        QuestionDto created = questionService.create(req);
        return ResponseEntity
                .created(URI.create("/api/admin/questions/" + created.id()))
                .body(created);
    }

    @PutMapping("/{id}")
    public QuestionDto update(@PathVariable UUID id, @Valid @RequestBody QuestionWriteRequest req) {
        return questionService.update(id, req);
    }

    @PatchMapping("/{id}/status")
    public QuestionDto setStatus(@PathVariable UUID id, @Valid @RequestBody QuestionStatusUpdate req) {
        return questionService.setActive(id, req.active());
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable UUID id) {
        questionService.delete(id);
    }
}
