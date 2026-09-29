package com.sejourfr.app.manager;

import com.sejourfr.app.entity.AgentRoleCard;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.AgentInfoImportance;
import com.sejourfr.app.enums.AgentRelation;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Colonne JSONB {@code production_tasks.agent_role_card} (V021) sur Postgres
 * reel : aller-retour du mapping {@link AgentRoleCard}, garde-fou de la
 * contrainte {@code chk_prod_task_agent_role_card}, et controle de qualite des
 * fiches seedees par V743 sur les sujets EO tache 2.
 *
 * <p>Assertions tolerantes au seed : on filtre sur les ids crees par le test, ou
 * on raisonne en propriete universelle (« toute tache EO T2 porte une fiche
 * valide ») plutot qu'en total exact.
 */
class ProductionTaskAgentRoleCardIT extends AbstractIntegrationTest {

    private static final int SUJETS_EO_T2_SEEDES = 20;   // V740 (3) + V741 (10) + V742 (7)

    @Autowired
    private ProductionTaskManager manager;

    @Autowired
    private TestData testData;

    @PersistenceContext
    private EntityManager em;

    private static AgentRoleCard card() {
        return new AgentRoleCard(
                "Guichetier de test",
                AgentRelation.INCONNU_VOUVOIEMENT,
                "Envoyer un colis et connaître le prix.",
                "Bonjour, que puis-je pour vous ?",
                List.of(new AgentRoleCard.Info("tarif", "Le tarif est de 9 euros 50.", AgentInfoImportance.HAUTE)),
                List.of(new AgentRoleCard.Info("horaires", "Nous ouvrons à 9 heures.", AgentInfoImportance.BASSE)),
                List.of("Tu réponds par des phrases courtes.")
        );
    }

    @Test
    void agentRoleCard_roundTripsThroughJsonb() {
        UUID id = testData.productionTaskEoT2(card()).getId();
        em.clear();

        AgentRoleCard relue = manager.findById(id).orElseThrow().getAgentRoleCard();

        assertThat(relue.roleAgent()).isEqualTo("Guichetier de test");
        assertThat(relue.relation()).isEqualTo(AgentRelation.INCONNU_VOUVOIEMENT);
        assertThat(relue.phraseOuverture()).isEqualTo("Bonjour, que puis-je pour vous ?");
        assertThat(relue.informationsEssentielles())
                .singleElement()
                .isEqualTo(new AgentRoleCard.Info("tarif", "Le tarif est de 9 euros 50.", AgentInfoImportance.HAUTE));
        assertThat(relue.informationsSecondaires()).hasSize(1);
        assertThat(relue.contraintesAgent()).containsExactly("Tu réponds par des phrases courtes.");
        assertThat(relue.toutesInformations()).hasSize(2);
    }

    @Test
    void agentRoleCard_isNullableAndOptional() {
        UUID id = testData.productionTaskEoT2(null).getId();
        em.clear();

        assertThat(manager.findById(id).orElseThrow().getAgentRoleCard()).isNull();
    }

    @Test
    void agentRoleCard_rejectedOutsideEoTache2() {
        ProductionTask ee = testData.productionTask(EpreuveType.TCF_EE);
        ee.setAgentRoleCard(card());

        assertThatThrownBy(em::flush)
                .hasStackTraceContaining("chk_prod_task_agent_role_card");
    }

    @Test
    void seededEoT2Tasks_allCarryAValidCard() {
        List<ProductionTask> sujets = manager.findActive(EpreuveType.TCF_EO, null, (short) 2);

        assertThat(sujets).hasSizeGreaterThanOrEqualTo(SUJETS_EO_T2_SEEDES);

        assertThat(sujets).allSatisfy(sujet -> {
            AgentRoleCard fiche = sujet.getAgentRoleCard();
            assertThat(fiche).as("fiche du sujet %s", sujet.getId()).isNotNull();
            assertThat(fiche.roleAgent()).isNotBlank();
            assertThat(fiche.relation()).isNotNull();
            assertThat(fiche.objectifCandidat()).isNotBlank();
            assertThat(fiche.phraseOuverture()).isNotBlank();
            assertThat(fiche.informationsEssentielles()).hasSizeBetween(4, 6);
            assertThat(fiche.informationsSecondaires()).hasSizeBetween(1, 3);
            assertThat(fiche.contraintesAgent()).isNotEmpty().allSatisfy(c -> assertThat(c).isNotBlank());
        });
    }

    @Test
    void seededEoT2Cards_haveSelfContainedFactsWithUniqueKeys() {
        List<ProductionTask> sujets = manager.findActive(EpreuveType.TCF_EO, null, (short) 2);

        assertThat(sujets).allSatisfy(sujet -> {
            List<AgentRoleCard.Info> infos = sujet.getAgentRoleCard().toutesInformations();

            assertThat(infos).allSatisfy(info -> {
                assertThat(info.id()).as("clé machine du sujet %s", sujet.getId()).isNotBlank();
                assertThat(info.importance()).isNotNull();
                // La `valeur` part telle quelle dans le prompt : phrase complète.
                assertThat(info.valeur()).isNotBlank().hasSizeGreaterThan(15).endsWith(".");
            });
            assertThat(infos).extracting(AgentRoleCard.Info::id).doesNotHaveDuplicates();
        });
    }
}
