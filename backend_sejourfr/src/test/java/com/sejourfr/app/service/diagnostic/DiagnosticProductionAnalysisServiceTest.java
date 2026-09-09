package com.sejourfr.app.service.diagnostic;

import com.sejourfr.app.entity.DiagnosticProductionAnalysis;
import com.sejourfr.app.entity.DiagnosticTaskSkill;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.SubmissionStatut;
import com.sejourfr.app.manager.DiagnosticProductionAnalysisManager;
import com.sejourfr.app.manager.DiagnosticTaskSkillManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.manager.SkillManager;
import com.sejourfr.app.manager.TranscriptionManager;
import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.enums.ProductionEvaluabilite;
import com.sejourfr.app.service.EvaluationPurgeMetrics;
import com.sejourfr.app.service.LearningPlanObservationService;
import com.sejourfr.app.service.ProductionValidityService;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class DiagnosticProductionAnalysisServiceTest {

    @Test
    void repriseApresPersistanceAnalyseFinaliseStatutEtObservationsSansNouvelAppelLlm() {
        ProductionSubmissionManager submissions = mock(ProductionSubmissionManager.class);
        TranscriptionManager transcriptions = mock(TranscriptionManager.class);
        DiagnosticTaskSkillManager taskSkills = mock(DiagnosticTaskSkillManager.class);
        SkillManager skills = mock(SkillManager.class);
        DiagnosticAnalysisPromptBuilder prompts = mock(DiagnosticAnalysisPromptBuilder.class);
        DiagnosticAnalysisLlmClient llm = mock(DiagnosticAnalysisLlmClient.class);
        DiagnosticAnalysisReconciler reconciler = mock(DiagnosticAnalysisReconciler.class);
        DiagnosticAnalysisValidator validator = mock(DiagnosticAnalysisValidator.class);
        DiagnosticProductionAnalysisManager analyses = mock(DiagnosticProductionAnalysisManager.class);
        DiagnosticRubricsProvider rubrics = mock(DiagnosticRubricsProvider.class);
        LearningPlanObservationService observations = mock(LearningPlanObservationService.class);
        DiagnosticProductionAnalysisService service = new DiagnosticProductionAnalysisService(
                submissions, transcriptions, taskSkills, skills, prompts, llm,
                reconciler, validator, analyses, rubrics, observations,
                new DiagnosticOralArtifactFilter(new EvaluationPurgeMetrics()),
                new ProductionValidityService(new ProductionEvaluationProperties()),
                new DiagnosticStatusDistributionMetrics());

        ProductionTask task = new ProductionTask();
        task.setId(UUID.randomUUID());
        task.setEpreuve(EpreuveType.TCF_EE);
        task.setDiagnosticCode("INITIAL_TCF");
        task.setDiagnosticVersion(1);
        User user = new User();
        user.setId(UUID.randomUUID());
        ProductionSubmission submission = new ProductionSubmission();
        submission.setId(UUID.randomUUID());
        submission.setProductionTask(task);
        submission.setUser(user);
        submission.setStatut(SubmissionStatut.EVALUATING);
        submission.setDiagnostic(true);
        DiagnosticProductionAnalysis existing = new DiagnosticProductionAnalysis();
        existing.setSubmission(submission);
        existing.setAnalysisJson(Map.of("skills", List.of()));
        when(analyses.findBySubmissionId(submission.getId())).thenReturn(Optional.of(existing));
        when(submissions.findByIdWithTaskAndUser(submission.getId()))
                .thenReturn(Optional.of(submission));
        when(taskSkills.findActiveByTaskId(task.getId())).thenReturn(List.of());

        assertThat(service.analyseDiagnostic(submission.getId())).isSameAs(existing);

        assertThat(submission.getStatut()).isEqualTo(SubmissionStatut.EVALUATED);
        verify(submissions).save(submission);
        verify(observations).recordProduction(
                submission, List.of(), existing.getAnalysisJson(), true);
        verify(llm, never()).analyse(any(), any());
    }

    @Test
    void panneObservationLaisseLaProductionNonEvalueePourUneRepriseSure() {
        ProductionSubmissionManager submissions = mock(ProductionSubmissionManager.class);
        TranscriptionManager transcriptions = mock(TranscriptionManager.class);
        DiagnosticTaskSkillManager taskSkills = mock(DiagnosticTaskSkillManager.class);
        SkillManager skills = mock(SkillManager.class);
        DiagnosticAnalysisPromptBuilder prompts = mock(DiagnosticAnalysisPromptBuilder.class);
        DiagnosticAnalysisLlmClient llm = mock(DiagnosticAnalysisLlmClient.class);
        DiagnosticAnalysisReconciler reconciler = mock(DiagnosticAnalysisReconciler.class);
        DiagnosticAnalysisValidator validator = mock(DiagnosticAnalysisValidator.class);
        DiagnosticProductionAnalysisManager analyses = mock(DiagnosticProductionAnalysisManager.class);
        DiagnosticRubricsProvider rubrics = mock(DiagnosticRubricsProvider.class);
        LearningPlanObservationService observations = mock(LearningPlanObservationService.class);
        DiagnosticProductionAnalysisService service = new DiagnosticProductionAnalysisService(
                submissions, transcriptions, taskSkills, skills, prompts, llm,
                reconciler, validator, analyses, rubrics, observations,
                new DiagnosticOralArtifactFilter(new EvaluationPurgeMetrics()),
                new ProductionValidityService(new ProductionEvaluationProperties()),
                new DiagnosticStatusDistributionMetrics());

        ProductionTask task = new ProductionTask();
        task.setId(UUID.randomUUID());
        task.setEpreuve(EpreuveType.TCF_EE);
        task.setDiagnosticCode("INITIAL_TCF");
        task.setDiagnosticVersion(1);
        User user = new User();
        user.setId(UUID.randomUUID());
        ProductionSubmission submission = new ProductionSubmission();
        submission.setId(UUID.randomUUID());
        submission.setProductionTask(task);
        submission.setUser(user);
        submission.setStatut(SubmissionStatut.EVALUATING);
        submission.setDiagnostic(true);
        DiagnosticProductionAnalysis existing = new DiagnosticProductionAnalysis();
        existing.setSubmission(submission);
        existing.setAnalysisJson(Map.of("skills", List.of()));
        when(analyses.findBySubmissionId(submission.getId())).thenReturn(Optional.of(existing));
        when(submissions.findByIdWithTaskAndUser(submission.getId()))
                .thenReturn(Optional.of(submission));
        when(taskSkills.findActiveByTaskId(task.getId())).thenReturn(List.of());
        doThrow(new IllegalStateException("plan indisponible"))
                .when(observations).recordProduction(
                        submission, List.of(), existing.getAnalysisJson(), true);

        assertThatThrownBy(() -> service.analyseDiagnostic(submission.getId()))
                .isInstanceOf(IllegalStateException.class)
                .hasMessage("plan indisponible");

        assertThat(submission.getStatut()).isEqualTo(SubmissionStatut.EVALUATING);
        verify(submissions, never()).save(submission);
        verify(llm, never()).analyse(any(), any());
    }

    /**
     * LE PARCOURS COMPLET, sur l'incident réel : le reproche bâti sur
     * « horreurs » (le candidat avait dit « horaires ») est retiré de l'analyse
     * AVANT persistance, et la submission finit quand même {@code EVALUATED}.
     *
     * <p>C'est l'invariant qui compte : une purge ne fait jamais échouer une
     * analyse. Le filtre tourne après le validateur, sur la sortie déjà
     * normalisée — rien ne revalide derrière lui.
     */
    @Test
    void purgeLeReprocheDArtefactOralAvantPersistanceSansJamaisFaireEchouerLAnalyse() {
        ProductionSubmissionManager submissions = mock(ProductionSubmissionManager.class);
        TranscriptionManager transcriptions = mock(TranscriptionManager.class);
        DiagnosticTaskSkillManager taskSkills = mock(DiagnosticTaskSkillManager.class);
        SkillManager skills = mock(SkillManager.class);
        DiagnosticAnalysisPromptBuilder prompts = mock(DiagnosticAnalysisPromptBuilder.class);
        DiagnosticAnalysisLlmClient llm = mock(DiagnosticAnalysisLlmClient.class);
        DiagnosticAnalysisReconciler reconciler = mock(DiagnosticAnalysisReconciler.class);
        DiagnosticAnalysisValidator validator = mock(DiagnosticAnalysisValidator.class);
        DiagnosticProductionAnalysisManager analyses = mock(DiagnosticProductionAnalysisManager.class);
        DiagnosticRubricsProvider rubrics = mock(DiagnosticRubricsProvider.class);
        LearningPlanObservationService observations = mock(LearningPlanObservationService.class);
        DiagnosticProductionAnalysisService service = new DiagnosticProductionAnalysisService(
                submissions, transcriptions, taskSkills, skills, prompts, llm,
                reconciler, validator, analyses, rubrics, observations,
                new DiagnosticOralArtifactFilter(new EvaluationPurgeMetrics()),
                new ProductionValidityService(new ProductionEvaluationProperties()),
                new DiagnosticStatusDistributionMetrics());

        ProductionTask task = new ProductionTask();
        task.setId(UUID.randomUUID());
        task.setEpreuve(EpreuveType.TCF_EO);
        task.setDiagnosticCode("INITIAL_TCF");
        task.setDiagnosticVersion(1);
        User user = new User();
        user.setId(UUID.randomUUID());
        ProductionSubmission submission = new ProductionSubmission();
        submission.setId(UUID.randomUUID());
        submission.setProductionTask(task);
        submission.setUser(user);
        submission.setStatut(SubmissionStatut.EVALUATING);
        submission.setDiagnostic(true);

        Skill skill = new Skill();
        skill.setId(UUID.randomUUID());
        skill.setCode("EO2-C3");
        DiagnosticTaskSkill link = new DiagnosticTaskSkill();
        link.setSkill(skill);

        String transcription = "Si c'est le cas, j'aimerais savoir, c'est quoi les horreurs ? "
                + "Est-ce que c'est gratuit ou bien c'est payant ?";
        Map<String, Object> normalise = normalise(
                "Demande les horaires et le tarif, mais « horreurs » pour « horaires » est une "
                        + "erreur lexicale qui peut gêner.");

        when(analyses.findBySubmissionId(submission.getId())).thenReturn(Optional.empty());
        when(submissions.findByIdWithTaskAndUser(submission.getId()))
                .thenReturn(Optional.of(submission));
        when(taskSkills.findActiveByTaskId(task.getId())).thenReturn(List.of(link));
        when(transcriptions.findLatestTexteBySubmissionId(submission.getId()))
                .thenReturn(Optional.of(transcription));
        DiagnosticAnalysisLlmClient.Outcome outcome =
                new DiagnosticAnalysisLlmClient.Outcome(Map.of(), 10, 20, 3);
        when(llm.analyse(any(), any())).thenReturn(outcome);
        when(llm.getModelName()).thenReturn("modele-test");
        when(llm.getToolSchemaVersion()).thenReturn("v1");
        when(rubrics.version()).thenReturn("v1");
        when(reconciler.reconcile(any(), any())).thenReturn(Map.of());
        when(validator.violations(any(), any(), any())).thenReturn(List.of());
        when(validator.normalize(any(), any())).thenReturn(normalise);
        when(analyses.save(any(DiagnosticProductionAnalysis.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        DiagnosticProductionAnalysis persistee = service.analyseDiagnostic(submission.getId());

        assertThat(observation(persistee.getAnalysisJson()).get("explanation")).isEqualTo("");
        assertThat(observation(persistee.getAnalysisJson()).get("status"))
                .isEqualTo("TO_REINFORCE");
        assertThat(persistee.getLevelEstimate()).isEqualTo(NiveauCecrl.A2);
        assertThat(submission.getStatut()).isEqualTo(SubmissionStatut.EVALUATED);
    }

    /**
     * L'INCIDENT MESURE EN BASE : 4 secondes d'audio, 7 caracteres transcrits,
     * verdict {@code A1_NON_ATTEINT}. Une ABSENCE DE PREUVE etait enregistree
     * comme la PREUVE DU NIVEAU LE PLUS FAIBLE — et comme le diagnostic sert de
     * repli a {@code TcfProfileService} et que le niveau global est le plancher
     * des quatre domaines, tout le profil du candidat s'en trouvait tire au
     * fond.
     *
     * <p>Deux invariants ici : <b>aucun appel au correcteur</b> (on ne demande
     * pas a un modele de nommer un palier sans matiere : il en nommerait un), et
     * <b>aucun verdict</b> — ni niveau, ni accomplissement, ni communication.
     */
    @Test
    void uneProductionOraleQuasiVideNAppellePasLeCorrecteurEtNeRendAucunNiveau() {
        Fixture f = new Fixture(EpreuveType.TCF_EO);
        f.transcription("Bonjour.");

        DiagnosticProductionAnalysis persistee = f.service.analyseDiagnostic(f.submission.getId());

        verify(f.llm, never()).analyse(any(), any());
        assertThat(persistee.getEvaluabilite()).isEqualTo(ProductionEvaluabilite.NON_EVALUABLE);
        assertThat(persistee.getLevelEstimate()).isNull();
        assertThat(persistee.getTaskCompletion()).isNull();
        assertThat(persistee.getCommunicationStatus()).isNull();
        assertThat(persistee.getTokensInput()).isZero();
        assertThat(persistee.getCostMicroUsd()).isZero();
        // La session reste utilisable : la production est bien finalisee, elle
        // ne bascule pas en FAILED. Le candidat garde son ecrit.
        assertThat(f.submission.getStatut()).isEqualTo(SubmissionStatut.EVALUATED);
    }

    /**
     * Le faux positif est le risque principal : un A1 authentique produit peu,
     * et refuser de l'analyser lui retirerait le seul retour qu'il vient
     * chercher. La frontiere n'est pas « c'est mauvais », c'est « il n'y a rien
     * a observer ». Une production nettement plus courte que ce que le sujet
     * demande (100-120 mots) part donc bien au correcteur.
     */
    @Test
    void uneProductionCourteMaisReelleEstBienAnalysee() {
        Fixture f = new Fixture(EpreuveType.TCF_EO);
        f.transcription("Bonjour madame, je voudrais savoir les horaires de la piscine et "
                + "aussi le tarif pour les enfants, parce que je veux venir avec ma fille "
                + "le samedi matin.");
        f.correcteurRepond(normalise("Le tarif est demande."));

        DiagnosticProductionAnalysis persistee = f.service.analyseDiagnostic(f.submission.getId());

        verify(f.llm).analyse(any(), any());
        assertThat(persistee.getEvaluabilite()).isEqualTo(ProductionEvaluabilite.EVALUABLE);
        assertThat(persistee.getLevelEstimate()).isEqualTo(NiveauCecrl.A2);
    }

    /**
     * Une production inexploitable reste une ACTIVITE : le depot tient qu'une
     * production rendue compte meme quand le correcteur n'a rien pu observer
     * (c'est ce que lit {@code lastActivityAt} de la seance du Plan). On ecrit
     * donc une observation {@code NOT_OBSERVED} par competence de l'allowlist —
     * jamais une faiblesse, jamais une priorite.
     */
    @Test
    void uneProductionInexploitableObserveNotObservedEtJamaisUneFaiblesse() {
        Fixture f = new Fixture(EpreuveType.TCF_EE);
        f.submission.setTexteSoumis("Bonjour.");

        DiagnosticProductionAnalysis persistee = f.service.analyseDiagnostic(f.submission.getId());

        assertThat(observation(persistee.getAnalysisJson()).get("status")).isEqualTo("NOT_OBSERVED");
        assertThat(observation(persistee.getAnalysisJson()).get("observed")).isEqualTo(Boolean.FALSE);
        assertThat(observation(persistee.getAnalysisJson()).get("priority")).isEqualTo(Boolean.FALSE);
        assertThat(persistee.getAnalysisJson().get("strengths")).isEqualTo(List.of());
        assertThat(persistee.getAnalysisJson().get("weaknesses")).isEqualTo(List.of());
        verify(f.observations).recordProduction(
                eq(f.submission), any(), eq(persistee.getAnalysisJson()), eq(true));
    }

    /** Montage commun des trois cas ci-dessus. */
    private static final class Fixture {
        private final ProductionSubmissionManager submissions = mock(ProductionSubmissionManager.class);
        private final TranscriptionManager transcriptions = mock(TranscriptionManager.class);
        private final DiagnosticTaskSkillManager taskSkills = mock(DiagnosticTaskSkillManager.class);
        private final DiagnosticAnalysisLlmClient llm = mock(DiagnosticAnalysisLlmClient.class);
        private final DiagnosticAnalysisReconciler reconciler = mock(DiagnosticAnalysisReconciler.class);
        private final DiagnosticAnalysisValidator validator = mock(DiagnosticAnalysisValidator.class);
        private final DiagnosticProductionAnalysisManager analyses =
                mock(DiagnosticProductionAnalysisManager.class);
        private final DiagnosticRubricsProvider rubrics = mock(DiagnosticRubricsProvider.class);
        private final LearningPlanObservationService observations =
                mock(LearningPlanObservationService.class);
        private final DiagnosticProductionAnalysisService service;
        private final ProductionSubmission submission = new ProductionSubmission();

        private Fixture(EpreuveType epreuve) {
            service = new DiagnosticProductionAnalysisService(
                    submissions, transcriptions, taskSkills, mock(SkillManager.class),
                    mock(DiagnosticAnalysisPromptBuilder.class), llm, reconciler, validator,
                    analyses, rubrics, observations,
                    new DiagnosticOralArtifactFilter(new EvaluationPurgeMetrics()),
                    new ProductionValidityService(new ProductionEvaluationProperties()),
                new DiagnosticStatusDistributionMetrics());

            ProductionTask task = new ProductionTask();
            task.setId(UUID.randomUUID());
            task.setEpreuve(epreuve);
            task.setDiagnosticCode("INITIAL_TCF");
            task.setDiagnosticVersion(1);
            User user = new User();
            user.setId(UUID.randomUUID());
            submission.setId(UUID.randomUUID());
            submission.setProductionTask(task);
            submission.setUser(user);
            submission.setStatut(SubmissionStatut.EVALUATING);
            submission.setDiagnostic(true);

            Skill skill = new Skill();
            skill.setId(UUID.randomUUID());
            skill.setCode("EO2-C3");
            DiagnosticTaskSkill link = new DiagnosticTaskSkill();
            link.setSkill(skill);

            when(analyses.findBySubmissionId(submission.getId())).thenReturn(Optional.empty());
            when(submissions.findByIdWithTaskAndUser(submission.getId()))
                    .thenReturn(Optional.of(submission));
            when(taskSkills.findActiveByTaskId(task.getId())).thenReturn(List.of(link));
            when(analyses.save(any(DiagnosticProductionAnalysis.class)))
                    .thenAnswer(invocation -> invocation.getArgument(0));
        }

        private void transcription(String texte) {
            when(transcriptions.findLatestTexteBySubmissionId(submission.getId()))
                    .thenReturn(Optional.of(texte));
        }

        private void correcteurRepond(Map<String, Object> normalise) {
            DiagnosticAnalysisLlmClient.Outcome outcome =
                    new DiagnosticAnalysisLlmClient.Outcome(Map.of(), 10, 20, 3);
            when(llm.analyse(any(), any())).thenReturn(outcome);
            when(llm.getModelName()).thenReturn("modele-test");
            when(llm.getToolSchemaVersion()).thenReturn("v1");
            when(rubrics.version()).thenReturn("v1");
            when(reconciler.reconcile(any(), any())).thenReturn(Map.of());
            when(validator.violations(any(), any(), any())).thenReturn(List.of());
            when(validator.normalize(any(), any())).thenReturn(normalise);
        }
    }

    private static Map<String, Object> normalise(String explication) {
        Map<String, Object> observation = new LinkedHashMap<>();
        observation.put("skill_code", "EO2-C3");
        observation.put("observed", Boolean.TRUE);
        observation.put("status", "TO_REINFORCE");
        observation.put("evidence_segment", 1);
        observation.put("evidence", "Si c'est le cas, j'aimerais savoir, c'est quoi les horreurs ?");
        observation.put("explanation", explication);
        observation.put("confidence", "MEDIUM");
        observation.put("priority", Boolean.TRUE);

        Map<String, Object> analysis = new LinkedHashMap<>();
        analysis.put("level_estimate", "A2");
        analysis.put("task_completion", "PARTIAL");
        analysis.put("communication_status", "EFFECTIVE");
        analysis.put("summary", "Le candidat pose ses questions.");
        analysis.put("strengths", List.of("Se présente clairement."));
        analysis.put("weaknesses", new ArrayList<String>());
        List<Map<String, Object>> skills = new ArrayList<>();
        skills.add(observation);
        analysis.put("skills", skills);
        return analysis;
    }

    @SuppressWarnings("unchecked")
    private static Map<String, Object> observation(Map<String, Object> analysis) {
        return ((List<Map<String, Object>>) analysis.get("skills")).getFirst();
    }
}
