package com.sejourfr.app.manager;

import com.sejourfr.app.entity.HumanCalibrationNote;
import com.sejourfr.app.repository.HumanCalibrationNoteRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.UUID;

/**
 * Couche d'acces aux donnees pour {@link HumanCalibrationNote} (notes de
 * calibration humaine sur les productions EO/EE).
 */
@Component
@RequiredArgsConstructor
public class HumanCalibrationNoteManager {

    private final HumanCalibrationNoteRepository repository;

    public List<HumanCalibrationNote> findBySubmissionOrderedByCreatedAtDesc(UUID submissionId) {
        return repository.findBySubmissionIdOrderByCreatedAtDesc(submissionId);
    }

    /** Toutes les notes — utilise par le dashboard de calibration (volumes maitrises). */
    public List<HumanCalibrationNote> findAll() {
        return repository.findAll();
    }

    public HumanCalibrationNote save(HumanCalibrationNote note) {
        return repository.save(note);
    }
}
