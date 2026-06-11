package com.sejourfr.app.dto;

import java.math.BigDecimal;
import java.util.Map;

/**
 * Vue front d'une {@link com.sejourfr.app.entity.AiEvaluation}. Le bloc
 * {@code feedback} est passe depuis le JSONB persiste (structure documentee
 * dans la spec section 3.2), expurge des champs de niveau.
 *
 * <p><b>Pas de niveau CECRL par tache</b> : le niveau (et sa justification)
 * reste calcule et persiste en base pour la calibration admin, mais n'est
 * jamais expose tache par tache — l'IA n'est pas fiable sur une production
 * courte isolee. Le niveau n'apparait qu'au <b>bilan d'epreuve en examen
 * blanc</b> (cf. {@code ProductionBilanResponse} et
 * {@code FullTcfExamResponse.SubAttempt.cecrlLevel}).
 */
public record EvaluationResultDto(
        BigDecimal noteSurVingt,
        Map<String, Object> feedback
) {
}
