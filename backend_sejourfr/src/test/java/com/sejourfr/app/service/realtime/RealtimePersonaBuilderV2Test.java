package com.sejourfr.app.service.realtime;

import com.sejourfr.app.config.RealtimeProperties;
import com.sejourfr.app.entity.AgentRoleCard;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.AgentInfoImportance;
import com.sejourfr.app.enums.AgentRelation;
import com.sejourfr.app.enums.EpreuveType;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.ObjectMapper;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Rendu de la persona v2 (prompts/realtime-personas-v2.json), qui ajoute la
 * fiche de scenario de la Tache 2 ({@link AgentRoleCard}) aux gabarits v1.
 *
 * <p>Deux garanties verrouillees ici :
 * <ul>
 *   <li>avec fiche : les faits partent dans le prompt, assortis des regles qui
 *       empechent l'agent d'en inventer d'autres, de les livrer spontanement ou
 *       de souffler les questions au candidat ;</li>
 *   <li>sans fiche : le rendu est <b>identique au caractere pres</b> a celui de
 *       la v1 — aucun sujet existant ne se degrade.</li>
 * </ul>
 */
class RealtimePersonaBuilderV2Test {

    private static RealtimePersonaBuilder builder(String version) {
        RealtimeProperties props = new RealtimeProperties();
        props.setPersonaVersion(version);
        RealtimePersonaTemplates templates = new RealtimePersonaTemplates(props, new ObjectMapper());
        templates.load();
        return new RealtimePersonaBuilder(templates);
    }

    private static ProductionTask task(short tache, AgentRoleCard card) {
        ProductionTask t = new ProductionTask();
        t.setEpreuve(EpreuveType.TCF_EO);
        t.setTacheNumero(tache);
        t.setDureeMaxSec(210);
        t.setNiveauCible("B1");
        t.setContexte("L'examinateur joue le conseiller du service après-vente.");
        t.setConsigne("Vous appelez le service après-vente.");
        t.setAgentRoleCard(card);
        return t;
    }

    private static AgentRoleCard card() {
        return new AgentRoleCard(
                "Conseiller du service après-vente",
                AgentRelation.INCONNU_VOUVOIEMENT,
                "Obtenir une réparation et négocier un délai.",
                "Service après-vente, bonjour, que puis-je pour vous ?",
                List.of(
                        new AgentRoleCard.Info("delai_reparation",
                                "Le délai de réparation est de trois semaines.", AgentInfoImportance.HAUTE),
                        new AgentRoleCard.Info("garantie",
                                "L'appareil est garanti deux ans avec la facture.", AgentInfoImportance.HAUTE)),
                List.of(new AgentRoleCard.Info("pret_appareil",
                        "Nous ne prêtons pas d'appareil de remplacement.", AgentInfoImportance.BASSE)),
                List.of("Tu proposes d'abord la réparation.")
        );
    }

    @Test
    void v2_t2_withCard_injectsFactsAndAntiInventionRules() {
        String out = builder("v2").build(task((short) 2, card()));

        assertThat(out)
                .contains("FICHE DU SCÉNARIO")
                .contains("Conseiller du service après-vente")
                .contains("vouvoie le candidat")
                .contains("Service après-vente, bonjour, que puis-je pour vous ?")
                .contains("- Le délai de réparation est de trois semaines.")
                .contains("- L'appareil est garanti deux ans avec la facture.")
                .contains("- Nous ne prêtons pas d'appareil de remplacement.")
                .contains("- Tu proposes d'abord la réparation.")
                .contains("N'en invente AUCUN autre")
                .contains("Tu ne les livres PAS spontanément");
    }

    @Test
    void v2_t2_withCard_keepsV1Framing() {
        // La fiche s'ajoute au cadrage v1, elle ne le remplace pas.
        String out = builder("v2").build(task((short) 2, card()));

        assertThat(out)
                .contains("RÈGLES ABSOLUES")
                .contains("TU RÉPONDS, tu ne mènes pas")
                .contains("N'ORIENTE JAMAIS le candidat vers les questions attendues du sujet")
                .contains("Ne corrige JAMAIS la langue du candidat")
                .contains("Voici la deuxième partie");
    }

    @Test
    void v2_t2_cardIsNotACheckList() {
        // Regle produit : une information non obtenue est informative, pas
        // penalisante — l'agent ne doit ni derouler la fiche ni la reprocher.
        String out = builder("v2").build(task((short) 2, card()));

        assertThat(out)
                .contains("n'est PAS un programme à faire dérouler")
                .contains("tu ne t'inquiètes pas de ce qu'il n'a pas demandé")
                .doesNotContain("delai_reparation")   // les cles machine ne partent pas dans le prompt
                .doesNotContain("HAUTE");
    }

    @Test
    void v2_t2_withoutCard_rendersExactlyLikeV1() {
        ProductionTask sansFiche = task((short) 2, null);

        assertThat(builder("v2").build(sansFiche)).isEqualTo(builder("v1").build(sansFiche));
    }

    @Test
    void v2_t2_withoutCard_leavesNoPlaceholder() {
        String out = builder("v2").build(task((short) 2, null));

        assertThat(out).doesNotContain("{ficheScenario}").doesNotContain("FICHE DU SCÉNARIO");
    }

    @Test
    void v2_t1_ignoresCard() {
        // La fiche ne concerne que le jeu de role : l'entretien dirige est intact.
        ProductionTask t1 = task((short) 1, card());

        assertThat(builder("v2").build(t1))
                .isEqualTo(builder("v1").build(t1))
                .doesNotContain("FICHE DU SCÉNARIO");
    }

    @Test
    void v2_t2_partialCard_fallsBackWithoutBreaking() {
        AgentRoleCard partielle = new AgentRoleCard(
                null, null, null, null, List.of(), null, null);

        String out = builder("v2").build(task((short) 2, partielle));

        assertThat(out)
                .contains("FICHE DU SCÉNARIO")
                .contains("vouvoie le candidat")
                .contains("Aucun fait imposé")
                .contains("Aucune contrainte particulière")
                .doesNotContain("{roleAgent}")
                .doesNotContain("{informations}")
                .doesNotContain("{contraintesAgent}");
    }
}
