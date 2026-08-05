package com.sejourfr.app.controller;

import com.sejourfr.app.dto.CalibrationStatsDto;
import com.sejourfr.app.dto.CalibrationSubmissionDto;
import com.sejourfr.app.dto.HumanCalibrationNoteDto;
import com.sejourfr.app.dto.NiveauCalibrationStatsDto;
import com.sejourfr.app.security.CurrentUser;
import com.sejourfr.app.service.AdminCalibrationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
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
@RequiredArgsConstructor
public class AdminCalibrationController {

    private final AdminCalibrationService adminCalibrationService;
    private final CurrentUser currentUser;

    /**
     * Liste les submissions a annoter (statut EVALUATED, sans note humaine).
     * Filtre {@code hasHumanNote=true} pour voir UNIQUEMENT les deja-annotees.
     * Chaque ligne enveloppe la soumission et les versions de grille / de
     * tool-schema de sa derniere evaluation IA.
     */
    @GetMapping("/submissions")
    public List<CalibrationSubmissionDto> submissions(
            @RequestParam(required = false, defaultValue = "evaluated") String status,
            @RequestParam(required = false) Boolean hasHumanNote,
            @RequestParam(defaultValue = "50") int limit) {
        return adminCalibrationService.listSubmissions(status, hasHumanNote, limit);
    }

    /**
     * Derniere note humaine d'une submission (relecture / pre-remplissage du
     * formulaire d'annotation). 404 si la submission n'a jamais ete annotee.
     */
    @GetMapping("/submissions/{id}/human-note")
    public HumanCalibrationNoteDto humanNote(@PathVariable UUID id) {
        return adminCalibrationService.latestHumanNote(id);
    }

    @PostMapping("/submissions/{id}/human-note")
    public ResponseEntity<HumanCalibrationNoteDto> annoter(
            @PathVariable UUID id,
            @Valid @RequestBody HumanCalibrationNoteDto body) {
        HumanCalibrationNoteDto saved = adminCalibrationService.annoter(id, currentUser.getId(), body);
        return ResponseEntity
                .created(URI.create("/api/admin/calibration/submissions/" + id + "/human-note"))
                .body(saved);
    }

    @GetMapping("/stats")
    public CalibrationStatsDto stats() {
        return adminCalibrationService.stats();
    }

    /** Ecart niveau CECRL : LLM brut vs calcule serveur (calibration du niveau). */
    @GetMapping("/stats/niveau")
    public NiveauCalibrationStatsDto niveauStats() {
        return adminCalibrationService.niveauStats();
    }
}
