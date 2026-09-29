package com.sejourfr.app.dto;

import com.sejourfr.app.enums.NiveauCecrl;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * Payload pour soumettre une note humaine de reference (admin / prof partenaire).
 * Cf. POST /api/admin/calibration/submissions/{id}/human-note (spec section 8).
 */
public record HumanCalibrationNoteDto(
        UUID submissionId,
        BigDecimal noteHumaineSurVingt,
        NiveauCecrl niveauCecrlHumain,
        String commentaires
) {
}
