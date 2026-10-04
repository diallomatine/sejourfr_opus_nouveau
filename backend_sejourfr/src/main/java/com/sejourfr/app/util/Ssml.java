package com.sejourfr.app.util;

/**
 * Autorite unique de la construction SSML « texte -> Azure » cote serveur.
 *
 * <p>Extraite des deux constructeurs qui la recopiaient
 * ({@code ProductionExampleAudioService}, {@code DiagnosticInstructionAudioService}),
 * au moment ou l'import CO image en devenait le troisieme appelant
 * ({@link PropositionsLuesCoImage}). Le gabarit est celui qu'ils produisaient
 * deja, a l'octet pres : voix unique fr-FR, debit 0.95.
 */
public final class Ssml {

    /** Debit commun des syntheses serveur (V802, exemples-modeles, consignes du diagnostic). */
    public static final String DEBIT = "0.95";

    private Ssml() {}

    /** Echappe les 5 entites XML. Un texte echappe ne peut pas ouvrir de balise SSML. */
    public static String echapperXml(String texte) {
        return texte.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&apos;");
    }

    /**
     * Enveloppe un contenu SSML (deja echappe, breaks compris) dans un
     * {@code <speak>} fr-FR a voix unique, debit {@link #DEBIT}. Les breaks
     * restent INTERIEURS a la voix : {@code SsmlValidator.cleanForAzure} ne
     * retire que ceux qui pendent entre deux {@code <voice>}.
     */
    public static String voixUnique(String voix, String contenuSsml) {
        return "<speak version=\"1.0\" xml:lang=\"fr-FR\">"
                + "<voice name=\"" + voix + "\">"
                + "<prosody rate=\"" + DEBIT + "\">" + contenuSsml + "</prosody>"
                + "</voice></speak>";
    }
}
