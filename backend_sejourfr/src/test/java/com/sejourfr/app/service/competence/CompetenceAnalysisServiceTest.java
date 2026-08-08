package com.sejourfr.app.service.competence;

import com.sejourfr.app.config.CompetenceProperties;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.SkillPrompt;
import com.sejourfr.app.entity.UserSkillAttempt;
import com.sejourfr.app.enums.SkillAttemptStatut;
import com.sejourfr.app.enums.SkillCriterionStatus;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.exception.AiEvaluationException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.UserSkillAttemptManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import tools.jackson.databind.ObjectMapper;

import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class CompetenceAnalysisServiceTest {

    private static final UUID ATTEMPT_ID = UUID.fromString("11111111-2222-3333-4444-555555555555");
    /** Duree de l'enregistrement : ne doit apparaitre dans aucun prompt. */
    private static final int DUREE_ORALE_SEC = 137;

    private UserSkillAttemptManager attemptManager;
    private CompetenceAnalysisLlmClient client;
    private CompetenceAnalysisServiceImpl service;

    @BeforeEach
    void setUp() {
        attemptManager = mock(UserSkillAttemptManager.class);
        client = mock(CompetenceAnalysisLlmClient.class);
        when(client.getModelName()).thenReturn("deepseek-v4-flash");
        when(client.getToolSchemaVersion()).thenReturn("v2");

        CompetenceRubricsProvider rubrics =
            new CompetenceRubricsProvider(new CompetenceProperties(), new ObjectMapper());
        rubrics.load();
        CompetenceAnalysisPromptBuilder promptBuilder =
            new CompetenceAnalysisPromptBuilder(new ObjectMapper(), rubrics);
        CompetenceAnalysisValidator validator = new CompetenceAnalysisValidator(rubrics);

        service = new CompetenceAnalysisServiceImpl(
            attemptManager, promptBuilder, client, validator, rubrics);
    }

    // --- fabriques ---------------------------------------------------------

    private static Skill skill(SkillSection section, SkillTaskCode taskCode) {
        Skill skill = new Skill();
        skill.setId(UUID.randomUUID());
        skill.setSection(section);
        skill.setTaskCode(taskCode);
        skill.setCode(taskCode.name() + "-C3");
        skill.setTitle("Developper une reponse avec une precision");
        skill.setDescription("Ajouter un detail utile a une reponse personnelle.");
        skill.setTargetLevel("A2");
        return skill;
    }

    private static UserSkillAttempt attempt(SkillSection section) {
        Skill skill = skill(section, section == SkillSection.EO ? SkillTaskCode.EO1 : SkillTaskCode.EE1);

        SkillPrompt prompt = new SkillPrompt();
        prompt.setId(UUID.randomUUID());
        prompt.setSkill(skill);
        prompt.setSection(section);
        prompt.setCode(skill.getCode() + "-S1");
        prompt.setTitle("Le week-end");
        prompt.setContext("L'examinateur vous demande ce que vous faites le week-end.");
        prompt.setInstruction("Repondez a la question.");
        prompt.setUniqueCriterion("Donner une activite et au moins une precision.");

        UserSkillAttempt attempt = new UserSkillAttempt();
        attempt.setId(ATTEMPT_ID);
        attempt.setSkillPrompt(prompt);
        attempt.setStatut(SkillAttemptStatut.EVALUATING);
        attempt.setAnalysisRequested(true);
        if (section == SkillSection.EO) {
            attempt.setTranscript("J'aime le sport.");
            attempt.setAudioDurationSec(DUREE_ORALE_SEC);
        } else {
            attempt.setWrittenProduction("La semaine derniere, je suis alle au restaurant.");
        }
        return attempt;
    }

    private static Map<String, Object> sortieValide() {
        Map<String, Object> sortie = new LinkedHashMap<>();
        sortie.put(CompetenceAnalysisFields.STATUS, "PARTIAL");
        sortie.put(CompetenceAnalysisFields.VERDICT,
            "  L'activite est donnee, mais la reponse manque encore de precision.  ");
        sortie.put(CompetenceAnalysisFields.SUCCESS_POINT,
            "Vous repondez directement en parlant d'une activite que vous aimez.");
        sortie.put(CompetenceAnalysisFields.IMPROVEMENT_PRIORITY,
            "Ajoutez quand, ou ou avec qui vous pratiquez cette activite.");
        sortie.put(CompetenceAnalysisFields.IMPROVED_VERSION,
            "J'aime le sport. Le samedi matin, je joue au football avec mes amis.");
        return sortie;
    }

    private static Map<String, Object> sortieInvalide() {
        Map<String, Object> sortie = sortieValide();
        sortie.put(CompetenceAnalysisFields.STATUS, "PRESQUE");
        return sortie;
    }

    private static CompetenceAnalysisLlmClient.Outcome outcome(
            Map<String, Object> analyse, int in, int out, int cout) {
        return new CompetenceAnalysisLlmClient.Outcome(analyse, in, out, cout);
    }

    // --- tests -------------------------------------------------------------

    @Test
    void persisteTousLesChampsEtTermineEnEvaluated() {
        UserSkillAttempt attempt = attempt(SkillSection.EE);
        when(attemptManager.findByIdWithPrompt(ATTEMPT_ID)).thenReturn(Optional.of(attempt));
        when(client.analyse(anyString(), anyString()))
            .thenReturn(outcome(sortieValide(), 1200, 180, 3));

        service.analyse(ATTEMPT_ID);

        assertThat(attempt.getStatut()).isEqualTo(SkillAttemptStatut.EVALUATED);
        assertThat(attempt.getCriterionStatus()).isEqualTo(SkillCriterionStatus.PARTIAL);
        assertThat(attempt.getAiModel()).isEqualTo("deepseek-v4-flash");
        assertThat(attempt.getPromptVersion()).isEqualTo("v2");
        assertThat(attempt.getRubricsVersion()).isEqualTo("v2");
        assertThat(attempt.getTokensInput()).isEqualTo(1200);
        assertThat(attempt.getTokensOutput()).isEqualTo(180);
        assertThat(attempt.getCoutEstimeCentimes()).isEqualTo(3);
        assertThat(attempt.getErrorMessage()).isNull();
        verify(attemptManager).save(attempt);
    }

    @Test
    void nePersisteQueLesCinqClesDuContratEtLesTrime() {
        UserSkillAttempt attempt = attempt(SkillSection.EE);
        when(attemptManager.findByIdWithPrompt(ATTEMPT_ID)).thenReturn(Optional.of(attempt));
        when(client.analyse(anyString(), anyString()))
            .thenReturn(outcome(sortieValide(), 10, 10, 1));

        service.analyse(ATTEMPT_ID);

        assertThat(attempt.getAnalysisJson()).containsOnlyKeys(
            CompetenceAnalysisFields.STATUS,
            CompetenceAnalysisFields.VERDICT,
            CompetenceAnalysisFields.SUCCESS_POINT,
            CompetenceAnalysisFields.IMPROVEMENT_PRIORITY,
            CompetenceAnalysisFields.IMPROVED_VERSION);
        assertThat(attempt.getAnalysisJson().get(CompetenceAnalysisFields.VERDICT))
            .isEqualTo("L'activite est donnee, mais la reponse manque encore de precision.");
    }

    @Test
    void criterionStatusEstToujoursRenseigneCarIlPiloteLAffichage() {
        UserSkillAttempt attempt = attempt(SkillSection.EE);
        when(attemptManager.findByIdWithPrompt(ATTEMPT_ID)).thenReturn(Optional.of(attempt));
        when(client.analyse(anyString(), anyString()))
            .thenReturn(outcome(sortieValide(), 10, 10, 1));

        service.analyse(ATTEMPT_ID);

        // C'est la COLONNE, pas la cle JSON, qui derive le statut du sujet cote
        // fronts : la laisser nulle afficherait « Fait » sur une analyse payee.
        assertThat(attempt.getCriterionStatus()).isNotNull();
    }

    @Test
    void sortieInvalideEstRejoueeUneSeuleFoisPuisAcceptee() {
        UserSkillAttempt attempt = attempt(SkillSection.EE);
        when(attemptManager.findByIdWithPrompt(ATTEMPT_ID)).thenReturn(Optional.of(attempt));
        when(client.analyse(anyString(), anyString()))
            .thenReturn(outcome(sortieInvalide(), 1000, 100, 2))
            .thenReturn(outcome(sortieValide(), 1100, 120, 3));

        service.analyse(ATTEMPT_ID);

        verify(client, times(2)).analyse(anyString(), anyString());
        assertThat(attempt.getStatut()).isEqualTo(SkillAttemptStatut.EVALUATED);
        // Les deux appels ont ete factures : sous-estimer le cout sur les cas les
        // plus chers rendrait le suivi de cout faux la ou il sert.
        assertThat(attempt.getTokensInput()).isEqualTo(2100);
        assertThat(attempt.getTokensOutput()).isEqualTo(220);
        assertThat(attempt.getCoutEstimeCentimes()).isEqualTo(5);
    }

    @Test
    void leMessageDeReessaiPorteLesViolationsEtLaSortieRefusee() {
        UserSkillAttempt attempt = attempt(SkillSection.EE);
        when(attemptManager.findByIdWithPrompt(ATTEMPT_ID)).thenReturn(Optional.of(attempt));
        when(client.analyse(anyString(), anyString()))
            .thenReturn(outcome(sortieInvalide(), 10, 10, 1))
            .thenReturn(outcome(sortieValide(), 10, 10, 1));

        service.analyse(ATTEMPT_ID);

        ArgumentCaptor<String> userPrompts = ArgumentCaptor.forClass(String.class);
        verify(client, times(2)).analyse(anyString(), userPrompts.capture());
        String reessai = userPrompts.getAllValues().get(1);
        assertThat(reessai)
            .contains("REJETEE")
            .contains("VALIDATED, PARTIAL ou NOT_VALIDATED")
            .contains("PRESQUE");
    }

    @Test
    void secondRefusEchoueNettementSansAnalysePartielle() {
        UserSkillAttempt attempt = attempt(SkillSection.EE);
        when(attemptManager.findByIdWithPrompt(ATTEMPT_ID)).thenReturn(Optional.of(attempt));
        when(client.analyse(anyString(), anyString()))
            .thenReturn(outcome(sortieInvalide(), 10, 10, 1));

        assertThatThrownBy(() -> service.analyse(ATTEMPT_ID))
            .isInstanceOf(AiEvaluationException.class)
            .hasMessageContaining("apres une tentative de reparation");

        verify(client, times(2)).analyse(anyString(), anyString());
        // Rien n'est persiste : le runner async transformera l'exception en
        // FAILED durable, avec un bouton « relancer » cote candidat.
        verify(attemptManager, never()).save(any());
        assertThat(attempt.getStatut()).isEqualTo(SkillAttemptStatut.EVALUATING);
        assertThat(attempt.getCriterionStatus()).isNull();
    }

    @Test
    void enOralLaDureeNEstJamaisEnvoyeeAuCorrecteur() {
        UserSkillAttempt attempt = attempt(SkillSection.EO);
        when(attemptManager.findByIdWithPrompt(ATTEMPT_ID)).thenReturn(Optional.of(attempt));
        when(client.analyse(anyString(), anyString()))
            .thenReturn(outcome(sortieValide(), 10, 10, 1));

        service.analyse(ATTEMPT_ID);

        ArgumentCaptor<String> system = ArgumentCaptor.forClass(String.class);
        ArgumentCaptor<String> user = ArgumentCaptor.forClass(String.class);
        verify(client).analyse(system.capture(), user.capture());

        assertThat(user.getValue())
            .as("le correcteur ne doit pas pouvoir fonder son verdict sur une duree")
            .doesNotContain(String.valueOf(DUREE_ORALE_SEC));
        assertThat(system.getValue()).doesNotContain(String.valueOf(DUREE_ORALE_SEC));
    }

    @Test
    void enOralCEstLaTranscriptionQuiEstEnvoyeeSousUneCleQuiLeDit() {
        UserSkillAttempt attempt = attempt(SkillSection.EO);
        when(attemptManager.findByIdWithPrompt(ATTEMPT_ID)).thenReturn(Optional.of(attempt));
        when(client.analyse(anyString(), anyString()))
            .thenReturn(outcome(sortieValide(), 10, 10, 1));

        service.analyse(ATTEMPT_ID);

        ArgumentCaptor<String> user = ArgumentCaptor.forClass(String.class);
        verify(client).analyse(anyString(), user.capture());
        assertThat(user.getValue())
            .contains("transcript")
            .contains("J'aime le sport.")
            .doesNotContain("candidateProduction");
    }

    @Test
    void leUserPromptNePorteQueLesEntreesMinimales() {
        UserSkillAttempt attempt = attempt(SkillSection.EE);
        when(attemptManager.findByIdWithPrompt(ATTEMPT_ID)).thenReturn(Optional.of(attempt));
        when(client.analyse(anyString(), anyString()))
            .thenReturn(outcome(sortieValide(), 10, 10, 1));

        service.analyse(ATTEMPT_ID);

        ArgumentCaptor<String> user = ArgumentCaptor.forClass(String.class);
        verify(client).analyse(anyString(), user.capture());
        assertThat(user.getValue()).contains(
            "\"exam\":\"TCF_IRN\"", "\"section\":\"EE\"", "\"taskCode\":\"EE1\"",
            "\"skillId\":\"EE1-C3\"", "\"targetLevel\":\"A2\"",
            "uniqueCriterion", "candidateProduction");
    }

    @Test
    void aucuneNoteNiNiveauNEstDemandeAuCorrecteur() {
        UserSkillAttempt attempt = attempt(SkillSection.EE);
        when(attemptManager.findByIdWithPrompt(ATTEMPT_ID)).thenReturn(Optional.of(attempt));
        when(client.analyse(anyString(), anyString()))
            .thenReturn(outcome(sortieValide(), 10, 10, 1));

        service.analyse(ATTEMPT_ID);

        ArgumentCaptor<String> system = ArgumentCaptor.forClass(String.class);
        verify(client).analyse(system.capture(), anyString());
        String consignes = system.getValue().toLowerCase(Locale.ROOT);
        assertThat(consignes).contains("cecrl", "note");
        assertThat(consignes)
            .as("les consignes doivent INTERDIRE la note et le niveau, pas les demander")
            .contains("tu n'attribues jamais de niveau cecrl")
            .contains("tu n'attribues jamais de note");
    }

    @Test
    void tentativeIntrouvableEchoue() {
        when(attemptManager.findByIdWithPrompt(ATTEMPT_ID)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.analyse(ATTEMPT_ID))
            .isInstanceOf(NotFoundException.class);
    }

    @Test
    void oralSansTranscriptionEchoueSansAppelerLeCorrecteur() {
        UserSkillAttempt attempt = attempt(SkillSection.EO);
        attempt.setTranscript(null);
        when(attemptManager.findByIdWithPrompt(ATTEMPT_ID)).thenReturn(Optional.of(attempt));

        assertThatThrownBy(() -> service.analyse(ATTEMPT_ID))
            .isInstanceOf(AiEvaluationException.class)
            .hasMessageContaining("transcription");

        verify(client, never()).analyse(anyString(), anyString());
    }
}
