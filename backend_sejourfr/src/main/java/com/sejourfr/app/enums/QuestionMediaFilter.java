package com.sejourfr.app.enums;

/**
 * Valeurs du filtre « Média » de la console admin
 * ({@code GET /api/admin/questions?media=...}).
 *
 * <p>Enum dediee plutot que {@link MediaType} : « aucun média », « image
 * fichier », « image SVG » et « audio manquant » sont des criteres de recherche
 * legitimes qui ne sont pas des types de média.
 */
public enum QuestionMediaFilter {
    /** Média principal de type AUDIO. */
    AUDIO,
    /** Média principal de type IMAGE (fichier OU SVG). */
    IMAGE,
    /** Média principal de type VIDEO. */
    VIDEO,
    /** Questions sans média principal. */
    NONE,
    /** Image servie depuis un fichier ({@code medias.url} renseignee, R2 ou disque). */
    IMAGE_FILE,
    /**
     * Image servie en SVG inline ({@code inline_svg} renseigne, SANS {@code url} :
     * l'URL primant a l'affichage, une image qui a les deux est un fichier). Les
     * CO image encore a remplacer par une vraie image.
     */
    IMAGE_SVG,
    /** Question de comprehension orale sans bande audio ({@code util/AudioManquant}). */
    AUDIO_MISSING;

    /** Type du média principal vise, ou {@code null} pour un critere qui n'en est pas un. */
    public MediaType toMediaType() {
        return switch (this) {
            case AUDIO -> MediaType.AUDIO;
            case IMAGE, IMAGE_FILE, IMAGE_SVG -> MediaType.IMAGE;
            case VIDEO -> MediaType.VIDEO;
            case NONE, AUDIO_MISSING -> null;
        };
    }
}
