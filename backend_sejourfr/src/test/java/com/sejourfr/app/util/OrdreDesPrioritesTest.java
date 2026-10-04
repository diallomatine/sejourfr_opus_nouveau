package com.sejourfr.app.util;

import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.ObservationConfidence;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * L'ordre des fragilites, ecrit une seule fois (AR-3) : statut, confiance,
 * recence, rang editorial, code — dans cet ordre de priorite, chaque critere ne
 * jouant qu'a egalite des precedents.
 */
class OrdreDesPrioritesTest {

    private static final Instant T0 = Instant.parse("2026-10-04T10:00:00Z");

    @Test
    @DisplayName("PRIORITY passe devant TO_REINFORCE, quelle que soit la confiance")
    void leStatutDAbord() {
        var renforcer = observation("EE1-C1", 1, LearningPlanSkillStatus.TO_REINFORCE,
                ObservationConfidence.HIGH, T0);
        var priorite = observation("EE1-C2", 2, LearningPlanSkillStatus.PRIORITY,
                ObservationConfidence.LOW, T0);

        assertThat(trie(renforcer, priorite)).containsExactly("EE1-C2", "EE1-C1");
    }

    @Test
    @DisplayName("À statut égal, la confiance la mieux établie d'abord")
    void puisLaConfiance() {
        var basse = observation("EE1-C1", 1, LearningPlanSkillStatus.TO_REINFORCE,
                ObservationConfidence.LOW, T0);
        var haute = observation("EE1-C2", 2, LearningPlanSkillStatus.TO_REINFORCE,
                ObservationConfidence.HIGH, T0);

        assertThat(trie(basse, haute)).containsExactly("EE1-C2", "EE1-C1");
    }

    @Test
    @DisplayName("Puis l'observation la plus récente — entre deux PRODUCTIONS différentes")
    void puisLaRecence() {
        var ancienne = observation("EE1-C1", 1, LearningPlanSkillStatus.TO_REINFORCE,
                ObservationConfidence.MEDIUM, T0);
        var recente = observation("EE1-C2", 2, LearningPlanSkillStatus.TO_REINFORCE,
                ObservationConfidence.MEDIUM, T0.plusSeconds(3_600));

        assertThat(trie(ancienne, recente)).containsExactly("EE1-C2", "EE1-C1");
    }

    @Test
    @DisplayName("🔴 À égalité parfaite (même production) : le rang éditorial tranche, pas le code")
    void puisLeRangEditorial() {
        // EE3-C5 a un code « plus grand » que EE2-C7, mais un rang editorial
        // plus fort : c'est lui qui passe, pas l'alphabet.
        var rang7 = observation("EE2-C7", 7, LearningPlanSkillStatus.TO_REINFORCE,
                ObservationConfidence.MEDIUM, T0);
        var rang5 = observation("EE3-C5", 5, LearningPlanSkillStatus.TO_REINFORCE,
                ObservationConfidence.MEDIUM, T0);

        assertThat(trie(rang7, rang5)).containsExactly("EE3-C5", "EE2-C7");
    }

    @Test
    @DisplayName("Puis le code, pour qu'une égalité parfaite reste déterministe")
    void enfinLeCode() {
        var ee3 = observation("EE3-C3", 3, LearningPlanSkillStatus.TO_REINFORCE,
                ObservationConfidence.MEDIUM, T0);
        var ee2 = observation("EE2-C3", 3, LearningPlanSkillStatus.TO_REINFORCE,
                ObservationConfidence.MEDIUM, T0);

        assertThat(trie(ee3, ee2)).containsExactly("EE2-C3", "EE3-C3");
        assertThat(trie(ee2, ee3)).containsExactly("EE2-C3", "EE3-C3");
    }

    @Test
    @DisplayName("Le départage générique : une date absente passe après, un code absent aussi")
    void leDepartageGeneriqueTolereLesAbsences() {
        record Ligne(Instant quand, int rang, String code) {}
        List<Ligne> lignes = List.of(
                new Ligne(null, 1, "A"),
                new Ligne(T0, 2, null),
                new Ligne(T0, 2, "B"),
                new Ligne(T0, 1, "C"));

        List<Ligne> triees = lignes.stream()
                .sorted(OrdreDesPriorites.departage(Ligne::quand, Ligne::rang, Ligne::code))
                .toList();

        assertThat(triees).containsExactly(
                new Ligne(T0, 1, "C"), new Ligne(T0, 2, "B"), new Ligne(T0, 2, null),
                new Ligne(null, 1, "A"));
    }

    @Test
    @DisplayName("Confiance : HIGH 3, MEDIUM 2, LOW et inconnue 1 ; compétence absente : rang le plus faible")
    void lesRangs() {
        assertThat(OrdreDesPriorites.rangConfiance(ObservationConfidence.HIGH)).isEqualTo(3);
        assertThat(OrdreDesPriorites.rangConfiance(ObservationConfidence.MEDIUM)).isEqualTo(2);
        assertThat(OrdreDesPriorites.rangConfiance(ObservationConfidence.LOW)).isEqualTo(1);
        assertThat(OrdreDesPriorites.rangConfiance(null)).isEqualTo(1);
        assertThat(OrdreDesPriorites.rangEditorial(null)).isEqualTo(Integer.MAX_VALUE);
    }

    private static List<String> trie(LearningPlanObservation... observations) {
        return java.util.Arrays.stream(observations)
                .sorted(OrdreDesPriorites.PAR_GRAVITE)
                .map(observation -> observation.getSkill().getCode())
                .toList();
    }

    static LearningPlanObservation observation(String code, int rang,
                                               LearningPlanSkillStatus status,
                                               ObservationConfidence confidence,
                                               Instant observedAt) {
        Skill skill = new Skill();
        skill.setId(UUID.randomUUID());
        skill.setCode(code);
        skill.setDisplayOrder((short) rang);
        LearningPlanObservation observation = new LearningPlanObservation();
        observation.setSkill(skill);
        observation.setStatus(status);
        observation.setConfidence(confidence);
        observation.setObserved(true);
        observation.setObservedAt(observedAt);
        return observation;
    }
}
