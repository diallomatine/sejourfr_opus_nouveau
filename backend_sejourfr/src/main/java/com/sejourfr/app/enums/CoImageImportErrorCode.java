package com.sejourfr.app.enums;

/**
 * Codes d'erreur de l'import CO image (rapport d'analyse et 422 d'import).
 * Contrat de la console admin : un code ne se renomme pas, il s'ajoute.
 *
 * <p>Erreurs de LOT (champ {@code errors} du rapport) : {@link #MANIFESTE_ILLISIBLE},
 * {@link #VERSION_INCONNUE}, {@link #FORMAT_INCONNU}, {@link #NOMBRE_QUESTIONS},
 * {@link #FICHIER_EN_TROP}, {@link #FICHIER_EN_DOUBLE}. Toutes les autres sont
 * portees par une question ({@code questions[i].errors}).
 */
public enum CoImageImportErrorCode {
    MANIFESTE_ILLISIBLE,
    VERSION_INCONNUE,
    FORMAT_INCONNU,
    NOMBRE_QUESTIONS,
    FICHIER_EN_TROP,
    FICHIER_EN_DOUBLE,

    QUESTION_ABSENTE,
    EXTERNAL_ID_INVALIDE,
    EXTERNAL_ID_EN_DOUBLE,
    EXTERNAL_ID_DEJA_IMPORTE,
    NIVEAU_INVALIDE,
    THEME_INCONNU,
    THEME_HORS_TCF,
    CHOIX_NOMBRE,
    CHOIX_VIDE,
    CHOIX_TROP_LONG,
    CHOIX_EN_DOUBLE,
    BONNE_REPONSE_INVALIDE,
    DESCRIPTION_SCENE_VIDE,
    DESCRIPTION_SCENE_TROP_LONGUE,
    EXPLICATION_TROP_LONGUE,

    IMAGE_NON_RENSEIGNEE,
    IMAGE_REFERENCEE_PLUSIEURS_FOIS,
    IMAGE_ABSENTE,
    IMAGE_TROP_LOURDE,
    IMAGE_FORMAT_INVALIDE,
    IMAGE_FORMAT_HORS_CHARTE,
    IMAGE_ILLISIBLE,
    IMAGE_TROP_PETITE,
    IMAGE_RATIO,
    IMAGE_TRANSPARENTE
}
