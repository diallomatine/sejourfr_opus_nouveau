package com.sejourfr.app.service.plan;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.PlanActionNature;
import com.sejourfr.app.enums.PlanDomainPriority;

import java.util.EnumSet;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * La configuration du Plan se charge, ou le demarrage echoue.
 *
 * <p>🛑 Ce test est le garde-fou de l'invariant « <b>aucune valeur de
 * classement en dur</b> » : si quelqu'un remet un plafond dans le code Java, il
 * n'aura pas d'entree ici, et la config cessera d'etre l'autorite sans que rien
 * ne le signale.
 */
class PlanConfigLoaderTest {

    @Test
    @DisplayName("La version livree se charge et porte tous les plafonds")
    void laVersionLivreeSeCharge() {
        PlanConfig config = PlanConfigLoader.load(1);

        assertThat(config.planConfigVersion()).isEqualTo(1);
        assertThat(config.display().todayMaxActions()).isPositive();
        assertThat(config.display().prioritiesMaxActions())
                .isGreaterThanOrEqualTo(config.display().todayMaxActions());
        assertThat(config.display().todayMaxSecondaryDomainActions())
                .isNotNegative()
                .isLessThan(config.display().todayMaxActions());
    }

    /**
     * 🛑 Les trois tables sont <b>exhaustives</b> : une entree manquante fait
     * echouer le demarrage, jamais un zero silencieux qui reléguerait une nature
     * d'action en fin de classement sans que personne ne s'en apercoive.
     */
    @Test
    @DisplayName("Les tables de poids couvrent tous les enums")
    void lesTablesDePoidsCouvrentTousLesEnums() {
        PlanConfig.Ranking ranking = PlanConfigLoader.load(1).ranking();

        assertThat(ranking.natureWeights().keySet())
                .containsExactlyInAnyOrderElementsOf(EnumSet.allOf(PlanActionNature.class));
        assertThat(ranking.domainPriorityWeights().keySet())
                .containsExactlyInAnyOrderElementsOf(EnumSet.allOf(PlanDomainPriority.class));
        assertThat(ranking.confidenceWeights().keySet())
                .containsExactlyInAnyOrderElementsOf(EnumSet.allOf(ObservationConfidence.class));
    }

    /**
     * L'ordre des natures <b>est</b> la doctrine : mesurer ce qui manque,
     * reparer ce qui est fragile, verifier ce qui est pret, apprendre ce qui
     * vient. C'est l'ordre de declaration de {@code PlanActionNature}.
     */
    @Test
    @DisplayName("Les poids de nature suivent l'ordre de la doctrine")
    void lesPoidsDeNatureSuiventLOrdreDeLaDoctrine() {
        var poids = PlanConfigLoader.load(1).ranking().natureWeights();

        assertThat(poids.get(PlanActionNature.A_EVALUER))
                .isGreaterThan(poids.get(PlanActionNature.A_RENFORCER));
        assertThat(poids.get(PlanActionNature.A_RENFORCER))
                .isGreaterThan(poids.get(PlanActionNature.A_VERIFIER));
        assertThat(poids.get(PlanActionNature.A_VERIFIER))
                .isGreaterThan(poids.get(PlanActionNature.A_ACQUERIR));
    }

    /** L'urgence d'un domaine suit l'ordre que le serveur a deja decide. */
    @Test
    @DisplayName("Les poids d'urgence suivent l'ordre de PlanDomainPriority")
    void lesPoidsDUrgenceSuiventLOrdreDeLEnum() {
        var poids = PlanConfigLoader.load(1).ranking().domainPriorityWeights();

        assertThat(poids.get(PlanDomainPriority.FORTE))
                .isGreaterThan(poids.get(PlanDomainPriority.A_TRAVAILLER));
        assertThat(poids.get(PlanDomainPriority.A_TRAVAILLER))
                .isGreaterThan(poids.get(PlanDomainPriority.PAS_ENCORE_PRIORITAIRE));
    }

    /** Une version absente ne demarre pas en silence sur des valeurs par defaut. */
    @Test
    @DisplayName("Une version inconnue fait echouer le demarrage")
    void uneVersionInconnueFaitEchouerLeDemarrage() {
        assertThatThrownBy(() -> PlanConfigLoader.load(999))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("plan-config-v999.json");
    }
}
