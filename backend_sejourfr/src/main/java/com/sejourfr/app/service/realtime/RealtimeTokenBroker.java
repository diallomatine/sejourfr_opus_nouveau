package com.sejourfr.app.service.realtime;

/**
 * Abstraction d'emission d'un token ephemere realtime, independante du
 * fournisseur. Schema de connexion (A) : le backend emet un secret court (la
 * persona/system instruction verrouillee cote serveur) que le client utilise
 * pour ouvrir lui-meme le WebSocket vers le fournisseur.
 *
 * <p>Basculer vers un autre fournisseur (OpenAI Realtime, Qwen…) = fournir un
 * nouvel adaptateur implementant cette interface + pointer
 * {@code sejourfr.realtime.provider} dessus. Aucun changement cote clients
 * au-dela du protocole WS encapsule dans un module dedie par front.
 */
public interface RealtimeTokenBroker {

    /** Identifiant du provider ({@code gemini}, {@code openai}…). */
    String provider();

    /** Faux si la cle/API n'est pas configuree : le service bascule en async. */
    boolean isConfigured();

    /**
     * Vrai si le fournisseur est configure pour la REPRISE de session : le client
     * doit alors conserver le dernier handle reçu et le renvoyer au serveur pour
     * obtenir un nouveau token qui reprend l'echange au lieu d'en ouvrir un neuf.
     */
    boolean supportsResumption();

    /**
     * Emet un token ephemere verrouille sur la configuration donnee (modele,
     * sortie AUDIO, transcription in/out, persona). Le client se connecte
     * ensuite directement au WebSocket du fournisseur avec ce token.
     *
     * @param systemInstruction persona complete (jamais renvoyee au client).
     * @param resumptionHandle  handle de reprise a verrouiller dans le setup, ou
     *                          {@code null} pour une session neuve. Le client ne
     *                          peut pas le poser lui-meme : le token est contraint.
     * @return descripteur de connexion (token + endpoint + modele).
     */
    MintedSession mint(String systemInstruction, String resumptionHandle);

    /**
     * @param token            secret ephemere ({@code access_token}) a passer au WS.
     * @param wsEndpoint       URL WebSocket du fournisseur.
     * @param model            modele effectivement verrouille (pour tracabilite).
     */
    record MintedSession(String token, String wsEndpoint, String model) {}
}
