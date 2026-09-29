package com.sejourfr.app.service;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.SubmissionStatut;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
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
 * Moteur d'evaluation sur la grille du TCF (rubriques v5, les VRAIES) :
 * <ul>
 *   <li>la note est la moyenne des QUATRE criteres equiponderes ;</li>
 *   <li>le niveau se lit sur cette note (seuils declares par le fichier) ;</li>
 *   <li>le GARDE-FOU DE COUPLAGE est applique cote serveur : un
 *       {@code communiquer} eleve sur une langue pauvre ne fabrique pas de
 *       niveau — c'est la protection qui remplace l'exclusion de
 *       l'accomplissement du calcul du niveau ;</li>
 *   <li>les plafonds cibles (T3 sans prise de position, EO T2 sans echange)
 *       continuent de mordre via {@code communiquer} ;</li>
 *   <li>{@code points_a_ameliorer} est normalise en objets pour les fronts.</li>
 * </ul>
 */
class AiEvaluationServiceV5Test {

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

    /** Feedback plausible sur la grille v5 (4 criteres), preuves prises dans le texte. */
    private static Map<String, Object> feedbackV5(Number communiquer, Number interagir,
                                                  Number lexique, Number morphosyntaxe) {
        Map<String, Object> f = new LinkedHashMap<>();
        f.put("note_globale", 12);
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
        when(submissionManager.findById(s.getId())).thenReturn(Optional.of(s));
        when(transcriptionManager.findLatestTexteBySubmissionId(s.getId()))
                .thenReturn(Optional.of(transcript));
        return s;
    }

    private void stubLlm(Map<String, Object> feedback) {
        when(llmClient.evaluate(anyString(), anyString()))
            .thenReturn(new EvaluationLlmClient.Outcome(feedback, 100, 200, 3));
    }

    @SuppressWarnings("unchecked")
    private static Map<String, BigDecimal> notes(AiEvaluation eval) {
        Map<String, BigDecimal> out = new LinkedHashMap<>();
        for (Object s : (List<Object>) eval.getFeedbackJson().get("scores_criteres")) {
            Map<?, ?> m = (Map<?, ?>) s;
            out.put(String.valueOf(m.get("code")), new BigDecimal(m.get("note_sur_20").toString()));
        }
        return out;
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
        props.setRubricsVersion("v5");
        buildService();
    }

    private void buildService() {
        ProductionRubricsProvider rubrics = new ProductionRubricsProvider(props, new ObjectMapper());
        rubrics.load();
        EvaluationPromptBuilder promptBuilder = new EvaluationPromptBuilder(new ObjectMapper(), rubrics);
        service = new AiEvaluationService(submissionManager, transcriptionManager, aiEvaluationManager,
            llmClient, promptBuilder, rubrics, new ProductionValidityService(props),
            new ProductionSecondePasseService(props, mock(EvaluationLlmClient.class), rubrics),
            new ProductionFluiditeService(props), new EvaluationRefusalMetrics(), new EvaluationPurgeMetrics(), props);
    }

    // ------------------------------------------------------ note et niveau

    @Test
    void note_est_la_moyenne_des_quatre_criteres_equiponderes() {
        stubLlm(feedbackV5(15, 13, 13, 13));
        ProductionSubmission sub = submission(task(EpreuveType.TCF_EE, 1), TEXTE_EE);

        AiEvaluation eval = service.evaluate(sub.getId());

        // (15 + 13 + 13 + 13) / 4 = 13,5 — une decimale, pas un entier.
        assertThat(eval.getNoteSur20()).isEqualByComparingTo(new BigDecimal("13.5"));
        assertThat(eval.getNiveauCecrl()).isEqualTo(NiveauCecrl.B1);
    }

    @Test
    void le_niveau_se_lit_sur_la_note_et_non_sur_la_seule_langue() {
        // Langue B1 (13/13) mais tache brillamment accomplie : 16 -> B2.
        stubLlm(feedbackV5(17, 17, 15, 15));
        ProductionSubmission sub = submission(task(EpreuveType.TCF_EE, 1), TEXTE_EE);

        AiEvaluation eval = service.evaluate(sub.getId());

        assertThat(eval.getNoteSur20()).isEqualByComparingTo(new BigDecimal("16"));
        assertThat(eval.getNiveauCecrl()).isEqualTo(NiveauCecrl.B2);
    }

    /**
     * LE defaut corrige par v5 : sous v4.2 l'accomplissement etait EXCLU du
     * niveau, si bien qu'un message qui remplit sa fonction et se fait
     * comprendre ressortait A2. Ici il pese, comme au TCF.
     */
    @Test
    void accomplissement_compte_dans_le_niveau() {
        stubLlm(feedbackV5(15, 15, 12, 12));
        ProductionSubmission sub = submission(task(EpreuveType.TCF_EE, 1), TEXTE_EE);

        // (15 + 15 + 12 + 12)/4 = 13.5 -> B1, alors que la seule langue (12) ferait A2.
        assertThat(service.evaluate(sub.getId()).getNiveauCecrl()).isEqualTo(NiveauCecrl.B1);
    }

    // ------------------------------------------------- garde-fou de couplage

    /**
     * Contrepartie du test precedent : cocher tous les points d'une consigne
     * dans un francais pauvre ne fait PAS monter d'un palier. Le filet ramene
     * communiquer et interagir a moyenne(langue) + 4.
     */
    @Test
    void couplage_ramene_communiquer_et_interagir_sous_le_socle_de_langue() {
        stubLlm(feedbackV5(18, 17, 5, 4));
        ProductionSubmission sub = submission(task(EpreuveType.TCF_EE, 1), TEXTE_EE);

        AiEvaluation eval = service.evaluate(sub.getId());

        // moyenne(5, 4) = 4.5 -> plafond 8.5, tronque a 8.5 (1 decimale).
        assertThat(notes(eval).get("communiquer")).isEqualByComparingTo(new BigDecimal("8.5"));
        assertThat(notes(eval).get("interagir")).isEqualByComparingTo(new BigDecimal("8.5"));
        assertThat(notes(eval).get("lexique")).isEqualByComparingTo(new BigDecimal("5"));
        // (8.5 + 8.5 + 5 + 4)/4 = 6.5 -> A1, et non A2/B1.
        assertThat(eval.getNoteSur20()).isEqualByComparingTo(new BigDecimal("6.5"));
        assertThat(eval.getNiveauCecrl()).isEqualTo(NiveauCecrl.A1);
    }

    @Test
    void couplage_ne_touche_pas_une_production_coherente() {
        stubLlm(feedbackV5(15, 14, 13, 13));
        ProductionSubmission sub = submission(task(EpreuveType.TCF_EE, 1), TEXTE_EE);

        AiEvaluation eval = service.evaluate(sub.getId());

        assertThat(notes(eval).get("communiquer")).isEqualByComparingTo(new BigDecimal("15"));
        assertThat(notes(eval).get("interagir")).isEqualByComparingTo(new BigDecimal("14"));
    }

    @Test
    void couplage_desactivable_pour_la_mesure() {
        props.getCouplage().setEnabled(false);
        buildService();
        stubLlm(feedbackV5(18, 17, 5, 4));
        ProductionSubmission sub = submission(task(EpreuveType.TCF_EE, 1), TEXTE_EE);

        assertThat(notes(service.evaluate(sub.getId())).get("communiquer"))
            .isEqualByComparingTo(new BigDecimal("18"));
    }

    // ------------------------------------------------------ plafonds cibles

    /**
     * Les deux plafonds cibles etaient cables sur {@code prise_position} et
     * {@code conduite_echange}, qui n'existent plus en v5 : ils lisent
     * desormais {@code communiquer}, qui les absorbe. Sans ce repli ils
     * seraient devenus des no-op silencieux.
     */
    @Test
    void plafond_T3_sans_prise_de_position_mord_via_communiquer() {
        // communiquer 4 (aucune opinion identifiable) mais langue B2 : sans le
        // plafond la note ferait 14 -> B1. Le plafond ramene a A2 et l'explique.
        stubLlm(feedbackV5(4, 16, 18, 18));
        ProductionSubmission sub = submission(task(EpreuveType.TCF_EE, 3),
            "Le télétravail est une pratique répandue. Beaucoup de gens travaillent chez eux "
                + "et les entreprises proposent souvent cette possibilité à leurs salariés.");

        AiEvaluation eval = service.evaluate(sub.getId());

        assertThat(eval.getNiveauCecrl()).isEqualTo(NiveauCecrl.A2);
        assertThat(eval.getFeedbackJson().get(AiEvaluationService.PLAFOND_NIVEAU_KEY))
            .isEqualTo("A2");
    }

    @Test
    void plafond_EO_T2_sans_echange_mord_via_communiquer() {
        stubLlm(feedbackV5(3, 16, 18, 18));
        ProductionSubmission sub = submissionOrale(task(EpreuveType.TCF_EO, 2),
            "Examinateur : Bonjour, bienvenue à la mairie, je vous écoute.\n"
                + "Candidat : euh bonjour madame je voudrais des renseignements pour une inscription\n"
                + "Examinateur : Très bien, pour qui souhaitez-vous inscrire ?\n"
                + "Candidat : euh voilà c'est ça oui merci beaucoup au revoir madame bonne journée");

        AiEvaluation eval = service.evaluate(sub.getId());

        assertThat(eval.getNiveauCecrl()).isEqualTo(NiveauCecrl.A2);
    }

    // ------------------------------------------------- contrat de sortie v3

    @Test
    void points_a_ameliorer_gardent_le_comment_et_l_exemple() {
        stubLlm(feedbackV5(14, 12, 13, 13));
        ProductionSubmission sub = submission(task(EpreuveType.TCF_EE, 1), TEXTE_EE);

        AiEvaluation eval = service.evaluate(sub.getId());

        Object points = eval.getFeedbackJson().get("points_a_ameliorer");
        assertThat(points).asInstanceOf(org.assertj.core.api.InstanceOfAssertFactories.LIST)
            .hasSize(1)
            .first()
            .asInstanceOf(org.assertj.core.api.InstanceOfAssertFactories.MAP)
            .containsKeys("constat", "comment", "exemple");
    }

    /**
     * Forme UNIQUE pour les 3 fronts : une priorite renvoyee en simple chaine
     * (schemas anterieurs, production invalide) devient un objet
     * {@code {constat}} — les fronts n'ont jamais deux formes a gerer.
     */
    @Test
    void points_a_ameliorer_en_chaine_sont_normalises_en_objets() {
        Map<String, Object> feedback = feedbackV5(14, 12, 13, 13);
        feedback.put("points_a_ameliorer", new ArrayList<>(List.of("Varier les connecteurs")));
        stubLlm(feedback);
        ProductionSubmission sub = submission(task(EpreuveType.TCF_EE, 1), TEXTE_EE);

        AiEvaluation eval = service.evaluate(sub.getId());

        assertThat(eval.getFeedbackJson().get("points_a_ameliorer"))
            .asInstanceOf(org.assertj.core.api.InstanceOfAssertFactories.LIST)
            .first()
            .asInstanceOf(org.assertj.core.api.InstanceOfAssertFactories.MAP)
            .containsEntry("constat", "Varier les connecteurs");
    }

    @Test
    void production_invalide_expose_aussi_des_objets() {
        ProductionSubmission sub = submission(task(EpreuveType.TCF_EE, 1),
            "Hello Mary, I am writing to tell you that I finally found a new apartment "
                + "in the city center, it is very nice and it has two bedrooms.");

        AiEvaluation eval = service.evaluate(sub.getId());

        assertThat(eval.getNoteSur20()).isNull();
        assertThat(eval.getFeedbackJson().get("points_a_ameliorer"))
            .asInstanceOf(org.assertj.core.api.InstanceOfAssertFactories.LIST)
            .isNotEmpty()
            .first()
            .asInstanceOf(org.assertj.core.api.InstanceOfAssertFactories.MAP)
            .containsKey("constat");
    }

    /** Les libelles rendus au candidat viennent de la rubrique, ACCENTUES. */
    @Test
    void labels_accentues_remontent_dans_les_scores() {
        stubLlm(feedbackV5(14, 12, 13, 13));
        ProductionSubmission sub = submission(task(EpreuveType.TCF_EE, 1), TEXTE_EE);

        AiEvaluation eval = service.evaluate(sub.getId());

        @SuppressWarnings("unchecked")
        List<Map<String, Object>> scores =
            (List<Map<String, Object>>) eval.getFeedbackJson().get("scores_criteres");
        assertThat(scores).allSatisfy(s ->
            assertThat(String.valueOf(s.get("label"))).isNotBlank());
        assertThat(String.valueOf(scores.get(0).get("label"))).contains("tâche");
    }
}
