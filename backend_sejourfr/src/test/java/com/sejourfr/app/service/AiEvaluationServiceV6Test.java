package com.sejourfr.app.service;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.entity.Transcription;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.SubmissionStatut;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import tools.jackson.databind.ObjectMapper;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * Moteur d'evaluation sur l'ECHELLE du TCF (rubriques v6, les VRAIES).
 *
 * <p>Ce que verrouille cette classe, et qui n'existait pas avant v6 :
 * <ul>
 *   <li>le passage note -> niveau suit la TABLE OFFICIELLE du TCF IRN
 *       (0 = A1 non atteint, 1 = A1, 2-5 = A2, 6-9 = B1, 10-20 = B2) — la note
 *       affichee au candidat et le niveau annonce ne peuvent plus se
 *       contredire ;</li>
 *   <li>le GARDE-FOU DE COUPLAGE, recalcule a 1 point, empeche toujours qu'une
 *       consigne bien cochee en francais pauvre fasse franchir un palier — sur
 *       cette echelle, +4 le permettrait ;</li>
 *   <li>les plafonds cibles et les bandes qualitatives suivent l'echelle de la
 *       grille, et non plus des bornes en dur ;</li>
 *   <li>v5 reste chargeable a l'identique : {@code EVAL_RUBRICS_VERSION} seule
 *       suffit a revenir en arriere.</li>
 * </ul>
 */
class AiEvaluationServiceV6Test {

    private static final String TEXTE_EE =
        "Salut Paul ! J'ai une bonne nouvelle : j'ai enfin déménagé la semaine dernière. "
            + "Mon logement se trouve près de la gare, il est lumineux et il y a un petit "
            + "jardin derrière. Viens passer le week-end quand tu veux, il y a de la place.";

    private com.sejourfr.app.manager.ProductionSubmissionManager submissionManager;
    private com.sejourfr.app.manager.TranscriptionManager transcriptionManager;
    private com.sejourfr.app.manager.AiEvaluationManager aiEvaluationManager;
    private EvaluationLlmClient llmClient;
    private ProductionEvaluationProperties props;
    private AiEvaluationService service;

    private static Map<String, Object> score(String code, Number note, String preuve) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("code", code);
        m.put("note_sur_20", note);
        m.put("commentaire", "commentaire " + code);
        m.put("preuve", preuve);
        return m;
    }

    /** Feedback plausible sur la grille du TCF (4 criteres), preuves prises dans le texte. */
    private static Map<String, Object> feedback(Number communiquer, Number interagir,
                                                Number lexique, Number morphosyntaxe) {
        Map<String, Object> f = new LinkedHashMap<>();
        f.put("note_globale", 7);
        f.put("niveau_cecrl", "B1");
        f.put("justification_niveau", "Emploi du passé composé et lexique du logement.");
        f.put("confiance", "HAUTE");
        f.put("confiance_raisons", new ArrayList<>(List.of("production complète et lisible")));
        f.put("accomplissement", Map.of(
            "points_traites", List.of(Map.of("libelle", "Nouvelle annoncée", "obligatoire", true)),
            "points_oublies", List.of()));
        f.put("scores_criteres", new ArrayList<>(List.of(
            score("communiquer", communiquer, "j'ai enfin déménagé"),
            score("interagir", interagir, "Salut Paul"),
            score("lexique", lexique, "il est lumineux"),
            score("morphosyntaxe", morphosyntaxe, "Viens passer le week-end"))));
        f.put("points_forts", new ArrayList<>(List.of("Message clair")));
        f.put("points_a_ameliorer", new ArrayList<>(List.of(Map.of(
            "constat", "Vos idées sont juxtaposées.",
            "comment", "Relie tes deux idées avec « parce que » au lieu d'un point.",
            "exemple", Map.of("avant", "il est lumineux", "apres", "il est lumineux parce qu'il")))));
        return f;
    }

    private ProductionTask task(EpreuveType epreuve, int tache) {
        ProductionTask t = new ProductionTask();
        t.setId(UUID.randomUUID());
        t.setEpreuve(epreuve);
        t.setTacheNumero((short) tache);
        t.setConsigne("Vous venez d'emménager. Écrivez à un ami pour annoncer la nouvelle, "
            + "décrire votre logement et l'inviter.");
        t.setNiveauCible("B1");
        return t;
    }

    private ProductionSubmission submission(ProductionTask task, String texte) {
        ProductionSubmission s = new ProductionSubmission();
        s.setId(UUID.randomUUID());
        s.setProductionTask(task);
        s.setStatut(SubmissionStatut.SUBMITTED);
        s.setTexteSoumis(texte);
        when(submissionManager.findById(s.getId())).thenReturn(Optional.of(s));
        return s;
    }

    private ProductionSubmission submissionOrale(ProductionTask task, String transcript) {
        ProductionSubmission s = new ProductionSubmission();
        s.setId(UUID.randomUUID());
        s.setProductionTask(task);
        s.setStatut(SubmissionStatut.SUBMITTED);
        s.setMediaDurationSec(210);
        Transcription t = new Transcription();
        t.setTexte(transcript);
        when(submissionManager.findById(s.getId())).thenReturn(Optional.of(s));
        when(transcriptionManager.findLatestBySubmissionId(s.getId())).thenReturn(Optional.of(t));
        return s;
    }

    private void stubLlm(Map<String, Object> feedback) {
        when(llmClient.evaluate(anyString(), anyString()))
            .thenReturn(new EvaluationLlmClient.Outcome(feedback, 100, 200, 3));
    }

    @SuppressWarnings("unchecked")
    private static Map<String, Object> critere(AiEvaluation eval, String code) {
        for (Object s : (List<Object>) eval.getFeedbackJson().get("scores_criteres")) {
            Map<String, Object> m = (Map<String, Object>) s;
            if (code.equals(m.get("code"))) return m;
        }
        throw new AssertionError("critere absent : " + code);
    }

    private static BigDecimal note(AiEvaluation eval, String code) {
        return new BigDecimal(critere(eval, code).get("note_sur_20").toString());
    }

    @BeforeEach
    void setUp() {
        submissionManager = mock(com.sejourfr.app.manager.ProductionSubmissionManager.class);
        transcriptionManager = mock(com.sejourfr.app.manager.TranscriptionManager.class);
        aiEvaluationManager = mock(com.sejourfr.app.manager.AiEvaluationManager.class);
        llmClient = mock(EvaluationLlmClient.class);
        when(llmClient.getModelName()).thenReturn("modele-test");
        when(llmClient.getPromptVersion()).thenReturn("v3");
        when(aiEvaluationManager.save(any())).thenAnswer(inv -> inv.getArgument(0));

        props = new ProductionEvaluationProperties();
        props.setRubricsVersion("v6");
        buildService();
    }

    private void buildService() {
        ProductionRubricsProvider rubrics = new ProductionRubricsProvider(props, new ObjectMapper());
        rubrics.load();
        EvaluationPromptBuilder promptBuilder = new EvaluationPromptBuilder(new ObjectMapper(), rubrics);
        service = new AiEvaluationService(submissionManager, transcriptionManager, aiEvaluationManager,
            llmClient, promptBuilder, rubrics, new ProductionValidityService(props),
            new ProductionSecondePasseService(props, mock(EvaluationLlmClient.class)),
            new ProductionFluiditeService(props), props);
    }

    // ------------------------------------------------ la table officielle du TCF

    /**
     * LE point de la v6 : c'est la table du TCF qui convertit la note en niveau.
     * Sur l'ancienne echelle, 10/20 valait A2 et 13,5 valait B1 ; le candidat
     * lisait « 12,5/20 » et « proche du B1 », deux informations contradictoires
     * pour qui connait la grille officielle.
     */
    @ParameterizedTest
    @CsvSource({
        // communiquer, interagir, lexique, morphosyntaxe, note attendue, niveau attendu
        "0,  0,  0,  0,  0,     A1_NON_ATTEINT",
        "1,  1,  1,  1,  1,     A1",
        "2,  2,  1,  1,  1.5,   A1",
        "2,  2,  2,  2,  2,     A2",
        "5,  5,  4,  4,  4.5,   A2",
        "6,  5,  5,  5,  5.3,   A2",
        "6,  6,  6,  6,  6,     B1",
        "9,  9,  9,  9,  9,     B1",
        "10, 9,  9,  9,  9.3,   B1",
        "10, 10, 10, 10, 10,    B2",
        "14, 14, 14, 13, 13.8,  B2"
    })
    void le_niveau_suit_la_table_officielle_du_tcf(int communiquer, int interagir, int lexique,
                                                   int morphosyntaxe, String noteAttendue,
                                                   NiveauCecrl niveauAttendu) {
        stubLlm(feedback(communiquer, interagir, lexique, morphosyntaxe));
        ProductionSubmission sub = submission(task(EpreuveType.TCF_EE, 1), TEXTE_EE);

        AiEvaluation eval = service.evaluate(sub.getId());

        assertThat(eval.getNoteSur20()).isEqualByComparingTo(new BigDecimal(noteAttendue));
        assertThat(eval.getNiveauCecrl()).isEqualTo(niveauAttendu);
    }

    /**
     * Le meme jeu de notes sous v5 raconterait une autre histoire : c'est la
     * preuve que la bascule tient au FICHIER de rubriques, et que
     * {@code EVAL_RUBRICS_VERSION} seule suffit a revenir en arriere.
     */
    @Test
    void la_meme_note_ne_donne_pas_le_meme_niveau_sous_v5() {
        props.setRubricsVersion("v5");
        buildService();
        stubLlm(feedback(10, 10, 10, 10));
        ProductionSubmission sub = submission(task(EpreuveType.TCF_EE, 1), TEXTE_EE);

        AiEvaluation eval = service.evaluate(sub.getId());

        assertThat(eval.getNoteSur20()).isEqualByComparingTo(new BigDecimal("10"));
        assertThat(eval.getNiveauCecrl())
            .as("10/20 vaut A2 sur l'echelle de v5, B2 sur celle du TCF")
            .isEqualTo(NiveauCecrl.A2);
    }

    // ------------------------------------------------- garde-fou de couplage

    /**
     * Cocher tous les points d'une consigne dans un francais A1 ne fait PAS
     * monter d'un palier. Avec l'ecart de 4 herite de v5, communiquer serait
     * ramene a 5 et la moyenne a 3 : on annoncerait A2 a un candidat A1.
     */
    @Test
    void couplage_recalcule_empeche_une_langue_A1_de_ressortir_A2() {
        stubLlm(feedback(12, 11, 1, 1));
        ProductionSubmission sub = submission(task(EpreuveType.TCF_EE, 1), TEXTE_EE);

        AiEvaluation eval = service.evaluate(sub.getId());

        // moyenne(1, 1) = 1 -> plafond 2.
        assertThat(note(eval, "communiquer")).isEqualByComparingTo(new BigDecimal("2"));
        assertThat(note(eval, "interagir")).isEqualByComparingTo(new BigDecimal("2"));
        assertThat(eval.getNoteSur20()).isEqualByComparingTo(new BigDecimal("1.5"));
        assertThat(eval.getNiveauCecrl()).isEqualTo(NiveauCecrl.A1);
    }

    /**
     * Le garde-fou est calibre pour que le gain concede a la moyenne
     * ({@code ecart-max / 2} = 0,5) ne franchisse jamais un seuil de palier :
     * une langue au HAUT du A2 (5) reste A2, une langue au haut du B1 (9) reste
     * B1.
     */
    @ParameterizedTest
    @CsvSource({
        "5, 5.5,  A2",
        "9, 9.5,  B1"
    })
    void couplage_ne_laisse_jamais_franchir_un_palier(int langue, String noteAttendue,
                                                      NiveauCecrl niveauAttendu) {
        stubLlm(feedback(20, 20, langue, langue));
        ProductionSubmission sub = submission(task(EpreuveType.TCF_EE, 1), TEXTE_EE);

        AiEvaluation eval = service.evaluate(sub.getId());

        assertThat(eval.getNoteSur20()).isEqualByComparingTo(new BigDecimal(noteAttendue));
        assertThat(eval.getNiveauCecrl()).isEqualTo(niveauAttendu);
    }

    /** Sur une production coherente, le garde-fou ne touche a rien. */
    @Test
    void couplage_ne_touche_pas_une_production_coherente() {
        stubLlm(feedback(14, 13, 13, 13));
        ProductionSubmission sub = submission(task(EpreuveType.TCF_EE, 1), TEXTE_EE);

        AiEvaluation eval = service.evaluate(sub.getId());

        assertThat(note(eval, "communiquer")).isEqualByComparingTo(new BigDecimal("14"));
        assertThat(note(eval, "interagir")).isEqualByComparingTo(new BigDecimal("13"));
        assertThat(eval.getNiveauCecrl()).isEqualTo(NiveauCecrl.B2);
    }

    /** Coupe-circuit conserve : le banc doit pouvoir mesurer avec et sans. */
    @Test
    void couplage_desactivable_pour_la_mesure() {
        props.getCouplage().setEnabled(false);
        buildService();
        stubLlm(feedback(12, 11, 1, 1));
        ProductionSubmission sub = submission(task(EpreuveType.TCF_EE, 1), TEXTE_EE);

        assertThat(note(service.evaluate(sub.getId()), "communiquer"))
            .isEqualByComparingTo(new BigDecimal("12"));
    }

    // ------------------------------------------------------ plafonds cibles

    /**
     * Les deux plafonds cibles mordent toujours, a leur seuil transpose (haut
     * de la bande A1 = 1 sur l'echelle du TCF). Sans transposition, le seuil de
     * 5 herite de v5 aurait fait plafonner a A2 tout candidat dont
     * {@code communiquer} vaut 5 — c'est-a-dire un A2 SOLIDE, voire un bon
     * dossier : le plafond serait devenu une sanction de masse.
     */
    @Test
    void plafond_T3_sans_prise_de_position_mord_toujours() {
        stubLlm(feedback(1, 13, 14, 14));
        ProductionSubmission sub = submission(task(EpreuveType.TCF_EE, 3),
            "Le télétravail est une pratique répandue. Beaucoup de gens travaillent chez eux "
                + "et les entreprises proposent souvent cette possibilité à leurs salariés.");

        AiEvaluation eval = service.evaluate(sub.getId());

        assertThat(eval.getNiveauCecrl()).isEqualTo(NiveauCecrl.A2);
        assertThat(eval.getFeedbackJson().get(AiEvaluationService.PLAFOND_NIVEAU_KEY)).isEqualTo("A2");
    }

    @Test
    void plafond_T3_ne_mord_pas_sur_un_A2_solide() {
        stubLlm(feedback(5, 5, 4, 4));
        ProductionSubmission sub = submission(task(EpreuveType.TCF_EE, 3),
            "Je préfère habiter dans une petite ville. D'abord c'est moins cher, et aussi "
                + "il y a moins de bruit. Mais dans la grande ville il y a plus de travail.");

        AiEvaluation eval = service.evaluate(sub.getId());

        assertThat(eval.getNiveauCecrl()).isEqualTo(NiveauCecrl.A2);
        assertThat(eval.getFeedbackJson()).doesNotContainKey(AiEvaluationService.PLAFOND_NIVEAU_KEY);
    }

    @Test
    void plafond_EO_T2_sans_echange_mord_toujours() {
        stubLlm(feedback(1, 13, 14, 14));
        ProductionSubmission sub = submissionOrale(task(EpreuveType.TCF_EO, 2),
            "Examinateur : Bonjour, bienvenue à la mairie, je vous écoute.\n"
                + "Candidat : euh bonjour madame je voudrais des renseignements pour une inscription\n"
                + "Examinateur : Très bien, pour qui souhaitez-vous inscrire ?\n"
                + "Candidat : euh voilà c'est ça oui merci beaucoup au revoir madame bonne journée");

        assertThat(service.evaluate(sub.getId()).getNiveauCecrl()).isEqualTo(NiveauCecrl.A2);
    }

    // ------------------------------------------- bandes affichees aux candidats

    /**
     * Les fronts affichent la BANDE, pas le nombre. Avec les bornes de v5
     * laissees en dur, un critere a 8 (bon B1) se serait affiche « en cours
     * d'acquisition » et un critere a 12 (B2 confirme) « satisfaisant ».
     */
    @Test
    void bandes_suivent_l_echelle_de_la_grille() {
        stubLlm(feedback(12, 8, 4, 1));
        ProductionSubmission sub = submission(task(EpreuveType.TCF_EE, 1), TEXTE_EE);

        AiEvaluation eval = service.evaluate(sub.getId());

        // Le couplage ramene communiquer/interagir a moyenne(4, 1) + 1 = 3,5.
        assertThat(critere(eval, "communiquer")).containsEntry("bande", "EN_COURS_ACQUISITION");
        assertThat(critere(eval, "lexique")).containsEntry("bande", "EN_COURS_ACQUISITION");
        assertThat(critere(eval, "morphosyntaxe")).containsEntry("bande", "FRAGILE");
    }

    @Test
    void bandes_haute_et_moyenne_sur_l_echelle_du_tcf() {
        stubLlm(feedback(12, 8, 12, 11));
        ProductionSubmission sub = submission(task(EpreuveType.TCF_EE, 1), TEXTE_EE);

        AiEvaluation eval = service.evaluate(sub.getId());

        assertThat(critere(eval, "lexique"))
            .as("12/20 = B2 confirme sur l'echelle du TCF")
            .containsEntry("bande", "TRES_BONNE_MAITRISE");
        assertThat(critere(eval, "interagir"))
            .as("8/20 = bon B1")
            .containsEntry("bande", "SATISFAISANT");
    }

    // ------------------------------------------------------------- hors-sujet

    /** Le hors-sujet reste a 0 sur les quatre criteres : la regle prime toujours. */
    @Test
    void hors_sujet_reste_a_zero() {
        Map<String, Object> f = feedback(0, 0, 0, 0);
        f.put("note_globale", 0);
        f.put("niveau_cecrl", "A1_NON_ATTEINT");
        stubLlm(f);
        ProductionSubmission sub = submission(task(EpreuveType.TCF_EE, 1), TEXTE_EE);

        AiEvaluation eval = service.evaluate(sub.getId());

        assertThat(eval.getNoteSur20()).isEqualByComparingTo(BigDecimal.ZERO);
        assertThat(eval.getNiveauCecrl()).isEqualTo(NiveauCecrl.A1_NON_ATTEINT);
    }
}
