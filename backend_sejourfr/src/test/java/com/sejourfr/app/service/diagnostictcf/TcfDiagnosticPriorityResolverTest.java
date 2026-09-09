package com.sejourfr.app.service.diagnostictcf;

import com.sejourfr.app.config.TcfDiagnosticProperties;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.service.diagnostictcf.TcfDiagnosticPriorityResolver.Priorite;
import com.sejourfr.app.service.diagnostictcf.TcfDiagnosticPriorityResolver.TacheMesuree;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/** Le classement des priorites du diagnostic TCF (10_ §4.4 et §13). */
class TcfDiagnosticPriorityResolverTest {

    private final TcfDiagnosticProperties props = new TcfDiagnosticProperties();
    private final TcfDiagnosticPriorityResolver resolver = new TcfDiagnosticPriorityResolver(props);

    private static TacheMesuree tache(
            EpreuveType epreuve, String code, NiveauCecrl niveauTache,
            NiveauCecrl niveauEpreuve, int aTravailler, int fragiles) {
        return new TacheMesuree(epreuve, code, niveauTache, niveauEpreuve, aTravailler, fragiles);
    }

    /**
     * 🛑 Le test de garde que 10_ §13 exige nommement. Nommer « EO tache 2 »
     * comme priorite sans l'avoir evaluee rendrait la personnalisation fictive :
     * c'est la faute produit que l'arbitrage A2 existe pour empecher.
     */
    @Test
    @DisplayName("🛑 Aucune priorité ne peut nommer une tâche non évaluée")
    void jamaisUneTacheNonEvaluee() {
        List<Priorite> p = resolver.priorites(List.of(
                tache(EpreuveType.TCF_EO, "EO2", null, NiveauCecrl.B1, 3, 2),
                tache(EpreuveType.TCF_EE, "EE3", NiveauCecrl.A2, NiveauCecrl.A2, 1, 0)
        ), NiveauCecrl.B2);

        assertThat(p).extracting(Priorite::taskCode).containsExactly("EE3");
    }

    @Test
    @DisplayName("🛑 Une épreuve déjà au niveau cible ne génère aucune priorité")
    void epreuveAuNiveauNeGenereRien() {
        List<Priorite> p = resolver.priorites(List.of(
                // CO au niveau, malgre des competences fragiles.
                tache(EpreuveType.TCF_CO, null, NiveauCecrl.B2, NiveauCecrl.B2, 4, 4),
                tache(EpreuveType.TCF_EO, "EO3", NiveauCecrl.B1, NiveauCecrl.B1, 1, 0)
        ), NiveauCecrl.B2);

        assertThat(p).extracting(Priorite::epreuve).containsExactly(EpreuveType.TCF_EO);
    }

    @Test
    @DisplayName("Le plafond d'affichage est de 3 priorités (A6)")
    void plafondTroisPriorites() {
        List<Priorite> p = resolver.priorites(List.of(
                tache(EpreuveType.TCF_EO, "EO1", NiveauCecrl.A2, NiveauCecrl.A2, 3, 1),
                tache(EpreuveType.TCF_EO, "EO2", NiveauCecrl.A2, NiveauCecrl.A2, 3, 1),
                tache(EpreuveType.TCF_EO, "EO3", NiveauCecrl.A2, NiveauCecrl.A2, 3, 1),
                tache(EpreuveType.TCF_EE, "EE1", NiveauCecrl.A2, NiveauCecrl.A2, 3, 1),
                tache(EpreuveType.TCF_EE, "EE2", NiveauCecrl.A2, NiveauCecrl.A2, 3, 1)
        ), NiveauCecrl.B2);

        assertThat(p).hasSize(3);
        assertThat(p).extracting(Priorite::rang).containsExactly(1, 2, 3);
    }

    @Test
    @DisplayName("À score égal : EO avant EE avant CE avant CO")
    void egaliteTrancheeParEpreuve() {
        List<Priorite> p = resolver.priorites(List.of(
                tache(EpreuveType.TCF_CO, null, NiveauCecrl.B1, NiveauCecrl.B1, 1, 0),
                tache(EpreuveType.TCF_EE, "EE1", NiveauCecrl.B1, NiveauCecrl.B1, 1, 0),
                tache(EpreuveType.TCF_CE, null, NiveauCecrl.B1, NiveauCecrl.B1, 1, 0),
                tache(EpreuveType.TCF_EO, "EO1", NiveauCecrl.B1, NiveauCecrl.B1, 1, 0)
        ), NiveauCecrl.B2);

        assertThat(p).extracting(Priorite::epreuve)
                .containsExactly(EpreuveType.TCF_EO, EpreuveType.TCF_EE, EpreuveType.TCF_CE);
    }

    @Test
    @DisplayName("Un écart de niveau plus grand passe devant une sévérité plus grande")
    void ecartPrimeSurSeverite() {
        // A2 vise B2 : gap_tache 2 ⇒ 3x2 + 2x2 + 0 = 10
        // B1 vise B2 : gap_tache 1 ⇒ 3x1 + 2x1 + 2 = 7
        List<Priorite> p = resolver.priorites(List.of(
                tache(EpreuveType.TCF_EE, "EE1", NiveauCecrl.B1, NiveauCecrl.B1, 1, 0),
                tache(EpreuveType.TCF_EE, "EE2", NiveauCecrl.A2, NiveauCecrl.A2, 0, 0)
        ), NiveauCecrl.B2);

        assertThat(p).extracting(Priorite::taskCode).containsExactly("EE2", "EE1");
    }

    @Test
    @DisplayName("Le score suit la formule de la spec, à la lettre")
    void formuleDuScore() {
        // gap_tache = 1 (B1 → B2), gap_epreuve = 1, severite = 2x2 + 1x1 = 5
        // sous objectif ⇒ poids 1,0 ⇒ 3x1 + 2x1 + 5 = 10
        int score = resolver.score(
                tache(EpreuveType.TCF_EO, "EO3", NiveauCecrl.B1, NiveauCecrl.B1, 2, 1),
                NiveauCecrl.B2);
        assertThat(score).isEqualTo(10);
    }

    @Test
    @DisplayName("Le poids de 0,3 range une tâche faible d'une épreuve au niveau, il ne l'annule pas")
    void poidsEpreuveAuNiveau() {
        // Epreuve au niveau ⇒ gap_epreuve = 0 ⇒ brut = 3x1 + 0 + 5 = 8, x0,3 = 2
        int score = resolver.score(
                tache(EpreuveType.TCF_EO, "EO3", NiveauCecrl.B1, NiveauCecrl.B2, 2, 1),
                NiveauCecrl.B2);
        assertThat(score).isEqualTo(2);
    }

    @Test
    @DisplayName("Aucune donnée exploitable : aucune priorité, jamais d'exception")
    void entreesVides() {
        assertThat(resolver.priorites(null, NiveauCecrl.B2)).isEmpty();
        assertThat(resolver.priorites(List.of(), NiveauCecrl.B2)).isEmpty();
        assertThat(resolver.priorites(
                List.of(tache(EpreuveType.TCF_EO, "EO1", NiveauCecrl.B1, NiveauCecrl.B1, 1, 0)),
                null))
                .isEmpty();
    }

    @Test
    @DisplayName("Le classement est stable : deux appels rendent le même ordre")
    void classementStable() {
        List<TacheMesuree> taches = List.of(
                tache(EpreuveType.TCF_EE, "EE3", NiveauCecrl.B1, NiveauCecrl.B1, 1, 0),
                tache(EpreuveType.TCF_EE, "EE1", NiveauCecrl.B1, NiveauCecrl.B1, 1, 0),
                tache(EpreuveType.TCF_EE, "EE2", NiveauCecrl.B1, NiveauCecrl.B1, 1, 0));

        // A epreuve et score egaux, c'est le code de tache qui departage — sans
        // quoi un meme diagnostic rendrait deux classements differents.
        assertThat(resolver.priorites(taches, NiveauCecrl.B2))
                .extracting(Priorite::taskCode)
                .isEqualTo(resolver.priorites(taches, NiveauCecrl.B2).stream()
                        .map(Priorite::taskCode).toList())
                .containsExactly("EE1", "EE2", "EE3");
    }
}
