package com.sejourfr.app.service.billing;

import com.sejourfr.app.config.AnalyticsProperties;
import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.UserSubscription;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class MontantEncaisseResolverTest {

    private final AnalyticsProperties properties = new AnalyticsProperties();
    private final MontantEncaisseResolver resolver = new MontantEncaisseResolver(properties);

    private static Plan plan(String prix) {
        Plan plan = new Plan();
        plan.setCode("INTEGRAL_PASS_2M");
        if (prix != null) plan.setPrice(new BigDecimal(prix));
        return plan;
    }

    @Test
    @DisplayName("Un prix de store en euros donne des centimes exacts et un taux de 1")
    void prixStoreEnEuros() {
        MontantEncaisse montant = resolver.duStore(29.99, "EUR");
        assertThat(montant.estConnu()).isTrue();
        assertThat(montant.amountCents()).isEqualTo(2999);
        assertThat(montant.currency()).isEqualTo("EUR");
        assertThat(montant.amountEurCents()).isEqualTo(2999);
        assertThat(montant.fxRateToEur()).isEqualByComparingTo(BigDecimal.ONE);
    }

    @Test
    @DisplayName("Une devise étrangère est convertie au taux configuré, et le taux est figé dans la ligne")
    void deviseEtrangereConvertie() {
        MontantEncaisse montant = resolver.duStore(34.99, "usd");
        assertThat(montant.amountCents()).isEqualTo(3499);
        assertThat(montant.currency()).isEqualTo("USD");
        // 3499 × 0,92 = 3219,08 → 3219
        assertThat(montant.amountEurCents()).isEqualTo(3219);
        assertThat(montant.fxRateToEur()).isEqualByComparingTo(new BigDecimal("0.92"));
    }

    /**
     * 🛑 L'invariant central. Un revenu inconnu vaut {@code null}, pas zero :
     * zero euro est une AFFIRMATION (« ce client n'a rien payé »), l'absence de
     * taux est une IGNORANCE. Les additionner donnerait un chiffre d'affaires
     * faussement bas, et personne ne verrait qu'il manque quelque chose.
     */
    @Test
    @DisplayName("Une devise sans taux garde son montant mais n'invente aucune conversion")
    void deviseSansTaux() {
        MontantEncaisse montant = resolver.duStore(1200.0, "JPY");
        assertThat(montant.estConnu()).isTrue();
        assertThat(montant.amountCents()).isEqualTo(120000);
        assertThat(montant.currency()).isEqualTo("JPY");
        assertThat(montant.amountEurCents()).isNull();
        assertThat(montant.fxRateToEur()).isNull();
    }

    @Test
    @DisplayName("Un montant absent, nul ou une devise illisible reste inconnu")
    void montantInconnu() {
        assertThat(resolver.duStore(null, "EUR").estConnu()).isFalse();
        assertThat(resolver.duStore(0.0, "EUR").estConnu()).isFalse();
        assertThat(resolver.duStore(-5.0, "EUR").estConnu()).isFalse();
        assertThat(resolver.duStore(9.99, null).estConnu()).isFalse();
        assertThat(resolver.duStore(9.99, "EUROS").estConnu()).isFalse();
    }

    @Test
    @DisplayName("Stripe déclare en unités mineures : on les prend telles quelles")
    void unitesMineures() {
        MontantEncaisse montant = resolver.enUnitesMineures(1999L, "eur");
        assertThat(montant.amountCents()).isEqualTo(1999);
        assertThat(montant.amountEurCents()).isEqualTo(1999);
        assertThat(resolver.enUnitesMineures(null, "EUR").estConnu()).isFalse();
        assertThat(resolver.enUnitesMineures(0L, "EUR").estConnu()).isFalse();
    }

    @Test
    @DisplayName("À défaut, le prix affiché du plan — en euros")
    void repliSurLePlan() {
        MontantEncaisse montant = resolver.duPlan(plan("19.99"));
        assertThat(montant.amountCents()).isEqualTo(1999);
        assertThat(montant.currency()).isEqualTo("EUR");
        assertThat(resolver.duPlan(plan(null)).estConnu()).isFalse();
        assertThat(resolver.duPlan(null).estConnu()).isFalse();
        assertThat(resolver.duPlan(plan("0.00")).estConnu()).isFalse();
    }

    /**
     * Le montant reellement preleve prime toujours sur le tarif affiche : il
     * tient compte des remises, de la proration et de la devise reelle.
     */
    @Test
    @DisplayName("Le montant constaté par le canal l'emporte sur le prix du plan")
    void constatePrimeSurLePlan() {
        MontantEncaisse constate = resolver.duStore(9.99, "EUR");
        assertThat(resolver.ouDefautDuPlan(constate, plan("19.99")).amountCents()).isEqualTo(999);
        assertThat(resolver.ouDefautDuPlan(MontantEncaisse.INCONNU, plan("19.99")).amountCents())
                .isEqualTo(1999);
        assertThat(resolver.ouDefautDuPlan(null, plan("19.99")).amountCents()).isEqualTo(1999);
    }

    @Test
    @DisplayName("Un montant inconnu n'écrit aucune des quatre colonnes")
    void inconnuNEcritRien() {
        UserSubscription sub = new UserSubscription();
        MontantEncaisse.INCONNU.appliquerA(sub);
        assertThat(sub.getAmountCents()).isNull();
        assertThat(sub.getCurrency()).isNull();
        assertThat(sub.getAmountEurCents()).isNull();
        assertThat(sub.getFxRateToEur()).isNull();
    }

    @Test
    @DisplayName("Un montant connu écrit les quatre colonnes ensemble (la contrainte l'exige)")
    void connuEcritLesQuatre() {
        UserSubscription sub = new UserSubscription();
        resolver.duStore(29.99, "EUR").appliquerA(sub);
        assertThat(sub.getAmountCents()).isEqualTo(2999);
        assertThat(sub.getCurrency()).isEqualTo("EUR");
        assertThat(sub.getAmountEurCents()).isEqualTo(2999);
        assertThat(sub.getFxRateToEur()).isEqualByComparingTo(BigDecimal.ONE);
    }

    /**
     * Le taux est RECOPIE dans la ligne. Le modifier en configuration ne doit
     * donc rien changer aux paiements deja encaisses — sinon le chiffre
     * d'affaires du passe bougerait tout seul au gre des cours.
     */
    @Test
    @DisplayName("Changer un taux en configuration n'affecte que les paiements à venir")
    void tauxFigeDansLaLigne() {
        UserSubscription hier = new UserSubscription();
        resolver.duStore(100.0, "USD").appliquerA(hier);
        Integer eurHier = hier.getAmountEurCents();

        properties.setFxRates(Map.of("USD", new BigDecimal("0.500000")));
        UserSubscription aujourdhui = new UserSubscription();
        resolver.duStore(100.0, "USD").appliquerA(aujourdhui);

        assertThat(hier.getAmountEurCents()).isEqualTo(eurHier);
        assertThat(aujourdhui.getAmountEurCents()).isNotEqualTo(eurHier);
    }
}
