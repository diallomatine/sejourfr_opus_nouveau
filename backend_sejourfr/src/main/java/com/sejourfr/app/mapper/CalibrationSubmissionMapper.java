package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.CalibrationSubmissionDto;
import com.sejourfr.app.dto.ProductionSubmissionDto;
import com.sejourfr.app.entity.AiEvaluation;
import org.springframework.stereotype.Component;

/**
 * Assemble la ligne de la console de calibration. Le mapper recoit la
 * soumission deja mappee et l'evaluation IA de reference : c'est le service qui
 * fait les lookups.
 */
@Component
public class CalibrationSubmissionMapper {

    /**
     * @param evaluation derniere evaluation IA, ou {@code null} si la soumission
     *                   n'en a pas — les deux versions sortent alors a
     *                   {@code null}, cas normal cote console.
     */
    public CalibrationSubmissionDto toDto(ProductionSubmissionDto submission, AiEvaluation evaluation) {
        return new CalibrationSubmissionDto(
                submission,
                evaluation == null ? null : evaluation.getRubricsVersion(),
                evaluation == null ? null : evaluation.getPromptVersion());
    }
}
