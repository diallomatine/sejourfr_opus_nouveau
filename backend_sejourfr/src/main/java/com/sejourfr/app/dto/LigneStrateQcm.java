package com.sejourfr.app.dto;

import com.sejourfr.app.enums.QuestionType;

import java.util.UUID;

/**
 * Une ligne de l'agrégat « items posés / réussis » d'un lot de tentatives QCM :
 * <b>quelle tentative</b>, <b>quelle épreuve</b>, <b>quelle strate</b>.
 *
 * <p>C'est la forme brute rendue par {@code AttemptQuestionManager
 * .stratesParAttempt}, elle-même alimentée par l'unique requête groupée du
 * niveau QCM. Le repliement {@code CO_IMAGE → CO} et le calcul du palier sont
 * des règles métier : ils vivent chez {@code TcfLevelEstimatorService}, pas ici.
 */
public record LigneStrateQcm(UUID attemptId, QuestionType epreuve, StrateQcm strate) {}
