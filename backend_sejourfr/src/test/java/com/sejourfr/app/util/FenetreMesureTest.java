package com.sejourfr.app.util;

import org.junit.jupiter.api.Test;

import java.time.LocalDate;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Autorité unique de la fenêtre des deux consoles. Ce qui est verrouillé ici :
 * les bornes sont INCLUSES, un demi-intervalle est une erreur nommée (jamais un
 * repli muet sur {@code days}, qui afficherait des chiffres qu'on croirait
 * filtrés), et une borne future est ramenée à aujourd'hui plutôt que refusée.
 */
class FenetreMesureTest {

    private static final LocalDate TODAY = LocalDate.now(FenetreMesure.PARIS);

    @Test
    void sansBornesOnRetombeSurLaFenetreGlissante() {
        FenetreMesure fenetre = FenetreMesure.resolve(null, null, 30);

        assertThat(fenetre.to()).isEqualTo(TODAY);
        assertThat(fenetre.from()).isEqualTo(TODAY.minusDays(29));
        assertThat(fenetre.days()).isEqualTo(30);
    }

    @Test
    void leClampHistoriqueDesJoursEstConserve() {
        assertThat(FenetreMesure.resolve(null, null, 0).days()).isEqualTo(1);
        assertThat(FenetreMesure.resolve(null, null, -5).days()).isEqualTo(1);
        assertThat(FenetreMesure.resolve(null, null, 100_000).days()).isEqualTo(365);
    }

    @Test
    void lesBornesSontIncluses() {
        FenetreMesure fenetre = FenetreMesure.resolve("2026-08-01", "2026-08-07", 30);

        assertThat(fenetre.from()).isEqualTo(LocalDate.parse("2026-08-01"));
        assertThat(fenetre.to()).isEqualTo(LocalDate.parse("2026-08-07"));
        assertThat(fenetre.days()).isEqualTo(7);
    }

    /** Le cas « une seule journée » : la borne de fin est incluse, donc 1 jour. */
    @Test
    void uneSeuleJourneeCouvreUnJour() {
        FenetreMesure fenetre = FenetreMesure.resolve("2026-08-18", "2026-08-18", 30);

        assertThat(fenetre.days()).isEqualTo(1);
        assertThat(fenetre.from()).isEqualTo(fenetre.to());
        assertThat(fenetre.endInstantExclusive())
                .isEqualTo(fenetre.to().plusDays(1)
                        .atStartOfDay(FenetreMesure.PARIS).toInstant());
    }

    /**
     * Un demi-intervalle ne retombe PAS sur {@code days} : l'écran afficherait
     * la fenêtre par défaut en croyant montrer la journée demandée, et rien ne
     * le signalerait.
     */
    @Test
    void uneSeuleBorneEstUneErreurNommee() {
        assertThatThrownBy(() -> FenetreMesure.resolve("2026-08-18", null, 30))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("to");
        assertThatThrownBy(() -> FenetreMesure.resolve(null, "2026-08-18", 30))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("from");
    }

    @Test
    void unePeriodeInverseeEstRefusee() {
        assertThatThrownBy(() -> FenetreMesure.resolve("2026-08-19", "2026-08-18", 30))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("postérieur");
    }

    @Test
    void uneAmplitudeAuDelaDuPlafondEstRefusee() {
        String from = TODAY.minusDays(400).toString();

        assertThatThrownBy(() -> FenetreMesure.resolve(from, TODAY.toString(), 30))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("365");

        // Le plafond lui-même passe : 365 jours, bornes incluses.
        assertThat(FenetreMesure.resolve(TODAY.minusDays(364).toString(), TODAY.toString(), 30)
                .days()).isEqualTo(365);
    }

    @Test
    void uneDateIllisibleEstRefusee() {
        assertThatThrownBy(() -> FenetreMesure.resolve("18/08/2026", "2026-08-18", 30))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("yyyy-MM-dd");
    }

    /**
     * Cliquer un jour à venir dans un sélecteur de date n'est pas une faute :
     * il n'existe simplement aucune donnée après aujourd'hui.
     */
    @Test
    void uneBorneDeFinFutureEstRamenéeAAujourdhui() {
        FenetreMesure fenetre = FenetreMesure.resolve(
                TODAY.minusDays(2).toString(), TODAY.plusDays(30).toString(), 30);

        assertThat(fenetre.to()).isEqualTo(TODAY);
        assertThat(fenetre.from()).isEqualTo(TODAY.minusDays(2));
        assertThat(fenetre.days()).isEqualTo(3);
    }

    /** Fenêtre entièrement future : elle se réduit à aujourd'hui, sans erreur. */
    @Test
    void uneFenetreEntierementFutureSeReduitAAujourdhui() {
        FenetreMesure fenetre = FenetreMesure.resolve(
                TODAY.plusDays(1).toString(), TODAY.plusDays(3).toString(), 30);

        assertThat(fenetre.from()).isEqualTo(TODAY);
        assertThat(fenetre.to()).isEqualTo(TODAY);
        assertThat(fenetre.days()).isEqualTo(1);
    }

    @Test
    void uneBorneVideEquivautAUneBorneAbsente() {
        assertThat(FenetreMesure.resolve("  ", "  ", 7).days()).isEqualTo(7);
    }
}
