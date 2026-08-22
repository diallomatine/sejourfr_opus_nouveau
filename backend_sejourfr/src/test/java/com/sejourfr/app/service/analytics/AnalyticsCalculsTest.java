package com.sejourfr.app.service.analytics;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Les deux calculs de l'ecran, et surtout leur reponse quand il n'y a rien a
 * comparer.
 *
 * <p>« 0 % » et « on n'a mesure personne » se ressemblent a l'ecran et ne
 * veulent pas dire la meme chose. C'est exactement le piege du premier mois d'un
 * produit, ou la periode precedente est vide.
 */
class AnalyticsCalculsTest {

    @Test
    @DisplayName("Un taux sans base est null, jamais zéro ni l'infini")
    void tauxSansBase() {
        assertThat(AnalyticsCalculs.taux(0, 0)).isNull();
        assertThat(AnalyticsCalculs.taux(5, 0)).isNull();
        assertThat(AnalyticsCalculs.taux(5, -3)).isNull();
    }

    @Test
    @DisplayName("Un taux se lit entre 0 et 1")
    void tauxNormal() {
        assertThat(AnalyticsCalculs.taux(1, 4)).isEqualTo(0.25d);
        assertThat(AnalyticsCalculs.taux(0, 4)).isEqualTo(0d);
    }

    /**
     * Brief §25 : « attention a la division par zero ». Sans ce null, une
     * periode precedente vide afficherait « +100 % » la ou rien n'a ete mesure.
     */
    @Test
    @DisplayName("previous = 0 ⇒ delta null, jamais une division par zéro")
    void deltaSansPrecedent() {
        assertThat(AnalyticsCalculs.delta(42, 0)).isNull();
        assertThat(AnalyticsCalculs.delta(0, 0)).isNull();
    }

    @Test
    @DisplayName("Le delta est relatif et signé")
    void deltaNormal() {
        assertThat(AnalyticsCalculs.delta(150, 100)).isEqualTo(0.5d);
        assertThat(AnalyticsCalculs.delta(50, 100)).isEqualTo(-0.5d);
        assertThat(AnalyticsCalculs.delta(100, 100)).isEqualTo(0d);
    }
}
