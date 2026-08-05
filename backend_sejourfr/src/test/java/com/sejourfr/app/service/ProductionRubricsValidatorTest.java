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
        // Reglages de niveau "historiques" (v3-v4.2) : lexique + morphosyntaxe + coherence.
        when(rubrics.niveauCecrl()).thenReturn(new ProductionEvaluationProperties.NiveauCecrl());
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

    /** v4.2 (frontiere B1/B2 opposable) doit demarrer au meme titre que v3, v4 et v4.1. */
    @Test
    void validate_realV42File_noThrow() {
        when(taskManager.findAllActive()).thenReturn(List.of());
        ProductionRubricsValidator v =
                new ProductionRubricsValidator(realProvider("v4.2"), taskManager);

        assertThatCode(v::validate).doesNotThrowAnyException();
    }

    /** v4.2 garde le contrat structurel de v4/v4.1 : 6 taches, poids a 1.00, codes porteurs. */
    @Test
    void v42File_keepsV4Contract() {
        Map<String, Map<String, Object>> all = realProvider("v4.2").all();

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
        assertThat(codes(all, "EE_T3")).contains("argumentation");
    }

    /**
     * Ce que v4.2 ajoute : la frontiere B1/B2 devient OPPOSABLE (test decisif +
     * obligation de citation + plafond a 14/20), sans qu'aucune tolerance ni
     * aucun acquis de v4.1 ne saute. On verrouille la presence des regles, pas
     * leur redaction — c'est le banc de mesure qui juge de leur effet.
     */
    @Test
    void v42File_makesB1B2FrontierOpposable() {
        Map<String, Object> commun = realProvider("v4.2").getCommun();
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

        // Les acquis v4.1 sur le BAS de l'echelle sont intacts.
        assertThat(texte)
                .contains("Ne pas penaliser un defaut n'est pas crediter une qualite")
                .contains("PLAFOND A1")
                .contains("PLAFOND A2")
                .contains("TEST DECISIF A1 vs A2")
                .contains("GARDE-FOU DE COUPLAGE")
                .contains("REPERES DE NOTE GLOBALE")
                .as("le hors-sujet reste a 0/20")
                .contains("Cette regle PRIME sur toute autre consideration");

        // Le NOUVEAU : le haut de l'echelle est ancre, symetriquement.
        assertThat(texte)
                .as("test opposable de la frontiere B1/B2")
                .contains("TEST DECISIF B1 vs B2")
                .as("obligation de citation au-dessus de B1")
                .contains("CITER LITTERALEMENT au moins DEUX de ces marqueurs")
                .as("plafond de note a defaut de marqueur B2 citable")
                .contains("ne depassent alors pas 14/20")
                .as("faux B2 : connecteurs de surface, longueur, correction, formules apprises")
                .contains("LES CONNECTEURS DE SURFACE")
                .contains("LA CORRECTION CONFONDUE AVEC LA RICHESSE")
                .contains("LES FORMULES APPRISES PAR COEUR")
                .as("reconnaitre une objection ne vaut pas la refuter")
                .contains("RECONNAITRE N'EST PAS REFUTER")
                .as("le plafond ne mord pas sous B1 et n'autorise pas a rogner un vrai B2")
                .contains("il ne mord jamais en dessous de 15/20")
                .contains("note lexique, morphosyntaxe et coherence 16 a 18 SANS HESITER");
    }

    /** Ancres few-shot v4.2 : la frontiere B1/B2 est couverte dans les deux sens. */
    @Test
    void v42File_fewShotCoversB1B2Frontier() {
        Map<String, Object> commun = realProvider("v4.2").getCommun();
        List<?> fewShot = (List<?>) commun.get("few_shot");

        assertThat(fewShot).as("les 13 ancres v4.1 + les ancres de frontiere")
                .hasSizeGreaterThanOrEqualTo(15);

        int b1ANePasSurclasser = 0;
        int b2ANePasRogner = 0;
        for (Object o : fewShot) {
            Map<?, ?> m = (Map<?, ?>) o;
            String niveau = String.valueOf(m.get("niveau_cecrl"));
            String justification = String.valueOf(m.get("justification"));
            // Casse libre sur le renvoi au test : c'est sa PRESENCE qui est verrouillee.
            if ("B1".equals(niveau) && justification.contains("POURQUOI PAS B2")
                    && justification.toUpperCase(java.util.Locale.ROOT).contains("TEST DECISIF")) {
                b1ANePasSurclasser++;
            }
            if ("B2".equals(niveau) && justification.contains("PAS 14")) {
                b2ANePasRogner++;
            }
        }
        assertThat(b1ANePasSurclasser)
                .as("au moins deux B1 convaincants que le test decisif retient sous le B2")
                .isGreaterThanOrEqualTo(2);
        assertThat(b2ANePasRogner)
                .as("au moins un vrai B2 dont l'ancre interdit de rogner les porteurs")
                .isGreaterThanOrEqualTo(1);
    }

    /** Chaque tache rappelle l'ancrage du haut d'echelle dans ses consignes. */
    @Test
    void v42File_eachTaskRecallsHighEndAnchor() {
        Map<String, Map<String, Object>> all = realProvider("v4.2").all();

        for (Map.Entry<String, Map<String, Object>> e : all.entrySet()) {
            assertThat(String.valueOf(e.getValue().get("consignes_correcteur")))
                    .as(e.getKey() + " rappelle le test decisif B1 vs B2")
                    .contains("TEST DECISIF B1 vs B2");
            assertThat(String.valueOf(e.getValue().get("consignes_correcteur")))
                    .as(e.getKey() + " rappelle aussi l'ancrage du bas d'echelle (v4.1 conserve)")
                    .contains("ANCRAGE BAS D'ECHELLE");
        }
    }

    // ------------------------------------------------------------------- v5

    /** v5 (grille du TCF) doit demarrer comme v3, v4, v4.1 et v4.2. */
    @Test
    void validate_realV5File_noThrow() {
        when(taskManager.findAllActive()).thenReturn(List.of());
        ProductionRubricsValidator v =
                new ProductionRubricsValidator(realProvider("v5"), taskManager);

        assertThatCode(v::validate).doesNotThrowAnyException();
    }

    /**
     * LE contrat v5 : la grille reelle du TCF — exactement 4 criteres, memes
     * codes sur les 6 taches, equiponderes a 0,25. C'est ce qui change tout le
     * reste, donc c'est verrouille ici.
     */
    @Test
    void v5File_hasFourEquallyWeightedTcfCriteria() {
        Map<String, Map<String, Object>> all = realProvider("v5").all();

        assertThat(all).containsOnlyKeys("EE_T1", "EE_T2", "EE_T3", "EO_T1", "EO_T2", "EO_T3");
        for (String cle : all.keySet()) {
            assertThat(codes(all, cle))
                    .as(cle + " : les 4 criteres du TCF, dans cet ordre, et aucun autre")
                    .containsExactly("communiquer", "interagir", "lexique", "morphosyntaxe");
            for (Object c : (List<?>) all.get(cle).get("criteres")) {
                assertThat(((Number) ((Map<?, ?>) c).get("poids")).doubleValue())
                        .as(cle + " : chaque critere pese 0,25")
                        .isEqualTo(0.25);
            }
            assertThat(poidsTotal(all, cle)).as(cle + " : somme des poids")
                    .isEqualTo(1.0, org.assertj.core.data.Offset.offset(0.0001));
        }
    }

    /**
     * Les libelles affiches au candidat sont ACCENTUES (ils remontent tels quels
     * dans scores_criteres puis dans les 3 fronts), alors que le reste du
     * fichier — instructions au modele — reste sans accents.
     */
    @Test
    void v5File_labelsAreProperlyAccented() {
        Map<String, Map<String, Object>> all = realProvider("v5").all();

        for (String cle : all.keySet()) {
            for (Object c : (List<?>) all.get(cle).get("criteres")) {
                Map<?, ?> critere = (Map<?, ?>) c;
                String label = String.valueOf(critere.get("label"));
                assertThat(label).as(cle + " : label non vide").isNotBlank();
                if ("communiquer".equals(critere.get("code"))) {
                    assertThat(label).contains("tâche").contains("idées");
                }
                if ("lexique".equals(critere.get("code"))) {
                    assertThat(label).contains("approprié");
                }
            }
        }
    }

    /**
     * v5 declare LUI-MEME son passage note -> niveau : la paire de rollback
     * rubriques/tool-schema n'a donc pas besoin d'une troisième surcharge pour
     * les seuils (v4.2 lit trois criteres et d'autres seuils).
     */
    @Test
    void v5File_declaresItsOwnLevelSettings() {
        ProductionEvaluationProperties.NiveauCecrl v5 = realProvider("v5").niveauCecrl();

        assertThat(v5.getSourceCriteres())
                .as("le niveau derive des QUATRE criteres, donc de la note ponderee elle-meme")
                .containsExactly("communiquer", "interagir", "lexique", "morphosyntaxe");
        assertThat(v5.getSeuilB2()).isEqualTo(16.0);
        assertThat(v5.getSeuilB1()).isEqualTo(13.0);
        assertThat(v5.getSeuilA2()).isEqualTo(9.0);

        ProductionEvaluationProperties.NiveauCecrl v42 = realProvider("v4.2").niveauCecrl();
        assertThat(v42.getSourceCriteres())
                .as("v4.2 ne declare rien : elle garde les reglages de la config")
                .containsExactly("lexique", "morphosyntaxe", "coherence");
        assertThat(v42.getSeuilB2()).isEqualTo(15.0);
    }

    /**
     * Ce que v5 change ET ce qu'elle ne perd pas : l'accomplissement revient
     * dans le niveau, mais toutes les tolerances et les deux ancrages
     * d'echelle de v4.1/v4.2 restent, et le garde-fou de couplage devient la
     * protection qui remplace l'exclusion du critere de tache.
     */
    @Test
    void v5File_keepsEveryToleranceAndAnchorsBothEnds() {
        Map<String, Object> commun = realProvider("v5").getCommun();
        String texte = String.valueOf(commun.get("sections"));

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
                .contains("Ne conclus JAMAIS que le candidat est 'incomprehensible'")
                .as("hors-sujet toujours prioritaire")
                .contains("Cette regle PRIME sur toute autre consideration");

        assertThat(texte)
                .as("bas d'echelle (v4.1) intact")
                .contains("PLAFOND A1").contains("PLAFOND A2").contains("TEST DECISIF A1 vs A2")
                .as("haut d'echelle (v4.2) intact")
                .contains("TEST DECISIF B1 vs B2")
                .contains("CITER LITTERALEMENT au moins DEUX de ces marqueurs")
                .as("le plafond B1 couvre desormais les QUATRE criteres")
                .contains("AUCUN des quatre criteres ne depasse alors 14/20")
                .as("le garde-fou de couplage remplace l'exclusion de l'accomplissement")
                .contains("GARDE-FOU DE COUPLAGE")
                .contains("ne depassent donc JAMAIS de plus de 4 points la moyenne de lexique et")
                .as("le niveau se lit sur la note")
                .contains("16 et plus -> B2 ; 13 a 15 -> B1 ; 9 a 12 -> A2 ; 1 a 8 -> A1");
    }

    /** v5 exige d'ENSEIGNER : chaque priorite porte un « comment » et un exemple. */
    @Test
    void v5File_requiresActionableAdvice() {
        Map<String, Object> commun = realProvider("v5").getCommun();
        String texte = String.valueOf(commun.get("sections"));

        assertThat(texte)
                .contains("ENSEIGNER, PAS CONSTATER")
                .as("les formules creuses observees en production sont nommement interdites")
                .contains("ameliorer la ponctuation pour plus de clarte")
                .contains("pratiquer l'utilisation de connecteurs")
                .as("une priorite doit contenir une technique et un exemple avant/apres")
                .contains("TECHNIQUE REUTILISABLE")
                .contains("verbe d'action adresse au candidat")
                .as("les exemples corriges doivent faire gagner un niveau")
                .contains("GAGNER UN NIVEAU");
    }

    /** Chaque tache v5 rappelle les deux ancrages ET l'exigence pedagogique. */
    @Test
    void v5File_eachTaskRecallsAnchorsAndTeachingRule() {
        Map<String, Map<String, Object>> all = realProvider("v5").all();

        for (Map.Entry<String, Map<String, Object>> e : all.entrySet()) {
            String consignes = String.valueOf(e.getValue().get("consignes_correcteur"));
            assertThat(consignes).as(e.getKey())
                    .contains("ANCRAGE BAS D'ECHELLE")
                    .contains("TEST DECISIF B1 vs B2")
                    .contains("ENSEIGNER, PAS CONSTATER");
            assertThat(String.valueOf(e.getValue().get("descripteurs")))
                    .as(e.getKey() + " : descripteurs par niveau, ce qui distingue les taches")
                    .contains("A1").contains("A2").contains("B1").contains("B2");
        }
    }

    // ------------------------------------------------------------------- v6

    /** v6 (echelle du TCF) doit demarrer comme toutes les versions precedentes. */
    @Test
    void validate_realV6File_noThrow() {
        when(taskManager.findAllActive()).thenReturn(List.of());
        ProductionRubricsValidator v =
                new ProductionRubricsValidator(realProvider("v6"), taskManager);

        assertThatCode(v::validate).doesNotThrowAnyException();
    }

    /** v6 ne touche pas aux CRITERES : ce sont ceux du TCF, comme en v5. */
    @Test
    void v6File_keepsTheFourTcfCriteria() {
        Map<String, Map<String, Object>> all = realProvider("v6").all();

        assertThat(all).containsOnlyKeys("EE_T1", "EE_T2", "EE_T3", "EO_T1", "EO_T2", "EO_T3");
        for (String cle : all.keySet()) {
            assertThat(codes(all, cle))
                    .as(cle + " : les 4 criteres du TCF, dans cet ordre, et aucun autre")
                    .containsExactly("communiquer", "interagir", "lexique", "morphosyntaxe");
            assertThat(poidsTotal(all, cle)).as(cle + " : somme des poids")
                    .isEqualTo(1.0, org.assertj.core.data.Offset.offset(0.0001));
        }
    }

    /**
     * LE contrat v6 : les seuils de niveau sont la TABLE OFFICIELLE du TCF IRN,
     * reprise telle quelle. C'est ce qui rend impossible d'afficher « 12,5/20 »
     * et « proche du B1 » sur la meme carte.
     */
    @Test
    void v6File_declaresTheOfficialTcfConversionTable() {
        ProductionEvaluationProperties.NiveauCecrl v6 = realProvider("v6").niveauCecrl();

        assertThat(v6.getSourceCriteres())
                .containsExactly("communiquer", "interagir", "lexique", "morphosyntaxe");
        assertThat(v6.getSeuilB2()).as("B2 des 10/20, comme au TCF").isEqualTo(10.0);
        assertThat(v6.getSeuilB1()).as("B1 de 6 a 9").isEqualTo(6.0);
        assertThat(v6.getSeuilA2()).as("A2 de 2 a 5 ; sous 2 -> A1 ; 0 -> A1 non atteint").isEqualTo(2.0);

        ProductionEvaluationProperties.NiveauCecrl v5 = realProvider("v5").niveauCecrl();
        assertThat(v5.getSeuilB2()).as("v5 reste intacte et rechargeable").isEqualTo(16.0);
    }

    /**
     * Tout ce qui se LIT sur une note (garde-fou de couplage, plafonds de
     * niveau, bandes affichees) est une propriete de l'ECHELLE : v6 les declare
     * donc elle-meme, sans quoi revenir a v5 avec la config de v6 — ou
     * l'inverse — donnerait des resultats faux.
     */
    @Test
    void v6File_declaresEveryScaleDependentSetting() {
        ProductionRubricsProvider v6 = realProvider("v6");

        assertThat(v6.couplage().getEcartMax())
                .as("le garde-fou concede au plus 0,5 point a la moyenne des quatre : "
                        + "une langue au haut de son palier ne peut pas franchir le seuil suivant")
                .isEqualTo(1.0);
        assertThat(v6.plafonds().getPrisePositionSeuil())
                .as("haut de la bande A1 sur l'echelle du TCF").isEqualTo(1.0);
        assertThat(v6.plafonds().getConduiteEchangeSeuil()).isEqualTo(1.0);
        assertThat(v6.bandesCriteres().getTresBonneMaitrise()).isEqualTo(10.0);
        assertThat(v6.bandesCriteres().getSatisfaisant()).isEqualTo(6.0);
        assertThat(v6.bandesCriteres().getEnCoursAcquisition()).isEqualTo(2.0);

        ProductionRubricsProvider v5 = realProvider("v5");
        assertThat(v5.couplage().getEcartMax()).as("v5 garde son ecart de 4 points").isEqualTo(4.0);
        assertThat(v5.plafonds().getPrisePositionSeuil()).as("v5 garde ses seuils").isEqualTo(5.0);
        assertThat(v5.bandesCriteres().getTresBonneMaitrise()).as("v5 garde ses bandes").isEqualTo(16.0);
    }

    /**
     * v6 change l'echelle, PAS les garde-fous : toutes les tolerances de v4 et
     * les deux ancrages d'echelle de v4.1/v4.2/v5 sont la, re-exprimes sur la
     * table du TCF (A1 = 1, A2 = 2-5, B1 = 6-9, B2 = 10-20).
     */
    @Test
    void v6File_keepsEveryToleranceAndAnchorsBothEnds() {
        Map<String, Object> commun = realProvider("v6").getCommun();
        String texte = String.valueOf(commun.get("sections"));

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
                .contains("Ne conclus JAMAIS que le candidat est 'incomprehensible'")
                .as("hors-sujet toujours prioritaire")
                .contains("Cette regle PRIME sur toute autre consideration");

        assertThat(texte)
                .as("bas d'echelle (v4.1) intact")
                .contains("PLAFOND A1").contains("PLAFOND A2").contains("TEST DECISIF A1 vs A2")
                .as("haut d'echelle (v4.2) intact")
                .contains("TEST DECISIF B1 vs B2")
                .contains("CITER LITTERALEMENT au moins DEUX de ces marqueurs")
                .as("distinction obligatoire / piste intacte")
                .contains("POINTS OBLIGATOIRES").contains("PISTES SUGGEREES")
                .as("garde-fou de couplage conserve, recalcule sur la nouvelle echelle")
                .contains("GARDE-FOU DE COUPLAGE")
                .contains("ne depassent donc JAMAIS de plus de 1 point la moyenne de lexique et")
                .as("le plafond B1 devient le haut du palier B1 sur l'echelle du TCF")
                .contains("AUCUN des quatre criteres ne depasse alors 9/20")
                .as("la table officielle est la regle de lecture de la note")
                .contains("10 et plus -> B2 ; 6 a 9 -> B1 ; 2 a 5 -> A2")
                .as("le 0 couvre desormais aussi le en-deca du A1 : la table n'a rien entre 0 et 1")
                .contains("PLANCHER A1_NON_ATTEINT")
                .as("le reflexe scolaire du 10 = moyenne est explicitement desamorce")
                .contains("10/20 n'est PAS 'la moyenne', c'est le SEUIL DU B2");
    }

    /**
     * LE point critique de la bascule : les ancres few-shot ont bien ete
     * RE-SCOREES, pas recopiees. On rejoue chaque ancre — moyenne des quatre
     * notes contre la table officielle, et respect du garde-fou de couplage —
     * parce qu'une ancre restee sur l'ancienne echelle enseignerait au modele
     * exactement le contraire de la grille.
     */
    @Test
    void v6File_everyFewShotAnchorIsRescoredOnTheTcfScale() {
        ProductionRubricsProvider provider = realProvider("v6");
        List<?> fewShot = (List<?>) provider.getCommun().get("few_shot");
        double ecartMax = provider.couplage().getEcartMax();

        assertThat(fewShot).as("les ancres de v5 sont toutes conservees").hasSizeGreaterThanOrEqualTo(16);
        for (Object o : fewShot) {
            Map<?, ?> m = (Map<?, ?>) o;
            String contexte = String.valueOf(m.get("contexte"));
            Map<String, Double> notes = notesDeLAncre(String.valueOf(m.get("scores")));
            assertThat(notes).as(contexte + " : les 4 criteres sont notes")
                    .containsOnlyKeys("communiquer", "interagir", "lexique", "morphosyntaxe");

            double moyenne = notes.values().stream().mapToDouble(Double::doubleValue).sum() / 4.0;
            assertThat(niveauDeLaNote(moyenne, provider.niveauCecrl()))
                    .as(contexte + " : moyenne " + moyenne + " -> le niveau annonce par l'ancre")
                    .isEqualTo(String.valueOf(m.get("niveau_cecrl")));

            double socle = (notes.get("lexique") + notes.get("morphosyntaxe")) / 2.0;
            assertThat(Math.max(notes.get("communiquer"), notes.get("interagir")))
                    .as(contexte + " : l'ancre respecte elle-meme le garde-fou de couplage")
                    .isLessThanOrEqualTo(socle + ecartMax);
        }
    }

    /** Chaque tache v6 rappelle les ancrages, l'exigence pedagogique et les bornes recalculees. */
    @Test
    void v6File_eachTaskRecallsAnchorsOnTheNewScale() {
        Map<String, Map<String, Object>> all = realProvider("v6").all();

        for (Map.Entry<String, Map<String, Object>> e : all.entrySet()) {
            String consignes = String.valueOf(e.getValue().get("consignes_correcteur"));
            assertThat(consignes).as(e.getKey())
                    .contains("ANCRAGE BAS D'ECHELLE")
                    .contains("TEST DECISIF B1 vs B2")
                    .contains("ENSEIGNER, PAS CONSTATER")
                    .contains("de plus de 1 point la moyenne de lexique et morphosyntaxe")
                    .contains("ne depasse 9/20")
                    .contains("Ce plafond ne mord jamais en dessous de 10/20");
            assertThat(consignes).as(e.getKey() + " : plus aucune borne de l'ancienne echelle")
                    .doesNotContain("14/20").doesNotContain("15/20").doesNotContain("16 a 18");
        }
    }

    /** Notes /20 par code, lues dans le champ libre {@code scores} d'une ancre few-shot. */
    private static Map<String, Double> notesDeLAncre(String scores) {
        Map<String, Double> out = new LinkedHashMap<>();
        java.util.regex.Matcher m = java.util.regex.Pattern
                .compile("(communiquer|interagir|lexique|morphosyntaxe) (\\d+(?:,\\d+)?)")
                .matcher(scores);
        while (m.find()) {
            out.put(m.group(1), Double.parseDouble(m.group(2).replace(',', '.')));
        }
        return out;
    }

    /** Meme regle que le serveur : 0 -> A1 non atteint, puis les seuils de la grille. */
    private static String niveauDeLaNote(double note, ProductionEvaluationProperties.NiveauCecrl seuils) {
        if (note == 0.0) return "A1_NON_ATTEINT";
        if (note >= seuils.getSeuilB2()) return "B2";
        if (note >= seuils.getSeuilB1()) return "B1";
        if (note >= seuils.getSeuilA2()) return "A2";
        return "A1";
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

    /**
     * La protection suit la grille : avec les reglages v5, c'est l'absence d'un
     * des QUATRE criteres du TCF qui bloque le demarrage (et non plus celle de
     * {@code coherence}, qui n'existe plus).
     */
    @Test
    void validate_v5Settings_missingInteragir_throws() {
        Map<String, Map<String, Object>> all = new LinkedHashMap<>();
        for (String cle : List.of("EE_T1", "EE_T2", "EE_T3", "EO_T1", "EO_T2", "EO_T3")) {
            all.put(cle, rubric(List.of(
                    critere("communiquer", 0.25), critere("interagir", 0.25),
                    critere("lexique", 0.25), critere("morphosyntaxe", 0.25))));
        }
        all.put("EO_T2", rubric(List.of(
                critere("communiquer", 0.4), critere("lexique", 0.3), critere("morphosyntaxe", 0.3))));
        when(rubrics.getCommun()).thenReturn(validCommun());
        when(rubrics.all()).thenReturn(all);
        when(rubrics.niveauCecrl()).thenReturn(niveauV5());
        lenient().when(taskManager.findAllActive()).thenReturn(List.of());

        assertThatThrownBy(() -> validator().validate())
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("Rubriques de notation invalides");
    }

    /**
     * Le SOCLE DE LANGUE reste obligatoire meme si la grille pretendait ne pas
     * en deriver son niveau : c'est lui que lit le garde-fou de couplage.
     */
    @Test
    void validate_missingLexiqueAlwaysThrows_evenIfNotALevelSource() {
        ProductionEvaluationProperties.NiveauCecrl sansLangue =
                new ProductionEvaluationProperties.NiveauCecrl();
        sansLangue.setSourceCriteres(List.of("communiquer"));
        Map<String, Map<String, Object>> all = new LinkedHashMap<>();
        for (String cle : List.of("EE_T1", "EE_T2", "EE_T3", "EO_T1", "EO_T2", "EO_T3")) {
            all.put(cle, rubric(List.of(critere("communiquer", 0.5), critere("morphosyntaxe", 0.5))));
        }
        when(rubrics.getCommun()).thenReturn(validCommun());
        when(rubrics.all()).thenReturn(all);
        when(rubrics.niveauCecrl()).thenReturn(sansLangue);
        lenient().when(taskManager.findAllActive()).thenReturn(List.of());

        assertThatThrownBy(() -> validator().validate())
                .isInstanceOf(IllegalStateException.class);
    }

    private static ProductionEvaluationProperties.NiveauCecrl niveauV5() {
        ProductionEvaluationProperties.NiveauCecrl n = new ProductionEvaluationProperties.NiveauCecrl();
        n.setSourceCriteres(List.of("communiquer", "interagir", "lexique", "morphosyntaxe"));
        return n;
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
        when(rubrics.niveauCecrl()).thenReturn(new ProductionEvaluationProperties.NiveauCecrl());
        lenient().when(taskManager.findAllActive()).thenReturn(List.of());

        assertThatThrownBy(() -> validator().validate())
                .isInstanceOf(IllegalStateException.class);
    }

    @Test
    void validate_activeTaskWithoutRubric_throws() {
        Map<String, Map<String, Object>> all = sixRubriques();
        when(rubrics.getCommun()).thenReturn(validCommun());
        when(rubrics.all()).thenReturn(all);
        when(rubrics.niveauCecrl()).thenReturn(new ProductionEvaluationProperties.NiveauCecrl());

        ProductionTask task = new ProductionTask();
        task.setEpreuve(EpreuveType.TCF_EE);
        task.setTacheNumero((short) 4);
        when(taskManager.findAllActive()).thenReturn(List.of(task));
        when(rubrics.find(EpreuveType.TCF_EE, 4)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> validator().validate())
                .isInstanceOf(IllegalStateException.class);
    }
}
