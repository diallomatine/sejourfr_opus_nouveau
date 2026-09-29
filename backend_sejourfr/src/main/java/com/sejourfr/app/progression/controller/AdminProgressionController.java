package com.sejourfr.app.progression.controller;

import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.progression.dto.ProgressionShadowReportDto;
import com.sejourfr.app.progression.dto.ProgressionStateDto;
import com.sejourfr.app.progression.entity.ProgressionPredictionRecord;
import com.sejourfr.app.progression.entity.ProgressionStateRecord;
import com.sejourfr.app.progression.service.ProgressionIngestionService;
import com.sejourfr.app.progression.service.ProgressionReportService;
import com.sejourfr.app.progression.service.ProgressionShadowService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * <b>Le moteur de progression, vu de la console</b> (V4.2 §46, §47).
 *
 * <p>C'est le seul endroit du produit où {@code masteryScore} et
 * {@code confidence} sortent du moteur (§25 bis.2). Un front candidat n'y a
 * jamais accès : lui servir ces valeurs lui permettrait de reconstituer un
 * seuil, donc de reclasser un nombre en état pédagogique — exactement ce que le
 * contrat de rendu interdit.
 *
 * <p>Il existe pour une raison précise : <b>rendre la bascule en {@code ACTIVE}
 * décidable</b>. Tant que le rapport shadow ne montre pas une précision
 * suffisante sur une base suffisante, le moteur reste en observation, et les
 * seuils de {@code progression-config-v1.json} restent ce qu'ils sont — des
 * hypothèses produit.
 */
@RestController
@RequestMapping("/api/admin/progression")
@PreAuthorize("hasRole('ADMIN')")
@RequiredArgsConstructor
public class AdminProgressionController {

    private final ProgressionReportService reportService;
    private final ProgressionShadowService shadowService;
    private final ProgressionIngestionService ingestionService;

    /** §47.4 — les chiffres du go/no-go, et la phrase qui les tempère. */
    @GetMapping("/shadow")
    public ProgressionShadowReportDto shadow() {
        return reportService.rapportShadow();
    }

    /**
     * §47.3 — rattache les prédictions en attente au premier examen qualifiant
     * survenu dans la fenêtre.
     *
     * <p>Déclenché à la main plutôt que par un job planifié : le rattachement
     * est idempotent, il n'y a aucune urgence à ce qu'il tourne toutes les
     * heures, et un job de plus est une chose de plus qui peut échouer en
     * silence. La console appelle avant de lire.
     */
    @PostMapping("/shadow/rattacher")
    public Map<String, Integer> rattacher() {
        return Map.of("rattachees", shadowService.rattacherResultats(Instant.now()));
    }

    /**
     * Les états internes d'un candidat — {@code masteryScore},
     * {@code confidence}, accumulateurs epoch compris.
     */
    @GetMapping("/utilisateurs/{userId}/etats")
    public List<ProgressionStateRecord> etats(@PathVariable UUID userId) {
        return reportService.etatsInternes(userId);
    }

    /**
     * Les mêmes états, <b>dans la forme servable à un front</b> : de quoi
     * afficher, jamais de quoi recalculer. Sert aussi à vérifier de visu que le
     * contrat de §25 bis.2 est bien ce qu'on croit.
     */
    @GetMapping("/utilisateurs/{userId}/etats-servis")
    public List<ProgressionStateDto> etatsServis(@PathVariable UUID userId,
                                                 @RequestParam TargetLevel objectif) {
        return reportService.etatsServis(userId, objectif);
    }

    /** Le journal de prédictions d'un candidat, figé à chaque {@code predictedAt}. */
    @GetMapping("/utilisateurs/{userId}/predictions")
    public List<ProgressionPredictionRecord> predictions(@PathVariable UUID userId) {
        return reportService.predictions(userId);
    }

    /**
     * §29 — rejoue tout l'historique d'un candidat sur la version courante du
     * moteur.
     *
     * <p>Réservé aux changements d'{@code engineVersion}, aux corrections de
     * données et aux audits. Il repart d'une projection vide : c'est la seule
     * façon de garantir qu'aucun reste d'un calcul précédent ne survit.
     */
    @PostMapping("/utilisateurs/{userId}/replay")
    public Map<String, Integer> replay(@PathVariable UUID userId) {
        return Map.of("clesReconstruites", ingestionService.rejouer(userId, Instant.now()));
    }
}
