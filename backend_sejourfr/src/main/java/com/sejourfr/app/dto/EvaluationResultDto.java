package com.sejourfr.app.dto;

import com.sejourfr.app.enums.NiveauCecrl;

import java.math.BigDecimal;
import java.util.Map;

/**
 * Vue front d'une {@link com.sejourfr.app.entity.AiEvaluation}. Le bloc
 * {@code feedback} est passe en l'etat depuis le JSONB persiste (structure
 * documentee dans la spec section 3.2).
 *
 * <p>{@code justificationNiveau} est extrait de {@code feedback.justification_niveau}
 * et expose explicitement pour faciliter l'affichage cote mobile/web. Nullable
 * pour rester retro-compatible avec les evaluations en prompt-version v1.0
 * qui n'avaient pas ce champ.
 */
public record EvaluationResultDto(
        BigDecimal noteSurVingt,
        NiveauCecrl niveauCecrl,
        String justificationNiveau,
        Map<String, Object> feedback
) {
}
