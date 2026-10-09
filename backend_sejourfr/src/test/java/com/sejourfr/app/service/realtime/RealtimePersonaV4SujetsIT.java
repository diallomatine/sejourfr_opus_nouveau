package com.sejourfr.app.service.realtime;

import com.sejourfr.app.entity.AgentRoleCard;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.manager.ProductionTaskManager;
import com.sejourfr.app.support.AbstractIntegrationTest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.regex.Pattern;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Persona v4 sur les VRAIS sujets T2 (migrations seedées) : pour chacun des
 * sujets EO T2 actifs, en examen blanc comme en entraînement, le prompt assemblé
 * ne laisse aucun placeholder, et l'ouverture entendue par le candidat — en-tête
 * + réplique d'entrée de la fiche + « Je vous écoute. » — tient en 35 mots.
 * Un sujet qui dépasserait se raccourcit en DONNÉES (sa {@code phraseOuverture}),
 * pas dans le prompt.
 */
class RealtimePersonaV4SujetsIT extends AbstractIntegrationTest {

    private static final Pattern PLACEHOLDER = Pattern.compile("\\{[a-zA-Z]+}");

    @Autowired private RealtimePersonaBuilder builder;
    @Autowired private ProductionTaskManager taskManager;
    @Autowired private JdbcTemplate jdbc;

    @Test
    void chaque_sujet_t2_actif_s_assemble_sans_placeholder_et_s_ouvre_en_35_mots_au_plus() {
        // Les sujets SEEDÉS portent tous une fiche ; un autre test peut laisser en base
        // un sujet T2 sans fiche (base partagée) : on ne mesure que les premiers.
        List<UUID> ids = jdbc.queryForList(
                "SELECT id FROM production_tasks WHERE epreuve = 'TCF_EO' AND tache_numero = 2 AND is_active "
                        + "AND agent_role_card IS NOT NULL",
                UUID.class);
        assertThat(ids).hasSizeGreaterThanOrEqualTo(20);

        List<String> tropLongues = new ArrayList<>();
        for (UUID id : ids) {
            ProductionTask task = taskManager.findActiveById(id).orElseThrow();
            for (boolean examen : new boolean[] {true, false}) {
                String out = builder.build(task, examen);
                assertThat(PLACEHOLDER.matcher(out).find()).as("sujet %s, examen=%s", id, examen).isFalse();
            }
            AgentRoleCard card = task.getAgentRoleCard();
            assertThat(card).as("sujet %s sans fiche", id).isNotNull();
            int mots = RealtimePersonaV4Test.motsOuvertureT2(card.phraseOuverture(), true);
            if (mots > 35) tropLongues.add(id + " (" + mots + " mots)");
        }
        assertThat(tropLongues).as("ouvertures T2 de plus de 35 mots").isEmpty();
    }
}
