package com.sejourfr.app.service.journey;

import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.enums.AttemptMode;
import com.sejourfr.app.enums.AttemptStatus;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.dto.JourneyDto;
import com.sejourfr.app.dto.JourneyStepDto;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.SkillPrompt;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.JourneyAssessmentKind;
import com.sejourfr.app.enums.JourneyProgressUnit;
import com.sejourfr.app.enums.JourneyState;
import com.sejourfr.app.enums.JourneyStepStatus;
import com.sejourfr.app.enums.JourneyStepType;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.service.LearningPlanStep;
import com.sejourfr.app.manager.SkillManager;
import com.sejourfr.app.service.AccountDeletionService;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * <b>Ce qu'un entrainement fait au parcours — et ce qu'il ne fait jamais.</b>
 *
 * <p>Deux regles se rencontrent ici, et elles sont faciles a confondre :
 * <ul>
 *   <li><b>R1 / D-6</b> : un entrainement ne <b>cree</b> jamais d'etape ;</li>
 *   <li><b>R8 / D-5</b> : il peut en <b>clore</b> une, et le quota n'a pas la
 *       meme unite selon la famille — 5 petits sujets en expression,
 *       {@code trainSeriesQuota} series ciblees en comprehension.</li>
 * </ul>
 *
 * <p>Non transactionnel, pour la meme raison que {@link JourneyServiceIT} : le
 * service ecrit en {@link Propagation#REQUIRES_NEW}, et une transaction de test
 * l'empecherait de voir ce que le test vient d'ecrire.
 */
@Transactional(propagation = Propagation.NOT_SUPPORTED)
class JourneyProgressionIT extends AbstractIntegrationTest {

    @Autowired private JourneyService journeyService;
    @Autowired private TcfJourneyConfig config;
    @Autowired private TestData data;
    @Autowired private SkillManager skillManager;
    @Autowired private com.sejourfr.app.manager.SkillPromptManager promptManager;
    @Autowired private AccountDeletionService accountDeletionService;

    private final List<UUID> candidats = new java.util.ArrayList<>();

    /**
     * Menage a la main : ces tests ne sont pas transactionnels, donc rien ne se
     * defait tout seul. Chaque candidat cree est supprime — et avec lui son
     * parcours, ses lots, ses etapes, son journal et ses observations.
     */
    @AfterEach
    void menage() {
        candidats.forEach(id -> accountDeletionService.deleteAccount(id));
        candidats.clear();
    }

    private static final Instant HIER = Instant.now().minusSeconds(86_400);

    // =====================================================================
    // R1 — un entrainement ne cree jamais d'etape
    // =====================================================================

    @Test
    @DisplayName("§18-4 — une faiblesse detectee par un entrainement n'ajoute AUCUNE etape")
    void unEntrainementNAjouteJamaisDEtape() {
        User user = candidat();
        Skill duParcours = skill(SkillTaskCode.EE1, 0);
        UUID examen = UUID.randomUUID();
        observationDExamen(user, duParcours, examen);
        List<JourneyStepDto> avant = journeyService.lire(user.getId(), true).steps();

        // Un petit sujet revele une fragilite sur une TOUTE AUTRE competence.
        Skill revelee = skill(SkillTaskCode.EE1, 1);
        data.learningPlanObservation(user, revelee, LearningPlanSourceType.SKILL_TRAINING,
                LearningPlanSkillStatus.PRIORITY, ObservationConfidence.HIGH, null,
                Instant.now());
        journeyService.onTrainingProgress(user.getId(), List.of(revelee.getId()));

        List<JourneyStepDto> apres = journeyService.lire(user.getId(), true).steps();
        // 🛑 Elle entrera dans le Plan si une EVALUATION la detecte. Pas avant.
        assertThat(apres).hasSameSizeAs(avant);
        assertThat(apres.stream().map(JourneyStepDto::skillCode))
                .doesNotContain(revelee.getCode());
    }

    // =====================================================================
    // R8 — cloture d'une etape d'entrainement
    // =====================================================================

    @Test
    @DisplayName("§18-6 — expression : les 5 sujets de l'etape traites la closent (QUOTA_REACHED)")
    void lesCinqSujetsTraitesClosentLEtapeDExpression() {
        User user = abonne();
        Skill skill = skill(SkillTaskCode.EE1);
        List<SkillPrompt> sujets = sujetsDeLEtape(skill);
        observationDExamen(user, skill, UUID.randomUUID());
        JourneyDto avant = journeyService.lire(user.getId(), true);
        assertThat(progressionDe(avant, skill))
                .isEqualTo(new JourneyStepDto.JourneyProgressDto(
                        0, sujets.size(), JourneyProgressUnit.PROMPT));

        sujets.forEach(sujet -> data.userSkillAttempt(user, sujet));
        journeyService.onTrainingProgress(user.getId(), List.of(skill.getId()));

        JourneyDto apres = journeyService.lire(user.getId(), true);
        // « Traites, pas valides » : on peut terminer une etape sans tout
        // reussir, et on ne bloque jamais un candidat sur une competence non
        // maitrisee — l'examen decidera si elle revient.
        assertThat(etapeDe(apres, skill).status())
                .isIn(JourneyStepStatus.COMPLETED, JourneyStepStatus.SKIPPED);
    }

    @Test
    @DisplayName("§18-32 / §18-41 — comprehension : le quota se compte en SERIES, pas en sujets")
    void leQuotaDeComprehensionSeCompteEnSeries() {
        User user = abonne();
        Skill skill = comprehension(SkillSection.CO);
        UUID examen = examenBlanc(user, EpreuveType.TCF_CO);
        data.learningPlanObservation(user, skill, LearningPlanSourceType.TCF_CO,
                LearningPlanSkillStatus.PRIORITY, ObservationConfidence.HIGH, null, HIER, examen);
        journeyService.onAssessmentCompleted(user.getId(), new JourneyEvaluation(
                examen, JourneyAssessmentKind.SECTION_EXAM, EpreuveType.TCF_CO, HIER));

        JourneyDto ouverte = journeyService.lire(user.getId(), true);
        JourneyStepDto etape = etapeDe(ouverte, skill);
        // 🛑 L'unite est SERVIE : un front n'a pas a la deduire de la nullite de
        // taskCode. Les competences CO/CE n'ont ni tache ni petit sujet.
        assertThat(etape.taskCode()).isNull();
        assertThat(etape.progress().unit()).isEqualTo(JourneyProgressUnit.SERIES);
        assertThat(etape.progress().quota()).isEqualTo(config.trainSeriesQuota());
        assertThat(etape.progress().done()).isZero();

        // Deux series ciblees terminees apres la creation de l'etape.
        for (int i = 0; i < config.trainSeriesQuota(); i++) {
            data.learningPlanObservation(user, skill, LearningPlanSourceType.TCF_CO,
                    LearningPlanSkillStatus.TO_REINFORCE, ObservationConfidence.MEDIUM, null,
                    Instant.now(), UUID.randomUUID());
        }
        journeyService.onTrainingProgress(user.getId(), List.of(skill.getId()));

        assertThat(etapeDe(journeyService.lire(user.getId(), true), skill).status())
                .isIn(JourneyStepStatus.COMPLETED, JourneyStepStatus.SKIPPED);
    }

    @Test
    @DisplayName("§18-42 — une cloture ne se reouvre JAMAIS, meme si la fragilite revient")
    void uneClotureNeSeReouvreJamais() {
        User user = abonne();
        Skill skill = comprehension(SkillSection.CE);
        UUID examen = examenBlanc(user, EpreuveType.TCF_CE);
        data.learningPlanObservation(user, skill, LearningPlanSourceType.TCF_CE,
                LearningPlanSkillStatus.PRIORITY, ObservationConfidence.HIGH, null, HIER, examen);
        journeyService.onAssessmentCompleted(user.getId(), new JourneyEvaluation(
                examen, JourneyAssessmentKind.SECTION_EXAM, EpreuveType.TCF_CE, HIER));
        for (int i = 0; i < config.trainSeriesQuota(); i++) {
            data.learningPlanObservation(user, skill, LearningPlanSourceType.TCF_CE,
                    LearningPlanSkillStatus.TO_REINFORCE, ObservationConfidence.MEDIUM, null,
                    Instant.now(), UUID.randomUUID());
        }
        journeyService.onTrainingProgress(user.getId(), List.of(skill.getId()));
        JourneyStepDto close = etapeDe(journeyService.lire(user.getId(), true), skill);
        assertThat(close.status()).isIn(JourneyStepStatus.COMPLETED, JourneyStepStatus.SKIPPED);

        // La competence redevient fragile : de nouvelles series, un nouveau
        // verdict PRIORITY.
        data.learningPlanObservation(user, skill, LearningPlanSourceType.TCF_CE,
                LearningPlanSkillStatus.PRIORITY, ObservationConfidence.HIGH, null,
                Instant.now(), UUID.randomUUID());
        journeyService.onTrainingProgress(user.getId(), List.of(skill.getId()));

        // 🛑 L'etape reste close : elle reviendra par un EXAMEN (R7), pas par un
        // entrainement. C'est ce qui empeche le parcours de tourner en rond.
        assertThat(etapeDe(journeyService.lire(user.getId(), true), skill).status())
                .isEqualTo(close.status());
    }

    // =====================================================================
    // D-1 — CURRENT est la premiere etape EXECUTABLE
    // =====================================================================

    @Test
    @DisplayName("§18-34 — compte gratuit : l'etape non finissable reste AFFICHEE, cadenassee")
    void uneEtapeNonFinissableResteAfficheeMaisNePrendPasLaMain() {
        User gratuit = candidat();
        Skill premiere = skill(SkillTaskCode.EE1, 0);
        Skill seconde = skill(SkillTaskCode.EE1, 1);
        UUID examen = UUID.randomUUID();
        observationDExamen(gratuit, premiere, examen);
        observationDExamen(gratuit, seconde, examen);

        JourneyDto vue = journeyService.lire(gratuit.getId(), true);

        // Un compte gratuit plafonne a 2 sujets sur 5 : aucune etape
        // d'expression n'est finissable, donc aucune ne prend la main.
        assertThat(etapeDe(vue, premiere).locked()).isTrue();
        assertThat(etapeDe(vue, seconde).locked()).isTrue();
        // 🛑 Mais elles restent AFFICHEES, a leur place : le Plan reste
        // integralement visible (contradiction #1, tranchee le 2026-08-21).
        assertThat(vue.steps().stream().map(JourneyStepDto::skillCode))
                .contains(premiere.getCode(), seconde.getCode());
        // Le parcours AVANCE quand meme : la main passe a ce qui est faisable.
        assertThat(vue.current()).isNotNull();
        assertThat(vue.current().locked()).isFalse();
        assertThat(vue.current().type()).isEqualTo(JourneyStepType.SECTION_EXAM);
    }

    @Test
    @DisplayName("§18-37 — l'abonnement ouvre l'etape SANS aucune ecriture en base")
    void lAbonnementOuvreLEtapeSansEcriture() {
        User user = candidat();
        Skill skill = skill(SkillTaskCode.EE1);
        observationDExamen(user, skill, UUID.randomUUID());
        JourneyDto gratuit = journeyService.lire(user.getId(), true);
        assertThat(etapeDe(gratuit, skill).locked()).isTrue();

        data.userSubscription(user, data.plan());

        JourneyDto abonne = journeyService.lire(user.getId(), true);
        // 🛑 `locked` est DERIVE a la lecture (D-7) : la file n'a pas bouge d'une
        // ligne, seules les portes se sont ouvertes.
        assertThat(etapeDe(abonne, skill).locked()).isFalse();
        assertThat(abonne.steps().stream().map(JourneyStepDto::id))
                .containsExactlyElementsOf(gratuit.steps().stream().map(JourneyStepDto::id).toList());
        assertThat(abonne.current().skillCode()).isEqualTo(skill.getCode());
        assertThat(abonne.state()).isEqualTo(JourneyState.IN_PROGRESS);
    }

    // ------------------------------------------------------------- fabriques

    private User candidat() {
        User user = data.user();
        candidats.add(user.getId());
        user.setTargetProcedure(TargetProcedure.NAT);
        user.setTargetLevel(TargetProcedure.NAT.getRequiredTcfLevel());
        return data.saveUser(user);
    }

    private User abonne() {
        User user = candidat();
        data.userSubscription(user, data.plan());
        return user;
    }

    /**
     * Une competence du <b>referentiel seede</b>, jamais une competence creee.
     *
     * <p>🛑 Ces tests ne sont pas transactionnels (cf. l'en-tete) : une
     * competence creee ici <b>survivrait</b> a la classe et ferait echouer, a
     * distance, les tests qui comptent le referentiel
     * ({@code LearningPlanDomainSkillsIT} attend 24 competences EE et 3 par
     * domaine de comprehension). On emprunte donc ce qui existe.
     *
     * @param rang rang dans la tache, pour designer deux competences distinctes
     */
    private Skill skill(SkillTaskCode taskCode, int rang) {
        List<Skill> seedees = skillManager.findActiveByTaskCode(taskCode);
        assertThat(seedees).as("referentiel seede pour " + taskCode).hasSizeGreaterThan(rang);
        return seedees.get(rang);
    }

    private Skill skill(SkillTaskCode taskCode) {
        return skill(taskCode, 0);
    }

    /** La premiere competence seedee du domaine de comprehension. */
    private Skill comprehension(SkillSection section) {
        List<Skill> seedees = skillManager.findAllComprehensionBySection(section);
        assertThat(seedees).as("referentiel seede " + section).isNotEmpty();
        return seedees.getFirst();
    }

    /**
     * Les sujets de l'<b>etape</b> d'une competence, tels que le seed les publie.
     *
     * <p>🛑 On n'en <b>cree</b> aucun : ces tests ne sont pas transactionnels, et
     * un sujet cree survivrait a la classe — l'index
     * {@code uq_skill_prompts_skill_order} refuserait d'ailleurs le rang, deja
     * pris par le seed. Le perimetre est celui de {@link LearningPlanStep#scope},
     * son unique autorite.
     */
    private List<SkillPrompt> sujetsDeLEtape(Skill skill) {
        List<SkillPrompt> actifs = promptManager
                .findActiveBySkillIds(List.of(skill.getId()))
                .getOrDefault(skill.getId(), List.of());
        assertThat(actifs).as("sujets seedes de " + skill.getCode()).isNotEmpty();
        return LearningPlanStep.scope(actifs);
    }

    /**
     * Un <b>examen blanc</b> reellement en base — pas un identifiant tire au
     * hasard.
     *
     * <p>🛑 En comprehension, le filtre R1 interroge la <b>session</b> pour
     * savoir si c'est un examen ou une serie ciblee : un {@code sourceId} qui ne
     * designe aucun attempt est traite comme un entrainement, et ne cree donc
     * aucune etape. C'est exactement le comportement voulu, et c'est ce que ce
     * helper existe pour ne pas contourner par accident.
     */
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

    private void observationDExamen(User user, Skill skill, UUID examen) {
        data.learningPlanObservation(user, skill, LearningPlanSourceType.MOCK_EXAM_EE,
                LearningPlanSkillStatus.PRIORITY, ObservationConfidence.HIGH, null, HIER, examen);
    }

    private static JourneyStepDto etapeDe(JourneyDto vue, Skill skill) {
        return vue.steps().stream()
                .filter(step -> skill.getCode().equals(step.skillCode()))
                .findFirst()
                .orElseThrow(() -> new AssertionError(
                        "Aucune etape pour " + skill.getCode() + " dans " + vue.steps()));
    }

    private static JourneyStepDto.JourneyProgressDto progressionDe(JourneyDto vue, Skill skill) {
        return etapeDe(vue, skill).progress();
    }
}
