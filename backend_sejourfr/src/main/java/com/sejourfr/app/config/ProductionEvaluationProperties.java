package com.sejourfr.app.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Parametres du pipeline d'evaluation des productions (EO/EE).
 * <p>
 * On ne reutilise PAS {@code sejourfr.anthropic} (qui est dedie au pipeline de
 * generation de questions audio CO et fixe son propre model/prompt-version) :
 * l'evaluation a son propre namespace pour pouvoir tourner sur un modele
 * different (claude-sonnet-4-5 plutot qu'opus 4.7).
 */
@ConfigurationProperties(prefix = "sejourfr.production-evaluation")
public class ProductionEvaluationProperties {

    private Anthropic anthropic = new Anthropic();

    /** Plafond audio accepte pour une submission EO (defaut: 5 min). */
    private int maxAudioDurationSeconds = 300;

    /** Plafond mots accepte pour une submission EE. */
    private int maxTextWords = 300;

    /** Plancher mots accepte pour une submission EE. */
    private int minTextWords = 10;

    /** Taille max upload audio (bytes). */
    private long maxAudioSizeBytes = 25L * 1024 * 1024;

    /** Logging systematique des couts (tokens/centimes). */
    private boolean costTrackingEnabled = true;

    /** Anti-abus : nombre max de retries manuels par submission. */
    private int maxRetriesPerSubmission = 3;

    /** TTL des URL signees pour recuperer l'audio user (minutes). */
    private int presignedUrlExpiryMinutes = 15;

    public Anthropic getAnthropic() { return anthropic; }
    public void setAnthropic(Anthropic anthropic) { this.anthropic = anthropic; }

    public int getMaxAudioDurationSeconds() { return maxAudioDurationSeconds; }
    public void setMaxAudioDurationSeconds(int maxAudioDurationSeconds) {
        this.maxAudioDurationSeconds = maxAudioDurationSeconds;
    }

    public int getMaxTextWords() { return maxTextWords; }
    public void setMaxTextWords(int maxTextWords) { this.maxTextWords = maxTextWords; }

    public int getMinTextWords() { return minTextWords; }
    public void setMinTextWords(int minTextWords) { this.minTextWords = minTextWords; }

    public long getMaxAudioSizeBytes() { return maxAudioSizeBytes; }
    public void setMaxAudioSizeBytes(long maxAudioSizeBytes) { this.maxAudioSizeBytes = maxAudioSizeBytes; }

    public boolean isCostTrackingEnabled() { return costTrackingEnabled; }
    public void setCostTrackingEnabled(boolean costTrackingEnabled) {
        this.costTrackingEnabled = costTrackingEnabled;
    }

    public int getMaxRetriesPerSubmission() { return maxRetriesPerSubmission; }
    public void setMaxRetriesPerSubmission(int maxRetriesPerSubmission) {
        this.maxRetriesPerSubmission = maxRetriesPerSubmission;
    }

    public int getPresignedUrlExpiryMinutes() { return presignedUrlExpiryMinutes; }
    public void setPresignedUrlExpiryMinutes(int presignedUrlExpiryMinutes) {
        this.presignedUrlExpiryMinutes = presignedUrlExpiryMinutes;
    }

    public static class Anthropic {
        private String apiKey = "";
        private String apiUrl = "https://api.anthropic.com/v1/messages";
        private String anthropicVersion = "2023-06-01";
        private String model = "claude-sonnet-4-5";
        private int maxTokens = 2000;
        private int timeoutSec = 60;
        private int maxRetries = 2;
        private long retryBackoffMs = 1000L;
        /** Versionne dans ai_evaluations.prompt_version. */
        private String promptVersion = "v1.0";

        public boolean isConfigured() {
            return apiKey != null && !apiKey.isBlank();
        }

        public String getApiKey() { return apiKey; }
        public void setApiKey(String apiKey) { this.apiKey = apiKey; }

        public String getApiUrl() { return apiUrl; }
        public void setApiUrl(String apiUrl) { this.apiUrl = apiUrl; }

        public String getAnthropicVersion() { return anthropicVersion; }
        public void setAnthropicVersion(String anthropicVersion) {
            this.anthropicVersion = anthropicVersion;
        }

        public String getModel() { return model; }
        public void setModel(String model) { this.model = model; }

        public int getMaxTokens() { return maxTokens; }
        public void setMaxTokens(int maxTokens) { this.maxTokens = maxTokens; }

        public int getTimeoutSec() { return timeoutSec; }
        public void setTimeoutSec(int timeoutSec) { this.timeoutSec = timeoutSec; }

        public int getMaxRetries() { return maxRetries; }
        public void setMaxRetries(int maxRetries) { this.maxRetries = maxRetries; }

        public long getRetryBackoffMs() { return retryBackoffMs; }
        public void setRetryBackoffMs(long retryBackoffMs) { this.retryBackoffMs = retryBackoffMs; }

        public String getPromptVersion() { return promptVersion; }
        public void setPromptVersion(String promptVersion) { this.promptVersion = promptVersion; }
    }
}
