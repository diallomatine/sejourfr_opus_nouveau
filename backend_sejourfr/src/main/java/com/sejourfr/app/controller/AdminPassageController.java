package com.sejourfr.app.controller;

import com.sejourfr.app.dto.PassageDto;
import com.sejourfr.app.dto.PassageWriteRequest;
import com.sejourfr.app.service.PassageService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.net.URI;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/admin/passages")
public class AdminPassageController {

    private final PassageService service;

    public AdminPassageController(PassageService service) {
        this.service = service;
    }

    @GetMapping
    public List<PassageDto> list(@RequestParam(required = false) UUID themeId) {
        return service.list(themeId);
    }

    @GetMapping("/{id}")
    public PassageDto getById(@PathVariable UUID id) {
        return service.getById(id);
    }

    @PostMapping
    public ResponseEntity<PassageDto> create(@Valid @RequestBody PassageWriteRequest req) {
        PassageDto created = service.create(req);
        return ResponseEntity
                .created(URI.create("/api/admin/passages/" + created.id()))
                .body(created);
    }

    @PutMapping("/{id}")
    public PassageDto update(@PathVariable UUID id, @Valid @RequestBody PassageWriteRequest req) {
        return service.update(id, req);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable UUID id) {
        service.delete(id);
    }
}
