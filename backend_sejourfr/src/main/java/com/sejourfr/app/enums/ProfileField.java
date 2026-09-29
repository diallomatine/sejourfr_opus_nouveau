package com.sejourfr.app.enums;

/**
 * Un champ du profil <b>obligatoire</b> — ce qu'une inscription locale demande
 * et qu'un compte doit porter avant d'accéder à l'application
 * ({@link com.sejourfr.app.util.ProfilObligatoire}).
 *
 * <p>La date d'examen n'y figure pas et n'y figurera pas : « pas encore de
 * date » est une réponse pleine, jamais un profil incomplet.
 */
public enum ProfileField {
    FIRST_NAME,
    LAST_NAME,
    TARGET_PROCEDURE
}
