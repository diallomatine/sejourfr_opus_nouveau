package com.sejourfr.app.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Parametres du module « Competences TCF » (micro-entrainement EE/EO).
 *
 * <p>Namespace distinct de {@code sejourfr.production-evaluation} : l'analyse
 * ciblee est une voie PARALLELE a la notation des productions completes. Elle
 * n'a ni note sur 20, ni niveau CECRL, ni les quatre criteres du TCF — donc ni
 * les memes versions de consignes, ni le meme budget de tokens. Melanger les
 * deux namespaces aurait fait qu'un retour arriere sur la grille de notation
 * des epreuves completes emporterait au passage l'analyse des competences.
 *
 * <p>Le CHOIX DU FOURNISSEUR, lui, reste celui de
 * {@code sejourfr.production-evaluation.provider} : la regle « un seul
 * correcteur configurable » du projet vaut aussi ici, on ne veut pas de deux
 * modeles qui divergent silencieusement.
 *
 * <p><b>Les valeurs par defaut de ce POJO doivent rester identiques a celles
 * d'{@code application.yaml}</b> : deux sources qui divergent, c'est un
 * comportement different selon qu'une cle est presente ou non.
 */
@ConfigurationProperties(prefix = "sejourfr.competences")
public class CompetenceProperties {

    private Analysis analysis = new Analysis();

    public Analysis getAnalysis() {
        return analysis;
    }

    public void setAnalysis(Analysis analysis) {
        this.analysis = analysis;
    }

    /** Reglages de l'analyse ciblee et des garde-fous de soumission. */
    public static class Analysis {

        /**
         * Version du fichier de consignes charge par le fournisseur de
         * rubriques : {@code prompts/competence-analysis-rubrics-<v>.json}.
         */
        private String rubricsVersion = "v1";

        /**
         * Version du contrat de sortie :
         * {@code prompts/competence-analysis-tool-schema-<v>.json}. Versionnee
         * separement des consignes, comme cote productions : deux analyses
         * produites avec le meme schema mais des consignes differentes ne sont
         * pas comparables.
         */
        private String toolSchemaVersion = "v1";

        /**
         * Plafond de tokens de SORTIE. 600 suffit largement : la reponse tient
         * en cinq champs courts. C'est un plafond, pas une consommation — mais
         * le relever sans raison ouvrirait la porte a des sorties bavardes que
         * le contrat n'attend pas.
         */
        private int maxTokens = 600;

        /** Zero : sur un verdict de critere, on veut de la reproductibilite, pas de la creativite. */
        private double temperature = 0;

        /**
         * Analyses IA offertes a vie aux comptes gratuits. Produire,
         * s'auto-evaluer et lire les references restent gratuits et illimites :
         * ce quota ne borne QUE l'appel au correcteur.
         */
        private int freeAnalyses = 3;

        /**
         * Plafond de mots accepte sur une production ecrite. C'est un garde-fou
         * ANTI-ABUS (cout LLM, taille de ligne), pas une regle pedagogique : les
         * bornes {@code recommendedMin/MaxWords} d'un sujet restent indicatives
         * et ne bloquent jamais.
         */
        private int maxTextWords = 400;

        /**
         * Plafond de duree accepte sur une production orale, en secondes. Meme
         * nature : un micro-exercice se joue en une trentaine de secondes, 180 s
         * ne cadre pas le candidat, il coupe l'abus.
         */
        private int maxAudioDurationSeconds = 180;

        public String getRubricsVersion() { return rubricsVersion; }
        public void setRubricsVersion(String rubricsVersion) { this.rubricsVersion = rubricsVersion; }

        public String getToolSchemaVersion() { return toolSchemaVersion; }
        public void setToolSchemaVersion(String toolSchemaVersion) { this.toolSchemaVersion = toolSchemaVersion; }

        public int getMaxTokens() { return maxTokens; }
        public void setMaxTokens(int maxTokens) { this.maxTokens = maxTokens; }

        public double getTemperature() { return temperature; }
        public void setTemperature(double temperature) { this.temperature = temperature; }

        public int getFreeAnalyses() { return freeAnalyses; }
        public void setFreeAnalyses(int freeAnalyses) { this.freeAnalyses = freeAnalyses; }

        public int getMaxTextWords() { return maxTextWords; }
        public void setMaxTextWords(int maxTextWords) { this.maxTextWords = maxTextWords; }

        public int getMaxAudioDurationSeconds() { return maxAudioDurationSeconds; }
        public void setMaxAudioDurationSeconds(int maxAudioDurationSeconds) {
            this.maxAudioDurationSeconds = maxAudioDurationSeconds;
        }
    }
}
