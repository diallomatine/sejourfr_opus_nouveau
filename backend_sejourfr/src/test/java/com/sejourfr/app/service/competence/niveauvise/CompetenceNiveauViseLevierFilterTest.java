package com.sejourfr.app.service.competence.niveauvise;

import com.sejourfr.app.enums.TargetLevel;
import org.junit.jupiter.api.Test;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Le filet « un moyen A2 n'est pas la marche vers un palier superieur », sur les
 * leviers du module Competences.
 *
 * <p>Ce que cette classe verrouille : la purge quand le levier vend un marqueur
 * A2, le silence quand le niveau vise EST A2, et le garde-fou des formules de
 * rejet — sans lequel notre propre ancre « … au lieu de poser "mais" seul »
 * s'effacerait elle-meme.
 */
class CompetenceNiveauViseLevierFilterTest {

    private static Map<String, Object> levier(String action, String exemple) {
        Map<String, Object> l = new LinkedHashMap<>();
        l.put(CompetenceNiveauViseFields.ACTION, action);
        l.put(CompetenceNiveauViseFields.EXEMPLE, exemple);
        return l;
    }

    private static final Map<String, Object> BON =
        levier("Subordonne au lieu de juxtaposer", "bien que ce soit");
    private static final Map<String, Object> AUTRE_BON =
        levier("Nuance ta position", "à condition que");

    /**
     * LE CAS FAUTIF TYPE : l'exemple est un marqueur A2 servi comme la cle du B1.
     * Il est inspecte entre guillemets — ce qu'il est semantiquement, un bout de
     * langue cite.
     */
    @Test
    void unExempleQuiEstUnMarqueurA2EstPurgeQuandOnViseAuDessus() {
        var resultat = CompetenceNiveauViseLevierFilter.purge(
            List.of(levier("Relie tes deux idées", "parce que"), BON), TargetLevel.B1);

        assertThat(resultat.retires()).hasSize(1);
        assertThat(resultat.gardes()).containsExactly(BON);
    }

    @Test
    void memeChoseQuandLeMarqueurEstDansLAction() {
        var resultat = CompetenceNiveauViseLevierFilter.purge(
            List.of(levier("Emploie le connecteur « et »", "Paul et moi"), BON), TargetLevel.B2);

        assertThat(resultat.retires()).hasSize(1);
        assertThat(resultat.gardes()).containsExactly(BON);
    }

    /**
     * Viser A2, c'est justement le moment de conseiller « parce que » — une ancre
     * de notre propre grille de notation l'ORDONNE. Rien n'est purge.
     */
    @Test
    void rienNEstPurgeQuandLeNiveauViseEstA2() {
        List<Map<String, Object>> leviers =
            List.of(levier("Relie tes deux idées", "parce que"), BON);

        var resultat = CompetenceNiveauViseLevierFilter.purge(leviers, TargetLevel.A2);

        assertThat(resultat.retires()).isEmpty();
        assertThat(resultat.gardes()).isEqualTo(leviers);
    }

    @Test
    void rienNEstPurgeSansNiveauVise() {
        List<Map<String, Object>> leviers =
            List.of(levier("Relie tes deux idées", "parce que"), BON);

        assertThat(CompetenceNiveauViseLevierFilter.purge(leviers, null).retires()).isEmpty();
    }

    /**
     * GARDE-FOU DES FORMULES DE REJET. Un levier qui cite un marqueur A2 pour dire
     * ce qu'il faut DEPASSER dit exactement la bonne chose : ce qui suit
     * « au lieu de » n'est jamais inspecte. Sans lui, notre propre ancre few-shot
     * se purgerait elle-meme.
     */
    @Test
    void unMarqueurCiteApresUneFormuleDeRejetNestPasPurge() {
        Map<String, Object> ancre = levier(
            "Annonce l'objection puis réponds", "au lieu de « mais » seul");

        var resultat = CompetenceNiveauViseLevierFilter.purge(
            List.of(ancre, AUTRE_BON), TargetLevel.B2);

        assertThat(resultat.retires()).isEmpty();
        assertThat(resultat.gardes()).containsExactly(ancre, AUTRE_BON);
    }

    /**
     * L'egalite avec le marqueur doit etre EXACTE : une formule qui le CONTIENT
     * sans s'y reduire n'est pas un marqueur A2 vendu comme la marche suivante.
     */
    @Test
    void uneFormuleQuiContientUnMarqueurSansSYReduireEstConservee() {
        Map<String, Object> subtil = levier("Enchaîne avec une relative", "ce qui me permet");

        var resultat = CompetenceNiveauViseLevierFilter.purge(
            List.of(subtil, AUTRE_BON), TargetLevel.B2);

        assertThat(resultat.retires()).isEmpty();
    }

    @Test
    void leLevierTombeEnEntierPasSeulementSonExemple() {
        Map<String, Object> fautif = levier("Relie tes idées", "mais");

        var resultat = CompetenceNiveauViseLevierFilter.purge(
            List.of(fautif, BON, AUTRE_BON), TargetLevel.B2);

        // Un demi-levier ne s'applique pas : action et exemple forment un couple.
        assertThat(resultat.retires()).containsExactly(fautif);
        assertThat(resultat.gardes()).containsExactly(BON, AUTRE_BON);
    }

    @Test
    void leLibelleReprendLActionEtLExemple() {
        assertThat(CompetenceNiveauViseLevierFilter.libelle(BON))
            .isEqualTo("Subordonne au lieu de juxtaposer — « bien que ce soit »");
    }

    @Test
    void uneListeVideNeCasseRien() {
        assertThat(CompetenceNiveauViseLevierFilter.purge(List.of(), TargetLevel.B2).gardes())
            .isEmpty();
        assertThat(CompetenceNiveauViseLevierFilter.purge(null, TargetLevel.B2).gardes()).isEmpty();
    }
}
