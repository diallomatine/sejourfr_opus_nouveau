package com.sejourfr.app.controller;

import com.sejourfr.app.dto.CalibrationStatsDto;
import com.sejourfr.app.dto.HumanCalibrationNoteDto;
import com.sejourfr.app.dto.ProductionSubmissionDto;
import com.sejourfr.app.entity.HumanCalibrationNote;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.mapper.ProductionSubmissionMapper;
import com.sejourfr.app.security.CurrentUser;
import com.sejourfr.app.service.AdminCalibrationService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.net.URI;
import java.util.List;
import java.util.UUID;

/**
 * Console admin de calibration IA : annoter des submissions, suivre l'ecart
 * entre IA et notes humaines. Securise par {@code /api/admin/**} -&gt; ROLE_ADMIN
 * (cf. SecurityConfig).
 */
@RestController
@RequestMapping("/api/admin/calibration")
public class AdminCalibrationController {

    private final AdminCalibrationService calibrationService;
    private final ProductionSubmissionMapper mapper;
    private final CurrentUser currentUser;

    public AdminCalibrationController(
            AdminCalibrationService calibrationService,
            ProductionSubmissionMapper mapper,
            CurrentUser currentUser) {
        this.calibrationService = calibrationService;
        this.mapper = mapper;
        this.currentUser = currentUser;
    }

    /**
     * Liste les submissions a annoter (statut EVALUATED, sans note humaine).
     * Filtre {@code hasHumanNote=true} pour voir les deja-annotees.
     */
    @GetMapping("/submissions")
    public List<ProductionSubmissionDto> submissions(
            @RequestParam(required = false, defaultValue = "evaluated") String status,
            @RequestParam(required = false) Boolean hasHumanNote,
            @RequestParam(defaultValue = "50") int limit) {
        if (!"evaluated".equalsIgnoreCase(status)) {
            throw new BusinessException("status=evaluated est le seul filtre supporte pour l'instant.");
        }
        List<ProductionSubmission> list = Boolean.TRUE.equals(hasHumanNote)
            ? calibrationService.listEvaluated(limit)
            : calibrationService.listAToAnnoter(limit);
        return list.stream().map(mapper::toDtoWithSignedAudio).toList();
    }

    @PostMapping("/submissions/{id}/human-note")
    public ResponseEntity<HumanCalibrationNoteDto> annoter(
            @PathVariable UUID id,
            @Valid @RequestBody HumanCalibrationNoteDto body) {
        UUID adminId = currentUser.getId();
        HumanCalibrationNote saved = calibrationService.enregistrer(id, adminId, body);
        HumanCalibrationNoteDto echo = new HumanCalibrationNoteDto(
            saved.getSubmission().getId(),
            saved.getNoteHumaineSur20(),
            saved.getNiveauCecrlHumain(),
            saved.getCommentaires()
        );
        return ResponseEntity.created(URI.create("/api/admin/calibration/submissions/" + id + "/human-note"))
            .body(echo);
    }

    @GetMapping("/stats")
    public CalibrationStatsDto stats() {
        return calibrationService.stats();
    }
}
