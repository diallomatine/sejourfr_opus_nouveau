package com.sejourfr.app.util;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * BORNES DE LONGUEUR — source de vérité unique, partagée par la validation
 * d'une soumission et par le texte modèle « version au niveau visé ».
 */
class ProductionTextBoundsTest {

    /** EE T1 : 30–60 mots. C'est la tâche sur laquelle le défaut a été mesuré. */
    @Test
    void bornesDeLaTache_63MotsEstRefuse_60EstAccepte() {
        ProductionTextBounds bornes = ProductionTextBounds.of(30, 60, 10, 300);

        assertThat(bornes.accepte(60)).isTrue();
        assertThat(bornes.accepte(63)).isFalse();
        assertThat(bornes.accepte(64)).isFalse();
        assertThat(bornes.accepte(30)).isTrue();
        assertThat(bornes.accepte(29)).isFalse();
        assertThat(bornes.libelle()).isEqualTo("30 a 60 mots");
    }

    /** Le plancher de configuration l'emporte quand la tâche est plus permissive. */
    @Test
    void lePlancherDeConfigurationRemonteCeluiDeLaTache() {
        assertThat(ProductionTextBounds.of(5, 90, 10, 300).min()).isEqualTo(10);
        assertThat(ProductionTextBounds.of(40, 90, 10, 300).min()).isEqualTo(40);
    }

    /** Le plafond absolu anti-payload géant l'emporte toujours. */
    @Test
    void lePlafondAbsoluBorneCeluiDeLaTache() {
        assertThat(ProductionTextBounds.of(30, 1000, 10, 300).max()).isEqualTo(300);
    }

    /** Tâche sans bornes déclarées : seuls les garde-fous de configuration jouent. */
    @Test
    void tacheSansBornes_retombeSurLaConfiguration() {
        ProductionTextBounds bornes = ProductionTextBounds.of(null, null, 10, 300);

        assertThat(bornes.min()).isEqualTo(10);
        assertThat(bornes.max()).isEqualTo(300);
    }

    /** Bornes incohérentes en base : jamais un intervalle vide. */
    @Test
    void bornesIncoherentes_neProduisentJamaisUnIntervalleVide() {
        ProductionTextBounds bornes = ProductionTextBounds.of(80, 40, 10, 300);

        assertThat(bornes.max()).isGreaterThanOrEqualTo(bornes.min());
        assertThat(bornes.accepte(80)).isTrue();
    }
}
