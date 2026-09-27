package com.sejourfr.app.dto;

import com.sejourfr.app.enums.NiveauCecrl;

/**
 * <b>Ce que l'examen qui a clos une etape a donne</b> — servi par la seule
 * consultation d'un cycle clos (« Mes cycles », 2026-09-27).
 *
 * <p>🛑 <b>Relu chez l'autorite de chaque examen, jamais recompose ici</b> :
 * le palier d'un examen de comprehension vient de
 * {@code TcfLevelEstimatorService.niveauxQcm} (le meme que les ecrans de
 * progression), celui d'une epreuve d'expression de
 * {@code EpreuvesProductionQualifiantesResolver}, le score d'un examen de theme
 * civique de l'attempt lui-meme ({@code score} / {@code max_score}).
 *
 * <p>🛑 <b>{@code null} = inconnu, jamais mauvais</b> : une etape close par un
 * diagnostic, par l'examen complet d'un autre axe ou par une evaluation dont
 * rien n'est exploitable n'a <b>aucun</b> resultat servi — l'ecran dit
 * « Passé », sans niveau.
 *
 * @param niveau   le palier de l'examen — <b>TCF</b>. {@code null} en civique.
 * @param score    le score obtenu — <b>CIVIQUE</b> (examen de theme). {@code null} en TCF.
 * @param maxScore le score maximal de ce meme examen. Meme regle.
 */
public record JourneyExamResultDto(NiveauCecrl niveau, Integer score, Integer maxScore) {}
