package com.sejourfr.app.enums;

/**
 * Type d'une session (attempt).
 * <p>
 * - TRAINING : entraînement libre. Correction immédiate après chaque réponse.
 * - MOCK_EXAM : examen blanc en conditions réelles. Chronomètre + correction
 * uniquement à la fin (POST /finish).
 * - REVIEW : session de révision (favoris ou erreurs récentes). Pas de chrono,
 * correction immédiate comme en TRAINING.
 */
public enum AttemptType {
    TRAINING,
    MOCK_EXAM,
    REVIEW
}