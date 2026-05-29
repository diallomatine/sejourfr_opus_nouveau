package com.sejourfr.app.enums;

/**
 * Cycle de vie de la génération audio d'un {@link com.sejourfr.app.entity.ProductionExample}
 * d'Expression Orale.
 *
 * <pre>
 *   NONE ──▶ PENDING ──▶ GENERATING ──▶ GENERATED ──▶ PUBLISHED
 *                                   └──▶ ERROR (relançable)
 * </pre>
 *
 * Seuls les exemples {@code PUBLISHED} exposent leur {@code audio_url} au candidat.
 * Les exemples EE restent en {@code NONE} (pas d'audio).
 */
public enum ExampleAudioStatus {
    NONE,
    PENDING,
    GENERATING,
    GENERATED,
    PUBLISHED,
    ERROR
}
