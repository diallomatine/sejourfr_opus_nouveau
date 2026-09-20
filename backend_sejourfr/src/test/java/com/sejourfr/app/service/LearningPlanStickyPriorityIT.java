package com.sejourfr.app.service;

import com.sejourfr.app.dto.LearningPlanDto;
import com.sejourfr.app.dto.LearningPlanPriorityDto;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.AttemptQuestion;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.SkillPrompt;
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
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.manager.PlanPinnedPriorityManager;
import com.sejourfr.app.manager.SkillPromptManager;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * <b>La priorite courante est EPINGLEE</b> : une nouvelle observation ne la
 * remplace pas tant que l'etape n'est pas sortie de son cycle.
 *
 * <h2>Le defaut corrige (2026-09-13)</h2>
 * L'ordre des priorites se recalculait entierement a chaque lecture, et son
 * dernier critere est la <b>recence</b>. Une production rendue sur une
 * <i>autre</i> competence prenait donc la premiere place par sa seule
 * fraicheur. Cas reel : EE3 « Developper un argument » affichee a <b>0/5</b>,
 * remplacee par EO1 « Raconter brievement une experience passee » des la
 * premiere production orale — l'etape commencee disparaissait de l'ecran au
 * milieu de son cycle.
 *
 * <h2>Ce qui se verifie ici, et nulle part ailleurs</h2>
 * Le cycle complet contre la <b>vraie base</b> : micro-entrainement &rarr; 5/5
 * &rarr; « a verifier » &rarr; verification rendue &rarr; promotion de la
 * suivante. Les tests unitaires de {@code PlanFocusResolverTest} decrivent la
 * regle sur des listes ; celui-ci verifie qu'elle survit au Plan entier — au
 * classement, au filtre de contenu, aux acquisitions et aux compteurs d'etape.
 *
 * <p>🛑 <b>La file d'attente n'est pas persistee</b>, et ces tests le
 * verrouillent : elle se relit du classement a chaque lecture, sans doublon par
 * construction. Seule la premiere place a une ligne en base.
 */
class LearningPlanStickyPriorityIT extends AbstractIntegrationTest {

    @Autowired private TestData data;
    @Autowired private LearningPlanService service;
    @Autowired private PlanPinnedPriorityManager pinManager;
    @Autowired private SkillPromptManager promptManager;
    @Autowired private EntityManager entityManager;

    /**
     * 🛑 LE CAS SIGNALE. L'etape en cours est a 0/5 — rien ne permet de la
     * retrouver dans les donnees de pratique — et c'est bien pour cela que la
     * premiere place s'ecrit.
     */
    @Test
    @DisplayName("Une nouvelle faiblesse observee ne remplace pas l'etape en cours")
    void uneNouvelleFaiblesseNeRemplacePasLetapeEnCours() {
        User user = candidat();
        Skill ee3 = competenceAvecSujets(SkillTaskCode.EE3, 5);
        Skill eo1 = competenceAvecSujets(SkillTaskCode.EO1, 5);
        fragilite(user, ee3, LearningPlanSourceType.PRODUCTION_EE, jours(2));
        flush();

        LearningPlanDto avant = service.get(user.getId());
        assertThat(avant.currentPriority().skillCode()).isEqualTo(ee3.getCode());
        assertThat(avant.currentPriority().stepAttemptedCount()).isZero();

        // La production EO1 arrive : plus recente, donc en tete du classement.
        fragilite(user, eo1, LearningPlanSourceType.PRODUCTION_EO, Instant.now());
        flush();

        LearningPlanDto apres = service.get(user.getId());
        assertThat(apres.currentPriority().skillCode())
                .as("l'etape en cours ne se fait pas doubler par une observation plus recente")
                .isEqualTo(ee3.getCode());
        assertThat(codes(apres.nextPriorities()))
                .as("la nouvelle faiblesse n'est pas perdue : elle entre dans la file")
                .contains(eo1.getCode());
    }

    /**
     * La file est <b>derivee</b>, donc sans doublon par construction : le
     * classement ne connait qu'une action par competence. Une seconde production
     * sur la meme competence met la ligne a jour, elle n'en ajoute pas une.
     */
    @Test
    @DisplayName("Une faiblesse deja en file ne s'y ajoute pas deux fois")
    void uneFaiblesseDejaEnFileNeSeDedoublePas() {
        User user = candidat();
        Skill ee3 = competenceAvecSujets(SkillTaskCode.EE3, 5);
        Skill eo1 = competenceAvecSujets(SkillTaskCode.EO1, 5);
        fragilite(user, ee3, LearningPlanSourceType.PRODUCTION_EE, jours(3));
        flush();
        premierePlace(user, ee3);

        // Deux productions EO1 de suite : deux observations, une seule ligne.
        fragilite(user, eo1, LearningPlanSourceType.PRODUCTION_EO, jours(2));
        fragilite(user, eo1, LearningPlanSourceType.PRODUCTION_EO, jours(1));
        flush();

        LearningPlanDto plan = service.get(user.getId());

        assertThat(plan.currentPriority().skillCode()).isEqualTo(ee3.getCode());
        assertThat(codes(plan.nextPriorities()).stream().filter(eo1.getCode()::equals).count())
                .as("une competence, une ligne")
                .isEqualTo(1);
        assertThat(codes(plan.nextPriorities()))
                .doesNotContain(plan.currentPriority().skillCode());
    }

    /**
     * 🛑 5/5 SEULE NE LIBERE RIEN. L'etape change de <b>nature</b> — elle passe
     * a {@code A_VERIFIER}, dont le poids (800) est inferieur a
     * {@code A_RENFORCER} (1000) — et c'est precisement la que le classement
     * seul la ferait doubler par n'importe quelle fragilite fraiche. L'epingle
     * passe avant le score.
     */
    @Test
    @DisplayName("Serie terminee : la priorite passe a verifier, elle n'est pas remplacee")
    void cinqSurCinqNeLibereRien() {
        User user = candidat();
        Skill ee3 = competenceAvecSujets(SkillTaskCode.EE3, 5);
        Skill eo1 = competenceAvecSujets(SkillTaskCode.EO1, 5);
        fragilite(user, ee3, LearningPlanSourceType.PRODUCTION_EE, jours(3));
        flush();
        premierePlace(user, ee3);

        cinqPetitsSujetsRealises(user, ee3);
        // Une faiblesse fraiche ailleurs, exactement au mauvais moment.
        fragilite(user, eo1, LearningPlanSourceType.PRODUCTION_EO, Instant.now());
        flush();

        LearningPlanPriorityDto courante = service.get(user.getId()).currentPriority();

        assertThat(courante.skillCode()).isEqualTo(ee3.getCode());
        assertThat(courante.stepCompleted()).isTrue();
        assertThat(courante.stepAttemptedCount()).isEqualTo(courante.stepPromptCount());
        assertThat(courante.nature())
                .as("la serie est finie : la meme carte demande desormais une verification")
                .isEqualTo(PlanActionNature.A_VERIFIER);
    }

    /**
     * <b>La sortie de cycle est la verification RENDUE, pas {@code SOLID}.</b>
     * Une competence encore fragile revient plus tard selon les regles du
     * moteur ; elle n'est simplement plus interrompue au milieu.
     */
    @Test
    @DisplayName("Verification rendue : l'epingle est liberee et la meilleure en attente promue")
    void laVerificationRenduePromeutLaSuivante() {
        User user = candidat();
        Skill ee3 = competenceAvecSujets(SkillTaskCode.EE3, 5);
        Skill eo1 = competenceAvecSujets(SkillTaskCode.EO1, 5);
        fragilite(user, ee3, LearningPlanSourceType.PRODUCTION_EE, jours(5));
        flush();
        premierePlace(user, ee3);

        cinqPetitsSujetsRealises(user, ee3);
        fragilite(user, eo1, LearningPlanSourceType.PRODUCTION_EO, jours(3));
        flush();
        premierePlace(user, ee3);

        // La verification en situation est rendue — et elle ECHOUE : la
        // competence n'est pas SOLID, et elle sort quand meme du chemin
        // critique. Verifier n'est pas reussir, mais c'est avancer.
        observation(user, ee3, LearningPlanSourceType.PRODUCTION_EE,
                LearningPlanSkillStatus.TO_REINFORCE, Instant.now());
        flush();

        LearningPlanDto apres = service.get(user.getId());
        assertThat(apres.currentPriority().skillCode())
                .as("l'etape suivante prend la premiere place")
                .isEqualTo(eo1.getCode());
        assertThat(apres.currentPriority().masteryState())
                .as("la promotion n'attend pas que la precedente soit SOLID")
                .isNotNull();
        assertThat(pinManager.find(user.getId()).orElseThrow().getSkill().getCode())
                .isEqualTo(eo1.getCode());
    }

    /**
     * Une reussite en situation prouve le transfert : la competence quitte les
     * priorites pour les <b>etapes franchies</b>, et l'epingle la suit. C'est le
     * complement de {@link #laVerificationRenduePromeutLaSuivante} — la meme
     * sortie de pool, par l'autre voie.
     */
    @Test
    @DisplayName("Transfert prouve : la competence quitte les priorites, l'epingle aussi")
    void leTransfertProuveLibereLepingle() {
        User user = candidat();
        Skill ee3 = competenceAvecSujets(SkillTaskCode.EE3, 5);
        Skill eo1 = competenceAvecSujets(SkillTaskCode.EO1, 5);
        fragilite(user, ee3, LearningPlanSourceType.PRODUCTION_EE, jours(4));
        flush();
        premierePlace(user, ee3);

        fragilite(user, eo1, LearningPlanSourceType.PRODUCTION_EO, jours(3));
        flush();
        premierePlace(user, ee3);

        observation(user, ee3, LearningPlanSourceType.PRODUCTION_EE,
                LearningPlanSkillStatus.SOLID, Instant.now());
        flush();

        LearningPlanDto apres = service.get(user.getId());
        assertThat(apres.currentPriority().skillCode()).isEqualTo(eo1.getCode());
        assertThat(codes(apres.nextPriorities())).doesNotContain(ee3.getCode());
        assertThat(apres.completedSteps())
                .extracting(step -> step.skillCode())
                .contains(ee3.getCode());
    }

    /**
     * Deux lectures sans action du candidat rendent le meme ecran, et
     * n'ecrivent rien de plus : {@code pinned_at} date la <b>prise</b> de la
     * premiere place, pas la derniere consultation.
     */
    @Test
    @DisplayName("Relire le Plan ne redate pas l'epingle")
    void relireLePlanNeRedatePasLepingle() {
        User user = candidat();
        Skill ee3 = competenceAvecSujets(SkillTaskCode.EE3, 5);
        fragilite(user, ee3, LearningPlanSourceType.PRODUCTION_EE, jours(2));
        flush();

        service.get(user.getId());
        flush();
        Instant premiere = pinManager.find(user.getId()).orElseThrow().getPinnedAt();
        service.get(user.getId());
        flush();

        assertThat(pinManager.find(user.getId()).orElseThrow().getPinnedAt())
                .isEqualTo(premiere);
    }

    // ------------------------------------------------------------------------
    // Fabriques
    // ------------------------------------------------------------------------

    /**
     * Une lecture du Plan qui <b>designe</b> la premiere place, et la verifie.
     *
     * <p>Elle est indispensable a la mise en place de ces scenarios : l'epingle
     * se prend a la lecture, donc une etape « en cours » suppose qu'elle ait ete
     * affichee au moins une fois. C'est aussi le parcours reel — le candidat
     * ouvre son Plan, <b>puis</b> produit.
     */
    private void premierePlace(User user, Skill attendue) {
        assertThat(service.get(user.getId()).currentPriority().skillCode())
                .isEqualTo(attendue.getCode());
        flush();
    }

    private void flush() {
        entityManager.flush();
        entityManager.clear();
    }

    /** Un candidat NAT dont les quatre domaines sont mesures : le Plan est ACTIVE. */
    private User candidat() {
        User user = data.user();
        user.setTargetProcedure(TargetProcedure.NAT);
        user.setTargetLevel(TargetProcedure.NAT.getRequiredTcfLevel());
        user = data.saveUser(user);
        data.diagnosticSession(user, DiagnosticSessionStatus.COMPLETED);
        examenQcmPasse(user, EpreuveType.TCF_CO, NiveauCecrl.B1);
        examenQcmPasse(user, EpreuveType.TCF_CE, NiveauCecrl.B1);
        productionEvaluee(user, EpreuveType.TCF_EE, NiveauCecrl.B1);
        productionEvaluee(user, EpreuveType.TCF_EO, NiveauCecrl.B1);
        return user;
    }

    /**
     * Une competence et ses petits sujets. Le <b>filtre de faisabilite</b> du
     * Plan ecarte une competence d'expression sans sujet publie : sans eux, la
     * fragilite n'aurait aucune carte et ce test ne mesurerait rien.
     */
    private Skill competenceAvecSujets(SkillTaskCode taskCode, int sujets) {
        Skill skill = data.skill(taskCode);
        for (int rang = 0; rang < sujets; rang++) {
            data.skillPrompt(skill);
        }
        return skill;
    }

    /**
     * L'etape entiere realisee : ses cinq sujets <b>traites</b> — donc
     * {@code stepCompleted} — et les cinq observations ciblees qui vont avec.
     *
     * <p>Les deux sont necessaires et ne disent pas la meme chose. Les
     * {@code user_skill_attempts} font l'anneau « 5/5 »
     * ({@code SkillProgressCounter}) ; les observations {@code SKILL_TRAINING}
     * font la <b>date du dernier micro-entrainement</b>, sans laquelle le moteur
     * de maitrise ne peut pas voir qu'une contextualisee lui succede — c'est
     * exactement sa definition de « la verification a ete rendue ».
     */
    private void cinqPetitsSujetsRealises(User user, Skill skill) {
        for (SkillPrompt prompt : promptManager.findActiveBySkillId(skill.getId())) {
            data.userSkillAttempt(user, prompt);
            observation(user, skill, LearningPlanSourceType.SKILL_TRAINING,
                    LearningPlanSkillStatus.TO_REINFORCE, jours(2));
        }
    }

    private void fragilite(User user, Skill skill, LearningPlanSourceType source, Instant quand) {
        observation(user, skill, source, LearningPlanSkillStatus.TO_REINFORCE, quand);
    }

    private void observation(User user, Skill skill, LearningPlanSourceType source,
                             LearningPlanSkillStatus status, Instant quand) {
        data.learningPlanObservation(user, skill, source, status,
                ObservationConfidence.HIGH, UUID.randomUUID(), quand);
    }

    /**
     * 🛑 Delegue a {@code TestData.examenQcmTcfPasse} : depuis la suppression de
     * {@code attempts.cecrl_level}, le palier d'une epreuve QCM se DEMONTRE par
     * ses reponses, il ne se declare plus. Ce helper vivait en quatre copies.
     */
    private void examenQcmPasse(User user, EpreuveType epreuve, NiveauCecrl niveau) {
        data.examenQcmTcfPasse(user, epreuve, niveau);
    }

    private void productionEvaluee(User user, EpreuveType epreuve, NiveauCecrl niveau) {
        ProductionSubmission submission = data.productionSubmission(
                data.attempt(user), data.productionTask(epreuve), user);
        data.aiEvaluation(submission).setNiveauCecrl(niveau);
    }

    private static List<String> codes(List<LearningPlanPriorityDto> priorites) {
        return priorites.stream().map(LearningPlanPriorityDto::skillCode).toList();
    }

    private static Instant jours(int nombre) {
        return Instant.now().minus(nombre, ChronoUnit.DAYS);
    }
}
