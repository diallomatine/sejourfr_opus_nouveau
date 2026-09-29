package com.sejourfr.app.service.diagnostictcf;

import com.sejourfr.app.config.TcfDiagnosticProperties;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.NiveauCecrl;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.util.EnumMap;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Le calcul de niveau du diagnostic TCF, verifie AUX FRONTIERES EXACTES des
 * seuils — ce que 10_ §13 exige nommement.
 */
class TcfDiagnosticLevelResolverTest {

    private final TcfDiagnosticProperties props = new TcfDiagnosticProperties();
    private final TcfDiagnosticLevelResolver resolver = new TcfDiagnosticLevelResolver(props);

    /** 5 items par palier, comme le tirage reel. */
    private Optional<NiveauCecrl> niveau(int bonnesA2, int bonnesB1, int bonnesB2) {
        Map<Difficulty, Integer> bonnes = new EnumMap<>(Difficulty.class);
        bonnes.put(Difficulty.A2, bonnesA2);
        bonnes.put(Difficulty.B1, bonnesB1);
        bonnes.put(Difficulty.B2, bonnesB2);
        Map<Difficulty, Integer> poses = new EnumMap<>(Difficulty.class);
        poses.put(Difficulty.A2, 5);
        poses.put(Difficulty.B1, 5);
        poses.put(Difficulty.B2, 5);
        return resolver.niveauComprehension(bonnes, poses);
    }

    @Nested
    @DisplayName("Comprehension — les frontieres de seuil")
    class Frontieres {

        @Test
        @DisplayName("B2 exige 0,80 en A2 ET 0,70 en B1 ET 0,60 en B2 — le trio, pas une moyenne")
        void frontiereB2() {
            // 4/5 = 0,80 · 4/5 = 0,80 >= 0,70 · 3/5 = 0,60 : tout juste B2.
            assertThat(niveau(4, 4, 3)).contains(NiveauCecrl.B2);
            // Un cran sous le seuil B2 (2/5 = 0,40) : on retombe en B1.
            assertThat(niveau(4, 4, 2)).contains(NiveauCecrl.B1);
            // 3/5 = 0,60 en B1 : sous les 0,70 exiges pour B2, mais suffisant
            // pour B1 — le seuil B1 est PLUS SEVERE quand on vise B2.
            assertThat(niveau(4, 3, 5)).contains(NiveauCecrl.B1);
        }

        @Test
        @DisplayName("B1 exige 0,80 en A2 : reussir le B1 en ratant l'A2 ne fait pas un B1")
        void frontiereB1() {
            assertThat(niveau(4, 3, 0)).contains(NiveauCecrl.B1);
            // 3/5 = 0,60 en A2 : sous les 0,80. Le candidat est irregulier, il
            // reste A2 malgre un B1 tenu.
            assertThat(niveau(3, 5, 5)).contains(NiveauCecrl.A2);
        }

        @Test
        @DisplayName("A2 exige 0,60 — juste au-dessus et juste en dessous")
        void frontiereA2() {
            assertThat(niveau(3, 0, 0)).contains(NiveauCecrl.A2);
            assertThat(niveau(2, 0, 0)).contains(NiveauCecrl.A1);
        }

        @Test
        @DisplayName("Tout rate : A1, jamais A1_NON_ATTEINT")
        void toutRate() {
            // A1_NON_ATTEINT est un verdict de PRODUCTION (une copie
            // inexploitable). Un QCM entierement faux reste du A1 : le candidat
            // a bien repondu, il s'est trompe.
            assertThat(niveau(0, 0, 0)).contains(NiveauCecrl.A1);
        }
    }

    @Test
    @DisplayName("🛑 Une épreuve non passée n'a PAS de niveau — jamais le palier le plus bas")
    void epreuveNonPasseeEstVide() {
        assertThat(resolver.niveauComprehension(Map.of(), Map.of())).isEmpty();
        assertThat(resolver.niveauComprehension(null, null)).isEmpty();

        Map<Difficulty, Integer> aucunItem = new EnumMap<>(Difficulty.class);
        aucunItem.put(Difficulty.A2, 0);
        aucunItem.put(Difficulty.B1, 0);
        aucunItem.put(Difficulty.B2, 0);
        assertThat(resolver.niveauComprehension(Map.of(), aucunItem)).isEmpty();
    }

    /**
     * Mode degrade de 10_ §9 : le catalogue peut ne pas fournir les 5 items
     * d'un palier. On ajuste le denominateur au lieu d'inventer un echec sur
     * des questions que le candidat n'a jamais vues.
     */
    @Test
    @DisplayName("Un palier non posé n'est pas un palier raté : le dénominateur s'ajuste")
    void palierNonPoseNestPasUnEchec() {
        Map<Difficulty, Integer> bonnes = new EnumMap<>(Difficulty.class);
        bonnes.put(Difficulty.A2, 4);
        bonnes.put(Difficulty.B1, 4);
        Map<Difficulty, Integer> poses = new EnumMap<>(Difficulty.class);
        poses.put(Difficulty.A2, 5);
        poses.put(Difficulty.B1, 5);
        poses.put(Difficulty.B2, 0); // aucun item B2 en base

        // Sans l'ajustement, taux(B2) vaudrait 0 et plafonnerait a B1 un
        // candidat qui n'a jamais eu d'item B2 a traiter.
        assertThat(resolver.niveauComprehension(bonnes, poses)).contains(NiveauCecrl.B2);
    }

    @Nested
    @DisplayName("Production — le minimum des 3 tâches")
    class Production {

        @Test
        @DisplayName("Une tâche ratée plafonne l'épreuve")
        void minimumDesTaches() {
            assertThat(resolver.niveauProduction(
                    List.of(NiveauCecrl.B2, NiveauCecrl.B1, NiveauCecrl.B2)))
                    .contains(NiveauCecrl.B1);
        }

        @Test
        @DisplayName("Une tâche non rendue est ABSENTE, elle ne tire pas l'épreuve vers le bas")
        void tacheNonRendueEstAbsente() {
            assertThat(resolver.niveauProduction(
                    Arrays.asList(NiveauCecrl.B2, null, NiveauCecrl.B2)))
                    .contains(NiveauCecrl.B2);
        }

        @Test
        @DisplayName("Aucune tâche évaluée : épreuve non évaluée")
        void aucuneTacheEvaluee() {
            assertThat(resolver.niveauProduction(Arrays.asList(null, null, null))).isEmpty();
            assertThat(resolver.niveauProduction(List.of())).isEmpty();
            assertThat(resolver.niveauProduction(null)).isEmpty();
        }
    }

    @Nested
    @DisplayName("Niveau global — le plancher des épreuves ÉVALUÉES (A7)")
    class Global {

        @Test
        @DisplayName("Le plancher des quatre épreuves")
        void plancher() {
            assertThat(resolver.niveauGlobal(List.of(
                    NiveauCecrl.B2, NiveauCecrl.B2, NiveauCecrl.B1, NiveauCecrl.B1)))
                    .contains(NiveauCecrl.B1);
        }

        @Test
        @DisplayName("🛑 Une épreuve non évaluée est EXCLUE du minimum, pas comptée au plus bas")
        void nonEvalueeExclue() {
            // CO absente : le global reste B2, il ne tombe pas a A1.
            assertThat(resolver.niveauGlobal(
                    Arrays.asList(null, NiveauCecrl.B2, NiveauCecrl.B2, NiveauCecrl.B2)))
                    .contains(NiveauCecrl.B2);
        }

        @Test
        @DisplayName("Aucune épreuve évaluée : pas de niveau global")
        void aucuneEpreuveEvaluee() {
            assertThat(resolver.niveauGlobal(Arrays.asList(null, null, null, null))).isEmpty();
        }
    }

    @Nested
    @DisplayName("Écart à la cible")
    class Ecart {

        @Test
        @DisplayName("Compte les paliers manquants")
        void comptePaliers() {
            assertThat(TcfDiagnosticLevelResolver.ecart(NiveauCecrl.A2, NiveauCecrl.B2)).isEqualTo(2);
            assertThat(TcfDiagnosticLevelResolver.ecart(NiveauCecrl.B1, NiveauCecrl.B2)).isEqualTo(1);
        }

        @Test
        @DisplayName("Au-dessus de la cible, l'écart vaut 0 — jamais un négatif")
        void jamaisNegatif() {
            // Un ecart negatif reduirait le score d'une autre tache par effet
            // de bord : la borne a zero est structurelle, pas cosmetique.
            assertThat(TcfDiagnosticLevelResolver.ecart(NiveauCecrl.C1, NiveauCecrl.B1)).isZero();
            assertThat(TcfDiagnosticLevelResolver.ecart(NiveauCecrl.B2, NiveauCecrl.B2)).isZero();
        }

        @Test
        @DisplayName("Un niveau inconnu ne crée pas d'écart")
        void inconnuNeCreePasDecart() {
            assertThat(TcfDiagnosticLevelResolver.ecart(null, NiveauCecrl.B2)).isZero();
            assertThat(TcfDiagnosticLevelResolver.ecart(NiveauCecrl.A2, null)).isZero();
        }
    }

    @Test
    @DisplayName("Le rang CECRL suit l'ordre du référentiel, A1_NON_ATTEINT au plancher")
    void rangSuitLeReferentiel() {
        assertThat(TcfDiagnosticLevelResolver.rang(NiveauCecrl.A1_NON_ATTEINT)).isZero();
        assertThat(TcfDiagnosticLevelResolver.rang(NiveauCecrl.A1))
                .isLessThan(TcfDiagnosticLevelResolver.rang(NiveauCecrl.A2));
        assertThat(TcfDiagnosticLevelResolver.rang(NiveauCecrl.B1))
                .isLessThan(TcfDiagnosticLevelResolver.rang(NiveauCecrl.B2));
    }
}
