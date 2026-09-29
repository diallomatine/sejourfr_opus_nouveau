package com.sejourfr.app.service;

import com.sejourfr.app.config.LearningPlanProperties;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.IntStream;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * <b>L'écrivain d'observation civique</b> — le cœur de <b>D-49</b>.
 *
 * <h2>🛑 Ce que ces tests tiennent</h2>
 * <ul>
 *   <li>le grain est l'<b>unité officielle</b>, jamais la notion (D-48), et
 *       l'observation ne porte <b>aucun</b> {@code skill_id} ;</li>
 *   <li>le seuil est <b>lu</b> chez {@code learning-plan.comprehension}, jamais
 *       redéclaré — aucun 9ᵉ seuil ;</li>
 *   <li>une série trop courte compte comme série <b>terminée</b>, jamais comme
 *       série <b>réussie</b> : {@code NOT_OBSERVED}, sans preuve ;</li>
 *   <li>l'idempotence (R14) tient sur {@code (user, unité, source, session)}.</li>
 * </ul>
 *
 * <p>⚠️ <b>Non transactionnels</b> : le service écrit en {@code REQUIRES_NEW},
 * et une transaction de test l'envelopperait — il ne verrait rien de ce que le
 * test vient d'écrire.
 */
@Transactional(propagation = Propagation.NOT_SUPPORTED)
class CivicObservationServiceIT extends AbstractIntegrationTest {

    @Autowired private CivicObservationService service;
    @Autowired private LearningPlanProperties properties;
    @Autowired private AccountDeletionService accountDeletionService;
    @Autowired private TestData data;
    @Autowired private JdbcTemplate jdbc;

    private final List<UUID> candidats = new ArrayList<>();

    @AfterEach
    void menage() {
        candidats.forEach(id -> accountDeletionService.deleteAccount(id));
        candidats.clear();
    }

    @Test
    @DisplayName("Une serie ecrit UNE observation par unite, sur l'unite et jamais sur une competence")
    void uneObservationParUnite() {
        User user = candidat();
        UUID principes = unite("P2_LAICITE");
        UUID droits = unite("D1_DROITS_FONDAMENTAUX");
        UUID session = UUID.randomUUID();

        List<CivicObservationService.ReponseCivique> serie = new ArrayList<>();
        serie.addAll(reponses(principes, 8, 8));   // tout juste
        serie.addAll(reponses(droits, 8, 4));      // la moitie

        Set<UUID> concernees = service.record(user.getId(), session,
                LearningPlanSourceType.CIVIQUE_SERIE, Instant.now(), serie);

        assertThat(concernees).containsExactlyInAnyOrder(principes, droits);

        List<Map<String, Object>> lignes = observations(user);
        assertThat(lignes).hasSize(2);
        // 🛑 `official_unit_id` porte la mesure, `skill_id` reste NUL :
        // `chk_learning_plan_observation_unite` (V070) exige exactement un des deux.
        assertThat(lignes).allSatisfy(ligne -> {
            assertThat(ligne.get("official_unit_id")).isNotNull();
            assertThat(ligne.get("skill_id")).isNull();
            assertThat(ligne.get("source_type")).isEqualTo("CIVIQUE_SERIE");
        });
    }

    @Test
    @DisplayName("🛑 Le seuil est LU chez son autorite : 8/10 est SOLIDE, 7/10 ne l'est pas")
    void leSeuilEstLuChezSonAutorite() {
        User user = candidat();
        UUID unite = unite("P2_LAICITE");
        double solide = properties.getComprehension().getSolidRatio();

        service.record(user.getId(), UUID.randomUUID(),
                LearningPlanSourceType.CIVIQUE_SERIE, Instant.now(),
                reponses(unite, 10, (int) Math.round(solide * 10)));
        service.record(user.getId(), UUID.randomUUID(),
                LearningPlanSourceType.CIVIQUE_SERIE, Instant.now(),
                reponses(unite, 10, (int) Math.round(solide * 10) - 1));

        List<String> statuts = observations(user).stream()
                .map(ligne -> (String) ligne.get("status"))
                .toList();
        // 🛑 Lu chez `learning-plan.comprehension.solid-ratio`, pas ecrit ici :
        // si le seuil bouge, ce test bouge avec lui -- c'est le but.
        assertThat(statuts).containsExactlyInAnyOrder(
                LearningPlanSkillStatus.SOLID.name(),
                LearningPlanSkillStatus.TO_REINFORCE.name());
    }

    @Test
    @DisplayName("Sous le plancher de questions : NOT_OBSERVED, sans preuve — terminee, pas reussie")
    void sousLePlancherLaSerieEstTermineePasReussie() {
        User user = candidat();
        UUID unite = unite("P2_LAICITE");
        int plancher = properties.getComprehension().getMinQuestions();

        // Toutes justes, mais trop peu : la mesure n'est pas probante.
        service.record(user.getId(), UUID.randomUUID(),
                LearningPlanSourceType.CIVIQUE_SERIE, Instant.now(),
                reponses(unite, plancher - 1, plancher - 1));

        Map<String, Object> ligne = observations(user).getFirst();
        assertThat(ligne.get("status")).isEqualTo(LearningPlanSkillStatus.NOT_OBSERVED.name());
        assertThat(ligne.get("observed")).isEqualTo(false);
        // `chk_learning_plan_observation_coherence` : pas de preuve sans mesure.
        assertThat(ligne.get("evidence")).isNull();
        assertThat(ligne.get("confidence")).isEqualTo(ObservationConfidence.LOW.name());
    }

    @Test
    @DisplayName("Une question laissee VIDE n'apprend rien : ni au numerateur, ni au denominateur")
    void uneQuestionVideNApprendRien() {
        User user = candidat();
        UUID unite = unite("P2_LAICITE");

        List<CivicObservationService.ReponseCivique> reponses = new ArrayList<>(
                reponses(unite, 10, 10));
        reponses.add(new CivicObservationService.ReponseCivique(unite, false, false));

        service.record(user.getId(), UUID.randomUUID(),
                LearningPlanSourceType.CIVIQUE_SERIE, Instant.now(), reponses);

        // 10 sur 10, et non 10 sur 11 : la question vide ne compte nulle part.
        assertThat(observations(user).getFirst().get("evidence"))
                .isEqualTo("10 / 10 bonnes réponses");
    }

    @Test
    @DisplayName("Une reponse HORS PROGRAMME n'ecrit rien : `null` dit inconnu, jamais Principes")
    void uneReponseHorsProgrammeNEcritRien() {
        User user = candidat();

        Set<UUID> concernees = service.record(user.getId(), UUID.randomUUID(),
                LearningPlanSourceType.CIVIQUE_SERIE, Instant.now(),
                List.of(new CivicObservationService.ReponseCivique(null, true, true)));

        assertThat(concernees).isEmpty();
        assertThat(observations(user)).isEmpty();
    }

    @Test
    @DisplayName("R14 — deux clotures de la MEME session n'ecrivent qu'une ligne")
    void lIdempotenceTientSurLaSession() {
        User user = candidat();
        UUID unite = unite("P2_LAICITE");
        UUID session = UUID.randomUUID();

        service.record(user.getId(), session, LearningPlanSourceType.CIVIQUE_SERIE,
                Instant.now(), reponses(unite, 10, 10));
        Set<UUID> rejeu = service.record(user.getId(), session,
                LearningPlanSourceType.CIVIQUE_SERIE, Instant.now(), reponses(unite, 10, 10));

        assertThat(observations(user)).hasSize(1);
        // 🛑 Le rejeu rend quand meme l'unite : il ne doit pas faire DISPARAITRE
        // ce que la session a enseigne -- le parcours lit ce retour pour faire
        // avancer ses etapes.
        assertThat(rejeu).containsExactly(unite);
    }

    @Test
    @DisplayName("🛑 Une source TCF leve : c'est un branchement faux, pas une donnee")
    void uneSourceTcfLeve() {
        User user = candidat();
        UUID unite = unite("P2_LAICITE");

        assertThatThrownBy(() -> service.record(user.getId(), UUID.randomUUID(),
                LearningPlanSourceType.TCF_CO, Instant.now(), reponses(unite, 10, 10)))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("source civique");
    }

    // ------------------------------------------------------------------------

    private static List<CivicObservationService.ReponseCivique> reponses(
            UUID unite, int total, int correctes) {
        return IntStream.range(0, total)
                .mapToObj(i -> new CivicObservationService.ReponseCivique(
                        unite, true, i < correctes))
                .toList();
    }

    private List<Map<String, Object>> observations(User user) {
        return jdbc.queryForList("""
                SELECT official_unit_id, skill_id, source_type, status, observed, evidence,
                       confidence
                FROM learning_plan_observations WHERE user_id = ?
                ORDER BY created_at
                """, user.getId());
    }

    private UUID unite(String code) {
        return jdbc.queryForObject(
                "SELECT id FROM civic_official_units WHERE code = ?", UUID.class, code);
    }

    private User candidat() {
        User user = data.user();
        candidats.add(user.getId());
        return user;
    }
}
