package com.sejourfr.app.media;

import com.sejourfr.app.media.enums.MediaType;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.net.URI;
import java.util.UUID;

@RestController
@RequestMapping("/api/admin/media")
public class AdminMediaController {

    private final MediaService service;

    public AdminMediaController(MediaService service) {
        this.service = service;
    }

    @PostMapping(value = "/upload", consumes = org.springframework.http.MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<MediaDto> upload(
            @RequestPart("file") MultipartFile file,
            @RequestParam("type") MediaType type,
            @RequestParam(value = "durationSec", required = false) Integer durationSec,
            @RequestParam(value = "altText", required = false) String altText
    ) {
        MediaDto created = service.upload(file, type, durationSec, altText);
        return ResponseEntity
                .created(URI.create("/api/admin/media/" + created.id()))
                .body(created);
    }

    @PostMapping("/from-url")
    public ResponseEntity<MediaDto> createFromUrl(@Valid @RequestBody MediaCreateFromUrlRequest req) {
        MediaDto created = service.createFromUrl(req);
        return ResponseEntity
                .created(URI.create("/api/admin/media/" + created.id()))
                .body(created);
    }

    @GetMapping("/{id}")
    public MediaDto getById(@PathVariable UUID id) {
        return service.getById(id);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable UUID id) {
        service.delete(id);
    }
}
