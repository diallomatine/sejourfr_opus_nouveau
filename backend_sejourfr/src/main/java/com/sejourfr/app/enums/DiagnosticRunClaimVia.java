package com.sejourfr.app.enums;

/**
 * Canal par lequel le {@code claimToken} d'une run est revenu au serveur
 * ({@code diagnostic_run.claimed_via}, V074). Dans les deux cas c'est le
 * <b>jeton</b> qui prouve la run : il n'existe aucune recherche heuristique.
 *
 * <ul>
 *   <li>{@link #SAME_DEVICE} : le jeton lu dans le brouillon de l'appareil qui a
 *       cree la run (IndexedDB / SharedPreferences), transmis a l'auth.</li>
 *   <li>{@link #APP_LINK} : le meme jeton porte par le lien web → app (lot 3b).
 *       Le service de claim l'accepte deja ; aucun client ne l'envoie encore.</li>
 * </ul>
 */
public enum DiagnosticRunClaimVia {
    SAME_DEVICE,
    APP_LINK
}
