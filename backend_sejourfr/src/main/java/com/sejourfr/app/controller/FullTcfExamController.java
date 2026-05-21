package com.sejourfr.app.controller;

import com.sejourfr.app.dto.FullTcfExamResponse;
import com.sejourfr.app.dto.FullTcfExamSummaryResponse;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.security.CurrentUser;
import com.sejourfr.app.service.FullTcfExamService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

/**
 * REST endpoints pour les examens blancs TCF complets (les 4 épreuves
 * enchaînées CO + CE + EE + EO, 90 min). Cf. {@link FullTcfExamService}
 * pour la mécanique.
 */
@RestController
@RequiredArgsConstructor
public class FullTcfExamController {

    private final FullTcfExamService fullTcfExamService;
    private final CurrentUser currentUser;

    /**
     * Démarre un examen blanc complet : crée le parent {@code TCF_COMPLET}
     * et les 4 sous-attempts CO/CE/EE/EO en une transaction. Réservé aux
     * abonnés TCF.
     */
    @PostMapping("/api/full-tcf-exams")
    public FullTcfExamResponse start() {
        return fullTcfExamService.start(currentUser.getId());
    }

    /** Détail courant : 4 sous-attempts + agrégation CECRL plancher lazy. */
    @GetMapping("/api/full-tcf-exams/{id}")
    public FullTcfExamResponse get(@PathVariable UUID id) {
        return fullTcfExamService.get(currentUser.getId(), id);
    }

    /**
     * Marque l'examen comme terminé (pose {@code finishedAt} sur le parent
     * et persiste le niveau CECRL plancher dès que toutes les évaluations IA
     * EE/EO sont prêtes).
     */
    @PostMapping("/api/full-tcf-exams/{id}/finish")
    public FullTcfExamResponse finish(@PathVariable UUID id) {
        return fullTcfExamService.finish(currentUser.getId(), id);
    }

    /** Historique des examens blancs complets de l'utilisateur, tri descendant. */
    @GetMapping("/api/me/full-tcf-exams")
    public List<FullTcfExamSummaryResponse> mine(@RequestParam(defaultValue = "20") int limit) {
        return fullTcfExamService.listMine(currentUser.getId(), limit);
    }

    /**
     * Marque explicitement un sous-attempt EE ou EO comme terminé. Appelé
     * par le mobile après la dernière tâche d'une épreuve productive, pour
     * que le hub de progression débloque l'étape suivante sans attendre que
     * l'évaluation IA fire-and-forget ait fini de tourner côté serveur.
     */
    @PostMapping("/api/full-tcf-exams/{id}/sub-done")
    public FullTcfExamResponse markSubDone(
            @PathVariable UUID id,
            @RequestParam EpreuveType epreuve) {
        return fullTcfExamService.markSubAttemptDone(
                currentUser.getId(), id, epreuve);
    }
}
