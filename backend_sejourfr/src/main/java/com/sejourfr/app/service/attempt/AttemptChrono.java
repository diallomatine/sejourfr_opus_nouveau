package com.sejourfr.app.service.attempt;

import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.enums.DureeEpreuve;

import java.time.Instant;

/**
 * <b>Autorité unique de l'échéance d'une session.</b> Répond à deux questions,
 * et à elles seules : « quand cette épreuve expire-t-elle ? » et « est-ce déjà
 * passé ? ». Pure, sans état — le chiffre des durées vit dans
 * {@link DureeEpreuve}, l'ancre vit ici.
 *
 * <p><b>L'ancre dépend du contexte</b>, et c'est la seule subtilité :
 * <ul>
 *   <li><b>Sous-épreuve d'un examen blanc TCF complet</b> (parent non null) :
 *       les 4 sous-attempts sont créés d'un coup au lancement de l'examen,
 *       donc {@code started_at} ne dit rien du moment où le candidat ouvre
 *       l'épreuve. Seul {@code timer_started_at}, posé par
 *       {@code FullTcfExamService.beginEpreuve}, fait foi : tant qu'il est
 *       null, <b>l'épreuve n'a pas d'échéance</b> — elle n'a pas commencé.
 *       Sans cette règle, la CE (35 min) aurait expiré pendant la CO.</li>
 *   <li><b>Session isolée</b> (examen module CO/CE/STRUCTURE, examen civique,
 *       session d'examen EE) : {@code started_at} est le vrai début, et
 *       {@code timer_started_at} l'emporte s'il a été posé.</li>
 * </ul>
 *
 * <p>Le temps restant d'une épreuve ne se transfère <b>jamais</b> à la
 * suivante, et quitter ne suspend rien : l'échéance est absolue, calculée une
 * fois pour toutes depuis l'ancre.
 */
public final class AttemptChrono {

    private AttemptChrono() {
    }

    /**
     * Instant à partir duquel le chrono de cette session court, ou {@code null}
     * si elle n'a pas encore été lancée (cf. javadoc de classe).
     */
    public static Instant ancre(Attempt attempt) {
        if (attempt == null) return null;
        if (attempt.getTimerStartedAt() != null) return attempt.getTimerStartedAt();
        if (attempt.getParentAttempt() != null) return null;
        return attempt.getStartedAt();
    }

    /**
     * Échéance de l'épreuve, ou {@code null} quand elle n'en a pas : session
     * sans {@code time_limit_seconds} (entraînement libre, expression orale —
     * dont le temps se compte par tâche), ou épreuve d'examen complet pas
     * encore lancée.
     */
    public static Instant echeance(Attempt attempt) {
        if (attempt == null || attempt.getTimeLimitSeconds() == null) return null;
        Instant ancre = ancre(attempt);
        return ancre == null ? null : ancre.plusSeconds(attempt.getTimeLimitSeconds());
    }

    /** Échéance + la grâce de {@value DureeEpreuve#GRACE_SOUMISSION_SECONDS} s. */
    public static Instant echeanceAvecGrace(Attempt attempt) {
        Instant echeance = echeance(attempt);
        return echeance == null
                ? null
                : echeance.plusSeconds(DureeEpreuve.GRACE_SOUMISSION_SECONDS);
    }

    /**
     * Le délai (grâce comprise) est-il dépassé ? {@code false} quand l'épreuve
     * n'a pas d'échéance — une absence de chrono n'est jamais une expiration.
     */
    public static boolean horsDelai(Attempt attempt, Instant maintenant) {
        Instant limite = echeanceAvecGrace(attempt);
        return limite != null && maintenant.isAfter(limite);
    }
}
