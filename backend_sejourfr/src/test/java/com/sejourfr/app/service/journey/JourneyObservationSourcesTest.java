package com.sejourfr.app.service.journey;

import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.service.journey.JourneyObservationSources.Sources;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Set;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * <b>Le garde de {@link JourneyObservationSources}</b> : un join qui rend zero
 * n'est jamais normal.
 *
 * <h2>Ce que ce test protege, et pourquoi il ne teste PAS un log</h2>
 * <p>Le defaut d'A95 n'a leve aucune exception et n'a rendu aucun test rouge :
 * le join a rendu zero ligne, et zero ligne est un resultat <b>legitime</b>
 * (R9 — « zero fragilite observee donne zero priorite »). Le seul signal
 * exploitable est donc la distinction entre <b>zero priorite</b> (normal) et
 * <b>zero observation rattachee</b> (une panne).
 *
 * <p>C'est cette distinction qui est figee ici, sur le <b>predicat</b> plutot
 * que sur le message : un test qui lit un log verifie une chaine de caracteres,
 * pas une regle.
 */
class JourneyObservationSourcesTest {

    private static final UUID EVALUATION = UUID.randomUUID();
    private static final UUID SOUMISSION = UUID.randomUUID();

    @Test
    @DisplayName("Le join a rattache des observations : rien a signaler")
    void leJoinQuiRattacheNeDeclenchePas() {
        Sources sources = new Sources(EVALUATION, Set.of(EVALUATION, SOUMISSION));

        assertThat(JourneyObservationSources.joinVide(
                sources, List.of(observation(SOUMISSION, LearningPlanSourceType.DIAGNOSTIC_EE))))
                .isFalse();
    }

    @Test
    @DisplayName("🛑 Le defaut d'A95 : l'identite seule, des observations clavetees ailleurs")
    void leJoinQuiRendZeroDeclenche() {
        // Exactement la forme mesuree en base : l'evaluation porte l'id de la
        // SESSION, l'observation celui de la SOUMISSION. L'egalite ne matche
        // jamais, et rien ne le disait.
        Sources sources = new Sources(EVALUATION, Set.of(EVALUATION));

        assertThat(JourneyObservationSources.joinVide(
                sources, List.of(observation(SOUMISSION, LearningPlanSourceType.DIAGNOSTIC_EE))))
                .isTrue();
    }

    @Test
    @DisplayName("Aucune observation du tout : ce n'est pas un defaut de jointure")
    void aucuneObservationNeDeclenchePas() {
        Sources sources = new Sources(EVALUATION, Set.of(EVALUATION));

        // 🛑 Un candidat sans observation exploitable est un cas REEL (R19.8 :
        // le parcours demande alors un diagnostic). Le garde ne doit pas crier
        // dessus, sinon il devient du bruit et on cesse de le lire.
        assertThat(JourneyObservationSources.joinVide(sources, List.of())).isFalse();
        assertThat(JourneyObservationSources.joinVide(sources, null)).isFalse();
    }

    @Test
    @DisplayName("Une observation sans source_id ne rattache rien, et le dit")
    void observationSansSourceDeclenche() {
        Sources sources = new Sources(EVALUATION, Set.of(EVALUATION));

        assertThat(JourneyObservationSources.joinVide(
                sources, List.of(observation(null, LearningPlanSourceType.TCF_CO))))
                .isTrue();
    }

    private static LearningPlanObservation observation(UUID sourceId, LearningPlanSourceType type) {
        LearningPlanObservation observation = new LearningPlanObservation();
        observation.setSourceId(sourceId);
        observation.setSourceType(type);
        return observation;
    }
}
