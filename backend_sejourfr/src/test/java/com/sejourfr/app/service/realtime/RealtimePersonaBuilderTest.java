package com.sejourfr.app.service.realtime;

import com.sejourfr.app.config.RealtimeProperties;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.ObjectMapper;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Construction de la persona T1/T2 a partir des gabarits externalises
 * (prompts/realtime-personas-v1.json). On charge le VRAI fichier (pas un mock) :
 * ce test verrouille a la fois le rendu (substitution des placeholders) ET le
 * cadrage baked dans la persona v1 (1-2 phrases, une question, ne pas repeter,
 * inversion T2, adaptation au niveau).
 */
class RealtimePersonaBuilderTest {

    private RealtimePersonaBuilder builder;

    @BeforeEach
    void setUp() {
        RealtimeProperties props = new RealtimeProperties(); // persona-version = v1
        RealtimePersonaTemplates templates = new RealtimePersonaTemplates(props, new ObjectMapper());
        templates.load();
        builder = new RealtimePersonaBuilder(templates);
    }

    private ProductionTask task(short tache, Integer dureeMaxSec, String niveau, String contexte, String consigne) {
        ProductionTask t = new ProductionTask();
        t.setEpreuve(EpreuveType.TCF_EO);
        t.setTacheNumero(tache);
        t.setDureeMaxSec(dureeMaxSec);
        t.setNiveauCible(niveau);
        t.setContexte(contexte);
        t.setConsigne(consigne);
        return t;
    }

    @Test
    void build_t1_containsLockedRulesAndOpening() {
        String out = builder.build(task((short) 1, 120, "B1", null, null));

        assertThat(out)
                .contains("RÈGLES ABSOLUES")
                .contains("examinateur officiel")
                .contains("tu n'évalues jamais")
                .contains("TÂCHE 1")
                .contains("Bonjour, je suis votre examinateur")
                .contains("120 secondes");
    }

    @Test
    void build_t1_bakesConversationRules() {
        String out = builder.build(task((short) 1, 180, "B1", null, null));

        assertThat(out)
                .contains("1 à 2 phrases")
                .contains("une seule question")
                .contains("Ne repose JAMAIS une question déjà posée")
                .contains("demande simplement de répéter");
    }

    @Test
    void build_doesNotTargetCandidateLevel() {
        // L'examinateur parle un francais normal a tout le monde : le niveau cible
        // (qui ne sert qu'a la VAD) ne doit PAS teinter la persona.
        String a2 = builder.build(task((short) 1, 180, "A2", null, null));
        String b2 = builder.build(task((short) 1, 180, "B2", null, null));
        assertThat(a2).isEqualTo(b2);
        assertThat(a2).doesNotContain("A2").doesNotContain("{niveauCible}");
    }

    @Test
    void build_t2_injectsContextAndSituation() {
        String out = builder.build(task((short) 2, 200, "B2",
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
    void build_t2_reinforcesRoleInversion() {
        String out = builder.build(task((short) 2, 180, "B1", "Tu es réceptionniste.", "Vous réservez."));
        assertThat(out).contains("TU RÉPONDS, tu ne mènes pas");
    }

    @Test
    void build_forbidsSteeringTowardExpectedQuestions() {
        // L'examinateur ne doit jamais pousser le candidat vers les questions
        // attendues du sujet (regle commune + renfort T2).
        String t1 = builder.build(task((short) 1, 180, "B1", null, null));
        assertThat(t1).contains("Ne suggère JAMAIS au candidat quoi dire, quelles questions poser");

        String t2 = builder.build(task((short) 2, 180, "B1", "Tu es agent.", "Vous réservez."));
        assertThat(t2).contains("N'ORIENTE JAMAIS le candidat vers les questions attendues du sujet");
    }

    @Test
    void build_t2_nullContext_usesFallback() {
        String out = builder.build(task((short) 2, 180, "B1", null, "Situation candidat."));

        assertThat(out).contains("Tu joues le rôle indiqué dans la consigne.");
        assertThat(out).contains("Situation candidat.");
    }

    @Test
    void build_nullDuree_defaultsTo180() {
        String out = builder.build(task((short) 1, null, "B1", null, null));
        assertThat(out).contains("180 secondes");
    }

    @Test
    void build_nullTacheNumero_defaultsToT1() {
        ProductionTask t = task((short) 1, 150, "B1", null, null);
        t.setTacheNumero(null);
        String out = builder.build(t);
        assertThat(out).contains("TÂCHE 1");
    }
}
