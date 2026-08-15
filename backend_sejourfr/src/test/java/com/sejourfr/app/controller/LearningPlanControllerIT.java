package com.sejourfr.app.controller;

import com.sejourfr.app.entity.DiagnosticSession;
import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.SkillPrompt;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSkillAttempt;
import com.sejourfr.app.enums.DiagnosticSessionStatus;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.SkillAttemptStatut;
import com.sejourfr.app.enums.SkillCriterionStatus;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.manager.DiagnosticSessionManager;
import com.sejourfr.app.manager.LearningPlanObservationManager;
import com.sejourfr.app.manager.ProductionTaskManager;
import com.sejourfr.app.manager.UserSkillAttemptManager;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.AuthTestSupport;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.test.web.servlet.MockMvc;

import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Le Plan servi sur de vraies données : compteurs de progression et exercice
 * recommandé, calculés en base et non par le client.
 */
class LearningPlanControllerIT extends AbstractIntegrationTest {

    @Autowired private MockMvc mvc;
    @Autowired private TestData data;
    @Autowired private AuthTestSupport auth;
    @Autowired private UserSkillAttemptManager attemptManager;
    @Autowired private LearningPlanObservationManager observationManager;
    @Autowired private DiagnosticSessionManager sessionManager;
    @Autowired private ProductionTaskManager taskManager;

    @Test
    void lePlanExposeLaProgressionReelleEtUnExerciceQuiAvance() throws Exception {
        User user = data.user();
        Skill skill = data.skill(SkillTaskCode.EE1);
        SkillPrompt premier = data.skillPrompt(skill);
        SkillPrompt second = data.skillPrompt(skill);
        SkillPrompt jamaisTente = data.skillPrompt(skill);

        // Un sujet validé, un sujet rendu sans analyse (« Fait »), un intact.
        analysed(data.userSkillAttempt(user, premier), SkillCriterionStatus.VALIDATED);
        data.userSkillAttempt(user, second);
        observation(user, skill);
        completedSession(user);

        mvc.perform(get("/api/me/plan")
                        .header(HttpHeaders.AUTHORIZATION, auth.bearer(user)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.state").value("ACTIVE"))
                .andExpect(jsonPath("$.currentPriority.skillCode").value(skill.getCode()))
                .andExpect(jsonPath("$.currentPriority.promptCount").value(3))
                .andExpect(jsonPath("$.currentPriority.attemptedCount").value(2))
                .andExpect(jsonPath("$.currentPriority.validatedCount").value(1))
                // L'étape vaut ce que la compétence publie quand elle a moins de
                // 5 sujets : aucun dénominateur n'est inventé.
                .andExpect(jsonPath("$.currentPriority.stepPromptCount").value(3))
                .andExpect(jsonPath("$.currentPriority.stepAttemptedCount").value(2))
                .andExpect(jsonPath("$.currentPriority.stepValidatedCount").value(1))
                .andExpect(jsonPath("$.currentPriority.stepCompleted").value(false))
                // Le sujet jamais traité, pas le rang 1 déjà validé.
                .andExpect(jsonPath("$.currentPriority.recommendedExercise.skillPromptId")
                        .value(jamaisTente.getId().toString()))
                // 15-50 mots conseillés → 32 mots à 12 mots/minute.
                .andExpect(jsonPath("$.currentPriority.recommendedExercise.estimatedMinutes")
                        .value(3))
                .andExpect(jsonPath("$.observedSkills[0].skillCode").value(skill.getCode()))
                .andExpect(jsonPath("$.observedSkills[0].promptCount").value(3))
                .andExpect(jsonPath("$.observedSkills[0].attemptedCount").value(2))
                .andExpect(jsonPath("$.observedSkills[0].validatedCount").value(1));
    }

    @Test
    void tousLesSujetsTraitesLePlanProposeCeluiARenforcerLePlusAncien() throws Exception {
        User user = data.user();
        Skill skill = data.skill(SkillTaskCode.EE2);
        SkillPrompt valide = data.skillPrompt(skill);
        SkillPrompt aRenforcer = data.skillPrompt(skill);

        analysed(data.userSkillAttempt(user, valide), SkillCriterionStatus.VALIDATED);
        analysed(data.userSkillAttempt(user, aRenforcer), SkillCriterionStatus.NOT_VALIDATED);
        observation(user, skill);
        completedSession(user);

        mvc.perform(get("/api/me/plan")
                        .header(HttpHeaders.AUTHORIZATION, auth.bearer(user)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.currentPriority.promptCount").value(2))
                .andExpect(jsonPath("$.currentPriority.attemptedCount").value(2))
                .andExpect(jsonPath("$.currentPriority.validatedCount").value(1))
                .andExpect(jsonPath("$.currentPriority.recommendedExercise.skillPromptId")
                        .value(aRenforcer.getId().toString()));
    }

    /**
     * Une etape, ce sont les 5 premiers sujets actifs — pas les 15 de la
     * competence. Les deux jeux de compteurs sont servis cote a cote, et
     * l'exercice recommande ne sort jamais de l'etape.
     */
    @Test
    void uneEtapeVautCinqSujetsQuelQueSoitLeCatalogueDeLaCompetence() throws Exception {
        User user = data.user();
        Skill skill = data.skill(SkillTaskCode.EE1);
        List<SkillPrompt> prompts = new ArrayList<>();
        for (int rang = 1; rang <= 15; rang++) {
            prompts.add(data.skillPrompt(skill));
        }
        // Les 4 premiers sujets de l'etape sont traites, le 5e ne l'est pas.
        for (int index = 0; index < 4; index++) {
            data.userSkillAttempt(user, prompts.get(index));
        }
        observation(user, skill);
        completedSession(user);

        mvc.perform(get("/api/me/plan")
                        .header(HttpHeaders.AUTHORIZATION, auth.bearer(user)))
                .andExpect(status().isOk())
                // Compteurs de COMPETENCE : la semantique de SkillDto, intacte.
                .andExpect(jsonPath("$.currentPriority.promptCount").value(15))
                .andExpect(jsonPath("$.currentPriority.attemptedCount").value(4))
                // Compteurs d'ETAPE : les 5 premiers sujets, et eux seuls.
                .andExpect(jsonPath("$.currentPriority.stepPromptCount").value(5))
                .andExpect(jsonPath("$.currentPriority.stepAttemptedCount").value(4))
                .andExpect(jsonPath("$.currentPriority.stepValidatedCount").value(0))
                .andExpect(jsonPath("$.currentPriority.stepCompleted").value(false))
                // Le PERIMETRE de l'etape : ses 5 sujets, dans l'ordre. C'est lui
                // qu'un front ouvre quand on clique la competence depuis le Plan,
                // au lieu de retomber sur la fiche generique et son « 4/15 ».
                .andExpect(jsonPath("$.currentPriority.stepPromptIds.length()").value(5))
                .andExpect(jsonPath("$.currentPriority.stepPromptIds[0]")
                        .value(prompts.get(0).getId().toString()))
                .andExpect(jsonPath("$.currentPriority.stepPromptIds[4]")
                        .value(prompts.get(4).getId().toString()))
                // Le rang 5, jamais traite — jamais le rang 6, hors etape.
                .andExpect(jsonPath("$.currentPriority.recommendedExercise.skillPromptId")
                        .value(prompts.get(4).getId().toString()))
                // La carte « competence observee » n'est pas une etape : elle
                // garde les compteurs des 15 sujets.
                .andExpect(jsonPath("$.observedSkills[0].promptCount").value(15))
                .andExpect(jsonPath("$.observedSkills[0].attemptedCount").value(4));
    }

    /**
     * Une etape terminee <b>reste dans le Plan</b> : les priorites ne bougent
     * qu'a l'arrivee d'une nouvelle observation. Et l'exercice recommande reste
     * DANS l'etape — jamais le rang 6, pourtant jamais tente.
     */
    @Test
    void uneEtapeTermineeResteAffichEeEtSonExerciceResteDansLEtape() throws Exception {
        User user = data.user();
        data.userSubscription(user, data.plan());
        Skill skill = data.skill(SkillTaskCode.EO1);
        List<SkillPrompt> prompts = new ArrayList<>();
        for (int rang = 1; rang <= 7; rang++) {
            prompts.add(data.skillPrompt(skill));
        }
        for (int index = 0; index < 5; index++) {
            UserSkillAttempt attempt = data.userSkillAttempt(user, prompts.get(index));
            if (index == 0) analysed(attempt, SkillCriterionStatus.VALIDATED);
            if (index == 2) analysed(attempt, SkillCriterionStatus.NOT_VALIDATED);
        }
        observation(user, skill);
        completedSession(user);

        mvc.perform(get("/api/me/plan")
                        .header(HttpHeaders.AUTHORIZATION, auth.bearer(user)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.currentPriority.skillCode").value(skill.getCode()))
                .andExpect(jsonPath("$.currentPriority.stepPromptCount").value(5))
                .andExpect(jsonPath("$.currentPriority.stepAttemptedCount").value(5))
                // Terminee n'est pas « tout valide ».
                .andExpect(jsonPath("$.currentPriority.stepValidatedCount").value(1))
                .andExpect(jsonPath("$.currentPriority.stepCompleted").value(true))
                .andExpect(jsonPath("$.currentPriority.promptCount").value(7))
                .andExpect(jsonPath("$.currentPriority.recommendedExercise.skillPromptId")
                        .value(prompts.get(2).getId().toString()));
    }

    /**
     * Le verrou freemium ne masque RIEN du Plan : la priorite, ses compteurs et
     * l'exercice recommande sont servis en entier, avec un simple {@code locked}.
     * La competence de la priorite n&deg;1 reste ouverte meme si elle n'est pas
     * la premiere de sa tache — sinon l'etape 1 du Plan serait inatteignable.
     */
    @Test
    void sansAccesTcfLaCompetenceDeLaPrioriteResteOuverteEtLePlanResteEntier() throws Exception {
        User user = data.user();
        // TestData cree la competence apres les 8 rangs seedes : elle n'est
        // donc PAS la premiere de sa tache, et n'est ouverte que par le Plan.
        Skill skill = data.skill(SkillTaskCode.EE1);
        SkillPrompt premier = data.skillPrompt(skill);
        data.skillPrompt(skill);
        observation(user, skill);
        completedSession(user);

        mvc.perform(get("/api/me/plan")
                        .header(HttpHeaders.AUTHORIZATION, auth.bearer(user)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.currentPriority.skillCode").value(skill.getCode()))
                .andExpect(jsonPath("$.currentPriority.locked").value(false))
                .andExpect(jsonPath("$.currentPriority.promptCount").value(2))
                .andExpect(jsonPath("$.observedSkills[0].locked").value(false))
                // Ses 2 premiers sujets sont ouverts : l'exercice recommande
                // (le rang 1, jamais tente) est donc jouable tout de suite.
                .andExpect(jsonPath("$.currentPriority.recommendedExercise.skillPromptId")
                        .value(premier.getId().toString()))
                .andExpect(jsonPath("$.currentPriority.recommendedExercise.locked").value(false));
    }

    /**
     * Au-dela des 2 sujets offerts, l'exercice recommande reste DESIGNE et
     * visible : on pose le cadenas, on ne detourne pas le Plan vers un sujet
     * ouvert qui ne serait plus la priorite mesuree.
     *
     * <p>Et il fixe la consequence assumee du freemium : un compte gratuit
     * plafonne a <b>2 sur 5</b> — aucune etape n'est finissable sans
     * abonnement, alors que le Plan reste entierement visible.
     */
    @Test
    void auDelaDesDeuxSujetsOffertsLExerciceRecommandeEstDesigneMaisVerrouille()
            throws Exception {
        User user = data.user();
        Skill skill = data.skill(SkillTaskCode.EE2);
        List<SkillPrompt> prompts = new ArrayList<>();
        for (int rang = 1; rang <= 5; rang++) {
            prompts.add(data.skillPrompt(skill));
        }
        data.userSkillAttempt(user, prompts.get(0));
        data.userSkillAttempt(user, prompts.get(1));
        observation(user, skill);
        completedSession(user);

        mvc.perform(get("/api/me/plan")
                        .header(HttpHeaders.AUTHORIZATION, auth.bearer(user)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.currentPriority.locked").value(false))
                .andExpect(jsonPath("$.currentPriority.stepPromptCount").value(5))
                .andExpect(jsonPath("$.currentPriority.stepAttemptedCount").value(2))
                .andExpect(jsonPath("$.currentPriority.stepCompleted").value(false))
                .andExpect(jsonPath("$.currentPriority.recommendedExercise.skillPromptId")
                        .value(prompts.get(2).getId().toString()))
                .andExpect(jsonPath("$.currentPriority.recommendedExercise.locked").value(true));
    }

    /**
     * Le cas reel : le correcteur du diagnostic n'a designe aucune priorite, il
     * n'a rendu que des faiblesses ({@code TO_REINFORCE}). Le Plan doit quand
     * meme designer une etape ET un exercice — sinon il reste {@code ACTIVE}
     * sans rien a faire pendant que l'ecran du diagnostic, lui, en propose un.
     *
     * <p>Il verifie aussi le freemium sur une priorite <b>derivee</b> : la
     * competence n'est pas la premiere de sa tache, elle n'est donc ouverte que
     * parce que {@code SkillAccessService} suit le meme resolveur de priorites.
     */
    @Test
    void sansPrioriteDesigneeLePlanDesigneQuandMemeUneEtapeOuverteEtUnExercice()
            throws Exception {
        User user = data.user();
        Skill skill = data.skill(SkillTaskCode.EE3);
        SkillPrompt premier = data.skillPrompt(skill);
        data.skillPrompt(skill);
        observation(user, skill, LearningPlanSkillStatus.TO_REINFORCE);
        completedSession(user);

        mvc.perform(get("/api/me/plan")
                        .header(HttpHeaders.AUTHORIZATION, auth.bearer(user)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.state").value("ACTIVE"))
                .andExpect(jsonPath("$.currentPriority.skillCode").value(skill.getCode()))
                .andExpect(jsonPath("$.currentPriority.status").value("TO_REINFORCE"))
                .andExpect(jsonPath("$.currentPriority.recommendedExercise.skillPromptId")
                        .value(premier.getId().toString()))
                // Une priorite derivee ouvre la competence comme une designee.
                .andExpect(jsonPath("$.currentPriority.locked").value(false))
                .andExpect(jsonPath("$.currentPriority.recommendedExercise.locked").value(false));
    }

    @Test
    void unAbonneTcfNaAucunCadenasSurSonPlan() throws Exception {
        User user = data.user();
        data.userSubscription(user, data.plan());
        Skill skill = data.skill(SkillTaskCode.EE3);
        data.skillPrompt(skill);
        observation(user, skill);
        completedSession(user);

        mvc.perform(get("/api/me/plan")
                        .header(HttpHeaders.AUTHORIZATION, auth.bearer(user)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.currentPriority.locked").value(false))
                .andExpect(jsonPath("$.currentPriority.recommendedExercise.locked").value(false))
                .andExpect(jsonPath("$.observedSkills[0].locked").value(false));
    }

    private void analysed(UserSkillAttempt attempt, SkillCriterionStatus criterion) {
        attempt.setAnalysisRequested(true);
        attempt.setStatut(SkillAttemptStatut.EVALUATED);
        attempt.setCriterionStatus(criterion);
        attemptManager.save(attempt);
    }

    private void observation(User user, Skill skill) {
        observation(user, skill, LearningPlanSkillStatus.PRIORITY);
    }

    private void observation(User user, Skill skill, LearningPlanSkillStatus status) {
        LearningPlanObservation observation = new LearningPlanObservation();
        observation.setUser(user);
        observation.setSkill(skill);
        observation.setSourceType(LearningPlanSourceType.DIAGNOSTIC_EE);
        observation.setSourceId(UUID.randomUUID());
        observation.setObserved(true);
        observation.setStatus(status);
        observation.setEvidence("Bonjour Paul, je t'écris…");
        observation.setExplanation("Le destinataire n'est pas encore pris en compte.");
        observation.setConfidence(ObservationConfidence.HIGH);
        observation.setBaseline(true);
        observation.setObservedAt(Instant.now());
        observationManager.save(observation);
    }

    /** Le Plan n'est ACTIF qu'après un diagnostic terminé : on en pose un vrai. */
    private void completedSession(User user) {
        String code = "INITIAL_TCF";
        int version = taskManager.findLatestActiveDiagnosticVersion(code).orElseThrow();
        Map<String, Object> summary = new LinkedHashMap<>();
        summary.put("priority_skill_codes", java.util.List.of());
        DiagnosticSession session = new DiagnosticSession();
        session.setUser(user);
        session.setDiagnosticCode(code);
        session.setDiagnosticVersion(version);
        session.setWrittenTask(taskManager
                .findActiveDiagnostic(code, version, EpreuveType.TCF_EE).orElseThrow());
        session.setOralTask(taskManager
                .findActiveDiagnostic(code, version, EpreuveType.TCF_EO).orElseThrow());
        session.setWrittenAttempt(data.attempt(user));
        session.setOralAttempt(data.attempt(user));
        session.setStatus(DiagnosticSessionStatus.COMPLETED);
        session.setSummaryJson(summary);
        session.setStartedAt(Instant.now().minusSeconds(600));
        session.setCompletedAt(Instant.now());
        sessionManager.saveAndFlush(session);
    }
}
