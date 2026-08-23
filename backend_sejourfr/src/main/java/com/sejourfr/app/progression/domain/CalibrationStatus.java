package com.sejourfr.app.progression.domain;

/**
 * Une serie CO/CE respecte-t-elle le blueprint 6 EASY / 10 MEDIUM / 4 HARD sur
 * 20 questions (V4.2 §6.2, §7) ?
 *
 * <p>Une serie {@link #UNCALIBRATED} compte dans la progression visible, dans
 * le {@code masteryScore} et dans la confiance, avec un poids reduit a 0.50.
 * Mais elle ne satisfait <b>jamais</b> un {@code qualificationGate} (T05) et ne
 * declenche <b>jamais</b> seule une contradiction forte (§15).
 */
public enum CalibrationStatus {
    CALIBRATED,
    UNCALIBRATED
}
