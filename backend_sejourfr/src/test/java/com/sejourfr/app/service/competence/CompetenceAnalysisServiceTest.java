package com.sejourfr.app.service.competence;

import com.sejourfr.app.config.CompetenceProperties;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.SkillPrompt;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSkillAttempt;
import com.sejourfr.app.enums.SkillAttemptStatut;
import com.sejourfr.app.enums.SkillCriterionStatus;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.enums.TargetProcedure;
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
    private CompetenceLevelDowngradeMetrics downgradeMetrics;
    private CompetenceAnalysisServiceImpl service;

    @BeforeEach
    void setUp() {
        service = service(new CompetenceProperties());
    }

    /** Instancie le service sur un contrat donne, pour tester le retour arriere. */
    private CompetenceAnalysisServiceImpl service(CompetenceProperties props) {
        attemptManager = mock(UserSkillAttemptManager.class);
        client = mock(CompetenceAnalysisLlmClient.class);
        when(client.getModelName()).thenReturn("deepseek-v4-flash");
        when(client.getToolSchemaVersion()).thenReturn(props.getAnalysis().getToolSchemaVersion());

        CompetenceRubricsProvider rubrics =
            new CompetenceRubricsProvider(props, new ObjectMapper());
        rubrics.load();
        CompetenceAnalysisPromptBuilder promptBuilder =
            new CompetenceAnalysisPromptBuilder(new ObjectMapper(), rubrics);
        CompetenceAnalysisValidator validator = new CompetenceAnalysisValidator(rubrics);
        downgradeMetrics = new CompetenceLevelDowngradeMetrics();

        return new CompetenceAnalysisServiceImpl(
            attemptManager, promptBuilder, client, validator, rubrics,
            new CompetenceLevelEvidenceGuard(downgradeMetrics));
    }

    private static CompetenceProperties proprietes(String rubriques, String schema) {
        CompetenceProperties props = new CompetenceProperties();
        props.getAnalysis().setRubricsVersion(rubriques);
        props.getAnalysis().setToolSchemaVersion(schema);
        return props;
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
            // DEUX phrases, donc DEUX segments citables : sans quoi tout numero
            // valide vaudrait 1 et les tests de preuve ne prouveraient rien.
            attempt.setWrittenProduction("La semaine derniere, je suis alle au restaurant. "
                + "Comme le service etait lent, nous sommes partis avant le dessert.");
        }
        return attempt;
    }

    private static Map<String, Object> sortieValide() {
        Map<String, Object> sortie = new LinkedHashMap<>();
        sortie.put(CompetenceAnalysisFields.STATUS, "PARTIAL");
        sortie.put(CompetenceAnalysisFields.LEVEL_REACHED, "A2");
        sortie.put(CompetenceAnalysisFields.VERDICT,
            "  L'activite est donnee, mais la reponse manque encore de precision.  ");
        sortie.put(CompetenceAnalysisFields.STRENGTH_TAG, "Reponse directe");
        sortie.put(CompetenceAnalysisFields.FOCUS_TAG, "Ajouter une precision");
        return sortie;
    }

    private static Map<String, Object> sortieInvalide() {
        Map<String, Object> sortie = sortieValide();
        sortie.put(CompetenceAnalysisFields.STATUS, "PRESQUE");
        return sortie;
    }

    /** Sortie annoncant un palier a demontrer, avec la preuve donnee ou non. */
    private static Map<String, Object> sortieNiveau(String niveau, Object preuve) {
        Map<String, Object> sortie = sortieValide();
        sortie.put(CompetenceAnalysisFields.LEVEL_REACHED, niveau);
        if (preuve != null) sortie.put(CompetenceAnalysisFields.LEVEL_EVIDENCE, preuve);
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
        // Les deux versions ne coincident plus : v5 lit d'autres consignes en
        // rendant exactement le meme JSON, donc le meme contrat de sortie.
        assertThat(attempt.getPromptVersion()).isEqualTo("v4");
        assertThat(attempt.getRubricsVersion()).isEqualTo("v5");
        assertThat(attempt.getTokensInput()).isEqualTo(1200);
        assertThat(attempt.getTokensOutput()).isEqualTo(180);
        assertThat(attempt.getCoutEstimeCentimes()).isEqualTo(3);
        assertThat(attempt.getErrorMessage()).isNull();
        verify(attemptManager).save(attempt);
    }

    /**
     * Sur un A2, {@code level_evidence} est legitimement absent : rien n'est a
     * demontrer en dessous du B1. La cle ne doit alors pas etre persistee du
     * tout — un « trou nomme » en base ferait croire a une preuve perdue.
     */
    @Test
    void nePersisteQueLesClesRenseigneesDuContratEtLesTrime() {
        UserSkillAttempt attempt = attempt(SkillSection.EE);
        when(attemptManager.findByIdWithPrompt(ATTEMPT_ID)).thenReturn(Optional.of(attempt));
        when(client.analyse(anyString(), anyString()))
            .thenReturn(outcome(sortieValide(), 10, 10, 1));

        service.analyse(ATTEMPT_ID);

        assertThat(attempt.getAnalysisJson()).containsOnlyKeys(
            CompetenceAnalysisFields.STATUS,
            CompetenceAnalysisFields.LEVEL_REACHED,
            CompetenceAnalysisFields.VERDICT,
            CompetenceAnalysisFields.STRENGTH_TAG,
            CompetenceAnalysisFields.FOCUS_TAG);
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
            "\"skillId\":\"EE1-C3\"", "uniqueCriterion", "candidateProduction");
    }

    /**
     * AUCUNE ETIQUETTE DE PALIER n'accompagne plus le texte a niveler (v5).
     *
     * <p>Le {@code targetLevel} envoye jusqu'a v4 etait celui de la COMPETENCE,
     * pas de la personne — mais la grille ne le nommait <b>nulle part</b> : le
     * correcteur recevait un « A2 » dans le meme objet JSON que la production, et
     * n'a jamais rendu autre chose que du A2 sur ces sujets-la (mesure en base :
     * 0 B2 sur 18 tentatives). Le principe est celui du montage a deux appels :
     * on ne pose pas un niveau a cote d'un texte qu'on demande de niveler.
     */
    @Test
    void leNiveauCibleDeLaCompetenceNAccompagnePlusLaProduction() {
        UserSkillAttempt attempt = attempt(SkillSection.EE);
        when(attemptManager.findByIdWithPrompt(ATTEMPT_ID)).thenReturn(Optional.of(attempt));
        when(client.analyse(anyString(), anyString()))
            .thenReturn(outcome(sortieValide(), 10, 10, 1));

        service.analyse(ATTEMPT_ID);

        ArgumentCaptor<String> user = ArgumentCaptor.forClass(String.class);
        ArgumentCaptor<String> system = ArgumentCaptor.forClass(String.class);
        verify(client).analyse(system.capture(), user.capture());
        assertThat(user.getValue()).doesNotContain("targetLevel");
        assertThat(system.getValue()).doesNotContain("targetLevel");
    }

    /**
     * RETOUR ARRIERE REEL : sous les consignes v4, le prompt reprend exactement
     * la forme d'avant, {@code targetLevel} compris. Une bascule qui ne se defait
     * pas au bit pres n'est pas un retour arriere.
     */
    @Test
    void leRetourArriereEnV4RemetLeNiveauCibleDeLaCompetenceDansLePrompt() {
        CompetenceAnalysisServiceImpl v4 = service(proprietes("v4", "v4"));
        UserSkillAttempt attempt = attempt(SkillSection.EE);
        when(attemptManager.findByIdWithPrompt(ATTEMPT_ID)).thenReturn(Optional.of(attempt));
        when(client.analyse(anyString(), anyString()))
            .thenReturn(outcome(sortieValide(), 10, 10, 1));

        v4.analyse(ATTEMPT_ID);

        ArgumentCaptor<String> user = ArgumentCaptor.forClass(String.class);
        verify(client).analyse(anyString(), user.capture());
        assertThat(user.getValue()).contains("\"targetLevel\":\"A2\"");
    }

    @Test
    void aucuneNoteNEstDemandeeMaisLeNiveauLEst() {
        UserSkillAttempt attempt = attempt(SkillSection.EE);
        when(attemptManager.findByIdWithPrompt(ATTEMPT_ID)).thenReturn(Optional.of(attempt));
        when(client.analyse(anyString(), anyString()))
            .thenReturn(outcome(sortieValide(), 10, 10, 1));

        service.analyse(ATTEMPT_ID);

        ArgumentCaptor<String> system = ArgumentCaptor.forClass(String.class);
        verify(client).analyse(system.capture(), anyString());
        String consignes = system.getValue().toLowerCase(Locale.ROOT);
        assertThat(consignes)
            .as("la note reste interdite, dans toutes ses formes")
            .contains("tu n'attribues jamais de note");
        assertThat(consignes)
            .as("le niveau, lui, est desormais DEMANDE — dans son propre champ")
            .contains("level_reached")
            .contains("a1_non_atteint");
    }

    /**
     * L'INVARIANT DU MONTAGE A DEUX APPELS. Ce service ne doit jamais apprendre
     * quel palier la demarche du candidat exige : le depot a mesure, sur les
     * productions completes, qu'un correcteur qui connait l'objectif aligne son
     * jugement dessus (v10/v11 : accord exact 81,8 % → 75,6 %).
     *
     * <p>Le candidat de ce test vise la NATURALISATION (B2 exige) tout en portant
     * un {@code targetLevel} herite a B1 — exactement le couple qui a produit le
     * defaut d'origine ailleurs. Aucun des deux ne doit apparaitre.
     */
    @Test
    void leCorrecteurNApprendJamaisLePalierViseParLeCandidat() {
        UserSkillAttempt attempt = attempt(SkillSection.EE);
        User candidat = new User();
        candidat.setId(UUID.randomUUID());
        candidat.setTargetProcedure(TargetProcedure.NAT);
        candidat.setTargetLevel(TargetLevel.B1);
        attempt.setUser(candidat);
        when(attemptManager.findByIdWithPrompt(ATTEMPT_ID)).thenReturn(Optional.of(attempt));
        when(client.analyse(anyString(), anyString()))
            .thenReturn(outcome(sortieValide(), 10, 10, 1));

        service.analyse(ATTEMPT_ID);

        ArgumentCaptor<String> system = ArgumentCaptor.forClass(String.class);
        ArgumentCaptor<String> user = ArgumentCaptor.forClass(String.class);
        verify(client).analyse(system.capture(), user.capture());

        assertThat(user.getValue())
            .doesNotContain("niveau_vise")
            .doesNotContain("NAT")
            .doesNotContain("naturalisation");
        assertThat(system.getValue()).doesNotContain("niveau_vise");
        // Et depuis v5, meme le niveau cible de la COMPETENCE (donnee editoriale
        // du sujet) a disparu du prompt : aucune etiquette de palier n'accompagne
        // plus le texte a niveler.
        assertThat(user.getValue()).doesNotContain("targetLevel", "\"B1\"");
    }

    // ============================ preuve du niveau (contrat v4) ============

    /**
     * Un numero VALIDE est resolu en TEXTE avant persistance, comme
     * {@code resolvePreuveSegments} cote productions completes : aucune ligne de
     * base, donc aucun miroir DTO, ne transporte l'entier.
     */
    @Test
    void unNumeroValideEstResoluEnTexteEtLeNiveauEstConserve() {
        UserSkillAttempt attempt = attempt(SkillSection.EE);
        when(attemptManager.findByIdWithPrompt(ATTEMPT_ID)).thenReturn(Optional.of(attempt));
        when(client.analyse(anyString(), anyString()))
            .thenReturn(outcome(sortieNiveau("B1", 2), 10, 10, 1));

        service.analyse(ATTEMPT_ID);

        verify(client, times(1)).analyse(anyString(), anyString());
        assertThat(attempt.getAnalysisJson())
            .containsEntry(CompetenceAnalysisFields.LEVEL_REACHED, "B1")
            .containsEntry(CompetenceAnalysisFields.LEVEL_EVIDENCE,
                "Comme le service etait lent, nous sommes partis avant le dessert.");
        assertThat(downgradeMetrics.compteurs()).isEmpty();
    }

    /** La production part au correcteur DECOUPEE et NUMEROTEE, pas en bloc. */
    @Test
    void laProductionEstServieDecoupeeEnSegmentsNumerotes() {
        UserSkillAttempt attempt = attempt(SkillSection.EE);
        when(attemptManager.findByIdWithPrompt(ATTEMPT_ID)).thenReturn(Optional.of(attempt));
        when(client.analyse(anyString(), anyString()))
            .thenReturn(outcome(sortieValide(), 10, 10, 1));

        service.analyse(ATTEMPT_ID);

        ArgumentCaptor<String> user = ArgumentCaptor.forClass(String.class);
        verify(client).analyse(anyString(), user.capture());
        assertThat(user.getValue())
            .contains("[1] La semaine derniere")
            .contains("[2] Comme le service etait lent")
            .contains("de [1] a [2]");
    }

    /**
     * Preuve ABSENTE sur un B2 : une seule reparation, puis abaissement d'un
     * palier. L'analyse n'est jamais perdue — elle coute au candidat sa
     * production et son quota, un niveau prudent ne lui coute qu'un affichage.
     */
    @Test
    void preuveAbsenteSurUnB2EstRepareeUneFoisPuisLeNiveauEstAbaisse() {
        UserSkillAttempt attempt = attempt(SkillSection.EE);
        when(attemptManager.findByIdWithPrompt(ATTEMPT_ID)).thenReturn(Optional.of(attempt));
        when(client.analyse(anyString(), anyString()))
            .thenReturn(outcome(sortieNiveau("B2", null), 10, 10, 1));

        service.analyse(ATTEMPT_ID);

        verify(client, times(2)).analyse(anyString(), anyString());
        assertThat(attempt.getStatut()).isEqualTo(SkillAttemptStatut.EVALUATED);
        assertThat(attempt.getAnalysisJson())
            .as("un palier, jamais deux, et le garde-fou ne releve jamais")
            .containsEntry(CompetenceAnalysisFields.LEVEL_REACHED, "B1")
            .doesNotContainKey(CompetenceAnalysisFields.LEVEL_EVIDENCE);
        assertThat(downgradeMetrics.compteurs())
            .containsEntry("PREUVE_ABSENTE", 1L)
            .containsEntry("PREUVE_ABSENTE/B2->B1", 1L);
    }

    /** Numero HORS BORNES : meme traitement, et le motif reste distinguable. */
    @Test
    void numeroHorsBornesEstRepareUneFoisPuisLeNiveauEstAbaisse() {
        UserSkillAttempt attempt = attempt(SkillSection.EE);
        when(attemptManager.findByIdWithPrompt(ATTEMPT_ID)).thenReturn(Optional.of(attempt));
        when(client.analyse(anyString(), anyString()))
            .thenReturn(outcome(sortieNiveau("B1", 7), 10, 10, 1));

        service.analyse(ATTEMPT_ID);

        verify(client, times(2)).analyse(anyString(), anyString());
        assertThat(attempt.getAnalysisJson())
            .containsEntry(CompetenceAnalysisFields.LEVEL_REACHED, "A2")
            .doesNotContainKey(CompetenceAnalysisFields.LEVEL_EVIDENCE);
        assertThat(downgradeMetrics.compteurs()).containsEntry("PREUVE_HORS_BORNES/B1->A2", 1L);
    }

    /**
     * Le message de reparation doit etre ACTIONNABLE. Le depot a mesure que le
     * seul libelle brut d'une violation ne repare rien : 0 preuve reparee sur 8.
     */
    @Test
    void leMessageDeReparationNommeLeNumeroRefuseEtLesBornesReelles() {
        UserSkillAttempt attempt = attempt(SkillSection.EE);
        when(attemptManager.findByIdWithPrompt(ATTEMPT_ID)).thenReturn(Optional.of(attempt));
        when(client.analyse(anyString(), anyString()))
            .thenReturn(outcome(sortieNiveau("B2", 9), 10, 10, 1))
            .thenReturn(outcome(sortieNiveau("B2", 1), 10, 10, 1));

        service.analyse(ATTEMPT_ID);

        ArgumentCaptor<String> prompts = ArgumentCaptor.forClass(String.class);
        verify(client, times(2)).analyse(anyString(), prompts.capture());
        assertThat(prompts.getAllValues().get(1))
            .contains("level_evidence vaut 9")
            .contains("les numeros vont de 1 a 2")
            .contains("annonce le palier INFERIEUR");
        // Reparee : le niveau annonce est conserve, rien n'est abaisse.
        assertThat(attempt.getAnalysisJson())
            .containsEntry(CompetenceAnalysisFields.LEVEL_REACHED, "B2");
        assertThat(downgradeMetrics.compteurs()).isEmpty();
    }

    /** A2 et en dessous n'ont rien a demontrer : aucune reparation, aucun abaissement. */
    @Test
    void unA2SansPreuveEstAccepteSansReparationNiAbaissement() {
        UserSkillAttempt attempt = attempt(SkillSection.EE);
        when(attemptManager.findByIdWithPrompt(ATTEMPT_ID)).thenReturn(Optional.of(attempt));
        when(client.analyse(anyString(), anyString()))
            .thenReturn(outcome(sortieNiveau("A2", null), 10, 10, 1));

        service.analyse(ATTEMPT_ID);

        verify(client, times(1)).analyse(anyString(), anyString());
        assertThat(attempt.getAnalysisJson())
            .containsEntry(CompetenceAnalysisFields.LEVEL_REACHED, "A2");
        assertThat(downgradeMetrics.compteurs()).isEmpty();
    }

    /**
     * UNE preuve manquante ne fait JAMAIS echouer l'analyse, meme quand le
     * correcteur ne repare pas. C'est la doctrine du depot : une analyse perdue
     * coute plus cher au candidat qu'un niveau prudent.
     */
    @Test
    void unePreuveManquanteNeFaitJamaisEchouerLAnalyse() {
        UserSkillAttempt attempt = attempt(SkillSection.EE);
        when(attemptManager.findByIdWithPrompt(ATTEMPT_ID)).thenReturn(Optional.of(attempt));
        when(client.analyse(anyString(), anyString()))
            .thenReturn(outcome(sortieNiveau("B2", "le deuxieme"), 10, 10, 1));

        service.analyse(ATTEMPT_ID);

        assertThat(attempt.getStatut()).isEqualTo(SkillAttemptStatut.EVALUATED);
        assertThat(attempt.getErrorMessage()).isNull();
        verify(attemptManager).save(attempt);
        assertThat(downgradeMetrics.compteurs()).containsEntry("PREUVE_NON_ENTIERE/B2->B1", 1L);
    }

    /**
     * RETOUR ARRIERE. Sous v3, {@code level_evidence} n'est ni exige, ni attendu,
     * ni meme evoque : la production repart en bloc, non numerotee.
     */
    @Test
    void sousLeContratV3LaPreuveDuNiveauNEstNiExigeeNiAttendue() {
        service = service(proprietes("v3", "v3"));
        UserSkillAttempt attempt = attempt(SkillSection.EE);
        when(attemptManager.findByIdWithPrompt(ATTEMPT_ID)).thenReturn(Optional.of(attempt));
        when(client.analyse(anyString(), anyString()))
            .thenReturn(outcome(sortieNiveau("B2", null), 10, 10, 1));

        service.analyse(ATTEMPT_ID);

        verify(client, times(1)).analyse(anyString(), anyString());
        assertThat(attempt.getAnalysisJson())
            .containsEntry(CompetenceAnalysisFields.LEVEL_REACHED, "B2")
            .doesNotContainKey(CompetenceAnalysisFields.LEVEL_EVIDENCE);
        assertThat(downgradeMetrics.compteurs()).isEmpty();

        ArgumentCaptor<String> user = ArgumentCaptor.forClass(String.class);
        verify(client).analyse(anyString(), user.capture());
        assertThat(user.getValue())
            .doesNotContain("[1] La semaine derniere")
            .doesNotContain("level_evidence");
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
