package com.sejourfr.app.service.versionciblee;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.SubmissionStatut;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.exception.AiEvaluationException;
import com.sejourfr.app.manager.AiEvaluationManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.service.EvaluationPurgeMetrics;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import tools.jackson.databind.ObjectMapper;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

/**
 * « Version au niveau visé » — SECOND appel LLM, séparé de la correction.
 *
 * <p>Ce que verrouille cette classe :
 * <ul>
 *   <li>rien n'est produit quand le niveau visé est <b>déjà atteint</b> ;</li>
 *   <li>rien n'est produit à l'ORAL (EE seulement, miroir de
 *       {@code version_amelioree}) ;</li>
 *   <li>un échec de ce second appel ne dégrade JAMAIS l'évaluation : pas
 *       d'exception, pas de bloc, l'évaluation reste telle quelle ;</li>
 *   <li>le niveau visé du candidat n'est envoyé qu'à CE prompt-là — le
 *       correcteur ne l'apprend jamais ;</li>
 *   <li>les plafonds sont tenus SERVEUR, pas seulement demandés au modèle.</li>
 * </ul>
 */
class ProductionVersionCibleeServiceTest {

    private static final String TEXTE_EE =
        "Salut Paul ! J'ai déménagé la semaine dernière. Mon logement est près de la gare. "
            + "C'est bien. Viens quand tu veux.";

    /**
     * Version modèle conforme aux bornes de la tâche de test (40 à 90 mots).
     * Les tests ne peuvent plus se contenter de « Version B2. » : depuis que la
     * longueur est un contrôle DUR, un texte de deux mots est refusé — comme il
     * le serait à la soumission.
     */
    private static final String VERSION_CONFORME_45_MOTS = motsFactices(45);

    private ProductionSubmissionManager submissionManager;
    private AiEvaluationManager aiEvaluationManager;
    private VersionCibleeLlmClient llmClient;
    private EvaluationPurgeMetrics purgeMetrics;
    private ProductionEvaluationProperties props;
    private ProductionVersionCibleeService service;

    @BeforeEach
    void setUp() {
        submissionManager = mock(ProductionSubmissionManager.class);
        aiEvaluationManager = mock(AiEvaluationManager.class);
        llmClient = mock(VersionCibleeLlmClient.class);
        when(llmClient.getModelName()).thenReturn("modele-test");
        when(aiEvaluationManager.save(any())).thenAnswer(inv -> inv.getArgument(0));

        props = new ProductionEvaluationProperties();
        VersionCibleeRubricsProvider rubrics =
            new VersionCibleeRubricsProvider(props, new ObjectMapper());
        rubrics.load();
        purgeMetrics = new EvaluationPurgeMetrics();
        service = new ProductionVersionCibleeService(
            submissionManager, aiEvaluationManager, llmClient,
            new VersionCibleePromptBuilder(new ObjectMapper(), rubrics),
            new VersionCibleeValidator(rubrics), purgeMetrics, props);
    }

    // ------------------------------------------------------------ cas nominal

    @Test
    @SuppressWarnings("unchecked")
    void ajouteLaVersionAuNiveauViseQuandIlResteQuelqueChoseAViser() {
        ProductionSubmission sub = submissionEcrite(TargetLevel.B2);
        AiEvaluation eval = eval(NiveauCecrl.A2, sub.getId());
        stubLlm(sortie(
            "Je suis heureux de t'annoncer que j'ai enfin emménagé près de la gare, la semaine "
                + "dernière. L'appartement est lumineux et le quartier me plaît beaucoup, car il "
                + "y a des commerces à deux pas. Passe quand tu veux ce week-end : je te ferai "
                + "visiter et nous prendrons un café ensemble.",
            List.of("Relier les idées avec « puisque » plutôt que de les juxtaposer.",
                "Remplacer « c'est bien » par un adjectif précis comme « lumineux ».")));

        service.enrichir(sub.getId());

        Map<String, Object> bloc = (Map<String, Object>) eval.getFeedbackJson()
            .get(VersionCibleeFields.BLOC);
        assertThat(bloc).isNotNull();
        assertThat(bloc.get(VersionCibleeFields.NIVEAU_VISE)).isEqualTo("B2");
        assertThat(bloc.get(VersionCibleeFields.NIVEAU_CONSTATE)).isEqualTo("A2");
        assertThat(bloc.get(VersionCibleeFields.TEXTE)).asString().isNotBlank();
        assertThat((List<String>) bloc.get(VersionCibleeFields.CE_QUI_MANQUE)).hasSize(2);
        verify(aiEvaluationManager).save(eval);
    }

    /** Le second appel est payé : son coût rejoint celui de la correction. */
    @Test
    void leCoutDuSecondAppelRejointCeluiDeLaCorrection() {
        ProductionSubmission sub = submissionEcrite(TargetLevel.B2);
        AiEvaluation eval = eval(NiveauCecrl.A2, sub.getId());
        eval.setTokensInput(1000);
        eval.setTokensOutput(500);
        eval.setCoutEstimeCentimes(3);
        stubLlm(sortie(VERSION_CONFORME_45_MOTS, List.of("Relier les idées.", "Préciser le lexique.")));

        service.enrichir(sub.getId());

        assertThat(eval.getTokensInput()).isEqualTo(1300);
        assertThat(eval.getTokensOutput()).isEqualTo(700);
        assertThat(eval.getCoutEstimeCentimes()).isEqualTo(4);
    }

    /**
     * LE POINT CAPITAL : le niveau visé n'apparaît QUE dans le prompt de ce
     * second appel. Le prompt de notation, lui, ne le voit jamais — sinon le
     * correcteur alignerait sa note dessus (cf. rubriques v10/v11, mesurées
     * moins bonnes après l'ajout d'un simple bloc de consigne).
     */
    @Test
    void leNiveauViseNEstEnvoyeQuAuSecondAppel() {
        ProductionSubmission sub = submissionEcrite(TargetLevel.B2);
        eval(NiveauCecrl.A2, sub.getId());
        stubLlm(sortie(VERSION_CONFORME_45_MOTS, List.of("Relier les idées.", "Préciser le lexique.")));

        service.enrichir(sub.getId());

        ArgumentCaptor<String> user = ArgumentCaptor.forClass(String.class);
        verify(llmClient).produire(anyString(), user.capture());
        assertThat(user.getValue())
            .contains("\"niveau_vise\":\"B2\"")
            .contains("\"niveau_constate\":\"A2\"")
            .contains(TEXTE_EE);
    }

    // ------------------------------------------------------- rien a produire

    @Test
    void niveauViseDejaAtteint_aucunAppelPaye() {
        ProductionSubmission sub = submissionEcrite(TargetLevel.B1);
        eval(NiveauCecrl.B1, sub.getId());

        service.enrichir(sub.getId());

        verify(llmClient, never()).produire(anyString(), anyString());
        verify(aiEvaluationManager, never()).save(any());
    }

    @Test
    void niveauViseSousLeNiveauConstate_aucunAppelPaye() {
        ProductionSubmission sub = submissionEcrite(TargetLevel.A2);
        eval(NiveauCecrl.B2, sub.getId());

        service.enrichir(sub.getId());

        verify(llmClient, never()).produire(anyString(), anyString());
    }

    /** EE uniquement, en miroir de la règle {@code version_amelioree}. */
    @Test
    void aLOral_rienNEstProduit() {
        ProductionSubmission sub = submissionOrale(TargetLevel.B2);
        eval(NiveauCecrl.A2, sub.getId());

        service.enrichir(sub.getId());

        verify(llmClient, never()).produire(anyString(), anyString());
    }

    @Test
    void coupeCircuitEteint_aucunAppelNiLecture() {
        props.getVersionCiblee().setEnabled(false);
        ProductionSubmission sub = submissionEcrite(TargetLevel.B2);
        eval(NiveauCecrl.A2, sub.getId());

        service.enrichir(sub.getId());

        verifyNoInteractions(llmClient);
        verify(submissionManager, never()).findByIdWithTaskAndUser(any());
    }

    /** Sans {@code TargetLevel} sur le compte, on retombe sur le niveau cible de la tâche. */
    @Test
    @SuppressWarnings("unchecked")
    void sansTargetLevelDuCandidat_leNiveauCibleDeLaTacheFaitFoi() {
        ProductionSubmission sub = submissionEcrite(null);
        sub.getProductionTask().setNiveauCible("B1");
        AiEvaluation eval = eval(NiveauCecrl.A2, sub.getId());
        stubLlm(sortie(VERSION_CONFORME_45_MOTS, List.of("Relier les idées.", "Préciser le lexique.")));

        service.enrichir(sub.getId());

        Map<String, Object> bloc = (Map<String, Object>) eval.getFeedbackJson()
            .get(VersionCibleeFields.BLOC);
        assertThat(bloc.get(VersionCibleeFields.NIVEAU_VISE)).isEqualTo("B1");
    }

    @Test
    void sansAucunNiveauVisable_rienNEstProduit() {
        ProductionSubmission sub = submissionEcrite(null);
        sub.getProductionTask().setNiveauCible("A1");
        eval(NiveauCecrl.A2, sub.getId());

        service.enrichir(sub.getId());

        verify(llmClient, never()).produire(anyString(), anyString());
    }

    // --------------------------------------- best-effort : jamais bloquant

    /**
     * INVARIANT. Le second appel tombe (timeout, 4xx, clé absente) : aucune
     * exception ne sort, l'évaluation n'est pas touchée, la submission reste
     * EVALUATED.
     */
    @Test
    void echecDuSecondAppel_nEndommagePasLEvaluation() {
        ProductionSubmission sub = submissionEcrite(TargetLevel.B2);
        AiEvaluation eval = eval(NiveauCecrl.A2, sub.getId());
        when(llmClient.produire(anyString(), anyString()))
            .thenThrow(new AiEvaluationException("DeepSeek version ciblee indisponible"));

        assertThatCode(() -> service.enrichir(sub.getId())).doesNotThrowAnyException();

        assertThat(eval.getFeedbackJson()).doesNotContainKey(VersionCibleeFields.BLOC);
        assertThat(sub.getStatut()).isEqualTo(SubmissionStatut.EVALUATED);
        verify(aiEvaluationManager, never()).save(any());
    }

    /** Même chose sur une panne imprévue : le service est total, par construction. */
    @Test
    void panneImprevue_neRemontePas() {
        ProductionSubmission sub = submissionEcrite(TargetLevel.B2);
        eval(NiveauCecrl.A2, sub.getId());
        when(llmClient.produire(anyString(), anyString()))
            .thenThrow(new IllegalStateException("boom"));

        assertThatCode(() -> service.enrichir(sub.getId())).doesNotThrowAnyException();
    }

    @Test
    void sortieInvalide_aucunBlocPersisteEtAucunReessai() {
        ProductionSubmission sub = submissionEcrite(TargetLevel.B2);
        AiEvaluation eval = eval(NiveauCecrl.A2, sub.getId());
        // Un seul levier : le contrat en demande deux au minimum.
        stubLlm(sortie(VERSION_CONFORME_45_MOTS, List.of("Relier les idées.")));

        service.enrichir(sub.getId());

        assertThat(eval.getFeedbackJson()).doesNotContainKey(VersionCibleeFields.BLOC);
        verify(llmClient).produire(anyString(), anyString());
        verify(aiEvaluationManager, never()).save(any());
    }

    @Test
    void texteVide_refuse() {
        ProductionSubmission sub = submissionEcrite(TargetLevel.B2);
        AiEvaluation eval = eval(NiveauCecrl.A2, sub.getId());
        stubLlm(sortie("   ", List.of("Relier les idées.", "Préciser le lexique.")));

        service.enrichir(sub.getId());

        assertThat(eval.getFeedbackJson()).doesNotContainKey(VersionCibleeFields.BLOC);
    }

    @Test
    void cleHorsContrat_refusee() {
        ProductionSubmission sub = submissionEcrite(TargetLevel.B2);
        AiEvaluation eval = eval(NiveauCecrl.A2, sub.getId());
        Map<String, Object> sortie = sortie(VERSION_CONFORME_45_MOTS,
            List.of("Relier les idées.", "Préciser le lexique."));
        sortie.put("note_globale", 14);
        stubLlm(sortie);

        service.enrichir(sub.getId());

        assertThat(eval.getFeedbackJson()).doesNotContainKey(VersionCibleeFields.BLOC);
    }

    /** Un levier trop long est refusé : un « levier » de trois lignes n'est plus actionnable. */
    @Test
    void levierBeaucoupTropLong_refuse() {
        ProductionSubmission sub = submissionEcrite(TargetLevel.B2);
        AiEvaluation eval = eval(NiveauCecrl.A2, sub.getId());
        String bavard = "mot ".repeat(60).trim();
        stubLlm(sortie(VERSION_CONFORME_45_MOTS, List.of(bavard, "Préciser le lexique.")));

        service.enrichir(sub.getId());

        assertThat(eval.getFeedbackJson()).doesNotContainKey(VersionCibleeFields.BLOC);
    }

    // ------------------------------------------------------ plafond serveur

    /**
     * Quatre leviers : le tool-schema en demande 3 au plus, le validateur les
     * refuse au-delà — donc rien n'est persisté. Le plafond n'est pas une
     * simple consigne au modèle.
     */
    @Test
    void quatreLeviers_refuses() {
        ProductionSubmission sub = submissionEcrite(TargetLevel.B2);
        AiEvaluation eval = eval(NiveauCecrl.A2, sub.getId());
        stubLlm(sortie(VERSION_CONFORME_45_MOTS, List.of("Un.", "Deux.", "Trois.", "Quatre.")));

        service.enrichir(sub.getId());

        assertThat(eval.getFeedbackJson()).doesNotContainKey(VersionCibleeFields.BLOC);
    }

    /** L'ordre rendu par le modèle est conservé : le premier levier est le plus rentable. */
    @Test
    @SuppressWarnings("unchecked")
    void lOrdreDesLeviersEstConserve() {
        ProductionSubmission sub = submissionEcrite(TargetLevel.B2);
        AiEvaluation eval = eval(NiveauCecrl.A2, sub.getId());
        stubLlm(sortie(VERSION_CONFORME_45_MOTS, List.of("Un.", "Deux.", "Trois.")));

        service.enrichir(sub.getId());

        Map<String, Object> bloc = (Map<String, Object>) eval.getFeedbackJson()
            .get(VersionCibleeFields.BLOC);
        assertThat((List<String>) bloc.get(VersionCibleeFields.CE_QUI_MANQUE))
            .containsExactly("Un.", "Deux.", "Trois.");
    }

    // ------------------------------------------- longueur du texte modele

    /**
     * LE DÉFAUT MESURÉ EN BASE. Les deux seuls blocs {@code version_ciblee}
     * livrés faisaient <b>63 et 64 mots</b> sur une tâche EE T1 plafonnée à
     * <b>60</b> : nous rendions au candidat un texte modèle que notre propre
     * serveur refuse de recevoir
     * ({@code ProductionEvaluationService.validateTextWordCount} : « Votre texte
     * est trop long : 63 mots pour un maximum de 60 »), en l'invitant à s'en
     * inspirer pour rejouer le sujet.
     */
    @Test
    void texteDe63MotsSurUneTacheA60_estRefuse_uneReparation_puisAbandon() {
        ProductionSubmission sub = submissionEcrite(TargetLevel.B1);
        sub.getProductionTask().setMotsMin(30);
        sub.getProductionTask().setMotsMax(60);
        AiEvaluation eval = eval(NiveauCecrl.A2, sub.getId());
        // Le modèle s'entête : même sortie hors bornes aux deux appels.
        stubLlm(sortie(motsFactices(63), List.of("Relier les idées.", "Préciser le lexique.")));

        service.enrichir(sub.getId());

        assertThat(eval.getFeedbackJson()).doesNotContainKey(VersionCibleeFields.BLOC);
        // UNE seule réparation, jamais deux.
        verify(llmClient, times(2)).produire(anyString(), anyString());
        verify(aiEvaluationManager, never()).save(any());
    }

    /** Le message de réparation NOMME la violation : compte obtenu, bornes, opération. */
    @Test
    void laReparationNommeLaViolationEtLOperationAFaire() {
        ProductionSubmission sub = submissionEcrite(TargetLevel.B1);
        sub.getProductionTask().setMotsMin(30);
        sub.getProductionTask().setMotsMax(60);
        eval(NiveauCecrl.A2, sub.getId());
        stubLlm(sortie(motsFactices(63), List.of("Relier les idées.", "Préciser le lexique.")));

        service.enrichir(sub.getId());

        ArgumentCaptor<String> prompts = ArgumentCaptor.forClass(String.class);
        verify(llmClient, times(2)).produire(anyString(), prompts.capture());
        String reparation = prompts.getAllValues().get(1);
        assertThat(reparation)
            .contains("63 mots")
            .contains("30 a 60 mots")
            .contains("RETIRANT au moins 3 mots")
            .contains("Ne coupe PAS le texte en cours de phrase");
    }

    /** Réparée dans les bornes, la version est rendue — et les DEUX appels sont payés. */
    @Test
    @SuppressWarnings("unchecked")
    void texteReparteDansLesBornes_estRendu_etLesDeuxAppelsSontComptes() {
        ProductionSubmission sub = submissionEcrite(TargetLevel.B1);
        sub.getProductionTask().setMotsMin(30);
        sub.getProductionTask().setMotsMax(60);
        AiEvaluation eval = eval(NiveauCecrl.A2, sub.getId());
        List<String> leviers = List.of("Relier les idées.", "Préciser le lexique.");
        when(llmClient.produire(anyString(), anyString()))
            .thenReturn(new VersionCibleeLlmClient.Outcome(sortie(motsFactices(63), leviers),
                300, 200, 1))
            .thenReturn(new VersionCibleeLlmClient.Outcome(sortie(motsFactices(55), leviers),
                400, 150, 2));

        service.enrichir(sub.getId());

        Map<String, Object> bloc = (Map<String, Object>) eval.getFeedbackJson()
            .get(VersionCibleeFields.BLOC);
        assertThat(bloc).isNotNull();
        assertThat(VersionCibleeValidator.compterMots(
            String.valueOf(bloc.get(VersionCibleeFields.TEXTE)))).isEqualTo(55);
        assertThat(eval.getTokensInput()).isEqualTo(700);
        assertThat(eval.getTokensOutput()).isEqualTo(350);
        assertThat(eval.getCoutEstimeCentimes()).isEqualTo(3);
    }

    /** Un modèle TROP COURT est tout aussi irrecevable : le plancher compte aussi. */
    @Test
    void texteSousLePlancherDeLaTache_estRefuse() {
        ProductionSubmission sub = submissionEcrite(TargetLevel.B1);
        AiEvaluation eval = eval(NiveauCecrl.A2, sub.getId());
        stubLlm(sortie(motsFactices(12), List.of("Relier les idées.", "Préciser le lexique.")));

        service.enrichir(sub.getId());

        assertThat(eval.getFeedbackJson()).doesNotContainKey(VersionCibleeFields.BLOC);
        ArgumentCaptor<String> prompts = ArgumentCaptor.forClass(String.class);
        verify(llmClient, times(2)).produire(anyString(), prompts.capture());
        assertThat(prompts.getAllValues().get(1)).contains("AJOUTANT au moins 28 mots");
    }

    /**
     * Les bornes partent DANS le prompt, et ce sont celles de
     * {@code production_tasks} — jamais une valeur écrite en dur.
     */
    @Test
    void lesBornesDeLaTacheSontInjecteesDansLePrompt() {
        ProductionSubmission sub = submissionEcrite(TargetLevel.B1);
        sub.getProductionTask().setMotsMin(30);
        sub.getProductionTask().setMotsMax(60);
        eval(NiveauCecrl.A2, sub.getId());
        stubLlm(sortie(motsFactices(45), List.of("Relier les idées.", "Préciser le lexique.")));

        service.enrichir(sub.getId());

        ArgumentCaptor<String> user = ArgumentCaptor.forClass(String.class);
        verify(llmClient).produire(anyString(), user.capture());
        assertThat(user.getValue())
            .contains("\"longueur_attendue\":\"30 à 60 mots\"")
            .contains("en 30 à 60 mots");
    }

    /**
     * Une sortie structurellement fausse ne vaut PAS un second appel payé : seule
     * la longueur, défaut mécanique, ouvre droit à une réparation.
     */
    @Test
    void sortieStructurellementFausse_aucuneReparationPayee() {
        ProductionSubmission sub = submissionEcrite(TargetLevel.B1);
        AiEvaluation eval = eval(NiveauCecrl.A2, sub.getId());
        stubLlm(sortie(motsFactices(45), List.of("Un seul levier.")));

        service.enrichir(sub.getId());

        assertThat(eval.getFeedbackJson()).doesNotContainKey(VersionCibleeFields.BLOC);
        verify(llmClient, times(1)).produire(anyString(), anyString());
    }

    // ------------------------------------ leviers qui vendent un moyen A2

    /**
     * LE DÉFAUT SIGNALÉ, verbatim, relevé en base sur un bloc
     * {@code niveau_vise: B1}. Le levier tombe, les deux autres suffisent : la
     * version est rendue sans payer de second appel.
     */
    @Test
    @SuppressWarnings("unchecked")
    void levierQuiVendEtEtMaisCommeLaMarcheVersB1_estRetire_sansReparation() {
        ProductionSubmission sub = submissionEcrite(TargetLevel.B1);
        AiEvaluation eval = eval(NiveauCecrl.A2, sub.getId());
        String fautif = "Relier les phrases avec des connecteurs simples : « et », « mais », "
            + "« donc » au lieu de juxtaposer des idées sans lien.";
        stubLlm(sortie(VERSION_CONFORME_45_MOTS, List.of(fautif,
            "Préciser le lexique : « jolie » remplace « belle ».",
            "Introduire une nuance entre l'apparence et le caractère.")));

        service.enrichir(sub.getId());

        Map<String, Object> bloc = (Map<String, Object>) eval.getFeedbackJson()
            .get(VersionCibleeFields.BLOC);
        assertThat((List<String>) bloc.get(VersionCibleeFields.CE_QUI_MANQUE))
            .hasSize(2)
            .noneMatch(levier -> levier.contains("connecteurs simples"));
        verify(llmClient, times(1)).produire(anyString(), anyString());
    }

    /** La purge est COMPTÉE — un filet muet ne peut ni se durcir ni se désarmer. */
    @Test
    void laPurgeEstComptee() {
        ProductionSubmission sub = submissionEcrite(TargetLevel.B1);
        eval(NiveauCecrl.A2, sub.getId());
        stubLlm(sortie(VERSION_CONFORME_45_MOTS, List.of(
            "Relier avec « et » et « mais ».",
            "Préciser le lexique.",
            "Structurer en deux temps.")));

        service.enrichir(sub.getId());

        assertThat(purgeMetrics.compteurs())
            .containsEntry("MARQUEUR_PALIER_LEVIER/entrees", 1L);
    }

    /**
     * FAUX POSITIF À NE JAMAIS PRODUIRE : l'ancre few-shot de notre propre prompt
     * cite « mais » pour dire ce qu'il faut ARRÊTER de faire.
     */
    @Test
    @SuppressWarnings("unchecked")
    void levierQuiCiteUnMarqueurA2PourLeRejeter_estConserve() {
        ProductionSubmission sub = submissionEcrite(TargetLevel.B2);
        AiEvaluation eval = eval(NiveauCecrl.A2, sub.getId());
        stubLlm(sortie(VERSION_CONFORME_45_MOTS, List.of(
            "Annoncer l'objection avant d'y répondre : « On objectera que… ; c'est vrai, "
                + "mais… » au lieu de poser « mais » seul.",
            "Conditionner votre accord : « à condition que la mairie renforce les transports »."
        )));

        service.enrichir(sub.getId());

        Map<String, Object> bloc = (Map<String, Object>) eval.getFeedbackJson()
            .get(VersionCibleeFields.BLOC);
        assertThat((List<String>) bloc.get(VersionCibleeFields.CE_QUI_MANQUE)).hasSize(2);
        assertThat(purgeMetrics.compteurs()).isEmpty();
    }

    /** Viser A2 : « parce que » est alors le BON conseil, rien n'est retiré. */
    @Test
    @SuppressWarnings("unchecked")
    void versLeA2_lesMarqueursA2SontLeBonConseil() {
        ProductionSubmission sub = submissionEcrite(TargetLevel.A2);
        AiEvaluation eval = eval(NiveauCecrl.A1, sub.getId());
        stubLlm(sortie(VERSION_CONFORME_45_MOTS, List.of(
            "Relier vos deux idées avec « parce que ».",
            "Employer « et » pour enchaîner les faits.")));

        service.enrichir(sub.getId());

        Map<String, Object> bloc = (Map<String, Object>) eval.getFeedbackJson()
            .get(VersionCibleeFields.BLOC);
        assertThat((List<String>) bloc.get(VersionCibleeFields.CE_QUI_MANQUE)).hasSize(2);
    }

    /**
     * MOINS DE DEUX LEVIERS APRÈS PURGE : le contrat en impose deux. UNE
     * réparation est payée, et son message NOMME le levier refusé plus
     * l'opération à faire — un réessai non actionnable ne répare rien (mesuré :
     * 0 preuve sur 8, cf. {@code EvaluationRepairPrompt}).
     */
    @Test
    @SuppressWarnings("unchecked")
    void moinsDeDeuxLeviersApresPurge_uneReparationNommeeQuiRepare() {
        ProductionSubmission sub = submissionEcrite(TargetLevel.B1);
        AiEvaluation eval = eval(NiveauCecrl.A2, sub.getId());
        String fautif = "Relier les phrases avec « et » et « mais ».";
        when(llmClient.produire(anyString(), anyString()))
            .thenReturn(new VersionCibleeLlmClient.Outcome(sortie(VERSION_CONFORME_45_MOTS,
                List.of(fautif, "Employer « parce que » pour justifier.", "Préciser le lexique.")),
                300, 200, 1))
            .thenReturn(new VersionCibleeLlmClient.Outcome(sortie(VERSION_CONFORME_45_MOTS,
                List.of("Subordonner : « bien que je travaille tard ».",
                    "Organiser le propos avec « c'est pourquoi ».")), 400, 150, 2));

        service.enrichir(sub.getId());

        ArgumentCaptor<String> prompts = ArgumentCaptor.forClass(String.class);
        verify(llmClient, times(2)).produire(anyString(), prompts.capture());
        assertThat(prompts.getAllValues().get(1))
            .contains("LEVIER(S) REFUSÉ(S)")
            .contains(fautif)
            .contains("niveau B1")
            .contains("attendus dès le niveau A2")
            .contains("Reprends `texte` à l'identique");

        Map<String, Object> bloc = (Map<String, Object>) eval.getFeedbackJson()
            .get(VersionCibleeFields.BLOC);
        assertThat((List<String>) bloc.get(VersionCibleeFields.CE_QUI_MANQUE)).hasSize(2);
        // Les DEUX appels sont payés.
        assertThat(eval.getTokensInput()).isEqualTo(700);
    }

    /** Le modèle s'entête : une seule réparation, puis le bloc est abandonné. */
    @Test
    void leviersToujoursFautifsApresReparation_leBlocEstAbandonne() {
        ProductionSubmission sub = submissionEcrite(TargetLevel.B1);
        AiEvaluation eval = eval(NiveauCecrl.A2, sub.getId());
        stubLlm(sortie(VERSION_CONFORME_45_MOTS, List.of(
            "Relier les phrases avec « et ».",
            "Employer « parce que » pour justifier.",
            "Ajouter « mais » entre les deux idées.")));

        service.enrichir(sub.getId());

        assertThat(eval.getFeedbackJson()).doesNotContainKey(VersionCibleeFields.BLOC);
        verify(llmClient, times(2)).produire(anyString(), anyString());
        verify(aiEvaluationManager, never()).save(any());
    }

    // -------------------------------------------------------------- fixtures

    /** {@code n} mots séparés par une espace — le comptage de la soumission. */
    private static String motsFactices(int n) {
        return ("mot ".repeat(n)).trim();
    }

    private void stubLlm(Map<String, Object> sortie) {
        when(llmClient.produire(anyString(), anyString()))
            .thenReturn(new VersionCibleeLlmClient.Outcome(sortie, 300, 200, 1));
    }

    private static Map<String, Object> sortie(String texte, List<String> leviers) {
        Map<String, Object> out = new LinkedHashMap<>();
        out.put(VersionCibleeFields.TEXTE, texte);
        out.put(VersionCibleeFields.CE_QUI_MANQUE, new ArrayList<>(leviers));
        return out;
    }

    private ProductionTask task(EpreuveType epreuve) {
        ProductionTask t = new ProductionTask();
        t.setId(UUID.randomUUID());
        t.setEpreuve(epreuve);
        t.setTacheNumero((short) 2);
        t.setNiveauCible("B1");
        t.setConsigne("Vous venez d'emménager. Écrivez à un ami.");
        t.setMotsMin(40);
        t.setMotsMax(90);
        return t;
    }

    private ProductionSubmission submissionEcrite(TargetLevel targetLevel) {
        return submission(EpreuveType.TCF_EE, targetLevel, TEXTE_EE);
    }

    private ProductionSubmission submissionOrale(TargetLevel targetLevel) {
        return submission(EpreuveType.TCF_EO, targetLevel, null);
    }

    private ProductionSubmission submission(EpreuveType epreuve, TargetLevel targetLevel,
                                            String texte) {
        ProductionSubmission s = new ProductionSubmission();
        s.setId(UUID.randomUUID());
        s.setProductionTask(task(epreuve));
        s.setStatut(SubmissionStatut.EVALUATED);
        s.setTexteSoumis(texte);
        User user = new User();
        user.setId(UUID.randomUUID());
        user.setTargetLevel(targetLevel);
        s.setUser(user);
        when(submissionManager.findByIdWithTaskAndUser(s.getId())).thenReturn(Optional.of(s));
        return s;
    }

    private AiEvaluation eval(NiveauCecrl niveau, UUID submissionId) {
        AiEvaluation e = new AiEvaluation();
        e.setId(UUID.randomUUID());
        e.setNiveauCecrl(niveau);
        e.setFeedbackJson(new LinkedHashMap<>(Map.of("confiance", "HAUTE")));
        when(aiEvaluationManager.findLatestBySubmissionId(submissionId)).thenReturn(Optional.of(e));
        return e;
    }
}
