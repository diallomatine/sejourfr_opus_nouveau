package com.sejourfr.app.enums;

/**
 * Canal par lequel le {@code claimToken} d'une run est revenu au serveur
 * ({@code diagnostic_run.claimed_via}, V074). Dans les deux cas c'est le
 * <b>jeton</b> qui prouve la run : il n'existe aucune recherche heuristique,
 * et les verifications du claim sont les memes (hash, expiration, jamais
 * claimee, sans porteur).
 *
 * <ul>
 *   <li>{@link #SAME_DEVICE} : le jeton lu dans le brouillon de l'appareil qui a
 *       cree la run (IndexedDB / SharedPreferences), transmis a l'auth.</li>
 *   <li>{@link #APP_LINK} : le meme jeton porte par le lien web → app
 *       « Continuer sur l'application » (lot 3b), recu par l'app puis transmis
 *       a l'auth avec {@code claimVia = "APP_LINK"}.</li>
 * </ul>
 */
public enum DiagnosticRunClaimVia {
    SAME_DEVICE,
    APP_LINK;

    /**
     * Le canal <b>declare</b> par le client dans la requete d'auth. Absent,
     * vide ou inconnu : {@link #SAME_DEVICE}, le comportement d'avant le lot 3b
     * — une valeur illisible ne fait jamais un 400 d'auth. Le canal ne donne
     * aucun droit : il qualifie un claim que le jeton seul autorise.
     */
    public static DiagnosticRunClaimVia fromClient(String raw) {
        return raw != null && APP_LINK.name().equals(raw.trim()) ? APP_LINK : SAME_DEVICE;
    }
}
