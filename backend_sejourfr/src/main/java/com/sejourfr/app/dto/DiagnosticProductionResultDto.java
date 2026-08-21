package com.sejourfr.app.dto;

import com.sejourfr.app.enums.DiagnosticCommunicationStatus;
import com.sejourfr.app.enums.ProductionEvaluabilite;
import com.sejourfr.app.enums.DiagnosticTaskCompletion;
import com.sejourfr.app.enums.NiveauCecrl;

import java.util.List;

/**
 * Le resultat d'UNE des deux productions du diagnostic.
 *
 * <p>⚠️ <b>Trois etats, pas deux.</b> Le bloc entier {@code null} (cote
 * {@code DiagnosticResultDto.written} / {@code .oral}) signifie « pas encore
 * rendue ». Un bloc present avec {@code evaluabilite = NON_EVALUABLE} signifie
 * « rendue, mais il n'y avait rien a observer » : les trois verdicts valent
 * alors {@code null}, {@code skills} ne porte que des observations non
 * observees, et {@code strengths} / {@code weaknesses} sont vides. Les fronts
 * doivent distinguer ces deux cas — « pas encore evaluee » et « n'a pas pu etre
 * evaluee » ne se disent pas pareil — mais la phrase leur appartient : le
 * serveur n'expose ici que des faits.
 *
 * @param evaluabilite        jamais {@code null}. {@code EVALUABLE} sur toutes
 *                            les analyses anterieures a V040.
 * @param levelEstimate       {@code null} si {@code NON_EVALUABLE} — null =
 *                            inconnu, jamais mauvais.
 * @param taskCompletion      {@code null} si {@code NON_EVALUABLE}.
 * @param communicationStatus {@code null} si {@code NON_EVALUABLE}.
 */
public record DiagnosticProductionResultDto(
        ProductionEvaluabilite evaluabilite,
        NiveauCecrl levelEstimate,
        DiagnosticTaskCompletion taskCompletion,
        DiagnosticCommunicationStatus communicationStatus,
        String summary,
        List<String> strengths,
        List<String> weaknesses,
        List<DiagnosticSkillObservationDto> skills
) {}
