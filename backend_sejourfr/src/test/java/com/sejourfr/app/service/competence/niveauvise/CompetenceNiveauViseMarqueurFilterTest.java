package com.sejourfr.app.service.competence.niveauvise;

import com.sejourfr.app.enums.TargetLevel;
import org.junit.jupiter.api.Test;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * LE FILET DES MARQUEURS DU PALIER — ce que le texte modele prouve, verifie sur
 * le texte lui-meme.
 *
 * <p>Invariant a ne pas casser : <b>un marqueur retire ne fait jamais tomber la
 * section</b>. Ce filet nettoie et mesure ; ce qui tient la regle, c'est le
 * tool-schema v2 qui REQUIERT deux a trois marqueurs recopies du texte.
 */
class CompetenceNiveauViseMarqueurFilterTest {

    private static final String TEXTE =
        "Bonjour, serait-il possible d'obtenir un rendez-vous jeudi prochain, "
            + "ce qui m'arrangerait beaucoup ? Je vous remercie par avance.";

    private static Map<String, Object> marqueur(String extrait, String type) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put(CompetenceNiveauViseFields.EXTRAIT, extrait);
        m.put(CompetenceNiveauViseFields.TYPE, type);
        return m;
    }

    @Test
    void unMarqueurValideEstConserveEtSonExtraitResoluSurLeTexte() {
        // Apostrophe COURBE rendue par le modele, apostrophe droite dans le
        // texte : la comparaison neutralise la typographie, et l'extrait servi
        // est la sous-chaine ORIGINALE exacte — le front surligne par simple
        // recherche de chaine.
        CompetenceNiveauViseMarqueurFilter.Resultat resultat =
            CompetenceNiveauViseMarqueurFilter.purge(List.of(
                marqueur("ce qui m’arrangerait beaucoup", "SUBORDINATION")),
                TEXTE, TargetLevel.B1);

        assertThat(resultat.retires()).isEmpty();
        assertThat(resultat.gardes()).singleElement().satisfies(m ->
            assertThat(TEXTE).contains(
                String.valueOf(m.get(CompetenceNiveauViseFields.EXTRAIT))));
    }

    /** « On ne demontre pas l'A2 en traitant une objection. » */
    @Test
    void unProcedeQuiSurVendLePalierCibleEstRetire() {
        CompetenceNiveauViseMarqueurFilter.Resultat resultat =
            CompetenceNiveauViseMarqueurFilter.purge(List.of(
                marqueur("jeudi prochain", "OBJECTION_TRAITEE")),
                TEXTE, TargetLevel.A2);

        assertThat(resultat.gardes()).isEmpty();
        assertThat(resultat.retires()).singleElement().satisfies(r ->
            assertThat(r.motif())
                .isEqualTo(CompetenceNiveauViseMarqueurFilter.Motif.TYPE_SUR_VENDU));
    }

    /**
     * ON NE PURGE QUE LA SUR-VENTE. Un procede plus modeste que le palier cible
     * reste une preuve legitime de ce que le texte fait : ajuster son registre
     * ne cesse pas d'etre vrai parce qu'on vise le B2.
     */
    @Test
    void unProcedeSousLePalierCibleResteRecevable() {
        CompetenceNiveauViseMarqueurFilter.Resultat resultat =
            CompetenceNiveauViseMarqueurFilter.purge(List.of(
                marqueur("Je vous remercie par avance", "REGISTRE_AJUSTE")),
                TEXTE, TargetLevel.B2);

        assertThat(resultat.gardes()).hasSize(1);
        assertThat(resultat.retires()).isEmpty();
    }

    @Test
    void unTypeHorsEnumerationEstRetire() {
        CompetenceNiveauViseMarqueurFilter.Resultat resultat =
            CompetenceNiveauViseMarqueurFilter.purge(List.of(
                marqueur("jeudi prochain", "ELEGANCE")),
                TEXTE, TargetLevel.B2);

        assertThat(resultat.gardes()).isEmpty();
        assertThat(resultat.retires()).singleElement().satisfies(r ->
            assertThat(r.motif())
                .isEqualTo(CompetenceNiveauViseMarqueurFilter.Motif.TYPE_INCONNU));
    }

    @Test
    void unExtraitIntrouvableOuMalFormeEstRetire() {
        CompetenceNiveauViseMarqueurFilter.Resultat resultat =
            CompetenceNiveauViseMarqueurFilter.purge(List.of(
                marqueur("une phrase jamais ecrite", "SUBORDINATION"),
                "pas un objet",
                Map.of(CompetenceNiveauViseFields.EXTRAIT, "jeudi prochain")),
                TEXTE, TargetLevel.B1);

        assertThat(resultat.gardes()).isEmpty();
        assertThat(resultat.retires()).extracting(
                CompetenceNiveauViseMarqueurFilter.Retire::motif)
            .containsExactly(
                CompetenceNiveauViseMarqueurFilter.Motif.EXTRAIT_INTROUVABLE,
                CompetenceNiveauViseMarqueurFilter.Motif.MALFORME,
                CompetenceNiveauViseMarqueurFilter.Motif.MALFORME);
    }

    /** Sans texte modele, il n'y a rien ou chercher : on ne garde rien. */
    @Test
    void sansTexteModeleAucunMarqueurNEstConserve() {
        assertThat(CompetenceNiveauViseMarqueurFilter.purge(List.of(
            marqueur("jeudi prochain", "LEXIQUE_PRECIS")), "  ", TargetLevel.B1).gardes())
            .isEmpty();
        assertThat(CompetenceNiveauViseMarqueurFilter.purge(null, TEXTE, TargetLevel.B1).gardes())
            .isEmpty();
    }

    /**
     * LA TABLE DES PALIERS est celle de l'enum, et rien d'autre : elle est
     * opposee a la grille au BOOT par {@code CompetenceNiveauViseRubricsProvider}.
     */
    @Test
    void laTableDesProcedesEstCelleDeLEnum() {
        assertThat(MarqueurPalier.table()).containsExactlyInAnyOrderEntriesOf(Map.of(
            "REGISTRE_AJUSTE", "A2",
            "ARTICULATION_LOGIQUE", "A2",
            "SUBORDINATION", "B1",
            "LEXIQUE_PRECIS", "B1",
            "NUANCE", "B2",
            "OBJECTION_TRAITEE", "B2"));
        assertThat(MarqueurPalier.de("subordination")).contains(MarqueurPalier.SUBORDINATION);
        assertThat(MarqueurPalier.de("inconnu")).isEmpty();
        assertThat(MarqueurPalier.de(null)).isEmpty();
    }
}
