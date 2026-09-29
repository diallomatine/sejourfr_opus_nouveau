package com.sejourfr.app.service.diagnostic.exemplecible;

import com.sejourfr.app.util.ProductionTextBounds;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Ce que le serveur refuse dans la sortie BRUTE du second appel du diagnostic.
 *
 * <p>Deux violations seulement sont MECANIQUES — un numero de phrase hors bornes,
 * un texte trop long — et ce sont les seules qui vaudront un appel de reparation.
 * Tout le reste est structurel : le bloc tombe, sans second appel paye.
 *
 * <p><b>Les segments ne sont jamais juges ici</b> : ils sont un confort de
 * lecture, retire un par un par {@code SegmentsSurlignage}. Une liste absente,
 * vide ou mal typee n'est pas une violation, c'est un texte sans surlignage.
 */
class DiagnosticExempleCibleValidatorTest {

    /** 3 phrases citables dans la production de reference. */
    private static final int NB_SEGMENTS = 3;

    private static final ProductionTextBounds BORNES = ProductionTextBounds.of(100, 130, 10, 300);

    private final DiagnosticExempleCibleValidator validator = new DiagnosticExempleCibleValidator();

    /** Sortie conforme, partagee avec le test de service. */
    static Map<String, Object> sortieValide() {
        Map<String, Object> sortie = new LinkedHashMap<>();
        sortie.put(DiagnosticExempleCibleFields.SEGMENT_NUMERO, 2);
        sortie.put(DiagnosticExempleCibleFields.TEXTE,
            "J'ai travaillé deux ans dans un magasin, ce qui m'a appris à gérer les demandes "
                + "des clients même quand l'affluence est forte.");
        List<Map<String, Object>> segments = new ArrayList<>();
        segments.add(segment("ce qui m'a appris à", "lien explicite"));
        segments.add(segment("même quand l'affluence est forte", "précision concrète"));
        sortie.put(DiagnosticExempleCibleFields.SEGMENTS, segments);
        return sortie;
    }

    static Map<String, Object> segment(String extrait, String apport) {
        Map<String, Object> segment = new LinkedHashMap<>();
        segment.put(DiagnosticExempleCibleFields.EXTRAIT, extrait);
        segment.put(DiagnosticExempleCibleFields.APPORT, apport);
        return segment;
    }

    /** Texte de {@code mots} mots, pour eprouver les bornes. */
    static String texteDe(int mots) {
        return ("mot ".repeat(mots)).trim();
    }

    @Test
    void uneSortieConformeNeLeveAucuneViolation() {
        assertThat(validator.violations(sortieValide(), NB_SEGMENTS, BORNES)).isEmpty();
    }

    @Test
    void uneSortieVideEstNommeeAPart() {
        List<String> violations = validator.violations(Map.of(), NB_SEGMENTS, BORNES);

        assertThat(violations).hasSize(1);
        assertThat(violations.getFirst())
            .startsWith(DiagnosticExempleCibleValidator.VIOLATION_SORTIE_VIDE);
        assertThat(DiagnosticExempleCibleValidator.toutesReparables(violations))
            .as("rien n'est exploitable : aucun appel paye ne rachetterait ça")
            .isFalse();
    }

    @Test
    void uneCleHorsContratEstRefusee() {
        Map<String, Object> sortie = sortieValide();
        sortie.put("note_globale", 12);

        List<String> violations = validator.violations(sortie, NB_SEGMENTS, BORNES);

        assertThat(violations).anyMatch(v -> v.startsWith("cle hors contrat"));
        assertThat(DiagnosticExempleCibleValidator.toutesReparables(violations)).isFalse();
    }

    // -------------------------------------------------------- numero de phrase

    @Test
    void unNumeroAuDelaDuDecoupageEstRefuseEtReparable() {
        Map<String, Object> sortie = sortieValide();
        sortie.put(DiagnosticExempleCibleFields.SEGMENT_NUMERO, NB_SEGMENTS + 1);

        List<String> violations = validator.violations(sortie, NB_SEGMENTS, BORNES);

        assertThat(violations).singleElement().asString()
            .startsWith(DiagnosticExempleCibleValidator.VIOLATION_NUMERO)
            .contains("de 1 a " + NB_SEGMENTS);
        assertThat(DiagnosticExempleCibleValidator.toutesReparables(violations))
            .as("un numero hors bornes se nomme exactement, donc se repare")
            .isTrue();
    }

    @Test
    void unNumeroNonEntierEstRefuse() {
        Map<String, Object> sortie = sortieValide();
        sortie.put(DiagnosticExempleCibleFields.SEGMENT_NUMERO, "la deuxième");

        assertThat(validator.violations(sortie, NB_SEGMENTS, BORNES)).singleElement().asString()
            .startsWith(DiagnosticExempleCibleValidator.VIOLATION_NUMERO);
    }

    @Test
    void unNumeroAbsentEstRefuse() {
        Map<String, Object> sortie = sortieValide();
        sortie.remove(DiagnosticExempleCibleFields.SEGMENT_NUMERO);

        assertThat(validator.violations(sortie, NB_SEGMENTS, BORNES)).singleElement().asString()
            .startsWith(DiagnosticExempleCibleValidator.VIOLATION_NUMERO);
    }

    /** Le JSON rend souvent les entiers en {@code Double} : ce n'est pas une faute. */
    @Test
    void unNumeroRenduEnNombreFlottantEntierEstAccepte() {
        Map<String, Object> sortie = sortieValide();
        sortie.put(DiagnosticExempleCibleFields.SEGMENT_NUMERO, 2.0d);

        assertThat(validator.violations(sortie, NB_SEGMENTS, BORNES)).isEmpty();
    }

    // ---------------------------------------------------------------- texte

    @Test
    void unTexteVideFaitTomberLaSection() {
        Map<String, Object> sortie = sortieValide();
        sortie.put(DiagnosticExempleCibleFields.TEXTE, "   ");

        List<String> violations = validator.violations(sortie, NB_SEGMENTS, BORNES);

        assertThat(violations).singleElement().asString().contains("est vide");
        assertThat(DiagnosticExempleCibleValidator.toutesReparables(violations))
            .as("un texte absent n'est pas un defaut mecanique : rien a redemander")
            .isFalse();
    }

    @Test
    void unTexteAuDelaDuPlafondDeLaTacheEstRefuseEtReparable() {
        Map<String, Object> sortie = sortieValide();
        sortie.put(DiagnosticExempleCibleFields.TEXTE, texteDe(BORNES.max() + 10));

        List<String> violations = validator.violations(sortie, NB_SEGMENTS, BORNES);

        assertThat(violations).singleElement().asString()
            .startsWith(DiagnosticExempleCibleValidator.VIOLATION_LONGUEUR);
        assertThat(DiagnosticExempleCibleValidator.toutesReparables(violations)).isTrue();
    }

    /**
     * ⚠️ SEUL LE PLAFOND s'applique. La borne basse de
     * {@link ProductionTextBounds} decrit une production ENTIERE (100 mots au
     * diagnostic), alors qu'on ne reecrit qu'UNE phrase : l'exiger reviendrait a
     * demander une phrase de cent mots, et le bloc ne sortirait jamais.
     */
    @Test
    void unePhraseCourteNEstPasJugeeSurLaBorneBasseDeLaProduction() {
        Map<String, Object> sortie = sortieValide();
        sortie.put(DiagnosticExempleCibleFields.TEXTE, texteDe(12));

        assertThat(BORNES.min()).isEqualTo(100);
        assertThat(validator.violations(sortie, NB_SEGMENTS, BORNES)).isEmpty();
    }

    // ------------------------------------------------------------- segments

    @Test
    void lesSegmentsNeSontJamaisJugesIci() {
        Map<String, Object> sansSegments = sortieValide();
        sansSegments.remove(DiagnosticExempleCibleFields.SEGMENTS);
        Map<String, Object> segmentsMalTypes = sortieValide();
        segmentsMalTypes.put(DiagnosticExempleCibleFields.SEGMENTS, "deux passages");
        Map<String, Object> unSeulSegment = sortieValide();
        unSeulSegment.put(DiagnosticExempleCibleFields.SEGMENTS,
            List.of(segment("phrase inventée", "plus précis")));

        // Un surlignage ne tient pas la section : c'est le TEXTE qui la porte.
        assertThat(validator.violations(sansSegments, NB_SEGMENTS, BORNES)).isEmpty();
        assertThat(validator.violations(segmentsMalTypes, NB_SEGMENTS, BORNES)).isEmpty();
        assertThat(validator.violations(unSeulSegment, NB_SEGMENTS, BORNES)).isEmpty();
    }

    /** Une violation structurelle contamine le lot : plus rien n'est reparable. */
    @Test
    void unMelangeDeViolationsNEstPasReparable() {
        Map<String, Object> sortie = sortieValide();
        sortie.put(DiagnosticExempleCibleFields.SEGMENT_NUMERO, 99);
        sortie.put(DiagnosticExempleCibleFields.TEXTE, "");

        List<String> violations = validator.violations(sortie, NB_SEGMENTS, BORNES);

        assertThat(violations).hasSize(2);
        assertThat(DiagnosticExempleCibleValidator.toutesReparables(violations)).isFalse();
    }
}
