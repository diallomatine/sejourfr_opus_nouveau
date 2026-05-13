package com.sejourfr.app.question;

import com.sejourfr.app.common.PageResponse;
import com.sejourfr.app.question.enums.Difficulty;
import com.sejourfr.app.question.enums.QuestionType;
import com.sejourfr.app.theme.enums.Module;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.net.URI;
import java.util.UUID;

@RestController
@RequestMapping("/api/admin/questions")
public class AdminQuestionController {

    private final QuestionService service;

    public AdminQuestionController(QuestionService service) {
        this.service = service;
    }

    @GetMapping
    public PageResponse<QuestionDto> search(
            @RequestParam(required = false) Module module,
            @RequestParam(required = false) UUID themeId,
            @RequestParam(required = false) Difficulty difficulty,
            @RequestParam(required = false) QuestionType type,
            @RequestParam(required = false) Boolean active,
            @RequestParam(required = false) String search,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable
    ) {
        Page<QuestionDto> page = service.search(module, themeId, difficulty, type, active, search, pageable);
        return PageResponse.from(page);
    }

    @GetMapping("/{id}")
    public QuestionDto getById(@PathVariable UUID id) {
        return service.getById(id);
    }

    @PostMapping
    public ResponseEntity<QuestionDto> create(@Valid @RequestBody QuestionWriteRequest req) {
        QuestionDto created = service.create(req);
        return ResponseEntity
                .created(URI.create("/api/admin/questions/" + created.id()))
                .body(created);
    }

    @PutMapping("/{id}")
    public QuestionDto update(@PathVariable UUID id, @Valid @RequestBody QuestionWriteRequest req) {
        return service.update(id, req);
    }

    @PatchMapping("/{id}/status")
    public QuestionDto setStatus(@PathVariable UUID id, @Valid @RequestBody QuestionStatusUpdate req) {
        return service.setActive(id, req.active());
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable UUID id) {
        service.delete(id);
    }
}
