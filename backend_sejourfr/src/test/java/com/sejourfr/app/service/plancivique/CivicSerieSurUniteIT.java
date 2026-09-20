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
