package com.sejourfr.app.service.plancivique;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * LA DOTATION D'UNE CIBLE CIVIQUE, PAR MENTION ({@code 50_} §6.1).
 *
 * <p>Ce que ce test verrouille :
 * <ul>
 *   <li>🛑 <b>zéro question ⇒ {@code NON_APPLICABLE}, jamais
 *       {@code CONTENU_INSUFFISANT}</b> — le référentiel validé (V058) a mesuré
 *       que CSP, CR et NAT sont <b>trois programmes différents</b> : « Devenir
 *       français » porte 10 questions en NAT et zéro en CSP. « Pas au programme
 *       de ce candidat » n'est pas « il manque de la matière », et les
 *       confondre efface le signal qui dit quoi écrire ;</li>
 *   <li>la bande <b>1 à 4</b> reste {@code CONTENU_INSUFFISANT} : la notion
 *       existe pour ce candidat, elle est seulement trop mince pour devenir une
 *       unité de parcours (arbitrage propriétaire, seuil 5) ;</li>
 *   <li>🛑 <b>la dérivation vit ICI et nulle part ailleurs</b> — ni le plan ni
 *       le scorer ne recomparent un compte à un seuil. Deux copies d'un seuil
 *       finissent toujours par diverger.</li>
 * </ul>
 */
class CivicDotationTest {

    /** Le seuil d'une notion ({@code CivicPlanProperties.questionsMinParNotion}). */
    private static final int MIN_NOTION = 5;

    @Test
    @DisplayName("🛑 Zéro question dans la mention ⇒ NON_APPLICABLE, pas un manque")
    void zeroQuestionNestPasUnManque() {
        assertThat(CivicDotation.depuis(0, MIN_NOTION))
                .isEqualTo(CivicDotation.NON_APPLICABLE);
        assertThat(CivicDotation.NON_APPLICABLE.estServable()).isFalse();
    }

    @ParameterizedTest(name = "{0} question(s) ⇒ CONTENU_INSUFFISANT")
    @ValueSource(longs = {1, 2, 3, 4})
    @DisplayName("De 1 à 4, la notion EXISTE mais manque de matière")
    void sousLeSeuilLaNotionExiste(long questions) {
        assertThat(CivicDotation.depuis(questions, MIN_NOTION))
                .isEqualTo(CivicDotation.CONTENU_INSUFFISANT);
        assertThat(CivicDotation.CONTENU_INSUFFISANT.estServable()).isFalse();
    }

    @Test
    @DisplayName("À 5, la notion devient une unité de parcours")
    void auSeuilElleDevientServable() {
        assertThat(CivicDotation.depuis(5, MIN_NOTION)).isEqualTo(CivicDotation.SERVABLE);
        assertThat(CivicDotation.depuis(214, MIN_NOTION)).isEqualTo(CivicDotation.SERVABLE);
        assertThat(CivicDotation.SERVABLE.estServable()).isTrue();
    }

    @Test
    @DisplayName("🛑 Le seuil du grain THÈME est celui de la SÉRIE (10), pas celui de la notion")
    void leSeuilDuGrainThemeEstCeluiDeLaSerie() {
        // Un thème se voit proposer une série entière : 9 questions ne la
        // remplissent pas, alors que 9 questions font une notion largement
        // servable. Les deux grains ne se comparent pas au même nombre, et
        // c'est la seule chose que l'appelant choisit.
        assertThat(CivicDotation.depuis(9, 10)).isEqualTo(CivicDotation.CONTENU_INSUFFISANT);
        assertThat(CivicDotation.depuis(9, MIN_NOTION)).isEqualTo(CivicDotation.SERVABLE);
        assertThat(CivicDotation.depuis(10, 10)).isEqualTo(CivicDotation.SERVABLE);
        // 🛑 Et zéro reste zéro quel que soit le grain : un thème vide pour
        // cette mention n'est pas un thème « à étoffer ».
        assertThat(CivicDotation.depuis(0, 10)).isEqualTo(CivicDotation.NON_APPLICABLE);
    }
}
