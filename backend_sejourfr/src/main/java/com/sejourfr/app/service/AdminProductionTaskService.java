package com.sejourfr.app.service;

import com.sejourfr.app.dto.AdminProductionTaskDto;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.ProductionTaskManager;
import com.sejourfr.app.mapper.AdminProductionTaskMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Comparator;
import java.util.List;
import java.util.UUID;

/**
 * Console admin : l'<b>intitule editorial</b> des sujets de production.
 *
 * <p>Perimetre volontairement etroit — lire le catalogue, poser ou retirer un
 * titre. Le reste d'un sujet (consigne, bornes de mots/duree, fiche de scenario
 * T2, activation) reste pilote par les migrations de contenu : ce sont des
 * donnees qu'une rubrique de notation et des tests de seed verrouillent, pas du
 * texte d'affichage.
 *
 * <p>Le contenu initial est publie par V754 (genere depuis
 * {@code tools/production-titres/}), mais une fois les migrations appliquees
 * c'est la <b>base</b> qui fait foi : meme convention que le module
 * Competences.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class AdminProductionTaskService {

    /** Aligne sur {@code production_tasks.titre varchar(80)}. */
    private static final int TITRE_MAX = 80;

    private final ProductionTaskManager taskManager;
    private final AdminProductionTaskMapper mapper;

    /**
     * Catalogue complet d'une epreuve, <b>desactivees comprises</b>, dans
     * l'ordre ou les candidats voient les sujets (tache puis niveau) — c'est ce
     * qui rend le rang affiche en console comparable au « Sujet N » du front.
     */
    public List<AdminProductionTaskDto> list(EpreuveType epreuve, Short tacheNumero) {
        validateEpreuve(epreuve);
        validateTacheNumero(tacheNumero);
        return taskManager.findAllStandardByEpreuve(epreuve).stream()
                .filter(t -> tacheNumero == null || tacheNumero.equals(t.getTacheNumero()))
                .sorted(Comparator
                        .comparing(ProductionTask::getTacheNumero,
                                Comparator.nullsLast(Comparator.naturalOrder()))
                        .thenComparing(ProductionTask::getNiveauCible,
                                Comparator.nullsLast(Comparator.naturalOrder())))
                .map(mapper::toDto)
                .toList();
    }

    /**
     * Pose le titre, ou le retire quand il arrive vide/blanc : « pas de titre »
     * se dit NULL en base (contrainte {@code chk_prod_task_titre}), jamais par
     * une chaine vide qui laisserait un trou a l'ecran.
     */
    @Transactional
    public AdminProductionTaskDto updateTitre(UUID id, String titre) {
        ProductionTask task = taskManager.findById(id)
                .orElseThrow(() -> new NotFoundException("Sujet de production introuvable : " + id));
        if (task.isDiagnostic()) {
            throw new NotFoundException("Sujet de production introuvable : " + id);
        }

        String normalise = normalizeTitre(titre);
        if (normalise != null && normalise.length() > TITRE_MAX) {
            throw new BusinessException("Le titre ne doit pas depasser " + TITRE_MAX + " caracteres.");
        }

        task.setTitre(normalise);
        ProductionTask saved = taskManager.save(task);
        log.info("Titre du sujet {} ({} T{}) : {}",
                id, saved.getEpreuve(), saved.getTacheNumero(),
                normalise == null ? "retire" : normalise);
        return mapper.toDto(saved);
    }

    private static String normalizeTitre(String titre) {
        if (titre == null) return null;
        String trimmed = titre.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private void validateEpreuve(EpreuveType epreuve) {
        if (epreuve != EpreuveType.TCF_EO && epreuve != EpreuveType.TCF_EE) {
            throw new BusinessException("epreuve doit etre TCF_EO ou TCF_EE.");
        }
    }

    private void validateTacheNumero(Short tacheNumero) {
        if (tacheNumero != null && (tacheNumero < 1 || tacheNumero > 3)) {
            throw new BusinessException("tacheNumero doit etre entre 1 et 3.");
        }
    }
}
