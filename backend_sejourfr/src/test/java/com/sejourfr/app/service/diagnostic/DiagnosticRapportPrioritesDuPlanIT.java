package com.sejourfr.app.service.diagnostic;

import com.sejourfr.app.dto.DiagnosticPlanPriorityDto;
import com.sejourfr.app.dto.DiagnosticResultDto;
import com.sejourfr.app.entity.DiagnosticProductionAnalysis;
import com.sejourfr.app.entity.DiagnosticSession;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.DiagnosticSessionStatus;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.SituationObjectif;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.manager.DiagnosticProductionAnalysisManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.manager.SkillManager;
import com.sejourfr.app.service.AccountDeletionService;
import com.sejourfr.app.service.LearningPlanObservationService;
import com.sejourfr.app.service.journey.JourneyEvaluation;
import com.sejourfr.app.service.journey.JourneyService;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.AuthTestSupport;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.is;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * 🛑 <b>Le rapport du diagnostic rapide sert les priorites du LOT DU PLAN</b>,
 * et ce lot suit l'ordre editorial — plus l'ordre d'ecriture des observations
 * (AR-3, audit du 2026-10-04).
 *
 * <p>Le chemin est le chemin LIVE, sans LLM : les observations sont ecrites par
 * le vrai {@link LearningPlanObservationService#recordProduction} (c'est lui
 * qui portait le bug), le lot par le vrai {@code JourneyService}, le rapport
 * par le vrai {@link DiagnosticService}. Seule l'analyse du correcteur est
 * posee a la main.
 *
 * <p>🛑 Non transactionnel : le parcours ecrit en {@code REQUIRES_NEW}.
 */
@Transactional(propagation = Propagation.NOT_SUPPORTED)
class DiagnosticRapportPrioritesDuPlanIT extends AbstractIntegrationTest {

    @Autowired private DiagnosticService diagnosticService;
    @Autowired private LearningPlanObservationService observationService;
    @Autowired private JourneyService journeyService;
    @Autowired private DiagnosticProductionAnalysisManager analysisManager;
    @Autowired private SkillManager skillManager;
    @Autowired private ProductionSubmissionManager submissionManager;
    @Autowired private TestData data;
    @Autowired private AuthTestSupport auth;
    @Autowired private MockMvc mockMvc;
    @Autowired private JdbcTemplate jdbc;
    @Autowired private AccountDeletionService accountDeletionService;

    private final List<UUID> candidats = new ArrayList<>();

    @AfterEach
    void menage() {
        candidats.forEach(accountDeletionService::deleteAccount);
        candidats.clear();
    }

    @Test
    @DisplayName("🔴 AR-3 — rapport = lot du Plan : mêmes compétences, même ordre, même skill_id, "
            + "et l'ordre est éditorial, pas celui de l'écriture")
    void lesPrioritesDuRapportSontCellesDuLot() {
        User user = candidat();
        journeyService.lire(user.getId(), Module.TCF);
        // Quatre fragilites a egalite parfaite (meme statut, meme confiance),
        // rendues par le correcteur dans l'ordre editorial 1, 2, 3, 4. L'ancien
        // horodatage par LIGNE donnait la 4e pour la plus recente : le lot
        // retenait 4, 3, 2 — la derniere competence ecrite d'abord.
        List<Skill> ee3 = skillManager.findActiveByTaskCode(SkillTaskCode.EE3).stream()
                .sorted(Comparator.comparingInt(Skill::getDisplayOrder))
                .toList();
        assertThat(ee3).as("referentiel EE3 seede").hasSizeGreaterThanOrEqualTo(5);
        List<Skill> fragiles = ee3.subList(0, 4);
        Skill solide = ee3.get(4);
        Diagnostic diagnostic = diagnosticAnalyse(user, fragiles, solide, NiveauCecrl.B1);

        DiagnosticResultDto result = diagnosticService.detail(user.getId(), diagnostic.sessionId())
                .result();

        // 1. Toutes les observations de la production portent le MEME instant.
        assertThat(jdbc.queryForList("""
                SELECT DISTINCT observed_at FROM learning_plan_observations
                WHERE source_id = ?""", Timestamp.class, diagnostic.submissionId()))
                .hasSize(1);
        // 2. Le lot suit l'ordre editorial (display_order), plafonne a 3.
        List<UUID> lot = jdbc.queryForList("""
                SELECT js.skill_id FROM journey_step js
                JOIN journey j ON j.id = js.journey_id
                WHERE js.source_assessment_id = ? AND js.type = 'TRAIN_SKILL'
                  AND j.status = 'EN_COURS'
                ORDER BY js.position""", UUID.class, diagnostic.sessionId());
        assertThat(lot).containsExactly(
                fragiles.get(0).getId(), fragiles.get(1).getId(), fragiles.get(2).getId());
        // 3. Le rapport sert EXACTEMENT le lot : memes skill_id, meme ordre.
        assertThat(result.planPriorities()).extracting(DiagnosticPlanPriorityDto::skillId)
                .containsExactlyElementsOf(lot);
        assertThat(result.planPriorities()).extracting(DiagnosticPlanPriorityDto::rank)
                .containsExactly(1, 2, 3);
        assertThat(result.planPriorities()).allSatisfy(priorite -> {
            assertThat(priorite.inCurrentCycle()).isTrue();
            assertThat(priorite.taskCode()).isEqualTo(SkillTaskCode.EE3);
            assertThat(priorite.generalCriterion()).isNotBlank();
            assertThat(priorite.explanation())
                    .isEqualTo("Constat sur " + priorite.skillCode() + ".");
        });
        // 4. Objectif NAT = B2, ecrit estime B1 : un palier sous l'objectif.
        assertThat(result.objectiveLevel()).isEqualTo(TargetLevel.B2);
        assertThat(result.situationObjectif()).isEqualTo(SituationObjectif.UN_PALIER_SOUS_OBJECTIF);
    }

    @Test
    @DisplayName("Sans lot (aucune fragilité) : liste vide, jamais un repli sur les priorités du diagnostic")
    void sansLotLaListeEstVide() {
        User user = candidat();
        journeyService.lire(user.getId(), Module.TCF);
        List<Skill> ee3 = skillManager.findActiveByTaskCode(SkillTaskCode.EE3);
        Diagnostic diagnostic = diagnosticAnalyse(user, List.of(), ee3.getFirst(), NiveauCecrl.B2);

        DiagnosticResultDto result = diagnosticService.detail(user.getId(), diagnostic.sessionId())
                .result();

        assertThat(result.planPriorities()).isEmpty();
        assertThat(result.situationObjectif()).isEqualTo(SituationObjectif.OBJECTIF_ATTEINT);
    }

    /**
     * « Revoir ma réponse » : aucune route nouvelle. La consigne est servie par
     * {@code written.instruction}, le texte par
     * {@code GET /api/production-submissions/{written.submissionId}} au
     * proprietaire, production de diagnostic comprise.
     */
    @Test
    @DisplayName("« Revoir ma réponse » : consigne et texte du candidat déjà servis par les routes existantes")
    void laReponseSeRelitParLesRoutesExistantes() throws Exception {
        User user = candidat();
        List<Skill> ee3 = skillManager.findActiveByTaskCode(SkillTaskCode.EE3);
        Diagnostic diagnostic = diagnosticAnalyse(user, List.of(ee3.getFirst()), ee3.get(1),
                NiveauCecrl.A2);
        String bearer = auth.bearer(user);

        mockMvc.perform(get("/api/diagnostics/" + diagnostic.sessionId())
                        .header(HttpHeaders.AUTHORIZATION, bearer))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.written.instruction").isNotEmpty())
                .andExpect(jsonPath("$.written.submissionId", is(diagnostic.submissionId().toString())))
                .andExpect(jsonPath("$.result.planPriorities").isArray())
                .andExpect(jsonPath("$.result.objectiveLevel", is("B2")))
                .andExpect(jsonPath("$.result.situationObjectif", is("PLUSIEURS_PALIERS_SOUS_OBJECTIF")));
        mockMvc.perform(get("/api/production-submissions/" + diagnostic.submissionId())
                        .header(HttpHeaders.AUTHORIZATION, bearer))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.texteSoumis", is(diagnostic.texte())));
    }

    // ------------------------------------------------------------------

    private record Diagnostic(UUID sessionId, UUID submissionId, String texte) {}

    /**
     * Un diagnostic rapide clos et analyse : l'analyse est posee a la main
     * (aucun LLM), puis tout le reste suit le chemin LIVE — observations,
     * parcours.
     */
    private Diagnostic diagnosticAnalyse(
            User user, List<Skill> fragiles, Skill solide, NiveauCecrl niveau) {
        DiagnosticSession session = data.diagnosticSession(user, DiagnosticSessionStatus.COMPLETED);
        ProductionSubmission ecrit = data.diagnosticSubmission(
                session.getWrittenAttempt(), session.getWrittenTask(), user);
        List<Map<String, Object>> skills = new ArrayList<>();
        List<Skill> allowlist = new ArrayList<>(fragiles);
        allowlist.add(solide);
        for (Skill skill : allowlist) {
            boolean fragile = fragiles.contains(skill);
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("skill_code", skill.getCode());
            item.put("observed", true);
            item.put("status", fragile ? "TO_REINFORCE" : "SOLID");
            item.put("confidence", "MEDIUM");
            item.put("priority", false);
            item.put("evidence", "Extrait de la production.");
            item.put("explanation", "Constat sur " + skill.getCode() + ".");
            skills.add(item);
        }
        Map<String, Object> analyse = Map.of("skills", skills, "summary", "Synthese.");
        DiagnosticProductionAnalysis analysis = data.diagnosticAnalysis(ecrit, niveau);
        analysis.setAnalysisJson(analyse);
        analysisManager.save(analysis);

        // Recharge comme le pipeline LIVE (finalizeDiagnostic) : tache et
        // candidat charges, hors de toute transaction englobante.
        observationService.recordProduction(
                submissionManager.findByIdWithTaskAndUser(ecrit.getId()).orElseThrow(),
                allowlist, analyse, true);
        journeyService.onAssessmentCompleted(user.getId(),
                JourneyEvaluation.diagnosticRapide(session.getId(), session.getCompletedAt()));
        return new Diagnostic(session.getId(), ecrit.getId(), ecrit.getTexteSoumis());
    }

    private User candidat() {
        User user = data.user();
        candidats.add(user.getId());
        user.setTargetProcedure(TargetProcedure.NAT);
        user.setTargetLevel(TargetProcedure.NAT.getRequiredTcfLevel());
        return data.saveUser(user);
    }
}
