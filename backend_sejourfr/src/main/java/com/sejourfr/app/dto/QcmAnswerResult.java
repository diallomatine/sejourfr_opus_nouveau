package com.sejourfr.app.dto;

import com.sejourfr.app.enums.Difficulty;

import java.util.UUID;

/**
 * Résultat unitaire d'une question QCM pour l'estimation du niveau CECRL.
 * {@code difficulty} porte la strate TCF de la question (A2 / B1 / B2) ; les
 * autres valeurs de {@link Difficulty} (CSP/CR/NAT côté civique) sont ignorées
 * par l'estimateur.
 */
public record QcmAnswerResult(UUID questionId, Difficulty difficulty, boolean correct) {}
