package com.sejourfr.app.controller;

import com.sejourfr.app.dto.PassageDto;
import com.sejourfr.app.dto.PassageWriteRequest;
import com.sejourfr.app.service.PassageService;
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
@RequestMapping("/api/admin/passages")
@RequiredArgsConstructor
public class AdminPassageController {

    private final PassageService passageService;

    @GetMapping
    public List<PassageDto> list(@RequestParam(required = false) UUID themeId) {
        return passageService.list(themeId);
    }

    @GetMapping("/{id}")
    public PassageDto getById(@PathVariable UUID id) {
        return passageService.getById(id);
    }

    @PostMapping
    public ResponseEntity<PassageDto> create(@Valid @RequestBody PassageWriteRequest req) {
        PassageDto created = passageService.create(req);
        return ResponseEntity
                .created(URI.create("/api/admin/passages/" + created.id()))
                .body(created);
    }

    @PutMapping("/{id}")
    public PassageDto update(@PathVariable UUID id, @Valid @RequestBody PassageWriteRequest req) {
        return passageService.update(id, req);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable UUID id) {
        passageService.delete(id);
    }
}
