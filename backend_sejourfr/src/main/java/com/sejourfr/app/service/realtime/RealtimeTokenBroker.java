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
     * Emet un token ephemere verrouille sur la configuration donnee (modele,
     * sortie AUDIO, transcription in/out, persona). Le client se connecte
     * ensuite directement au WebSocket du fournisseur avec ce token.
     *
     * @param systemInstruction persona complete (jamais renvoyee au client).
     * @return descripteur de connexion (token + endpoint + modele).
     */
    MintedSession mint(String systemInstruction);

    /**
     * @param token            secret ephemere ({@code access_token}) a passer au WS.
     * @param wsEndpoint       URL WebSocket du fournisseur.
     * @param model            modele effectivement verrouille (pour tracabilite).
     */
    record MintedSession(String token, String wsEndpoint, String model) {}
}
