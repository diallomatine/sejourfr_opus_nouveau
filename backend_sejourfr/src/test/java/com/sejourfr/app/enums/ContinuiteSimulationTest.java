package com.sejourfr.app.enums;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.Duration;
import java.time.Instant;
import java.util.Arrays;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Gèle les libellés FR de {@link ContinuiteSimulation} et sa règle de
 * dérivation. Même contrat que {@code SkillLabelsTest} : ces chaînes ne
 * transitent pas par le réseau, chaque front en tient une copie écrite à la
 * main — un libellé qui bouge ici, ce sont trois miroirs à changer dans la
 * même passe.
 */
class ContinuiteSimulationTest {

    private static final Instant T0 = Instant.parse("2026-08-15T09:00:00Z");

    @Test
    @DisplayName("Libelles FR geles — contrat mirore sur les 3 fronts")
    void libellesGeles() {
        assertThat(ContinuiteSimulation.SESSION_UNIQUE.getLabel())
                .isEqualTo("Simulation complète — conditions examen");
        assertThat(ContinuiteSimulation.PLUSIEURS_SESSIONS.getLabel())
                .isEqualTo("Simulation complétée en plusieurs sessions");
    }

    @Test
    @DisplayName("Deux valeurs, pas trois : le cas « bilan partiel » vit dans finalLevelPartial")
    void deuxValeursSeulement() {
        assertThat(ContinuiteSimulation.values()).hasSize(2);
    }

    @Test
    @DisplayName("Epreuves enchainees sans pause notable : simulation d'une traite")
    void enchaineDuneTraite() {
        assertThat(ContinuiteSimulation.of(etapes(
                0, 20,
                21, 56,
                58, 88,
                90, 100)))
                .isEqualTo(ContinuiteSimulation.SESSION_UNIQUE);
    }

    @Test
    @DisplayName("Une pause de quelques minutes ne declasse pas la simulation")
    void petitePauseToleree() {
        // 14 min entre la fin de la CO et le lancement de la CE : installation,
        // relecture du briefing, reconnexion réseau.
        assertThat(ContinuiteSimulation.of(etapes(
                0, 20,
                34, 69)))
                .isEqualTo(ContinuiteSimulation.SESSION_UNIQUE);
    }

    @Test
    @DisplayName("Au-dela du seuil, le candidat a quitte et repris")
    void grandePauseDeclasse() {
        assertThat(ContinuiteSimulation.of(etapes(
                0, 20,
                36, 71)))
                .isEqualTo(ContinuiteSimulation.PLUSIEURS_SESSIONS);
    }

    @Test
    @DisplayName("Le seuil vaut 15 min et rien d'autre ne le pilote")
    void seuilExplicite() {
        assertThat(ContinuiteSimulation.PAUSE_MAX_ENTRE_EPREUVES)
                .isEqualTo(Duration.ofMinutes(15));
    }

    @Test
    @DisplayName("Une reprise le lendemain est une autre session")
    void repriseLeLendemain() {
        List<ContinuiteSimulation.Etape> etapes = List.of(
                new ContinuiteSimulation.Etape(T0, T0.plus(Duration.ofMinutes(20))),
                new ContinuiteSimulation.Etape(
                        T0.plus(Duration.ofDays(1)), T0.plus(Duration.ofDays(1)).plusSeconds(2100)));

        assertThat(ContinuiteSimulation.of(etapes))
                .isEqualTo(ContinuiteSimulation.PLUSIEURS_SESSIONS);
    }

    @Test
    @DisplayName("Une epreuve jamais lancee (verrouillee) ne declasse rien")
    void epreuveJamaisLanceeIgnoree() {
        // EE/EO verrouillées par le freemium : pré-terminées, sans début connu.
        // Une donnée absente n'est pas la preuve d'une interruption.
        List<ContinuiteSimulation.Etape> etapes = List.of(
                new ContinuiteSimulation.Etape(T0, T0.plus(Duration.ofMinutes(20))),
                new ContinuiteSimulation.Etape(
                        T0.plus(Duration.ofMinutes(21)), T0.plus(Duration.ofMinutes(56))),
                new ContinuiteSimulation.Etape(null, T0),
                new ContinuiteSimulation.Etape(null, T0));

        assertThat(ContinuiteSimulation.of(etapes))
                .isEqualTo(ContinuiteSimulation.SESSION_UNIQUE);
    }

    @Test
    @DisplayName("Liste vide ou nulle : rien ne contredit la traite")
    void listeVide() {
        assertThat(ContinuiteSimulation.of(null)).isEqualTo(ContinuiteSimulation.SESSION_UNIQUE);
        assertThat(ContinuiteSimulation.of(List.of())).isEqualTo(ContinuiteSimulation.SESSION_UNIQUE);
        assertThat(ContinuiteSimulation.of(Arrays.asList((ContinuiteSimulation.Etape) null)))
                .isEqualTo(ContinuiteSimulation.SESSION_UNIQUE);
    }

    /** Suite d'étapes déclarées en minutes depuis {@link #T0} : début, fin, début, fin… */
    private static List<ContinuiteSimulation.Etape> etapes(int... minutes) {
        return java.util.stream.IntStream.range(0, minutes.length / 2)
                .mapToObj(i -> new ContinuiteSimulation.Etape(
                        T0.plus(Duration.ofMinutes(minutes[2 * i])),
                        T0.plus(Duration.ofMinutes(minutes[2 * i + 1]))))
                .toList();
    }
}
