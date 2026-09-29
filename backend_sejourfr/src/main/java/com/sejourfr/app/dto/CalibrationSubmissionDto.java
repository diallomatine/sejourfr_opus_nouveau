package com.sejourfr.app.dto;

/**
 * Ligne de la console admin de calibration : la soumission telle que les fronts
 * la connaissent, augmentee des versions d'evaluation.
 *
 * <p>Enveloppe plutot qu'ajout de champs sur {@link ProductionSubmissionDto} /
 * {@link EvaluationResultDto} : ces deux DTO sont partages avec le web et le
 * mobile, alors que la version de grille n'interesse que l'ecran qui juge la
 * notation. Une note produite avec la grille v3 et une note produite avec la
 * v4.2 ne sont pas comparables — sans cette information, l'ecart IA/humain
 * affiche cote console peut melanger deux baremes.
 *
 * @param submission     la soumission et son evaluation, format inchange
 * @param rubricsVersion grille de notation appliquee
 *                       ({@code prompts/production-rubrics-<v>.json}), ou
 *                       {@code null} pour une evaluation anterieure a la
 *                       colonne {@code ai_evaluations.rubrics_version} (V022)
 * @param promptVersion  version du tool-schema de sortie, ou {@code null} sans
 *                       evaluation IA rattachee
 */
public record CalibrationSubmissionDto(
        ProductionSubmissionDto submission,
        String rubricsVersion,
        String promptVersion
) {
}
