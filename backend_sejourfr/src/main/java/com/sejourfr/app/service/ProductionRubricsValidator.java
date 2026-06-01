package com.sejourfr.app.service;

import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.manager.ProductionTaskManager;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Garde-fou de demarrage : le fichier de rubriques etant l'UNIQUE source du
 * "comment noter", on refuse de demarrer si la couverture ou la coherence n'est
 * pas garantie. Verifie, sur {@link ApplicationReadyEvent} :
 * <ul>
 *   <li>chaque tache {@code is_active=TRUE} (epreuve EO/EE) a une rubrique ;</li>
 *   <li>par rubrique : Σ poids == 1.0 (±0.001) ;</li>
 *   <li>chaque {@code code} de critere ∈ set canonique.</li>
 * </ul>
 * Tout manquement → log ERROR + {@link IllegalStateException} (le contexte Spring
 * ne demarre pas).
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class ProductionRubricsValidator {

    /** Codes critere canoniques (v2) — EO sans prononciation (transcription Whisper). */
    static final Set<String> CANONICAL_CODES = Set.of(
        "pertinence", "coherence", "lexique", "morphosyntaxe");
    private static final double POIDS_TOLERANCE = 0.001;

    private final ProductionRubricsProvider rubrics;
    private final ProductionTaskManager taskManager;

    @EventListener(ApplicationReadyEvent.class)
    public void validate() {
        List<String> errors = new ArrayList<>();

        // 1. Coherence interne de chaque rubrique (poids = 1, codes canoniques).
        for (Map.Entry<String, Map<String, Object>> e : rubrics.all().entrySet()) {
            validateRubric(e.getKey(), e.getValue(), errors);
        }

        // 2. Couverture : chaque tache active a une rubrique.
        for (ProductionTask task : taskManager.findAllActive()) {
            EpreuveType epreuve = task.getEpreuve();
            if (epreuve != EpreuveType.TCF_EO && epreuve != EpreuveType.TCF_EE) {
                continue; // seules les productions EO/EE sont notees par rubrique
            }
            Integer tache = task.getTacheNumero() == null ? null : task.getTacheNumero().intValue();
            if (tache == null || rubrics.find(epreuve, tache).isEmpty()) {
                errors.add("Tache active sans rubrique : id=" + task.getId()
                    + " cle=" + ProductionRubricsProvider.key(epreuve, tache == null ? -1 : tache));
            }
        }

        if (!errors.isEmpty()) {
            errors.forEach(msg -> log.error("[rubriques] {}", msg));
            throw new IllegalStateException("Rubriques de notation invalides ("
                + errors.size() + " erreur(s)) — cf. logs ERROR [rubriques]. "
                + "Corriger production-rubrics-<version>.json ou desactiver la tache.");
        }
        log.info("Rubriques de notation validees : {} rubriques, couverture des taches actives OK.",
            rubrics.all().size());
    }

    private static void validateRubric(String cle, Map<String, Object> rubric, List<String> errors) {
        if (!(rubric.get("criteres") instanceof List<?> criteres) || criteres.isEmpty()) {
            errors.add(cle + " : aucun critere.");
            return;
        }
        double sommePoids = 0.0;
        for (Object c : criteres) {
            if (!(c instanceof Map<?, ?> m)) {
                errors.add(cle + " : critere malforme.");
                continue;
            }
            Object code = m.get("code");
            if (code == null || !CANONICAL_CODES.contains(code.toString())) {
                errors.add(cle + " : code non canonique '" + code + "' (attendus : " + CANONICAL_CODES + ").");
            }
            Object poids = m.get("poids");
            if (!(poids instanceof Number n)) {
                errors.add(cle + " : poids absent/non numerique pour '" + code + "'.");
            } else {
                sommePoids += n.doubleValue();
            }
        }
        if (Math.abs(sommePoids - 1.0) > POIDS_TOLERANCE) {
            errors.add(cle + " : Σ poids = " + sommePoids + " (attendu 1.0 ±" + POIDS_TOLERANCE + ").");
        }
    }
}
