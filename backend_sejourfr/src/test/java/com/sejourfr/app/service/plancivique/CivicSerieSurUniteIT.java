package com.sejourfr.app.service.plancivique;

import com.sejourfr.app.dto.AttemptResponse;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.access.AccessDeniedException;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * <b>La série d'une UNITÉ OFFICIELLE</b> — l'action d'une étape du cycle civique
 * (D-48, P8.7).
 *
 * <h2>🛑 Deux grains, deux routes</h2>
 * <p>Une cible du <b>plan dérivé</b> est une notion (ou un thème en mode
 * dégradé) ; une étape du <b>cycle</b> porte une <b>unité de l'arrêté</b>, qui
 * regroupe jusqu'à 8 notions. Faire passer l'un pour l'autre aurait rendu un
 * 404 incompréhensible.
 */
class CivicSerieSurUniteIT extends AbstractIntegrationTest {

    @Autowired private CivicPlanService service;
    @Autowired private TestData data;
    @Autowired private JdbcTemplate jdbc;

    @Test
    @DisplayName("Un abonné ouvre la série d'une unité, et elle tire DANS cette unité")
    void laSerieTireDansLUnite() {
        User user = data.user();
        data.userSubscription(user, data.plan());
        UUID unite = unite("P2_LAICITE");

        AttemptResponse serie = service.demarrerSerieSurUnite(user.getId(), "P2_LAICITE");

        assertThat(serie.questions()).isNotEmpty();
        assertThat(serie.type().name()).isEqualTo("TRAINING");
        for (var q : serie.questions()) {
            assertThat(jdbc.queryForObject("""
                    SELECT count(*) FROM questions q
                    JOIN civic_notions n ON n.id = q.civic_notion_id
                    WHERE q.id = ? AND n.official_unit_id = ?
                    """, Integer.class, q.question().id(), unite))
                    .as("chaque question appartient à l'unité demandée")
                    .isEqualTo(1);
        }
    }

    /**
     * 🛑 <b>Une unité trop mince est complétée par sa THÉMATIQUE</b>
     * (2026-09-20), et l'unité garde la <b>priorité absolue</b>.
     *
     * <p>Pourquoi ce complément existe : une série d'étape annonce 20 questions
     * et son seuil de réussite est calculé sur 20. Servir une série de 5 là où
     * l'écran a promis 20 rendrait la carte <b>impossible à valider</b> — le
     * candidat resterait bloqué sur son unité, et depuis la suppression du filet
     * rien ne le débloquerait.
     *
     * <p>La mesure se fait sur une unité <b>volontairement amincie</b> : le test
     * est transactionnel, la désactivation ne survit pas à sa méthode.
     */
    @Test
    @DisplayName("Une unité trop mince est complétée par sa thématique, l'unité d'abord")
    void uneUniteTropMinceEstCompleteeParSaThematique() {
        User user = data.user();
        data.userSubscription(user, data.plan());
        UUID unite = unite("P2_LAICITE");

        // On ne garde que CINQ questions actives sur l'unité.
        List<UUID> gardees = jdbc.queryForList("""
                SELECT q.id FROM questions q
                JOIN civic_notions n ON n.id = q.civic_notion_id
                WHERE n.official_unit_id = ? AND q.is_active AND q.status = 'ACTIVE'
                ORDER BY q.id LIMIT 5
                """, UUID.class, unite);
        jdbc.update("""
                UPDATE questions SET is_active = false
                WHERE civic_notion_id IN (SELECT id FROM civic_notions WHERE official_unit_id = ?)
                  AND id <> ALL (?)
                """, unite, gardees.toArray(new UUID[0]));

        AttemptResponse serie = service.demarrerSerieSurUnite(user.getId(), "P2_LAICITE");

        assertThat(serie.questions())
                .as("la série tient sa promesse de 20 questions")
                .hasSize(20);
        List<UUID> tirees = serie.questions().stream()
                .map(q -> q.question().id())
                .toList();
        assertThat(tirees)
                .as("priorité absolue aux questions de l'unité : les cinq y sont")
                .containsAll(gardees);
        assertThat(tirees).doesNotHaveDuplicates();
        for (UUID id : tirees) {
            assertThat(jdbc.queryForObject("""
                    SELECT count(*) FROM questions q
                    JOIN themes t ON t.id = q.theme_id
                    WHERE q.id = ? AND t.code = (
                        SELECT theme_code FROM civic_official_units WHERE id = ?)
                    """, Integer.class, id, unite))
                    .as("le complément reste DANS la thématique de l'unité")
                    .isEqualTo(1);
        }
    }

    @Test
    @DisplayName("🛑 Sans abonnement : 403, et la même phrase que la série ciblée (D-33)")
    void sansAbonnementLaSerieEstRefusee() {
        User user = data.user();

        assertThatThrownBy(() ->
                service.demarrerSerieSurUnite(user.getId(), "P2_LAICITE"))
                .isInstanceOf(AccessDeniedException.class)
                .hasMessageContaining("Votre plan, lui, reste entier");
    }

    @Test
    @DisplayName("Une unité inconnue du programme est refusée, pas servie à vide")
    void uneUniteInconnueEstRefusee() {
        User user = data.user();
        data.userSubscription(user, data.plan());

        assertThatThrownBy(() ->
                service.demarrerSerieSurUnite(user.getId(), "UNITE_QUI_NEXISTE_PAS"))
                .hasMessageContaining("ne fait pas partie du programme");
    }

    private UUID unite(String code) {
        return jdbc.queryForObject(
                "SELECT id FROM civic_official_units WHERE code = ?", UUID.class, code);
    }
}
