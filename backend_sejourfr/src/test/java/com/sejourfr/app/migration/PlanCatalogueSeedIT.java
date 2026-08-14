package com.sejourfr.app.migration;

import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.PlanPurchaseType;
import com.sejourfr.app.manager.PlanManager;
import com.sejourfr.app.support.AbstractIntegrationTest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Contrat durable du catalogue de passes vendu aux candidats (V100 + V114).
 *
 * <p>Ce qui est figé ici n'est pas « joli à avoir » : le prix affiché et la durée
 * d'accès accordée viennent tous deux de cette table, le backend posant lui-même
 * {@code ends_at = paiement + duration_days} (le store ne fait qu'encaisser). Une
 * durée qui change en base change rétroactivement ce qu'un candidat a acheté.
 */
class PlanCatalogueSeedIT extends AbstractIntegrationTest {

    @Autowired private PlanManager planManager;

    private Plan plan(String code) {
        Optional<Plan> found = planManager.findByCode(code);
        assertThat(found).as("plan %s absent du catalogue", code).isPresent();
        return found.get();
    }

    @Test
    void integralVendTroisPassesCourts() {
        Plan sevenDays = plan("INTEGRAL_PASS_7J");
        assertThat(sevenDays.getDurationDays()).isEqualTo(7);
        assertThat(sevenDays.getPrice()).isEqualByComparingTo(new BigDecimal("9.99"));
        assertThat(sevenDays.getRealtimeEoSessions()).isEqualTo(5);

        Plan oneMonth = plan("INTEGRAL_PASS_1M");
        assertThat(oneMonth.getDurationDays()).isEqualTo(30);
        assertThat(oneMonth.getPrice()).isEqualByComparingTo(new BigDecimal("19.99"));
        assertThat(oneMonth.getRealtimeEoSessions()).isEqualTo(15);

        Plan twoMonths = plan("INTEGRAL_PASS_2M");
        assertThat(twoMonths.getDurationDays()).isEqualTo(60);
        assertThat(twoMonths.getPrice()).isEqualByComparingTo(new BigDecimal("29.99"));
        assertThat(twoMonths.getRealtimeEoSessions()).isEqualTo(25);

        assertThat(List.of(sevenDays, oneMonth, twoMonths))
                .allSatisfy(plan -> {
                    assertThat(plan.isActive()).isTrue();
                    assertThat(plan.getPurchaseType()).isEqualTo(PlanPurchaseType.ONE_TIME);
                    assertThat(plan.getModuleAccess()).isEqualTo(ModuleAccess.INTEGRAL);
                });
    }

    /**
     * Le mobile lit les product IDs <em>tels quels</em> depuis le backend
     * ({@code PlanPublicResponse.appleProductId} / {@code googleProductId}) : un
     * identifiant absent ou mal orthographié rend le pass introuvable au store,
     * donc invisible au paywall — sans aucune erreur.
     */
    @Test
    void chaquePassPorteSesDeuxIdentifiantsDeStore() {
        assertThat(plan("INTEGRAL_PASS_7J").getAppleProductId()).isEqualTo("integral_pass_7j");
        assertThat(plan("INTEGRAL_PASS_7J").getGoogleProductId()).isEqualTo("integral_pass_7j");
        assertThat(plan("INTEGRAL_PASS_1M").getAppleProductId()).isEqualTo("integral_pass_1m");
        assertThat(plan("INTEGRAL_PASS_1M").getGoogleProductId()).isEqualTo("integral_pass_1m");
        assertThat(plan("INTEGRAL_PASS_2M").getAppleProductId()).isEqualTo("integral_pass_2m");
        assertThat(plan("INTEGRAL_PASS_2M").getGoogleProductId()).isEqualTo("integral_pass_2m");
    }

    /** Le catalogue Civique n'a pas bougé — c'est une décision produit, pas un oubli. */
    @Test
    void civiqueEstInchange() {
        Plan threeMonths = plan("CIVIQUE_PASS_3M");
        assertThat(threeMonths.isActive()).isTrue();
        assertThat(threeMonths.getDurationDays()).isEqualTo(90);
        assertThat(threeMonths.getPrice()).isEqualByComparingTo(new BigDecimal("9.99"));

        Plan oneYear = plan("CIVIQUE_PASS_1Y");
        assertThat(oneYear.isActive()).isTrue();
        assertThat(oneYear.getDurationDays()).isEqualTo(365);
        assertThat(oneYear.getPrice()).isEqualByComparingTo(new BigDecimal("29.99"));
    }

    /**
     * Les anciens passes Intégral sont <strong>dormants, pas supprimés</strong> :
     * les souscriptions déjà vendues les référencent par clé étrangère et lisent
     * leur durée, et les webhooks des stores doivent encore résoudre leur product
     * ID. Ils ne doivent simplement plus être proposés à l'achat.
     */
    @Test
    void lesAnciensPassesIntegralSurviventDesactives() {
        assertThat(List.of("INTEGRAL_PASS_SPRINT", "INTEGRAL_PASS_3M", "INTEGRAL_PASS_1Y"))
                .allSatisfy(code -> assertThat(plan(code).isActive()).isFalse());
    }

    /**
     * Ce que voit réellement un candidat : le paywall et les grilles de tarifs ne
     * rendent que les plans actifs. Trois passes Intégral, deux Civique — pas un
     * ancien pass oublié à côté des nouveaux prix.
     */
    @Test
    void seulsLesPassesDuCatalogueCourantSontActifs() {
        List<String> actifs = planManager.findAll().stream()
                .filter(Plan::isActive)
                .filter(plan -> plan.getPurchaseType() == PlanPurchaseType.ONE_TIME)
                .map(Plan::getCode)
                .sorted()
                .toList();

        assertThat(actifs).containsExactly(
                "CIVIQUE_PASS_1Y", "CIVIQUE_PASS_3M",
                "INTEGRAL_PASS_1M", "INTEGRAL_PASS_2M", "INTEGRAL_PASS_7J");
    }
}
