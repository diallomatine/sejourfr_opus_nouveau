package com.sejourfr.app.service;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import tools.jackson.databind.ObjectMapper;

/**
 * Charge un {@link ProductionRubricsProvider} hors contexte Spring.
 *
 * <p>{@code load()} est {@code @PostConstruct} et volontairement
 * package-private : les tests d'autres paquets (mapper, version ciblée) n'y
 * accèdent pas. Cette fabrique vit donc DANS le paquet du provider, plutôt que
 * de faire ouvrir la visibilité du code de production pour les besoins d'un
 * test.
 */
public final class ProductionRubricsFixture {

    private ProductionRubricsFixture() {
    }

    /** Provider chargé sur la version de grille demandée (ex. {@code "v13"}). */
    public static ProductionRubricsProvider charge(String rubricsVersion) {
        ProductionEvaluationProperties props = new ProductionEvaluationProperties();
        props.setRubricsVersion(rubricsVersion);
        return charge(props);
    }

    /** Variante quand l'appelant a déjà ses propriétés (seuils, provider, …). */
    public static ProductionRubricsProvider charge(ProductionEvaluationProperties props) {
        ProductionRubricsProvider provider =
            new ProductionRubricsProvider(props, new ObjectMapper());
        provider.load();
        return provider;
    }
}
