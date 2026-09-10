package com.sejourfr.app.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

/** Configuration du diagnostic rapide, distincte de la notation TCF /20. */
@ConfigurationProperties(prefix = "sejourfr.diagnostic")
public class DiagnosticProperties {

    /**
     * Code du diagnostic servi. {@code QUICK_TCF} = le diagnostic ecrit rapide
     * (L3, une production transversale) ; {@code INITIAL_TCF} = la paire EE+EO
     * historique. Valeur par defaut IDENTIQUE a celle d'application.yaml.
     *
     * <p>🛑 Ce n'est pas un drapeau de fonctionnalite : la FORME du parcours se
     * lit sur le contenu de ce couple (code, version) — presence ou absence
     * d'un sujet {@code TCF_EO} actif. Ne jamais ajouter un booleen a cote, il
     * pourrait contredire ce qui est reellement servi.
     */
    private String initialCode = "QUICK_TCF";
    private Analysis analysis = new Analysis();
    private ExempleCible exempleCible = new ExempleCible();

    public String getInitialCode() { return initialCode; }
    public void setInitialCode(String initialCode) { this.initialCode = initialCode; }
    public Analysis getAnalysis() { return analysis; }
    public void setAnalysis(Analysis analysis) { this.analysis = analysis; }
    public ExempleCible getExempleCible() { return exempleCible; }
    public void setExempleCible(ExempleCible exempleCible) { this.exempleCible = exempleCible; }

    public static class Analysis {
        private String rubricsVersion = "v1";
        private String toolSchemaVersion = "v1";
        private int maxTokens = 2200;
        private double temperature = 0;
        private int maxSessionRetries = 3;

        public String getRubricsVersion() { return rubricsVersion; }
        public void setRubricsVersion(String rubricsVersion) { this.rubricsVersion = rubricsVersion; }
        public String getToolSchemaVersion() { return toolSchemaVersion; }
        public void setToolSchemaVersion(String toolSchemaVersion) { this.toolSchemaVersion = toolSchemaVersion; }
        public int getMaxTokens() { return maxTokens; }
        public void setMaxTokens(int maxTokens) { this.maxTokens = maxTokens; }
        public double getTemperature() { return temperature; }
        public void setTemperature(double temperature) { this.temperature = temperature; }
        public int getMaxSessionRetries() { return maxSessionRetries; }
        public void setMaxSessionRetries(int maxSessionRetries) { this.maxSessionRetries = maxSessionRetries; }
    }

    /**
     * Reglages du SECOND appel « avant / apres » de l'ecran de resultat : la
     * phrase du candidat, et la meme phrase reecrite au niveau qu'il vise.
     *
     * <p>Namespace distinct d'{@link Analysis} pour la meme raison qui separe
     * deja le second appel des productions de leur correction : un retour arriere
     * sur le contrat d'analyse ne doit pas emporter au passage celui du second
     * appel, ni l'inverse. Le contrat d'analyse, lui, ne bouge <b>pas d'un
     * octet</b> — le correcteur du diagnostic n'apprend jamais qu'on va reecrire
     * quoi que ce soit (mesure v10/v11 : un bloc ajoute a une grille qui juge fait
     * tomber l'accord exact de 81,8 % a 75,6 %).
     *
     * <p>Le CHOIX DU FOURNISSEUR reste celui de
     * {@code sejourfr.production-evaluation.provider} — regle « un seul correcteur
     * configurable ».
     *
     * <p><b>Les valeurs par defaut de ce POJO doivent rester identiques a celles
     * d'{@code application.yaml}</b> : deux sources qui divergent, c'est un
     * comportement different selon qu'une cle est presente ou non.
     */
    public static class ExempleCible {

        /**
         * Coupe-circuit. A {@code false}, aucun second appel n'est emis et le bloc
         * est simplement absent : l'analyse diagnostique et la session restent
         * completes. C'est le retour arriere d'un enrichissement best-effort, il ne
         * coute aucune migration.
         */
        private boolean enabled = true;

        /** {@code prompts/diagnostic-exemple-cible-rubrics-<v>.json}. */
        private String rubricsVersion = "v1";

        /** {@code prompts/diagnostic-exemple-cible-tool-schema-<v>.json}. */
        private String toolSchemaVersion = "v1";

        /**
         * Plafond de tokens de SORTIE, propre a cet appel : un numero, une phrase
         * reecrite, deux ou trois etiquettes de trois mots. C'est un plafond, pas
         * une consommation.
         */
        private int maxTokens = 700;

        /** Zero : deux lectures de la meme production doivent rendre la meme phrase. */
        private double temperature = 0;

        public boolean isEnabled() { return enabled; }
        public void setEnabled(boolean enabled) { this.enabled = enabled; }

        public String getRubricsVersion() { return rubricsVersion; }
        public void setRubricsVersion(String rubricsVersion) { this.rubricsVersion = rubricsVersion; }

        public String getToolSchemaVersion() { return toolSchemaVersion; }
        public void setToolSchemaVersion(String toolSchemaVersion) {
            this.toolSchemaVersion = toolSchemaVersion;
        }

        public int getMaxTokens() { return maxTokens; }
        public void setMaxTokens(int maxTokens) { this.maxTokens = maxTokens; }

        public double getTemperature() { return temperature; }
        public void setTemperature(double temperature) { this.temperature = temperature; }
    }
}
