package com.sejourfr.app.controller;

import com.sejourfr.app.dto.CoImageImportReport;
import com.sejourfr.app.service.questionimport.CoImageImportService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

/**
 * Import par lot des questions TCF CO image (manifeste JSON + images) vers les
 * brouillons audio. Multipart : partie {@code manifest} (JSON) + N parties
 * {@code images} (un fichier chacune, nom = celui cite par le manifeste).
 */
@RestController
@RequestMapping("/api/admin/question-imports/co-image")
@RequiredArgsConstructor
public class AdminQuestionImportController {

    private final CoImageImportService importService;

    /** Rapport du lot, aucune ecriture. Toujours 200 : le verdict est dans le corps. */
    @PostMapping(value = "/analyze", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public CoImageImportReport analyze(
            @RequestPart(value = "manifest", required = false) String manifest,
            @RequestPart(value = "images", required = false) List<MultipartFile> images) {
        return importService.analyser(manifest, images);
    }

    /** 201 + brouillons crees, ou 422 + rapport (rien d'ecrit). */
    @PostMapping(value = "/import", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<CoImageImportReport> importer(
            @RequestPart(value = "manifest", required = false) String manifest,
            @RequestPart(value = "images", required = false) List<MultipartFile> images) {
        CoImageImportReport rapport = importService.importer(manifest, images);
        return ResponseEntity
                .status(rapport.imported() ? HttpStatus.CREATED : HttpStatus.UNPROCESSABLE_ENTITY)
                .body(rapport);
    }
}
