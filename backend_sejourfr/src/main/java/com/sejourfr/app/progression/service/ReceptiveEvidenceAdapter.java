package com.sejourfr.app.progression.service;

import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.progression.config.ProgressionConfig;
import com.sejourfr.app.progression.config.ProgressionProperties;
import com.sejourfr.app.progression.domain.AssistanceLevel;
import com.sejourfr.app.progression.domain.AttemptCompletionStatus;
import com.sejourfr.app.progression.domain.CalibrationStatus;
import com.sejourfr.app.progression.domain.EvidenceEntryPoint;
import com.sejourfr.app.progression.domain.EvidenceSourceType;
import com.sejourfr.app.progression.domain.IndependenceClass;
import com.sejourfr.app.progression.domain.LearningEvidence;
import com.sejourfr.app.progression.domain.PartialPractice;
import com.sejourfr.app.progression.domain.ProgressionStateKey;
import com.sejourfr.app.progression.engine.ProgressionEngine;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.ArrayList;
import java.util.EnumMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * <b>Ce qui transforme une session CO/CE terminée en preuves</b> (V4.2 §6, §23).
 *
 * <p>Deux décisions portent presque tout ce fichier.
 *
 * <h2>1. Le hasard est corrigé, et le score affiché ne bouge pas</h2>
 *
 * <p>16/20 à quatre propositions, c'est 80 % brut mais 73,3 % une fois retiré ce
 * qu'un candidat obtiendrait en cochant au hasard. Le moteur agrège la seconde
 * valeur ; le candidat continue de lire {@code 16/20} (§6.1). Sans cette
 * correction, une série à trois propositions et une série à quatre ne seraient
 * pas comparables, et le moteur validerait un palier en récompensant le format
 * de la question.
 *
 * <p>🛑 <b>Le dénominateur est toujours {@code totalQuestions}</b>, jamais le
 * nombre de questions répondues (invariants I6, I8). Sur une tentative rendue ou
 * expirée, ne pas répondre est une réponse fausse.
 *
 * <h2>2. Une session produit une preuve <i>par palier réellement mesuré</i></h2>
 *
 * <p>Un examen blanc tire des questions A2, B1 et B2. Le réduire à un unique
 * niveau opaque jetterait l'information la plus utile qu'il contient (§6.4). On
 * ventile donc par niveau de question, et chaque palier reçoit sa propre
 * mesure — ce qui permet, plus tard, qu'un B1 directement acquis satisfasse le
 * prérequis A2 sans qu'on ait jamais inventé de preuve A2.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ReceptiveEvidenceAdapter {

    /** Le minimum de questions d'un palier pour que sa mesure veuille dire quelque chose. */
    private static final int QUESTIONS_MINIMALES_PAR_PALIER = 3;

    private final ProgressionConfig config;
    private final ProgressionProperties properties;
    private final ProgressionEngine engine;
    private final ProgressionIngestionService ingestionService;
    private final ContentIdentityService contentIdentityService;

    /**
     * Une réponse de la session, réduite à ce qui entre dans le calcul.
     *
     * <p><b>Valeurs, pas entités</b> : l'appelant les extrait dans sa propre
     * transaction, où tout est déjà chargé. Rien de détaché ne traverse la
     * frontière {@code REQUIRES_NEW}.
     *
     * @param optionsCount le nombre de propositions de <i>cette</i> question —
     *                     le taux de hasard est une moyenne par question, pas
     *                     une constante 0,25 (§6.1).
     */
    public record ReponseQcm(
            UUID questionId,
            QuestionType questionType,
            Difficulty difficulty,
            int optionsCount,
            boolean answered,
            boolean correct
    ) {}

    /**
     * Enregistre ce qu'une session CO/CE terminée prouve.
     *
     * <p><b>Best-effort, jamais bloquant</b>, dans sa propre transaction — même
     * doctrine que {@code ComprehensionObservationService} : rien de ce qui
     * alimente la progression ne doit pouvoir faire échouer la correction d'une
     * session ni la réponse HTTP au candidat.
     *
     * @return le nombre de preuves écrites (0 est un cas normal : session
     *         civique, session STRUCTURE, ou session déjà ingérée)
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public int ingerer(UUID userId, UUID attemptId, Instant occurredAt,
                       AttemptCompletionStatus completion, EvidenceSourceType sourceType,
                       EvidenceEntryPoint entryPoint, List<ReponseQcm> reponses) {
        if (userId == null || reponses.isEmpty()) {
            return 0;
        }

        Map<SkillSection, List<ReponseQcm>> parDomaine = ventilerParDomaine(reponses);
        if (parDomaine.isEmpty()) {
            return 0;
        }

        if (!completion.emitsMasteryEvidence()) {
            // §23.1 à §23.3 — abandon, série laissée en cours, coupure
            // technique : aucune preuve de maîtrise. Le candidat a travaillé,
            // il n'a pas échoué. Seuls des points de parcours au prorata.
            enregistrerPratiquePartielle(userId, sourceType, parDomaine);
            return 0;
        }

        int ecrites = 0;
        for (Map.Entry<SkillSection, List<ReponseQcm>> domaine : parDomaine.entrySet()) {
            for (Map.Entry<TargetLevel, List<ReponseQcm>> palier
                    : ventilerParNiveau(domaine.getValue()).entrySet()) {
                if (palier.getValue().size() < QUESTIONS_MINIMALES_PAR_PALIER) {
                    continue;
                }
                if (ingererPalier(userId, attemptId, occurredAt, sourceType, entryPoint,
                        domaine.getKey(), palier.getKey(), palier.getValue())) {
                    ecrites++;
                }
            }
        }
        return ecrites;
    }

    private boolean ingererPalier(UUID userId, UUID attemptId, Instant occurredAt,
                                  EvidenceSourceType sourceType, EvidenceEntryPoint entryPoint,
                                  SkillSection section, TargetLevel level,
                                  List<ReponseQcm> reponses) {
        int total = reponses.size();
        int correctes = (int) reponses.stream().filter(ReponseQcm::correct).count();
        double tauxDeHasard = reponses.stream()
                .mapToDouble(r -> 1.0d / Math.max(2, r.optionsCount()))
                .average()
                .orElse(0.25d);
        double result = engine.chanceAdjustedResult(correctes, total, tauxDeHasard);

        List<UUID> questionIds = reponses.stream().map(ReponseQcm::questionId).toList();
        CalibrationStatus calibration = calibration(sourceType, reponses);
        EvidenceSourceType sourceEffective = sourceEffective(sourceType, calibration);

        String contentId = contentIdentityService.contentIdDeSerie(questionIds);
        IndependenceClass independance = independance(
                userId, sourceEffective, section, level, questionIds, contentId, occurredAt);

        LearningEvidence preuve = LearningEvidence.builder()
                .userId(userId)
                .attemptId(attemptId)
                .occurredAt(occurredAt)
                .ingestedAt(Instant.now())
                .entryPoint(entryPoint)
                .sourceType(sourceEffective)
                .section(section)
                .level(level)
                // §6.1 — la correction du hasard est interne au moteur. Elle ne
                // remplace ni le score TCF affiché, ni les statistiques brutes.
                .result(result)
                // Une correction QCM est entièrement déterministe : il n'y a
                // aucune incertitude de notation à déclarer.
                .scoringConfidence(1.0d)
                .assistanceLevel(AssistanceLevel.NONE)
                .contentId(contentId)
                .calibrationStatus(calibration)
                .independenceClass(independance)
                .engineVersionAtCreation(properties.getEngineVersion())
                .metadata(new LinkedHashMap<>(Map.of(
                        "questionIds", questionIds.stream().map(UUID::toString).toList(),
                        "correct", correctes,
                        "total", total,
                        "rawAccuracy", (double) correctes / total)))
                .build();

        return ingestionService.ingerer(preuve).isPresent();
    }

    /**
     * §23.1 — l'activité laissée en cours donne des points au prorata.
     *
     * <p>On les rattache au palier le plus représenté dans ce qu'il a
     * effectivement travaillé : il n'y a pas de preuve à ventiler, seulement de
     * l'effort à reconnaître.
     */
    private void enregistrerPratiquePartielle(UUID userId, EvidenceSourceType sourceType,
                                              Map<SkillSection, List<ReponseQcm>> parDomaine) {
        for (Map.Entry<SkillSection, List<ReponseQcm>> domaine : parDomaine.entrySet()) {
            Map<TargetLevel, List<ReponseQcm>> parNiveau = ventilerParNiveau(domaine.getValue());
            parNiveau.entrySet().stream()
                    .max(Map.Entry.comparingByValue(
                            (a, b) -> Integer.compare(a.size(), b.size())))
                    .ifPresent(dominant -> {
                        long repondues = domaine.getValue().stream()
                                .filter(ReponseQcm::answered).count();
                        ingestionService.ingererPratiquePartielle(userId, new PartialPractice(
                                ProgressionStateKey.receptive(domaine.getKey(), dominant.getKey()),
                                sourceType, (int) repondues,
                                Math.max(1, domaine.getValue().size()), Instant.now()));
                    });
        }
    }

    /**
     * §6.2, §7 — la série respecte-t-elle le blueprint 6 EASY / 10 MEDIUM /
     * 4 HARD sur 20 questions ?
     *
     * <p>Tant que le catalogue ne porte pas de {@code difficultyBand} (phase 4),
     * <b>aucune série d'entraînement n'est calibrée</b> : elles pèsent 0,50 au
     * lieu de 0,70 et ne peuvent jamais verrouiller un palier. C'est le choix
     * prudent — l'inverse validerait des paliers sur des séries dont on ignore
     * la composition, et il faudrait ensuite les retirer aux candidats.
     *
     * <p>Les examens blancs, eux, ont leurs strates garanties à la composition
     * (8 A2 + 9 B1 + 8 B2 par épreuve) : ils sont calibrés par construction.
     */
    private CalibrationStatus calibration(EvidenceSourceType sourceType,
                                          List<ReponseQcm> reponses) {
        if (sourceType == EvidenceSourceType.DOMAIN_MOCK
                || sourceType == EvidenceSourceType.FULL_MOCK_EXAM
                || sourceType == EvidenceSourceType.DIAGNOSTIC) {
            return CalibrationStatus.CALIBRATED;
        }
        return CalibrationStatus.UNCALIBRATED;
    }

    /** Une série non calibrée porte son propre {@code sourceType} (§6.3). */
    private EvidenceSourceType sourceEffective(EvidenceSourceType demande,
                                               CalibrationStatus calibration) {
        if (demande == EvidenceSourceType.CO_CE_20_SERIES
                && calibration == CalibrationStatus.UNCALIBRATED) {
            return EvidenceSourceType.CO_CE_20_SERIES_UNCALIBRATED;
        }
        return demande;
    }

    /**
     * §12 bis — le recouvrement d'items ne se calcule que pour les séries.
     *
     * <p>Un examen blanc a son propre contenu, tiré d'un gabarit : le
     * recouvrement n'y a pas de sens, et §16 Cas A ne s'appuie de toute façon
     * que sur son résultat.
     */
    private IndependenceClass independance(UUID userId, EvidenceSourceType sourceType,
                                           SkillSection section, TargetLevel level,
                                           List<UUID> questionIds, String contentId,
                                           Instant occurredAt) {
        boolean estUneSerie = sourceType == EvidenceSourceType.CO_CE_20_SERIES
                || sourceType == EvidenceSourceType.CO_CE_20_SERIES_UNCALIBRATED;
        if (!estUneSerie) {
            return IndependenceClass.NEW_CONTENT;
        }
        return contentIdentityService.classerSerie(
                userId, section, level, questionIds, contentId, occurredAt);
    }

    /** CO et CE évoluent indépendamment : on ne mélange jamais leurs réponses. */
    private Map<SkillSection, List<ReponseQcm>> ventilerParDomaine(List<ReponseQcm> reponses) {
        Map<SkillSection, List<ReponseQcm>> parDomaine = new EnumMap<>(SkillSection.class);
        for (ReponseQcm reponse : reponses) {
            SkillSection section = switch (reponse.questionType()) {
                case CO, CO_IMAGE -> SkillSection.CO;
                case CE -> SkillSection.CE;
                // CONNAISSANCE / MISE_SITUATION : civique, hors périmètre du
                // moteur TCF. STRUCTURE n'a pas de palier CECRL propre.
                default -> null;
            };
            if (section != null) {
                parDomaine.computeIfAbsent(section, k -> new ArrayList<>()).add(reponse);
            }
        }
        return parDomaine;
    }

    /**
     * §6.4 — une preuve par palier réellement mesuré.
     *
     * <p>Une question sans niveau CECRL (difficulté civique, ou pas encore
     * taguée) est <b>ignorée</b>, pas rangée par défaut dans un palier :
     * l'affecter arbitrairement à A2 fabriquerait une mesure qui n'a pas eu
     * lieu. Absent n'est pas mauvais.
     */
    private Map<TargetLevel, List<ReponseQcm>> ventilerParNiveau(List<ReponseQcm> reponses) {
        Map<TargetLevel, List<ReponseQcm>> parNiveau = new EnumMap<>(TargetLevel.class);
        for (ReponseQcm reponse : reponses) {
            TargetLevel niveau = switch (reponse.difficulty()) {
                case A2 -> TargetLevel.A2;
                case B1 -> TargetLevel.B1;
                case B2 -> TargetLevel.B2;
                case null, default -> null;
            };
            if (niveau != null) {
                parNiveau.computeIfAbsent(niveau, k -> new ArrayList<>()).add(reponse);
            }
        }
        return parNiveau;
    }
}
