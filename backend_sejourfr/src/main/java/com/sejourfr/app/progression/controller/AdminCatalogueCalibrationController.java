package com.sejourfr.app.progression.controller;

import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.progression.calibration.CatalogueCalibrationService;
import com.sejourfr.app.progression.calibration.EmpiricalDifficulty;
import com.sejourfr.app.progression.calibration.EmpiricalDifficultyService;
import com.sejourfr.app.progression.dto.CatalogueCalibrationDto;
import com.sejourfr.app.progression.dto.QuestionBandAssignmentRequest;
import com.sejourfr.app.enums.Module;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.nio.charset.StandardCharsets;
import java.util.List;

/**
 * <b>L'outillage du tagging du catalogue</b> (V4.2 §7, phase 4).
 *
 * <p>Tant qu'aucune question ne porte de {@code difficulty_band}, toutes les
 * séries d'entraînement sont {@code UNCALIBRATED} : elles ne satisfont jamais le
 * {@code qualificationGate}, aucun palier n'avance par l'entraînement, et les
 * métriques shadow ne voient que des examens blancs — échantillon minuscule et
 * biaisé. <b>Taguer précède mesurer, qui précède basculer.</b>
 *
 * <p>🛑 Aucun de ces endpoints ne pose une bande automatiquement. Le taux de
 * réussite observé <i>propose</i> ; c'est un humain qui tranche, et c'est le
 * seul chemin qui laisse une trace de qui a décidé quoi.
 */
@RestController
@RequestMapping("/api/admin/progression/catalogue")
@PreAuthorize("hasRole('ADMIN')")
@RequiredArgsConstructor
public class AdminCatalogueCalibrationController {

    private final CatalogueCalibrationService calibrationService;
    private final EmpiricalDifficultyService empiricalDifficultyService;

    /**
     * <b>L'indicateur d'avancement</b> : par (domaine, palier), les questions
     * taguées et surtout le nombre de séries 6/10/4 constructibles.
     *
     * <p>Le second chiffre est le seul qui compte. `bandeLimitante` dit quoi
     * produire en priorité, plutôt qu'un « il manque des questions » qui
     * n'oriente rien.
     */
    @GetMapping("/inventaire")
    public CatalogueCalibrationDto.Inventaire inventaire() {
        return calibrationService.inventaire();
    }

    /**
     * L'export de travail, en CSV — le tagging se fait hors application.
     *
     * <p>Les questions non taguées d'abord : c'est le travail restant, et une
     * liste qui commence par ce qui est déjà fait se referme sans être lue.
     */
    @GetMapping(value = "/export", produces = "text/csv")
    public ResponseEntity<byte[]> exporter(@RequestParam(required = false) SkillSection section,
                                           @RequestParam(required = false) TargetLevel level) {
        byte[] csv = calibrationService.exporterCsv(section, level)
                .getBytes(StandardCharsets.UTF_8);
        String nom = "calibration-" + (section == null ? "tout" : section)
                + "-" + (level == null ? "tous" : level) + ".csv";
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + nom + "\"")
                .contentType(MediaType.parseMediaType("text/csv; charset=UTF-8"))
                .body(csv);
    }

    /**
     * Le réimport : un lot de bandes à poser, ou à retirer.
     *
     * <p>Chaque ligne est indépendante — un identifiant inconnu est compté et
     * ignoré, il n'annule pas les autres. Un import de 300 lignes dont une porte
     * une coquille doit poser les 299 bonnes.
     *
     * <p>Une {@code band} nulle <b>dé-tague</b>. C'est légitime : retirer un tag
     * qu'on sait faux vaut mieux que le remplacer par un tag douteux.
     */
    @PostMapping("/bandes")
    public CatalogueCalibrationService.Resultat affecter(
            @Valid @RequestBody QuestionBandAssignmentRequest requete) {
        return calibrationService.affecter(requete);
    }

    /**
     * §7 — ce que les candidats montrent réellement, item par item.
     *
     * <p>Sous {@link EmpiricalDifficulty#MIN_REPONSES} réponses, aucune bande
     * n'est proposée : un taux sur trois réponses est du bruit, et le proposer
     * ferait basculer des bandes sur rien.
     */
    @GetMapping("/difficulte-observee")
    public List<EmpiricalDifficulty> difficulteObservee(
            @RequestParam(required = false) QuestionType questionType,
            @RequestParam(required = false) Difficulty difficulty) {
        return empiricalDifficultyService.mesurer(Module.TCF, questionType, difficulty);
    }

    /**
     * Les questions <b>non taguées</b> pour lesquelles les données suffisent à
     * proposer une bande. La liste à traiter en premier : le travail y est déjà
     * pré-mâché.
     */
    @GetMapping("/propositions")
    public List<EmpiricalDifficulty> propositions(
            @RequestParam(required = false) QuestionType questionType,
            @RequestParam(required = false) Difficulty difficulty) {
        return empiricalDifficultyService.propositions(Module.TCF, questionType, difficulty);
    }

    /**
     * Les questions dont la bande déclarée <b>contredit</b> ce que les candidats
     * montrent — taguée HARD, réussie à 90 %.
     *
     * <p>Ce n'est pas un détail de cosmétique : une telle question fausse la
     * comparabilité de toutes les séries qui la contiennent.
     */
    @GetMapping("/desaccords")
    public List<EmpiricalDifficulty> desaccords(
            @RequestParam(required = false) QuestionType questionType,
            @RequestParam(required = false) Difficulty difficulty) {
        return empiricalDifficultyService.desaccords(Module.TCF, questionType, difficulty);
    }
}
