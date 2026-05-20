package com.sejourfr.app.controller;

import com.sejourfr.app.dto.MediaCreateFromUrlRequest;
import com.sejourfr.app.dto.MediaDto;
import com.sejourfr.app.enums.MediaType;
import com.sejourfr.app.service.MediaService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.net.URI;
import java.util.UUID;

@RestController
@RequestMapping("/api/admin/media")
@RequiredArgsConstructor
public class AdminMediaController {

    private final MediaService mediaService;

    @PostMapping(value = "/upload", consumes = org.springframework.http.MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<MediaDto> upload(
            @RequestPart("file") MultipartFile file,
            @RequestParam("type") MediaType type,
            @RequestParam(value = "durationSec", required = false) Integer durationSec,
            @RequestParam(value = "altText", required = false) String altText) {
        MediaDto created = mediaService.upload(file, type, durationSec, altText);
        return ResponseEntity
                .created(URI.create("/api/admin/media/" + created.id()))
                .body(created);
    }

    @PostMapping("/from-url")
    public ResponseEntity<MediaDto> createFromUrl(@Valid @RequestBody MediaCreateFromUrlRequest req) {
        MediaDto created = mediaService.createFromUrl(req);
        return ResponseEntity
                .created(URI.create("/api/admin/media/" + created.id()))
                .body(created);
    }

    @GetMapping("/{id}")
    public MediaDto getById(@PathVariable UUID id) {
        return mediaService.getById(id);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable UUID id) {
        mediaService.delete(id);
    }
}
