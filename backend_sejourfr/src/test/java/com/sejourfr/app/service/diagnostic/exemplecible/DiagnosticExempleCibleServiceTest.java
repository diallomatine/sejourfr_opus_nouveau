package com.sejourfr.app.service.diagnostic.exemplecible;

import com.sejourfr.app.config.DiagnosticProperties;
import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.entity.DiagnosticProductionAnalysis;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.SubmissionStatut;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.exception.AiEvaluationException;
import com.sejourfr.app.manager.DiagnosticProductionAnalysisManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.service.EvaluationPurgeMetrics;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import tools.jackson.databind.ObjectMapper;

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
 * « AVANT / APRES » du diagnostic — SECOND appel LLM, separe de l'analyse.
 *
 * <p>Ce que verrouille cette classe :
 * <ul>
 *   <li>aucun appel n'est emis quand il n'y a rien a viser, ni a l'ORAL — c'est
 *       de l'argent economise, pas seulement un bloc absent ;</li>
 *   <li>un echec de ce second appel ne degrade JAMAIS l'analyse ni la session :
 *       pas d'exception, pas de bloc, l'analyse reste telle quelle ;</li>
 *   <li>la phrase du candidat est DESIGNEE par son numero puis resolue en
 *       sous-chaine originale exacte — le modele ne la recopie jamais ;</li>
 *   <li>un segment introuvable tombe seul, le texte reste servi ;</li>
 *   <li>UNE seule reparation, puis abandon — jamais deux appels payes de plus ;</li>
 *   <li>le serveur pose lui-meme les deux niveaux du bloc.</li>
 * </ul>
 */
class DiagnosticExempleCibleServiceTest {

    private static final UUID SUBMISSION_ID =
        UUID.fromString("11111111-2222-3333-4444-555555555555");

    /** Trois phrases citables. La phrase n°2 est celle des sorties de test. */
    private static final String PRODUCTION =
        "Bonjour, je vous écris pour le poste. "
            + "J'ai travaillé deux ans dans un magasin et j'aime bien le contact avec les clients. "
            + "Je suis libre tout de suite.";
    private static final String PHRASE_2 =
        "J'ai travaillé deux ans dans un magasin et j'aime bien le contact avec les clients.";

    private ProductionSubmissionManager submissionManager;
    private DiagnosticProductionAnalysisManager analysisManager;
    private DiagnosticExempleCibleLlmClient client;
    private DiagnosticProperties props;
    private DiagnosticExempleCibleMetrics metrics;
    private EvaluationPurgeMetrics purgeMetrics;
    private DiagnosticExempleCibleService service;

    @BeforeEach
    void setUp() {
        submissionManager = mock(ProductionSubmissionManager.class);
        analysisManager = mock(DiagnosticProductionAnalysisManager.class);
        client = mock(DiagnosticExempleCibleLlmClient.class);
        when(client.getModelName()).thenReturn("modele-test");
        when(analysisManager.save(any())).thenAnswer(inv -> inv.getArgument(0));

        props = new DiagnosticProperties();
        DiagnosticExempleCibleRubricsProvider rubrics =
            new DiagnosticExempleCibleRubricsProvider(props, new ObjectMapper());
        rubrics.load();
        metrics = new DiagnosticExempleCibleMetrics();
        purgeMetrics = new EvaluationPurgeMetrics();
        service = new DiagnosticExempleCibleService(
            submissionManager, analysisManager, client,
            new DiagnosticExempleCiblePromptBuilder(new ObjectMapper(), rubrics),
            new DiagnosticExempleCibleValidator(), rubrics, metrics, purgeMetrics,
            props, new ProductionEvaluationProperties());
    }

    // ------------------------------------------------------------ fabriques

    private DiagnosticProductionAnalysis contexte(EpreuveType epreuve, NiveauCecrl constate,
                                                  TargetProcedure procedure, TargetLevel declare) {
        ProductionTask task = new ProductionTask();
        task.setId(UUID.randomUUID());
        task.setEpreuve(epreuve);
        task.setConsigne("Vous répondez à une annonce pour un poste de vendeur.");
        task.setMotsMin(100);
        task.setMotsMax(130);
        task.setDiagnosticCode("INITIAL_TCF");
        task.setDiagnosticVersion(1);

        User user = new User();
        user.setId(UUID.randomUUID());
        user.setTargetProcedure(procedure);
        user.setTargetLevel(declare);

        ProductionSubmission submission = new ProductionSubmission();
        submission.setId(SUBMISSION_ID);
        submission.setProductionTask(task);
        submission.setUser(user);
        submission.setDiagnostic(true);
        submission.setStatut(SubmissionStatut.EVALUATED);
        submission.setTexteSoumis(PRODUCTION);

        DiagnosticProductionAnalysis analyse = new DiagnosticProductionAnalysis();
        analyse.setId(UUID.randomUUID());
        analyse.setSubmission(submission);
        analyse.setLevelEstimate(constate);
        analyse.setTokensInput(1000);
        analyse.setTokensOutput(100);
        analyse.setCostMicroUsd(2);
        Map<String, Object> json = new LinkedHashMap<>();
        json.put("level_estimate", constate.name());
        json.put("summary", "Le message est compréhensible.");
        analyse.setAnalysisJson(json);

        when(submissionManager.findByIdWithTaskAndUser(SUBMISSION_ID))
            .thenReturn(Optional.of(submission));
        when(analysisManager.findBySubmissionId(SUBMISSION_ID)).thenReturn(Optional.of(analyse));
        return analyse;
    }

    /** Contexte nominal : ecrit, A2 constate, demarche CR (B1 exige). */
    private DiagnosticProductionAnalysis contexteEcrit() {
        return contexte(EpreuveType.TCF_EE, NiveauCecrl.A2, TargetProcedure.CR, null);
    }

    private static DiagnosticExempleCibleLlmClient.Outcome outcome(Map<String, Object> sortie) {
        return new DiagnosticExempleCibleLlmClient.Outcome(sortie, 800, 200, 3);
    }

    @SuppressWarnings("unchecked")
    private static Map<String, Object> bloc(DiagnosticProductionAnalysis analyse) {
        return (Map<String, Object>) analyse.getAnalysisJson()
            .get(DiagnosticExempleCibleFields.BLOC);
    }

    @SuppressWarnings("unchecked")
    private static List<Map<String, Object>> segments(Map<String, Object> bloc) {
        return (List<Map<String, Object>>) bloc.get(DiagnosticExempleCibleFields.SEGMENTS);
    }

    // ---------------------------------------------------------- cas nominal

    @Test
    void servLeBlocEtResoutLeNumeroEnPhraseDuCandidat() {
        DiagnosticProductionAnalysis analyse = contexteEcrit();
        when(client.produire(anyString(), anyString()))
            .thenReturn(outcome(DiagnosticExempleCibleValidatorTest.sortieValide()));

        service.enrichir(SUBMISSION_ID);

        Map<String, Object> bloc = bloc(analyse);
        assertThat(bloc).isNotNull();
        // L'AVANT est la sous-chaine ORIGINALE EXACTE de la production : le
        // modele a designe « 2 », il n'a rien recopie.
        assertThat(bloc.get(DiagnosticExempleCibleFields.ORIGINAL)).isEqualTo(PHRASE_2);
        assertThat(PRODUCTION).contains(String.valueOf(
            bloc.get(DiagnosticExempleCibleFields.ORIGINAL)));
        // Les DEUX niveaux sont poses par le SERVEUR : le contrat de sortie ne
        // prevoit aucun champ ou le modele pourrait les ecrire.
        assertThat(bloc.get(DiagnosticExempleCibleFields.NIVEAU_VISE)).isEqualTo("B1");
        assertThat(bloc.get(DiagnosticExempleCibleFields.NIVEAU_CONSTATE)).isEqualTo("A2");
        assertThat(segments(bloc)).hasSize(2);
        // L'analyse d'origine est intacte a cote du bloc.
        assertThat(analyse.getAnalysisJson()).containsEntry("summary",
            "Le message est compréhensible.");
        verify(analysisManager).save(analyse);
    }

    /**
     * L'EXTRAIT SERVI EST LA SOUS-CHAINE ORIGINALE EXACTE du texte reecrit.
     *
     * <p>La comparaison neutralise la typographie — un extrait a l'apostrophe
     * courbe est retrouve dans un texte a l'apostrophe droite — puis le passage
     * servi est remplace par la sous-chaine originale. Sans cette resolution, le
     * surlignage du front, une simple recherche de chaine, echouerait en silence.
     */
    @Test
    void chaqueExtraitServiEstUneSousChaineLitteraleDuTexteReecrit() {
        DiagnosticProductionAnalysis analyse = contexteEcrit();
        Map<String, Object> sortie = DiagnosticExempleCibleValidatorTest.sortieValide();
        segmentsBruts(sortie).getFirst().put(
            DiagnosticExempleCibleFields.EXTRAIT, "ce qui m’a appris à");
        when(client.produire(anyString(), anyString())).thenReturn(outcome(sortie));

        service.enrichir(SUBMISSION_ID);

        Map<String, Object> bloc = bloc(analyse);
        String texte = String.valueOf(bloc.get(DiagnosticExempleCibleFields.TEXTE));
        for (Map<String, Object> segment : segments(bloc)) {
            assertThat(texte).contains(
                String.valueOf(segment.get(DiagnosticExempleCibleFields.EXTRAIT)));
        }
    }

    @Test
    void leCoutDuSecondAppelRejointCeluiDeLAnalyse() {
        DiagnosticProductionAnalysis analyse = contexteEcrit();
        when(client.produire(anyString(), anyString()))
            .thenReturn(outcome(DiagnosticExempleCibleValidatorTest.sortieValide()));

        service.enrichir(SUBMISSION_ID);

        assertThat(analyse.getTokensInput()).isEqualTo(1800);
        assertThat(analyse.getTokensOutput()).isEqualTo(300);
        assertThat(analyse.getCostMicroUsd()).isEqualTo(5);
    }

    /** LA DEMARCHE FAIT PLANCHER : NAT exige B2, meme avec un B1 declare. */
    @Test
    void laDemarcheFaitPlancherSurLeNiveauDeclare() {
        contexte(EpreuveType.TCF_EE, NiveauCecrl.A2, TargetProcedure.NAT, TargetLevel.B1);
        when(client.produire(anyString(), anyString()))
            .thenReturn(outcome(DiagnosticExempleCibleValidatorTest.sortieValide()));

        service.enrichir(SUBMISSION_ID);

        ArgumentCaptor<String> user = ArgumentCaptor.forClass(String.class);
        verify(client).produire(anyString(), user.capture());
        assertThat(user.getValue()).contains("\"niveau_vise\":\"B2\"");
        assertThat(user.getValue()).contains("au niveau B2");
        // La production part DECOUPEE, numerotee : c'est ce qui rend la
        // designation possible et la recopie inutile.
        assertThat(user.getValue()).contains("[2] " + PHRASE_2);
    }

    // ------------------------------------------------- quand rien n'est emis

    /** 🛑 ECRIT SEULEMENT : la production orale n'est JAMAIS reecrite. */
    @Test
    void aucunAppelSurUneProductionORALE() {
        DiagnosticProductionAnalysis analyse =
            contexte(EpreuveType.TCF_EO, NiveauCecrl.A2, TargetProcedure.NAT, null);

        service.enrichir(SUBMISSION_ID);

        verifyNoInteractions(client);
        assertThat(bloc(analyse)).isNull();
        verify(analysisManager, never()).save(any());
    }

    @Test
    void aucunAppelQuandLObjectifEstDejaAtteint() {
        DiagnosticProductionAnalysis analyse =
            contexte(EpreuveType.TCF_EE, NiveauCecrl.B2, TargetProcedure.CR, null);

        service.enrichir(SUBMISSION_ID);

        // Pas seulement « pas de bloc » : pas d'appel PAYE.
        verifyNoInteractions(client);
        assertThat(bloc(analyse)).isNull();
    }

    @Test
    void aucunAppelQuandLeNiveauViseEgaleLeNiveauConstate() {
        contexte(EpreuveType.TCF_EE, NiveauCecrl.B1, TargetProcedure.CR, null);

        service.enrichir(SUBMISSION_ID);

        verifyNoInteractions(client);
    }

    @Test
    void aucunAppelQuandLeCoupeCircuitEstOuvert() {
        props.getExempleCible().setEnabled(false);
        contexteEcrit();

        service.enrichir(SUBMISSION_ID);

        verifyNoInteractions(client);
    }

    @Test
    void aucunAppelSansAnalyseDiagnostiquePersistee() {
        contexteEcrit();
        when(analysisManager.findBySubmissionId(SUBMISSION_ID)).thenReturn(Optional.empty());

        service.enrichir(SUBMISSION_ID);

        verifyNoInteractions(client);
    }

    /** Idempotent : un rejeu du pipeline ne repaie jamais l'appel. */
    @Test
    void aucunAppelQuandLeBlocEstDejaPresent() {
        DiagnosticProductionAnalysis analyse = contexteEcrit();
        analyse.getAnalysisJson().put(DiagnosticExempleCibleFields.BLOC, Map.of());

        service.enrichir(SUBMISSION_ID);

        verifyNoInteractions(client);
        verify(analysisManager, never()).save(any());
    }

    @Test
    void aucunAppelSurUneProductionVide() {
        DiagnosticProductionAnalysis analyse = contexteEcrit();
        analyse.getSubmission().setTexteSoumis("   ");

        assertThatCode(() -> service.enrichir(SUBMISSION_ID)).doesNotThrowAnyException();
        verifyNoInteractions(client);
    }

    // --------------------------------------------------------- best-effort

    @Test
    void unEchecDuFournisseurNeDegradeJamaisLeDiagnostic() {
        DiagnosticProductionAnalysis analyse = contexteEcrit();
        when(client.produire(anyString(), anyString()))
            .thenThrow(new AiEvaluationException("fournisseur indisponible"));

        assertThatCode(() -> service.enrichir(SUBMISSION_ID)).doesNotThrowAnyException();

        assertThat(bloc(analyse)).isNull();
        assertThat(analyse.getAnalysisJson()).containsKey("level_estimate");
        assertThat(analyse.getSubmission().getStatut()).isEqualTo(SubmissionStatut.EVALUATED);
        verify(analysisManager, never()).save(any());
    }

    @Test
    void uneSubmissionIntrouvableNeCassePasLePipeline() {
        when(submissionManager.findByIdWithTaskAndUser(SUBMISSION_ID)).thenReturn(Optional.empty());

        assertThatCode(() -> service.enrichir(SUBMISSION_ID)).doesNotThrowAnyException();
        verifyNoInteractions(client);
    }

    // ---------------------------------------------------------- reparation

    /** Un surlignage ne vaut pas un appel paye : le segment tombe, le texte reste. */
    @Test
    void unExtraitIntrouvableRetireLeSegment_sansAppelPayeEtSansPerdreLeTexte() {
        DiagnosticProductionAnalysis analyse = contexteEcrit();
        Map<String, Object> sortie = DiagnosticExempleCibleValidatorTest.sortieValide();
        segmentsBruts(sortie).getFirst().put(
            DiagnosticExempleCibleFields.EXTRAIT, "veuillez agréer mes salutations");
        when(client.produire(anyString(), anyString())).thenReturn(outcome(sortie));

        service.enrichir(SUBMISSION_ID);

        verify(client, times(1)).produire(anyString(), anyString());
        Map<String, Object> bloc = bloc(analyse);
        assertThat(bloc.get(DiagnosticExempleCibleFields.TEXTE)).isNotNull();
        assertThat(segments(bloc)).hasSize(1);
        assertThat(metrics.compteurs()).containsEntry("SEGMENT_RETIRE/EXTRAIT_INTROUVABLE", 1L);
        assertThat(metrics.compteurs().keySet())
            .as("un surlignage ne vaut pas un appel paye")
            .noneMatch(cle -> cle.startsWith("REPARATION/"));
    }

    /** TOUS les segments perdus : le texte est servi seul, sans surlignage. */
    @Test
    void tousLesSegmentsInvalides_leTexteEstServiSansSurlignage() {
        DiagnosticProductionAnalysis analyse = contexteEcrit();
        Map<String, Object> sortie = DiagnosticExempleCibleValidatorTest.sortieValide();
        sortie.put(DiagnosticExempleCibleFields.SEGMENTS, List.of(
            "pas un objet",
            DiagnosticExempleCibleValidatorTest.segment("phrase inventée", "plus précis")));
        when(client.produire(anyString(), anyString())).thenReturn(outcome(sortie));

        service.enrichir(SUBMISSION_ID);

        verify(client, times(1)).produire(anyString(), anyString());
        Map<String, Object> bloc = bloc(analyse);
        assertThat(bloc.get(DiagnosticExempleCibleFields.TEXTE)).isNotNull();
        assertThat(segments(bloc)).isEmpty();
        assertThat(metrics.compteurs())
            .containsEntry("SEGMENT_RETIRE/MALFORME", 1L)
            .containsEntry("SEGMENT_RETIRE/EXTRAIT_INTROUVABLE", 1L);
    }

    @Test
    void unTexteHorsBornesDeclencheUneReparationPuisLAbandon() {
        DiagnosticProductionAnalysis analyse = contexteEcrit();
        Map<String, Object> fautive = DiagnosticExempleCibleValidatorTest.sortieValide();
        fautive.put(DiagnosticExempleCibleFields.TEXTE,
            DiagnosticExempleCibleValidatorTest.texteDe(200));
        when(client.produire(anyString(), anyString())).thenReturn(outcome(fautive));

        service.enrichir(SUBMISSION_ID);

        // UNE seule reparation, jamais deux. On ne tronque JAMAIS un texte modele.
        verify(client, times(2)).produire(anyString(), anyString());
        assertThat(bloc(analyse)).isNull();
        assertThat(metrics.compteurs())
            .containsEntry("REPARATION/LONGUEUR_TEXTE", 1L)
            .containsEntry("BLOC_ABANDONNE/LONGUEUR_TEXTE", 1L);
    }

    @Test
    void unNumeroHorsBornesDeclencheUneReparationPuisLeBlocSiElleRepare() {
        DiagnosticProductionAnalysis analyse = contexteEcrit();
        Map<String, Object> fautive = DiagnosticExempleCibleValidatorTest.sortieValide();
        fautive.put(DiagnosticExempleCibleFields.SEGMENT_NUMERO, 42);
        when(client.produire(anyString(), anyString()))
            .thenReturn(outcome(fautive))
            .thenReturn(outcome(DiagnosticExempleCibleValidatorTest.sortieValide()));

        service.enrichir(SUBMISSION_ID);

        verify(client, times(2)).produire(anyString(), anyString());
        assertThat(bloc(analyse)).isNotNull();
        assertThat(metrics.compteurs()).containsEntry("REPARATION/SEGMENT_NUMERO", 1L);
        // Les deux appels sont payes : oublier le rate sous-estimerait le cout.
        assertThat(analyse.getTokensInput()).isEqualTo(2600);
    }

    /** Le message de reparation NOMME ce qui a ete refuse — un libelle brut ne repare rien. */
    @Test
    void leMessageDeReparationEstActionnable() {
        contexteEcrit();
        Map<String, Object> fautive = DiagnosticExempleCibleValidatorTest.sortieValide();
        fautive.put(DiagnosticExempleCibleFields.SEGMENT_NUMERO, 42);
        when(client.produire(anyString(), anyString())).thenReturn(outcome(fautive));

        service.enrichir(SUBMISSION_ID);

        ArgumentCaptor<String> prompts = ArgumentCaptor.forClass(String.class);
        verify(client, times(2)).produire(anyString(), prompts.capture());
        assertThat(prompts.getAllValues().get(1))
            .contains("TA SORTIE PRÉCÉDENTE A ÉTÉ REJETÉE")
            .contains("Les numéros disponibles vont de 1 à 3");
    }

    @Test
    void uneSortieStructurellementFausseNOuvreDroitAAucunSecondAppel() {
        DiagnosticProductionAnalysis analyse = contexteEcrit();
        Map<String, Object> fautive = DiagnosticExempleCibleValidatorTest.sortieValide();
        fautive.put("bonus", "une cle hors contrat");
        when(client.produire(anyString(), anyString())).thenReturn(outcome(fautive));

        service.enrichir(SUBMISSION_ID);

        verify(client, times(1)).produire(anyString(), anyString());
        assertThat(bloc(analyse)).isNull();
        assertThat(metrics.compteurs()).containsEntry("BLOC_ABANDONNE/STRUCTURE", 1L);
    }

    @Test
    void uneSortieVideEstCompteeAPart() {
        DiagnosticProductionAnalysis analyse = contexteEcrit();
        when(client.produire(anyString(), anyString())).thenReturn(outcome(Map.of()));

        service.enrichir(SUBMISSION_ID);

        verify(client, times(1)).produire(anyString(), anyString());
        assertThat(bloc(analyse)).isNull();
        assertThat(metrics.compteurs()).containsEntry("BLOC_ABANDONNE/SORTIE_HORS_CONTRAT", 1L);
    }

    // ------------------------------------------------------------- filet A2

    /**
     * QUATRIEME surface du meme defaut : une etiquette qui vend « parce que »
     * comme ce qui fait la marche vers le B1. Le segment tombe, le texte reste —
     * une etiquette ne vaut pas la phrase reecrite.
     */
    @Test
    void uneEtiquetteQuiVendUnMoyenA2EstPurgeeEtLeTexteEstServi() {
        DiagnosticProductionAnalysis analyse = contexteEcrit();
        Map<String, Object> sortie = DiagnosticExempleCibleValidatorTest.sortieValide();
        segmentsBruts(sortie).getFirst().put(DiagnosticExempleCibleFields.APPORT, "parce que");
        when(client.produire(anyString(), anyString())).thenReturn(outcome(sortie));

        service.enrichir(SUBMISSION_ID);

        verify(client, times(1)).produire(anyString(), anyString());
        assertThat(segments(bloc(analyse))).hasSize(1);
        assertThat(purgeMetrics.compteurs())
            .containsEntry("MARQUEUR_PALIER_APPORT_DIAGNOSTIC/entrees", 1L);
    }

    @SuppressWarnings("unchecked")
    private static List<Map<String, Object>> segmentsBruts(Map<String, Object> sortie) {
        return (List<Map<String, Object>>) sortie.get(DiagnosticExempleCibleFields.SEGMENTS);
    }
}
