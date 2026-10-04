package com.sejourfr.app.dto;

import java.util.List;

/**
 * Reponse des deux endpoints d'import CO image : le rapport d'analyse
 * ({@code analyze}, toujours 200), le resultat d'import ({@code import} : 201
 * avec {@code imported = true}, ou 422 avec le meme rapport et rien d'ecrit).
 *
 * @param ok            aucune erreur de lot ni de question
 * @param imported      les brouillons ont ete crees (import seulement)
 * @param charteVersion version de la charte des images opposee
 * @param errors        erreurs de LOT (manifeste, fichiers en trop ou en double)
 */
public record CoImageImportReport(
        boolean ok,
        boolean imported,
        String format,
        String charteVersion,
        int maxQuestions,
        int questionCount,
        List<CoImageImportError> errors,
        List<CoImageImportQuestionReport> questions
) {}
