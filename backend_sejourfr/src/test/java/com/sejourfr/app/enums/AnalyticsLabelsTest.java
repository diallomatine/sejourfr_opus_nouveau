package com.sejourfr.app.enums;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.function.Function;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Fige les libelles FR de la mesure d'audience.
 *
 * <p><b>Pourquoi ce test existe.</b> Ces chaines ne transitent pas par le
 * reseau : l'ecran d'analytics de la console admin en tient sa propre copie a la
 * main. Rien, dans le compilateur, n'empeche donc les deux de deriver — et c'est
 * exactement ce qui est arrive au module Competences, ou un meme verdict
 * s'affichait en trois formulations differentes selon la couche (cf.
 * {@link SkillLabelsTest}).
 *
 * <p>Un echec ici n'est pas un test a mettre a jour a la legere : c'est le
 * signal qu'un libelle a bouge et que la copie admin doit bouger avec lui, dans
 * la meme passe.
 */
class AnalyticsLabelsTest {

    @Test
    @DisplayName("Emplacement de CTA : les dix libelles sont geles")
    void emplacementsDeCta() {
        assertThat(labels(AnalyticsCtaLocation.class, AnalyticsCtaLocation::getLabel))
                .containsExactly(
                        Map.entry("DIAGNOSTIC_REPORT", "Rapport diagnostic"),
                        Map.entry("LOCKED_PLAN", "Plan verrouillé"),
                        Map.entry("PRICING", "Page tarifs"),
                        Map.entry("AI_CORRECTION", "Correction IA"),
                        Map.entry("MOCK_EXAM", "Examen blanc"),
                        Map.entry("HERO", "Hero"),
                        Map.entry("MIDDLE", "Milieu de page"),
                        Map.entry("STICKY", "Barre collante"),
                        Map.entry("FOOTER", "Pied de page"),
                        Map.entry("OTHER", "Autre"));
    }

    @Test
    @DisplayName("Aucun libelle n'est vide : un emplacement sans nom serait illisible dans la table")
    void aucunLibelleVide() {
        for (AnalyticsCtaLocation location : AnalyticsCtaLocation.values()) {
            assertThat(location.getLabel())
                    .as("libellé de %s", location)
                    .isNotBlank();
        }
    }

    private static <E extends Enum<E>> Map<String, String> labels(
            Class<E> type, Function<E, String> label) {
        Map<String, String> map = new LinkedHashMap<>();
        for (E constant : type.getEnumConstants()) {
            map.put(constant.name(), label.apply(constant));
        }
        return map;
    }
}
