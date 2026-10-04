package com.sejourfr.app.dto;

import java.util.List;

/**
 * Une question du manifeste d'import CO image. Champs volontairement en
 * {@code String} : une valeur fautive (niveau, lettre) devient une erreur de la
 * question dans le rapport, pas un 400 qui masquerait toutes les autres.
 *
 * @param externalId       identifiant editorial, {@code [a-z0-9-]{3,64}}, unique pour toujours
 * @param level            A2 / B1 / B2
 * @param themeCode        facultatif ; absent = theme CO par defaut (config)
 * @param image            nom EXACT du fichier joint dans la partie {@code images}
 * @param sceneDescription description de la scene, devient {@code image_alt_text}
 * @param choices          exactement 4 propositions, lues dans l'ordre A, B, C, D
 * @param correctAnswer    lettre de la bonne proposition, A a D
 * @param explanation      facultative, affichee a la correction
 */
public record CoImageImportQuestion(
        String externalId,
        String level,
        String themeCode,
        String image,
        String sceneDescription,
        List<String> choices,
        String correctAnswer,
        String explanation
) {}
