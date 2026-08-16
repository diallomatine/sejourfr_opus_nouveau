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
    private NiveauVise niveauVise = new NiveauVise();

    public Analysis getAnalysis() {
        return analysis;
    }

    public void setAnalysis(Analysis analysis) {
        this.analysis = analysis;
    }

    public NiveauVise getNiveauVise() {
        return niveauVise;
    }

    public void setNiveauVise(NiveauVise niveauVise) {
        this.niveauVise = niveauVise;
    }

    /** Reglages de l'analyse ciblee et des garde-fous de soumission. */
    public static class Analysis {

        /**
         * Version du fichier de consignes charge par le fournisseur de
         * rubriques : {@code prompts/competence-analysis-rubrics-<v>.json}.
         *
         * <p>v6 = v5 au bit pres pour tout ce qui JUGE (role, les trois verdicts
         * et leur regle de decision, la table des cinq paliers, la brievete, le
         * garde-fou oral, l'accentuation, les plafonds, les dix ancres dans leur
         * substance). Elle corrige une asymetrie du MECANISME, pas une consigne :
         * annoncer un B1/B2 coutait un numero de segment et risquait un
         * abaissement, annoncer un A2 ne coutait rien. La preuve est desormais
         * exigee <b>a tous les paliers</b> — l'effort devient symetrique, la
         * sanction reste reservee au B1/B2.
         * Retour arriere : v5 + v4, v4 + v4, v3 + v3, v2 + v2, ou v1 + v1.
         */
        private String rubricsVersion = "v6";

        /**
         * Version du contrat de sortie :
         * {@code prompts/competence-analysis-tool-schema-<v>.json}. Versionnee
         * separement des consignes, comme cote productions : deux analyses
         * produites avec le meme schema mais des consignes differentes ne sont
         * pas comparables — c'est le cas de v5 des consignes, qui rendait le meme
         * JSON que v4. Le tool-schema v5, lui, est celui de v4 avec
         * {@code level_evidence} dans son {@code required}.
         */
        private String toolSchemaVersion = "v5";

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

    /**
     * Reglages du SECOND appel « pour viser X » : leviers, exemple cible et
     * tournure a retenir, produits APRES l'analyse et separement d'elle.
     *
     * <p>Namespace distinct de {@link Analysis} pour la meme raison qui separe
     * deja les Competences des productions completes : un retour arriere sur le
     * contrat d'analyse ne doit pas emporter au passage le contrat du second
     * appel, ni l'inverse. Le CHOIX DU FOURNISSEUR, lui, reste celui de
     * {@code sejourfr.production-evaluation.provider} — regle « un seul
     * correcteur configurable ».
     */
    public static class NiveauVise {

        /**
         * Coupe-circuit. A {@code false}, aucun second appel n'est emis et le
         * bloc est simplement absent : l'analyse, elle, reste complete. C'est le
         * retour arriere d'un enrichissement best-effort, il ne coute aucune
         * migration.
         */
        private boolean enabled = true;

        /**
         * {@code prompts/competence-niveau-vise-rubrics-<v>.json}.
         *
         * <p>v3 = UN LEVIER NOMME UNE OPERATION DE LANGUE. Chaque levier declare
         * son {@code procede} dans la MEME enumeration fermee que les marqueurs
         * du palier. Motif mesure : les leviers servis vers le B2 etaient « Rends
         * ton invitation plus chaleureuse », « Propose une alternative concrete »,
         * « Termine par une formule engageante » — des conseils de TON, qu'on
         * peut suivre a la lettre en restant A2. C'est le SCHEMA qui tient la
         * regle : 🛑 un levier n'est jamais purge a cause de son procede, il est
         * servi tel quel et l'anomalie est comptee.
         *
         * <p>v2 = le PALIER DEVIENT EXIGIBLE. Le texte modele vise la marche
         * suivante (palier constate + 1, plafonne a l'objectif du candidat), sa
         * longueur est bornee par celle du sujet, et il doit DESIGNER deux a
         * trois {@code marqueurs_du_palier} recopies de lui-meme. Motif mesure :
         * un candidat a recopie tel quel un texte servi comme « version pour
         * viser le B2 », l'a resoumis, et le correcteur l'a reevalue A2 — rien
         * n'obligeait ce texte a etre au niveau annonce.
         *
         * <p>Retour arriere : v2 + v2, ou v1 + v1, sans migration.
         */
        private String rubricsVersion = "v3";

        /** {@code prompts/competence-niveau-vise-tool-schema-<v>.json}. */
        private String toolSchemaVersion = "v3";

        /**
         * Plafond de tokens de SORTIE, propre a cet appel : deux ou trois
         * leviers de six mots, un texte de quelques phrases, une tournure. 900
         * laisse une marge large sans ouvrir la porte a une sortie bavarde.
         */
        private int maxTokens = 900;

        /** Zero : deux lectures de la meme production doivent rendre le meme plan. */
        private double temperature = 0;

        /**
         * Plafond SERVEUR du nombre de leviers (le tool-schema en demande 2 a
         * 3). Troisieme filet, celui qui ne depend d'aucune cooperation du
         * modele.
         */
        private int maxLeviers = 3;

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

        public int getMaxLeviers() { return maxLeviers; }
        public void setMaxLeviers(int maxLeviers) { this.maxLeviers = maxLeviers; }
    }
}
