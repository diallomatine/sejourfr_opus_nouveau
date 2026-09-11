package com.sejourfr.app.service;

import com.sejourfr.app.dto.AttemptResponse;
import com.sejourfr.app.dto.LearningPlanDto;
import com.sejourfr.app.dto.PlanDomainAssessmentDto;
import com.sejourfr.app.dto.LearningPlanPriorityDto;
import com.sejourfr.app.dto.PlanDomainDto;
import com.sejourfr.app.dto.StartAttemptRequest;
import com.sejourfr.app.dto.SubmitAnswerRequest;
import com.sejourfr.app.entity.AttemptQuestion;
import com.sejourfr.app.entity.Choice;
import com.sejourfr.app.entity.DiagnosticSession;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.DiagnosticSessionStatus;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.enums.LearningPlanState;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.PlanCycleState;
import com.sejourfr.app.enums.PlanDomainAssessmentKind;
import com.sejourfr.app.enums.PlanDomainPriority;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.manager.AttemptQuestionManager;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * <b>Parcours A du brief §113</b>, de bout en bout sur la vraie base : compte
 * neuf &rarr; Plan sans diagnostic &rarr; diagnostic rapide &rarr; Plan 2/4
 * &rarr; epreuve CO &rarr; Plan 3/4 &rarr; epreuve CE &rarr; Plan 4/4.
 *
 * <p>Ce qu'il verifie, c'est que <b>le diagnostic est devenu progressif</b> : a
 * chacun des cinq etats, {@code domaines}, {@code cycle} et
 * {@code domainesAEvaluer} disent la meme verite, et le Plan reste utilisable.
 *
 * <p>🛑 <b>Les deux etapes de comprehension sont REELLEMENT JOUEES</b> — examen
 * blanc de module existant, questions seedees, correction deterministe, aucun
 * appel LLM. C'est la garantie que « completer son profil » ne passe par aucun
 * moteur nouveau (brief §5, §84) et que la correction CO/CE reste 100 %
 * deterministe (brief §105).
 *
 * <p>Le diagnostic, lui, est <b>simule au niveau de ses resultats</b> (session
 * {@code COMPLETED} + les deux analyses) : le jouer vraiment appellerait un LLM
 * payant, ce que le depot interdit sans demande explicite. Ce qui est teste ici
 * n'est pas le pipeline d'analyse — il l'est ailleurs — mais ce que le Plan en
 * fait.
 *
 * <p>Assertions <b>tolerantes au seed Flyway</b> : la banque de questions est
 * seedee, on ne raisonne que sur la session que le test vient de creer.
 */
class LearningPlanProfilProgressifIT extends AbstractIntegrationTest {

    @Autowired private TestData data;
    @Autowired private LearningPlanService planService;
    @Autowired private AttemptService attemptService;
    @Autowired private AttemptQuestionManager attemptQuestionManager;
    @Autowired private EntityManager entityManager;

    @Test
    @DisplayName("Parcours A : 0/4 puis 2/4 puis 3/4 puis 4/4, sans jamais casser le Plan")
    void leProfilSeCompleteDomaineParDomaine() {
        User user = candidat();

        // --- 0 / 4 : compte neuf, aucun diagnostic --------------------------
        LearningPlanDto vierge = planService.get(user.getId());

        assertThat(vierge.state()).isEqualTo(LearningPlanState.NEEDS_DIAGNOSTIC);
        assertThat(vierge.cycle().domainsEvaluated()).isZero();
        assertThat(vierge.cycle().domainsExpected()).isEqualTo(4);
        assertThat(vierge.cycle().profileComplete()).isFalse();
        assertThat(vierge.cycle().startingLevel()).isNull();
        assertThat(vierge.cycle().state()).isEqualTo(PlanCycleState.BUILDING_BASELINE);
        // Les quatre domaines sont servis, tous a evaluer : l'ecran d'onboarding
        // du brief §6 n'est jamais vide.
        assertThat(vierge.domaines()).hasSize(4)
                .allSatisfy(domaine -> {
                    assertThat(domaine.evaluated()).isFalse();
                    assertThat(domaine.niveau()).isNull();
                    assertThat(domaine.priority()).isEqualTo(PlanDomainPriority.A_EVALUER);
                });
        assertThat(vierge.domainesAEvaluer())
                .extracting(PlanDomainAssessmentDto::epreuve)
                .containsExactly(EpreuveType.TCF_CO, EpreuveType.TCF_CE,
                        EpreuveType.TCF_EO, EpreuveType.TCF_EE);
        assertThat(assessment(vierge, EpreuveType.TCF_EE).kind())
                .isEqualTo(PlanDomainAssessmentKind.DIAGNOSTIC);
        assertThat(assessment(vierge, EpreuveType.TCF_CO).kind())
                .isEqualTo(PlanDomainAssessmentKind.MODULE_MOCK_EXAM);
        // Aucun examen de palier tant que le profil est incomplet (brief §77).
        assertThat(vierge.milestone()).isNull();

        // --- 2 / 4 : diagnostic rapide (EE + EO) ----------------------------
        diagnosticRapide(user, NiveauCecrl.A2, NiveauCecrl.A2);
        flush();
        LearningPlanDto apresDiagnostic = planService.get(user.getId());

        assertThat(apresDiagnostic.state()).isEqualTo(LearningPlanState.ACTIVE);
        assertThat(apresDiagnostic.cycle().domainsEvaluated()).isEqualTo(2);
        assertThat(apresDiagnostic.cycle().profileComplete()).isFalse();
        assertThat(apresDiagnostic.cycle().startingLevel()).isEqualTo(NiveauCecrl.A2);
        assertThat(domaine(apresDiagnostic, EpreuveType.TCF_EE).evaluated()).isTrue();
        assertThat(domaine(apresDiagnostic, EpreuveType.TCF_EO).evaluated()).isTrue();
        // « Completer mon profil » : il reste la comprehension, par un examen
        // blanc de module, sur le slot offert.
        assertThat(apresDiagnostic.domainesAEvaluer())
                .extracting(PlanDomainAssessmentDto::epreuve)
                .containsExactly(EpreuveType.TCF_CO, EpreuveType.TCF_CE);
        assertThat(apresDiagnostic.domainesAEvaluer()).allSatisfy(item -> {
            assertThat(item.kind()).isEqualTo(PlanDomainAssessmentKind.MODULE_MOCK_EXAM);
            assertThat(item.slotNumber()).isEqualTo(1);
        });
        assertThat(apresDiagnostic.milestone()).isNull();

        // --- 3 / 4 : l'epreuve CO, reellement jouee -------------------------
        // Le serveur a dit quoi lancer ; le test le lance EXACTEMENT comme il
        // l'a dit — c'est ce qui prouve que le fait servi est utilisable.
        jouer(user, assessment(apresDiagnostic, EpreuveType.TCF_CO));
        flush();
        LearningPlanDto apresCo = planService.get(user.getId());

        assertThat(apresCo.cycle().domainsEvaluated()).isEqualTo(3);
        assertThat(apresCo.cycle().profileComplete()).isFalse();
        PlanDomainDto co = domaine(apresCo, EpreuveType.TCF_CO);
        assertThat(co.evaluated()).isTrue();
        assertThat(co.niveau()).isNotNull();
        assertThat(co.priority()).isNotEqualTo(PlanDomainPriority.A_EVALUER);
        // Un domaine de comprehension mesure publie ses trois paliers.
        assertThat(co.paliers()).hasSize(3);
        assertThat(apresCo.domainesAEvaluer())
                .extracting(PlanDomainAssessmentDto::epreuve)
                .containsExactly(EpreuveType.TCF_CE);
        assertThat(apresCo.milestone()).isNull();

        // --- 4 / 4 : l'epreuve CE, et le profil est complet -----------------
        jouer(user, assessment(apresCo, EpreuveType.TCF_CE));
        flush();
        LearningPlanDto complet = planService.get(user.getId());

        assertThat(complet.cycle().domainsEvaluated()).isEqualTo(4);
        assertThat(complet.cycle().profileComplete()).isTrue();
        assertThat(complet.cycle().state()).isNotEqualTo(PlanCycleState.BUILDING_BASELINE);
        assertThat(complet.domaines()).hasSize(4)
                .allSatisfy(domaine -> assertThat(domaine.evaluated()).isTrue());
        // Plus rien a mesurer : vide est l'etat vise, pas une anomalie.
        assertThat(complet.domainesAEvaluer()).isEmpty();
        // Le niveau global est le plancher des quatre domaines mesures.
        assertThat(complet.cycle().startingLevel()).isNotNull();
    }

    /**
     * Un domaine mesure ne revient <b>jamais</b> dans « completer mon profil »,
     * meme si le candidat n'a jamais passe le diagnostic : le profil se lit sur
     * ce qui est mesure, pas sur une intention declaree (brief §3, §6 — « CO
     * uniquement » est un premier domaine legitime).
     */
    @Test
    @DisplayName("Un candidat qui commence par la comprehension a un Plan, sans diagnostic")
    void laComprehensionPeutEtreLePremierDomaineEvalue() {
        User user = candidat();

        jouer(user, PlanDomainAssessmentDto.moduleMockExam(
                EpreuveType.TCF_CO, QuestionType.CO, 1, 20));
        flush();
        LearningPlanDto plan = planService.get(user.getId());

        // Aucun diagnostic : le Plan le demande toujours pour ses PRIORITES...
        assertThat(plan.state()).isEqualTo(LearningPlanState.NEEDS_DIAGNOSTIC);
        // ... mais il connait deja un domaine sur quatre, et il le dit.
        assertThat(plan.cycle().domainsEvaluated()).isEqualTo(1);
        assertThat(domaine(plan, EpreuveType.TCF_CO).evaluated()).isTrue();
        assertThat(plan.domainesAEvaluer())
                .extracting(PlanDomainAssessmentDto::epreuve)
                .containsExactly(EpreuveType.TCF_CE, EpreuveType.TCF_EO, EpreuveType.TCF_EE);
        // L'expression reste ouverte par le diagnostic, qui n'a pas ete passe.
        assertThat(assessment(plan, EpreuveType.TCF_EO).kind())
                .isEqualTo(PlanDomainAssessmentKind.DIAGNOSTIC);
    }


    /**
     * <b>Le diagnostic RAPIDE suffit au Plan</b> — arbitrage du proprietaire du
     * 2026-09-12 : le diagnostic complet n'est plus un prerequis d'acces, il
     * n'est qu'un moyen d'affiner.
     *
     * <p>🛑 <b>Et la contrainte centrale, gelee ici</b> : un Plan provisoire ne
     * s'appuie que sur ce qui a ete <b>reellement mesure</b>. Le rapide dans sa
     * forme actuelle (L3/V050) n'a qu'une production <b>ecrite</b> : l'oral et
     * les deux comprehensions restent <b>inconnus</b>, donc aucune de leurs
     * competences ne devient une priorite. Elles ressortent « a evaluer », ce
     * qui est une tout autre nouvelle que « fragile » — c'est exactement la
     * confusion qui a produit les faux {@code A1_NON_ATTEINT} de V040/V041/V042.
     *
     * <p>Un Plan avec <b>peu</b> de priorites, toutes vraies, est le bon
     * resultat. Un Plan qui remplirait ses quatre domaines en devinant serait un
     * echec, meme s'il etait plus joli.
     */
    @Test
    @DisplayName("🛑 Le rapide seul donne un Plan REEL, et n'invente aucune priorite hors de ce qu'il a mesure")
    void leRapideSeulDonneUnPlanSansInventerDePriorite() {
        User user = candidat();

        // Le rapide dans sa forme actuelle : UNE production ecrite analysee.
        // L'etape orale n'est pas jouee — DiagnosticSession.oralTask est
        // nullable depuis V050, et « pas d'etape orale » n'est pas « oral rate ».
        DiagnosticSession session =
                data.diagnosticSession(user, DiagnosticSessionStatus.COMPLETED);
        data.diagnosticAnalysis(data.diagnosticSubmission(
                session.getWrittenAttempt(), session.getWrittenTask(), user), NiveauCecrl.A2);
        // 🛑 Une competence du REFERENTIEL PUBLIE, pas une competence de test :
        // le filtre de faisabilite (§8) ecarte toute competence sans sujet
        // actif, et une fragilite fabriquee sans contenu n'aurait jamais de
        // carte — le test aurait alors verifie le filtre, pas la regle.
        Skill mesuree = entityManager.createQuery(
                        "select s from Skill s where s.section = :section and s.active = true"
                                + " order by s.displayOrder asc", Skill.class)
                .setParameter("section", SkillSection.EE)
                .setMaxResults(1)
                .getSingleResult();
        data.learningPlanObservation(user, mesuree, LearningPlanSourceType.DIAGNOSTIC_EE,
                LearningPlanSkillStatus.TO_REINFORCE, ObservationConfidence.MEDIUM,
                null, Instant.now());
        flush();

        LearningPlanDto plan = planService.get(user.getId());

        // 1. Le Plan EXISTE et il est utilisable : des priorites, et chacune
        //    porte une action. Jamais une carte sans exercice.
        assertThat(plan.state()).isEqualTo(LearningPlanState.ACTIVE);
        List<LearningPlanPriorityDto> priorites = new java.util.ArrayList<>();
        if (plan.currentPriority() != null) priorites.add(plan.currentPriority());
        priorites.addAll(plan.nextPriorities());
        assertThat(priorites).isNotEmpty()
                .allSatisfy(p -> assertThat(p.recommendedExercise()).isNotNull());

        // 2. 🛑 AUCUNE priorite hors du seul domaine reellement mesure.
        assertThat(priorites)
                .extracting(LearningPlanPriorityDto::section)
                .containsOnly(SkillSection.EE);
        assertThat(priorites)
                .extracting(LearningPlanPriorityDto::skillId)
                .contains(mesuree.getId());

        // 3. Les trois domaines non mesures restent INCONNUS. `null` = inconnu,
        //    jamais mauvais : pas de niveau invente, pas de fragilite inventee,
        //    et une action qui MESURE plutot qu'une action qui repare.
        assertThat(plan.domainesAEvaluer())
                .extracting(PlanDomainAssessmentDto::epreuve)
                .containsExactlyInAnyOrder(
                        EpreuveType.TCF_EO, EpreuveType.TCF_CO, EpreuveType.TCF_CE);
        for (EpreuveType inconnu
                : List.of(EpreuveType.TCF_EO, EpreuveType.TCF_CO, EpreuveType.TCF_CE)) {
            PlanDomainDto domaine = domaine(plan, inconnu);
            assertThat(domaine.evaluated()).isFalse();
            assertThat(domaine.niveau()).isNull();
            assertThat(domaine.priority()).isEqualTo(PlanDomainPriority.A_EVALUER);
            // 🛑 Zero action fabriquee sur un domaine jamais mesure : on ne lui
            // apprend pas un palier qu'on n'a pas su situer.
            assertThat(domaine.acquireCount()).isZero();
        }

        // 4. Le Plan se dit PROVISOIRE par un fait servi, pas par un front qui
        //    compterait des domaines vides.
        assertThat(plan.cycle().profileComplete()).isFalse();
        assertThat(plan.cycle().domainsEvaluated()).isEqualTo(1);
        assertThat(plan.cycle().domainsExpected()).isEqualTo(4);
    }

    // ------------------------------------------------------------------------
    // Fabriques
    // ------------------------------------------------------------------------

    /** Naturalisation : l'objectif du Plan vaut B2 parce que la demarche l'exige. */
    private User candidat() {
        User user = data.user();
        user.setTargetProcedure(TargetProcedure.NAT);
        user.setTargetLevel(TargetProcedure.NAT.getRequiredTcfLevel());
        return data.saveUser(user);
    }

    /**
     * Le resultat d'un diagnostic rapide : la session terminee et ses deux
     * analyses. Le pipeline d'analyse n'est pas rejoue ici — il appellerait un
     * LLM payant.
     */
    private void diagnosticRapide(User user, NiveauCecrl ecrit, NiveauCecrl oral) {
        DiagnosticSession session =
                data.diagnosticSession(user, DiagnosticSessionStatus.COMPLETED);
        data.diagnosticAnalysis(data.diagnosticSubmission(
                session.getWrittenAttempt(), session.getWrittenTask(), user), ecrit);
        data.diagnosticAnalysis(data.diagnosticSubmission(
                session.getOralAttempt(), session.getOralTask(), user), oral);
    }

    /**
     * Joue reellement l'examen blanc que le serveur vient de designer : on
     * repart de ses champs, sans en reinventer aucun. Toutes les questions sont
     * repondues (juste au A2, faux au-dessus) pour que l'epreuve compte comme
     * <b>reellement passee</b> — {@code TcfProfileService} ecarte les examens
     * finis sans une seule reponse.
     */
    private void jouer(User user, PlanDomainAssessmentDto assessment) {
        assertThat(assessment.kind()).isEqualTo(PlanDomainAssessmentKind.MODULE_MOCK_EXAM);
        AttemptResponse session = attemptService.start(user.getId(), new StartAttemptRequest(
                AttemptType.MOCK_EXAM, Module.TCF, null, null, null, null, null, null,
                assessment.moduleExamQuestionType(), assessment.slotNumber(), null));

        for (AttemptQuestion question
                : attemptQuestionManager.findByAttemptOrderedByPosition(session.id())) {
            UUID choix = question.getQuestion().getChoices().stream()
                    .filter(Choice::isCorrect)
                    .map(Choice::getId)
                    .findFirst()
                    .orElseThrow();
            attemptService.submitAnswer(user.getId(), session.id(),
                    new SubmitAnswerRequest(question.getId(), List.of(choix)));
        }
        attemptService.finish(user.getId(), session.id());
    }

    private void flush() {
        entityManager.flush();
        entityManager.clear();
    }

    private static PlanDomainDto domaine(LearningPlanDto plan, EpreuveType epreuve) {
        return plan.domaines().stream()
                .filter(item -> item.epreuve() == epreuve)
                .findFirst()
                .orElseThrow();
    }

    private static PlanDomainAssessmentDto assessment(
            LearningPlanDto plan, EpreuveType epreuve) {
        return plan.domainesAEvaluer().stream()
                .filter(item -> item.epreuve() == epreuve)
                .findFirst()
                .orElseThrow();
    }
}
