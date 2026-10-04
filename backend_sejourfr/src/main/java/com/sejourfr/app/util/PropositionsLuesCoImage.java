package com.sejourfr.app.util;

import java.util.List;

/**
 * Gabarit de l'audio d'une question {@code CO_IMAGE} : une image est affichee,
 * l'audio lit une introduction puis les quatre propositions « A. … B. … ».
 * Autorite unique de la derivation {@code transcript_text} + {@code ssml_text}
 * a partir des propositions (import CO image) : le texte n'est jamais saisi deux
 * fois, il ne peut donc pas diverger entre l'ecran de revue et la bande.
 *
 * <p>Repris du gabarit ecrit a la main des 70 brouillons V802-V814 (voix Denise,
 * debit 0.95, pause 1500 ms apres l'introduction, 300 ms apres chaque lettre,
 * 700 ms entre deux propositions), a une difference pres, voulue : V802 pose
 * la pause de 1500 ms ENTRE deux {@code <voice>}, ou
 * {@code SsmlValidator.cleanForAzure} la retire avant la synthese. Ici tout tient
 * dans une seule voix, et la pause est reellement jouee.
 */
public final class PropositionsLuesCoImage {

    public static final String VOIX = "fr-FR-DeniseNeural";

    public static final String INTRODUCTION =
            "Écoutez les quatre propositions. Choisissez celle qui correspond à l'image.";

    /** Lettres lues, dans l'ordre de {@code display_order} 1..4. */
    public static final List<String> LETTRES = List.of("A", "B", "C", "D");

    private static final String PAUSE_INTRODUCTION = "<break time=\"1500ms\"/>";
    private static final String PAUSE_LETTRE = "<break time=\"300ms\"/>";
    private static final String PAUSE_PROPOSITION = "<break time=\"700ms\"/>";

    private PropositionsLuesCoImage() {}

    /** Transcription : l'introduction, une ligne vide, puis « A. … » une par ligne. */
    public static String transcription(List<String> propositions) {
        exigerQuatre(propositions);
        StringBuilder sb = new StringBuilder(INTRODUCTION).append("\n");
        for (int i = 0; i < propositions.size(); i++) {
            sb.append('\n').append(LETTRES.get(i)).append(". ").append(propositions.get(i));
        }
        return sb.toString();
    }

    /** SSML Azure de la bande, propositions echappees XML. */
    public static String ssml(List<String> propositions) {
        exigerQuatre(propositions);
        StringBuilder contenu = new StringBuilder(Ssml.echapperXml(INTRODUCTION)).append(PAUSE_INTRODUCTION);
        for (int i = 0; i < propositions.size(); i++) {
            if (i > 0) contenu.append(PAUSE_PROPOSITION);
            contenu.append(LETTRES.get(i)).append('.').append(PAUSE_LETTRE)
                    .append(Ssml.echapperXml(propositions.get(i)));
        }
        return Ssml.voixUnique(VOIX, contenu.toString());
    }

    private static void exigerQuatre(List<String> propositions) {
        if (propositions == null || propositions.size() != LETTRES.size()) {
            throw new IllegalArgumentException("Une question CO image lit exactement 4 propositions");
        }
    }
}
