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
 * Le validateur du SECOND appel, et surtout le controle qui n'existe nulle part
 * ailleurs : <b>chaque {@code extrait} est une sous-chaine exacte du texte
 * modele</b>. Le front surligne ces passages ; un extrait absent afficherait au
 * candidat une phrase presentee comme un morceau du modele alors qu'elle n'en
 * fait pas partie.
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

    // ---------------------------------------- extrait sous-chaine du texte

    @Test
    void unExtraitInventeEstRefuse() {
        Map<String, Object> sortie = sortieValide();
        segments(sortie).get(0).put(
            CompetenceNiveauViseFields.EXTRAIT, "veuillez agreer mes salutations");

        List<String> violations = validator.violations(sortie, MAX_LEVIERS);

        assertThat(violations).anySatisfy(v -> assertThat(v)
            .startsWith(CompetenceNiveauViseValidator.VIOLATION_EXTRAIT)
            .contains("veuillez agreer mes salutations"));
        assertThat(CompetenceNiveauViseValidator.uniquementExtraits(violations))
            .as("ce defaut-la, et lui seul, ouvre droit a une reparation")
            .isTrue();
    }

    @Test
    void unExtraitReformuleOuRaccourciEstRefuse() {
        Map<String, Object> sortie = sortieValide();
        // Le passage existe... presque : ellipse au milieu, casse changee.
        segments(sortie).get(0).put(
            CompetenceNiveauViseFields.EXTRAIT, "Serait-il possible… un rendez-vous");

        assertThat(validator.violations(sortie, MAX_LEVIERS)).anySatisfy(v -> assertThat(v)
            .startsWith(CompetenceNiveauViseValidator.VIOLATION_EXTRAIT));
    }

    @Test
    void unExtraitRecopieMotPourMotEstAccepte() {
        Map<String, Object> sortie = sortieValide();
        segments(sortie).get(0).put(CompetenceNiveauViseFields.EXTRAIT, "jeudi prochain");

        assertThat(validator.violations(sortie, MAX_LEVIERS)).isEmpty();
    }

    @Test
    void uneViolationDeStructureNouvreDroitAAucuneReparation() {
        Map<String, Object> sortie = sortieValide();
        sortie.put("bonus", "x");
        segments(sortie).get(0).put(CompetenceNiveauViseFields.EXTRAIT, "phrase inventee");

        List<String> violations = validator.violations(sortie, MAX_LEVIERS);

        assertThat(violations).hasSizeGreaterThanOrEqualTo(2);
        assertThat(CompetenceNiveauViseValidator.uniquementExtraits(violations))
            .as("une sortie structurellement fausse ne merite pas un second appel paye")
            .isFalse();
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

    // ------------------------------------------------------------ segments

    @Test
    void moinsDeDeuxSegmentsEstRefuse() {
        Map<String, Object> sortie = sortieValide();
        exempleCible(sortie).put(CompetenceNiveauViseFields.SEGMENTS,
            List.of(segment("jeudi prochain", "plus precis")));

        assertThat(validator.violations(sortie, MAX_LEVIERS))
            .anySatisfy(v -> assertThat(v).contains("segments", "il en faut 2 a 3"));
    }

    @Test
    void unApportBavardEstRefuse() {
        Map<String, Object> sortie = sortieValide();
        segments(sortie).get(0).put(CompetenceNiveauViseFields.APPORT, mots(5));

        assertThat(validator.violations(sortie, MAX_LEVIERS))
            .anySatisfy(v -> assertThat(v).contains("apport", "5 mots", "maximum est 3"));
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
        segments(sortie).get(0).put(CompetenceNiveauViseFields.EXTRAIT, "phrase inventee");

        // Une violation par appel couterait un appel LLM par violation.
        assertThat(validator.violations(sortie, MAX_LEVIERS)).hasSize(3);
    }
}
