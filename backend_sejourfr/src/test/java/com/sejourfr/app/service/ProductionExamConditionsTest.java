package com.sejourfr.app.service;

import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.entity.TcfDiagnosticSession;
import com.sejourfr.app.enums.EpreuveType;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * « Cette tache se passe-t-elle en conditions reelles ? » — le derive serveur
 * que les deux runners affichent.
 *
 * <p>Ce que ce test verrouille, c'est la <b>borne</b> de l'assouplissement :
 * EO1 et EO2, dans un diagnostic, et rien d'autre. L'examen blanc reste un
 * examen — c'est la regression qui couterait le plus cher.
 */
class ProductionExamConditionsTest {

    private static ProductionTask task(EpreuveType epreuve, int tache) {
        ProductionTask t = new ProductionTask();
        t.setEpreuve(epreuve);
        t.setTacheNumero((short) tache);
        return t;
    }

    /** Une section d'un diagnostic : sous-attempt rattache a la session. */
    private static Attempt sectionDeDiagnostic(EpreuveType epreuve) {
        Attempt parent = new Attempt();
        parent.setEpreuve(EpreuveType.TCF_COMPLET);
        parent.setTcfDiagnostic(new TcfDiagnosticSession());

        Attempt sub = new Attempt();
        sub.setEpreuve(epreuve);
        sub.setParentAttempt(parent);
        sub.setTcfDiagnostic(parent.getTcfDiagnostic());
        return sub;
    }

    /** Une epreuve d'un examen blanc complet : meme forme, sans diagnostic. */
    private static Attempt epreuveDExamenBlanc(EpreuveType epreuve) {
        Attempt parent = new Attempt();
        parent.setEpreuve(EpreuveType.TCF_COMPLET);
        parent.setSlotNumber(1);

        Attempt sub = new Attempt();
        sub.setEpreuve(epreuve);
        sub.setParentAttempt(parent);
        return sub;
    }

    @Test
    @DisplayName("Diagnostic : EO1 et EO2 ne sont PAS en conditions réelles")
    void diagnosticEoUnEtDeux() {
        Attempt eo = sectionDeDiagnostic(EpreuveType.TCF_EO);

        assertThat(ProductionExamConditions.conditionsReelles(eo, task(EpreuveType.TCF_EO, 1)))
                .isFalse();
        assertThat(ProductionExamConditions.conditionsReelles(eo, task(EpreuveType.TCF_EO, 2)))
                .isFalse();
    }

    @Test
    @DisplayName("🛑 Diagnostic : EO3 garde les conditions d'examen")
    void diagnosticEoTrois() {
        Attempt eo = sectionDeDiagnostic(EpreuveType.TCF_EO);

        assertThat(ProductionExamConditions.conditionsReelles(eo, task(EpreuveType.TCF_EO, 3)))
                .isTrue();
    }

    @Test
    @DisplayName("🛑 Diagnostic : l'expression ÉCRITE n'est pas assouplie")
    void diagnosticEcritInchange() {
        Attempt ee = sectionDeDiagnostic(EpreuveType.TCF_EE);

        assertThat(ProductionExamConditions.conditionsReelles(ee, task(EpreuveType.TCF_EE, 1)))
                .isTrue();
    }

    @Test
    @DisplayName("🛑 L'examen blanc reste un examen, y compris sur EO1 et EO2")
    void examenBlancInchange() {
        Attempt eo = epreuveDExamenBlanc(EpreuveType.TCF_EO);

        assertThat(ProductionExamConditions.conditionsReelles(eo, task(EpreuveType.TCF_EO, 1)))
                .isTrue();
        assertThat(ProductionExamConditions.conditionsReelles(eo, task(EpreuveType.TCF_EO, 2)))
                .isTrue();
    }

    @Test
    @DisplayName("Contexte inconnu ⇒ conditions réelles : on n'ouvre jamais par défaut")
    void defautConservateur() {
        assertThat(ProductionExamConditions.conditionsReelles(null, task(EpreuveType.TCF_EO, 1)))
                .isTrue();
        assertThat(ProductionExamConditions.conditionsReelles(
                epreuveDExamenBlanc(EpreuveType.TCF_EO), null)).isTrue();
    }
}
