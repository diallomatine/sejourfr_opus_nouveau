package com.sejourfr.app.service.realtime;

import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class RealtimePersonaBuilderTest {

    private final RealtimePersonaBuilder builder = new RealtimePersonaBuilder();

    private ProductionTask task(short tache, Integer dureeMaxSec, String contexte, String consigne) {
        ProductionTask t = new ProductionTask();
        t.setEpreuve(EpreuveType.TCF_EO);
        t.setTacheNumero(tache);
        t.setDureeMaxSec(dureeMaxSec);
        t.setContexte(contexte);
        t.setConsigne(consigne);
        return t;
    }

    @Test
    void build_t1_containsLockedRulesAndOpening() {
        String out = builder.build(task((short) 1, 120, null, null));

        assertThat(out)
                .contains("RÈGLES ABSOLUES")
                .contains("examinateur officiel")
                .contains("tu n'évalues jamais")
                .contains("TÂCHE 1")
                .contains("Bonjour, je suis votre examinateur")
                .contains("120 secondes");
    }

    @Test
    void build_t2_injectsContextAndSituation() {
        String out = builder.build(task((short) 2, 200,
                "Tu es un agent immobilier.", "Vous cherchez un appartement."));

        assertThat(out)
                .contains("RÈGLES ABSOLUES")
                .contains("TÂCHE 2")
                .contains("Voici la deuxième partie")
                .contains("Tu es un agent immobilier.")
                .contains("Vous cherchez un appartement.")
                .contains("200 secondes");
    }

    @Test
    void build_t2_nullContext_usesFallback() {
        String out = builder.build(task((short) 2, 180, null, "Situation candidat."));

        assertThat(out).contains("Tu joues le rôle indiqué dans la consigne.");
        assertThat(out).contains("Situation candidat.");
    }

    @Test
    void build_nullDuree_defaultsTo180() {
        String out = builder.build(task((short) 1, null, null, null));
        assertThat(out).contains("180 secondes");
    }

    @Test
    void build_nullTacheNumero_defaultsToT1() {
        ProductionTask t = task((short) 1, 150, null, null);
        t.setTacheNumero(null);
        String out = builder.build(t);
        assertThat(out).contains("TÂCHE 1");
    }
}
