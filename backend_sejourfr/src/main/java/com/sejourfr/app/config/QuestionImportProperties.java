package com.sejourfr.app.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Reglages de l'import par lot des questions CO image
 * ({@code /api/admin/question-imports/co-image/*}).
 *
 * <p>🛑 <b>Valeurs par defaut IDENTIQUES a celles d'application.yaml.</b> Les
 * contraintes techniques des IMAGES (formats, ratio, largeur, opacite) ne vivent
 * pas ici : elles sont dans la charte versionnee, leur seule autorite.
 */
@Getter
@Setter
@ConfigurationProperties(prefix = "sejourfr.question-import.co-image")
public class QuestionImportProperties {

    /**
     * Theme pose quand le manifeste ne donne pas de {@code themeCode}. TCF_CO
     * est le theme des 70 CO image existantes (V802-V814) et de toute la CO.
     */
    private String defaultThemeCode = "TCF_CO";

    /** Charte des images, chemin classpath. Changer de version = changer cette valeur. */
    private String charte = "generation_questions/charte-images-co-v1.json";

    /** Nombre maximal de questions par lot (borne aussi la requete multipart). */
    private int maxQuestions = 20;

    /** Longueur maximale d'une proposition lue, en caracteres. */
    private int choiceMaxLength = 120;

    /** Longueur maximale de la description de scene (devient image_alt_text). */
    private int sceneDescriptionMaxLength = 500;

    /** Longueur maximale de l'explication de correction. */
    private int explanationMaxLength = 2000;
}
