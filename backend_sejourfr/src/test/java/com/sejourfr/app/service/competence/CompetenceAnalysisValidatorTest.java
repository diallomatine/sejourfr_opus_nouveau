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

/**
 * Le validateur sous le contrat ACTIF (v3), plus le cas du retour arriere.
 *
 * <p>Ce qu'il protege : une carte de resultat servie a un candidat qui a paye
 * son analyse ne doit jamais porter un champ blanc, un verdict inconnu, un
 * niveau hors profil, ou une « etiquette » de quinze mots.
 */
class CompetenceAnalysisValidatorTest {

    private CompetenceAnalysisValidator validator;

    @BeforeEach
    void setUp() {
        validator = validateur(new CompetenceProperties());
    }

    private static CompetenceAnalysisValidator validateur(CompetenceProperties props) {
        CompetenceRubricsProvider provider =
            new CompetenceRubricsProvider(props, new ObjectMapper());
        provider.load();
        return new CompetenceAnalysisValidator(provider);
    }

    private static Map<String, Object> sortieValide() {
        Map<String, Object> sortie = new LinkedHashMap<>();
        sortie.put(CompetenceAnalysisFields.STATUS, "VALIDATED");
        sortie.put(CompetenceAnalysisFields.LEVEL_REACHED, "A2");
        sortie.put(CompetenceAnalysisFields.VERDICT,
            "Le moment et le lieu sont clairement indiques.");
        sortie.put(CompetenceAnalysisFields.STRENGTH_TAG, "Repere temporel precis");
        sortie.put(CompetenceAnalysisFields.FOCUS_TAG, "Detailler le lieu");
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
        sortie.remove(CompetenceAnalysisFields.FOCUS_TAG);

        assertThat(validator.violations(sortie))
            .anySatisfy(v -> assertThat(v).contains("focus_tag", "absent"));
    }

    @Test
    void champVideEstRefuse() {
        Map<String, Object> sortie = sortieValide();
        sortie.put(CompetenceAnalysisFields.STRENGTH_TAG, "   ");

        // Un champ blanc, c'est une carte de resultat avec une puce vide servie a
        // un candidat qui a paye son analyse.
        assertThat(validator.violations(sortie))
            .anySatisfy(v -> assertThat(v).contains("strength_tag", "vide"));
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
    void niveauHorsProfilTcfIrnEstRefuse() {
        Map<String, Object> sortie = sortieValide();
        sortie.put(CompetenceAnalysisFields.LEVEL_REACHED, "C1");

        // C1 existe dans NiveauCecrl (les productions completes en ont besoin) ;
        // ici il n'a aucun sens, le TCF IRN plafonne au B2.
        assertThat(validator.violations(sortie))
            .anySatisfy(v -> assertThat(v).contains("level_reached", "A1_NON_ATTEINT, A1, A2, B1 ou B2"));
    }

    @Test
    void lesCinqNiveauxDuProfilSontAcceptes() {
        for (String niveau : new String[] {"A1_NON_ATTEINT", "A1", "A2", "B1", "B2"}) {
            Map<String, Object> sortie = sortieValide();
            sortie.put(CompetenceAnalysisFields.LEVEL_REACHED, niveau);
            assertThat(validator.violations(sortie))
                .as("niveau %s", niveau)
                .isEmpty();
        }
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
    void lesChampsDuContratPrecedentSontDesClesEnTrop() {
        Map<String, Object> sortie = sortieValide();
        sortie.put(CompetenceAnalysisFields.IMPROVED_VERSION, "Une reformulation.");

        assertThat(validator.violations(sortie))
            .anySatisfy(v -> assertThat(v).contains("cle hors contrat", "improved_version"));
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

    /**
     * TOLERANCE REELLE SUR UN PETIT PLAFOND (2026-08-11). L'ancienne formule
     * {@code floor(3 * 1,2)} rendait 3 : sur les etiquettes de trois mots, la
     * tolerance annoncee n'existait pas, et une analyse deja payee se perdait pour
     * un mot. Un plafond tolere desormais toujours au moins un mot de plus.
     */
    @Test
    void uneEtiquetteDUnMotDeTropPasse() {
        Map<String, Object> sortie = sortieValide();
        sortie.put(CompetenceAnalysisFields.FOCUS_TAG, mots(4)); // plafond 3, tolere 4

        assertThat(validator.violations(sortie))
            .as("perdre une analyse deja payee pour un mot serait absurde")
            .isEmpty();
    }

    @Test
    void uneEtiquetteBavardeEstRefusee() {
        Map<String, Object> sortie = sortieValide();
        // Plafond 3, tolere 4 : a cinq mots, ce n'est plus une etiquette.
        sortie.put(CompetenceAnalysisFields.FOCUS_TAG, mots(5));

        assertThat(validator.violations(sortie))
            .anySatisfy(v -> assertThat(v).contains("focus_tag", "5 mots", "maximum est 3"));
    }

    @Test
    void chaqueEtiquetteEstControleeSeparement() {
        Map<String, Object> sortie = sortieValide();
        sortie.put(CompetenceAnalysisFields.STRENGTH_TAG, mots(6));
        sortie.put(CompetenceAnalysisFields.FOCUS_TAG, mots(7));

        assertThat(validator.violations(sortie)).hasSize(2);
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

    /**
     * RETOUR ARRIERE REEL : sous le contrat v2, ce sont les champs de v2 qui sont
     * exiges. Sans cette lecture version par version, un
     * {@code COMPETENCE_TOOL_SCHEMA_VERSION=v2} aurait produit des sorties
     * valides pour le fournisseur et systematiquement refusees par nous.
     */
    @Test
    void sousLeContratV2CeSontLesChampsDeV2QuiSontExiges() {
        CompetenceProperties props = new CompetenceProperties();
        props.getAnalysis().setRubricsVersion("v2");
        props.getAnalysis().setToolSchemaVersion("v2");
        CompetenceAnalysisValidator v2 = validateur(props);

        Map<String, Object> ancienne = new LinkedHashMap<>();
        ancienne.put(CompetenceAnalysisFields.STATUS, "VALIDATED");
        ancienne.put(CompetenceAnalysisFields.VERDICT, "Le critere est atteint.");
        ancienne.put(CompetenceAnalysisFields.SUCCESS_POINT, "Vous situez la scene.");
        ancienne.put(CompetenceAnalysisFields.IMPROVEMENT_PRIORITY, "Rien de prioritaire ici.");
        ancienne.put(CompetenceAnalysisFields.IMPROVED_VERSION, "La semaine derniere, au marche.");

        assertThat(v2.violations(ancienne)).isEmpty();
        assertThat(v2.violations(sortieValide()))
            .as("une sortie v3 n'a rien a faire sous un contrat v2")
            .isNotEmpty();
    }
}
