package com.sejourfr.app.progression.engine;

import com.sejourfr.app.progression.config.ProgressionConfig;

import java.time.Duration;
import java.time.Instant;

/**
 * <b>Le changement de repère qui rend l'agrégation commutative</b> (V4.2 §10).
 *
 * <p>Un poids n'est jamais stocké « tel qu'il vaut aujourd'hui » : il est stocké
 * dans le référentiel de l'epoch, {@code baseW × exp(lambda × joursDepuisEpoch)}.
 * La préférence de récence est alors <b>déjà dedans</b> — une preuve plus récente
 * reçoit mécaniquement un poids stocké plus grand — et l'écriture n'applique
 * aucun decay.
 *
 * <p>C'est ce qui donne les invariants I9 et I10 : {@code apply(A); apply(B)} et
 * {@code apply(B); apply(A)} produisent le même agrégat, à l'erreur flottante
 * près. Une preuve hors-ligne qui arrive trois jours plus tard atterrit au bon
 * endroit sans qu'on ait rien à rejouer.
 *
 * <p>🛑 <b>Il est donc interdit d'appeler un {@code decayStateTo(state, date)}
 * sur le chemin d'ingestion.</b> Le decay ne s'applique qu'à la lecture, une
 * fois, sur la masse totale.
 *
 * <p>Corollaire numérique (§27.2.1) : ces accumulateurs croissent
 * exponentiellement — de l'ordre de {@code 2.6e24} à J+3650 — d'où le
 * {@code double precision} obligatoire en base et le re-basage périodique de
 * l'epoch.
 */
public final class EpochWeights {

    private EpochWeights() {
    }

    /**
     * Le nombre de jours entre deux instants, <b>en fractionnaire</b>.
     *
     * <p>Arrondir au jour entier casserait la commutativité exacte que T11
     * vérifie à {@code 1e-12} : deux preuves du même jour à des heures
     * différentes doivent garder leur écart réel.
     */
    public static double daysBetween(Instant from, Instant to) {
        return (double) Duration.between(from, to).toNanos() / Duration.ofDays(1).toNanos();
    }

    /** {@code storedW = baseW × exp(lambda × joursDepuisEpoch)} (§10). */
    public static double toEpochWeight(ProgressionConfig config, double baseWeight,
                                       Instant occurredAt) {
        double daysFromEpoch = daysBetween(config.weightEpoch(), occurredAt);
        return baseWeight * Math.exp(config.lambda() * daysFromEpoch);
    }

    /**
     * Le facteur qui ramène une masse epoch à l'instant {@code t} (§11) :
     * {@code exp(-lambda × joursDepuisEpoch(t))}.
     */
    public static double decayToNow(ProgressionConfig config, Instant now) {
        return Math.exp(-config.lambda() * daysBetween(config.weightEpoch(), now));
    }
}
