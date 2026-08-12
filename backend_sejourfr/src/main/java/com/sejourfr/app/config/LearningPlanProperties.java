package com.sejourfr.app.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Reglages du <b>moteur de maitrise</b> des micro-competences.
 *
 * <p>Tous les nombres qui decident d'un etat de maitrise vivent ici, et <b>nulle
 * part ailleurs</b> : aucune constante de ponderation ne doit etre dispersee
 * dans le Java. Ce sont des parametres produit, pas des verites — ils seront
 * recalibres quand il y aura des donnees, et comme rien n'est persiste, changer
 * une valeur relit tout l'historique immediatement, sans migration ni job.
 *
 * <p><b>Les valeurs par defaut de ce POJO doivent rester identiques a celles
 * d'{@code application.yaml}</b> : deux sources qui divergent, c'est un
 * comportement different selon qu'une cle est presente ou non (meme regle que
 * {@link CompetenceProperties}).
 */
@ConfigurationProperties(prefix = "sejourfr.learning-plan")
public class LearningPlanProperties {

    private Mastery mastery = new Mastery();

    public Mastery getMastery() {
        return mastery;
    }

    public void setMastery(Mastery mastery) {
        this.mastery = mastery;
    }

    /** Ponderations, fenetre et seuils du moteur de maitrise. */
    public static class Mastery {

        /**
         * Fenetre glissante, en jours. Au-dela, une observation ne compte plus
         * du tout.
         *
         * <p>Motif : une moyenne depuis la creation du compte penalise
         * eternellement une erreur ancienne et fait remonter trop lentement une
         * competence nouvellement acquise. La fenetre borne l'histoire, la
         * recence pondere ce qui reste — les deux ensemble, pas l'un ou l'autre.
         */
        private int windowDays = 180;

        /**
         * Nombre maximal d'observations retenues par competence, les plus
         * recentes d'abord.
         *
         * <p>Garde-fou contre le candidat qui enchaine trente micro-exercices
         * dans la journee : sans plafond, la masse ecraserait deux vraies taches
         * ratees.
         */
        private int maxObservations = 12;

        /** Poids d'un micro-entrainement cible : il fait progresser, il ne prouve pas le transfert. */
        private double weightSkillTraining = 0.45;

        /** Poids du diagnostic initial : une vraie production, mais c'est la baseline. */
        private double weightDiagnostic = 0.80;

        /** Poids d'une production complete standard : la reference. */
        private double weightProduction = 1.00;

        /** Poids d'une production d'examen blanc : la preuve la plus forte, aucun filet. */
        private double weightMockExam = 1.20;

        /**
         * Poids d'une observation deterministe CO/CE. Reservee : rien ne
         * l'ecrit encore, la cle existe pour que l'extension future n'ait pas a
         * toucher au moteur.
         */
        private double weightComprehension = 1.00;

        /** Facteur applique quand le correcteur s'est dit sur de son observation. */
        private double confidenceHigh = 1.00;

        private double confidenceMedium = 0.80;

        /**
         * Une confiance basse pese moins, sans jamais disparaitre : c'est une
         * limite d'<b>observation</b>, pas un defaut du candidat.
         */
        private double confidenceLow = 0.55;

        /** Jusqu'a ce nombre de jours, l'observation compte a plein. */
        private int recencyRecentDays = 14;

        private double recencyRecentFactor = 1.00;

        /** Deuxieme palier de recence, en jours. */
        private int recencyMediumDays = 30;

        private double recencyMediumFactor = 0.85;

        /**
         * Plancher : au-dela du deuxieme palier et dans la fenetre, une
         * observation garde ce poids. Decroissance douce, jamais de chute
         * brutale — un candidat ne doit pas voir son etat basculer parce qu'une
         * nuit est passee.
         */
        private double recencyOldFactor = 0.70;

        /** Score pondere minimal pour envisager {@code SOLID}. */
        private double solidScore = 0.75;

        /** Score pondere minimal pour {@code CONSOLIDATING}. */
        private double consolidatingScore = 0.50;

        /** Score pondere minimal pour {@code TO_REINFORCE} ; en dessous, c'est une priorite. */
        private double reinforceScore = 0.30;

        /**
         * Observations positives distinctes exigees avant {@code SOLID} comme
         * avant {@code CONSOLIDATING}. Une reussite unique ne conclut rien.
         */
        private int minPositiveObservations = 2;

        /**
         * Sujets differents exiges avant {@code SOLID} : refaire trois fois le
         * meme exercice apres correction n'est pas une preuve de maitrise.
         */
        private int minDistinctSubjects = 2;

        /**
         * Fragilites <b>contextualisees et recentes</b> qui font redescendre une
         * competence solide. A {@code 2}, une seule production moins bonne est
         * toleree : la progression doit sembler stable, pas aleatoire.
         */
        private int fragilityTolerance = 2;

        /** Fenetre, en jours, ou une fragilite contextualisee compte encore contre {@code SOLID}. */
        private int fragilityWindowDays = 60;

        /**
         * Performance minimale <b>sur les seuls micro-entrainements</b> pour se
         * declarer pret a etre verifie en situation.
         *
         * <p>Volontairement pose sur la performance ciblee et non sur le score
         * global : la baseline du diagnostic est une fragilite, et un
         * micro-exercice reussi ne vaut qu'une demi-preuve — un seuil global
         * serait mecaniquement hors d'atteinte et le Plan proposerait des
         * micro-exercices a l'infini. A {@code 0.30}, il faut une <b>majorite</b>
         * de reussites recentes en cible.
         */
        private double readinessTargetedScore = 0.30;

        /** Sujets cibles differents reussis avant de proposer une verification en situation. */
        private int readinessTargetedSubjects = 2;

        /**
         * Duree, en jours, pendant laquelle une preuve de transfert reste
         * valable. Tant qu'elle l'est, on ne redemande pas de verification.
         */
        private int transferProofDays = 60;

        public int getWindowDays() { return windowDays; }
        public void setWindowDays(int windowDays) { this.windowDays = windowDays; }

        public int getMaxObservations() { return maxObservations; }
        public void setMaxObservations(int maxObservations) { this.maxObservations = maxObservations; }

        public double getWeightSkillTraining() { return weightSkillTraining; }
        public void setWeightSkillTraining(double weightSkillTraining) {
            this.weightSkillTraining = weightSkillTraining;
        }

        public double getWeightDiagnostic() { return weightDiagnostic; }
        public void setWeightDiagnostic(double weightDiagnostic) {
            this.weightDiagnostic = weightDiagnostic;
        }

        public double getWeightProduction() { return weightProduction; }
        public void setWeightProduction(double weightProduction) {
            this.weightProduction = weightProduction;
        }

        public double getWeightMockExam() { return weightMockExam; }
        public void setWeightMockExam(double weightMockExam) {
            this.weightMockExam = weightMockExam;
        }

        public double getWeightComprehension() { return weightComprehension; }
        public void setWeightComprehension(double weightComprehension) {
            this.weightComprehension = weightComprehension;
        }

        public double getConfidenceHigh() { return confidenceHigh; }
        public void setConfidenceHigh(double confidenceHigh) { this.confidenceHigh = confidenceHigh; }

        public double getConfidenceMedium() { return confidenceMedium; }
        public void setConfidenceMedium(double confidenceMedium) {
            this.confidenceMedium = confidenceMedium;
        }

        public double getConfidenceLow() { return confidenceLow; }
        public void setConfidenceLow(double confidenceLow) { this.confidenceLow = confidenceLow; }

        public int getRecencyRecentDays() { return recencyRecentDays; }
        public void setRecencyRecentDays(int recencyRecentDays) {
            this.recencyRecentDays = recencyRecentDays;
        }

        public double getRecencyRecentFactor() { return recencyRecentFactor; }
        public void setRecencyRecentFactor(double recencyRecentFactor) {
            this.recencyRecentFactor = recencyRecentFactor;
        }

        public int getRecencyMediumDays() { return recencyMediumDays; }
        public void setRecencyMediumDays(int recencyMediumDays) {
            this.recencyMediumDays = recencyMediumDays;
        }

        public double getRecencyMediumFactor() { return recencyMediumFactor; }
        public void setRecencyMediumFactor(double recencyMediumFactor) {
            this.recencyMediumFactor = recencyMediumFactor;
        }

        public double getRecencyOldFactor() { return recencyOldFactor; }
        public void setRecencyOldFactor(double recencyOldFactor) {
            this.recencyOldFactor = recencyOldFactor;
        }

        public double getSolidScore() { return solidScore; }
        public void setSolidScore(double solidScore) { this.solidScore = solidScore; }

        public double getConsolidatingScore() { return consolidatingScore; }
        public void setConsolidatingScore(double consolidatingScore) {
            this.consolidatingScore = consolidatingScore;
        }

        public double getReinforceScore() { return reinforceScore; }
        public void setReinforceScore(double reinforceScore) { this.reinforceScore = reinforceScore; }

        public int getMinPositiveObservations() { return minPositiveObservations; }
        public void setMinPositiveObservations(int minPositiveObservations) {
            this.minPositiveObservations = minPositiveObservations;
        }

        public int getMinDistinctSubjects() { return minDistinctSubjects; }
        public void setMinDistinctSubjects(int minDistinctSubjects) {
            this.minDistinctSubjects = minDistinctSubjects;
        }

        public int getFragilityTolerance() { return fragilityTolerance; }
        public void setFragilityTolerance(int fragilityTolerance) {
            this.fragilityTolerance = fragilityTolerance;
        }

        public int getFragilityWindowDays() { return fragilityWindowDays; }
        public void setFragilityWindowDays(int fragilityWindowDays) {
            this.fragilityWindowDays = fragilityWindowDays;
        }

        public double getReadinessTargetedScore() { return readinessTargetedScore; }
        public void setReadinessTargetedScore(double readinessTargetedScore) {
            this.readinessTargetedScore = readinessTargetedScore;
        }

        public int getReadinessTargetedSubjects() { return readinessTargetedSubjects; }
        public void setReadinessTargetedSubjects(int readinessTargetedSubjects) {
            this.readinessTargetedSubjects = readinessTargetedSubjects;
        }

        public int getTransferProofDays() { return transferProofDays; }
        public void setTransferProofDays(int transferProofDays) {
            this.transferProofDays = transferProofDays;
        }
    }
}
