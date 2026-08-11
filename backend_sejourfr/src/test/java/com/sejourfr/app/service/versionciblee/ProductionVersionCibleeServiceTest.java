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
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.exception.AiEvaluationException;
import com.sejourfr.app.manager.AiEvaluationManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.manager.TranscriptionManager;
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
 *   <li>À L'ÉCRIT, l'extrait surligné est une sous-chaîne EXACTE du texte
 *       modèle — accepté, réparé une fois, puis abandonné ;</li>
 *   <li>À L'ORAL, la production n'est jamais réécrite : le numéro de passage est
 *       résolu en texte, l'examinateur n'est pas désignable, une transcription
 *       dégradée n'émet aucun appel, et une reformulation qui ne change que la
 *       forme d'un mot est purgée ;</li>
 *   <li>un échec de ce second appel ne dégrade JAMAIS l'évaluation : pas
 *       d'exception, pas de bloc, l'évaluation reste telle quelle ;</li>
 *   <li>le niveau visé du candidat n'est envoyé qu'à CE prompt-là — le
 *       correcteur ne l'apprend jamais ;</li>
 *   <li>les plafonds sont tenus SERVEUR, pas seulement demandés au modèle ;</li>
 *   <li>le RETOUR ARRIÈRE v1 reste opérationnel.</li>
 * </ul>
 */
class ProductionVersionCibleeServiceTest {

    private static final String TEXTE_EE =
        "Salut Paul ! J'ai déménagé la semaine dernière. Mon logement est près de la gare. "
            + "C'est bien. Viens quand tu veux.";

    /**
     * Version modèle conforme aux bornes de la tâche de test (40 à 90 mots).
     * Depuis que la longueur est un contrôle DUR, un texte de deux mots est
     * refusé — comme il le serait à la soumission.
     */
    private static final String VERSION_CONFORME_45_MOTS = motsFactices(45);

    /** Dialogue oral sain : deux tours candidat, donc deux passages citables. */
    private static final String DIALOGUE_ORAL = """
        Examinateur : Bonjour, vous vouliez me voir ?
        Candidat : Oui bonjour, je viens d'arriver dans l'immeuble et je veux mettre mon vélo en bas.
        Examinateur : Le local est au sous-sol, il faut un badge.
        Candidat : D'accord, et je fais comment pour avoir le badge, c'est vous qui donnez ?
        """;

    /**
     * Extrait RÉEL du 2026-06-28, fenêtre du bug « mot coupé » : le transcripteur
     * découpe les mots. C'est exactement la transcription sur laquelle il ne faut
     * émettre aucun appel.
     */
    private static final String DIALOGUE_DEGRADE = """
        Examinateur : Voici la deuxième partie. Je suis l'employé d'une agence de location \
        de voitures.
        Candidat : Bo njour. Je suis l' emplo yé de l' age nce de location de voi ture.
        Examinateur : Vous souhaitez louer une voiture pour aller voir votre ami Diego.
        Candidat : Oui , bon jour , j'ai mera is lou er une peti te voi ture cita di ne .
        Candidat : Est-ce que vou s en avez de dis po nible là immédiatement.
        Examinateur : Pour combien de jours souhaitez-vous la louer ?
        Candidat : J' ai merais la lou er pour 5 jours s'il vous plaît, c'est pour un
        Candidat : week-end à Perpignan avec ma fami lle et mes deux enfa nts.
        """;

    private ProductionSubmissionManager submissionManager;
    private AiEvaluationManager aiEvaluationManager;
    private TranscriptionManager transcriptionManager;
    private VersionCibleeLlmClient llmClient;
    private EvaluationPurgeMetrics purgeMetrics;
    private ProductionEvaluationProperties props;
    private ProductionVersionCibleeService service;

    @BeforeEach
    void setUp() {
        props = new ProductionEvaluationProperties();
        service = serviceAvec(props);
    }

    /** Le service tel qu'il tourne, sur le contrat déclaré par la configuration. */
    private ProductionVersionCibleeService serviceAvec(ProductionEvaluationProperties props) {
        submissionManager = mock(ProductionSubmissionManager.class);
        aiEvaluationManager = mock(AiEvaluationManager.class);
        transcriptionManager = mock(TranscriptionManager.class);
        llmClient = mock(VersionCibleeLlmClient.class);
        when(llmClient.getModelName()).thenReturn("modele-test");
        when(aiEvaluationManager.save(any())).thenAnswer(inv -> inv.getArgument(0));

        VersionCibleeRubricsProvider rubrics =
            new VersionCibleeRubricsProvider(props, new ObjectMapper());
        rubrics.load();
        purgeMetrics = new EvaluationPurgeMetrics();
        return new ProductionVersionCibleeService(
            submissionManager, aiEvaluationManager, transcriptionManager, llmClient,
            new VersionCibleePromptBuilder(new ObjectMapper(), rubrics),
            new VersionCibleeValidator(rubrics), rubrics, purgeMetrics, props);
    }

    // ------------------------------------------------------ ÉCRIT, cas nominal

    @Test
    @SuppressWarnings("unchecked")
    void ecrit_ajouteLePlanDActionQuandIlResteQuelqueChoseAViser() {
        ProductionSubmission sub = submissionEcrite(TargetLevel.B2);
        AiEvaluation eval = eval(NiveauCecrl.A2, sub.getId());
        String texte = "Je suis heureux de t'annoncer que j'ai enfin emménagé près de la gare, "
            + "la semaine dernière. L'appartement est lumineux et le quartier me plaît beaucoup, "
            + "ce qui me change du précédent. Passe quand tu veux ce week-end : je te ferai "
            + "visiter et nous prendrons un café ensemble.";
        stubLlm(sortieEcrite(texte,
            List.of("ce qui me change du précédent", "Je suis heureux de t'annoncer"),
            levier("Subordonne ton explication", "ce qui me change"),
            levier("Annonce ta nouvelle", "Je suis heureux de")));

        service.enrichir(sub.getId());

        Map<String, Object> bloc = bloc(eval, VersionCibleeFields.BLOC);
        assertThat(bloc.get(VersionCibleeFields.NIVEAU_VISE)).isEqualTo("B2");
        assertThat(bloc.get(VersionCibleeFields.NIVEAU_CONSTATE)).isEqualTo("A2");
        assertThat((List<Object>) bloc.get(VersionCibleeFields.LEVIERS)).hasSize(2);
        Map<String, Object> exemple =
            (Map<String, Object>) bloc.get(VersionCibleeFields.EXEMPLE_CIBLE);
        assertThat(exemple.get(VersionCibleeFields.TEXTE)).isEqualTo(texte);
        assertThat((List<Object>) exemple.get(VersionCibleeFields.SEGMENTS)).hasSize(2);
        assertThat((Map<String, Object>) bloc.get(VersionCibleeFields.A_RETENIR))
            .containsKeys(VersionCibleeFields.FORMULE, VersionCibleeFields.EXPLICATION);
        // Une production ecrite n'est JAMAIS servie sous la forme orale.
        assertThat(bloc).doesNotContainKey(VersionCibleeFields.REFORMULATIONS);
        verify(aiEvaluationManager).save(eval);
    }

    /** Le second appel est payé : son coût rejoint celui de la correction. */
    @Test
    void ecrit_leCoutDuSecondAppelRejointCeluiDeLaCorrection() {
        ProductionSubmission sub = submissionEcrite(TargetLevel.B2);
        AiEvaluation eval = eval(NiveauCecrl.A2, sub.getId());
        eval.setTokensInput(1000);
        eval.setTokensOutput(500);
        eval.setCoutEstimeCentimes(3);
        stubLlm(sortieEcriteConforme());

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
    void ecrit_leNiveauViseNEstEnvoyeQuAuSecondAppel() {
        ProductionSubmission sub = submissionEcrite(TargetLevel.B2);
        eval(NiveauCecrl.A2, sub.getId());
        stubLlm(sortieEcriteConforme());

        service.enrichir(sub.getId());

        ArgumentCaptor<String> user = ArgumentCaptor.forClass(String.class);
        verify(llmClient).produire(anyString(), user.capture(), any());
        assertThat(user.getValue())
            .contains("\"niveau_vise\":\"B2\"")
            .contains("\"niveau_constate\":\"A2\"")
            .contains(TEXTE_EE);
    }

    // -------------------------------------------- ÉCRIT, l'extrait surlignable

    /**
     * LE CONTRÔLE CENTRAL DE L'ÉCRIT. Le front SURLIGNE l'extrait dans le texte
     * modèle : un extrait absent s'afficherait comme une citation du modèle alors
     * qu'il n'en fait pas partie. UNE réparation nommée, puis l'abandon de
     * l'exemple cible — jamais de surlignage faux.
     *
     * <p><b>Et lui SEUL</b> : les leviers et la tournure à retenir ne dépendent
     * d'aucune citation, ils sont servis.
     */
    @Test
    @SuppressWarnings("unchecked")
    void ecrit_extraitIntrouvable_uneReparationNommee_puisSeulLExempleCibleTombe() {
        ProductionSubmission sub = submissionEcrite(TargetLevel.B2);
        AiEvaluation eval = eval(NiveauCecrl.A2, sub.getId());
        stubLlm(sortieEcrite(VERSION_CONFORME_45_MOTS,
            List.of("un passage que le texte ne contient pas", "mot mot"),
            levier("Subordonne ton explication", "bien que"),
            levier("Organise ton propos", "c'est pourquoi")));

        service.enrichir(sub.getId());

        Map<String, Object> bloc = bloc(eval, VersionCibleeFields.BLOC);
        assertThat(bloc).doesNotContainKey(VersionCibleeFields.EXEMPLE_CIBLE);
        assertThat((List<Object>) bloc.get(VersionCibleeFields.LEVIERS)).hasSize(2);
        assertThat((Map<String, Object>) bloc.get(VersionCibleeFields.A_RETENIR))
            .containsKeys(VersionCibleeFields.FORMULE, VersionCibleeFields.EXPLICATION);
        ArgumentCaptor<String> prompts = ArgumentCaptor.forClass(String.class);
        verify(llmClient, times(2)).produire(anyString(), prompts.capture(), any());
        assertThat(prompts.getAllValues().get(1))
            .contains("extrait introuvable")
            .contains("un passage que le texte ne contient pas")
            .contains("COURTS et CONTIGUS");
    }

    /** Réparé, l'extrait est accepté et le bloc rendu — les DEUX appels sont payés. */
    @Test
    @SuppressWarnings("unchecked")
    void ecrit_extraitReparé_leBlocEstRendu() {
        ProductionSubmission sub = submissionEcrite(TargetLevel.B2);
        AiEvaluation eval = eval(NiveauCecrl.A2, sub.getId());
        when(llmClient.produire(anyString(), anyString(), any()))
            .thenReturn(new VersionCibleeLlmClient.Outcome(sortieEcrite(VERSION_CONFORME_45_MOTS,
                List.of("introuvable ici", "mot mot"), levierValide(), levierValide()), 300, 200, 1))
            .thenReturn(new VersionCibleeLlmClient.Outcome(sortieEcriteConforme(), 400, 150, 2));

        service.enrichir(sub.getId());

        Map<String, Object> exemple = (Map<String, Object>)
            bloc(eval, VersionCibleeFields.BLOC).get(VersionCibleeFields.EXEMPLE_CIBLE);
        String texte = String.valueOf(exemple.get(VersionCibleeFields.TEXTE));
        for (Object segment : (List<Object>) exemple.get(VersionCibleeFields.SEGMENTS)) {
            assertThat(texte).contains(
                String.valueOf(((Map<String, Object>) segment).get(VersionCibleeFields.EXTRAIT)));
        }
        assertThat(eval.getTokensInput()).isEqualTo(700);
    }

    // -------------------------------------------------- ÉCRIT, longueur modèle

    /**
     * LE DÉFAUT MESURÉ EN BASE : deux blocs livrés faisaient <b>63 et 64 mots</b>
     * sur une tâche EE plafonnée à <b>60</b> — nous rendions au candidat un texte
     * modèle que notre propre serveur refuse de recevoir.
     */
    @Test
    void ecrit_texteDe63MotsSurUneTacheA60_estRefuse_uneReparation_puisSeulLExempleCibleTombe() {
        ProductionSubmission sub = submissionEcrite(TargetLevel.B1);
        sub.getProductionTask().setMotsMin(30);
        sub.getProductionTask().setMotsMax(60);
        AiEvaluation eval = eval(NiveauCecrl.A2, sub.getId());
        stubLlm(sortieEcrite(motsFactices(63), List.of("mot mot", "mot mot mot"),
            levierValide(), levierValide()));

        service.enrichir(sub.getId());

        // On ne tronque JAMAIS un texte modele : il n'est simplement pas servi.
        assertThat(bloc(eval, VersionCibleeFields.BLOC))
            .doesNotContainKey(VersionCibleeFields.EXEMPLE_CIBLE)
            .containsKeys(VersionCibleeFields.LEVIERS, VersionCibleeFields.A_RETENIR);
        ArgumentCaptor<String> prompts = ArgumentCaptor.forClass(String.class);
        verify(llmClient, times(2)).produire(anyString(), prompts.capture(), any());
        assertThat(prompts.getAllValues().get(1))
            .contains("63 mots")
            .contains("30 a 60 mots")
            .contains("RETIRANT au moins 3 mots")
            .contains("Ne coupe PAS le texte en cours de phrase");
    }

    /** Un modèle TROP COURT est tout aussi irrecevable : le plancher compte aussi. */
    @Test
    void ecrit_texteSousLePlancherDeLaTache_estRefuse() {
        ProductionSubmission sub = submissionEcrite(TargetLevel.B1);
        AiEvaluation eval = eval(NiveauCecrl.A2, sub.getId());
        stubLlm(sortieEcrite(motsFactices(12), List.of("mot mot", "mot mot mot"),
            levierValide(), levierValide()));

        service.enrichir(sub.getId());

        assertThat(bloc(eval, VersionCibleeFields.BLOC))
            .doesNotContainKey(VersionCibleeFields.EXEMPLE_CIBLE);
        ArgumentCaptor<String> prompts = ArgumentCaptor.forClass(String.class);
        verify(llmClient, times(2)).produire(anyString(), prompts.capture(), any());
        assertThat(prompts.getAllValues().get(1)).contains("AJOUTANT au moins 28 mots");
    }

    /**
     * Les bornes partent DANS le prompt, et ce sont celles de
     * {@code production_tasks} — jamais une valeur écrite en dur.
     */
    @Test
    void ecrit_lesBornesDeLaTacheSontInjecteesDansLePrompt() {
        ProductionSubmission sub = submissionEcrite(TargetLevel.B1);
        sub.getProductionTask().setMotsMin(30);
        sub.getProductionTask().setMotsMax(60);
        eval(NiveauCecrl.A2, sub.getId());
        stubLlm(sortieEcrite(motsFactices(45), List.of("mot mot", "mot mot mot"),
            levierValide(), levierValide()));

        service.enrichir(sub.getId());

        ArgumentCaptor<String> user = ArgumentCaptor.forClass(String.class);
        verify(llmClient).produire(anyString(), user.capture(), any());
        assertThat(user.getValue())
            .contains("\"longueur_attendue\":\"30 à 60 mots\"")
            .contains("en 30 à 60 mots");
    }

    // ------------------------------------------------------- ORAL, cas nominal

    /**
     * À L'ORAL, ON NE RÉÉCRIT PAS LA PRODUCTION. Le bloc porte des
     * reformulations, chacune adossée au passage RÉEL du candidat — le numéro est
     * résolu en texte avant persistance, exactement comme
     * {@code resolvePreuveSegments}. Aucun miroir DTO ne transporte un entier.
     */
    @Test
    @SuppressWarnings("unchecked")
    void oral_ajouteDesReformulations_etResoutLeNumeroEnTexte() {
        ProductionSubmission sub = submissionOrale(TargetLevel.B1, DIALOGUE_ORAL);
        AiEvaluation eval = eval(NiveauCecrl.A2, sub.getId());
        stubLlm(sortieOrale(List.of(
                reformulation(1, "Bonjour, puisque je viens d'emménager, serait-il possible de "
                    + "ranger mon vélo au sous-sol ?", "demande plus polie"),
                reformulation(2, "Très bien. Pourriez-vous me dire à qui je dois m'adresser pour "
                    + "obtenir ce badge ?", "question construite")),
            levier("Formule ta demande poliment", "Serait-il possible de"),
            levier("Subordonne ton explication", "puisque je viens")));

        service.enrichir(sub.getId());

        Map<String, Object> bloc = bloc(eval, VersionCibleeFields.BLOC);
        assertThat(bloc.get(VersionCibleeFields.NIVEAU_VISE)).isEqualTo("B1");
        // Aucun texte modele complet : la production orale n'est jamais reecrite.
        assertThat(bloc).doesNotContainKeys(
            VersionCibleeFields.EXEMPLE_CIBLE, VersionCibleeFields.TEXTE);
        List<Map<String, Object>> reformulations =
            (List<Map<String, Object>>) bloc.get(VersionCibleeFields.REFORMULATIONS);
        assertThat(reformulations).hasSize(2);
        assertThat(reformulations.get(0).get(VersionCibleeFields.ORIGINAL).toString())
            .isEqualTo("Oui bonjour, je viens d'arriver dans l'immeuble et je veux mettre mon "
                + "vélo en bas.");
        assertThat(reformulations.get(1).get(VersionCibleeFields.ORIGINAL).toString())
            .startsWith("D'accord, et je fais comment");
        // LE NUMERO NE SURVIT PAS : les fronts lisent une chaine, jamais un entier.
        assertThat(reformulations).allSatisfy(
            r -> assertThat(r).doesNotContainKey(VersionCibleeFields.SEGMENT_NUMERO));
    }

    /**
     * L'EXAMINATEUR N'EST PAS DÉSIGNABLE, par construction : ses tours n'ont
     * aucun numéro. Un numéro hors bornes est mécanique — une réparation nommée,
     * puis l'abandon des seules reformulations.
     */
    @Test
    void oral_numeroHorsBornes_uneReparationNommee_puisSeulesLesReformulationsTombent() {
        ProductionSubmission sub = submissionOrale(TargetLevel.B1, DIALOGUE_ORAL);
        AiEvaluation eval = eval(NiveauCecrl.A2, sub.getId());
        stubLlm(sortieOrale(List.of(
                reformulation(1, "Bonjour, serait-il possible de ranger mon vélo ?", "plus poli"),
                reformulation(7, "Le local se trouve au sous-sol.", "plus clair")),
            levierValide(), levierValide()));

        service.enrichir(sub.getId());

        assertThat(bloc(eval, VersionCibleeFields.BLOC))
            .doesNotContainKey(VersionCibleeFields.REFORMULATIONS)
            .containsKeys(VersionCibleeFields.LEVIERS, VersionCibleeFields.A_RETENIR);
        ArgumentCaptor<String> prompts = ArgumentCaptor.forClass(String.class);
        verify(llmClient, times(2)).produire(anyString(), prompts.capture(), any());
        assertThat(prompts.getAllValues().get(1))
            .contains("numero de segment")
            .contains("la production en compte 2")
            .contains("Les tours de l'examinateur n'ont pas de numéro");
    }

    /**
     * GARDE-FOU N°1, exigence du propriétaire : sur une transcription DÉGRADÉE,
     * aucun bloc oral n'est produit — et surtout, <b>aucun appel n'est payé</b>.
     * Reformuler un texte que la machine a cassé reviendrait à reprocher au
     * candidat nos propres erreurs.
     */
    @Test
    void oral_transcriptionDegradee_aucunAppelEtAucunBloc() {
        ProductionSubmission sub = submissionOrale(TargetLevel.B2, DIALOGUE_DEGRADE);
        AiEvaluation eval = eval(NiveauCecrl.A2, sub.getId());

        service.enrichir(sub.getId());

        verify(llmClient, never()).produire(anyString(), anyString(), any());
        assertThat(eval.getFeedbackJson()).doesNotContainKey(VersionCibleeFields.BLOC);
        verify(aiEvaluationManager, never()).save(any());
    }

    /** Moins de deux passages citables : on ne montre pas un chemin avec un seul. */
    @Test
    void oral_unSeulPassageCitable_aucunAppel() {
        ProductionSubmission sub = submissionOrale(TargetLevel.B1,
            "Examinateur : Bonjour.\nCandidat : Bonjour monsieur.");
        eval(NiveauCecrl.A2, sub.getId());

        service.enrichir(sub.getId());

        verify(llmClient, never()).produire(anyString(), anyString(), any());
    }

    /**
     * GARDE-FOU N°2, exigence du propriétaire : une reformulation dont tout
     * l'apport tient à la forme d'un ou deux mots est PURGÉE. Cas réel : la
     * transcription porte « abit », le candidat avait dit « j'habite ». La règle
     * est celle du volet FORME, partagée via {@code EvaluationOralForme}.
     */
    @Test
    void oral_reformulationQuiNeChangeQuUnMotMalTranscrit_estPurgee() {
        ProductionSubmission sub = submissionOrale(TargetLevel.B1,
            "Candidat : Je abit à Lille depuis trois ans.\n"
                + "Candidat : Et je fais comment pour avoir le badge, c'est vous qui donnez ?");
        AiEvaluation eval = eval(NiveauCecrl.A2, sub.getId());
        Map<String, Object> forme =
            reformulation(1, "Je habite à Lille depuis trois ans.", "forme corrigée");
        when(llmClient.produire(anyString(), anyString(), any()))
            .thenReturn(new VersionCibleeLlmClient.Outcome(sortieOrale(List.of(forme,
                reformulation(2, "Pourriez-vous me dire à qui je dois m'adresser pour obtenir "
                    + "ce badge ?", "question construite")),
                levierValide(), levierValide()), 300, 200, 1))
            .thenReturn(new VersionCibleeLlmClient.Outcome(sortieOrale(List.of(
                reformulation(1, "Cela fait trois ans que je réside à Lille, dans le quartier "
                    + "de Wazemmes.", "phrase construite"),
                reformulation(2, "Pourriez-vous me dire à qui je dois m'adresser pour obtenir "
                    + "ce badge ?", "question construite")),
                levierValide(), levierValide()), 400, 150, 2));

        service.enrichir(sub.getId());

        ArgumentCaptor<String> prompts = ArgumentCaptor.forClass(String.class);
        verify(llmClient, times(2)).produire(anyString(), prompts.capture(), any());
        assertThat(prompts.getAllValues().get(1))
            .contains("que la FORME d'un ou deux mots")
            .contains("TRANSCRIPTION AUTOMATIQUE")
            .contains("la CONSTRUCTION");
        assertThat(bloc(eval, VersionCibleeFields.BLOC))
            .containsKey(VersionCibleeFields.REFORMULATIONS);
    }

    /**
     * La purge est COMPTÉE, à part de celle des leviers — un filet muet ne peut
     * ni se durcir ni se désarmer. Ici deux reformulations survivent, donc aucune
     * réparation n'est payée : c'est la sortie retenue qui est comptée.
     */
    @Test
    @SuppressWarnings("unchecked")
    void oral_laPurgeDeFormeEstComptee() {
        ProductionSubmission sub = submissionOrale(TargetLevel.B1,
            "Candidat : Je abit à Lille depuis trois ans.\n"
                + "Candidat : Et je fais comment pour avoir le badge, c'est vous qui donnez ?\n"
                + "Candidat : Je veux mettre mon vélo en bas parce que je viens d'arriver.");
        AiEvaluation eval = eval(NiveauCecrl.A2, sub.getId());
        stubLlm(sortieOrale(List.of(
                reformulation(1, "Je habite à Lille depuis trois ans.", "forme corrigée"),
                reformulation(2, "Pourriez-vous me dire à qui je dois m'adresser pour obtenir "
                    + "ce badge ?", "question construite"),
                reformulation(3, "Puisque je viens d'arriver, je veux mettre mon vélo en bas.",
                    "subordination")),
            levierValide(), levierValide()));

        service.enrichir(sub.getId());

        assertThat((List<Object>) bloc(eval, VersionCibleeFields.BLOC)
            .get(VersionCibleeFields.REFORMULATIONS)).hasSize(2);
        verify(llmClient, times(1)).produire(anyString(), anyString(), any());
        assertThat(purgeMetrics.compteurs())
            .containsEntry("REFORMULATION_ORALE_FORME/entrees", 1L);
    }

    /**
     * LE DÉFAUT CORRIGÉ, mesuré sur une tâche 1 d'EO en temps réel. Le modèle
     * s'entête : une seule réparation, puis <b>seules les reformulations</b>
     * tombent. Le candidat garde ses leviers et son « à retenir », qui ne
     * dépendent d'aucune citation — la fragilité des citations à l'oral ne doit
     * pas emporter des contenus qui n'en dépendent pas.
     */
    @Test
    @SuppressWarnings("unchecked")
    void oral_reformulationsToujoursDeFormeApresReparation_leResteDuBlocEstServi() {
        ProductionSubmission sub = submissionOrale(TargetLevel.B1,
            "Candidat : Je abit à Lille depuis trois ans.\n"
                + "Candidat : Et je travail dans une agence depuis deux ans.");
        AiEvaluation eval = eval(NiveauCecrl.A2, sub.getId());
        stubLlm(sortieOrale(List.of(
                reformulation(1, "Je habite à Lille depuis trois ans.", "forme"),
                reformulation(2, "Et je travaille dans une agence depuis deux ans.", "forme")),
            levierValide(), levierValide()));

        service.enrichir(sub.getId());

        Map<String, Object> bloc = bloc(eval, VersionCibleeFields.BLOC);
        assertThat(bloc).doesNotContainKey(VersionCibleeFields.REFORMULATIONS);
        assertThat((List<Object>) bloc.get(VersionCibleeFields.LEVIERS)).hasSize(2);
        assertThat((Map<String, Object>) bloc.get(VersionCibleeFields.A_RETENIR))
            .containsKeys(VersionCibleeFields.FORMULE, VersionCibleeFields.EXPLICATION);
        assertThat(bloc.get(VersionCibleeFields.NIVEAU_VISE)).isEqualTo("B1");
        // UNE seule reparation, malgre l'echec : le bloc reste un confort.
        verify(llmClient, times(2)).produire(anyString(), anyString(), any());
        verify(aiEvaluationManager).save(eval);
    }

    /**
     * L'AUTRE MOITIÉ DE LA RÈGLE : les leviers portent le bloc. Purgés sous leur
     * minimum et non réparés, <b>tout</b> est abandonné — un plan d'action sans
     * levier n'a aucun intérêt. Comportement conservé.
     */
    @Test
    void oral_reformulationsEtLeviersPurges_leBlocEstAbandonne() {
        ProductionSubmission sub = submissionOrale(TargetLevel.B1,
            "Candidat : Je abit à Lille depuis trois ans.\n"
                + "Candidat : Et je travail dans une agence depuis deux ans.");
        AiEvaluation eval = eval(NiveauCecrl.A2, sub.getId());
        stubLlm(sortieOrale(List.of(
                reformulation(1, "Je habite à Lille depuis trois ans.", "forme"),
                reformulation(2, "Et je travaille dans une agence depuis deux ans.", "forme")),
            levier("Relie tes deux idées", "et"),
            levier("Justifie ton choix", "parce que")));

        service.enrichir(sub.getId());

        assertThat(eval.getFeedbackJson()).doesNotContainKey(VersionCibleeFields.BLOC);
        // Les DEUX motifs tiennent dans LA seule reparation payee.
        ArgumentCaptor<String> prompts = ArgumentCaptor.forClass(String.class);
        verify(llmClient, times(2)).produire(anyString(), prompts.capture(), any());
        assertThat(prompts.getAllValues().get(1))
            .contains("LEVIER(S) REFUSÉ(S)")
            .contains("REFORMULATION(S) REFUSÉE(S)");
        verify(aiEvaluationManager, never()).save(any());
    }

    /**
     * La tournure à retenir est facultative elle aussi : malformée, elle tombe
     * seule, sans coûter le moindre appel de plus (un défaut de structure n'est
     * pas réparable).
     */
    @Test
    @SuppressWarnings("unchecked")
    void aRetenirMalforme_tombeSeul_sansReparation() {
        ProductionSubmission sub = submissionEcrite(TargetLevel.B2);
        AiEvaluation eval = eval(NiveauCecrl.A2, sub.getId());
        Map<String, Object> sortie = sortieEcriteConforme();
        Map<String, Object> aRetenir = new LinkedHashMap<>();
        aRetenir.put(VersionCibleeFields.FORMULE, "bien que + subjonctif");
        sortie.put(VersionCibleeFields.A_RETENIR, aRetenir);
        stubLlm(sortie);

        service.enrichir(sub.getId());

        Map<String, Object> bloc = bloc(eval, VersionCibleeFields.BLOC);
        assertThat(bloc).doesNotContainKey(VersionCibleeFields.A_RETENIR);
        assertThat((List<Object>) bloc.get(VersionCibleeFields.LEVIERS)).hasSize(2);
        assertThat(bloc).containsKey(VersionCibleeFields.EXEMPLE_CIBLE);
        verify(llmClient, times(1)).produire(anyString(), anyString(), any());
    }

    /**
     * Une reformulation qui ne change AUCUN mot plein est une STRUCTURE pure —
     * subordination, ordre des mots, question construite. C'est exactement ce
     * qu'on veut : elle est conservée.
     */
    @Test
    @SuppressWarnings("unchecked")
    void oral_reformulationQuiNeChangeQueLaStructure_estConservee() {
        ProductionSubmission sub = submissionOrale(TargetLevel.B1,
            "Candidat : Je veux mettre mon vélo en bas parce que je viens d'arriver.\n"
                + "Candidat : Et je fais comment pour avoir le badge, c'est vous qui donnez ?");
        AiEvaluation eval = eval(NiveauCecrl.A2, sub.getId());
        stubLlm(sortieOrale(List.of(
                // Pas un seul mot plein ne change : seule la subordination bouge.
                reformulation(1, "Puisque je viens d'arriver, je veux mettre mon vélo en bas.",
                    "subordination"),
                reformulation(2, "Pourriez-vous me dire à qui je dois m'adresser pour obtenir "
                    + "ce badge ?", "question construite")),
            levierValide(), levierValide()));

        service.enrichir(sub.getId());

        assertThat((List<Object>) bloc(eval, VersionCibleeFields.BLOC)
            .get(VersionCibleeFields.REFORMULATIONS)).hasSize(2);
        verify(llmClient, times(1)).produire(anyString(), anyString(), any());
        assertThat(purgeMetrics.compteurs()).isEmpty();
    }

    // ------------------------------------------------------- rien à produire

    /**
     * Objectif atteint : aucun appel payé, mais le serveur le DIT.
     *
     * <p>Se taire laissait un trou sur l'écran — depuis le retrait de
     * {@code version_amelioree}, la section modèle disparaissait sans un mot et
     * le candidat ne pouvait pas distinguer sa réussite d'une panne.
     */
    @Test
    void niveauViseDejaAtteint_aucunAppelPayeMaisLeServeurLAnnonce() {
        ProductionSubmission sub = submissionEcrite(TargetLevel.B1);
        AiEvaluation eval = eval(NiveauCecrl.B1, sub.getId());

        service.enrichir(sub.getId());

        verify(llmClient, never()).produire(anyString(), anyString(), any());
        Map<String, Object> bloc = bloc(eval, VersionCibleeFields.BLOC_ATTEINT);
        assertThat(bloc.get(VersionCibleeFields.NIVEAU_VISE)).isEqualTo("B1");
        assertThat(bloc.get(VersionCibleeFields.NIVEAU_CONSTATE)).isEqualTo("B1");
        // Les deux blocs sont EXCLUSIFS : jamais un modèle à côté.
        assertThat(eval.getFeedbackJson()).doesNotContainKey(VersionCibleeFields.BLOC);
        verify(aiEvaluationManager).save(eval);
    }

    @Test
    void niveauViseSousLeNiveauConstate_aucunAppelPayeMaisLeServeurLAnnonce() {
        ProductionSubmission sub = submissionEcrite(TargetLevel.A2);
        AiEvaluation eval = eval(NiveauCecrl.B2, sub.getId());

        service.enrichir(sub.getId());

        verify(llmClient, never()).produire(anyString(), anyString(), any());
        Map<String, Object> bloc = bloc(eval, VersionCibleeFields.BLOC_ATTEINT);
        assertThat(bloc.get(VersionCibleeFields.NIVEAU_VISE)).isEqualTo("A2");
        assertThat(bloc.get(VersionCibleeFields.NIVEAU_CONSTATE)).isEqualTo("B2");
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

    @Test
    void sansAucunNiveauVisable_rienNEstProduit() {
        ProductionSubmission sub = submissionEcrite(null);
        sub.getProductionTask().setNiveauCible("A1");
        eval(NiveauCecrl.A2, sub.getId());

        service.enrichir(sub.getId());

        verify(llmClient, never()).produire(anyString(), anyString(), any());
    }

    // ------------------------------------------- la démarche fait PLANCHER

    /**
     * LE DÉFAUT D'ORIGINE, verrouillé : naturalisation (B2 exigé) + un
     * {@code targetLevel} hérité à B1. Sans plancher, le service concluait
     * « objectif atteint » à B1 et ne tirait jamais le candidat vers le B2 dont
     * sa démarche a besoin.
     */
    @Test
    void naturalisationAvecUnNiveauDeclarePlusBas_viseQuandMemeB2() {
        ProductionSubmission sub = submissionEcrite(TargetProcedure.NAT, TargetLevel.B1);
        AiEvaluation eval = eval(NiveauCecrl.B1, sub.getId());
        stubLlm(sortieEcriteConforme());

        service.enrichir(sub.getId());

        assertThat(bloc(eval, VersionCibleeFields.BLOC).get(VersionCibleeFields.NIVEAU_VISE))
            .isEqualTo("B2");
        assertThat(eval.getFeedbackJson()).doesNotContainKey(VersionCibleeFields.BLOC_ATTEINT);
    }

    /** Viser plus haut que sa démarche est un choix légitime : on le respecte. */
    @Test
    void carteDeSejourMaisNiveauDeclarePlusHaut_viseLeNiveauDeclare() {
        ProductionSubmission sub = submissionEcrite(TargetProcedure.CSP, TargetLevel.B2);
        AiEvaluation eval = eval(NiveauCecrl.A2, sub.getId());
        stubLlm(sortieEcriteConforme());

        service.enrichir(sub.getId());

        assertThat(bloc(eval, VersionCibleeFields.BLOC).get(VersionCibleeFields.NIVEAU_VISE))
            .isEqualTo("B2");
    }

    /** Démarche seule, sans niveau déclaré : c'est elle qui fait foi. */
    @Test
    void demarcheSeule_leNiveauExigeFaitFoi() {
        ProductionSubmission sub = submissionEcrite(TargetProcedure.CR, null);
        AiEvaluation eval = eval(NiveauCecrl.A2, sub.getId());
        stubLlm(sortieEcriteConforme());

        service.enrichir(sub.getId());

        assertThat(bloc(eval, VersionCibleeFields.BLOC).get(VersionCibleeFields.NIVEAU_VISE))
            .isEqualTo("B1");
    }

    /** Sans {@code TargetLevel} sur le compte, on retombe sur le niveau cible de la tâche. */
    @Test
    void sansTargetLevelDuCandidat_leNiveauCibleDeLaTacheFaitFoi() {
        ProductionSubmission sub = submissionEcrite(null);
        sub.getProductionTask().setNiveauCible("B1");
        AiEvaluation eval = eval(NiveauCecrl.A2, sub.getId());
        stubLlm(sortieEcriteConforme());

        service.enrichir(sub.getId());

        assertThat(bloc(eval, VersionCibleeFields.BLOC).get(VersionCibleeFields.NIVEAU_VISE))
            .isEqualTo("B1");
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
        when(llmClient.produire(anyString(), anyString(), any()))
            .thenThrow(new AiEvaluationException("DeepSeek version ciblee indisponible"));

        assertThatCode(() -> service.enrichir(sub.getId())).doesNotThrowAnyException();

        assertThat(eval.getFeedbackJson()).doesNotContainKey(VersionCibleeFields.BLOC);
        assertThat(sub.getStatut()).isEqualTo(SubmissionStatut.EVALUATED);
        verify(aiEvaluationManager, never()).save(any());
    }

    /** Même chose à l'ORAL : la nouvelle voie n'affaiblit pas l'invariant. */
    @Test
    void echecDuSecondAppelOral_nEndommagePasLEvaluation() {
        ProductionSubmission sub = submissionOrale(TargetLevel.B1, DIALOGUE_ORAL);
        AiEvaluation eval = eval(NiveauCecrl.A2, sub.getId());
        when(llmClient.produire(anyString(), anyString(), any()))
            .thenThrow(new AiEvaluationException("DeepSeek indisponible"));

        assertThatCode(() -> service.enrichir(sub.getId())).doesNotThrowAnyException();

        assertThat(eval.getFeedbackJson()).doesNotContainKey(VersionCibleeFields.BLOC);
        verify(aiEvaluationManager, never()).save(any());
    }

    /** Même chose sur une panne imprévue : le service est total, par construction. */
    @Test
    void panneImprevue_neRemontePas() {
        ProductionSubmission sub = submissionEcrite(TargetLevel.B2);
        eval(NiveauCecrl.A2, sub.getId());
        when(llmClient.produire(anyString(), anyString(), any()))
            .thenThrow(new IllegalStateException("boom"));

        assertThatCode(() -> service.enrichir(sub.getId())).doesNotThrowAnyException();
    }

    // ------------------------------------------------------ plafonds serveur

    @Test
    void sortieStructurellementFausse_aucuneReparationPayee() {
        ProductionSubmission sub = submissionEcrite(TargetLevel.B1);
        AiEvaluation eval = eval(NiveauCecrl.A2, sub.getId());
        // Un seul levier : le contrat en demande deux au minimum. Defaut de
        // STRUCTURE, donc aucun second appel paye.
        Map<String, Object> sortie = sortieEcriteConforme();
        sortie.put(VersionCibleeFields.LEVIERS, new ArrayList<>(List.of(levierValide())));
        stubLlm(sortie);

        service.enrichir(sub.getId());

        assertThat(eval.getFeedbackJson()).doesNotContainKey(VersionCibleeFields.BLOC);
        verify(llmClient, times(1)).produire(anyString(), anyString(), any());
    }

    @Test
    void cleHorsContrat_refusee() {
        ProductionSubmission sub = submissionEcrite(TargetLevel.B2);
        AiEvaluation eval = eval(NiveauCecrl.A2, sub.getId());
        Map<String, Object> sortie = sortieEcriteConforme();
        sortie.put("note_globale", 14);
        stubLlm(sortie);

        service.enrichir(sub.getId());

        assertThat(eval.getFeedbackJson()).doesNotContainKey(VersionCibleeFields.BLOC);
        verify(llmClient, times(1)).produire(anyString(), anyString(), any());
    }

    /** Une action de quinze mots n'est plus une action : le plafond est SERVEUR. */
    @Test
    void actionBeaucoupTropLongue_refusee() {
        ProductionSubmission sub = submissionEcrite(TargetLevel.B2);
        AiEvaluation eval = eval(NiveauCecrl.A2, sub.getId());
        Map<String, Object> sortie = sortieEcriteConforme();
        sortie.put(VersionCibleeFields.LEVIERS, new ArrayList<>(List.of(
            levier("mot ".repeat(20).trim(), "bien que"), levierValide())));
        stubLlm(sortie);

        service.enrichir(sub.getId());

        assertThat(eval.getFeedbackJson()).doesNotContainKey(VersionCibleeFields.BLOC);
    }

    @Test
    void quatreLeviers_refuses() {
        ProductionSubmission sub = submissionEcrite(TargetLevel.B2);
        AiEvaluation eval = eval(NiveauCecrl.A2, sub.getId());
        Map<String, Object> sortie = sortieEcriteConforme();
        sortie.put(VersionCibleeFields.LEVIERS, new ArrayList<>(List.of(
            levierValide(), levierValide(), levierValide(), levierValide())));
        stubLlm(sortie);

        service.enrichir(sub.getId());

        assertThat(eval.getFeedbackJson()).doesNotContainKey(VersionCibleeFields.BLOC);
    }

    // ------------------------------------ leviers qui vendent un moyen A2

    /**
     * LE DÉFAUT SIGNALÉ, relevé en base sur un bloc {@code niveau_vise: B1}, sous
     * la forme du contrat v2 : l'{@code exemple} est un marqueur A2 nu. Le levier
     * tombe en ENTIER, les deux autres suffisent, aucun second appel n'est payé.
     */
    @Test
    @SuppressWarnings("unchecked")
    void levierQuiVendUnMarqueurA2_estRetire_sansReparation() {
        ProductionSubmission sub = submissionEcrite(TargetLevel.B1);
        AiEvaluation eval = eval(NiveauCecrl.A2, sub.getId());
        Map<String, Object> sortie = sortieEcriteConforme();
        sortie.put(VersionCibleeFields.LEVIERS, new ArrayList<>(List.of(
            levier("Relie tes deux idées", "parce que"),
            levier("Subordonne ton explication", "bien que ce soit"),
            levier("Organise ton propos", "c'est pourquoi"))));
        stubLlm(sortie);

        service.enrichir(sub.getId());

        List<Map<String, Object>> leviers = (List<Map<String, Object>>)
            bloc(eval, VersionCibleeFields.BLOC).get(VersionCibleeFields.LEVIERS);
        assertThat(leviers).hasSize(2)
            .noneMatch(l -> "parce que".equals(l.get(VersionCibleeFields.EXEMPLE)));
        verify(llmClient, times(1)).produire(anyString(), anyString(), any());
        assertThat(purgeMetrics.compteurs()).containsEntry("MARQUEUR_PALIER_LEVIER/entrees", 1L);
    }

    /**
     * MOINS DE DEUX LEVIERS APRÈS PURGE : UNE réparation est payée, et son message
     * NOMME le levier refusé plus l'opération à faire — un réessai non actionnable
     * ne répare rien (mesuré : 0 preuve sur 8).
     */
    @Test
    @SuppressWarnings("unchecked")
    void moinsDeDeuxLeviersApresPurge_uneReparationNommeeQuiRepare() {
        ProductionSubmission sub = submissionEcrite(TargetLevel.B1);
        AiEvaluation eval = eval(NiveauCecrl.A2, sub.getId());
        Map<String, Object> fautive = sortieEcriteConforme();
        fautive.put(VersionCibleeFields.LEVIERS, new ArrayList<>(List.of(
            levier("Relie tes deux idées", "et"),
            levier("Justifie ton choix", "parce que"),
            levier("Organise ton propos", "c'est pourquoi"))));
        when(llmClient.produire(anyString(), anyString(), any()))
            .thenReturn(new VersionCibleeLlmClient.Outcome(fautive, 300, 200, 1))
            .thenReturn(new VersionCibleeLlmClient.Outcome(sortieEcriteConforme(), 400, 150, 2));

        service.enrichir(sub.getId());

        ArgumentCaptor<String> prompts = ArgumentCaptor.forClass(String.class);
        verify(llmClient, times(2)).produire(anyString(), prompts.capture(), any());
        assertThat(prompts.getAllValues().get(1))
            .contains("LEVIER(S) REFUSÉ(S)")
            .contains("Relie tes deux idées — « et »")
            .contains("niveau B1")
            .contains("attendus dès le niveau A2");
        assertThat((List<Object>) bloc(eval, VersionCibleeFields.BLOC)
            .get(VersionCibleeFields.LEVIERS)).hasSize(2);
        assertThat(eval.getTokensInput()).isEqualTo(700);
    }

    /** Viser A2 : « parce que » est alors le BON conseil, rien n'est retiré. */
    @Test
    @SuppressWarnings("unchecked")
    void versLeA2_lesMarqueursA2SontLeBonConseil() {
        ProductionSubmission sub = submissionEcrite(TargetLevel.A2);
        AiEvaluation eval = eval(NiveauCecrl.A1, sub.getId());
        Map<String, Object> sortie = sortieEcriteConforme();
        sortie.put(VersionCibleeFields.LEVIERS, new ArrayList<>(List.of(
            levier("Relie tes deux idées", "parce que"),
            levier("Enchaîne tes faits", "et ensuite"))));
        stubLlm(sortie);

        service.enrichir(sub.getId());

        assertThat((List<Object>) bloc(eval, VersionCibleeFields.BLOC)
            .get(VersionCibleeFields.LEVIERS)).hasSize(2);
    }

    // --------------------------------------------------- RETOUR ARRIÈRE v1

    /**
     * RETOUR ARRIÈRE, sans migration : deux variables d'environnement suffisent.
     * Sous le contrat v1, la sortie reprend sa forme d'origine —
     * {@code texte} + {@code ce_qui_manque} — et l'ORAL ne produit plus rien.
     */
    @Test
    @SuppressWarnings("unchecked")
    void retourArriereV1_lASortieReprendSaFormeDOrigine() {
        ProductionEvaluationProperties v1 = new ProductionEvaluationProperties();
        v1.getVersionCiblee().setRubricsVersion("v1");
        v1.getVersionCiblee().setToolSchemaVersion("v1");
        service = serviceAvec(v1);
        props = v1;

        ProductionSubmission sub = submissionEcrite(TargetLevel.B2);
        AiEvaluation eval = eval(NiveauCecrl.A2, sub.getId());
        Map<String, Object> sortie = new LinkedHashMap<>();
        sortie.put(VersionCibleeFields.TEXTE, VERSION_CONFORME_45_MOTS);
        sortie.put(VersionCibleeFields.CE_QUI_MANQUE,
            new ArrayList<>(List.of("Relier les idées.", "Préciser le lexique.")));
        stubLlm(sortie);

        service.enrichir(sub.getId());

        Map<String, Object> bloc = bloc(eval, VersionCibleeFields.BLOC);
        assertThat(bloc.get(VersionCibleeFields.TEXTE)).isEqualTo(VERSION_CONFORME_45_MOTS);
        assertThat((List<Object>) bloc.get(VersionCibleeFields.CE_QUI_MANQUE)).hasSize(2);
        assertThat(bloc).doesNotContainKeys(VersionCibleeFields.LEVIERS,
            VersionCibleeFields.EXEMPLE_CIBLE, VersionCibleeFields.A_RETENIR);
    }

    /** Sous v1, l'oral ne produit rien : le contrat n'y a qu'une forme, celle d'un texte. */
    @Test
    void retourArriereV1_aLOralRienNEstProduit() {
        ProductionEvaluationProperties v1 = new ProductionEvaluationProperties();
        v1.getVersionCiblee().setRubricsVersion("v1");
        v1.getVersionCiblee().setToolSchemaVersion("v1");
        service = serviceAvec(v1);

        ProductionSubmission sub = submissionOrale(TargetLevel.B2, DIALOGUE_ORAL);
        AiEvaluation eval = eval(NiveauCecrl.A2, sub.getId());

        service.enrichir(sub.getId());

        verify(llmClient, never()).produire(anyString(), anyString(), any());
        assertThat(eval.getFeedbackJson()).doesNotContainKey(VersionCibleeFields.BLOC);
    }

    // -------------------------------------------------------------- fixtures

    /** {@code n} mots séparés par une espace — le comptage de la soumission. */
    private static String motsFactices(int n) {
        return ("mot ".repeat(n)).trim();
    }

    private void stubLlm(Map<String, Object> sortie) {
        when(llmClient.produire(anyString(), anyString(), any()))
            .thenReturn(new VersionCibleeLlmClient.Outcome(sortie, 300, 200, 1));
    }

    private static Map<String, Object> levier(String action, String exemple) {
        Map<String, Object> levier = new LinkedHashMap<>();
        levier.put(VersionCibleeFields.ACTION, action);
        levier.put(VersionCibleeFields.EXEMPLE, exemple);
        return levier;
    }

    private static Map<String, Object> levierValide() {
        return levier("Subordonne ton explication", "bien que ce soit");
    }

    private static Map<String, Object> segment(String extrait, String apport) {
        Map<String, Object> segment = new LinkedHashMap<>();
        segment.put(VersionCibleeFields.EXTRAIT, extrait);
        segment.put(VersionCibleeFields.APPORT, apport);
        return segment;
    }

    private static Map<String, Object> reformulation(int numero, String reformule, String apport) {
        Map<String, Object> reformulation = new LinkedHashMap<>();
        reformulation.put(VersionCibleeFields.SEGMENT_NUMERO, numero);
        reformulation.put(VersionCibleeFields.REFORMULE, reformule);
        reformulation.put(VersionCibleeFields.APPORT, apport);
        return reformulation;
    }

    private static Map<String, Object> aRetenir() {
        Map<String, Object> aRetenir = new LinkedHashMap<>();
        aRetenir.put(VersionCibleeFields.FORMULE, "bien que + subjonctif");
        aRetenir.put(VersionCibleeFields.EXPLICATION,
            "Pour nuancer une opposition sans changer de phrase.");
        return aRetenir;
    }

    private static Map<String, Object> sortieEcrite(String texte, List<String> extraits,
                                                    Map<String, Object>... leviers) {
        Map<String, Object> exemple = new LinkedHashMap<>();
        exemple.put(VersionCibleeFields.TEXTE, texte);
        List<Object> segments = new ArrayList<>();
        for (String extrait : extraits) {
            segments.add(segment(extrait, "plus précis"));
        }
        exemple.put(VersionCibleeFields.SEGMENTS, segments);

        Map<String, Object> sortie = new LinkedHashMap<>();
        sortie.put(VersionCibleeFields.LEVIERS, new ArrayList<Object>(List.of(leviers)));
        sortie.put(VersionCibleeFields.EXEMPLE_CIBLE, exemple);
        sortie.put(VersionCibleeFields.A_RETENIR, aRetenir());
        return sortie;
    }

    /** Sortie écrite valide de bout en bout, bornes de la tâche comprises. */
    private static Map<String, Object> sortieEcriteConforme() {
        return sortieEcrite(VERSION_CONFORME_45_MOTS, List.of("mot mot", "mot mot mot"),
            levierValide(), levier("Organise ton propos", "c'est pourquoi"));
    }

    private static Map<String, Object> sortieOrale(List<Map<String, Object>> reformulations,
                                                   Map<String, Object>... leviers) {
        Map<String, Object> sortie = new LinkedHashMap<>();
        sortie.put(VersionCibleeFields.LEVIERS, new ArrayList<Object>(List.of(leviers)));
        sortie.put(VersionCibleeFields.REFORMULATIONS, new ArrayList<>(reformulations));
        sortie.put(VersionCibleeFields.A_RETENIR, aRetenir());
        return sortie;
    }

    @SuppressWarnings("unchecked")
    private static Map<String, Object> bloc(AiEvaluation eval, String cle) {
        Object bloc = eval.getFeedbackJson().get(cle);
        assertThat(bloc).as("bloc %s", cle).isNotNull();
        return (Map<String, Object>) bloc;
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
        return submission(EpreuveType.TCF_EE, null, targetLevel, TEXTE_EE, null);
    }

    private ProductionSubmission submissionEcrite(TargetProcedure procedure,
                                                  TargetLevel targetLevel) {
        return submission(EpreuveType.TCF_EE, procedure, targetLevel, TEXTE_EE, null);
    }

    private ProductionSubmission submissionOrale(TargetLevel targetLevel, String transcription) {
        return submission(EpreuveType.TCF_EO, null, targetLevel, null, transcription);
    }

    private ProductionSubmission submission(EpreuveType epreuve, TargetProcedure procedure,
                                            TargetLevel targetLevel, String texte,
                                            String transcription) {
        ProductionSubmission s = new ProductionSubmission();
        s.setId(UUID.randomUUID());
        s.setProductionTask(task(epreuve));
        s.setStatut(SubmissionStatut.EVALUATED);
        s.setTexteSoumis(texte);
        User user = new User();
        user.setId(UUID.randomUUID());
        user.setTargetProcedure(procedure);
        user.setTargetLevel(targetLevel);
        s.setUser(user);
        when(submissionManager.findByIdWithTaskAndUser(s.getId())).thenReturn(Optional.of(s));
        when(transcriptionManager.findLatestTexteBySubmissionId(s.getId()))
            .thenReturn(Optional.ofNullable(transcription));
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
