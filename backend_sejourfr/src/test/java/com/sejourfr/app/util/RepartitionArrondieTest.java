package com.sejourfr.app.util;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.Random;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * L'invariant qui tient tous les tableaux de l'ecran Analytics : <b>la somme des
 * lignes egale le pied</b>.
 *
 * <p>Un pied a 99 % ne se remarque pas tout de suite, et c'est bien le probleme :
 * quand un lecteur finit par le voir, c'est le tableau entier qui perd sa
 * credibilite.
 */
class RepartitionArrondieTest {

    @Test
    @DisplayName("Trois tiers font 100, pas 99")
    void troisTiersFontCent() {
        int[] parts = RepartitionArrondie.pourcentages(new long[]{1, 1, 1});
        assertThat(parts).containsExactly(34, 33, 33);
        assertThat(somme(parts)).isEqualTo(100);
    }

    @Test
    @DisplayName("La somme vaut 100 quels que soient les poids")
    void sommeToujoursConservee() {
        Random alea = new Random(20260821L);
        for (int essai = 0; essai < 500; essai++) {
            long[] poids = new long[1 + alea.nextInt(9)];
            boolean auMoinsUn = false;
            for (int i = 0; i < poids.length; i++) {
                poids[i] = alea.nextInt(1000);
                auMoinsUn |= poids[i] > 0;
            }
            int[] parts = RepartitionArrondie.pourcentages(poids);
            assertThat(somme(parts)).isEqualTo(auMoinsUn ? 100 : 0);
        }
    }

    /**
     * Une ligne sans donnee ne recoit jamais un point d'arrondi : « 1 % » sur
     * une ligne a zero visiteur serait un chiffre invente.
     */
    @Test
    @DisplayName("Une ligne vide ne reçoit aucun point d'arrondi")
    void ligneVideNeRecoitRien() {
        int[] parts = RepartitionArrondie.pourcentages(new long[]{7, 0, 0, 1});
        assertThat(parts[1]).isZero();
        assertThat(parts[2]).isZero();
        assertThat(somme(parts)).isEqualTo(100);
    }

    /**
     * Rien a repartir : on rend des zeros. Repartir 100 entre des lignes vides
     * fabriquerait des parts a partir de rien.
     */
    @Test
    @DisplayName("Aucune donnée : que des zéros, jamais un total inventé")
    void aucuneDonnee() {
        assertThat(RepartitionArrondie.pourcentages(new long[]{0, 0, 0}))
                .containsExactly(0, 0, 0);
        assertThat(RepartitionArrondie.pourcentages(new long[0])).isEmpty();
    }

    @Test
    @DisplayName("Le reliquat va au plus fort reste, pas à la première ligne")
    void reliquatAuPlusFortReste() {
        // 100 x 1/6 = 16,67 ; 100 x 5/6 = 83,33. Le reste le plus fort est celui
        // de la petite ligne : c'est elle qui monte a 17.
        int[] parts = RepartitionArrondie.pourcentages(new long[]{5, 1});
        assertThat(parts).containsExactly(83, 17);
    }

    private static int somme(int[] parts) {
        int total = 0;
        for (int part : parts) total += part;
        return total;
    }
}
