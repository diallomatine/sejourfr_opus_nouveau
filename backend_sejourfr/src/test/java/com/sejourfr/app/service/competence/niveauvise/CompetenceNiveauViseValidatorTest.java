package com.sejourfr.app.service.competence.niveauvise;

import com.sejourfr.app.config.CompetenceProperties;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.ObjectMapper;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import java.util.stream.IntStream;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Le validateur du SECOND appel — et ce qu'il ne juge PLUS.
 *
 * <p>Depuis le 2026-08-12 (alignement sur les productions), les {@code segments}
 * ne passent plus par ici : ils sont un confort de lecture, filtres un a un par
 * {@code SegmentsSurlignage} et verrouilles par {@code SegmentsSurlignageTest}.
 * Ce que ce validateur tient, c'est la <b>structure</b> du bloc et son
 * <b>texte</b> : eux seuls peuvent faire tomber la section.
 */
class CompetenceNiveauViseValidatorTest {

    private static final String TEXTE =
        "Bonjour, serait-il possible d'obtenir un rendez-vous jeudi prochain ? "
            + "Je vous remercie par avance.";

    private static final int MAX_LEVIERS = 3;

    private CompetenceNiveauViseValidator validator;

    @BeforeEach
    void setUp() {
        CompetenceNiveauViseRubricsProvider rubrics =
            new CompetenceNiveauViseRubricsProvider(new CompetenceProperties(), new ObjectMapper());
        rubrics.load();
        validator = new CompetenceNiveauViseValidator(rubrics);
    }

    // ------------------------------------------------------------ fabriques

    private static Map<String, Object> levier(String action, String exemple) {
        Map<String, Object> l = new LinkedHashMap<>();
        l.put(CompetenceNiveauViseFields.ACTION, action);
        l.put(CompetenceNiveauViseFields.EXEMPLE, exemple);
        return l;
    }

    private static Map<String, Object> segment(String extrait, String apport) {
        Map<String, Object> s = new LinkedHashMap<>();
        s.put(CompetenceNiveauViseFields.EXTRAIT, extrait);
        s.put(CompetenceNiveauViseFields.APPORT, apport);
        return s;
    }

    static Map<String, Object> sortieValide() {
        Map<String, Object> exemple = new LinkedHashMap<>();
        exemple.put(CompetenceNiveauViseFields.TEXTE, TEXTE);
        exemple.put(CompetenceNiveauViseFields.SEGMENTS, new ArrayList<>(List.of(
            segment("serait-il possible d'obtenir un rendez-vous", "plus poli"),
            segment("Je vous remercie par avance", "cloture soignee"))));

        Map<String, Object> aRetenir = new LinkedHashMap<>();
        aRetenir.put(CompetenceNiveauViseFields.FORMULE, "Serait-il possible de + infinitif");
        aRetenir.put(CompetenceNiveauViseFields.EXPLICATION,
            "Pour demander quelque chose sans donner d'ordre.");

        Map<String, Object> sortie = new LinkedHashMap<>();
        sortie.put(CompetenceNiveauViseFields.LEVIERS, new ArrayList<>(List.of(
            levier("Formule ta demande plus poliment", "Serait-il possible de"),
            levier("Remercie a la fin", "Je vous remercie"))));
        sortie.put(CompetenceNiveauViseFields.EXEMPLE_CIBLE, exemple);
        sortie.put(CompetenceNiveauViseFields.A_RETENIR, aRetenir);
        return sortie;
    }

    @SuppressWarnings("unchecked")
    private static Map<String, Object> exempleCible(Map<String, Object> sortie) {
        return (Map<String, Object>) sortie.get(CompetenceNiveauViseFields.EXEMPLE_CIBLE);
    }

    @SuppressWarnings("unchecked")
    private static List<Map<String, Object>> segments(Map<String, Object> sortie) {
        return (List<Map<String, Object>>)
            exempleCible(sortie).get(CompetenceNiveauViseFields.SEGMENTS);
    }

    private static String mots(int n) {
        return IntStream.range(0, n).mapToObj(i -> "mot").collect(Collectors.joining(" "));
    }

    // ---------------------------------------------------------------- tests

    @Test
    void sortieConformeAucuneViolation() {
        assertThat(validator.violations(sortieValide(), MAX_LEVIERS)).isEmpty();
    }

    @Test
    void sortieVideEstRefusee() {
        assertThat(validator.violations(null, MAX_LEVIERS)).isNotEmpty();
        assertThat(validator.violations(Map.of(), MAX_LEVIERS)).isNotEmpty();
    }

    // -------------------------------- le texte, et lui seul, tient la section

    /**
     * ⚠️ REMPLACE l'ancien gel « un extrait invente est refuse » : il faisait
     * tomber tout le bloc — leviers et tournure a retenir compris — pour un
     * surlignage. Le segment fautif est desormais RETIRE par
     * {@code SegmentsSurlignage} ; le validateur, lui, n'a plus rien a en dire.
     */
    @Test
    void unExtraitInventeNEstPlusUneViolation() {
        Map<String, Object> sortie = sortieValide();
        segments(sortie).get(0).put(
            CompetenceNiveauViseFields.EXTRAIT, "veuillez agreer mes salutations");

        assertThat(validator.violations(sortie, MAX_LEVIERS)).isEmpty();
    }

    /** ⚠️ REMPLACE « moins de deux segments est refuse » et « un apport bavard est refuse ». */
    @Test
    void desSegmentsAbsentsMalTypesOuUniquesNeFontPlusTomberLaSection() {
        Map<String, Object> sansSegments = sortieValide();
        exempleCible(sansSegments).remove(CompetenceNiveauViseFields.SEGMENTS);
        assertThat(validator.violations(sansSegments, MAX_LEVIERS)).isEmpty();

        Map<String, Object> malTypes = sortieValide();
        exempleCible(malTypes).put(CompetenceNiveauViseFields.SEGMENTS, "pas une liste");
        assertThat(validator.violations(malTypes, MAX_LEVIERS)).isEmpty();

        Map<String, Object> unSeul = sortieValide();
        exempleCible(unSeul).put(CompetenceNiveauViseFields.SEGMENTS,
            List.of(segment("jeudi prochain", mots(12))));
        assertThat(validator.violations(unSeul, MAX_LEVIERS)).isEmpty();
    }

    /** Le TEXTE, lui, reste obligatoire : sans lui il n'y a plus rien a montrer. */
    @Test
    void unTexteModeleAbsentOuVideFaitTomberLaSection() {
        Map<String, Object> absent = sortieValide();
        exempleCible(absent).remove(CompetenceNiveauViseFields.TEXTE);
        assertThat(validator.violations(absent, MAX_LEVIERS))
            .anySatisfy(v -> assertThat(v).contains("exemple_cible.texte", "absent"));

        Map<String, Object> vide = sortieValide();
        exempleCible(vide).put(CompetenceNiveauViseFields.TEXTE, "   ");
        assertThat(validator.violations(vide, MAX_LEVIERS))
            .anySatisfy(v -> assertThat(v).contains("exemple_cible.texte", "vide"));
    }

    @Test
    void uneCleHorsContratDansLExempleCibleResteUneViolation() {
        Map<String, Object> sortie = sortieValide();
        exempleCible(sortie).put("note", 14);

        assertThat(validator.violations(sortie, MAX_LEVIERS))
            .anySatisfy(v -> assertThat(v).contains("cle hors contrat", "exemple_cible.note"));
    }

    /** Une sortie vide se compte a part : elle ne se corrige pas comme un champ fautif. */
    @Test
    void uneSortieVideEstNommeeCommeTelle() {
        assertThat(validator.violations(Map.of(), MAX_LEVIERS)).singleElement().satisfies(v ->
            assertThat(v).startsWith(CompetenceNiveauViseValidator.VIOLATION_SORTIE_VIDE));
    }

    // ------------------------------------------------------------- leviers

    @Test
    void moinsDeDeuxLeviersEstRefuse() {
        Map<String, Object> sortie = sortieValide();
        sortie.put(CompetenceNiveauViseFields.LEVIERS,
            List.of(levier("Formule ta demande poliment", "Serait-il possible de")));

        assertThat(validator.violations(sortie, MAX_LEVIERS))
            .anySatisfy(v -> assertThat(v).contains("leviers", "au moins 2"));
    }

    @Test
    void plusDeTroisLeviersEstRefuse() {
        Map<String, Object> sortie = sortieValide();
        sortie.put(CompetenceNiveauViseFields.LEVIERS, List.of(
            levier("Un", "un"), levier("Deux", "deux"),
            levier("Trois", "trois"), levier("Quatre", "quatre")));

        assertThat(validator.violations(sortie, MAX_LEVIERS))
            .anySatisfy(v -> assertThat(v).contains("leviers", "maximum est 3"));
    }

    @Test
    void unLevierIncompletEstRefuse() {
        Map<String, Object> sortie = sortieValide();
        sortie.put(CompetenceNiveauViseFields.LEVIERS, List.of(
            Map.of(CompetenceNiveauViseFields.ACTION, "Formule ta demande poliment"),
            levier("Remercie a la fin", "Je vous remercie")));

        assertThat(validator.violations(sortie, MAX_LEVIERS))
            .anySatisfy(v -> assertThat(v).contains("leviers[1].exemple", "absent"));
    }

    @Test
    void uneActionBavardeEstRefusee() {
        Map<String, Object> sortie = sortieValide();
        // Plafond 6 mots, tolerance 1,2 -> 7 : huit mots, ce n'est plus une action.
        sortie.put(CompetenceNiveauViseFields.LEVIERS, List.of(
            levier(mots(8), "Serait-il possible de"),
            levier("Remercie a la fin", "Je vous remercie")));

        assertThat(validator.violations(sortie, MAX_LEVIERS))
            .anySatisfy(v -> assertThat(v).contains("leviers[1].action", "8 mots", "maximum est 6"));
    }

    // ----------------------------------------------------------- a retenir

    @Test
    void uneExplicationBavardeEstRefusee() {
        Map<String, Object> sortie = sortieValide();
        @SuppressWarnings("unchecked")
        Map<String, Object> aRetenir =
            (Map<String, Object>) sortie.get(CompetenceNiveauViseFields.A_RETENIR);
        aRetenir.put(CompetenceNiveauViseFields.EXPLICATION, mots(20));

        assertThat(validator.violations(sortie, MAX_LEVIERS))
            .anySatisfy(v -> assertThat(v).contains("explication", "maximum est 14"));
    }

    @Test
    void unBlocARetenirManquantEstRefuse() {
        Map<String, Object> sortie = sortieValide();
        sortie.remove(CompetenceNiveauViseFields.A_RETENIR);

        assertThat(validator.violations(sortie, MAX_LEVIERS))
            .anySatisfy(v -> assertThat(v).contains("a_retenir", "absent"));
    }

    @Test
    void toutesLesViolationsSontCollectees() {
        Map<String, Object> sortie = sortieValide();
        sortie.put("bonus", "x");
        sortie.remove(CompetenceNiveauViseFields.A_RETENIR);
        exempleCible(sortie).remove(CompetenceNiveauViseFields.TEXTE);

        // Une violation par appel couterait un appel LLM par violation.
        assertThat(validator.violations(sortie, MAX_LEVIERS)).hasSize(3);
    }
}
