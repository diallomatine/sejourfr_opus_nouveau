package com.sejourfr.app.enums;

/**
 * Valeurs du filtre « Média » de la console admin
 * ({@code GET /api/admin/questions?media=...}) : les trois types de média
 * plus {@code NONE} pour « questions sans média ».
 *
 * <p>Enum dediee plutot que {@link MediaType} : « aucun média » est un critere
 * de recherche legitime qui n'est pas un type de média.
 */
public enum QuestionMediaFilter {
    AUDIO,
    IMAGE,
    VIDEO,
    /** Questions sans média principal. */
    NONE;

    /** Type de média correspondant, ou {@code null} pour {@link #NONE}. */
    public MediaType toMediaType() {
        return this == NONE ? null : MediaType.valueOf(name());
    }
}
