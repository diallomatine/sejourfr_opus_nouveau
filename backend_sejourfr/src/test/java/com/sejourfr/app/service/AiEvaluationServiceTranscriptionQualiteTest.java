package com.sejourfr.app.service;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.ProductionSubmissionSource;
import com.sejourfr.app.enums.SubmissionStatut;
import com.sejourfr.app.manager.AiEvaluationManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.manager.TranscriptionManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.ObjectMapper;

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
 * CE QUE L'INDICATEUR DE QUALITE DE TRANSCRIPTION DECLENCHE, bout en bout — et
 * surtout ce qu'il ne declenche pas.
 *
 * <p>Trois garanties, dans cet ordre d'importance :
 * <ol>
 *   <li><b>la note et le niveau ne bougent jamais</b>, transcription abimee ou
 *       non. C'est ce qui permet de livrer ces filets sans campagne de banc ;</li>
 *   <li>la <b>confiance</b> est plafonnee : une transcription abimee est un
 *       obstacle a l'OBSERVATION, pas un defaut du candidat ;</li>
 *   <li><b>l'ECRIT n'est jamais touche</b>. Mesure sur les 142 evaluations de la
 *       base : 0 artefact sur 67 productions ecrites, contre 9 sur 75 orales. A
 *       l'ecrit le candidat tape chaque lettre — une forme fautive y est une
 *       vraie faute.</li>
 * </ol>
 */
class AiEvaluationServiceTranscriptionQualiteTest {

    /** Extrait REEL de la fenetre du bug « mot coupe » : mesure > 10 % de formes suspectes. */
    private static final String DIALOGUE_DEGRADE = """
        Examinateur : Voici la deuxième partie, je suis l'employé de l'agence de location.
        Candidat : Bo njour. Je suis l' emplo yé de l' age nce de location de voi ture.
        Candidat : Oui , bon jour , j'ai mera is lou er une peti te voi ture cita di ne .
        Candidat : Est-ce que vou s en avez de dis po nible là immédiatement s'il vous plaît.
        Candidat : J' ai merais la lou er pour 5 jours pour un week-end à Perpi gnan.
        """;

    /** Meme source, meme modele, apres correction du bug : mesure < 5 %. */
    private static final String DIALOGUE_SAIN = """
        Examinateur : Bonjour, pouvez-vous vous présenter ?
        Candidat : Oui, bonjour, je me nomme Diallo, j'ai 21 ans et je suis d'origine guinéenne, je suis un étudiant en informatique et j'habite à Lille.
        Examinateur : Et vos projets après le master ?
        Candidat : Après le master j'aimerais travailler, chercher de l'expérience en CDI pendant deux ou trois ans, et ensuite rentrer en Guinée pour aider mon pays.
        """;

    /**
     * Production ECRITE portant exactement la meme forme fautive isolee. A
     * l'ecrit, c'est une vraie faute : rien ne doit etre purge.
     */
    private static final String TEXTE_ECRIT = """
        Salut Paul ! J'ai une bonne nouvelle : j'ai enfin déménagé la semaine dernière. \
        Maintenant abit à Lille, tout près de la gare, dans un logement lumineux avec un \
        petit jardin derrière. Viens passer le week-end quand tu veux, il y a de la place.
        """;

    private ProductionSubmissionManager submissionManager;
    private TranscriptionManager transcriptionManager;
    private AiEvaluationManager aiEvaluationManager;
    private EvaluationLlmClient llmClient;
    private ProductionEvaluationProperties props;
    private AiEvaluationService service;

    @BeforeEach
    void setUp() {
        submissionManager = mock(ProductionSubmissionManager.class);
        transcriptionManager = mock(TranscriptionManager.class);
        aiEvaluationManager = mock(AiEvaluationManager.class);
        llmClient = mock(EvaluationLlmClient.class);
        when(llmClient.getModelName()).thenReturn("modele-test");
        when(llmClient.getPromptVersion()).thenReturn("v8");
        when(aiEvaluationManager.save(any())).thenAnswer(inv -> inv.getArgument(0));

        props = new ProductionEvaluationProperties();
        props.setRubricsVersion("v14"); // paire active v14 / tool-schema v8
        ProductionRubricsProvider rubrics = new ProductionRubricsProvider(props, new ObjectMapper());
        rubrics.load();
        service = new AiEvaluationService(submissionManager, transcriptionManager, aiEvaluationManager,
            llmClient, new EvaluationPromptBuilder(new ObjectMapper(), rubrics), rubrics,
            new ProductionValidityService(props),
            new ProductionSecondePasseService(props, mock(EvaluationLlmClient.class), rubrics),
            new ProductionFluiditeService(props), new EvaluationRefusalMetrics(),
            new EvaluationPurgeMetrics(), props);
    }

    // ------------------------------------------- la note ne bouge JAMAIS

    @Test
    void une_transcription_degradee_ne_change_ni_la_note_ni_le_niveau() {
        stubLlm(feedbackOral());
        AiEvaluation saine = service.evaluate(submissionOrale(DIALOGUE_SAIN).getId());

        stubLlm(feedbackOral());
        AiEvaluation degradee = service.evaluate(submissionOrale(DIALOGUE_DEGRADE).getId());

        assertThat(degradee.getNoteSur20()).isEqualByComparingTo(saine.getNoteSur20());
        assertThat(degradee.getNiveauCecrl()).isEqualTo(saine.getNiveauCecrl());
    }

    // --------------------------------------------------- la confiance

    @Test
    void une_transcription_degradee_plafonne_la_confiance_et_dit_pourquoi() {
        stubLlm(feedbackOral());
        AiEvaluation eval = service.evaluate(submissionOrale(DIALOGUE_DEGRADE).getId());

        assertThat(eval.getFeedbackJson().get("confiance")).isEqualTo("FAIBLE");
        assertThat(raisons(eval))
            .anySatisfy(r -> assertThat(r).contains("dégradée"));
    }

    @Test
    void une_transcription_saine_ne_plafonne_pas_au_dela_du_temps_reel() {
        stubLlm(feedbackOral());
        AiEvaluation eval = service.evaluate(submissionOrale(DIALOGUE_SAIN).getId());

        // Le plafond REALTIME (MOYENNE) reste, celui de la degradation ne s'ajoute pas.
        assertThat(eval.getFeedbackJson().get("confiance")).isEqualTo("MOYENNE");
        assertThat(raisons(eval)).noneSatisfy(r -> assertThat(r).contains("dégradée"));
    }

    // ------------------------------------------------- l'ecrit est intact

    @Test
    void a_l_ecrit_une_forme_fautive_isolee_reste_reprochee() {
        Map<String, Object> feedback = feedbackEcrit();
        stubLlm(feedback);

        AiEvaluation eval = service.evaluate(submissionEcrite().getId());

        assertThat(commentaire(eval, "morphosyntaxe"))
            .as("a l'ecrit, le candidat tape chaque lettre : 0 artefact sur 67 productions mesurees")
            .contains("abit à Lille");
        assertThat(avertissements(eval))
            .noneSatisfy(a -> assertThat(a)
                .isEqualTo(EvaluationOralArtifactFilter.AVERTISSEMENT_FORME));
    }

    /** A l'ORAL, la meme phrase sur la meme forme est retiree, et le candidat est prevenu. */
    @Test
    void a_l_oral_la_meme_forme_est_retiree_et_le_candidat_est_prevenu() {
        Map<String, Object> feedback = feedbackOral();
        scoreDe(feedback, "morphosyntaxe").put("commentaire",
            "Phrases simples correctement construites. "
                + "On relève une erreur perceptible : « abit à Lille » (j'habite).");
        stubLlm(feedback);

        AiEvaluation eval = service.evaluate(submissionOrale(DIALOGUE_ABIT).getId());

        assertThat(commentaire(eval, "morphosyntaxe")).doesNotContain("abit à Lille");
        assertThat(avertissements(eval))
            .contains(EvaluationOralArtifactFilter.AVERTISSEMENT_FORME);
    }

    /** Transcription saine ou non, la meme forme isolee est ecartee a l'oral. */
    private static final String DIALOGUE_ABIT = """
        Examinateur : Bonjour, pouvez-vous vous présenter ?
        Candidat : Oui, bonjour, je me nomme Diallo, j'ai 21 ans, je suis un étudiant en informatique en licence 3 et puis abit à Lille et j'étudie également à l'université de Lille.
        Examinateur : Et vos projets après le master ?
        Candidat : Après le master j'aimerais travailler, chercher de l'expérience en CDI pendant deux ou trois ans, et ensuite rentrer en Guinée pour aider mon pays.
        """;

    // ------------------------------------------------------------- fixtures

    private void stubLlm(Map<String, Object> feedback) {
        when(llmClient.evaluate(anyString(), anyString()))
            .thenReturn(new EvaluationLlmClient.Outcome(feedback, 100, 200, 3));
    }

    @SuppressWarnings("unchecked")
    private static List<String> raisons(AiEvaluation eval) {
        Object raw = eval.getFeedbackJson().get("confiance_raisons");
        return raw instanceof List<?> l ? (List<String>) l : List.of();
    }

    @SuppressWarnings("unchecked")
    private static List<String> avertissements(AiEvaluation eval) {
        Object raw = eval.getFeedbackJson().get("avertissements");
        return raw instanceof List<?> l ? (List<String>) l : List.of();
    }

    @SuppressWarnings("unchecked")
    private static String commentaire(AiEvaluation eval, String code) {
        for (Object raw : (List<Object>) eval.getFeedbackJson().get("scores_criteres")) {
            Map<String, Object> s = (Map<String, Object>) raw;
            if (code.equals(s.get("code"))) return String.valueOf(s.get("commentaire"));
        }
        throw new IllegalStateException("critere absent : " + code);
    }

    @SuppressWarnings("unchecked")
    private static Map<String, Object> scoreDe(Map<String, Object> feedback, String code) {
        for (Object raw : (List<Object>) feedback.get("scores_criteres")) {
            Map<String, Object> s = (Map<String, Object>) raw;
            if (code.equals(s.get("code"))) return s;
        }
        throw new IllegalStateException("critere absent : " + code);
    }

    private ProductionTask task(EpreuveType epreuve, int tache) {
        ProductionTask t = new ProductionTask();
        t.setId(UUID.randomUUID());
        t.setEpreuve(epreuve);
        t.setTacheNumero((short) tache);
        t.setNiveauCible("B1");
        t.setConsigne("Vous venez d'emménager. Écrivez à un ami pour annoncer la nouvelle, "
            + "décrire votre logement et l'inviter.");
        return t;
    }

    private ProductionSubmission submissionEcrite() {
        ProductionSubmission s = new ProductionSubmission();
        s.setId(UUID.randomUUID());
        s.setProductionTask(task(EpreuveType.TCF_EE, 1));
        s.setStatut(SubmissionStatut.SUBMITTED);
        s.setTexteSoumis(TEXTE_ECRIT);
        when(submissionManager.findById(s.getId())).thenReturn(Optional.of(s));
        return s;
    }

    private ProductionSubmission submissionOrale(String transcription) {
        ProductionSubmission s = new ProductionSubmission();
        s.setId(UUID.randomUUID());
        s.setProductionTask(task(EpreuveType.TCF_EO, 1));
        s.setStatut(SubmissionStatut.SUBMITTED);
        s.setSource(ProductionSubmissionSource.REALTIME);
        s.setMediaDurationSec(180);
        when(submissionManager.findById(s.getId())).thenReturn(Optional.of(s));
        when(transcriptionManager.findLatestTexteBySubmissionId(s.getId()))
            .thenReturn(Optional.of(transcription));
        return s;
    }

    private static Map<String, Object> feedbackEcrit() {
        Map<String, Object> f = base();
        f.put("scores_criteres", new ArrayList<>(List.of(
            score("communiquer", 8, "j'ai enfin déménagé"),
            score("interagir", 8, "Salut Paul"),
            score("lexique", 7, "il est lumineux"),
            score("morphosyntaxe", 7,
                "Quelques erreurs perceptibles : « abit à Lille » (j'habite)."))));
        return f;
    }

    private static Map<String, Object> feedbackOral() {
        Map<String, Object> f = base();
        f.put("scores_criteres", new ArrayList<>(List.of(
            score("communiquer", 8, "Présentation complète et compréhensible."),
            score("interagir", 8, "Le candidat répond aux questions posées."),
            score("lexique", 7, "Lexique de base adapté à la situation."),
            score("morphosyntaxe", 7, "Phrases simples correctement construites."))));
        return f;
    }

    private static Map<String, Object> base() {
        Map<String, Object> f = new LinkedHashMap<>();
        f.put("note_globale", 7);
        f.put("niveau_cecrl", "B1");
        f.put("justification_niveau", "Emploi du passé composé et lexique du quotidien.");
        f.put("confiance", "HAUTE");
        f.put("confiance_raisons", new ArrayList<>(List.of("production complète et lisible")));
        Map<String, Object> acc = new LinkedHashMap<>();
        acc.put("objectif", "ATTEINT");
        acc.put("objectif_resume", "Tu te présentes et tu réponds aux questions.");
        acc.put("points_traites", new ArrayList<>(List.of(
            Map.of("libelle", "Présentation faite", "obligatoire", true))));
        acc.put("points_oublies", new ArrayList<>());
        f.put("accomplissement", acc);
        f.put("points_forts", new ArrayList<>(List.of("Message clair")));
        f.put("points_a_ameliorer", new ArrayList<>(List.of(new LinkedHashMap<>(Map.of(
            "constat", "Vos idées sont juxtaposées.",
            "comment", "Reliez-les avec « parce que ».")))));
        f.put("suggestions", new ArrayList<>());
        f.put("exemples_corriges", new ArrayList<>());
        return f;
    }

    private static Map<String, Object> score(String code, Number note, String commentaire) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("code", code);
        m.put("note_sur_20", note);
        m.put("commentaire", commentaire);
        m.put("preuve_segment", 1); // contrat v8 : la preuve est un NUMERO de segment
        return m;
    }
}
