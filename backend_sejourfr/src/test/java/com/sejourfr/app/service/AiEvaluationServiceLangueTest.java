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
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
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
 * Rubriques v10 ET v11 / tool-schema v5. Les deux ajoutent UNE regle — la regle
 * de LANGUE de la section orale, asymetrique EE/EO — et ne touchent a rien
 * d'autre. v11 succede a v10 : meme regle, un tiers de texte en moins, sanction
 * enoncee avant tolerance, et rappel explicite que le hors-sujet et la
 * transcription bruitee ne changent pas.
 *
 * <p><b>Ce que verrouille cette classe</b> : v10 se charge bien sur le contrat
 * v5, et surtout la NOTATION est celle de v9 <b>au point pres</b>. C'est le
 * pendant runtime du verrou statique de {@code ProductionEvaluationContractTest}
 * : le meme jeu de {@code scores_criteres} doit donner exactement la meme note
 * et le meme niveau sous v9, v10 et v11, a l'ecrit comme a l'oral. Sans cette
 * garantie, la campagne de banc ne serait pas interpretable — on ne saurait pas
 * si un ecart vient de la nouvelle consigne ou d'un bareme deplace.
 *
 * <p><b>⚠️ v10 et v11 sont MESUREES MOINS BONNES QUE v9 et NE SONT PAS
 * ACTIVEES</b> (campagne du 2026-08-07, temoin v9 du meme jour, meme modele,
 * {@code retries=1} : niveaux exacts 81,8 % pour v9 contre 75,6 % et 76,7 % ;
 * corrections perdues 8,33 % contre 14,58 % et 10,42 %). Elles restent
 * chargeables — on ne supprime jamais une grille livree — et cette classe
 * verrouille le fait qu'elles n'ont deplace aucun bareme. <b>Ne pas reessayer
 * cette voie sans le savoir</b> : le comportement vise est desormais tenu par un
 * controle serveur deterministe ({@link EvaluationOralArtifactFilter}, volet
 * LANGUE), teste dans {@code EvaluationOralArtifactFilterTest}.
 *
 * <p>La regle de langue de v10/v11 est une CONSIGNE donnee au correcteur : aucun
 * code serveur ne l'applique, donc elle ne se teste pas ici. Elle se mesure au
 * banc, sur le corpus — et en particulier sur le piege {@code AUTRE_LANGUE}
 * ({@code EO_T3_PIEGE_01}), qui doit continuer d'etre sanctionne.
 */
class AiEvaluationServiceLangueTest {

    private static final String TEXTE_EE =
        "Salut Paul ! J'ai une bonne nouvelle : j'ai enfin déménagé la semaine dernière. "
            + "Mon logement se trouve près de la gare, il est lumineux et il y a un petit "
            + "jardin derrière. Viens passer le week-end quand tu veux, il y a de la place.";

    /**
     * Dialogue temps reel portant un fragment en langue etrangere ISOLE au
     * milieu d'une production francaise : c'est la forme reellement observee en
     * base (un tour halluciné par le transcripteur multilingue de Gemini Live).
     */
    private static final String DIALOGUE_EO =
        "Examinateur : Bonjour, pourquoi souhaitez-vous déménager ?\n"
            + "Candidat : je veux aller habiter à Lille parce que le loyer est moins cher "
            + "pour ma famille\n"
            + "Candidat : Ja. Dus kan nog sorteer de weekenden\n"
            + "Examinateur : Et les transports, cela vous inquiète ?\n"
            + "Candidat : non il y a le tramway et je mets vingt minutes";

    private com.sejourfr.app.manager.ProductionSubmissionManager submissionManager;
    private com.sejourfr.app.manager.TranscriptionManager transcriptionManager;
    private com.sejourfr.app.manager.AiEvaluationManager aiEvaluationManager;
    private EvaluationLlmClient llmClient;
    private ProductionEvaluationProperties props;
    private AiEvaluationService service;

    @BeforeEach
    void setUp() {
        submissionManager = mock(com.sejourfr.app.manager.ProductionSubmissionManager.class);
        transcriptionManager = mock(com.sejourfr.app.manager.TranscriptionManager.class);
        aiEvaluationManager = mock(com.sejourfr.app.manager.AiEvaluationManager.class);
        llmClient = mock(EvaluationLlmClient.class);
        when(llmClient.getModelName()).thenReturn("modele-test");
        when(llmClient.getPromptVersion()).thenReturn("v5");
        when(aiEvaluationManager.save(any())).thenAnswer(inv -> inv.getArgument(0));

        props = new ProductionEvaluationProperties();
        props.setRubricsVersion("v10");
        buildService();
    }

    private void buildService() {
        ProductionRubricsProvider rubrics = new ProductionRubricsProvider(props, new ObjectMapper());
        rubrics.load();
        service = new AiEvaluationService(submissionManager, transcriptionManager, aiEvaluationManager,
            llmClient, new EvaluationPromptBuilder(new ObjectMapper(), rubrics), rubrics,
            new ProductionValidityService(props),
            new ProductionSecondePasseService(props, mock(EvaluationLlmClient.class), rubrics),
            new ProductionFluiditeService(props), new EvaluationRefusalMetrics(), new EvaluationPurgeMetrics(), props);
    }

    // --------------------------------------------------------- non-regression

    /** ECRIT : ni v10 ni v11 ne touchent a un bareme — meme sortie, meme note. */
    @ParameterizedTest
    @CsvSource({"v10", "v11"})
    void la_notation_ecrite_est_identique_a_celle_de_v9(String version) {
        props.setRubricsVersion(version);
        buildService();
        stubLlm(feedbackEcrit(12, 11, 1, 1));
        AiEvaluation v10 = service.evaluate(submissionEcrite().getId());

        props.setRubricsVersion("v9");
        buildService();
        stubLlm(feedbackEcrit(12, 11, 1, 1));
        AiEvaluation v9 = service.evaluate(submissionEcrite().getId());

        assertThat(v10.getNoteSur20()).isEqualByComparingTo(v9.getNoteSur20());
        assertThat(v10.getNiveauCecrl()).isEqualTo(v9.getNiveauCecrl());
        // Couplage a 1 point : une langue a 1 plafonne la realisation.
        assertThat(v10.getNoteSur20()).isEqualByComparingTo("1.5");
        assertThat(v10.getNiveauCecrl()).isEqualTo(NiveauCecrl.A1);
    }

    /** ORAL : idem. La nouvelle consigne ne deplace aucun seuil. */
    @ParameterizedTest
    @CsvSource({"v10", "v11"})
    void la_notation_orale_est_identique_a_celle_de_v9(String version) {
        props.setRubricsVersion(version);
        buildService();
        stubLlm(feedbackOral());
        AiEvaluation v10 = service.evaluate(submissionOrale().getId());

        props.setRubricsVersion("v9");
        buildService();
        stubLlm(feedbackOral());
        AiEvaluation v9 = service.evaluate(submissionOrale().getId());

        assertThat(v10.getNoteSur20()).isEqualByComparingTo(v9.getNoteSur20());
        assertThat(v10.getNiveauCecrl()).isEqualTo(v9.getNiveauCecrl());
        assertThat(v10.getNiveauCecrl()).isEqualTo(NiveauCecrl.B1);
    }

    /** v10/v11 se chargent sur le contrat v5, avec les parametres de note de v9. */
    @ParameterizedTest
    @CsvSource({"v10", "v11"})
    void seChargeSurLeContratV5_avecLesParametresDeV9(String version) {
        props.setRubricsVersion(version);
        ProductionRubricsProvider v10 = new ProductionRubricsProvider(props, new ObjectMapper());
        v10.load();

        ProductionEvaluationProperties p9 = new ProductionEvaluationProperties();
        p9.setRubricsVersion("v9");
        ProductionRubricsProvider v9 = new ProductionRubricsProvider(p9, new ObjectMapper());
        v9.load();

        assertThat(v10.niveauCecrl().getSeuilB2()).isEqualTo(v9.niveauCecrl().getSeuilB2());
        assertThat(v10.niveauCecrl().getSeuilB1()).isEqualTo(v9.niveauCecrl().getSeuilB1());
        assertThat(v10.niveauCecrl().getSeuilA2()).isEqualTo(v9.niveauCecrl().getSeuilA2());
        assertThat(v10.couplage().getEcartMax()).isEqualTo(v9.couplage().getEcartMax());
        assertThat(v10.bandesCriteres()).usingRecursiveComparison().isEqualTo(v9.bandesCriteres());
    }

    // -------------------------------------------------- la regle, dans le prompt

    /**
     * La regle de langue part bien dans le prompt systeme, avec ses DEUX faces :
     * la tolerance (artefact) et la sanction (vraie bascule). L'une sans l'autre
     * casserait soit le candidat, soit le piege {@code AUTRE_LANGUE}.
     */
    @ParameterizedTest
    @CsvSource({"v10", "v11"})
    void la_regle_de_langue_part_dans_le_prompt_avec_ses_deux_faces(String version) {
        props.setRubricsVersion(version);
        ProductionRubricsProvider rubrics = new ProductionRubricsProvider(props, new ObjectMapper());
        rubrics.load();
        String systemPrompt = new EvaluationPromptBuilder(new ObjectMapper(), rubrics)
            .buildSystemPrompt();

        assertThat(systemPrompt)
            .as(version + " : la tolerance ET la sanction partent toutes les deux")
            .contains("un quart")
            .contains("SEUL LE FRANCAIS REELLEMENT PRODUIT COMPTE")
            .contains("A L'ECRIT, RIEN DE CETTE REGLE NE S'APPLIQUE");
    }

    /**
     * v11 seule : elle reaffirme ce que la campagne du 2026-08-07 a vu deriver
     * sous v10 (hors-sujet et transcription bruitee).
     */
    @Test
    void v11_rappelle_dans_le_prompt_ce_que_la_regle_ne_change_pas() {
        props.setRubricsVersion("v11");
        ProductionRubricsProvider rubrics = new ProductionRubricsProvider(props, new ObjectMapper());
        rubrics.load();

        assertThat(new EvaluationPromptBuilder(new ObjectMapper(), rubrics).buildSystemPrompt())
            .contains("CE QUE CETTE REGLE NE CHANGE PAS")
            .contains("HORS-SUJET")
            .contains("BRUITEE");
    }

    /** v9 ne la portait pas : c'est bien v10 qui l'introduit. */
    @Test
    void v9_ne_portait_pas_cette_regle() {
        ProductionEvaluationProperties p9 = new ProductionEvaluationProperties();
        p9.setRubricsVersion("v9");
        ProductionRubricsProvider v9 = new ProductionRubricsProvider(p9, new ObjectMapper());
        v9.load();

        assertThat(new EvaluationPromptBuilder(new ObjectMapper(), v9).buildSystemPrompt())
            .doesNotContain("LANGUE OU ECRITURE ETRANGERE A L'ORAL");
    }

    // ------------------------------------------------------------- fixtures

    private void stubLlm(Map<String, Object> feedback) {
        when(llmClient.evaluate(anyString(), anyString()))
            .thenReturn(new EvaluationLlmClient.Outcome(feedback, 100, 200, 3));
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
        s.setTexteSoumis(TEXTE_EE);
        when(submissionManager.findById(s.getId())).thenReturn(Optional.of(s));
        return s;
    }

    private ProductionSubmission submissionOrale() {
        ProductionSubmission s = new ProductionSubmission();
        s.setId(UUID.randomUUID());
        s.setProductionTask(task(EpreuveType.TCF_EO, 2));
        s.setStatut(SubmissionStatut.SUBMITTED);
        s.setMediaDurationSec(210);
        when(submissionManager.findById(s.getId())).thenReturn(Optional.of(s));
        when(transcriptionManager.findLatestTexteBySubmissionId(s.getId()))
            .thenReturn(Optional.of(DIALOGUE_EO));
        return s;
    }

    private static Map<String, Object> feedbackEcrit(Number communiquer, Number interagir,
                                                     Number lexique, Number morphosyntaxe) {
        Map<String, Object> f = base();
        f.put("scores_criteres", new ArrayList<>(List.of(
            score("communiquer", communiquer, "j'ai enfin déménagé"),
            score("interagir", interagir, "Salut Paul"),
            score("lexique", lexique, "il est lumineux"),
            score("morphosyntaxe", morphosyntaxe, "Viens passer le week-end"))));
        f.put("version_amelioree", "Salut Paul ! J'ai déménagé la semaine dernière parce que "
            + "mon ancien logement était trop petit. Viens quand tu veux.");
        return f;
    }

    private static Map<String, Object> feedbackOral() {
        Map<String, Object> f = base();
        f.put("scores_criteres", new ArrayList<>(List.of(
            score("communiquer", 7, "le loyer est moins cher"),
            score("interagir", 7, "il y a le tramway"),
            score("lexique", 7, "pour ma famille"),
            score("morphosyntaxe", 7, "je mets vingt minutes"))));
        return f;
    }

    private static Map<String, Object> base() {
        Map<String, Object> f = new LinkedHashMap<>();
        f.put("note_globale", 7);
        f.put("niveau_cecrl", "B1");
        f.put("justification_niveau", "Emploi du passé composé et lexique du logement.");
        f.put("confiance", "HAUTE");
        f.put("confiance_raisons", new ArrayList<>(List.of("production complète et lisible")));
        Map<String, Object> acc = new LinkedHashMap<>();
        acc.put("objectif", "ATTEINT");
        acc.put("objectif_resume", "Tu expliques ton projet et tu réponds aux questions.");
        acc.put("points_traites", new ArrayList<>(List.of(
            Map.of("libelle", "Projet expliqué", "obligatoire", true))));
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

    private static Map<String, Object> score(String code, Number note, String preuve) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("code", code);
        m.put("note_sur_20", note);
        m.put("commentaire", "Commentaire neutre sur " + code + ".");
        m.put("preuve", preuve);
        return m;
    }
}
