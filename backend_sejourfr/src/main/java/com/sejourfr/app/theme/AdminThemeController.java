package com.sejourfr.app.theme;

import com.sejourfr.app.theme.enums.Module;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.net.URI;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/admin/themes")
public class AdminThemeController {

    private final ThemeService service;

    public AdminThemeController(ThemeService service) {
        this.service = service;
    }

    @GetMapping
    public List<ThemeDto> list(@RequestParam(required = false) Module module) {
        return module == null ? service.listAll() : service.listByModule(module);
    }

    @GetMapping("/{id}")
    public ThemeDto getById(@PathVariable UUID id) {
        return service.getById(id);
    }

    @PostMapping
    public ResponseEntity<ThemeDto> create(@Valid @RequestBody ThemeWriteRequest req) {
        ThemeDto created = service.create(req);
        return ResponseEntity
                .created(URI.create("/api/admin/themes/" + created.id()))
                .body(created);
    }

    @PutMapping("/{id}")
    public ThemeDto update(@PathVariable UUID id, @Valid @RequestBody ThemeWriteRequest req) {
        return service.update(id, req);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable UUID id) {
        service.delete(id);
    }
}
