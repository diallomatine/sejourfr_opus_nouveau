package com.sejourfr.app.dto;

import com.sejourfr.app.enums.NiveauCecrl;

import java.math.BigDecimal;
import java.util.Map;

/**
 * Vue front d'une {@link com.sejourfr.app.entity.AiEvaluation}. Le bloc
 * {@code feedback} est passe en l'etat depuis le JSONB persiste (structure
 * documentee dans la spec section 3.2).
 */
public record EvaluationResultDto(
        BigDecimal noteSurVingt,
        NiveauCecrl niveauCecrl,
        Map<String, Object> feedback
) {
}
