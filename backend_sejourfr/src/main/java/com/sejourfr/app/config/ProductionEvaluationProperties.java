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

    /**
     * Provider LLM actif pour l'evaluation des productions. Valeurs supportees :
     * {@code openai}, {@code anthropic}, {@code deepseek} (et tout endpoint
     * compatible OpenAI via le bloc deepseek/openai). Bascule a chaud
     * (redemarrage du backend suffit, aucune migration / aucun changement mobile).
     */
    private String provider = "openai";

    /**
     * Version du fichier de rubriques par tache charge par
     * {@code ProductionRubricsProvider} : {@code prompts/production-rubrics-<v>.json}.
     * Source unique du "comment noter" propre a chaque tache (criteres, bareme,
     * descripteurs, consignes). Independant de la prompt-version (templates).
     */
    private String rubricsVersion = "v1";

    private Anthropic anthropic = new Anthropic();
    private OpenAi openai = new OpenAi();
    private DeepSeek deepseek = new DeepSeek();
    private NiveauCecrl niveauCecrl = new NiveauCecrl();
    /**
     * Plafond audio accepte pour une submission EO (defaut: 5 min).
     */
    private int maxAudioDurationSeconds = 300;
    /**
     * Plafond mots accepte pour une submission EE.
     */
    private int maxTextWords = 300;
    /**
     * Plancher mots accepte pour une submission EE.
     */
    private int minTextWords = 10;
    /**
     * Taille max upload audio (bytes).
     */
    private long maxAudioSizeBytes = 25L * 1024 * 1024;
    /**
     * Logging systematique des couts (tokens/centimes).
     */
    private boolean costTrackingEnabled = true;
    /**
     * Anti-abus : nombre max de retries manuels par submission.
     */
    private int maxRetriesPerSubmission = 3;
    /**
     * TTL des URL signees pour recuperer l'audio user (minutes).
     */
    private int presignedUrlExpiryMinutes = 15;

    public String getProvider() {
        return provider;
    }

    public void setProvider(String provider) {
        this.provider = provider;
    }

    public String getRubricsVersion() {
        return rubricsVersion;
    }

    public void setRubricsVersion(String rubricsVersion) {
        this.rubricsVersion = rubricsVersion;
    }

    public Anthropic getAnthropic() {
        return anthropic;
    }

    public void setAnthropic(Anthropic anthropic) {
        this.anthropic = anthropic;
    }

    public OpenAi getOpenai() {
        return openai;
    }

    public void setOpenai(OpenAi openai) {
        this.openai = openai;
    }

    public DeepSeek getDeepseek() {
        return deepseek;
    }

    public void setDeepseek(DeepSeek deepseek) {
        this.deepseek = deepseek;
    }

    public NiveauCecrl getNiveauCecrl() {
        return niveauCecrl;
    }

    public void setNiveauCecrl(NiveauCecrl niveauCecrl) {
        this.niveauCecrl = niveauCecrl;
    }

    public int getMaxAudioDurationSeconds() {
        return maxAudioDurationSeconds;
    }

    public void setMaxAudioDurationSeconds(int maxAudioDurationSeconds) {
        this.maxAudioDurationSeconds = maxAudioDurationSeconds;
    }

    public int getMaxTextWords() {
        return maxTextWords;
    }

    public void setMaxTextWords(int maxTextWords) {
        this.maxTextWords = maxTextWords;
    }

    public int getMinTextWords() {
        return minTextWords;
    }

    public void setMinTextWords(int minTextWords) {
        this.minTextWords = minTextWords;
    }

    public long getMaxAudioSizeBytes() {
        return maxAudioSizeBytes;
    }

    public void setMaxAudioSizeBytes(long maxAudioSizeBytes) {
        this.maxAudioSizeBytes = maxAudioSizeBytes;
    }

    public boolean isCostTrackingEnabled() {
        return costTrackingEnabled;
    }

    public void setCostTrackingEnabled(boolean costTrackingEnabled) {
        this.costTrackingEnabled = costTrackingEnabled;
    }

    public int getMaxRetriesPerSubmission() {
        return maxRetriesPerSubmission;
    }

    public void setMaxRetriesPerSubmission(int maxRetriesPerSubmission) {
        this.maxRetriesPerSubmission = maxRetriesPerSubmission;
    }

    public int getPresignedUrlExpiryMinutes() {
        return presignedUrlExpiryMinutes;
    }

    public void setPresignedUrlExpiryMinutes(int presignedUrlExpiryMinutes) {
        this.presignedUrlExpiryMinutes = presignedUrlExpiryMinutes;
    }

    /**
     * Reglages communs aux providers compatibles OpenAI (Chat Completions +
     * function calling) : OpenAI, DeepSeek, ou tout endpoint OpenAI-compatible.
     * Pilote {@code OpenAiCompatibleEvalClient} sans dupliquer le client.
     */
    public interface ChatCompletionSettings {
        String getApiKey();

        String getApiUrl();

        String getModel();

        int getMaxTokens();

        int getTimeoutSec();

        String getPromptVersion();

        double getCostPerMillionInputTokens();

        double getCostPerMillionOutputTokens();

        boolean isConfigured();

        /**
         * Temperature d'echantillonnage. 0 = deterministe — recommande pour une
         * EVALUATION (memes scores d'un run a l'autre sur le meme texte). Au-dela
         * de 0, la notation varie a chaque appel.
         */
        default double getTemperature() { return 0.0; }

        /**
         * true → ajoute {@code "thinking":{"type":"disabled"}} a la requete.
         * Necessaire pour DeepSeek V4 (thinking mode actif par defaut refuse le
         * {@code tool_choice} force → 400). Faux pour OpenAI (champ inconnu, 400).
         */
        default boolean isDisableThinking() {
            return false;
        }
    }

    public static class Anthropic {
        // Valeurs fournies par application.yaml
        // (sejourfr.production-evaluation.anthropic.*) — pas de defaut metier en dur.
        private String apiKey = "";
        private String apiUrl;
        private String anthropicVersion;
        private String model;
        private int maxTokens;
        private int timeoutSec;
        private int maxRetries;
        private long retryBackoffMs;
        private String promptVersion;
        private double costPerMillionInputTokens;
        private double costPerMillionOutputTokens;

        public boolean isConfigured() {
            return apiKey != null && !apiKey.isBlank();
        }

        public String getApiKey() {
            return apiKey;
        }

        public void setApiKey(String apiKey) {
            this.apiKey = apiKey;
        }

        public String getApiUrl() {
            return apiUrl;
        }

        public void setApiUrl(String apiUrl) {
            this.apiUrl = apiUrl;
        }

        public String getAnthropicVersion() {
            return anthropicVersion;
        }

        public void setAnthropicVersion(String anthropicVersion) {
            this.anthropicVersion = anthropicVersion;
        }

        public String getModel() {
            return model;
        }

        public void setModel(String model) {
            this.model = model;
        }

        public int getMaxTokens() {
            return maxTokens;
        }

        public void setMaxTokens(int maxTokens) {
            this.maxTokens = maxTokens;
        }

        public int getTimeoutSec() {
            return timeoutSec;
        }

        public void setTimeoutSec(int timeoutSec) {
            this.timeoutSec = timeoutSec;
        }

        public int getMaxRetries() {
            return maxRetries;
        }

        public void setMaxRetries(int maxRetries) {
            this.maxRetries = maxRetries;
        }

        public long getRetryBackoffMs() {
            return retryBackoffMs;
        }

        public void setRetryBackoffMs(long retryBackoffMs) {
            this.retryBackoffMs = retryBackoffMs;
        }

        public String getPromptVersion() {
            return promptVersion;
        }

        public void setPromptVersion(String promptVersion) {
            this.promptVersion = promptVersion;
        }

        public double getCostPerMillionInputTokens() {
            return costPerMillionInputTokens;
        }

        public void setCostPerMillionInputTokens(double v) {
            this.costPerMillionInputTokens = v;
        }

        public double getCostPerMillionOutputTokens() {
            return costPerMillionOutputTokens;
        }

        public void setCostPerMillionOutputTokens(double v) {
            this.costPerMillionOutputTokens = v;
        }
    }

    /**
     * Config du provider OpenAI (Chat Completions + function calling). On reuse
     * le meme JSON schema d'outil que le pipeline Anthropic ; seule l'enveloppe
     * de la requete change. La cle peut etre la meme que celle utilisee pour
     * Whisper (sejourfr.openai.api-key) ou une cle dediee.
     */
    public static class OpenAi implements ChatCompletionSettings {
        // Valeurs fournies par application.yaml
        // (sejourfr.production-evaluation.openai.*) — pas de defaut metier en dur.
        private String apiKey = "";
        private String apiUrl;
        private String model;
        private int maxTokens;
        private int timeoutSec;
        private int maxRetries;
        private long retryBackoffMs;
        private String promptVersion;
        private double temperature;
        private double costPerMillionInputTokens;
        private double costPerMillionOutputTokens;

        public boolean isConfigured() {
            return apiKey != null && !apiKey.isBlank();
        }

        @Override
        public double getTemperature() {
            return temperature;
        }

        public void setTemperature(double temperature) {
            this.temperature = temperature;
        }

        public String getApiKey() {
            return apiKey;
        }

        public void setApiKey(String apiKey) {
            this.apiKey = apiKey;
        }

        public String getApiUrl() {
            return apiUrl;
        }

        public void setApiUrl(String apiUrl) {
            this.apiUrl = apiUrl;
        }

        public String getModel() {
            return model;
        }

        public void setModel(String model) {
            this.model = model;
        }

        public int getMaxTokens() {
            return maxTokens;
        }

        public void setMaxTokens(int maxTokens) {
            this.maxTokens = maxTokens;
        }

        public int getTimeoutSec() {
            return timeoutSec;
        }

        public void setTimeoutSec(int timeoutSec) {
            this.timeoutSec = timeoutSec;
        }

        public int getMaxRetries() {
            return maxRetries;
        }

        public void setMaxRetries(int maxRetries) {
            this.maxRetries = maxRetries;
        }

        public long getRetryBackoffMs() {
            return retryBackoffMs;
        }

        public void setRetryBackoffMs(long retryBackoffMs) {
            this.retryBackoffMs = retryBackoffMs;
        }

        public String getPromptVersion() {
            return promptVersion;
        }

        public void setPromptVersion(String promptVersion) {
            this.promptVersion = promptVersion;
        }

        public double getCostPerMillionInputTokens() {
            return costPerMillionInputTokens;
        }

        public void setCostPerMillionInputTokens(double v) {
            this.costPerMillionInputTokens = v;
        }

        public double getCostPerMillionOutputTokens() {
            return costPerMillionOutputTokens;
        }

        public void setCostPerMillionOutputTokens(double v) {
            this.costPerMillionOutputTokens = v;
        }
    }

    /**
     * Config du provider DeepSeek. L'API DeepSeek est compatible OpenAI (meme
     * endpoint {@code /chat/completions}, meme format {@code tools}/{@code tool_calls},
     * auth Bearer), donc le meme {@code OpenAiCompatibleEvalClient} la sert sans
     * code dedie. Renseigner {@code …deepseek.api-key} (DEEPSEEK_API_KEY). Le
     * modele par defaut est {@code deepseek-v4-flash} (function calling supporte) ;
     * surchargeable via {@code …deepseek.model}.
     */
    public static class DeepSeek implements ChatCompletionSettings {
        // Toutes les valeurs viennent de application.yaml
        // (sejourfr.production-evaluation.deepseek.*) — pas de defaut metier en dur
        // ici, le yaml est la source unique (api-url, model, disable-thinking, tarifs…).
        private String apiKey = "";
        private String apiUrl;
        private String model;
        private int maxTokens;
        private int timeoutSec;
        private String promptVersion;
        private boolean disableThinking;
        private double temperature;
        private double costPerMillionInputTokens;
        private double costPerMillionOutputTokens;

        public boolean isConfigured() {
            return apiKey != null && !apiKey.isBlank();
        }

        @Override
        public double getTemperature() {
            return temperature;
        }

        public void setTemperature(double temperature) {
            this.temperature = temperature;
        }

        @Override
        public boolean isDisableThinking() {
            return disableThinking;
        }

        public void setDisableThinking(boolean disableThinking) {
            this.disableThinking = disableThinking;
        }

        public String getApiKey() {
            return apiKey;
        }

        public void setApiKey(String apiKey) {
            this.apiKey = apiKey;
        }

        public String getApiUrl() {
            return apiUrl;
        }

        public void setApiUrl(String apiUrl) {
            this.apiUrl = apiUrl;
        }

        public String getModel() {
            return model;
        }

        public void setModel(String model) {
            this.model = model;
        }

        public int getMaxTokens() {
            return maxTokens;
        }

        public void setMaxTokens(int maxTokens) {
            this.maxTokens = maxTokens;
        }

        public int getTimeoutSec() {
            return timeoutSec;
        }

        public void setTimeoutSec(int timeoutSec) {
            this.timeoutSec = timeoutSec;
        }

        public String getPromptVersion() {
            return promptVersion;
        }

        public void setPromptVersion(String promptVersion) {
            this.promptVersion = promptVersion;
        }

        public double getCostPerMillionInputTokens() {
            return costPerMillionInputTokens;
        }

        public void setCostPerMillionInputTokens(double v) {
            this.costPerMillionInputTokens = v;
        }

        public double getCostPerMillionOutputTokens() {
            return costPerMillionOutputTokens;
        }

        public void setCostPerMillionOutputTokens(double v) {
            this.costPerMillionOutputTokens = v;
        }
    }

    /**
     * Seuils du niveau CECRL CALCULE serveur (cf. {@code AiEvaluationService}).
     * Le niveau affiche n'est plus celui du LLM : il est derive des criteres
     * porteurs du niveau ({@code source-criteres}, par defaut lexique +
     * morphosyntaxe), via {@code competence = moyenne(source)} comparee aux
     * seuils. Plafond B2 (cible naturalisation ; C1/C2 non fiables sur T1).
     * Ajustables sans redeploiement (recalibration apres analyse du dashboard).
     */
    public static class NiveauCecrl {
        /** Codes de criteres porteurs du niveau (moyennes pour {@code competence}). */
        private java.util.List<String> sourceCriteres = java.util.List.of("lexique", "morphosyntaxe");
        /** competence >= seuilB2 -> B2. */
        private double seuilB2 = 15.0;
        /** competence >= seuilB1 -> B1. */
        private double seuilB1 = 12.0;
        /** competence >= seuilA2 -> A2 ; < seuilA2 (mais > 0) -> A1 ; hors-sujet -> A1_NON_ATTEINT. */
        private double seuilA2 = 7.0;

        public java.util.List<String> getSourceCriteres() {
            return sourceCriteres;
        }

        public void setSourceCriteres(java.util.List<String> sourceCriteres) {
            this.sourceCriteres = sourceCriteres;
        }

        public double getSeuilB2() {
            return seuilB2;
        }

        public void setSeuilB2(double seuilB2) {
            this.seuilB2 = seuilB2;
        }

        public double getSeuilB1() {
            return seuilB1;
        }

        public void setSeuilB1(double seuilB1) {
            this.seuilB1 = seuilB1;
        }

        public double getSeuilA2() {
            return seuilA2;
        }

        public void setSeuilA2(double seuilA2) {
            this.seuilA2 = seuilA2;
        }
    }
}
