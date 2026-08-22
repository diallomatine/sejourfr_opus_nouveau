package com.sejourfr.app.service;

import com.sejourfr.app.dto.LearningPlanDto;
import com.sejourfr.app.dto.PlanDomainDto;
import com.sejourfr.app.dto.PlanDomainSkillDto;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.AttemptQuestion;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AttemptMode;
import com.sejourfr.app.enums.AttemptStatus;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.DiagnosticSessionStatus;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.PlanActionNature;
import com.sejourfr.app.enums.SkillMasteryState;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.manager.SkillManager;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * <b>Une epreuve, ses competences</b> : l'ecran « Mon diagnostic » se lit domaine
 * par domaine, et chaque domaine porte desormais la liste complete de ses
 * competences avec leur statut.
 *
 * <p>Ce qui ne se verifie qu'ici : la liste sort du <b>referentiel reellement
 * publie</b> (24 competences par epreuve d'expression, 3 paliers par domaine de
 * comprehension), les statuts sortent des vraies observations, et le
 * <b>cadenas</b> sort de {@code SkillAccessService} — pas d'un mock qui dirait ce
 * qu'on veut entendre.
 */
class LearningPlanDomainSkillsIT extends AbstractIntegrationTest {

    @Autowired private TestData data;
    @Autowired private LearningPlanService service;
    @Autowired private SkillManager skillManager;
    @Autowired private EntityManager entityManager;

    /**
     * Les quatre domaines portent leur referentiel, et les trois compteurs en
     * sont <b>derives</b> : leur somme vaut toujours la taille de la liste. C'est
     * cette egalite qui interdit a un front d'afficher un « + N » faux.
     */
    @Test
    @DisplayName("Les quatre domaines portent TOUTES leurs competences, et les compteurs somment")
    void lesQuatreDomainesPortentLeursCompetences() {
        User user = profilComplet();
        observation(user, seed("EE2-C1"), LearningPlanSourceType.PRODUCTION_EE,
                LearningPlanSkillStatus.TO_REINFORCE, jours(2));
        flush();

        LearningPlanDto plan = service.get(user.getId());

        assertThat(plan.domaines()).hasSize(4);
        assertThat(plan.domaines()).allSatisfy(domaine -> {
            assertThat(domaine.skills()).isNotNull().isNotEmpty();
            assertThat(domaine.skills()).allSatisfy(skill ->
                    assertThat(skill.status()).isNotNull());
            assertThat(domaine.fragileSkillCount()
                    + domaine.solidSkillCount()
                    + domaine.notObservedSkillCount())
                    .as("les trois compteurs sont derives de la liste, jamais recomptes ailleurs")
                    .isEqualTo(domaine.skills().size());
        });

        // Expression : les 3 taches x 8 competences, avec leur tache et leur numero.
        PlanDomainDto ee = domaine(plan, EpreuveType.TCF_EE);
        assertThat(ee.skills()).hasSize(24);
        assertThat(ee.skills()).allSatisfy(skill -> {
            assertThat(skill.section()).isEqualTo(SkillSection.EE);
            assertThat(skill.taskCode()).isNotNull();
            assertThat(skill.tacheNumero()).isNotNull();
        });
        assertThat(ee.fragileSkillCount()).isEqualTo(1);

        // Comprehension : une competence par palier, sans tache ni numero.
        PlanDomainDto co = domaine(plan, EpreuveType.TCF_CO);
        assertThat(co.skills()).extracting(PlanDomainSkillDto::skillCode)
                .containsExactly("CO-A2", "CO-B1", "CO-B2");
        assertThat(co.skills()).allSatisfy(skill -> {
            assertThat(skill.taskCode()).isNull();
            assertThat(skill.tacheNumero()).isNull();
        });
        assertThat(co.skills()).extracting(PlanDomainSkillDto::targetLevel)
                .containsExactly(TargetLevel.A2, TargetLevel.B1, TargetLevel.B2);
    }

    /**
     * L'ordre est <b>decide par le serveur</b> et deterministe : tache puis rang
     * d'affichage en expression, A2 &rarr; B1 &rarr; B2 en comprehension. Aucun
     * front ne retrie — deux copies designeraient deux ordres.
     */
    @Test
    @DisplayName("L'ordre des competences est celui du referentiel, et il ne bouge pas")
    void lOrdreDesCompetencesEstDeterministe() {
        User user = profilComplet();
        flush();

        List<PlanDomainSkillDto> eo = domaine(service.get(user.getId()), EpreuveType.TCF_EO).skills();

        assertThat(eo).extracting(PlanDomainSkillDto::taskCode)
                .startsWith(SkillTaskCode.EO1, SkillTaskCode.EO1)
                .endsWith(SkillTaskCode.EO3, SkillTaskCode.EO3);
        assertThat(eo).isSortedAccordingTo(Comparator
                .comparingInt((PlanDomainSkillDto skill) -> skill.taskCode().ordinal())
                .thenComparing(skill -> rang(skill.skillId())));
        assertThat(domaine(service.get(user.getId()), EpreuveType.TCF_EO).skills())
                .as("deux lectures rendent exactement la meme liste")
                .extracting(PlanDomainSkillDto::skillId)
                .isEqualTo(eo.stream().map(PlanDomainSkillDto::skillId).toList());
    }

    /**
     * 🛑 <i>null = inconnu, jamais mauvais.</i> Une competence jamais observee
     * n'est pas une faiblesse : elle n'a ni etat de maitrise, ni date, ni nature
     * — et surtout on ne lui en invente aucune pour remplir la colonne.
     */
    @Test
    @DisplayName("Une competence jamais observee : NOT_OBSERVED, et rien d'autre")
    void uneCompetenceJamaisObserveeNAffirmeRien() {
        User user = profilComplet();
        observation(user, seed("EE2-C1"), LearningPlanSourceType.PRODUCTION_EE,
                LearningPlanSkillStatus.TO_REINFORCE, jours(2));
        flush();

        PlanDomainSkillDto jamaisVue = skill(service.get(user.getId()), "EE1-C7");

        assertThat(jamaisVue.status()).isEqualTo(LearningPlanSkillStatus.NOT_OBSERVED);
        assertThat(jamaisVue.masteryState()).isNull();
        assertThat(jamaisVue.observedAt()).isNull();
        assertThat(jamaisVue.nature())
                .as("le Plan ne demande rien dessus : on ne fabrique pas une action")
                .isNull();
    }

    /**
     * Un domaine <b>jamais mesure</b> reste servi avec tout son referentiel : le
     * candidat doit voir ce qui l'attend, pas une carte vide.
     */
    @Test
    @DisplayName("Un domaine jamais evalue porte quand meme ses competences")
    void unDomaineJamaisEvalueGardeSonReferentiel() {
        User user = candidat();
        data.diagnosticSession(user, DiagnosticSessionStatus.COMPLETED);
        productionEvaluee(user, EpreuveType.TCF_EE, NiveauCecrl.A2);
        flush();

        PlanDomainDto ce = domaine(service.get(user.getId()), EpreuveType.TCF_CE);

        assertThat(ce.evaluated()).isFalse();
        assertThat(ce.niveau()).isNull();
        assertThat(ce.skills()).hasSize(3);
        assertThat(ce.notObservedSkillCount()).isEqualTo(3);
        assertThat(ce.skills()).allSatisfy(skill -> {
            assertThat(skill.status()).isEqualTo(LearningPlanSkillStatus.NOT_OBSERVED);
            assertThat(skill.masteryState()).isNull();
        });
    }

    /**
     * Le Plan sans diagnostic termine sert le meme ecran : tout le referentiel,
     * tout en {@code NOT_OBSERVED}. Un candidat qui ouvre son Plan le premier
     * jour voit ce qu'il y a a decouvrir.
     */
    @Test
    @DisplayName("Sans diagnostic termine, les quatre domaines portent deja leurs competences")
    void sansDiagnosticLesCompetencesSontDejaLa() {
        User user = candidat();
        flush();

        LearningPlanDto plan = service.get(user.getId());

        assertThat(plan.domaines()).hasSize(4);
        assertThat(plan.domaines()).allSatisfy(domaine -> {
            assertThat(domaine.skills()).isNotEmpty();
            assertThat(domaine.notObservedSkillCount()).isEqualTo(domaine.skills().size());
            assertThat(domaine.skills()).allSatisfy(skill ->
                    assertThat(skill.nature()).isNull());
        });
    }

    /**
     * Une competence <b>solide</b> n'est pas une action : elle est finie. Sa
     * nature reste nulle, quel que soit son etat de maitrise.
     */
    @Test
    @DisplayName("Une competence solide n'a aucune nature : il n'y a plus rien a y faire")
    void uneCompetenceSolideNEstPasUneAction() {
        User user = profilComplet();
        observation(user, seed("EE1-C1"), LearningPlanSourceType.PRODUCTION_EE,
                LearningPlanSkillStatus.SOLID, jours(20));
        observation(user, seed("EE1-C1"), LearningPlanSourceType.MOCK_EXAM_EE,
                LearningPlanSkillStatus.SOLID, jours(10));
        flush();

        PlanDomainSkillDto solide = skill(service.get(user.getId()), "EE1-C1");

        assertThat(solide.status()).isEqualTo(LearningPlanSkillStatus.SOLID);
        assertThat(solide.masteryState()).isEqualTo(SkillMasteryState.SOLID);
        assertThat(solide.observedAt()).isNotNull();
        assertThat(solide.nature()).isNull();
    }

    /**
     * Une fragilite observee porte la nature que la carte du Plan lui a deja
     * donnee : la liste par epreuve et les cartes ne peuvent pas se contredire.
     */
    @Test
    @DisplayName("Une fragilite porte la meme nature que sa carte du Plan")
    void uneFragilitePorteLaNatureDeSaCarte() {
        User user = profilComplet();
        observation(user, seed("EE2-C1"), LearningPlanSourceType.PRODUCTION_EE,
                LearningPlanSkillStatus.TO_REINFORCE, jours(2));
        flush();

        LearningPlanDto plan = service.get(user.getId());

        assertThat(plan.currentPriority().skillCode()).isEqualTo("EE2-C1");
        assertThat(skill(plan, "EE2-C1").nature())
                .isEqualTo(plan.currentPriority().nature())
                .isEqualTo(PlanActionNature.A_RENFORCER);
    }

    /**
     * Une competence retenue par {@link PlanAcquisitionSelector} ressort en
     * {@code A_ACQUERIR} — jamais « a renforcer » : renforcer suppose un constat
     * negatif, et il n'y en a aucun.
     */
    @Test
    @DisplayName("Une acquisition ressort A_ACQUERIR dans son domaine")
    void uneAcquisitionRessortAAcquerir() {
        User user = profilComplet();
        flush();

        LearningPlanDto plan = service.get(user.getId());

        assertThat(plan.currentPriority()).isNotNull();
        assertThat(plan.currentPriority().nature()).isEqualTo(PlanActionNature.A_ACQUERIR);
        String code = plan.currentPriority().skillCode();
        PlanDomainSkillDto acquise = skill(plan, code);
        assertThat(acquise.nature()).isEqualTo(PlanActionNature.A_ACQUERIR);
        assertThat(acquise.status())
                .as("rien n'a ete observe : la nature ne fabrique aucun verdict")
                .isEqualTo(LearningPlanSkillStatus.NOT_OBSERVED);
        assertThat(acquise.masteryState()).isNull();
    }

    /**
     * 🛑 Le cadenas vient de {@code SkillAccessService}, unique autorite : pour un
     * compte gratuit, la premiere competence de chaque tache est ouverte, plus
     * <b>la premiere place du Plan</b> ({@link PlanFocusResolver}) — ici une
     * fragilite de rang 3, que le verrou par tache aurait fermee.
     */
    @Test
    @DisplayName("Le cadenas suit SkillAccessService, la premiere place du Plan comprise")
    void leCadenasSuitLeServiceDAcces() {
        User user = profilComplet();
        observation(user, seed("EE2-C3"), LearningPlanSourceType.PRODUCTION_EE,
                LearningPlanSkillStatus.TO_REINFORCE, jours(2));
        flush();

        LearningPlanDto plan = service.get(user.getId());

        assertThat(plan.currentPriority().skillCode()).isEqualTo("EE2-C3");
        assertThat(skill(plan, "EE2-C3").locked())
                .as("la premiere place du Plan est toujours ouverte")
                .isFalse();
        assertThat(skill(plan, "EE2-C1").locked())
                .as("la premiere competence de chaque tache reste ouverte")
                .isFalse();
        assertThat(skill(plan, "EE2-C4").locked()).isTrue();
        assertThat(skill(plan, "CO-A2").locked()).isFalse();
        assertThat(skill(plan, "CO-B2").locked()).isTrue();
    }

    // ------------------------------------------------------------------------
    // Fabriques
    // ------------------------------------------------------------------------

    private static PlanDomainDto domaine(LearningPlanDto plan, EpreuveType epreuve) {
        return plan.domaines().stream()
                .filter(item -> item.epreuve() == epreuve)
                .findFirst()
                .orElseThrow();
    }

    private static PlanDomainSkillDto skill(LearningPlanDto plan, String code) {
        return plan.domaines().stream()
                .flatMap(domaine -> domaine.skills().stream())
                .filter(item -> code.equals(item.skillCode()))
                .findFirst()
                .orElseThrow();
    }

    private short rang(UUID skillId) {
        return skillManager.findById(skillId).orElseThrow().getDisplayOrder();
    }

    /** Un candidat visant le B2, sans acces TCF : le verrou freemium s'applique. */
    private User candidat() {
        User user = data.user();
        user.setTargetProcedure(TargetProcedure.NAT);
        user.setTargetLevel(TargetProcedure.NAT.getRequiredTcfLevel());
        return data.saveUser(user);
    }

    /** Le meme, dont les quatre domaines sont mesures et le diagnostic termine. */
    private User profilComplet() {
        User user = candidat();
        data.diagnosticSession(user, DiagnosticSessionStatus.COMPLETED);
        examenQcmPasse(user, EpreuveType.TCF_CO, NiveauCecrl.A2);
        examenQcmPasse(user, EpreuveType.TCF_CE, NiveauCecrl.A2);
        productionEvaluee(user, EpreuveType.TCF_EE, NiveauCecrl.A2);
        productionEvaluee(user, EpreuveType.TCF_EO, NiveauCecrl.A2);
        return user;
    }

    private void flush() {
        entityManager.flush();
        entityManager.clear();
    }

    private Skill seed(String code) {
        return skillManager.findByCode(code).orElseThrow();
    }

    private void examenQcmPasse(User user, EpreuveType epreuve, NiveauCecrl niveau) {
        Attempt attempt = data.attempt(user);
        attempt.setType(AttemptType.MOCK_EXAM);
        attempt.setModule(Module.TCF);
        attempt.setEpreuve(epreuve);
        attempt.setMode(AttemptMode.EXAMEN);
        attempt.setStatus(AttemptStatus.TERMINE);
        attempt.setFinishedAt(Instant.now());
        attempt.setCecrlLevel(niveau);
        AttemptQuestion question = data.attemptQuestion(attempt, data.question());
        data.answer(question);
    }

    private void productionEvaluee(User user, EpreuveType epreuve, NiveauCecrl niveau) {
        ProductionSubmission submission = data.productionSubmission(
                data.attempt(user), data.productionTask(epreuve), user);
        data.aiEvaluation(submission).setNiveauCecrl(niveau);
    }

    private void observation(
            User user, Skill skill, LearningPlanSourceType source,
            LearningPlanSkillStatus status, Instant quand) {
        data.learningPlanObservation(user, skill, source, status,
                ObservationConfidence.HIGH, UUID.randomUUID(), quand);
    }

    private static Instant jours(int nombre) {
        return Instant.now().minus(nombre, ChronoUnit.DAYS);
    }
}
