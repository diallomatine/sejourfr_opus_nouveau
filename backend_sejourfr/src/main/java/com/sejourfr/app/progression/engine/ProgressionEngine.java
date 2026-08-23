package com.sejourfr.app.progression.engine;

import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.progression.domain.DomainProjection;
import com.sejourfr.app.progression.domain.LearningEvidence;
import com.sejourfr.app.progression.domain.PartialPractice;
import com.sejourfr.app.progression.domain.ProgressionSnapshot;
import com.sejourfr.app.progression.domain.ProgressionStateKey;

import java.time.Instant;
import java.util.Collection;

/**
 * <b>Le contrat du moteur de progression V4.2</b> — ecrit avant son
 * implementation, parce que ce sont les tests d'acceptation T01–T36 qui
 * definissent le moteur, pas l'inverse (§49, phase 0).
 *
 * <p>Tout y est <b>pur</b> : meme multiensemble de preuves + meme config + meme
 * {@code now} = meme projection (invariant I10). Aucune methode ne depend de
 * l'ordre dans lequel les preuves arrivent (invariant I9) — c'est ce qui rend le
 * moteur offline-safe et rejouable.
 *
 * <p>Ce que le moteur ne fait pas, volontairement : il ne persiste rien, il ne
 * lit aucun repository, et il n'appelle jamais {@code decayStateTo(...)} sur le
 * chemin d'ingestion (§10).
 */
public interface ProgressionEngine {

    /**
     * Le {@code result} corrige du hasard d'un QCM (§6.1).
     *
     * <p>🛑 <b>Le denominateur est toujours {@code totalQuestions}</b>, jamais
     * {@code answeredCount} (invariants I6, I8) : sur une tentative rendue ou
     * expiree, les questions non repondues comptent fausses.
     *
     * <p>Cette correction est <b>interne au moteur</b>. Le score montre au
     * candidat reste {@code 16/20} : elle ne remplace ni les scores TCF
     * affiches, ni les statistiques brutes (§6.1).
     *
     * @param meanGuessRate moyenne de {@code 1 / numberOfOptions(q)} sur les
     *                      questions de la preuve — c'est bien une moyenne par
     *                      question, pas une constante 0.25.
     */
    double chanceAdjustedResult(int correctAnswers, int totalQuestions, double meanGuessRate);

    /**
     * Le poids d'une preuve hors recence (§8.2) :
     * {@code sourceWeight × scoringConfidence × assistanceFactor ×
     * independenceFactor}.
     *
     * <p>Aucun plancher : une preuve tres assistee doit reellement peser moins.
     */
    double baseEffectiveWeight(LearningEvidence evidence);

    /**
     * Le poids stocke, exprime dans le referentiel de l'epoch (§10) :
     * {@code baseW × exp(lambda × daysFromEpoch)}.
     *
     * <p>C'est ce changement de repere qui rend l'agregation commutative — la
     * preference de recence est deja dedans, et aucun decay n'est applique a
     * l'ecriture.
     */
    double toEpochWeight(double baseWeight, Instant occurredAt);

    /**
     * L'etat d'une cle, projete a l'instant {@code now} depuis l'ensemble de ses
     * preuves.
     *
     * <p>La collection est un <b>multiensemble</b> : son ordre d'iteration ne
     * doit avoir aucun effet sur le resultat (T11). Les doublons de cle
     * naturelle sont ignores, pas additionnes (T12).
     *
     * @param partialPractice les activites laissees en cours (§23.1) : elles
     *                        n'apportent que des points de parcours.
     */
    ProgressionSnapshot project(
            ProgressionStateKey stateKey,
            Collection<LearningEvidence> evidence,
            Collection<PartialPractice> partialPractice,
            Instant now);

    /** La forme courante : aucune activité laissée en cours à comptabiliser. */
    default ProgressionSnapshot project(
            ProgressionStateKey stateKey,
            Collection<LearningEvidence> evidence,
            Instant now) {
        return project(stateKey, evidence, java.util.List.of(), now);
    }

    /**
     * La lecture complete d'un domaine receptif : les trois paliers, les
     * prerequis derives, {@code activeLearningLevel} et {@code prescriptionLevel}
     * (§18, §19).
     */
    DomainProjection projectDomain(
            SkillSection section,
            TargetLevel objectiveLevel,
            Collection<LearningEvidence> evidence,
            Instant now);
}
