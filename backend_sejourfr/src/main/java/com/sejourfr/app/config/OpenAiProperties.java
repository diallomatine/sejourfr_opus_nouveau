package com.sejourfr.app.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Configuration OpenAI Whisper (transcription audio).
 * Note : la cle <code>sejourfr.anthropic</code> est deja prise par le pipeline
 * de generation de questions audio (audioquestion/). Pour l'evaluation des
 * productions on a un namespace dedie <code>sejourfr.production-evaluation</code>.
 */
@ConfigurationProperties(prefix = "sejourfr.openai")
public class OpenAiProperties {

    private String apiKey = "";
    private String apiUrl = "https://api.openai.com/v1/audio/transcriptions";

    private Whisper whisper = new Whisper();

    public boolean isConfigured() {
        return apiKey != null && !apiKey.isBlank();
    }

    public String getApiKey() { return apiKey; }
    public void setApiKey(String apiKey) { this.apiKey = apiKey; }

    public String getApiUrl() { return apiUrl; }
    public void setApiUrl(String apiUrl) { this.apiUrl = apiUrl; }

    public Whisper getWhisper() { return whisper; }
    public void setWhisper(Whisper whisper) { this.whisper = whisper; }

    public static class Whisper {
        private String model = "whisper-1";
        private String language = "fr";
        private int timeoutSec = 60;
        private int maxRetries = 2;
        private long retryBackoffMs = 1000L;
        /**
         * Prompt force la transcription en mode "litteral" : Whisper a tendance
         * a auto-corriger les fautes grammaticales d'un apprenant, ce qui rend
         * l'evaluation par Claude trop indulgente. Cf. spec section 2.4.
         */
        private String literalModePrompt =
            "Transcription litterale d'un apprenant de francais langue etrangere. "
            + "Conserver les hesitations, les repetitions, et les eventuelles fautes "
            + "grammaticales telles que prononcees.";

        public String getModel() { return model; }
        public void setModel(String model) { this.model = model; }

        public String getLanguage() { return language; }
        public void setLanguage(String language) { this.language = language; }

        public int getTimeoutSec() { return timeoutSec; }
        public void setTimeoutSec(int timeoutSec) { this.timeoutSec = timeoutSec; }

        public int getMaxRetries() { return maxRetries; }
        public void setMaxRetries(int maxRetries) { this.maxRetries = maxRetries; }

        public long getRetryBackoffMs() { return retryBackoffMs; }
        public void setRetryBackoffMs(long retryBackoffMs) { this.retryBackoffMs = retryBackoffMs; }

        public String getLiteralModePrompt() { return literalModePrompt; }
        public void setLiteralModePrompt(String literalModePrompt) { this.literalModePrompt = literalModePrompt; }
    }
}
