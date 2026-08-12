package com.sejourfr.app.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

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

    public String getProvider() { return provider; }
    public void setProvider(String provider) { this.provider = provider; }

    public String getPersonaVersion() { return personaVersion; }
    public void setPersonaVersion(String personaVersion) { this.personaVersion = personaVersion; }

    public Gemini getGemini() { return gemini; }
    public void setGemini(Gemini gemini) { this.gemini = gemini; }

    public Audio getAudio() { return audio; }
    public void setAudio(Audio audio) { this.audio = audio; }

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
        private Vad vad = new Vad();
        private SessionResumption sessionResumption = new SessionResumption();
        private ContextWindowCompression contextWindowCompression = new ContextWindowCompression();
        /**
         * Nombre d'ouvertures de WebSocket admises pour UN token. 1 = le token
         * meurt a la premiere connexion, donc une coupure reseau detruit la
         * session. 3 = ouverture + 2 reprises sans repasser par le serveur.
         */
        private int tokenUses = 3;
        /**
         * Delai pour DEMARRER (ou REPRENDRE) la session avec le token
         * (newSessionExpireTime). Doit couvrir une coupure reseau realiste
         * (tunnel, ascenseur, bascule wifi/4G), sans quoi le token est mort
         * avant que le candidat soit revenu.
         */
        private int newSessionExpireSeconds = 600;
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

        public Vad getVad() { return vad; }
        public void setVad(Vad vad) { this.vad = vad; }

        public SessionResumption getSessionResumption() { return sessionResumption; }
        public void setSessionResumption(SessionResumption v) { this.sessionResumption = v; }

        public ContextWindowCompression getContextWindowCompression() { return contextWindowCompression; }
        public void setContextWindowCompression(ContextWindowCompression v) { this.contextWindowCompression = v; }

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
     * VAD (detection d'activite vocale) de Gemini Live, verrouillee dans le token
     * cote serveur via {@code realtimeInputConfig.automaticActivityDetection}.
     * Specifique au fournisseur (les valeurs de sensibilite sont des enums
     * Gemini).
     *
     * <p>Arbitrage patience ↔ reactivite. {@code endSensitivity=MEDIUM} est le
     * compromis retenu : {@code LOW} (l'ancien defaut) demande la confirmation la
     * plus prudente avant de declarer la fin de parole, ce qui se paie par une
     * attente ressentie « l'examinateur met trop de temps a repondre » une fois
     * que le candidat a fini ; {@code HIGH} couperait un apprenant A2 en pleine
     * hesitation. {@code startSensitivity=HIGH} detecte vite le DEBUT de parole.
     * Une SEULE fenetre de silence pour tous les niveaux ({@code silenceDurationMs}),
     * a 500 ms = plancher recommande par Google (500-800) — ne pas descendre sous
     * 500 sous peine de fragmenter un enonce sur ses pauses naturelles.
     *
     * <p>Les cinq valeurs sont surchargeables par variable d'environnement
     * ({@code REALTIME_GEMINI_VAD_*}) : essayer un autre reglage ne demande pas
     * de recompilation.
     */
    public static class Vad {
        private boolean disabled = false;
        private String startSensitivity = "START_SENSITIVITY_HIGH";
        private String endSensitivity = "END_SENSITIVITY_MEDIUM";
        private int prefixPaddingMs = 300;
        /**
         * Fenetre de silence (ms) avant de considerer le tour du candidat fini.
         * 500 = bas de la fourchette Google recommandee (500-800, defaut serveur
         * ~800) : reduit ~de moitie l'attente avant que l'examinateur reponde,
         * sans fragmenter la parole (ne pas descendre sous ~500).
         */
        private int silenceDurationMs = 500;

        public boolean isDisabled() { return disabled; }
        public void setDisabled(boolean disabled) { this.disabled = disabled; }

        public String getStartSensitivity() { return startSensitivity; }
        public void setStartSensitivity(String v) { this.startSensitivity = v; }

        public String getEndSensitivity() { return endSensitivity; }
        public void setEndSensitivity(String v) { this.endSensitivity = v; }

        public int getPrefixPaddingMs() { return prefixPaddingMs; }
        public void setPrefixPaddingMs(int v) { this.prefixPaddingMs = v; }

        public int getSilenceDurationMs() { return silenceDurationMs; }
        public void setSilenceDurationMs(int v) { this.silenceDurationMs = v; }
    }

    /**
     * REPRISE DE SESSION ({@code sessionResumption} du setup verrouille). Sans
     * elle, une coupure du WebSocket (metro, wifi qui saute, appli en arriere-plan)
     * detruit definitivement la session ET le slot deja debite au candidat : il
     * paie une simulation qu'il n'a pas pu terminer.
     *
     * <p>Activee, le fournisseur emet periodiquement un {@code sessionResumptionUpdate}
     * porteur d'un {@code newHandle}. Le client garde le dernier reçu et le
     * renvoie a la reprise ; le handle reste valide 2 h apres la fin de la session.
     *
     * <p>⚠️ Le token est CONTRAINT ({@code BidiGenerateContentConstrained}) : le
     * client ne peut poser aucun champ de setup, donc il ne peut pas glisser
     * lui-meme le handle. C'est le serveur qui le verrouille dans le setup d'un
     * NOUVEAU token, emis par {@code POST /sessions/{id}/resume} — d'ou
     * {@code maxResumptions}, qui borne le nombre de tokens qu'une session peut
     * faire emettre.
     */
    public static class SessionResumption {
        private boolean enabled = true;
        /** Reprises admises pour une meme session (bornage anti-abus). */
        private int maxResumptions = 3;

        public boolean isEnabled() { return enabled; }
        public void setEnabled(boolean enabled) { this.enabled = enabled; }

        public int getMaxResumptions() { return maxResumptions; }
        public void setMaxResumptions(int v) { this.maxResumptions = v; }
    }

    /**
     * COMPRESSION DE LA FENETRE DE CONTEXTE (fenetre glissante). L'audio consomme
     * ~25 tokens/s et une session audio est plafonnee a 15 min SANS compression.
     * Nos sessions EO visent ~200 s, donc ce n'est pas encore bloquant — mais
     * c'est ce qui permet a une session REPRISE (dont le contexte repart de son
     * handle) de ne pas heurter ce plafond.
     *
     * <p>{@code triggerTokens} = seuil de declenchement ; {@code targetTokens} =
     * taille visee apres compression. A 0, le champ n'est pas envoye et le
     * fournisseur applique son propre defaut.
     */
    public static class ContextWindowCompression {
        private boolean enabled = true;
        private long triggerTokens = 25600;
        private long targetTokens = 12800;

        public boolean isEnabled() { return enabled; }
        public void setEnabled(boolean enabled) { this.enabled = enabled; }

        public long getTriggerTokens() { return triggerTokens; }
        public void setTriggerTokens(long v) { this.triggerTokens = v; }

        public long getTargetTokens() { return targetTokens; }
        public void setTargetTokens(long v) { this.targetTokens = v; }
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
}
