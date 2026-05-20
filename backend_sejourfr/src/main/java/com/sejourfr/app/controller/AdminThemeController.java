package com.sejourfr.app.controller;

import com.sejourfr.app.dto.ThemeDto;
import com.sejourfr.app.dto.ThemeWriteRequest;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.service.ThemeService;
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
@RequestMapping("/api/admin/themes")
@RequiredArgsConstructor
public class AdminThemeController {

    private final ThemeService themeService;

    @GetMapping
    public List<ThemeDto> list(@RequestParam(required = false) Module module) {
        return module == null ? themeService.listAll() : themeService.listByModule(module);
    }

    @GetMapping("/{id}")
    public ThemeDto getById(@PathVariable UUID id) {
        return themeService.getById(id);
    }

    @PostMapping
    public ResponseEntity<ThemeDto> create(@Valid @RequestBody ThemeWriteRequest req) {
        ThemeDto created = themeService.create(req);
        return ResponseEntity
                .created(URI.create("/api/admin/themes/" + created.id()))
                .body(created);
    }

    @PutMapping("/{id}")
    public ThemeDto update(@PathVariable UUID id, @Valid @RequestBody ThemeWriteRequest req) {
        return themeService.update(id, req);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable UUID id) {
        themeService.delete(id);
    }
}
