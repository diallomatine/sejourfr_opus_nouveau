package com.sejourfr.app.manager;

import com.sejourfr.app.entity.HumanCalibrationNote;
import com.sejourfr.app.repository.HumanCalibrationNoteRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Collection;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

/**
 * Couche d'acces aux donnees pour {@link HumanCalibrationNote} (notes de
 * calibration humaine sur les productions EO/EE).
 *
 * <p>Les notes sont <b>historisees</b> : reannoter une submission ajoute une
 * ligne, elle n'en remplace pas une. C'est volontaire (on garde la trace des
 * corrections successives et des doubles annotations) — a charge des lectures
 * de ne retenir que la plus recente par submission.
 */
@Component
@RequiredArgsConstructor
public class HumanCalibrationNoteManager {

    private final HumanCalibrationNoteRepository repository;

    /** Derniere note humaine d'une submission (vide si jamais annotee). */
    public Optional<HumanCalibrationNote> findLatestBySubmission(UUID submissionId) {
        return repository.findFirstBySubmissionIdOrderByCreatedAtDescIdDesc(submissionId);
    }

    /**
     * Sous-ensemble de {@code submissionIds} deja annote, en UNE requete.
     * Retourne un ensemble vide sans toucher la base si l'entree est vide.
     */
    public Set<UUID> findAnnotatedSubmissionIds(Collection<UUID> submissionIds) {
        if (submissionIds == null || submissionIds.isEmpty()) return Set.of();
        return new LinkedHashSet<>(repository.findAnnotatedSubmissionIds(submissionIds));
    }

    /**
     * Toutes les notes, la plus recente d'abord — utilise par le dashboard de
     * calibration, qui n'en garde qu'une par submission (volumes maitrises).
     */
    public List<HumanCalibrationNote> findAllOrderedByCreatedAtDesc() {
        return repository.findAllByOrderByCreatedAtDescIdDesc();
    }

    public HumanCalibrationNote save(HumanCalibrationNote note) {
        return repository.save(note);
    }
}
