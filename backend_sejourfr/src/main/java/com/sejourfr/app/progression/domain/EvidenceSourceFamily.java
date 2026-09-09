package com.sejourfr.app.progression.domain;

/**
 * Famille de sources suivie separement dans les accumulateurs epoch, pour le
 * seul cap de confiance existant : celui des micro-sujets (V4.2 §11.1, §27.3).
 */
public enum EvidenceSourceFamily {
    MICRO,
    NON_MICRO
}
