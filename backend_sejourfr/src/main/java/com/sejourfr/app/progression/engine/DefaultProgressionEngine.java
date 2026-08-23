package com.sejourfr.app.progression.engine;

import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.progression.config.ProgressionConfig;
import com.sejourfr.app.progression.domain.DomainProjection;
import com.sejourfr.app.progression.domain.CalibrationStatus;
import com.sejourfr.app.progression.domain.EvidenceSourceFamily;
import com.sejourfr.app.progression.domain.EvidenceSourceType;
import com.sejourfr.app.progression.domain.LearningEvidence;
import com.sejourfr.app.progression.domain.PartialPractice;
import com.sejourfr.app.progression.domain.ProgressionSnapshot;
import com.sejourfr.app.progression.domain.ProgressionStateKey;
import com.sejourfr.app.progression.domain.ProgressionStateType;
import com.sejourfr.app.progression.domain.ProgressionStatus;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Comparator;
import java.util.EnumMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * <b>Le moteur de progression V4.2</b> — pur, déterministe, rejouable.
 *
 * <p>Il ne persiste rien, ne lit aucun repository et n'a aucun état : on lui
 * donne un multiensemble de preuves et un instant, il rend une projection. Même
 * multiensemble + même config + même {@code now} = même résultat (invariant
 * I10).
 *
 * <h2>Pourquoi un repli sur l'historique plutôt qu'un simple agrégat</h2>
 *
 * <p>Les agrégats — {@code sumWeightEpoch}, {@code masteryScore},
 * {@code confidence} — sont commutatifs par construction (§10) : on pourrait les
 * calculer en une passe, dans n'importe quel ordre. Mais trois choses dépendent
 * réellement de l'<b>histoire</b> et pas seulement du total :
 *
 * <ul>
 *   <li>les hystérésis {@code PROGRESSING} et {@code SOLID}, qui regardent
 *       l'état précédent (§14.6, §14.7) ;</li>
 *   <li>le passage {@code SOLID → WATCH}, déclenché par la <i>première</i>
 *       contradiction forte (§15) ;</li>
 *   <li>{@code visibleProgress}, qui ne redescend jamais dans un cycle (§25).</li>
 }
 * </ul>
 *
 * <p>Le moteur rejoue donc les preuves dans l'ordre de leur {@code occurredAt} —
 * <b>l'heure pédagogique, pas l'ordre d'arrivée serveur</b>. C'est exactement ce
 * que prescrit §29 : le replay utilise les timestamps et les règles, jamais
 * l'ordre d'ingestion. Une preuve hors-ligne qui remonte trois jours plus tard
 * se replace donc à sa vraie place, et le résultat est le même que si elle était
 * arrivée à l'heure (invariant I9).
 */
@Component
@RequiredArgsConstructor
public class DefaultProgressionEngine implements ProgressionEngine {

    private final ProgressionConfig config;

    @Override
    public double chanceAdjustedResult(int correctAnswers, int totalQuestions,
                                       double meanGuessRate) {
        if (totalQuestions <= 0) {
            throw new IllegalArgumentException("totalQuestions doit être > 0");
        }
        if (meanGuessRate >= 1.0d) {
            throw new IllegalArgumentException(
                    "meanGuessRate >= 1 : une question à une seule proposition ne mesure rien");
        }
        double accuracy = (double) correctAnswers / totalQuestions;
        return Math.clamp((accuracy - meanGuessRate) / (1 - meanGuessRate), 0.0d, 1.0d);
    }

    @Override
    public double baseEffectiveWeight(LearningEvidence evidence) {
        return config.sourceWeights().get(evidence.sourceType())
                * evidence.scoringConfidence()
                * config.assistanceFactors().get(evidence.assistanceLevel())
                * config.independenceFactors().get(evidence.independenceClass());
    }

    @Override
    public double toEpochWeight(double baseWeight, Instant occurredAt) {
        return EpochWeights.toEpochWeight(config, baseWeight, occurredAt);
    }

    @Override
    public ProgressionSnapshot project(ProgressionStateKey stateKey,
                                       Collection<LearningEvidence> evidence,
                                       Collection<PartialPractice> partialPractice,
                                       Instant now) {
        List<LearningEvidence> pertinentes = pertinentes(stateKey, evidence);
        Accumulateur acc = new Accumulateur(stateKey);

        for (LearningEvidence preuve : pertinentes) {
            acc.appliquer(preuve);
        }
        for (PartialPractice partielle : partialPractice) {
            if (partielle.stateKey().equals(stateKey)) {
                acc.appliquerPartielle(partielle);
            }
        }
        return acc.projeter(now);
    }

    @Override
    public DomainProjection projectDomain(SkillSection section, TargetLevel objectiveLevel,
                                          Collection<LearningEvidence> evidence,
                                          Instant now) {
        Map<TargetLevel, ProgressionSnapshot> paliers = new EnumMap<>(TargetLevel.class);
        for (TargetLevel niveau : TargetLevel.values()) {
            paliers.put(niveau,
                    project(ProgressionStateKey.receptive(section, niveau), evidence, now));
        }

        Map<TargetLevel, TargetLevel> parQuiSatisfait = new EnumMap<>(TargetLevel.class);
        Map<TargetLevel, Boolean> satisfaits = new EnumMap<>(TargetLevel.class);
        for (TargetLevel niveau : TargetLevel.values()) {
            TargetLevel source = niveauQuiSatisfait(niveau, paliers);
            satisfaits.put(niveau, source != null);
            if (source != null) {
                parQuiSatisfait.put(niveau, source);
            }
        }

        TargetLevel actif = activeLearningLevel(objectiveLevel, paliers, satisfaits);
        return new DomainProjection(section, objectiveLevel, paliers, satisfaits,
                parQuiSatisfait, actif, prescriptionLevel(paliers, actif));
    }

    /* --------------------------------------------------------------- prérequis */

    /**
     * §18.1 — quel niveau <b>directement qualifié</b> au-dessus satisfait ce
     * palier, s'il y en a un.
     *
     * <p>🛑 Seul un niveau à la fois {@code SOLID} <b>et</b>
     * {@code directQualification} peut satisfaire un prérequis inférieur
     * (§18.3). Un niveau lui-même seulement satisfait ne propage rien : sinon on
     * construirait une chaîne d'inférences sans la moindre preuve à son origine
     * (T15, invariant I22).
     *
     * <p>Et rien de tout ceci n'écrit de {@code LearningEvidence} au niveau
     * inférieur (invariant I4). L'inférence est <b>dérivée à la lecture</b>,
     * donc révocable dès que le niveau source retombe (§18.4, T16).
     *
     * <p>On remonte du plus proche au plus haut : « Validé via B1 » est plus
     * juste — et plus lisible pour le candidat — que « Validé via B2 » quand les
     * deux sont vrais.
     */
    private TargetLevel niveauQuiSatisfait(TargetLevel niveau,
                                           Map<TargetLevel, ProgressionSnapshot> paliers) {
        for (TargetLevel superieur : TargetLevel.values()) {
            if (superieur.ordinal() <= niveau.ordinal()) {
                continue;
            }
            ProgressionSnapshot etat = paliers.get(superieur);
            if (etat.status() == ProgressionStatus.SOLID && etat.directQualification()) {
                return superieur;
            }
        }
        return null;
    }

    /** §19 — un palier est franchi s'il est acquis, ou satisfait par le dessus. */
    private boolean estFranchi(TargetLevel niveau,
                               Map<TargetLevel, ProgressionSnapshot> paliers,
                               Map<TargetLevel, Boolean> satisfaits) {
        return paliers.get(niveau).status() == ProgressionStatus.SOLID
                || Boolean.TRUE.equals(satisfaits.get(niveau));
    }

    /**
     * §19 — le premier palier non franchi, sans jamais dépasser l'objectif.
     *
     * <p>{@code null} veut dire « l'objectif est atteint », pas « rien à faire » :
     * c'est au Plan de décider ce qu'il propose ensuite.
     */
    private TargetLevel activeLearningLevel(TargetLevel objectif,
                                            Map<TargetLevel, ProgressionSnapshot> paliers,
                                            Map<TargetLevel, Boolean> satisfaits) {
        for (TargetLevel niveau : TargetLevel.values()) {
            if (niveau.ordinal() > objectif.ordinal()) {
                return null;
            }
            if (!estFranchi(niveau, paliers, satisfaits)) {
                return niveau;
            }
        }
        return null;
    }

    /**
     * §19, §20 — ce que le Plan a le droit de prescrire, <b>et rien d'autre</b>.
     *
     * <p>Un palier en {@code WATCH} prend la main sur l'apprentissage normal :
     * c'est ce qui empêche d'afficher {@code CO A2} et {@code CO B1} le même
     * jour quand B1 est contredit et que son prérequis A2 vient d'être révoqué
     * (T16, T33, invariant I16). Le candidat vérifie d'abord ce qui vacille.
     *
     * <p>Entre plusieurs {@code WATCH}, on prend le <b>plus bas</b> : c'est le
     * plus proche des fondations, donc celui dont le doute contamine le reste.
     */
    private TargetLevel prescriptionLevel(Map<TargetLevel, ProgressionSnapshot> paliers,
                                          TargetLevel actif) {
        for (TargetLevel niveau : TargetLevel.values()) {
            if (paliers.get(niveau).status() == ProgressionStatus.WATCH) {
                return niveau;
            }
        }
        return actif;
    }

    /* ------------------------------------------------------------- préparation */

    /**
     * Les preuves de cette clé, dédoublonnées, dans l'ordre pédagogique.
     *
     * <p>Le dédoublonnage par {@code naturalKey} est ce qui rend un retry réseau
     * inoffensif (§42, T12) : deux fois la même tentative ne comptent qu'une.
     *
     * <p>Le tri est {@code (occurredAt, naturalKey)} : la seconde clé n'est pas
     * cosmétique, elle rend l'ordre <b>total</b>. Sans elle, deux preuves du même
     * instant se replieraient dans l'ordre du tableau reçu, et une projection
     * pourrait dépendre de l'ordre d'ingestion — exactement ce que T11 interdit.
     */
    private List<LearningEvidence> pertinentes(ProgressionStateKey stateKey,
                                               Collection<LearningEvidence> evidence) {
        Map<String, LearningEvidence> uniques = new LinkedHashMap<>();
        for (LearningEvidence preuve : evidence) {
            if (preuve.stateKey().equals(stateKey)) {
                uniques.putIfAbsent(preuve.naturalKey(), preuve);
            }
        }
        List<LearningEvidence> triees = new ArrayList<>(uniques.values());
        triees.sort(Comparator.comparing(LearningEvidence::occurredAt)
                .thenComparing(LearningEvidence::naturalKey));
        return triees;
    }

    /* ------------------------------------------------------------ accumulateur */

    /** Le repli lui-même : un état qui avance preuve par preuve. */
    private final class Accumulateur {

        private final ProgressionStateKey stateKey;
        private final List<LearningEvidence> vues = new ArrayList<>();

        private double sumWeightEpoch;
        private double sumWeightedResultEpoch;
        private double microSumWeightEpoch;
        private double nonMicroSumWeightEpoch;
        private double practicePoints;

        private ProgressionStatus status = ProgressionStatus.NOT_EVALUATED;
        private boolean qualificationGate;
        private boolean transferGate;
        private int visibleProgressMax;
        private boolean visibleProgressVu;
        private Instant derniereContradiction;

        Accumulateur(ProgressionStateKey stateKey) {
            this.stateKey = stateKey;
        }

        void appliquer(LearningEvidence preuve) {
            double storedW = toEpochWeight(baseEffectiveWeight(preuve), preuve.occurredAt());
            sumWeightEpoch += storedW;
            sumWeightedResultEpoch += storedW * preuve.result();
            if (preuve.family() == EvidenceSourceFamily.MICRO) {
                microSumWeightEpoch += storedW;
            } else {
                nonMicroSumWeightEpoch += storedW;
            }
            practicePoints += config.visibleProgress().practicePoints().get(preuve.sourceType());
            vues.add(preuve);

            Instant t = preuve.occurredAt();
            boolean contradiction = estContradictionForte(preuve);
            int contradictions = contradictionsIndependantes(t);
            qualificationGate = stateKey.stateType() == ProgressionStateType.RECEPTIVE_LEVEL
                    && ProgressionGates.receptive(config, vues);
            transferGate = stateKey.stateType() == ProgressionStateType.PRODUCTIVE_SKILL
                    && ProgressionGates.transfer(config, vues);

            status = ProgressionStateMachine.transition(status, stateKey.stateType(), config,
                    masteryScore(), confidenceAt(t), qualificationGate, transferGate,
                    contradiction, contradictions);
            if (contradiction) {
                derniereContradiction = t;
            }
            noterProgressionVisible();
        }

        /** §23.1, §26 — du parcours, jamais de la maîtrise. */
        void appliquerPartielle(PartialPractice partielle) {
            practicePoints += config.visibleProgress().practicePoints().get(partielle.sourceType())
                    * partielle.completionRatio();
        }

        Double masteryScore() {
            return sumWeightEpoch == 0.0d ? null : sumWeightedResultEpoch / sumWeightEpoch;
        }

        /**
         * §11 — la confiance est la <b>masse de preuves</b> ramenée à l'instant
         * demandé, pas le score.
         *
         * <p>Les deux définitions de {@code eligibleEvidenceMassNow} sont
         * normatives et aucune ne se déduit de l'autre (§11.0) : CO/CE prend la
         * masse brute, EE/EO plafonne l'apport des micro-sujets. Appliquer le
         * cap micro à un palier réceptif, ou l'oublier sur une compétence, sont
         * deux fautes symétriques (invariant I37).
         */
        double confidenceAt(Instant instant) {
            double decay = EpochWeights.decayToNow(config, instant);
            double eligible;
            if (stateKey.stateType() == ProgressionStateType.RECEPTIVE_LEVEL) {
                eligible = sumWeightEpoch * decay;
            } else {
                double plafond = config.microEvidenceCaps().maxConfidenceMass();
                eligible = nonMicroSumWeightEpoch * decay
                        + Math.min(microSumWeightEpoch * decay, plafond);
            }
            return Math.min(1.0d, eligible / config.confidenceK().get(stateKey.stateType()));
        }

        /** §15 — une contradiction forte dépend du type d'état, et de la source. */
        private boolean estContradictionForte(LearningEvidence preuve) {
            ProgressionConfig.StrongEvidence fortes =
                    config.strongEvidence().get(stateKey.stateType());
            if (preuve.result() > fortes.negativeResult()) {
                return false;
            }
            return switch (stateKey.stateType()) {
                // Une série UNCALIBRATED ne déclenche jamais seule une
                // contradiction : sa composition n'est pas garantie, son score
                // n'est pas comparable à celui qui a fondé l'acquis.
                case RECEPTIVE_LEVEL -> ProgressionGates.estExamen(preuve.sourceType())
                        || (preuve.sourceType() == EvidenceSourceType.CO_CE_20_SERIES
                            && preuve.calibrationStatus() == CalibrationStatus.CALIBRATED);
                case PRODUCTIVE_SKILL -> ProgressionGates.estPreuveDeTransfert(preuve.sourceType());
            };
        }

        /**
         * §12, §15 — deux contradictions ne comptent pour deux que si elles
         * portent sur un contenu <b>et</b> une tentative différents. Recorriger
         * deux fois la même soumission n'est pas deux mauvaises nouvelles.
         */
        private int contradictionsIndependantes(Instant instant) {
            ProgressionConfig.StrongEvidence fortes =
                    config.strongEvidence().get(stateKey.stateType());
            Instant debut = instant.minus(Duration.ofDays(fortes.windowDays()));
            Set<String> contenus = new HashSet<>();
            Set<String> tentatives = new HashSet<>();
            int compte = 0;
            for (LearningEvidence preuve : vues) {
                if (preuve.occurredAt().isBefore(debut) || !estContradictionForte(preuve)) {
                    continue;
                }
                boolean contenuNeuf = contenus.add(String.valueOf(preuve.contentId()));
                boolean tentativeNeuve = tentatives.add(String.valueOf(preuve.attemptId()));
                if (contenuNeuf && tentativeNeuve) {
                    compte++;
                }
            }
            return compte;
        }

        /**
         * §25 — la progression visible ne redescend jamais dans un cycle.
         *
         * <p>On garde le maximum atteint au fil du repli plutôt que la seule
         * valeur finale : c'est ce qui tient l'invariant I30 même quand une
         * mauvaise séance fait chuter le {@code masteryScore}. Et comme le repli
         * suit l'{@code occurredAt}, ce maximum ne dépend pas de l'ordre
         * d'arrivée — une preuve hors-ligne ne fait jamais « remonter » un
         * pourcentage a posteriori.
         */
        private void noterProgressionVisible() {
            visibleProgressVu = true;
            visibleProgressMax = Math.max(visibleProgressMax, candidat());
        }

        private int candidat() {
            ProgressionConfig.VisibleProgress reglages = config.visibleProgress();
            double couverture = Math.min(1.0d,
                    practicePoints / reglages.practicePointsRequired());
            Double mastery = masteryScore();
            double part = mastery == null ? 0.0d : mastery;
            double brut = 100.0d * (reglages.coverageWeight() * couverture
                    + reglages.masteryWeight() * part);
            return (int) Math.round(Math.min(reglages.unconfirmedCap(), brut));
        }

        ProgressionSnapshot projeter(Instant now) {
            Double mastery = masteryScore();
            double confiance = confidenceAt(now);

            // §16, §18.3 — `directQualification` est une notion PROPRE à CO/CE :
            // c'est elle, et elle seule, qui autorise un palier à satisfaire les
            // prérequis inférieurs. Une compétence de production ne satisfait
            // jamais de prérequis, donc elle ne la porte jamais.
            boolean direct = stateKey.stateType() == ProgressionStateType.RECEPTIVE_LEVEL
                    && status == ProgressionStatus.SOLID
                    && qualificationGate;

            Integer visible;
            if (sumWeightEpoch == 0.0d) {
                // §18.6 — jamais mesuré n'est pas « zéro ». Le candidat n'a pas
                // régressé ; le front n'affichera aucun pourcentage.
                visible = null;
            } else if (confirmeParSonPropreGate()) {
                // §25 — palier ou compétence réellement confirmé : 100, et le
                // cycle suivant repart de zéro. Le gate lu est celui du type
                // d'état : `qualificationGate` en CO/CE, `transferGate` en
                // EE/EO. Confondre les deux laissait une compétence acquise
                // bloquée sous le plafond de 95 %, sans que rien ne la débloque
                // jamais.
                visible = 100;
            } else {
                visible = visibleProgressVu ? visibleProgressMax : null;
            }

            return new ProgressionSnapshot(stateKey, mastery, confiance, status,
                    qualificationGate, transferGate, direct, visible, practicePoints,
                    sumWeightEpoch, sumWeightedResultEpoch, microSumWeightEpoch,
                    nonMicroSumWeightEpoch,
                    ProgressionGates.compteQualifiantes(config, vues),
                    contradictionsRecentesA(now), levelCycleId());
        }

        /** L'état est-il confirmé par le gate de SON type (§14.4, §14.5) ? */
        private boolean confirmeParSonPropreGate() {
            if (status != ProgressionStatus.SOLID) {
                return false;
            }
            return stateKey.stateType() == ProgressionStateType.RECEPTIVE_LEVEL
                    ? qualificationGate
                    : transferGate;
        }

        private int contradictionsRecentesA(Instant now) {
            return derniereContradiction == null ? 0 : contradictionsIndependantes(now);
        }

        /**
         * §25, §35 — un cycle par palier : passer au niveau suivant, c'est
         * repartir d'une progression visible à zéro, et le 100 % du palier
         * précédent reste dans l'historique.
         */
        private String levelCycleId() {
            return stateKey.asText() + "#1";
        }
    }
}
