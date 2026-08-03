package com.sejourfr.app.service;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.manager.ProductionTaskManager;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import tools.jackson.databind.ObjectMapper;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ProductionRubricsValidatorTest {

    @Mock
    private ProductionRubricsProvider rubrics;
    @Mock
    private ProductionTaskManager taskManager;

    private ProductionRubricsValidator validator() {
        return new ProductionRubricsValidator(rubrics, taskManager);
    }

    // ---------------------------------------------------------------- fixtures

    private Map<String, Object> validCommun() {
        return Map.of(
                "sections", List.of(Map.of("titre", "Role", "contenu", "...")),
                "few_shot", List.of(Map.of("niveau", "A2")));
    }

    private Map<String, Object> critere(String code, double poids) {
        return Map.of("code", code, "poids", poids);
    }

    /** Rubrique minimale valide : les 3 codes obligatoires + les champs rendus dans le prompt. */
    private Map<String, Object> rubric(List<Map<String, Object>> criteres) {
        Map<String, Object> r = new LinkedHashMap<>();
        r.put("criteres", criteres);
        r.put("bareme_note", "bareme de la tache");
        r.put("descripteurs", Map.of("A2", "descripteur A2"));
        r.put("consignes_correcteur", "consignes de la tache");
        return r;
    }

    private List<Map<String, Object>> criteresValides() {
        return List.of(
                critere("lexique", 0.4),
                critere("morphosyntaxe", 0.4),
                critere("coherence", 0.2));
    }

    /** Les 6 rubriques attendues, toutes valides. */
    private Map<String, Map<String, Object>> sixRubriques() {
        Map<String, Map<String, Object>> all = new LinkedHashMap<>();
        for (String cle : List.of("EE_T1", "EE_T2", "EE_T3", "EO_T1", "EO_T2", "EO_T3")) {
            all.put(cle, rubric(criteresValides()));
        }
        return all;
    }

    private void stub(Map<String, Map<String, Object>> all) {
        when(rubrics.getCommun()).thenReturn(validCommun());
        when(rubrics.all()).thenReturn(all);
        lenient().when(taskManager.findAllActive()).thenReturn(List.of());
    }

    // ------------------------------------------------- fichiers reels (v3, v4)

    private ProductionRubricsProvider realProvider(String version) {
        ProductionEvaluationProperties props = new ProductionEvaluationProperties();
        props.setRubricsVersion(version);
        ProductionRubricsProvider provider = new ProductionRubricsProvider(props, new ObjectMapper());
        provider.load();
        return provider;
    }

    /** Non-regression : les rubriques v3 (4 criteres universels) doivent continuer a demarrer. */
    @Test
    void validate_realV3File_noThrow() {
        when(taskManager.findAllActive()).thenReturn(List.of());
        ProductionRubricsValidator v =
                new ProductionRubricsValidator(realProvider("v3"), taskManager);

        assertThatCode(v::validate).doesNotThrowAnyException();
    }

    /** Le contrat v4 lui-meme : 6 taches, poids a 1.00, codes obligatoires presents. */
    @Test
    void validate_realV4File_noThrow() {
        when(taskManager.findAllActive()).thenReturn(List.of());
        ProductionRubricsValidator v =
                new ProductionRubricsValidator(realProvider("v4"), taskManager);

        assertThatCode(v::validate).doesNotThrowAnyException();
    }

    /** v4.1 (correction de l'indulgence) doit demarrer au meme titre que v3 et v4. */
    @Test
    void validate_realV41File_noThrow() {
        when(taskManager.findAllActive()).thenReturn(List.of());
        ProductionRubricsValidator v =
                new ProductionRubricsValidator(realProvider("v4.1"), taskManager);

        assertThatCode(v::validate).doesNotThrowAnyException();
    }

    /** v4.1 garde le contrat structurel de v4 : 6 taches, poids a 1.00, codes porteurs presents. */
    @Test
    void v41File_keepsV4Contract() {
        Map<String, Map<String, Object>> all = realProvider("v4.1").all();

        assertThat(all).containsOnlyKeys("EE_T1", "EE_T2", "EE_T3", "EO_T1", "EO_T2", "EO_T3");
        for (String cle : all.keySet()) {
            assertThat(codes(all, cle))
                    .as(cle + " garde les codes porteurs du niveau CECRL")
                    .contains("lexique", "morphosyntaxe", "coherence");
            assertThat(poidsTotal(all, cle)).as(cle + " : somme des poids")
                    .isEqualTo(1.0, org.assertj.core.data.Offset.offset(0.0001));
        }
        assertThat(codes(all, "EO_T2")).contains("conduite_echange");
        assertThat(codes(all, "EE_T2")).contains("chronologie_recit");
    }

    /**
     * Ce que v4.1 corrige : les tolerances de v4 sont ENCADREES (jamais supprimees)
     * et le bas d'echelle est ancre. On verrouille la presence des regles, pas leur
     * redaction — c'est le banc de mesure qui juge de leur effet.
     */
    @Test
    void v41File_framesTolerancesAndAnchorsLowLevels() {
        Map<String, Object> commun = realProvider("v4.1").getCommun();
        String texte = String.valueOf(commun.get("sections"));

        // Les 6 tolerances de v4 sont TOUJOURS la (aucune suppression).
        assertThat(texte)
                .as("tolerance longueur conservee")
                .contains("Ne penalise donc JAMAIS une production pour sa longueur")
                .as("tolerance orthographe a l'oral conservee")
                .contains("n'evalue PAS l'orthographe sur de l'oral transcrit")
                .as("tolerance exhaustivite conservee")
                .contains("n'exige JAMAIS l'exhaustivite")
                .as("examinateur temoin de comprehension conserve")
                .contains("L'EXAMINATEUR EST TON TEMOIN DE COMPREHENSION")
                .as("benefice du doute conserve")
                .contains("BENEFICE DU DOUTE")
                .as("interdiction de conclure a l'incomprehensibilite conservee")
                .contains("Ne conclus JAMAIS que le candidat est 'incomprehensible'");

        // ... mais elles sont desormais encadrees, et le bas d'echelle est ancre.
        assertThat(texte)
                .contains("Ne pas penaliser un defaut n'est pas crediter une qualite")
                .contains("PLAFOND A1")
                .contains("PLAFOND A2")
                .contains("TEST DECISIF A1 vs A2")
                .contains("GARDE-FOU DE COUPLAGE")
                .contains("REPERES DE NOTE GLOBALE")
                .as("le hors-sujet reste a 0/20 malgre le durcissement du bas d'echelle")
                .contains("Cette regle PRIME sur toute autre consideration");
    }

    /** Ancres few-shot v4.1 : le bas d'echelle est couvert sur les 3 taches ecrites. */
    @Test
    void v41File_fewShotAddsLowLevelWrittenAnchors() {
        Map<String, Object> commun = realProvider("v4.1").getCommun();
        List<?> fewShot = (List<?>) commun.get("few_shot");

        assertThat(fewShot).hasSizeGreaterThanOrEqualTo(12);
        List<String> basEchelle = new ArrayList<>();
        for (Object o : fewShot) {
            Map<?, ?> m = (Map<?, ?>) o;
            String niveau = String.valueOf(m.get("niveau_cecrl"));
            String contexte = String.valueOf(m.get("contexte"));
            if (("A1".equals(niveau) || "A2".equals(niveau)) && contexte.startsWith("EE_")) {
                basEchelle.add(contexte.substring(0, 5));
            }
        }
        assertThat(basEchelle)
                .as("une ancre A1 ou A2 sur chacune des 3 taches ecrites les plus deviantes")
                .contains("EE_T1", "EE_T2", "EE_T3");
        assertThat(basEchelle).hasSizeGreaterThanOrEqualTo(6);
    }

    /** v4 = criteres PROPRES A CHAQUE TACHE (le defaut corrige) + socle commun conserve. */
    @Test
    void v4File_hasTaskSpecificCriteria() {
        Map<String, Map<String, Object>> all = realProvider("v4").all();

        assertThat(all).containsOnlyKeys("EE_T1", "EE_T2", "EE_T3", "EO_T1", "EO_T2", "EO_T3");
        assertThat(codes(all, "EO_T2")).contains("conduite_echange");
        assertThat(codes(all, "EE_T1")).contains("adequation_destinataire");
        assertThat(codes(all, "EE_T2")).contains("chronologie_recit");
        assertThat(codes(all, "EE_T3")).contains("argumentation");
        assertThat(codes(all, "EO_T1")).contains("developpement_reponses");
        assertThat(codes(all, "EO_T3")).contains("argumentation");
        for (String cle : all.keySet()) {
            assertThat(codes(all, cle))
                    .as(cle + " garde les codes porteurs du niveau CECRL")
                    .contains("lexique", "morphosyntaxe", "coherence");
            assertThat(poidsTotal(all, cle)).as(cle + " : somme des poids").isEqualTo(1.0, org.assertj.core.data.Offset.offset(0.0001));
        }
    }

    /** Les few-shot v4 couvrent le bas de l'echelle et l'oral (calibration elargie). */
    @Test
    void v4File_fewShotCoversLowLevelsAndOral() {
        Map<String, Object> commun = realProvider("v4").getCommun();
        List<?> fewShot = (List<?>) commun.get("few_shot");

        assertThat(fewShot).hasSizeGreaterThanOrEqualTo(6);
        List<String> niveaux = new ArrayList<>();
        List<String> contextes = new ArrayList<>();
        for (Object o : fewShot) {
            Map<?, ?> m = (Map<?, ?>) o;
            niveaux.add(String.valueOf(m.get("niveau_cecrl")));
            contextes.add(String.valueOf(m.get("contexte")));
        }
        assertThat(niveaux).contains("A1_NON_ATTEINT", "A1");
        assertThat(contextes).anyMatch(c -> c.startsWith("EO_T1"));
        assertThat(contextes).anyMatch(c -> c.startsWith("EO_T2"));
        assertThat(contextes).anyMatch(c -> c.startsWith("EO_T3"));
    }

    private List<String> codes(Map<String, Map<String, Object>> all, String cle) {
        List<String> codes = new ArrayList<>();
        for (Object c : (List<?>) all.get(cle).get("criteres")) {
            codes.add(String.valueOf(((Map<?, ?>) c).get("code")));
        }
        return codes;
    }

    private double poidsTotal(Map<String, Map<String, Object>> all, String cle) {
        double somme = 0;
        for (Object c : (List<?>) all.get(cle).get("criteres")) {
            somme += ((Number) ((Map<?, ?>) c).get("poids")).doubleValue();
        }
        return somme;
    }

    // ------------------------------------------------------------ cas nominal

    @Test
    void validate_validRubrics_noThrow() {
        stub(sixRubriques());

        assertThatCode(() -> validator().validate()).doesNotThrowAnyException();
    }

    // ------------------------------------------------------------ cas d'echec

    @Test
    void validate_poidsSumNotOne_throws() {
        Map<String, Map<String, Object>> all = sixRubriques();
        all.put("EE_T1", rubric(List.of(
                critere("lexique", 0.4),
                critere("morphosyntaxe", 0.4),
                critere("coherence", 0.1))));
        stub(all);

        assertThatThrownBy(() -> validator().validate())
                .isInstanceOf(IllegalStateException.class);
    }

    @Test
    void validate_nonCanonicalCode_throws() {
        Map<String, Map<String, Object>> all = sixRubriques();
        all.put("EE_T1", rubric(List.of(
                critere("lexique", 0.4),
                critere("morphosyntaxe", 0.4),
                critere("coherence", 0.1),
                critere("orthographe", 0.1))));
        stub(all);

        assertThatThrownBy(() -> validator().validate())
                .isInstanceOf(IllegalStateException.class);
    }

    /** Supprimer 'coherence' casserait le calcul serveur du niveau CECRL. */
    @Test
    void validate_missingMandatoryCode_throws() {
        Map<String, Map<String, Object>> all = sixRubriques();
        all.put("EO_T2", rubric(List.of(
                critere("conduite_echange", 0.4),
                critere("lexique", 0.3),
                critere("morphosyntaxe", 0.3))));
        stub(all);

        assertThatThrownBy(() -> validator().validate())
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("Rubriques de notation invalides");
    }

    @Test
    void validate_duplicateCode_throws() {
        Map<String, Map<String, Object>> all = sixRubriques();
        all.put("EE_T3", rubric(List.of(
                critere("lexique", 0.3),
                critere("lexique", 0.2),
                critere("morphosyntaxe", 0.3),
                critere("coherence", 0.2))));
        stub(all);

        assertThatThrownBy(() -> validator().validate())
                .isInstanceOf(IllegalStateException.class);
    }

    @Test
    void validate_missingRubricKey_throws() {
        Map<String, Map<String, Object>> all = sixRubriques();
        all.remove("EO_T3");
        stub(all);

        assertThatThrownBy(() -> validator().validate())
                .isInstanceOf(IllegalStateException.class);
    }

    @Test
    void validate_missingBaremeNote_throws() {
        Map<String, Map<String, Object>> all = sixRubriques();
        all.get("EE_T2").remove("bareme_note");
        stub(all);

        assertThatThrownBy(() -> validator().validate())
                .isInstanceOf(IllegalStateException.class);
    }

    @Test
    void validate_emptyDescripteurs_throws() {
        Map<String, Map<String, Object>> all = sixRubriques();
        all.get("EE_T2").put("descripteurs", Map.of());
        stub(all);

        assertThatThrownBy(() -> validator().validate())
                .isInstanceOf(IllegalStateException.class);
    }

    @Test
    void validate_blankConsignesCorrecteur_throws() {
        Map<String, Map<String, Object>> all = sixRubriques();
        all.get("EO_T1").put("consignes_correcteur", "   ");
        stub(all);

        assertThatThrownBy(() -> validator().validate())
                .isInstanceOf(IllegalStateException.class);
    }

    @Test
    void validate_noCriteres_throws() {
        Map<String, Map<String, Object>> all = sixRubriques();
        all.get("EO_T1").put("criteres", List.of());
        stub(all);

        assertThatThrownBy(() -> validator().validate())
                .isInstanceOf(IllegalStateException.class);
    }

    @Test
    void validate_emptyCommunSections_throws() {
        when(rubrics.getCommun()).thenReturn(Map.of("sections", List.of(), "few_shot", List.of()));
        when(rubrics.all()).thenReturn(sixRubriques());
        lenient().when(taskManager.findAllActive()).thenReturn(List.of());

        assertThatThrownBy(() -> validator().validate())
                .isInstanceOf(IllegalStateException.class);
    }

    @Test
    void validate_activeTaskWithoutRubric_throws() {
        Map<String, Map<String, Object>> all = sixRubriques();
        when(rubrics.getCommun()).thenReturn(validCommun());
        when(rubrics.all()).thenReturn(all);

        ProductionTask task = new ProductionTask();
        task.setEpreuve(EpreuveType.TCF_EE);
        task.setTacheNumero((short) 4);
        when(taskManager.findAllActive()).thenReturn(List.of(task));
        when(rubrics.find(EpreuveType.TCF_EE, 4)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> validator().validate())
                .isInstanceOf(IllegalStateException.class);
    }
}
