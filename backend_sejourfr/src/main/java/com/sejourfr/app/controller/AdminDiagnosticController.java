package com.sejourfr.app.controller;

import com.sejourfr.app.dto.DiagnosticInstructionAudioDto;
import com.sejourfr.app.service.diagnostic.DiagnosticInstructionAudioService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** Maintenance seed-only du diagnostic ; /api/admin/** est réservé à ROLE_ADMIN. */
@RestController
@RequestMapping("/api/admin/diagnostics")
@RequiredArgsConstructor
public class AdminDiagnosticController {

    private final DiagnosticInstructionAudioService audioService;

    @GetMapping("/{code}/versions/{version}/instruction-audio")
    public DiagnosticInstructionAudioDto audioStatus(
            @PathVariable String code, @PathVariable int version) {
        return audioService.status(code, version);
    }

    /**
     * Idempotent par défaut. {@code force=true} refait la synthèse même si
     * l'objet R2 existe (consigne corrigée) : opt-in strict, jamais par défaut,
     * car c'est un appel payant.
     */
    @PostMapping("/{code}/versions/{version}/instruction-audio")
    public DiagnosticInstructionAudioDto generateAudio(
            @PathVariable String code,
            @PathVariable int version,
            @RequestParam(defaultValue = "false") boolean force) {
        return audioService.generate(code, version, force);
    }
}
