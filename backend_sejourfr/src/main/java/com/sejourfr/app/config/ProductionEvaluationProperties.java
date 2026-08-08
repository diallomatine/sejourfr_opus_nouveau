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
     * compatible OpenAI via le bloc deepseek/openai). Une bascule de configuration
     * demande seulement un redemarrage du backend, sans migration ni changement mobile.
     */
    private String provider = "deepseek";

    /**
     * Version du fichier de rubriques par tache charge par
     * {@code ProductionRubricsProvider} : {@code prompts/production-rubrics-<v>.json}.
     * Source unique du "comment noter" propre a chaque tache (criteres, bareme,
     * descripteurs, consignes). Versionne separement du tool-schema, avec une
     * matrice de compatibilite verifiee au demarrage avant toute evaluation.
     */
    private String rubricsVersion = "v1";

    private Anthropic anthropic = new Anthropic();
    private OpenAi openai = new OpenAi();
    private DeepSeek deepseek = new DeepSeek();
    private NiveauCecrl niveauCecrl = new NiveauCecrl();
    private Validite validite = new Validite();
    private Plafonds plafonds = new Plafonds();
    private Couplage couplage = new Couplage();
    private BandesCriteres bandesCriteres = new BandesCriteres();
    private Fluidite fluidite = new Fluidite();
    private SecondePasse secondePasse = new SecondePasse();
    private CoherenceBilan coherenceBilan = new CoherenceBilan();
    private RecollageTours recollageTours = new RecollageTours();
    private VersionCiblee versionCiblee = new VersionCiblee();
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

    public Validite getValidite() {
        return validite;
    }

    public void setValidite(Validite validite) {
        this.validite = validite;
    }

    public Plafonds getPlafonds() {
        return plafonds;
    }

    public void setPlafonds(Plafonds plafonds) {
        this.plafonds = plafonds;
    }

    public BandesCriteres getBandesCriteres() {
        return bandesCriteres;
    }

    public void setBandesCriteres(BandesCriteres bandesCriteres) {
        this.bandesCriteres = bandesCriteres;
    }

    public Couplage getCouplage() {
        return couplage;
    }

    public void setCouplage(Couplage couplage) {
        this.couplage = couplage;
    }

    public Fluidite getFluidite() {
        return fluidite;
    }

    public void setFluidite(Fluidite fluidite) {
        this.fluidite = fluidite;
    }

    public SecondePasse getSecondePasse() {
        return secondePasse;
    }

    public void setSecondePasse(SecondePasse secondePasse) {
        this.secondePasse = secondePasse;
    }

    public CoherenceBilan getCoherenceBilan() {
        return coherenceBilan;
    }

    public void setCoherenceBilan(CoherenceBilan coherenceBilan) {
        this.coherenceBilan = coherenceBilan;
    }

    public RecollageTours getRecollageTours() {
        return recollageTours;
    }

    public void setRecollageTours(RecollageTours recollageTours) {
        this.recollageTours = recollageTours;
    }

    public VersionCiblee getVersionCiblee() {
        return versionCiblee;
    }

    public void setVersionCiblee(VersionCiblee versionCiblee) {
        this.versionCiblee = versionCiblee;
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
         * Faut-il envoyer le champ {@code temperature} : {@code auto} (defaut,
         * detection par modele), {@code true} ou {@code false}. Les modeles a
         * temperature figee (mesure : gpt-5.5 — « Only the default (1) value is
         * supported ») exigent qu'on OMETTE le champ ; envoyer 1 reviendrait a
         * choisir une notation non deterministe sans le dire.
         */
        default String getSendTemperature() {
            return com.sejourfr.app.util.ChatCompletionDialect.AUTO;
        }

        /**
         * Nom du champ de plafond de sortie : {@code auto} (defaut, detection par
         * modele — cf. {@link com.sejourfr.app.util.ChatCompletionDialect}),
         * {@code max_tokens} ou {@code max_completion_tokens}. Le PLAFOND lui-meme
         * ({@link #getMaxTokens()}) est identique quel que soit le nom du champ.
         */
        default String getMaxTokensParam() {
            return com.sejourfr.app.util.ChatCompletionDialect.AUTO;
        }

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
        private String sendTemperature = com.sejourfr.app.util.ChatCompletionDialect.AUTO;
        private String maxTokensParam = com.sejourfr.app.util.ChatCompletionDialect.AUTO;
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
        public String getSendTemperature() {
            return sendTemperature;
        }

        public void setSendTemperature(String sendTemperature) {
            this.sendTemperature = sendTemperature;
        }

        @Override
        public String getMaxTokensParam() {
            return maxTokensParam;
        }

        public void setMaxTokensParam(String maxTokensParam) {
            this.maxTokensParam = maxTokensParam;
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
     * modele est celui d'{@code application.yaml}, lui-meme surchargeable par
     * {@code EVAL_DEEPSEEK_MODEL} : aucun nom de modele n'est ecrit ici.
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
        private String sendTemperature = com.sejourfr.app.util.ChatCompletionDialect.AUTO;
        private String maxTokensParam = com.sejourfr.app.util.ChatCompletionDialect.AUTO;
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

        /**
         * Meme echappatoire que le bloc OpenAI : la forme de requete est
         * NEGOCIEE par defaut ({@code auto}), et ces deux cles ne servent qu'a
         * reprendre la main SANS code si la negociation ne suffisait pas. Les
         * garder ici evite qu'une bascule de provider fasse perdre ce filet.
         */
        @Override
        public String getSendTemperature() {
            return sendTemperature;
        }

        public void setSendTemperature(String sendTemperature) {
            this.sendTemperature = sendTemperature;
        }

        @Override
        public String getMaxTokensParam() {
            return maxTokensParam;
        }

        public void setMaxTokensParam(String maxTokensParam) {
            this.maxTokensParam = maxTokensParam;
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
     * morphosyntaxe + coherence), via {@code competence = moyenne(source)}
     * comparee aux seuils. La pertinence reste EXCLUE (completion de tache, pas
     * un marqueur de niveau de langue). Plafond B2 (cible naturalisation ;
     * C1/C2 non fiables sur T1). Ajustables sans redeploiement (recalibration
     * apres analyse du dashboard).
     */
    public static class NiveauCecrl {
        /**
         * Codes de criteres porteurs du niveau (moyennes pour {@code competence}).
         *
         * <p>Valeurs par DEFAUT, utilisees par les grilles qui ne declarent pas
         * les leurs (v3, v4, v4.1, v4.2). Depuis v5, le fichier de rubriques
         * porte son propre bloc {@code commun.niveau} et c'est lui qui gagne :
         * cf. {@code ProductionRubricsProvider#niveauCecrl()}. Ne pas modifier
         * ces valeurs pour calibrer v5 — elles sont l'etat de v4.2.
         */
        private java.util.List<String> sourceCriteres = java.util.List.of("lexique", "morphosyntaxe", "coherence");
        /** competence >= seuilB2 -> B2. */
        private double seuilB2 = 15.0;
        /** competence >= seuilB1 -> B1. */
        private double seuilB1 = 12.0;
        /** competence >= seuilA2 -> A2 ; < seuilA2 (mais > 0) -> A1 ; hors-sujet -> A1_NON_ATTEINT. */
        private double seuilA2 = 7.0;
        /**
         * Poids des taches dans le bilan d'epreuve en examen (index = tacheNumero - 1).
         *
         * <p><b>Egaux depuis v5</b>. Le TCF publie UNE note /20 par epreuve et
         * aucune ponderation par tache ; la difficulte croissante des 3 taches
         * est deja portee par leurs DESCRIPTEURS (T3 vise B2), la ponderer une
         * seconde fois la compterait deux fois. Surtout, la moyenne simple rend
         * le bilan coherent : la note d'epreuve affichee EST la moyenne des 3
         * notes de tache, et le niveau d'epreuve se lit sur cette meme note.
         * Reglable sans redeploiement pour revenir a 1/2/3 si la mesure le
         * justifiait. Cf. {@code ProductionBilanService}.
         */
        private java.util.List<Double> poidsTaches = java.util.List.of(1.0, 1.0, 1.0);

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

        public java.util.List<Double> getPoidsTaches() {
            return poidsTaches;
        }

        public void setPoidsTaches(java.util.List<Double> poidsTaches) {
            this.poidsTaches = poidsTaches;
        }
    }

    /**
     * Seuils des controles DETERMINISTES pre-LLM (cf. {@code ProductionValidityService}).
     * Ajustables sans redeploiement : ce sont des heuristiques, elles se recalibrent.
     */
    public static class Validite {
        /** Sous ce nombre de mots exploitables, la production est INVALIDE (vide/quasi vide). */
        private int minMotsExploitables = 5;
        /**
         * Nombre de mots a partir duquel le ratio de mots-outils devient
         * statistiquement lisible. En dessous, on ne juge pas la langue.
         */
        private int motsMinAnalyseLangue = 12;
        /** Ratio de mots-outils francais sous lequel la production est INVALIDE (pas en francais). */
        private double ratioMotsOutilsInvalide = 0.10;
        /** Ratio de mots-outils francais sous lequel on emet un AVERTISSEMENT. */
        private double ratioMotsOutilsAvertissement = 0.18;
        /** Part de lettres d'un alphabet non latin au-dela de laquelle la production est INVALIDE. */
        private double ratioAlphabetNonLatinInvalide = 0.30;
        /** Taille des n-grammes (en mots normalises) du controle de recopiage de la consigne. */
        private int ngramConsigne = 5;
        /** Recouvrement production/consigne au-dela duquel on emet un AVERTISSEMENT. */
        private double ratioRecopiageAvertissement = 0.30;
        /** Recouvrement production/consigne au-dela duquel la production est INVALIDE. */
        private double ratioRecopiageInvalide = 0.60;

        public int getMinMotsExploitables() {
            return minMotsExploitables;
        }

        public void setMinMotsExploitables(int minMotsExploitables) {
            this.minMotsExploitables = minMotsExploitables;
        }

        public int getMotsMinAnalyseLangue() {
            return motsMinAnalyseLangue;
        }

        public void setMotsMinAnalyseLangue(int motsMinAnalyseLangue) {
            this.motsMinAnalyseLangue = motsMinAnalyseLangue;
        }

        public double getRatioMotsOutilsInvalide() {
            return ratioMotsOutilsInvalide;
        }

        public void setRatioMotsOutilsInvalide(double ratioMotsOutilsInvalide) {
            this.ratioMotsOutilsInvalide = ratioMotsOutilsInvalide;
        }

        public double getRatioMotsOutilsAvertissement() {
            return ratioMotsOutilsAvertissement;
        }

        public void setRatioMotsOutilsAvertissement(double ratioMotsOutilsAvertissement) {
            this.ratioMotsOutilsAvertissement = ratioMotsOutilsAvertissement;
        }

        public double getRatioAlphabetNonLatinInvalide() {
            return ratioAlphabetNonLatinInvalide;
        }

        public void setRatioAlphabetNonLatinInvalide(double ratioAlphabetNonLatinInvalide) {
            this.ratioAlphabetNonLatinInvalide = ratioAlphabetNonLatinInvalide;
        }

        public int getNgramConsigne() {
            return ngramConsigne;
        }

        public void setNgramConsigne(int ngramConsigne) {
            this.ngramConsigne = ngramConsigne;
        }

        public double getRatioRecopiageAvertissement() {
            return ratioRecopiageAvertissement;
        }

        public void setRatioRecopiageAvertissement(double ratioRecopiageAvertissement) {
            this.ratioRecopiageAvertissement = ratioRecopiageAvertissement;
        }

        public double getRatioRecopiageInvalide() {
            return ratioRecopiageInvalide;
        }

        public void setRatioRecopiageInvalide(double ratioRecopiageInvalide) {
            this.ratioRecopiageInvalide = ratioRecopiageInvalide;
        }
    }

    /**
     * Plafonds de niveau CECRL appliques cote serveur APRES le calcul du niveau
     * par soumission. Volontairement peu nombreux : uniquement des regles
     * objectivables a partir des criteres v4. Le hors-sujet (note 0 →
     * {@code A1_NON_ATTEINT}) est gere en amont et n'est pas un plafond.
     */
    public static class Plafonds {
        /** Coupe-circuit global (banc de mesure : comparer avec / sans plafonds). */
        private boolean enabled = true;
        /**
         * T3 (EE ou EO) : {@code prise_position} <= seuil → aucune opinion identifiable.
         *
         * <p>Valeur par DEFAUT, calee sur le HAUT DE LA BANDE A1 des criteres des
         * grilles v3-v5 (1-5). Une grille dont l'echelle differe declare la
         * sienne dans {@code commun.plafonds} du fichier de rubriques (v6 : 1,
         * haut de la bande A1 sur l'echelle du TCF) — cf.
         * {@code ProductionRubricsProvider#plafonds()}.
         */
        private double prisePositionSeuil = 5.0;
        private com.sejourfr.app.enums.NiveauCecrl prisePositionNiveauMax =
            com.sejourfr.app.enums.NiveauCecrl.A2;
        /** EO T2 : {@code conduite_echange} <= seuil → aucun veritable echange. */
        private double conduiteEchangeSeuil = 5.0;
        private com.sejourfr.app.enums.NiveauCecrl conduiteEchangeNiveauMax =
            com.sejourfr.app.enums.NiveauCecrl.A2;

        public boolean isEnabled() {
            return enabled;
        }

        public void setEnabled(boolean enabled) {
            this.enabled = enabled;
        }

        public double getPrisePositionSeuil() {
            return prisePositionSeuil;
        }

        public void setPrisePositionSeuil(double prisePositionSeuil) {
            this.prisePositionSeuil = prisePositionSeuil;
        }

        public com.sejourfr.app.enums.NiveauCecrl getPrisePositionNiveauMax() {
            return prisePositionNiveauMax;
        }

        public void setPrisePositionNiveauMax(com.sejourfr.app.enums.NiveauCecrl prisePositionNiveauMax) {
            this.prisePositionNiveauMax = prisePositionNiveauMax;
        }

        public double getConduiteEchangeSeuil() {
            return conduiteEchangeSeuil;
        }

        public void setConduiteEchangeSeuil(double conduiteEchangeSeuil) {
            this.conduiteEchangeSeuil = conduiteEchangeSeuil;
        }

        public com.sejourfr.app.enums.NiveauCecrl getConduiteEchangeNiveauMax() {
            return conduiteEchangeNiveauMax;
        }

        public void setConduiteEchangeNiveauMax(com.sejourfr.app.enums.NiveauCecrl conduiteEchangeNiveauMax) {
            this.conduiteEchangeNiveauMax = conduiteEchangeNiveauMax;
        }
    }

    /**
     * GARDE-FOU DE COUPLAGE, filet deterministe (v5). Une tache est toujours
     * accomplie AVEC des moyens linguistiques : les criteres de REALISATION
     * ({@code communiquer}, {@code interagir}) ne peuvent pas depasser de plus de
     * {@code ecartMax} points la moyenne des criteres de LANGUE ({@code lexique},
     * {@code morphosyntaxe}).
     *
     * <p>La regle est d'abord ecrite dans le prompt (bloc commun des rubriques
     * v5) ; ce filet la GARANTIT, sur le meme modele que
     * {@code capPointsAAmeliorer} — le prompt la demande, il ne la tient pas
     * toujours. Il est capital depuis v5 : les criteres de realisation pesent la
     * moitie de la note, donc du niveau ; sans lui, cocher tous les points d'une
     * consigne A2 dans un francais pauvre suffirait a monter d'un palier.
     *
     * <p>Sans effet sur les grilles anterieures : leurs criteres de tache ne
     * portent pas ces codes, {@code criteresRealisation} ne matche donc rien.
     */
    /**
     * Bornes des BANDES QUALITATIVES par critere (cf. {@code BandeCritere}), que
     * les 3 fronts affichent A LA PLACE du nombre : une IA ne distingue pas
     * honnetement un 13 d'un 14.
     *
     * <p>Ces bornes sont une propriete de l'ECHELLE DE LA GRILLE, pas du
     * deploiement. Les valeurs par defaut sont celles des grilles v3 a v5
     * (16-20 / 11-15 / 6-10 / 1-5 / 0) ; depuis v6, dont l'echelle est celle du
     * TCF, le fichier de rubriques declare les siennes dans
     * {@code commun.bandes_criteres} et c'est lui qui gagne — cf.
     * {@code ProductionRubricsProvider#bandesCriteres()}. Sans ce mecanisme, un
     * critere v6 a 8 (bon B1) s'afficherait « en cours d'acquisition » et un
     * critere a 12 (B2 confirme) « satisfaisant ».
     */
    public static class BandesCriteres {
        /** note >= seuil -> TRES_BONNE_MAITRISE. */
        private double tresBonneMaitrise = 16.0;
        /** note >= seuil -> SATISFAISANT. */
        private double satisfaisant = 11.0;
        /** note >= seuil -> EN_COURS_ACQUISITION ; au-dessus de 0 -> FRAGILE ; 0 -> NON_EVALUABLE. */
        private double enCoursAcquisition = 6.0;

        public double getTresBonneMaitrise() {
            return tresBonneMaitrise;
        }

        public void setTresBonneMaitrise(double tresBonneMaitrise) {
            this.tresBonneMaitrise = tresBonneMaitrise;
        }

        public double getSatisfaisant() {
            return satisfaisant;
        }

        public void setSatisfaisant(double satisfaisant) {
            this.satisfaisant = satisfaisant;
        }

        public double getEnCoursAcquisition() {
            return enCoursAcquisition;
        }

        public void setEnCoursAcquisition(double enCoursAcquisition) {
            this.enCoursAcquisition = enCoursAcquisition;
        }
    }

    public static class Couplage {
        /** Coupe-circuit (banc de mesure : comparer avec / sans). */
        private boolean enabled = true;
        /** Codes plafonnes (criteres de realisation de la grille TCF). */
        private java.util.List<String> criteresRealisation = java.util.List.of("communiquer", "interagir");
        /** Codes qui forment le socle de langue dont on prend la moyenne. */
        private java.util.List<String> criteresLangue = java.util.List.of("lexique", "morphosyntaxe");
        /**
         * Ecart maximal tolere au-dessus de la moyenne du socle de langue.
         *
         * <p>Valeur par DEFAUT (celle de v5, dont l'echelle etale le B2 sur
         * 16-20). Depuis v6, dont l'echelle est celle du TCF (B2 des 10), le
         * fichier de rubriques declare la sienne dans
         * {@code commun.couplage.ecart_max} et c'est elle qui gagne — cf.
         * {@code ProductionRubricsProvider#couplage()}. L'ecart n'a pas le meme
         * sens d'une echelle a l'autre : ce qu'il faut conserver, c'est le gain
         * maximal qu'il concede a la moyenne des quatre criteres
         * ({@code ecartMax / 2}), qui doit rester inferieur a la largeur d'un
         * palier.
         */
        private double ecartMax = 4.0;

        public boolean isEnabled() {
            return enabled;
        }

        public void setEnabled(boolean enabled) {
            this.enabled = enabled;
        }

        public java.util.List<String> getCriteresRealisation() {
            return criteresRealisation;
        }

        public void setCriteresRealisation(java.util.List<String> criteresRealisation) {
            this.criteresRealisation = criteresRealisation;
        }

        public java.util.List<String> getCriteresLangue() {
            return criteresLangue;
        }

        public void setCriteresLangue(java.util.List<String> criteresLangue) {
            this.criteresLangue = criteresLangue;
        }

        public double getEcartMax() {
            return ecartMax;
        }

        public void setEcartMax(double ecartMax) {
            this.ecartMax = ecartMax;
        }
    }

    /**
     * Indice de FLUIDITE des productions orales : debit (mots/minute) et, si la
     * transcription porte des horodatages exploitables, nombre de pauses
     * longues. <b>Donnees factuelles</b> exposees dans le feedback, jamais une
     * note : rien dans le calcul de la note ni du niveau ne lit ce bloc.
     *
     * <p>Choisi parce qu'il est <b>neutre vis-a-vis de l'accent</b>, a l'inverse
     * d'une analyse de prononciation. Livre <b>desactive</b>
     * ({@code enabled=false}) : c'est un changement de comportement produit
     * (aujourd'hui une regle explicite interdit a l'IA de juger le debit ou la
     * duree), il s'allume apres mesure.
     */
    public static class Fluidite {
        /** Coupe-circuit. false → aucun bloc {@code fluidite} dans le feedback. */
        private boolean enabled = false;
        /** Sous cette duree parlee, le debit n'est pas statistiquement lisible. */
        private int dureeMinSec = 20;
        /** Silence a partir duquel on compte une "pause longue" (secondes). */
        private double pauseLongueSeuilSec = 3.0;

        public boolean isEnabled() {
            return enabled;
        }

        public void setEnabled(boolean enabled) {
            this.enabled = enabled;
        }

        public int getDureeMinSec() {
            return dureeMinSec;
        }

        public void setDureeMinSec(int dureeMinSec) {
            this.dureeMinSec = dureeMinSec;
        }

        public double getPauseLongueSeuilSec() {
            return pauseLongueSeuilSec;
        }

        public void setPauseLongueSeuilSec(double pauseLongueSeuilSec) {
            this.pauseLongueSeuilSec = pauseLongueSeuilSec;
        }
    }

    /**
     * Seconde passe d'evaluation, declenchee <b>uniquement en zone floue</b>
     * (confiance faible, competence a la frontiere d'un seuil, ou divergence
     * LLM/serveur de plus d'un palier). Livre <b>desactive</b> : c'est un cout
     * LLM double sur une partie du trafic.
     *
     * <p>La seconde passe reutilise le provider et le modele principaux. Le
     * correcteur n'a ainsi qu'une seule source de configuration, y compris
     * pour le banc de calibration et les fins de session temps reel.
     */
    public static class SecondePasse {
        /** Coupe-circuit. false → une seule passe, comportement historique. */
        private boolean enabled = false;
        /**
         * Marge (en points /20) autour d'un seuil de niveau sous laquelle la
         * competence est jugee "a la frontiere" → zone floue.
         */
        private double margeSeuilNiveau = 1.0;

        public boolean isEnabled() {
            return enabled;
        }

        public void setEnabled(boolean enabled) {
            this.enabled = enabled;
        }

        public double getMargeSeuilNiveau() {
            return margeSeuilNiveau;
        }

        public void setMargeSeuilNiveau(double margeSeuilNiveau) {
            this.margeSeuilNiveau = margeSeuilNiveau;
        }
    }

    /**
     * RECOLLAGE DES TOURS CONSECUTIFS d'un meme locuteur dans un transcript
     * dialogue (expression orale TEMPS REEL). Livre <b>ACTIF</b> : c'est une
     * CORRECTION, pas une experimentation — a l'inverse de {@code fluidite},
     * {@code seconde-passe} et {@code coherence-bilan}, livres eteints.
     *
     * <p><b>Le probleme</b> : la transcription temps reel cloture un tour sur le
     * signal de fin de tour du MODELE, qui n'est pas la fin de la phrase du
     * CANDIDAT. Un meme enonce ressort donc scinde en plusieurs tours
     * consecutifs, a une frontiere arbitraire (« Candidat : … pousse a l'air.
     * Ah. » / « Candidat : aller vers l'informatique. »). Consequences : une
     * citation a cheval sur deux tours n'est jamais retrouvable par
     * {@code EvaluationProofMatcher} (un segment par tour), le correcteur juge
     * la morphosyntaxe sur un texte hache et baisse sa confiance pour une
     * raison qui vient de NOUS, et le candidat relit sa phrase coupee en deux.
     *
     * <p><b>Non destructif</b> : le recollage s'applique A LA LECTURE. Ni
     * {@code realtime_sessions.transcript} ni {@code transcriptions.texte} ne
     * sont reecrits ; a {@code false}, la sortie est rigoureusement celle
     * d'avant, sans redeploiement des fronts.
     *
     * <p>Regle et point d'application uniques :
     * {@code util/TranscriptTurnStitcher} + {@code TranscriptionManager}.
     */
    public static class RecollageTours {
        /** Coupe-circuit. false → transcript brut, comportement historique. */
        private boolean enabled = true;

        public boolean isEnabled() {
            return enabled;
        }

        public void setEnabled(boolean enabled) {
            this.enabled = enabled;
        }
    }

    /**
     * Regles de coherence appliquees au bilan d'une epreuve de 3 taches, APRES
     * la moyenne ponderee (cf. {@code ProductionBilanService}). Elles ne font
     * qu'ABAISSER un niveau, jamais le relever — c'est ce qui les rend sures.
     *
     * <p><b>ACTIF par defaut</b> depuis l'alignement TCF IRN : les 3 taches ne
     * sont pas interchangeables, la tache 3 est la seule qui demande
     * d'argumenter, donc la seule qui puisse demontrer un B2. Briller sur un
     * message simple et s'effondrer en argumentation ne prouve pas un B1.
     * {@code enabled=false} rend exactement les bilans d'avant (moyenne
     * ponderee seule) : c'est le retour arriere, en une variable
     * ({@code EVAL_COHERENCE_BILAN_ENABLED=false}).
     *
     * <p>Le couple ({@code tache3NiveauMin}, {@code plafondSiTache3Faible}) est
     * une regle UNIQUE : aujourd'hui « pas de B2 si la tache 3 est sous B1 ».
     * Une generalisation palier par palier (pas de B1 si la tache 3 est sous
     * A2, etc.) se ferait en remplacant ce couple par une LISTE de couples et
     * en retenant le plafond le plus bas — le calcul lui-meme
     * ({@code appliquerCoherence}) n'aurait pas a changer. Non implemente tant
     * que l'elargissement n'est pas decide.
     */
    public static class CoherenceBilan {
        /** Coupe-circuit. false → moyenne ponderee seule, math historique. */
        private boolean enabled = true;
        /**
         * Niveau plancher attendu sur la tache 3 (argumentation / prise de
         * position) pour qu'un bilan puisse depasser {@code plafondSiTache3Faible}.
         */
        private com.sejourfr.app.enums.NiveauCecrl tache3NiveauMin =
            com.sejourfr.app.enums.NiveauCecrl.B1;
        /**
         * Plafond du bilan quand la tache 3 est sous {@code tache3NiveauMin} :
         * pas de B2 global pour quelqu'un qui s'effondre sur l'argumentation.
         */
        private com.sejourfr.app.enums.NiveauCecrl plafondSiTache3Faible =
            com.sejourfr.app.enums.NiveauCecrl.B1;

        public boolean isEnabled() {
            return enabled;
        }

        public void setEnabled(boolean enabled) {
            this.enabled = enabled;
        }

        public com.sejourfr.app.enums.NiveauCecrl getTache3NiveauMin() {
            return tache3NiveauMin;
        }

        public void setTache3NiveauMin(com.sejourfr.app.enums.NiveauCecrl tache3NiveauMin) {
            this.tache3NiveauMin = tache3NiveauMin;
        }

        public com.sejourfr.app.enums.NiveauCecrl getPlafondSiTache3Faible() {
            return plafondSiTache3Faible;
        }

        public void setPlafondSiTache3Faible(com.sejourfr.app.enums.NiveauCecrl plafondSiTache3Faible) {
            this.plafondSiTache3Faible = plafondSiTache3Faible;
        }
    }

    /**
     * « Version au niveau visé » : la réponse du candidat réécrite au palier
     * qu'il VISE (son {@code TargetLevel}), plus deux à trois leviers concrets
     * pour l'atteindre. <b>EE uniquement</b>, en miroir de la règle
     * {@code version_amelioree} (obligatoire à l'écrit, retirée à l'oral).
     *
     * <p><b>SECOND APPEL LLM, totalement séparé de la correction — c'est la
     * raison même de la fonctionnalité, pas un détail d'implémentation.</b> Le
     * prompt de notation ne change pas d'un octet : le correcteur ne doit jamais
     * savoir quel niveau vise le candidat, sinon il aligne sa note dessus. Le
     * dépôt a déjà mesuré qu'ajouter un bloc à la grille dégrade la notation
     * (rubriques v10/v11 : accord exact 81,8 % → 75,6 %). Ne pas fusionner les
     * deux appels, même si ça paraît plus économique.
     *
     * <p><b>Best-effort, jamais bloquant</b> : un échec de ce second appel
     * (timeout, sortie invalide, clé absente) laisse l'évaluation
     * {@code EVALUATED} et valide, le bloc est simplement absent du feedback.
     *
     * <p>Le FOURNISSEUR reste {@code sejourfr.production-evaluation.provider} —
     * règle « un seul correcteur configurable ». Ce bloc ne porte que le contrat
     * de sortie, le budget de tokens et le coupe-circuit.
     */
    public static class VersionCiblee {
        /**
         * Livré ACTIF. {@code false} = plus aucun second appel, plus aucun bloc
         * {@code version_ciblee} : le comportement d'avant, à l'identique.
         */
        private boolean enabled = true;
        /** Consignes : {@code prompts/production-version-ciblee-rubrics-<v>.json}. */
        private String rubricsVersion = "v1";
        /** Contrat de sortie : {@code prompts/production-version-ciblee-tool-schema-<v>.json}. */
        private String toolSchemaVersion = "v1";
        /**
         * Plafond de tokens de SORTIE, PROPRE à cet appel (pas les 4000 d'une
         * correction complète) : la sortie tient en un texte court plus deux ou
         * trois phrases. C'est un plafond, pas une consommation — mais le
         * relever ouvrirait la porte à des versions bavardes que le contrat
         * n'attend pas.
         */
        private int maxTokens = 1200;
        /** Zéro : deux lectures du même texte doivent donner la même version. */
        private double temperature = 0;
        /** Plafond serveur du nombre de leviers rendus (le schéma en demande 2 à 3). */
        private int maxLeviers = 3;

        public boolean isEnabled() {
            return enabled;
        }

        public void setEnabled(boolean enabled) {
            this.enabled = enabled;
        }

        public String getRubricsVersion() {
            return rubricsVersion;
        }

        public void setRubricsVersion(String rubricsVersion) {
            this.rubricsVersion = rubricsVersion;
        }

        public String getToolSchemaVersion() {
            return toolSchemaVersion;
        }

        public void setToolSchemaVersion(String toolSchemaVersion) {
            this.toolSchemaVersion = toolSchemaVersion;
        }

        public int getMaxTokens() {
            return maxTokens;
        }

        public void setMaxTokens(int maxTokens) {
            this.maxTokens = maxTokens;
        }

        public double getTemperature() {
            return temperature;
        }

        public void setTemperature(double temperature) {
            this.temperature = temperature;
        }

        public int getMaxLeviers() {
            return maxLeviers;
        }

        public void setMaxLeviers(int maxLeviers) {
            this.maxLeviers = maxLeviers;
        }
    }
}
