package com.sejourfr.app.service.questionimport;

import com.sejourfr.app.dto.CoImageImportError;

import java.util.List;

/** Verdict complet d'un lot : erreurs de lot + une analyse par question. */
public record ResultatValidation(
        List<CoImageImportError> erreursLot,
        List<QuestionAnalysee> questions
) {
    /** Importable : aucune erreur de lot, au moins une question, toutes valides. */
    public boolean ok() {
        return erreursLot.isEmpty() && !questions.isEmpty()
                && questions.stream().allMatch(QuestionAnalysee::ok);
    }
}
