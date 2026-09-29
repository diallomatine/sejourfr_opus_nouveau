package com.sejourfr.app.service.billing;

import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.io.ClassPathResource;

import java.io.IOException;
import java.io.InputStream;
import java.math.BigDecimal;
import java.util.EnumSet;
import java.util.Set;

/**
 * Charge et <b>verifie</b> {@code billing/revenue-rules-vN.json} au demarrage.
 * Une regle de revenus fausse ne se voit pas : elle decale chaque achat de
 * quelques centimes, pour toujours (les montants sont figes a l'ecriture). D'ou
 * un refus au boot plutot qu'un repli.
 *
 * <p>Refus volontaires : cle inconnue ou manquante, version differente,
 * devise autre qu'EUR, arrondi autre que HALF_UP, taux hors {@code [0, 1[},
 * frais fixes negatifs, store sans taux.
 */
@Slf4j
public final class RevenueRulesLoader {

    private static final ObjectMapper MAPPER = new ObjectMapper()
            .enable(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES)
            .enable(DeserializationFeature.FAIL_ON_NULL_FOR_PRIMITIVES)
            .enable(DeserializationFeature.FAIL_ON_MISSING_CREATOR_PROPERTIES);

    private RevenueRulesLoader() {
    }

    public static RevenueRules load(int version) {
        String path = "billing/revenue-rules-v" + version + ".json";
        try (InputStream in = new ClassPathResource(path).getInputStream()) {
            return parse(in, version, path);
        } catch (IOException e) {
            throw new IllegalStateException("Regles de revenus illisibles : " + path, e);
        }
    }

    static RevenueRules parse(InputStream in, int version, String path) throws IOException {
        RevenueRules rules = MAPPER.readValue(in, RevenueRules.class);
        if (rules.revenueRulesVersion() != version) {
            throw new IllegalStateException("revenueRulesVersion=" + rules.revenueRulesVersion()
                    + " dans " + path + " alors que la version demandee est " + version);
        }
        if (!"EUR".equals(rules.currency())) {
            throw new IllegalStateException("currency doit valoir EUR dans " + path);
        }
        if (!"HALF_UP".equals(rules.rounding())) {
            throw new IllegalStateException("rounding doit valoir HALF_UP dans " + path);
        }
        if (rules.seller() == null || rules.stripe() == null || rules.stores() == null) {
            throw new IllegalStateException("Sections seller / stripe / stores absentes de " + path);
        }
        if (rules.seller().vatRegime() == null) {
            throw new IllegalStateException("seller.vatRegime absent de " + path);
        }
        taux(rules.seller().vatRateIfLiable(), "seller.vatRateIfLiable", path);
        taux(rules.stripe().percentFee(), "stripe.percentFee", path);
        if (rules.stripe().fixedFeeCents() < 0) {
            throw new IllegalStateException("stripe.fixedFeeCents negatif dans " + path);
        }
        taux(rules.stores().vatRate(), "stores.vatRate", path);
        if (rules.stores().commissionMode() == null) {
            throw new IllegalStateException("stores.commissionMode absent de " + path);
        }
        if (rules.stores().commissionRates() == null) {
            throw new IllegalStateException("stores.commissionRates absent de " + path);
        }
        Set<RevenueRules.Store> manquants = EnumSet.allOf(RevenueRules.Store.class);
        manquants.removeAll(rules.stores().commissionRates().keySet());
        if (!manquants.isEmpty()) {
            throw new IllegalStateException("stores.commissionRates n'a pas de taux pour " + manquants
                    + " dans " + path);
        }
        for (RevenueRules.Store store : RevenueRules.Store.values()) {
            taux(rules.commissionRate(store), "stores.commissionRates." + store, path);
        }
        log.info("Regles de revenus chargees (v{}) : regime {}, commission {} {}",
                rules.revenueRulesVersion(), rules.seller().vatRegime(),
                rules.stores().commissionMode(), rules.stores().commissionRates());
        return rules;
    }

    private static void taux(BigDecimal valeur, String cle, String path) {
        if (valeur == null || valeur.signum() < 0 || valeur.compareTo(BigDecimal.ONE) >= 0) {
            throw new IllegalStateException(cle + " doit etre un taux dans [0, 1[ dans " + path);
        }
    }
}
