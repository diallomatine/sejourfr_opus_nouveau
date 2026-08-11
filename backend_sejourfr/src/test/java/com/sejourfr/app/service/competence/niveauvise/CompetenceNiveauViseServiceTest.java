package com.sejourfr.app.service.competence.niveauvise;

import com.sejourfr.app.config.CompetenceProperties;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.SkillPrompt;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSkillAttempt;
import com.sejourfr.app.enums.SkillAttemptStatut;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.exception.AiEvaluationException;
import com.sejourfr.app.manager.UserSkillAttemptManager;
import com.sejourfr.app.service.EvaluationPurgeMetrics;
import com.sejourfr.app.service.competence.CompetenceAnalysisFields;
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
 * « Pour viser X » — SECOND appel LLM du module Competences, separe de l'analyse.
 *
 * <p>Ce que verrouille cette classe :
 * <ul>
 *   <li>aucun appel n'est emis quand il n'y a rien a viser — c'est de l'argent
 *       economise, pas seulement un bloc absent ;</li>
 *   <li>un echec de ce second appel ne degrade JAMAIS l'analyse : pas
 *       d'exception, pas de bloc, la tentative reste telle quelle ;</li>
 *   <li>le niveau vise n'est envoye qu'a CE prompt-la ;</li>
 *   <li>UNE seule reparation, puis abandon — jamais deux appels payes de plus ;</li>
 *   <li>le serveur pose lui-meme les deux niveaux du bloc.</li>
 * </ul>
 */
class CompetenceNiveauViseServiceTest {

    private static final UUID ATTEMPT_ID = UUID.fromString("aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee");

    private UserSkillAttemptManager attemptManager;
    private CompetenceNiveauViseLlmClient client;
    private CompetenceProperties props;
    private CompetenceNiveauViseMetrics metrics;
    private CompetenceNiveauViseService service;

    @BeforeEach
    void setUp() {
        attemptManager = mock(UserSkillAttemptManager.class);
        client = mock(CompetenceNiveauViseLlmClient.class);
        when(client.getModelName()).thenReturn("modele-test");
        when(attemptManager.save(any())).thenAnswer(inv -> inv.getArgument(0));

        props = new CompetenceProperties();
        CompetenceNiveauViseRubricsProvider rubrics =
            new CompetenceNiveauViseRubricsProvider(props, new ObjectMapper());
        rubrics.load();
        metrics = new CompetenceNiveauViseMetrics();
        service = new CompetenceNiveauViseService(
            attemptManager, client,
            new CompetenceNiveauVisePromptBuilder(new ObjectMapper(), rubrics),
            new CompetenceNiveauViseValidator(rubrics), rubrics,
            new EvaluationPurgeMetrics(), metrics, props);
    }

    // ------------------------------------------------------------ fabriques

    private UserSkillAttempt attempt(String niveauConstate, TargetProcedure procedure,
                                     TargetLevel declare) {
        Skill skill = new Skill();
        skill.setId(UUID.randomUUID());
        skill.setSection(SkillSection.EE);
        skill.setTaskCode(SkillTaskCode.EE1);
        skill.setCode("EE1-C2");
        skill.setTitle("Formuler une demande");
        skill.setTargetLevel("A2");

        SkillPrompt prompt = new SkillPrompt();
        prompt.setId(UUID.randomUUID());
        prompt.setSkill(skill);
        prompt.setSection(SkillSection.EE);
        prompt.setCode("EE1-C2-S1");
        prompt.setContext("Vous ecrivez au secretariat d'un cabinet medical.");
        prompt.setInstruction("Demandez un rendez-vous.");
        prompt.setUniqueCriterion("Formuler une demande claire et polie.");

        User user = new User();
        user.setId(UUID.randomUUID());
        user.setTargetProcedure(procedure);
        user.setTargetLevel(declare);

        UserSkillAttempt attempt = new UserSkillAttempt();
        attempt.setId(ATTEMPT_ID);
        attempt.setUser(user);
        attempt.setSkillPrompt(prompt);
        attempt.setStatut(SkillAttemptStatut.EVALUATED);
        attempt.setWrittenProduction("Bonjour, je veux un rendez-vous jeudi. Merci.");
        attempt.setTokensInput(1000);
        attempt.setTokensOutput(100);
        attempt.setCoutEstimeCentimes(2);

        Map<String, Object> analyse = new LinkedHashMap<>();
        analyse.put(CompetenceAnalysisFields.STATUS, "PARTIAL");
        if (niveauConstate != null) {
            analyse.put(CompetenceAnalysisFields.LEVEL_REACHED, niveauConstate);
        }
        analyse.put(CompetenceAnalysisFields.VERDICT, "La demande est la, mais elle est abrupte.");
        analyse.put(CompetenceAnalysisFields.STRENGTH_TAG, "Demande claire");
        analyse.put(CompetenceAnalysisFields.FOCUS_TAG, "Plus de politesse");
        attempt.setAnalysisJson(analyse);

        when(attemptManager.findByIdWithPrompt(ATTEMPT_ID)).thenReturn(Optional.of(attempt));
        return attempt;
    }

    private static CompetenceNiveauViseLlmClient.Outcome outcome(Map<String, Object> sortie) {
        return new CompetenceNiveauViseLlmClient.Outcome(sortie, 800, 200, 3);
    }

    @SuppressWarnings("unchecked")
    private static Map<String, Object> bloc(UserSkillAttempt attempt) {
        return (Map<String, Object>) attempt.getAnalysisJson()
            .get(CompetenceAnalysisFields.BLOC_POUR_VISER);
    }

    // ---------------------------------------------------------- cas nominal

    @Test
    @SuppressWarnings("unchecked")
    void ajouteLeBlocQuandIlResteQuelqueChoseAViser() {
        UserSkillAttempt attempt = attempt("A2", TargetProcedure.CR, null);
        when(client.produire(anyString(), anyString()))
            .thenReturn(outcome(CompetenceNiveauViseValidatorTest.sortieValide()));

        service.enrichir(ATTEMPT_ID);

        Map<String, Object> bloc = bloc(attempt);
        assertThat(bloc).isNotNull();
        // Les DEUX niveaux sont poses par le SERVEUR : le contrat de sortie ne
        // prevoit aucun champ ou le modele pourrait les ecrire.
        assertThat(bloc.get(CompetenceNiveauViseFields.NIVEAU_VISE)).isEqualTo("B1");
        assertThat(bloc.get(CompetenceNiveauViseFields.NIVEAU_CONSTATE)).isEqualTo("A2");
        assertThat((List<?>) bloc.get(CompetenceNiveauViseFields.LEVIERS)).hasSize(2);
        assertThat(bloc.get(CompetenceNiveauViseFields.EXEMPLE_CIBLE)).isNotNull();
        assertThat(bloc.get(CompetenceNiveauViseFields.A_RETENIR)).isNotNull();
        // L'analyse d'origine est intacte a cote du bloc.
        assertThat(attempt.getAnalysisJson())
            .containsEntry(CompetenceAnalysisFields.FOCUS_TAG, "Plus de politesse");
        verify(attemptManager).save(attempt);
    }

    /**
     * L'EXTRAIT SERVI EST LA SOUS-CHAINE ORIGINALE EXACTE du texte modele.
     *
     * <p>Le validateur compare desormais apres neutralisation typographique — un
     * extrait a l'apostrophe courbe est retrouve dans un texte a l'apostrophe
     * droite. Sans cette resolution, le front recevrait l'extrait tel que rendu
     * par le modele et son surlignage, une simple recherche de chaine, echouerait
     * en silence.
     */
    @Test
    @SuppressWarnings("unchecked")
    void lExtraitPersisteEstUneSousChaineLitteraleDuTexteModele() {
        UserSkillAttempt attempt = attempt("A2", TargetProcedure.CR, null);
        Map<String, Object> sortie = CompetenceNiveauViseValidatorTest.sortieValide();
        Map<String, Object> exemple =
            (Map<String, Object>) sortie.get(CompetenceNiveauViseFields.EXEMPLE_CIBLE);
        List<Map<String, Object>> segments =
            (List<Map<String, Object>>) exemple.get(CompetenceNiveauViseFields.SEGMENTS);
        segments.get(0).put(CompetenceNiveauViseFields.EXTRAIT,
            "serait-il possible d’obtenir un rendez-vous");
        when(client.produire(anyString(), anyString())).thenReturn(outcome(sortie));

        service.enrichir(ATTEMPT_ID);

        Map<String, Object> servi = (Map<String, Object>)
            bloc(attempt).get(CompetenceNiveauViseFields.EXEMPLE_CIBLE);
        String texte = String.valueOf(servi.get(CompetenceNiveauViseFields.TEXTE));
        for (Map<String, Object> segment
            : (List<Map<String, Object>>) servi.get(CompetenceNiveauViseFields.SEGMENTS)) {
            assertThat(texte).contains(
                String.valueOf(segment.get(CompetenceNiveauViseFields.EXTRAIT)));
        }
    }

    @Test
    void leCoutDuSecondAppelRejointCeluiDeLAnalyse() {
        UserSkillAttempt attempt = attempt("A2", TargetProcedure.CR, null);
        when(client.produire(anyString(), anyString()))
            .thenReturn(outcome(CompetenceNiveauViseValidatorTest.sortieValide()));

        service.enrichir(ATTEMPT_ID);

        // Sous-estimer le cout sur les cas les plus chers rendrait le suivi faux
        // la ou il sert.
        assertThat(attempt.getTokensInput()).isEqualTo(1800);
        assertThat(attempt.getTokensOutput()).isEqualTo(300);
        assertThat(attempt.getCoutEstimeCentimes()).isEqualTo(5);
    }

    /** LA DEMARCHE FAIT PLANCHER : NAT exige B2, meme avec un B1 declare. */
    @Test
    void laDemarcheFaitPlancherSurLeNiveauDeclare() {
        attempt("A2", TargetProcedure.NAT, TargetLevel.B1);
        when(client.produire(anyString(), anyString()))
            .thenReturn(outcome(CompetenceNiveauViseValidatorTest.sortieValide()));

        service.enrichir(ATTEMPT_ID);

        ArgumentCaptor<String> user = ArgumentCaptor.forClass(String.class);
        verify(client).produire(anyString(), user.capture());
        assertThat(user.getValue()).contains("\"niveau_vise\":\"B2\"");
        assertThat(user.getValue()).contains("le niveau B2");
    }

    // ------------------------------------------------- quand rien n'est emis

    @Test
    void aucunAppelQuandLObjectifEstDejaAtteint() {
        UserSkillAttempt attempt = attempt("B2", TargetProcedure.CR, null);

        service.enrichir(ATTEMPT_ID);

        // Pas seulement « pas de bloc » : pas d'appel PAYE. Montrer une version
        // B1 a quelqu'un qui ecrit deja du B2 serait un contresens, et le payer
        // le serait deux fois.
        verifyNoInteractions(client);
        assertThat(bloc(attempt)).isNull();
        verify(attemptManager, never()).save(any());
    }

    @Test
    void aucunAppelQuandLeNiveauViseEgaleLeNiveauConstate() {
        attempt("B1", TargetProcedure.CR, null);

        service.enrichir(ATTEMPT_ID);

        verifyNoInteractions(client);
    }

    @Test
    void aucunAppelSurUneAnalyseAncienneSansNiveau() {
        // Contrat v1/v2 : aucun level_reached persiste, rien a comparer.
        attempt(null, TargetProcedure.NAT, null);

        service.enrichir(ATTEMPT_ID);

        verifyNoInteractions(client);
    }

    @Test
    void aucunAppelQuandLeCoupeCircuitEstOuvert() {
        props.getNiveauVise().setEnabled(false);
        attempt("A2", TargetProcedure.NAT, null);

        service.enrichir(ATTEMPT_ID);

        verifyNoInteractions(client);
    }

    @Test
    void aucunAppelSansProduction() {
        UserSkillAttempt attempt = attempt("A2", TargetProcedure.NAT, null);
        attempt.setWrittenProduction(null);

        service.enrichir(ATTEMPT_ID);

        verifyNoInteractions(client);
    }

    // ------------------------------------------------------- best-effort

    @Test
    void unEchecDuFournisseurNeDegradeJamaisLAnalyse() {
        UserSkillAttempt attempt = attempt("A2", TargetProcedure.NAT, null);
        when(client.produire(anyString(), anyString()))
            .thenThrow(new AiEvaluationException("fournisseur indisponible"));

        assertThatCode(() -> service.enrichir(ATTEMPT_ID)).doesNotThrowAnyException();

        assertThat(bloc(attempt)).isNull();
        assertThat(attempt.getStatut()).isEqualTo(SkillAttemptStatut.EVALUATED);
        verify(attemptManager, never()).save(any());
    }

    @Test
    void uneTentativeIntrouvableNeCassePasLePipeline() {
        when(attemptManager.findByIdWithPrompt(ATTEMPT_ID)).thenReturn(Optional.empty());

        assertThatCode(() -> service.enrichir(ATTEMPT_ID)).doesNotThrowAnyException();
        verifyNoInteractions(client);
    }

    // --------------------------------------------------------- reparation

    /**
     * ⚠️ REMPLACE trois gels de l'ancienne regle (« un extrait introuvable
     * declenche une reparation », « son message nomme l'extrait », « il abandonne
     * le bloc apres reparation »). Le surlignage ne vaut plus un appel paye : le
     * segment tombe, le texte reste.
     */
    @Test
    @SuppressWarnings("unchecked")
    void unExtraitIntrouvableRetireLeSegment_sansAppelPayeEtSansPerdreLeTexte() {
        UserSkillAttempt attempt = attempt("A2", TargetProcedure.NAT, null);
        Map<String, Object> sortie = CompetenceNiveauViseValidatorTest.sortieValide();
        segments(sortie).get(0).put(
            CompetenceNiveauViseFields.EXTRAIT, "veuillez agreer mes salutations");
        when(client.produire(anyString(), anyString())).thenReturn(outcome(sortie));

        service.enrichir(ATTEMPT_ID);

        verify(client, times(1)).produire(anyString(), anyString());
        Map<String, Object> servi = (Map<String, Object>)
            bloc(attempt).get(CompetenceNiveauViseFields.EXEMPLE_CIBLE);
        assertThat(servi.get(CompetenceNiveauViseFields.TEXTE)).isNotNull();
        assertThat((List<?>) servi.get(CompetenceNiveauViseFields.SEGMENTS)).hasSize(1);
        assertThat(metrics.compteurs())
            .containsEntry("SEGMENT_RETIRE/EXTRAIT_INTROUVABLE", 1L);
        assertThat(metrics.compteurs().keySet())
            .as("un surlignage ne vaut pas un appel paye")
            .noneMatch(cle -> cle.startsWith("REPARATION/"));
    }

    /** TOUS les segments perdus : le texte est servi seul, sans surlignage. */
    @Test
    @SuppressWarnings("unchecked")
    void tousLesSegmentsInvalides_leTexteEstServiSansSurlignage() {
        UserSkillAttempt attempt = attempt("A2", TargetProcedure.NAT, null);
        Map<String, Object> sortie = CompetenceNiveauViseValidatorTest.sortieValide();
        Map<String, Object> exemple =
            (Map<String, Object>) sortie.get(CompetenceNiveauViseFields.EXEMPLE_CIBLE);
        exemple.put(CompetenceNiveauViseFields.SEGMENTS, List.of(
            "pas un objet",
            Map.of(CompetenceNiveauViseFields.EXTRAIT, "phrase inventee",
                CompetenceNiveauViseFields.APPORT, "plus poli")));
        when(client.produire(anyString(), anyString())).thenReturn(outcome(sortie));

        service.enrichir(ATTEMPT_ID);

        verify(client, times(1)).produire(anyString(), anyString());
        Map<String, Object> servi = (Map<String, Object>)
            bloc(attempt).get(CompetenceNiveauViseFields.EXEMPLE_CIBLE);
        assertThat(servi.get(CompetenceNiveauViseFields.TEXTE)).isNotNull();
        assertThat((List<?>) servi.get(CompetenceNiveauViseFields.SEGMENTS)).isEmpty();
        assertThat(metrics.compteurs())
            .containsEntry("SEGMENT_RETIRE/MALFORME", 1L)
            .containsEntry("SEGMENT_RETIRE/EXTRAIT_INTROUVABLE", 1L);
    }

    /** Le TEXTE, lui, tient toujours la section : sans lui, plus de bloc du tout. */
    @Test
    void unTexteModeleFautifFaitTomberLaSection() {
        UserSkillAttempt attempt = attempt("A2", TargetProcedure.NAT, null);
        Map<String, Object> fautive = CompetenceNiveauViseValidatorTest.sortieValide();
        exempleCible(fautive).put(CompetenceNiveauViseFields.TEXTE, "   ");
        when(client.produire(anyString(), anyString())).thenReturn(outcome(fautive));

        service.enrichir(ATTEMPT_ID);

        verify(client, times(1)).produire(anyString(), anyString());
        assertThat(bloc(attempt)).isNull();
        assertThat(metrics.compteurs()).containsEntry("BLOC_ABANDONNE/STRUCTURE", 1L);
    }

    @Test
    void uneSortieStructurellementFausseNOuvreDroitAAucunSecondAppel() {
        UserSkillAttempt attempt = attempt("A2", TargetProcedure.NAT, null);
        Map<String, Object> fautive = CompetenceNiveauViseValidatorTest.sortieValide();
        fautive.put("bonus", "une cle hors contrat");
        when(client.produire(anyString(), anyString())).thenReturn(outcome(fautive));

        service.enrichir(ATTEMPT_ID);

        verify(client, times(1)).produire(anyString(), anyString());
        assertThat(bloc(attempt)).isNull();
        assertThat(metrics.compteurs()).containsEntry("BLOC_ABANDONNE/STRUCTURE", 1L);
    }

    @Test
    void uneSortieVideEstCompteeAPart() {
        UserSkillAttempt attempt = attempt("A2", TargetProcedure.NAT, null);
        when(client.produire(anyString(), anyString())).thenReturn(outcome(Map.of()));

        service.enrichir(ATTEMPT_ID);

        assertThat(bloc(attempt)).isNull();
        assertThat(metrics.compteurs()).containsEntry("BLOC_ABANDONNE/SORTIE_HORS_CONTRAT", 1L);
    }

    // ------------------------------------------------------- filet A2

    @Test
    @SuppressWarnings("unchecked")
    void unLevierQuiVendUnMoyenA2EstPurgeEtLeResteEstServi() {
        UserSkillAttempt attempt = attempt("A2", TargetProcedure.NAT, null);
        Map<String, Object> sortie = CompetenceNiveauViseValidatorTest.sortieValide();
        List<Map<String, Object>> leviers =
            (List<Map<String, Object>>) sortie.get(CompetenceNiveauViseFields.LEVIERS);
        leviers.add(Map.of(
            CompetenceNiveauViseFields.ACTION, "Relie tes idées",
            CompetenceNiveauViseFields.EXEMPLE, "parce que"));
        when(client.produire(anyString(), anyString())).thenReturn(outcome(sortie));

        service.enrichir(ATTEMPT_ID);

        // Il reste deux leviers valides : pas de reparation, le bloc est servi.
        verify(client, times(1)).produire(anyString(), anyString());
        assertThat((List<?>) bloc(attempt).get(CompetenceNiveauViseFields.LEVIERS)).hasSize(2);
    }

    @Test
    void moinsDeDeuxLeviersApresPurgeDeclencheUneReparationPuisLAbandon() {
        UserSkillAttempt attempt = attempt("A2", TargetProcedure.NAT, null);
        Map<String, Object> fautive = CompetenceNiveauViseValidatorTest.sortieValide();
        fautive.put(CompetenceNiveauViseFields.LEVIERS, List.of(
            Map.of(CompetenceNiveauViseFields.ACTION, "Relie tes idées",
                CompetenceNiveauViseFields.EXEMPLE, "parce que"),
            Map.of(CompetenceNiveauViseFields.ACTION, "Enchaîne tes phrases",
                CompetenceNiveauViseFields.EXEMPLE, "mais")));
        when(client.produire(anyString(), anyString())).thenReturn(outcome(fautive));

        service.enrichir(ATTEMPT_ID);

        verify(client, times(2)).produire(anyString(), anyString());
        assertThat(bloc(attempt)).isNull();
        // UN appel paye, et il est compte : c'est le seul motif qui en vaut un.
        assertThat(metrics.compteurs())
            .containsEntry("REPARATION/PURGE_LEVIERS", 1L)
            .containsEntry("BLOC_ABANDONNE/PURGE_LEVIERS", 1L);
    }

    @SuppressWarnings("unchecked")
    private static Map<String, Object> exempleCible(Map<String, Object> sortie) {
        return (Map<String, Object>) sortie.get(CompetenceNiveauViseFields.EXEMPLE_CIBLE);
    }

    @SuppressWarnings("unchecked")
    private static List<Map<String, Object>> segments(Map<String, Object> sortie) {
        return (List<Map<String, Object>>)
            exempleCible(sortie).get(CompetenceNiveauViseFields.SEGMENTS);
    }
}
