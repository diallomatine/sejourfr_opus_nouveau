package com.sejourfr.app.controller;

import com.sejourfr.app.dto.AdminExamTemplateDto;
import com.sejourfr.app.dto.AdminExamTemplateWriteRequest;
import com.sejourfr.app.dto.ExamCompositionSuggestionDto;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.service.AdminExamTemplateService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.net.URI;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/admin/exams")
@RequiredArgsConstructor
public class AdminExamController {

    private final AdminExamTemplateService adminExamTemplateService;

    @GetMapping
    public List<AdminExamTemplateDto> list(@RequestParam(required = false) Module module) {
        return adminExamTemplateService.listAll(module);
    }

    @GetMapping("/{id}")
    public AdminExamTemplateDto getById(@PathVariable UUID id) {
        return adminExamTemplateService.getById(id);
    }

    @PostMapping
    public ResponseEntity<AdminExamTemplateDto> create(@Valid @RequestBody AdminExamTemplateWriteRequest req) {
        AdminExamTemplateDto created = adminExamTemplateService.create(req);
        return ResponseEntity
                .created(URI.create("/api/admin/exams/" + created.id()))
                .body(created);
    }

    @PutMapping("/{id}")
    public AdminExamTemplateDto update(@PathVariable UUID id, @Valid @RequestBody AdminExamTemplateWriteRequest req) {
        return adminExamTemplateService.update(id, req);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable UUID id) {
        adminExamTemplateService.delete(id);
    }

    @GetMapping("/composition-suggestion")
    public ExamCompositionSuggestionDto suggest(
            @RequestParam Module module,
            @RequestParam(required = false) TargetProcedure targetProcedure,
            @RequestParam(required = false) TargetLevel targetLevel,
            @RequestParam(required = false) Integer totalQuestions) {
        return adminExamTemplateService.suggestComposition(module, targetProcedure, targetLevel, totalQuestions);
    }
}
