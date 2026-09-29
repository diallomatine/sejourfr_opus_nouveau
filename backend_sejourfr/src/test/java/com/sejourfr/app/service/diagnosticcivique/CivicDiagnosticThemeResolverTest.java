package com.sejourfr.app.service.diagnosticcivique;

import com.sejourfr.app.config.CivicDiagnosticProperties;
import com.sejourfr.app.enums.CivicThemeState;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Les seuils d'état d'un thème civique (20_ §4.4), aux bornes exactes.
 *
 * <p>Composant pur : c'est précisément ce qui permet de tester les frontières,
 * là où un test de bout en bout ne toucherait jamais 0,80 pile.
 */
class CivicDiagnosticThemeResolverTest {

    private final CivicDiagnosticThemeResolver resolver =
            new CivicDiagnosticThemeResolver(new CivicDiagnosticProperties());

    @Test
    @DisplayName("🛑 Zéro question posée ⇒ NON_EVALUE, jamais FAIBLE")
    void zeroPoseeNestPasUnEchec() {
        // Un thème qu'on n'a pas mesuré n'a pas été raté. Les confondre
        // reproduirait V040/V041/V042 sur le module civique.
        assertThat(resolver.etat(0, 0)).isEqualTo(CivicThemeState.NON_EVALUE);
        assertThat(CivicDiagnosticThemeResolver.taux(0, 0)).isNull();
    }

    @Test
    @DisplayName("Le seuil SOLIDE est atteint À 0,80 pile, pas au-dessus")
    void seuilSolideInclusif() {
        assertThat(resolver.etat(4, 5)).isEqualTo(CivicThemeState.SOLIDE);
        assertThat(resolver.etat(8, 10)).isEqualTo(CivicThemeState.SOLIDE);
        // 0,75 : juste en dessous.
        assertThat(resolver.etat(3, 4)).isEqualTo(CivicThemeState.A_RENFORCER);
    }

    @Test
    @DisplayName("Le seuil FAIBLE est exclusif : 0,55 pile reste À_RENFORCER")
    void seuilFaibleExclusif() {
        assertThat(resolver.etat(11, 20)).isEqualTo(CivicThemeState.A_RENFORCER);
        // 0,50 : en dessous.
        assertThat(resolver.etat(10, 20)).isEqualTo(CivicThemeState.FAIBLE);
    }

    @Test
    @DisplayName("Tout raté est FAIBLE — mais avec un dénominateur réel")
    void toutRate() {
        assertThat(resolver.etat(0, 3)).isEqualTo(CivicThemeState.FAIBLE);
        assertThat(CivicDiagnosticThemeResolver.taux(0, 3)).isZero();
    }
}
