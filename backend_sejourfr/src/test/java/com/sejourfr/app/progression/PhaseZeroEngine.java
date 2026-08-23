package com.sejourfr.app.progression;

import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.progression.domain.DomainProjection;
import com.sejourfr.app.progression.domain.LearningEvidence;
import com.sejourfr.app.progression.domain.ProgressionSnapshot;
import com.sejourfr.app.progression.domain.ProgressionStateKey;
import com.sejourfr.app.progression.engine.ProgressionEngine;

import java.time.Instant;
import java.util.Collection;

/**
 * <b>Le moteur qui n'existe pas encore.</b>
 *
 * <p>La phase 0 impose d'ecrire T01–T36 <i>avant</i> le moteur (§49). Ce stub
 * est ce qui permet a la suite d'acceptation de compiler et de rester lisible
 * en revue, sans qu'aucune ligne de moteur ne soit ecrite en avance : chaque
 * appel echoue bruyamment.
 *
 * <p>🛑 <b>Il ne doit jamais recevoir de « juste assez » d'implementation pour
 * faire verdir un test.</b> Le jour ou la phase 1 demarre, on branche le vrai
 * moteur dans {@code ProgressionEngineAcceptanceTest} et on supprime ce
 * fichier — on ne le fait pas grandir.
 */
final class PhaseZeroEngine implements ProgressionEngine {

    static ProgressionEngine pending() {
        return new PhaseZeroEngine();
    }

    private PhaseZeroEngine() {
    }

    @Override
    public double chanceAdjustedResult(int correctAnswers, int totalQuestions,
                                       double meanGuessRate) {
        throw pendingPhaseOne();
    }

    @Override
    public double baseEffectiveWeight(LearningEvidence evidence) {
        throw pendingPhaseOne();
    }

    @Override
    public double toEpochWeight(double baseWeight, Instant occurredAt) {
        throw pendingPhaseOne();
    }

    @Override
    public ProgressionSnapshot project(ProgressionStateKey stateKey,
                                       Collection<LearningEvidence> evidence, Instant now) {
        throw pendingPhaseOne();
    }

    @Override
    public DomainProjection projectDomain(SkillSection section, TargetLevel objectiveLevel,
                                          Collection<LearningEvidence> evidence, Instant now) {
        throw pendingPhaseOne();
    }

    private static UnsupportedOperationException pendingPhaseOne() {
        return new UnsupportedOperationException(
                "Moteur de progression non implémenté — phase 1 (V4.2 §49)");
    }
}
