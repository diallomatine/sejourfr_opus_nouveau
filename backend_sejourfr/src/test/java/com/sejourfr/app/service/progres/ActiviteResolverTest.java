package com.sejourfr.app.service.progres;

import com.sejourfr.app.dto.ProgressDto;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * L'ACTIVITÉ DE L'ÉCRAN PROGRÈS (T28, {@code 30_} §7 bloc 4).
 *
 * <p>Ce que ce test verrouille :
 * <ul>
 *   <li>🛑 <b>la fenêtre est fermée des DEUX côtés</b> — un jour hors des 30
 *       derniers n'entre pas, et un jour dans le futur non plus. Sans la borne
 *       haute, une date d'appareil déréglée gonflerait le compteur ;</li>
 *   <li>les jours en double ne comptent qu'une fois : c'est un compte de
 *       <b>jours travaillés</b>, pas de séances ;</li>
 *   <li>les semaines vont de la <b>plus ancienne à la plus récente</b> — le sens
 *       de lecture d'une frise — et leur somme est le compteur ;</li>
 *   <li>aucune activité rend une fenêtre <b>pleine de zéros</b>, jamais une
 *       liste vide : l'écran doit pouvoir dessiner la frise dans tous les cas.</li>
 * </ul>
 */
class ActiviteResolverTest {

    private static final LocalDate AUJOURDHUI = LocalDate.of(2026, 9, 30);

    private final ActiviteResolver resolver = new ActiviteResolver();

    @Test
    @DisplayName("Aucune activité : une frise de zéros, jamais une liste vide")
    void aucuneActivite() {
        ProgressDto.Activite activite = resolver.resoudre(List.of(), AUJOURDHUI);

        assertThat(activite.joursActifs()).isZero();
        // 🛑 28, soit quatre semaines PLEINES : une frise dont la somme ne
        // vaudrait pas le compteur serait pire qu'un arrondi.
        assertThat(activite.fenetreJours()).isEqualTo(28);
        assertThat(activite.semaines()).hasSize(4);
        assertThat(activite.semaines()).allSatisfy(s -> assertThat(s.jours()).isZero());
    }

    @Test
    @DisplayName("🛑 La fenêtre est fermée des deux côtés : ni le passé lointain ni le futur")
    void fenetreFermeeDesDeuxCotes() {
        ProgressDto.Activite activite = resolver.resoudre(List.of(
                AUJOURDHUI.minusDays(60),  // trop vieux
                AUJOURDHUI.minusDays(27),  // premier jour de la fenêtre
                AUJOURDHUI,                // aujourd'hui
                AUJOURDHUI.plusDays(3)),   // horloge déréglée
                AUJOURDHUI);

        assertThat(activite.joursActifs()).isEqualTo(2);
    }

    @Test
    @DisplayName("Un jour travaillé deux fois ne compte qu'une fois")
    void joursDistincts() {
        ProgressDto.Activite activite = resolver.resoudre(List.of(
                AUJOURDHUI.minusDays(1),
                AUJOURDHUI.minusDays(1),
                AUJOURDHUI.minusDays(2)),
                AUJOURDHUI);

        assertThat(activite.joursActifs()).isEqualTo(2);
    }

    @Test
    @DisplayName("Les semaines vont de la plus ancienne à la plus récente, et leur somme fait le compte")
    void semainesOrdonnees() {
        ProgressDto.Activite activite = resolver.resoudre(List.of(
                AUJOURDHUI.minusDays(27),  // semaine 1
                AUJOURDHUI.minusDays(26),  // semaine 1
                AUJOURDHUI.minusDays(1),   // semaine 4
                AUJOURDHUI),               // semaine 4
                AUJOURDHUI);

        List<ProgressDto.Semaine> semaines = activite.semaines();
        assertThat(semaines.getFirst().debut()).isEqualTo(AUJOURDHUI.minusDays(27));
        assertThat(semaines.getFirst().jours()).isEqualTo(2);
        assertThat(semaines.getLast().jours()).isEqualTo(2);
        assertThat(semaines.get(1).jours()).isZero();

        assertThat(semaines.stream().mapToInt(ProgressDto.Semaine::jours).sum())
                .isEqualTo(activite.joursActifs());
        // Les débuts se suivent de sept en sept : une frise sans trou.
        for (int i = 1; i < semaines.size(); i++) {
            assertThat(semaines.get(i).debut())
                    .isEqualTo(semaines.get(i - 1).debut().plusDays(7));
        }
    }

    @Test
    @DisplayName("Une liste nulle ou un jour nul ne font pas lever : c'est une lecture d'écran")
    void toleranceAuNul() {
        assertThat(resolver.resoudre(null, AUJOURDHUI).joursActifs()).isZero();
        assertThat(resolver.resoudre(java.util.Arrays.asList(null, AUJOURDHUI), AUJOURDHUI)
                .joursActifs()).isEqualTo(1);
    }
}
