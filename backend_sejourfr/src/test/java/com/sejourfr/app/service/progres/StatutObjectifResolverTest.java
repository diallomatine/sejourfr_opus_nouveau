package com.sejourfr.app.service.progres;

import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.StatutObjectif;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * « Où en suis-je par rapport à mon objectif ? », épreuve par épreuve
 * (spec « progression par épreuve » V2 §2).
 *
 * <p>Ce que ce test verrouille :
 * <ul>
 *   <li>la table de la spec, aux <b>frontières</b> — l'égalité, le cran juste
 *       en dessous, deux crans en dessous, et au-dessus de l'objectif ;</li>
 *   <li>🛑 <b>sans objectif déclaré, aucun statut</b> : {@code null} = inconnu,
 *       jamais {@code TO_REINFORCE}. Sans démarche il n'y a pas de palier
 *       exigé, donc rien vers quoi renforcer ;</li>
 *   <li>🛑 <b>jamais mesuré rend bien {@code TO_REINFORCE}</b> (c'est la table
 *       de la spec), et c'est le <b>niveau servi à côté</b>, {@code null}, qui
 *       garde la distinction avec « mesuré faible » — l'écran lit les deux.</li>
 * </ul>
 */
class StatutObjectifResolverTest {

    private final StatutObjectifResolver resolver = new StatutObjectifResolver();

    @Test
    @DisplayName("Niveau égal à l'objectif : objectif atteint")
    void egal() {
        assertThat(resolver.resoudre(NiveauCecrl.B1, NiveauCecrl.B1))
                .isEqualTo(StatutObjectif.TARGET_REACHED);
    }

    @Test
    @DisplayName("Niveau au-dessus de l'objectif : objectif atteint, jamais un écart négatif")
    void auDessus() {
        assertThat(resolver.resoudre(NiveauCecrl.B2, NiveauCecrl.A2))
                .isEqualTo(StatutObjectif.TARGET_REACHED);
    }

    @Test
    @DisplayName("Un seul cran en dessous : proche de l'objectif")
    void unCranEnDessous() {
        assertThat(resolver.resoudre(NiveauCecrl.B1, NiveauCecrl.B2))
                .isEqualTo(StatutObjectif.CLOSE_TO_TARGET);
        assertThat(resolver.resoudre(NiveauCecrl.A2, NiveauCecrl.B1))
                .isEqualTo(StatutObjectif.CLOSE_TO_TARGET);
    }

    @Test
    @DisplayName("Deux crans ou plus en dessous : à renforcer")
    void plusieursCransEnDessous() {
        assertThat(resolver.resoudre(NiveauCecrl.A2, NiveauCecrl.B2))
                .isEqualTo(StatutObjectif.TO_REINFORCE);
        assertThat(resolver.resoudre(NiveauCecrl.A1_NON_ATTEINT, NiveauCecrl.B2))
                .isEqualTo(StatutObjectif.TO_REINFORCE);
    }

    /**
     * 🛑 Le cas de l'épreuve jamais passée. Le statut PRODUIT est bien
     * « à renforcer » — il n'y a rien de mesuré, donc tout reste à faire —, mais
     * il ne dit rien de plus qu'un A2 mesuré loin du B2 : c'est {@code niveau}
     * qui porte l'absence de mesure, et il vaut {@code null}.
     */
    @Test
    @DisplayName("🛑 Épreuve jamais mesurée : à renforcer, et le niveau reste null à côté")
    void jamaisMesuree() {
        assertThat(resolver.resoudre(null, NiveauCecrl.B1))
                .isEqualTo(StatutObjectif.TO_REINFORCE);
    }

    /**
     * 🛑 Aucune démarche déclarée : on ne devine pas à la place du candidat, et
     * on ne le range surtout pas dans le verdict le plus bas.
     */
    @Test
    @DisplayName("🛑 Sans objectif servi, aucun statut — jamais TO_REINFORCE par défaut")
    void sansObjectif() {
        assertThat(resolver.resoudre(NiveauCecrl.B2, null)).isNull();
        assertThat(resolver.resoudre(null, null)).isNull();
    }
}
