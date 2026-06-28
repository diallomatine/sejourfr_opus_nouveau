package com.sejourfr.app.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Configuration du mode "expression orale temps reel" (examinateur vocal IA,
 * Taches 1 & 2). Lu via {@code sejourfr.realtime.*}.
 *
 * <p>Tout est configurable (aucune valeur metier en dur cote code) : provider,
 * modele, endpoint, formats audio, voix, TTL des tokens, et surtout le QUOTA de
 * sessions par pass (cap keye par {@code Plan.code}). Le schema de connexion
 * retenu est (A) "client -> Gemini en direct via token ephemere" : le backend
 * NE relaie PAS l'audio, il se contente d'emettre le token (persona verrouillee
 * dedans cote serveur), de recevoir le transcript, et de tenir le quota.
 *
 * <p>L'abstraction fournisseur vit dans {@code service/realtime} (interface
 * {@code RealtimeTokenBroker} + adaptateur par provider). Basculer vers OpenAI
 * Realtime / Qwen = nouvel adaptateur + {@code provider} + bloc de config, sans
 * refonte.
 */
@ConfigurationProperties(prefix = "sejourfr.realtime")
public class RealtimeProperties {

    /** Provider actif. Aujourd'hui seul {@code gemini} est implemente. */
    private String provider = "gemini";

    /** Version du gabarit de persona charge par {@code RealtimePersonaBuilder}. */
    private String personaVersion = "v1";

    private Gemini gemini = new Gemini();
    private Audio audio = new Audio();
    private Quota quota = new Quota();

    /**
     * Fenetre (secondes) pendant laquelle une session PENDING "reserve" un slot
     * de quota, le temps que le client etablisse la connexion. Au-dela, une
     * session PENDING jamais connectee ne compte plus (le token a expire). Evite
     * qu'un client multiplie les mint sans connexion pour depasser le cap.
     */
    private int reservationWindowSeconds = 300;

    public String getProvider() { return provider; }
    public void setProvider(String provider) { this.provider = provider; }

    public String getPersonaVersion() { return personaVersion; }
    public void setPersonaVersion(String personaVersion) { this.personaVersion = personaVersion; }

    public Gemini getGemini() { return gemini; }
    public void setGemini(Gemini gemini) { this.gemini = gemini; }

    public Audio getAudio() { return audio; }
    public void setAudio(Audio audio) { this.audio = audio; }

    public Quota getQuota() { return quota; }
    public void setQuota(Quota quota) { this.quota = quota; }

    public int getReservationWindowSeconds() { return reservationWindowSeconds; }
    public void setReservationWindowSeconds(int v) { this.reservationWindowSeconds = v; }

    /**
     * Gemini Live (audio natif). Token ephemere emis via l'endpoint REST
     * {@code v1alpha/auth_tokens} ; le client se connecte ensuite au WebSocket
     * {@code BidiGenerateContent} en passant le token en {@code access_token}.
     *
     * <p>⚠️ La gamme native-audio evolue. Defaut pose sur l'alias GA stable
     * {@code gemini-live-2.5-flash-native-audio} (le preview
     * {@code ...-09-2025} est deprecie le 2026-03-19). A reverifier dans le
     * registre Gemini Live au moment d'un build et surchargeable par env.
     */
    public static class Gemini {
        private String apiKey = "";
        private String authTokensUrl = "https://generativelanguage.googleapis.com/v1alpha/auth_tokens";
        // Token ephemere CONTRAINT (liveConnectConstraints) -> endpoint
        // "...Constrained" (les champs verrouilles, dont la system instruction
        // et la transcription, ne s'appliquent que sur celui-ci).
        private String wsEndpoint =
                "wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContentConstrained";
        private String model = "gemini-live-2.5-flash-native-audio";
        private String voice = "Aoede";
        private double temperature = 0.7;
        /** Le token ne sert qu'a ouvrir UNE session. */
        private int tokenUses = 1;
        /** Delai pour DEMARRER la session avec le token (newSessionExpireTime). */
        private int newSessionExpireSeconds = 120;
        /** Duree pendant laquelle on peut echanger sur la session (expireTime). */
        private int sessionExpireSeconds = 1800;
        private int timeoutSec = 15;

        public boolean isConfigured() {
            return apiKey != null && !apiKey.isBlank();
        }

        public String getApiKey() { return apiKey; }
        public void setApiKey(String apiKey) { this.apiKey = apiKey; }

        public String getAuthTokensUrl() { return authTokensUrl; }
        public void setAuthTokensUrl(String authTokensUrl) { this.authTokensUrl = authTokensUrl; }

        public String getWsEndpoint() { return wsEndpoint; }
        public void setWsEndpoint(String wsEndpoint) { this.wsEndpoint = wsEndpoint; }

        public String getModel() { return model; }
        public void setModel(String model) { this.model = model; }

        public String getVoice() { return voice; }
        public void setVoice(String voice) { this.voice = voice; }

        public double getTemperature() { return temperature; }
        public void setTemperature(double temperature) { this.temperature = temperature; }

        public int getTokenUses() { return tokenUses; }
        public void setTokenUses(int tokenUses) { this.tokenUses = tokenUses; }

        public int getNewSessionExpireSeconds() { return newSessionExpireSeconds; }
        public void setNewSessionExpireSeconds(int v) { this.newSessionExpireSeconds = v; }

        public int getSessionExpireSeconds() { return sessionExpireSeconds; }
        public void setSessionExpireSeconds(int v) { this.sessionExpireSeconds = v; }

        public int getTimeoutSec() { return timeoutSec; }
        public void setTimeoutSec(int timeoutSec) { this.timeoutSec = timeoutSec; }
    }

    /**
     * Formats audio attendus par Gemini Live : entree PCM 16 bits 16 kHz mono,
     * sortie PCM 24 kHz. Exposes au client dans le descripteur de session pour
     * qu'il capture/joue au bon format.
     */
    public static class Audio {
        private int inputSampleRate = 16000;
        private String inputMimeType = "audio/pcm;rate=16000";
        private int outputSampleRate = 24000;

        public int getInputSampleRate() { return inputSampleRate; }
        public void setInputSampleRate(int v) { this.inputSampleRate = v; }

        public String getInputMimeType() { return inputMimeType; }
        public void setInputMimeType(String v) { this.inputMimeType = v; }

        public int getOutputSampleRate() { return outputSampleRate; }
        public void setOutputSampleRate(int v) { this.outputSampleRate = v; }
    }

    /**
     * Quota de sessions temps reel par pass. {@code byPlanCode} mappe un
     * {@code Plan.code} vers son nombre de sessions (valeurs provisoires :
     * Sprint ~25, Trimestre ~60, Annuel ~120). {@code defaultSessions} sert de
     * repli si le code n'est pas liste. Le quota n'est ouvert qu'aux pass TCF
     * (module INTEGRAL) — un plan non liste retombe sur {@code defaultSessions}.
     */
    public static class Quota {
        private int defaultSessions = 0;
        private Map<String, Integer> byPlanCode = new LinkedHashMap<>();

        public int getDefaultSessions() { return defaultSessions; }
        public void setDefaultSessions(int defaultSessions) { this.defaultSessions = defaultSessions; }

        public Map<String, Integer> getByPlanCode() { return byPlanCode; }
        public void setByPlanCode(Map<String, Integer> byPlanCode) { this.byPlanCode = byPlanCode; }
    }
}
