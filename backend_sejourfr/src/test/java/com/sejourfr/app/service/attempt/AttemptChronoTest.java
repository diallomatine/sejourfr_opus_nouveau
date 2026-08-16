package com.sejourfr.app.service.attempt;

import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.enums.EpreuveType;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.Instant;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Verrouille l'ancre du chrono d'une session — la subtilité qui a produit le
 * bug « la CE n'avait que 10 min » : les 4 sous-attempts d'un examen complet
 * sont créés d'un bloc, donc leur {@code started_at} ne dit rien du moment où
 * le candidat ouvre l'épreuve.
 */
class AttemptChronoTest {

    private static final Instant T0 = Instant.parse("2026-08-15T09:00:00Z");

    private static Attempt session(EpreuveType epreuve, Integer limite) {
        Attempt a = new Attempt();
        a.setEpreuve(epreuve);
        a.setStartedAt(T0);
        a.setTimeLimitSeconds(limite);
        return a;
    }

    private static Attempt sousEpreuve(EpreuveType epreuve, Integer limite) {
        Attempt parent = new Attempt();
        parent.setEpreuve(EpreuveType.TCF_COMPLET);
        Attempt a = session(epreuve, limite);
        a.setParentAttempt(parent);
        return a;
    }

    @Test
    @DisplayName("Session isolee : l'ancre est started_at")
    void sessionIsolee() {
        Attempt a = session(EpreuveType.TCF_CE, 2100);

        assertThat(AttemptChrono.ancre(a)).isEqualTo(T0);
        assertThat(AttemptChrono.echeance(a)).isEqualTo(T0.plusSeconds(2100));
        assertThat(AttemptChrono.echeanceAvecGrace(a)).isEqualTo(T0.plusSeconds(2160));
    }

    @Test
    @DisplayName("Sous-epreuve d'examen complet non lancee : AUCUNE echeance")
    void sousEpreuveNonLancee() {
        Attempt a = sousEpreuve(EpreuveType.TCF_CE, 2100);

        assertThat(AttemptChrono.ancre(a)).isNull();
        assertThat(AttemptChrono.echeance(a)).isNull();
        // Sans cette règle, la CE d'un examen complet aurait expiré pendant que
        // le candidat passait encore la CO.
        assertThat(AttemptChrono.horsDelai(a, T0.plusSeconds(100_000))).isFalse();
    }

    @Test
    @DisplayName("Sous-epreuve lancee : l'ancre est timer_started_at")
    void sousEpreuveLancee() {
        Attempt a = sousEpreuve(EpreuveType.TCF_CE, 2100);
        Instant lancement = T0.plusSeconds(1300);
        a.setTimerStartedAt(lancement);

        assertThat(AttemptChrono.ancre(a)).isEqualTo(lancement);
        assertThat(AttemptChrono.echeance(a)).isEqualTo(lancement.plusSeconds(2100));
    }

    @Test
    @DisplayName("timer_started_at l'emporte aussi sur une session isolee")
    void timerStartedAtPrioritaire() {
        Attempt a = session(EpreuveType.TCF_CO, 1200);
        a.setTimerStartedAt(T0.plusSeconds(600));

        assertThat(AttemptChrono.ancre(a)).isEqualTo(T0.plusSeconds(600));
    }

    @Test
    @DisplayName("Pas de time_limit : pas d'echeance, jamais hors delai")
    void sansChrono() {
        Attempt libre = session(EpreuveType.TCF_EO, null);

        assertThat(AttemptChrono.echeance(libre)).isNull();
        assertThat(AttemptChrono.echeanceAvecGrace(libre)).isNull();
        assertThat(AttemptChrono.horsDelai(libre, T0.plusSeconds(1_000_000))).isFalse();
    }

    @Test
    @DisplayName("La grace couvre l'auto-soumission de 0:00, pas une minute de plus")
    void grace() {
        Attempt a = session(EpreuveType.TCF_CO, 1200);

        assertThat(AttemptChrono.horsDelai(a, T0.plusSeconds(1200))).isFalse();
        assertThat(AttemptChrono.horsDelai(a, T0.plusSeconds(1259))).isFalse();
        assertThat(AttemptChrono.horsDelai(a, T0.plusSeconds(1261))).isTrue();
    }

    @Test
    @DisplayName("Null-safe")
    void nullSafe() {
        assertThat(AttemptChrono.ancre(null)).isNull();
        assertThat(AttemptChrono.echeance(null)).isNull();
        assertThat(AttemptChrono.horsDelai(null, T0)).isFalse();
    }
}
