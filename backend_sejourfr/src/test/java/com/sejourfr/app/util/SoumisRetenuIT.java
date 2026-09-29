package com.sejourfr.app.util;

import com.sejourfr.app.enums.DiagnosticRunType;
import com.sejourfr.app.service.analytics.AnalyticsConfig;
import com.sejourfr.app.support.AbstractIntegrationTest;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Contrôle C : le « soumis » retenu a deux lecteurs — la lecture Suivi (SQL) et
 * le contexte d'inscription posé au claim (Java). Ce test les évalue sur la même
 * grille, au seuil de la config de production, pour qu'ils ne divergent jamais.
 */
class SoumisRetenuIT extends AbstractIntegrationTest {

    @Autowired private JdbcTemplate jdbc;
    @Autowired private AnalyticsConfig config;

    private record Cas(DiagnosticRunType type, Integer repondues, Integer posees) {
    }

    private static List<Cas> grille() {
        List<Cas> cas = new ArrayList<>();
        Integer[] posees = {null, 0, 1, 3, 10, 40, 41};
        for (DiagnosticRunType type : DiagnosticRunType.values()) {
            for (Integer p : posees) {
                cas.add(new Cas(type, null, p));
                if (p == null) continue;
                for (int r = 0; r <= p; r++) cas.add(new Cas(type, r, p));
            }
        }
        return cas;
    }

    private boolean sql(Cas c, double ratio) {
        String requete = "SELECT COALESCE(" + SoumisRetenu.SQL + ", false) FROM (SELECT CAST(:type AS varchar)"
                + " AS diagnostic_type, CAST(:repondues AS integer) AS submitted_answered_count,"
                + " CAST(:posees AS integer) AS submitted_question_count) r";
        Boolean v = new NamedParameterJdbcTemplate(jdbc).queryForObject(requete, new MapSqlParameterSource()
                .addValue("type", c.type().name())
                .addValue("repondues", c.repondues())
                .addValue("posees", c.posees())
                .addValue("civicMinRatio", ratio), Boolean.class);
        return Boolean.TRUE.equals(v);
    }

    @Test
    @DisplayName("SQL (lecture Suivi) et Java (contexte d'inscription) rendent le même verdict, au seuil de la config")
    void memeVerdictDesDeuxCotes() {
        double ratio = config.civicSubmittedMinAnsweredRatio();
        Instant soumis = Instant.parse("2026-09-25T10:00:00Z");
        for (Cas c : grille()) {
            assertThat(SoumisRetenu.retenu(c.type(), soumis, c.repondues(), c.posees(), ratio))
                    .as("%s", c).isEqualTo(sql(c, ratio));
        }
    }

    @Test
    @DisplayName("Seuil de production : 80 % ; civique 32/40 retenu, 31/40 non, sans mesure inconnu ; TCF toujours retenu")
    void seuilDeProduction() {
        double ratio = config.civicSubmittedMinAnsweredRatio();
        Instant soumis = Instant.now();
        assertThat(ratio).isEqualTo(0.8);
        assertThat(SoumisRetenu.retenu(DiagnosticRunType.CIVIQUE, soumis, 32, 40, ratio)).isTrue();
        assertThat(SoumisRetenu.retenu(DiagnosticRunType.CIVIQUE, soumis, 31, 40, ratio)).isFalse();
        assertThat(SoumisRetenu.retenu(DiagnosticRunType.CIVIQUE, soumis, null, null, ratio)).isFalse();
        assertThat(SoumisRetenu.retenu(DiagnosticRunType.CIVIQUE, null, 40, 40, ratio)).isFalse();
        assertThat(Arrays.stream(new DiagnosticRunType[]{DiagnosticRunType.QUICK_TCF, DiagnosticRunType.FULL_TCF})
                .allMatch(t -> SoumisRetenu.retenu(t, soumis, null, null, ratio))).isTrue();
    }
}
