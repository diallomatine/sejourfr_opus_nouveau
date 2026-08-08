package com.sejourfr.app.service.competence;

import com.sejourfr.app.config.CompetenceProperties;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.ObjectMapper;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.stream.Collectors;
import java.util.stream.IntStream;

import static org.assertj.core.api.Assertions.assertThat;

class CompetenceAnalysisValidatorTest {

    private CompetenceAnalysisValidator validator;

    @BeforeEach
    void setUp() {
        CompetenceRubricsProvider provider =
            new CompetenceRubricsProvider(new CompetenceProperties(), new ObjectMapper());
        provider.load();
        validator = new CompetenceAnalysisValidator(provider);
    }

    private static Map<String, Object> sortieValide() {
        Map<String, Object> sortie = new LinkedHashMap<>();
        sortie.put(CompetenceAnalysisFields.STATUS, "VALIDATED");
        sortie.put(CompetenceAnalysisFields.VERDICT, "Le moment et le lieu sont clairement indiques.");
        sortie.put(CompetenceAnalysisFields.SUCCESS_POINT,
            "Vous utilisez un repere temporel precis et vous situez l'action dans un restaurant.");
        sortie.put(CompetenceAnalysisFields.IMPROVEMENT_PRIORITY,
            "Aucune correction prioritaire pour ce critere ; gardez cette precision dans le recit complet.");
        sortie.put(CompetenceAnalysisFields.IMPROVED_VERSION,
            "La semaine derniere, je suis alle dans un restaurant du centre-ville avec mes amis.");
        return sortie;
    }

    /** Genere un texte de n mots, pour tester les plafonds au mot pres. */
    private static String mots(int n) {
        return IntStream.range(0, n).mapToObj(i -> "mot").collect(Collectors.joining(" "));
    }

    @Test
    void sortieConformeAucuneViolation() {
        assertThat(validator.violations(sortieValide())).isEmpty();
    }

    @Test
    void sortieVideEstRefusee() {
        assertThat(validator.violations(Map.of())).isNotEmpty();
        assertThat(validator.violations(null)).isNotEmpty();
    }

    @Test
    void cleManquanteEstSignalee() {
        Map<String, Object> sortie = sortieValide();
        sortie.remove(CompetenceAnalysisFields.IMPROVED_VERSION);

        assertThat(validator.violations(sortie))
            .anySatisfy(v -> assertThat(v).contains("improved_version", "absent"));
    }

    @Test
    void champVideEstRefuse() {
        Map<String, Object> sortie = sortieValide();
        sortie.put(CompetenceAnalysisFields.SUCCESS_POINT, "   ");

        // Un champ blanc, c'est une carte de resultat avec un bloc vide servie a
        // un candidat qui a paye son analyse.
        assertThat(validator.violations(sortie))
            .anySatisfy(v -> assertThat(v).contains("success_point", "vide"));
    }

    @Test
    void statusHorsEnumEstRefuse() {
        Map<String, Object> sortie = sortieValide();
        sortie.put(CompetenceAnalysisFields.STATUS, "PRESQUE_VALIDE");

        assertThat(validator.violations(sortie))
            .anySatisfy(v -> assertThat(v).contains("status", "VALIDATED, PARTIAL ou NOT_VALIDATED"));
    }

    @Test
    void statusNonTextuelEstRefuse() {
        Map<String, Object> sortie = sortieValide();
        sortie.put(CompetenceAnalysisFields.STATUS, 1);

        assertThat(validator.violations(sortie))
            .anySatisfy(v -> assertThat(v).contains("status", "chaine"));
    }

    @Test
    void cleEnTropEstRefusee() {
        Map<String, Object> sortie = sortieValide();
        sortie.put("note_globale", "14/20");

        // Le contrat ne prevoit aucune note : si le correcteur en glisse une, la
        // sortie est rejetee, pas nettoyee en silence.
        assertThat(validator.violations(sortie))
            .anySatisfy(v -> assertThat(v).contains("cle hors contrat", "note_globale"));
    }

    @Test
    void longueurDansLaToleranceDeVingtPourCentPasse() {
        Map<String, Object> sortie = sortieValide();
        sortie.put(CompetenceAnalysisFields.VERDICT, mots(24)); // plafond 20, tolere 24

        assertThat(validator.violations(sortie))
            .as("perdre une analyse deja payee pour quatre mots de trop serait absurde")
            .isEmpty();
    }

    @Test
    void longueurAuDelaDeLaToleranceEstRefusee() {
        Map<String, Object> sortie = sortieValide();
        sortie.put(CompetenceAnalysisFields.VERDICT, mots(25));

        assertThat(validator.violations(sortie))
            .anySatisfy(v -> assertThat(v).contains("verdict", "25 mots", "maximum est 20"));
    }

    @Test
    void chaqueChampPlafonneEstControle() {
        Map<String, Object> sortie = sortieValide();
        sortie.put(CompetenceAnalysisFields.SUCCESS_POINT, mots(37));       // plafond 30, tolere 36
        sortie.put(CompetenceAnalysisFields.IMPROVEMENT_PRIORITY, mots(43)); // plafond 35, tolere 42

        assertThat(validator.violations(sortie)).hasSize(2);
    }

    @Test
    void laReformulationNEstPasPlafonneeEnMots() {
        Map<String, Object> sortie = sortieValide();
        // La specification demande une longueur « proche de la production
        // demandee » : un recit de trois phrases n'est pas une violation.
        sortie.put(CompetenceAnalysisFields.IMPROVED_VERSION, mots(60));

        assertThat(validator.violations(sortie)).isEmpty();
    }

    @Test
    void toutesLesViolationsSontCollectees() {
        Map<String, Object> sortie = sortieValide();
        sortie.put(CompetenceAnalysisFields.STATUS, "INCONNU");
        sortie.put(CompetenceAnalysisFields.VERDICT, "");
        sortie.put("bonus", "x");

        // Une violation par appel couterait un appel LLM par violation.
        assertThat(validator.violations(sortie)).hasSize(3);
    }
}
