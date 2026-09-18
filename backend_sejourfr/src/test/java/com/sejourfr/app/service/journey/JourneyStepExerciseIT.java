package com.sejourfr.app.service.journey;

import com.sejourfr.app.dto.JourneyDto;
import com.sejourfr.app.dto.JourneyStepDto;
import com.sejourfr.app.dto.LearningPlanDto;
import com.sejourfr.app.dto.LearningPlanPriorityDto;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AttemptMode;
import com.sejourfr.app.enums.AttemptStatus;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.JourneyStepType;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.PlanExerciseKind;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.manager.SkillManager;
import com.sejourfr.app.service.AccountDeletionService;
import com.sejourfr.app.service.LearningPlanService;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import org.hibernate.SessionFactory;
import org.hibernate.stat.Statistics;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * <b>L'exercice d'une etape de competence est SERVI</b> — et ce qu'il coute.
 *
 * <h2>Le cul-de-sac que ce champ ferme</h2>
 * <p>Jusqu'ici les fronts cherchaient l'action d'une etape {@code TRAIN_SKILL}
 * dans les <b>priorites</b> du Plan ({@code currentPriority} +
 * {@code nextPriorities}). Cette liste est <b>plafonnee</b> a
 * {@code display.prioritiesMaxActions} (5). Un cycle portant six competences ou
 * plus avait donc des etapes dont l'action n'etait servie <b>nulle part</b>, et
 * le garde-fou du depot (« une carte ne lance jamais autre chose que l'etape
 * qu'elle annonce », A25) rendait la ligne <b>sans bouton</b>. Correct comme
 * garde-fou, cul-de-sac comme resultat : c'est ce que le proprietaire voyait sur
 * l'expression ecrite.
 *
 * <p>C'est mot pour mot le raisonnement d'A24 pour les etapes d'EXAMEN : la
 * liste des priorites est une <b>vue bornee</b>, la file ne l'est pas.
 *
 * <h2>🛑 Et le prix ne bouge pas</h2>
 * <p>Le second test verrouille le cout par une <b>egalite</b>, jamais par un
 * {@code <=} : c'est la seule facon d'attraper un N+1. Meme jeu d'epreuves des
 * deux cotes — seul le nombre d'etapes change —, sinon on mesurerait le prix des
 * blocs plutot que celui des exercices.
 *
 * <p>Non transactionnel, comme {@link JourneyProgressionIT} : le service ecrit
 * en {@link Propagation#REQUIRES_NEW}.
 */
@Transactional(propagation = Propagation.NOT_SUPPORTED)
class JourneyStepExerciseIT extends AbstractIntegrationTest {

    @Autowired private JourneyService journeyService;
    @Autowired private LearningPlanService planService;
    @Autowired private TestData data;
    @Autowired private SkillManager skillManager;
    @Autowired private AccountDeletionService accountDeletionService;
    @Autowired private EntityManager entityManager;

    private final List<UUID> candidats = new ArrayList<>();

    private static final Instant HIER = Instant.now().minusSeconds(86_400);

    @AfterEach
    void menage() {
        candidats.forEach(id -> accountDeletionService.deleteAccount(id));
        candidats.clear();
    }

    /**
     * Huit competences dans le cycle, cinq places dans les priorites : au moins
     * trois etapes sont <b>hors de la fenetre</b>. Elles portent quand meme leur
     * exercice, et c'est tout l'objet du champ.
     */
    @Test
    @DisplayName("A26 — une etape HORS des 5 priorites du Plan porte quand meme son exercice")
    void uneEtapeHorsDesPrioritesPorteSonExercice() {
        User user = abonne();
        peupler(user, 3, 3, 2);

        JourneyDto vue = journeyService.lire(user.getId());
        LearningPlanDto plan = planService.get(user.getId());
        List<String> servies = prioritesServies(plan);
        List<JourneyStepDto> competences = etapesDeCompetence(vue);

        assertThat(competences).hasSize(8);
        // La fenetre est bien plus courte que le cycle : c'est la condition du
        // defaut, et sans elle ce test ne prouverait rien.
        assertThat(servies).hasSizeLessThan(competences.size());
        List<JourneyStepDto> horsFenetre = competences.stream()
                .filter(step -> !servies.contains(step.skillCode()))
                .toList();
        assertThat(horsFenetre)
                .as("au moins une etape que les priorites ne portent pas")
                .isNotEmpty();

        // 🛑 Chacune porte SON exercice, sur SA competence — jamais celui d'une
        // autre, ce que le repli sur `currentPriority` faisait.
        assertThat(horsFenetre).allSatisfy(step -> {
            assertThat(step.exercise())
                    .as("exercice servi sur " + step.skillCode())
                    .isNotNull();
            assertThat(step.exercise().skillCode()).isEqualTo(step.skillCode());
            assertThat(step.exercise().kind()).isEqualTo(step.taskCode() == null
                    ? PlanExerciseKind.TARGETED_QCM_SERIES : PlanExerciseKind.MICRO_TRAINING);
        });

        // Une etape d'examen n'en porte aucun : elle porte `assessment`.
        assertThat(vue.blocs()).allSatisfy(bloc -> {
            if (bloc.exam() != null) assertThat(bloc.exam().exercise()).isNull();
        });
    }

    /**
     * 🛑 <b>UN SEUL LOT</b> : le meme jeu d'epreuves des deux cotes, deux etapes
     * d'un cote et huit de l'autre, et <b>exactement</b> le meme nombre de
     * requetes. Un appel par etape aurait fait grimper le compte de six.
     */
    @Test
    @DisplayName("A26 — le cout de la lecture ne bouge pas de 2 a 8 etapes de competence")
    void leCoutNeBougePasAvecLeNombreDEtapes() {
        User petit = abonne();
        peupler(petit, 1, 1, 1);
        User grand = abonne();
        peupler(grand, 3, 3, 2);

        assertThat(etapesDeCompetence(journeyService.lire(petit.getId()))).hasSize(3);
        assertThat(etapesDeCompetence(journeyService.lire(grand.getId()))).hasSize(8);

        assertThat(requetes(grand))
                .as("le lot d'exercices est UNIQUE : le prix ne suit pas la taille du cycle")
                .isEqualTo(requetes(petit));
    }

    // ------------------------------------------------------------------ outils

    private long requetes(User user) {
        entityManager.clear();
        Statistics statistics = entityManager.getEntityManagerFactory()
                .unwrap(SessionFactory.class).getStatistics();
        statistics.setStatisticsEnabled(true);
        statistics.clear();
        journeyService.lire(user.getId());
        return statistics.getPrepareStatementCount();
    }

    /**
     * Un parcours reel de trois epreuves, avec le nombre de priorites demande.
     *
     * <p>🛑 <b>Tout est ecrit AVANT la premiere lecture</b>, et c'est
     * volontaire : le cycle est <b>borne</b> (D-13), un cycle amorce ne grossit
     * plus. Une evaluation qui arriverait apres l'amorce irait dans le cycle
     * <b>en attente</b> — invisible — et le cycle courant n'aurait qu'une
     * epreuve. C'est donc le <b>bootstrap</b> (R19, une evaluation de reference
     * par epreuve) qui construit la file, exactement comme pour un candidat qui
     * ouvre son Plan apres plusieurs examens.
     *
     * <p>🛑 <b>Les trois memes epreuves pour tout le monde</b> : le cout par
     * epreuve (verrou de production, « jamais mesuree ») ne doit pas polluer la
     * mesure du second test.
     */
    private void peupler(User user, int ee, int eo, int ce) {
        evaluation(user, EpreuveType.TCF_EE, LearningPlanSourceType.MOCK_EXAM_EE,
                expression(SkillTaskCode.EE1, ee));
        evaluation(user, EpreuveType.TCF_EO, LearningPlanSourceType.MOCK_EXAM_EO,
                expression(SkillTaskCode.EO1, eo));
        evaluation(user, EpreuveType.TCF_CE, LearningPlanSourceType.TCF_CE,
                comprehension(SkillSection.CE, ce));
    }

    private void evaluation(User user, EpreuveType epreuve,
                            LearningPlanSourceType source, List<Skill> competences) {
        UUID examen = examenBlanc(user, epreuve);
        competences.forEach(skill -> data.learningPlanObservation(
                user, skill, source, LearningPlanSkillStatus.PRIORITY,
                ObservationConfidence.HIGH, null, HIER, examen));
    }

    private UUID examenBlanc(User user, EpreuveType epreuve) {
        Attempt attempt = data.attempt(user);
        attempt.setType(AttemptType.MOCK_EXAM);
        attempt.setModule(Module.TCF);
        attempt.setEpreuve(epreuve);
        attempt.setMode(AttemptMode.EXAMEN);
        attempt.setStatus(AttemptStatus.TERMINE);
        attempt.setFinishedAt(HIER);
        return data.saveAttempt(attempt).getId();
    }

    /**
     * Des competences du <b>referentiel seede</b>, jamais creees : ces tests ne
     * sont pas transactionnels, et une competence creee survivrait a la classe.
     */
    private List<Skill> expression(SkillTaskCode tache, int combien) {
        List<Skill> seedees = skillManager.findActiveByTaskCode(tache);
        assertThat(seedees).as("referentiel seede " + tache).hasSizeGreaterThanOrEqualTo(combien);
        return seedees.subList(0, combien);
    }

    private List<Skill> comprehension(SkillSection section, int combien) {
        List<Skill> seedees = skillManager.findAllComprehensionBySection(section);
        assertThat(seedees).as("referentiel seede " + section).hasSizeGreaterThanOrEqualTo(combien);
        return seedees.subList(0, combien);
    }

    private static List<JourneyStepDto> etapesDeCompetence(JourneyDto vue) {
        return vue.blocs().stream()
                .flatMap(bloc -> bloc.steps().stream())
                .filter(step -> step.type() == JourneyStepType.TRAIN_SKILL)
                .toList();
    }

    private static List<String> prioritesServies(LearningPlanDto plan) {
        List<String> codes = new ArrayList<>();
        if (plan.currentPriority() != null) codes.add(plan.currentPriority().skillCode());
        plan.nextPriorities().stream()
                .map(LearningPlanPriorityDto::skillCode)
                .forEach(codes::add);
        return codes;
    }

    private User abonne() {
        User user = data.user();
        candidats.add(user.getId());
        user.setTargetProcedure(TargetProcedure.NAT);
        user.setTargetLevel(TargetProcedure.NAT.getRequiredTcfLevel());
        User sauve = data.saveUser(user);
        data.userSubscription(sauve, data.plan());
        return sauve;
    }
}
