package com.sejourfr.app.service;

import com.sejourfr.app.config.LearningPlanProperties;
import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.SkillMasteryState;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

/**
 * <b>LE</b> moteur de maitrise : d'un historique d'observations, il tire l'etat
 * d'une competence et le signal interne « prete a etre verifiee en situation ».
 *
 * <p><b>Fonction pure, aucun acces base.</b> Le chargement en lot vit dans
 * {@link SkillMasteryResolver} ; ici il n'y a que du calcul, testable sans mock
 * et rejouable sur n'importe quel historique. <b>Rien n'est persiste</b> :
 * recalibrer une ponderation dans {@code application.yaml} relit tout
 * l'historique au prochain appel, sans migration ni job de rattrapage — meme
 * philosophie que {@code SkillStatusResolver} et {@code SituationDansNiveau}.
 *
 * <h2>Comment le score se calcule</h2>
 * Chaque observation vaut {@code 1.0} (SOLID), {@code 0.5} (TO_REINFORCE) ou
 * {@code 0} (PRIORITY), et pese
 * {@code poidsSource x confiance x recence}. Le score est la moyenne
 * <b>ponderee</b> de ces valeurs, dans {@code [0,1]}. Il reste <b>interne</b> :
 * aucun DTO candidat ne l'expose, on ne montre pas un « 73 % maitrise » qui
 * ferait croire a une precision qui n'existe pas.
 *
 * <p>Les {@code NOT_OBSERVED} sont <b>ignores</b> : « je n'ai pas pu observer »
 * ne devient jamais « le candidat est mauvais ». Ils restent en base et
 * alimentent la frise, pas le calcul.
 *
 * <h2>Pourquoi l'etat ne se deduit pas du seul score</h2>
 * Un score eleve obtenu sur un seul micro-exercice ne prouve rien. {@code SOLID}
 * exige <b>cinq</b> conditions simultanees : le score, plusieurs observations
 * positives, <b>au moins une venue d'une production contextualisee</b> (jamais
 * d'un micro-entrainement seul), des sujets differents, et aucune serie de
 * fragilites recentes qui contredise la conclusion.
 *
 * <h2>Pourquoi une competence solide ne casse pas sur une erreur</h2>
 * Une production moins bonne fait mecaniquement chuter la moyenne sous le seuil.
 * Le moteur rejoue donc le calcul <b>sans les fragilites recentes</b> tant que
 * celles qui viennent d'une production contextualisee restent sous
 * {@code fragility-tolerance} : une seule est toleree (l'etat reste
 * {@code SOLID}, {@link SkillMastery#vigilance()} passe a vrai), deux le font
 * redescendre. Un echec en micro-exercice, lui, ne revoque jamais une maitrise
 * deja prouvee en situation. Une progression doit sembler stable, pas aleatoire.
 */
@Component
@RequiredArgsConstructor
public class SkillMasteryEngine {

    /** Cle de regroupement des observations dont le sujet est inconnu (lignes anterieures au suivi). */
    private static final UUID SUJET_INCONNU = new UUID(0L, 0L);

    private final LearningPlanProperties properties;

    /**
     * L'etat d'une competence a partir de son historique brut.
     *
     * @param observations toutes les observations connues de la competence,
     *                     dans n'importe quel ordre ; les {@code NOT_OBSERVED}
     *                     et les lignes hors fenetre sont ecartees ici.
     * @param now          instant de reference, injecte pour rendre la recence
     *                     testable.
     */
    public SkillMastery evaluate(Collection<LearningPlanObservation> observations, Instant now) {
        LearningPlanProperties.Mastery config = properties.getMastery();
        Instant windowStart = now.minus(Duration.ofDays(config.getWindowDays()));

        List<LearningPlanObservation> retained = observations.stream()
                .filter(LearningPlanObservation::isObserved)
                .filter(item -> item.getObservedAt() != null)
                .filter(item -> !item.getObservedAt().isBefore(windowStart))
                .sorted(Comparator.comparing(LearningPlanObservation::getObservedAt).reversed())
                .limit(Math.max(1, config.getMaxObservations()))
                .toList();
        if (retained.isEmpty()) return SkillMastery.NONE;

        Instant fragilityStart = now.minus(Duration.ofDays(config.getFragilityWindowDays()));
        List<LearningPlanObservation> recentFragilities = retained.stream()
                .filter(item -> item.getStatus() == LearningPlanSkillStatus.PRIORITY)
                .filter(item -> !item.getObservedAt().isBefore(fragilityStart))
                .toList();
        // SEULES les fragilites CONTEXTUALISEES peuvent revoquer une maitrise :
        // echouer un micro-exercice ne contredit pas un transfert deja prouve en
        // situation, alors que rater deux vraies productions, si.
        long revocatrices = recentFragilities.stream()
                .filter(item -> item.getSourceType() != null && item.getSourceType().isContextual())
                .count();

        Tally full = tally(retained, now, config);
        SkillMasteryState state = derive(full, config);

        // Filet de stabilite : une competence confirmee ne tombe pas parce
        // qu'UNE production s'est moins bien passee. On rejoue sans les
        // fragilites recentes tant que les revocatrices restent sous le seuil.
        boolean vigilance = false;
        if (state != SkillMasteryState.SOLID
                && !recentFragilities.isEmpty()
                && revocatrices < config.getFragilityTolerance()) {
            List<LearningPlanObservation> withoutFragilities = new ArrayList<>(retained);
            withoutFragilities.removeAll(recentFragilities);
            if (!withoutFragilities.isEmpty()
                    && derive(tally(withoutFragilities, now, config), config)
                            == SkillMasteryState.SOLID) {
                state = SkillMasteryState.SOLID;
                vigilance = true;
            }
        }

        return new SkillMastery(
                state,
                full.score(),
                retained.size(),
                full.positiveCount,
                full.contextualPositiveCount,
                full.distinctSubjects.size(),
                readyForReassessment(state, full, config),
                vigilance,
                retained.getFirst().getObservedAt());
    }

    // ------------------------------------------------------------------------
    // Interne
    // ------------------------------------------------------------------------

    /**
     * Passer de « le candidat comprend » a « verifions qu'il sait s'en servir ».
     *
     * <p>Signal <b>interne</b>, jamais un etat affiche : il dit au Plan de
     * cesser d'empiler les micro-exercices et de proposer une production. Quatre
     * conditions — assez de <b>reussites</b> ciblees au sens de
     * {@link #estReussiteCiblee} (un echec cible n'en est jamais une), sur des
     * <b>sujets differents</b>, une performance <b>ciblee</b> suffisante, et
     * <b>pas encore de preuve de transfert recente</b>. Une competence deja
     * {@code SOLID} n'a plus rien a verifier.
     *
     * <p><b>C'est la performance CIBLEE qui compte ici, pas le score global</b>,
     * et c'est structurel : la baseline du diagnostic est justement une
     * fragilite, et un micro-exercice reussi ne vaut jamais qu'une demi-preuve.
     * Un seuil pose sur le score global serait mecaniquement hors d'atteinte
     * tant que le diagnostic reste dans la fenetre — le Plan proposerait un
     * quatrieme, puis un dixieme micro-exercice, indefiniment.
     *
     * <p>⚠️ <b>Ce signal ne suffit pas a basculer l'etape.</b>
     * {@code LearningPlanService} lui ajoute une seconde condition, qu'il est le
     * seul a pouvoir voir : l'etape doit etre <b>terminee</b>
     * ({@code LearningPlanStep.Progress.completed()}, ses 5 sujets traites).
     * Sans elle, un candidat validant 2 des 5 sujets de son etape se voyait
     * proposer « verifier ma progression » avec un anneau a 2/5 — deux messages
     * contradictoires sur la meme carte. Corollaire <b>voulu</b> : un compte
     * gratuit, plafonne a 2 sujets, ne bascule jamais (la verification est
     * premium) et n'atteint donc jamais {@code SOLID}, qui exige la preuve
     * contextualisee qu'elle seule apporte.
     */
    private static boolean readyForReassessment(
            SkillMasteryState state, Tally tally, LearningPlanProperties.Mastery config) {
        if (state == SkillMasteryState.SOLID) return false;
        return tally.targetedPositiveSubjects.size() >= config.getReadinessTargetedSubjects()
                && tally.targetedScore() >= config.getReadinessTargetedScore()
                && !tally.recentContextualProof;
    }

    private static SkillMasteryState derive(Tally tally, LearningPlanProperties.Mastery config) {
        double score = tally.score();
        boolean assezDeReussites = tally.positiveCount >= config.getMinPositiveObservations();
        if (score >= config.getSolidScore()
                && assezDeReussites
                && tally.contextualPositiveCount >= 1
                && tally.distinctSubjects.size() >= config.getMinDistinctSubjects()) {
            return SkillMasteryState.SOLID;
        }
        if (score >= config.getConsolidatingScore() && assezDeReussites) {
            return SkillMasteryState.CONSOLIDATING;
        }
        if (score >= config.getReinforceScore()) return SkillMasteryState.TO_REINFORCE;
        return SkillMasteryState.PRIORITY;
    }

    private Tally tally(
            List<LearningPlanObservation> observations,
            Instant now,
            LearningPlanProperties.Mastery config) {
        Instant transferStart = now.minus(Duration.ofDays(config.getTransferProofDays()));
        Tally tally = new Tally();
        for (LearningPlanObservation item : observations) {
            double valeur = valeur(item.getStatus());
            double poids = poidsSource(item.getSourceType(), config)
                    * confiance(item.getConfidence(), config)
                    * recence(item.getObservedAt(), now, config);
            tally.poidsTotal += poids;
            tally.valeurPonderee += valeur * poids;
            tally.distinctSubjects.add(sujet(item));
            LearningPlanSourceType source = item.getSourceType();
            if (source != null && source.isTargeted()) {
                tally.targetedPoids += poids;
                tally.targetedValeurPonderee += valeur * poids;
                // Filtre PROPRE au signal de reevaluation, volontairement
                // decouple du « valeur >= 0.5 » ci-dessous : les deux ensembles
                // ne repondent pas a la meme question, et les faire dependre du
                // meme nombre magique revenait a recalibrer l'un en touchant
                // l'autre.
                if (estReussiteCiblee(item.getStatus())) {
                    tally.targetedPositiveSubjects.add(sujet(item));
                }
            }
            if (valeur < 0.5) continue;

            tally.positiveCount++;
            if (source == null) continue;
            if (source.isContextual()) {
                tally.contextualPositiveCount++;
                if (!item.getObservedAt().isBefore(transferStart)) tally.recentContextualProof = true;
            }
        }
        return tally;
    }

    /**
     * Un micro-entrainement <b>reussi</b>, et rien d'autre.
     *
     * <p>Ce que le module Competences ecrit reellement
     * ({@code LearningPlanObservationService.recordSkillAttempt}) : critere
     * {@code VALIDATED} &rarr; {@code TO_REINFORCE}, critere partiel ou non
     * atteint &rarr; {@code PRIORITY}. <b>Sur une observation CIBLEE,
     * {@code TO_REINFORCE} est donc un succes</b>, malgre son libelle « A
     * renforcer » — il dit « critere valide, mais une fois seulement, et en
     * situation guidee », pas « rate ». {@code SOLID} est accepte par
     * completude : cette voie ne l'ecrit jamais, et exiger {@code SOLID} ici
     * rendrait la verification en situation <b>structurellement inatteignable</b>
     * — donc {@code SOLID} lui-meme, qui reclame une preuve contextualisee que
     * seule cette verification apporte a un candidat qui ne fait que des
     * micro-exercices. Ne pas « corriger » cette methode a {@code SOLID} seul.
     */
    private static boolean estReussiteCiblee(LearningPlanSkillStatus status) {
        return status == LearningPlanSkillStatus.SOLID
                || status == LearningPlanSkillStatus.TO_REINFORCE;
    }

    /**
     * Sujet de l'observation. Les lignes sans sujet connu — celles ecrites avant
     * que la colonne existe — sont regroupees sous une meme cle : en cas de
     * doute on considere que c'est le <b>meme</b> sujet, jamais deux contextes
     * independants. L'erreur va ainsi vers « pas encore solide », jamais vers
     * une maitrise declaree a tort.
     */
    private static UUID sujet(LearningPlanObservation observation) {
        return observation.getSubjectId() == null ? SUJET_INCONNU : observation.getSubjectId();
    }

    private static double valeur(LearningPlanSkillStatus status) {
        if (status == null) return 0;
        return switch (status) {
            case SOLID -> 1.0;
            case TO_REINFORCE -> 0.5;
            case PRIORITY, NOT_OBSERVED -> 0;
        };
    }

    private static double poidsSource(
            LearningPlanSourceType source, LearningPlanProperties.Mastery config) {
        if (source == null) return config.getWeightProduction();
        return switch (source) {
            case SKILL_TRAINING -> config.getWeightSkillTraining();
            case DIAGNOSTIC_EE, DIAGNOSTIC_EO -> config.getWeightDiagnostic();
            case PRODUCTION_EE, PRODUCTION_EO -> config.getWeightProduction();
            case MOCK_EXAM_EE, MOCK_EXAM_EO -> config.getWeightMockExam();
            case TCF_CO, TCF_CE -> config.getWeightComprehension();
        };
    }

    private static double confiance(
            ObservationConfidence confidence, LearningPlanProperties.Mastery config) {
        if (confidence == null) return config.getConfidenceMedium();
        return switch (confidence) {
            case HIGH -> config.getConfidenceHigh();
            case MEDIUM -> config.getConfidenceMedium();
            case LOW -> config.getConfidenceLow();
        };
    }

    /** Decroissance par paliers : douce, bornee, et sans chute brutale d'un jour a l'autre. */
    private static double recence(
            Instant observedAt, Instant now, LearningPlanProperties.Mastery config) {
        long days = Duration.between(observedAt, now).toDays();
        if (days <= config.getRecencyRecentDays()) return config.getRecencyRecentFactor();
        if (days <= config.getRecencyMediumDays()) return config.getRecencyMediumFactor();
        return config.getRecencyOldFactor();
    }

    /** Accumulateur d'une passe de calcul. */
    private static final class Tally {
        private double poidsTotal;
        private double valeurPonderee;
        private double targetedPoids;
        private double targetedValeurPonderee;
        private int positiveCount;
        private int contextualPositiveCount;
        private boolean recentContextualProof;
        private final Set<UUID> distinctSubjects = new HashSet<>();
        private final Set<UUID> targetedPositiveSubjects = new HashSet<>();

        private double score() {
            return poidsTotal <= 0 ? 0 : valeurPonderee / poidsTotal;
        }

        /** Performance sur les seuls micro-entrainements : « a-t-il compris le moyen ? ». */
        private double targetedScore() {
            return targetedPoids <= 0 ? 0 : targetedValeurPonderee / targetedPoids;
        }
    }

    /**
     * Ce que le moteur conclut sur une competence.
     *
     * <p>{@code score} est <b>interne</b> : il sert aux tests, aux logs et a une
     * future calibration, jamais a l'affichage. {@code state} vaut {@code null}
     * quand aucune observation exploitable n'existe — on n'invente pas un etat
     * pour une competence que le serveur n'a jamais vue.
     */
    public record SkillMastery(
            SkillMasteryState state,
            double score,
            int observationCount,
            int positiveCount,
            int contextualPositiveCount,
            int distinctSubjectCount,
            /** Signal INTERNE : assez travaille en cible, il faut maintenant verifier en situation. */
            boolean readyForReassessment,
            /** {@code SOLID} conserve malgre une fragilite recente toleree. */
            boolean vigilance,
            Instant lastObservedAt) {

        /** Aucune observation exploitable : le moteur ne conclut rien. */
        public static final SkillMastery NONE =
                new SkillMastery(null, 0, 0, 0, 0, 0, false, false, null);
    }
}
