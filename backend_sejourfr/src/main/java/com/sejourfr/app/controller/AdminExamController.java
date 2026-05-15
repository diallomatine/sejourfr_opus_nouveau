package com.sejourfr.app.controller;

import com.sejourfr.app.dto.AdminExamTemplateDto;
import com.sejourfr.app.dto.AdminExamTemplateWriteRequest;
import com.sejourfr.app.dto.ExamCompositionSuggestionDto;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.service.AdminExamTemplateService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.net.URI;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/admin/exams")
public class AdminExamController {

    private final AdminExamTemplateService service;

    public AdminExamController(AdminExamTemplateService service) {
        this.service = service;
    }

    @GetMapping
    public List<AdminExamTemplateDto> list(@RequestParam(required = false) Module module) {
        return service.listAll(module);
    }

    @GetMapping("/{id}")
    public AdminExamTemplateDto getById(@PathVariable UUID id) {
        return service.getById(id);
    }

    @PostMapping
    public ResponseEntity<AdminExamTemplateDto> create(@Valid @RequestBody AdminExamTemplateWriteRequest req) {
        AdminExamTemplateDto created = service.create(req);
        return ResponseEntity
                .created(URI.create("/api/admin/exams/" + created.id()))
                .body(created);
    }

    @PutMapping("/{id}")
    public AdminExamTemplateDto update(@PathVariable UUID id, @Valid @RequestBody AdminExamTemplateWriteRequest req) {
        return service.update(id, req);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable UUID id) {
        service.delete(id);
    }

    @GetMapping("/composition-suggestion")
    public ExamCompositionSuggestionDto suggest(
            @RequestParam Module module,
            @RequestParam(required = false) TargetProcedure targetProcedure,
            @RequestParam(required = false) TargetLevel targetLevel,
            @RequestParam(required = false) Integer totalQuestions
    ) {
        return service.suggestComposition(module, targetProcedure, targetLevel, totalQuestions);
    }
}
