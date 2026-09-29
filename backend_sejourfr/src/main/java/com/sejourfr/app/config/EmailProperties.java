package com.sejourfr.app.config;

import com.sejourfr.app.enums.EmailType;
import org.springframework.boot.context.properties.ConfigurationProperties;

import java.util.ArrayList;
import java.util.EnumMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Configuration du systeme d'emails ({@code sejourfr.email.*}).
 *
 * <p>Les valeurs par defaut sont celles du YAML de base, a l'identique. Seule
 * exception assumee : la table {@link #templates}, qui n'a pas de defaut Java —
 * {@code EmailTemplateResolver} verifie AU DEMARRAGE que chaque {@link EmailType}
 * y est decrit, donc un oubli echoue au boot au lieu de diverger en silence.
 *
 * <p>Les delais, fenetres et plafonds de l'automatisation ne sont PAS ici : ils
 * vivent dans {@code email/email-automation-config-v{n}.json} (config versionnee).
 */
@ConfigurationProperties(prefix = "sejourfr.email")
public class EmailProperties {

    /**
     * Implementation d'envoi active : {@code spring-mail} aujourd'hui,
     * {@code brevo} demain. Passer a Brevo = creer {@code BrevoEmailSender},
     * renseigner les {@code brevo-template-id} et changer cette valeur.
     */
    private String provider = "spring-mail";

    /** Expediteur, nom affiche compris. */
    private String from = "SejourFR <no-reply@sejourfr.fr>";

    /** Reply-To de tous les mails clients : une reponse arrive au support. */
    private String replyTo = "support@sejourfr.fr";

    /** Logo en URL absolue hebergee (un template Brevo ne sait pas faire de CID). */
    private String logoUrl = "https://sejourfr.fr/logo_sejourFR.png";

    /** Sujet, preheader et gabarit de chaque type, par provider. */
    private Map<EmailType, Template> templates = new EnumMap<>(EmailType.class);

    private Unsubscribe unsubscribe = new Unsubscribe();

    private Allowlist allowlist = new Allowlist();

    private Automation automation = new Automation();

    private Maintenance maintenance = new Maintenance();

    private Executor executor = new Executor();

    public String getProvider() { return provider; }
    public void setProvider(String provider) { this.provider = provider; }

    public String getFrom() { return from; }
    public void setFrom(String from) { this.from = from; }

    public String getReplyTo() { return replyTo; }
    public void setReplyTo(String replyTo) { this.replyTo = replyTo; }

    public String getLogoUrl() { return logoUrl; }
    public void setLogoUrl(String logoUrl) { this.logoUrl = logoUrl; }

    public Map<EmailType, Template> getTemplates() { return templates; }
    public void setTemplates(Map<EmailType, Template> templates) { this.templates = templates; }

    public Unsubscribe getUnsubscribe() { return unsubscribe; }
    public void setUnsubscribe(Unsubscribe unsubscribe) { this.unsubscribe = unsubscribe; }

    public Allowlist getAllowlist() { return allowlist; }
    public void setAllowlist(Allowlist allowlist) { this.allowlist = allowlist; }

    public Automation getAutomation() { return automation; }
    public void setAutomation(Automation automation) { this.automation = automation; }

    public Maintenance getMaintenance() { return maintenance; }
    public void setMaintenance(Maintenance maintenance) { this.maintenance = maintenance; }

    public Executor getExecutor() { return executor; }
    public void setExecutor(Executor executor) { this.executor = executor; }

    /**
     * Un gabarit : le sujet et le preheader servent au rendu LOCAL ; chez Brevo
     * ils vivent dans le template, identifie par {@code brevoTemplateId}.
     * {@code {{variable}}} est substitue dans le sujet comme dans le corps.
     */
    public static class Template {
        private String subject;
        private String preheader = "";
        /** Chemin classpath sans extension : {@code .html} et {@code .txt} y sont lus. */
        private String localTemplate;
        private Long brevoTemplateId;

        public String getSubject() { return subject; }
        public void setSubject(String subject) { this.subject = subject; }

        public String getPreheader() { return preheader; }
        public void setPreheader(String preheader) { this.preheader = preheader; }

        public String getLocalTemplate() { return localTemplate; }
        public void setLocalTemplate(String localTemplate) { this.localTemplate = localTemplate; }

        public Long getBrevoTemplateId() { return brevoTemplateId; }
        public void setBrevoTemplateId(Long brevoTemplateId) { this.brevoTemplateId = brevoTemplateId; }
    }

    /**
     * Trousseau HMAC des liens de desabonnement. La cle COURANTE signe, les
     * anciennes restent acceptees en verification : un lien envoye avant une
     * rotation continue de marcher. Les secrets viennent de l'environnement.
     */
    public static class Unsubscribe {
        private int currentKeyVersion = 1;
        private Map<Integer, String> keys = new LinkedHashMap<>();

        public int getCurrentKeyVersion() { return currentKeyVersion; }
        public void setCurrentKeyVersion(int currentKeyVersion) { this.currentKeyVersion = currentKeyVersion; }

        public Map<Integer, String> getKeys() { return keys; }
        public void setKeys(Map<Integer, String> keys) { this.keys = keys; }
    }

    /**
     * Liste blanche des destinataires (arbitrage n°11). Activee en dev : une
     * liste VIDE bloque tout mail vers un utilisateur, et le mail bloque est
     * trace {@code SKIPPED / ALLOWLIST}. Une entree qui commence par {@code @}
     * autorise un domaine entier.
     */
    public static class Allowlist {
        private boolean enabled = false;
        private List<String> addresses = new ArrayList<>();

        public boolean isEnabled() { return enabled; }
        public void setEnabled(boolean enabled) { this.enabled = enabled; }

        public List<String> getAddresses() { return addresses; }
        public void setAddresses(List<String> addresses) { this.addresses = addresses; }
    }

    /** Le passage quotidien des scenarios ENGAGEMENT. */
    public static class Automation {
        /** {@code false} en dev par defaut (arbitrage n°11). */
        private boolean enabled = true;
        /** Cron du passage, fuseau Europe/Paris. */
        private String cron = "0 0 9 * * *";
        /** Version de {@code email/email-automation-config-v{n}.json}. */
        private int configVersion = 1;

        public boolean isEnabled() { return enabled; }
        public void setEnabled(boolean enabled) { this.enabled = enabled; }

        public String getCron() { return cron; }
        public void setCron(String cron) { this.cron = cron; }

        public int getConfigVersion() { return configVersion; }
        public void setConfigVersion(int configVersion) { this.configVersion = configVersion; }
    }

    /**
     * Passes de maintenance : PENDING bloques + relance differee des mails
     * evenementiels (horaire), purge de retention (quotidienne).
     */
    public static class Maintenance {
        private String retryCron = "0 20 * * * *";
        private String retentionCron = "0 40 3 * * *";

        public String getRetryCron() { return retryCron; }
        public void setRetryCron(String retryCron) { this.retryCron = retryCron; }

        public String getRetentionCron() { return retentionCron; }
        public void setRetentionCron(String retentionCron) { this.retentionCron = retentionCron; }
    }

    /**
     * {@code emailTaskExecutor}, dedie et BORNE : une panne SMTP ne doit jamais
     * ralentir la notation IA qui tourne sur l'executor par defaut. Pas de
     * {@code CallerRunsPolicy} (complement E) : un rejet devient une ligne FAILED.
     */
    public static class Executor {
        private int corePoolSize = 2;
        private int maxPoolSize = 4;
        private int queueCapacity = 500;

        public int getCorePoolSize() { return corePoolSize; }
        public void setCorePoolSize(int corePoolSize) { this.corePoolSize = corePoolSize; }

        public int getMaxPoolSize() { return maxPoolSize; }
        public void setMaxPoolSize(int maxPoolSize) { this.maxPoolSize = maxPoolSize; }

        public int getQueueCapacity() { return queueCapacity; }
        public void setQueueCapacity(int queueCapacity) { this.queueCapacity = queueCapacity; }
    }
}
