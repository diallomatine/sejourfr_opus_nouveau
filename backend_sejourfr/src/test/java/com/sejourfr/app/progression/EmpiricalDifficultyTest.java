package com.sejourfr.app.progression;

import com.sejourfr.app.enums.DifficultyBand;
import com.sejourfr.app.progression.calibration.EmpiricalDifficulty;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Ce que la difficulté observée a le droit de dire — et surtout ce qu'elle n'a
 * pas le droit de faire (V4.2 §7).
 */
class EmpiricalDifficultyTest {

    /**
     * 🛑 Le test le plus important du fichier.
     *
     * <p>Un taux sur trois réponses ne veut rien dire. Le proposer quand même
     * ferait basculer des bandes sur du bruit, donc la calibration des séries,
     * donc le poids des preuves — et un candidat verrait un acquis bouger sans
     * avoir rien fait.
     */
    @Test
    @DisplayName("Sous le plancher d'échantillon, on ne suggère rien")
    void echantillonTropMinceNeSuggereRien() {
        assertThat(mesure(3, 1.0d, null).bandeSuggeree()).isNull();
        assertThat(mesure(EmpiricalDifficulty.MIN_REPONSES - 1, 0.9d, null).bandeSuggeree())
                .isNull();
        assertThat(mesure(EmpiricalDifficulty.MIN_REPONSES, 0.9d, null).bandeSuggeree())
                .isEqualTo(DifficultyBand.EASY);
    }

    /** Jamais répondue : {@code null}, pas « difficile ». Absence n'est pas échec. */
    @Test
    @DisplayName("Une question jamais répondue n'a pas de taux, et donc pas de bande")
    void jamaisReponduNaPasDeTaux() {
        EmpiricalDifficulty jamais = mesure(0, null, DifficultyBand.MEDIUM);
        assertThat(jamais.tauxReussite()).isNull();
        assertThat(jamais.bandeSuggeree()).isNull();
        assertThat(jamais.enDesaccord()).isFalse();
    }

    @Test
    @DisplayName("Le taux observé se range en facile / moyen / difficile")
    void rangementParTaux() {
        assertThat(mesure(100, 0.90d, null).bandeSuggeree()).isEqualTo(DifficultyBand.EASY);
        assertThat(mesure(100, 0.60d, null).bandeSuggeree()).isEqualTo(DifficultyBand.MEDIUM);
        assertThat(mesure(100, 0.20d, null).bandeSuggeree()).isEqualTo(DifficultyBand.HARD);
    }

    /** Les égalités tombent dans MEDIUM : EASY est p > 0,75, pas p ≥ 0,75. */
    @Test
    @DisplayName("Une question pile au seuil est moyenne, jamais facile ni dure")
    void egalitesDansMedium() {
        assertThat(mesure(100, 0.75d, null).bandeSuggeree()).isEqualTo(DifficultyBand.MEDIUM);
        assertThat(mesure(100, 0.45d, null).bandeSuggeree()).isEqualTo(DifficultyBand.MEDIUM);
        assertThat(mesure(100, 0.7501d, null).bandeSuggeree()).isEqualTo(DifficultyBand.EASY);
        assertThat(mesure(100, 0.4499d, null).bandeSuggeree()).isEqualTo(DifficultyBand.HARD);
    }

    /**
     * Une question taguée HARD que 90 % des candidats réussissent fausse la
     * comparabilité de toutes les séries qui la contiennent. C'est la seule
     * liste réellement actionnable pour la production de contenu.
     */
    @Test
    @DisplayName("Un désaccord tag / données se voit, sans rien corriger tout seul")
    void desaccordSeVoit() {
        EmpiricalDifficulty faussementDure = mesure(100, 0.90d, DifficultyBand.HARD);
        assertThat(faussementDure.enDesaccord()).isTrue();
        // Et la bande déclarée n'a pas bougé : le service propose, un humain tranche.
        assertThat(faussementDure.bandeDeclaree()).isEqualTo(DifficultyBand.HARD);

        assertThat(mesure(100, 0.90d, DifficultyBand.EASY).enDesaccord()).isFalse();
        assertThat(mesure(100, 0.90d, null).enDesaccord()).isFalse();
    }

    private static EmpiricalDifficulty mesure(long reponses, Double taux, DifficultyBand declaree) {
        return new EmpiricalDifficulty(UUID.randomUUID(), reponses, taux, declaree);
    }
}
