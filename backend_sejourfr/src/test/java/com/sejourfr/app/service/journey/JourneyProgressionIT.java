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
    @Autowired private com.sejourfr.app.repository.JourneyStepRepository journeySteps;

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
        // 🛑 On compte les etapes REELLEMENT EN BASE, pas celles que le DTO
        // montre : « aucune etape ajoutee » est un fait de la file, et une
        // etape creee dans un bloc qui porte deja un examen ouvert ne se
        // verrait pas dans `exam`, qui n'en sert qu'un.
        List<UUID> avant = etapesEnBase(user);

        // Un petit sujet revele une fragilite sur une TOUTE AUTRE competence.
        Skill revelee = skill(SkillTaskCode.EE1, 1);
        data.learningPlanObservation(user, revelee, LearningPlanSourceType.SKILL_TRAINING,
                LearningPlanSkillStatus.PRIORITY, ObservationConfidence.HIGH, null,
                Instant.now());
        journeyService.onTrainingProgress(user.getId(), List.of(revelee.getId()));

        // 🛑 Elle entrera dans le Plan si une EVALUATION la detecte. Pas avant.
        assertThat(etapesEnBase(user)).containsExactlyElementsOf(avant);
        assertThat(competencesServies(journeyService.lire(user.getId(), Module.TCF)))
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
        JourneyDto avant = journeyService.lire(user.getId(), Module.TCF);
        assertThat(progressionDe(avant, skill))
                .isEqualTo(new JourneyStepDto.JourneyProgressDto(
                        0, sujets.size(), JourneyProgressUnit.PROMPT));

        sujets.forEach(sujet -> data.userSkillAttempt(user, sujet));
        journeyService.onTrainingProgress(user.getId(), List.of(skill.getId()));

        JourneyDto apres = journeyService.lire(user.getId(), Module.TCF);
        // « Traites, pas valides » : on peut terminer une etape sans tout
        // reussir, et on ne bloque jamais un candidat sur une competence non
        // maitrisee — l'examen decidera si elle revient.
        assertThat(etapeDe(apres, skill).status())
                .isIn(JourneyStepStatus.COMPLETED, JourneyStepStatus.SKIPPED);
    }

    /**
     * 🛑 <b>D-16 (2026-09-18) — 2 series REUSSIES closent l'etape.</b> Ce test
     * comptait des series <b>terminees</b> quelle que soit leur reussite (D-5,
     * « le quota mesure le travail fourni ») : cette semantique est
     * <b>revoquee</b>. « Reussie » se lit sur le verdict deja pose par
     * {@code ComprehensionObservationService} —
     * {@code learning_plan_observations.status = SOLID}, donc sur
     * {@code learning-plan.comprehension.solid-ratio}, sans nouvelle
     * declaration du seuil.
     */
    @Test
    @DisplayName("D-16 — comprehension : 2 series REUSSIES closent l'etape, comptees en SERIES")
    void deuxSeriesReussiesClosentLEtapeDeComprehension() {
        User user = abonne();
        Skill skill = comprehension(SkillSection.CO);
        UUID examen = examenBlanc(user, EpreuveType.TCF_CO);
        data.learningPlanObservation(user, skill, LearningPlanSourceType.TCF_CO,
                LearningPlanSkillStatus.PRIORITY, ObservationConfidence.HIGH, null, HIER, examen);
        journeyService.onAssessmentCompleted(user.getId(), new JourneyEvaluation(
                examen, JourneyAssessmentKind.SECTION_EXAM, EpreuveType.TCF_CO, HIER));

        JourneyDto ouverte = journeyService.lire(user.getId(), Module.TCF);
        JourneyStepDto etape = etapeDe(ouverte, skill);
        // 🛑 L'unite est SERVIE : un front n'a pas a la deduire de la nullite de
        // taskCode. Les competences CO/CE n'ont ni tache ni petit sujet.
        assertThat(etape.taskCode()).isNull();
        assertThat(etape.progress().unit()).isEqualTo(JourneyProgressUnit.SERIES);
        assertThat(etape.progress().quota()).isEqualTo(config.trainSeriesQuota());
        assertThat(etape.progress().done()).isZero();

        // Une premiere serie reussie : le compteur servi avance, le quota n'est
        // pas atteint. ⚠️ On LIT avant de brancher la cloture : le moteur de
        // maitrise peut conclure au transfert des la premiere serie reussie et
        // clore l'etape en MASTERED — c'est une autre regle, verrouillee
        // ailleurs, et ce test-ci porte sur le QUOTA.
        serie(user, skill, LearningPlanSourceType.TCF_CO, LearningPlanSkillStatus.SOLID);
        JourneyStepDto apresUne = etapeDe(journeyService.lire(user.getId(), Module.TCF), skill);
        assertThat(apresUne.progress().done()).isEqualTo(1);
        assertThat(apresUne.status()).isNotIn(
                JourneyStepStatus.COMPLETED, JourneyStepStatus.SKIPPED);

        // La seconde atteint le quota : l'etape se clot.
        serie(user, skill, LearningPlanSourceType.TCF_CO, LearningPlanSkillStatus.SOLID);
        journeyService.onTrainingProgress(user.getId(), List.of(skill.getId()));

        assertThat(etapeDe(journeyService.lire(user.getId(), Module.TCF), skill).status())
                .isIn(JourneyStepStatus.COMPLETED, JourneyStepStatus.SKIPPED);
    }

    /**
     * 🛑 <b>D-16 — l'echappatoire : 4 series TERMINEES closent l'etape quelle que
     * soit leur reussite.</b> Elle existe pour une raison nommee : <b>un
     * candidat faible ne doit jamais rester bloque</b> sur une etape.
     *
     * <p>Et le {@code progress} servi n'en dit rien : il compte les series
     * <b>reussies</b> — ici zero. Afficher « 3 series ratees sur 4 » inviterait
     * a echouer vite pour se debarrasser d'une etape.
     */
    @Test
    @DisplayName("D-16 — l'echappatoire de 4 series terminees clot une etape jamais reussie")
    void quatreSeriesTermineesClosentLEtapeSansAucuneReussite() {
        User user = abonne();
        Skill skill = comprehension(SkillSection.CO);
        UUID examen = examenBlanc(user, EpreuveType.TCF_CO);
        data.learningPlanObservation(user, skill, LearningPlanSourceType.TCF_CO,
                LearningPlanSkillStatus.PRIORITY, ObservationConfidence.HIGH, null, HIER, examen);
        journeyService.onAssessmentCompleted(user.getId(), new JourneyEvaluation(
                examen, JourneyAssessmentKind.SECTION_EXAM, EpreuveType.TCF_CO, HIER));

        // Une serie de moins que l'echappatoire : rien n'est clos.
        for (int i = 0; i < config.trainSeriesFallbackQuota() - 1; i++) {
            serie(user, skill, LearningPlanSourceType.TCF_CO,
                    LearningPlanSkillStatus.PRIORITY);
        }
        journeyService.onTrainingProgress(user.getId(), List.of(skill.getId()));
        JourneyStepDto avant = etapeDe(journeyService.lire(user.getId(), Module.TCF), skill);
        assertThat(avant.status()).isNotIn(
                JourneyStepStatus.COMPLETED, JourneyStepStatus.SKIPPED);
        assertThat(avant.progress().done())
                .as("le progress servi compte les REUSSIES : aucune ici")
                .isZero();

        // La derniere declenche l'echappatoire.
        serie(user, skill, LearningPlanSourceType.TCF_CO, LearningPlanSkillStatus.PRIORITY);
        journeyService.onTrainingProgress(user.getId(), List.of(skill.getId()));

        assertThat(etapeDe(journeyService.lire(user.getId(), Module.TCF), skill).status())
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
        // L'echappatoire de D-16 : 4 series terminees, aucune reussie.
        for (int i = 0; i < config.trainSeriesFallbackQuota(); i++) {
            serie(user, skill, LearningPlanSourceType.TCF_CE,
                    LearningPlanSkillStatus.TO_REINFORCE);
        }
        journeyService.onTrainingProgress(user.getId(), List.of(skill.getId()));
        JourneyStepDto close = etapeDe(journeyService.lire(user.getId(), Module.TCF), skill);
        assertThat(close.status()).isIn(JourneyStepStatus.COMPLETED, JourneyStepStatus.SKIPPED);

        // La competence redevient fragile : de nouvelles series, un nouveau
        // verdict PRIORITY.
        data.learningPlanObservation(user, skill, LearningPlanSourceType.TCF_CE,
                LearningPlanSkillStatus.PRIORITY, ObservationConfidence.HIGH, null,
                Instant.now(), UUID.randomUUID());
        journeyService.onTrainingProgress(user.getId(), List.of(skill.getId()));

        // 🛑 L'etape reste close : elle reviendra par un EXAMEN (R7), pas par un
        // entrainement. C'est ce qui empeche le parcours de tourner en rond.
        assertThat(etapeDe(journeyService.lire(user.getId(), Module.TCF), skill).status())
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

        JourneyDto vue = journeyService.lire(gratuit.getId(), Module.TCF);

        // Un compte gratuit plafonne a 2 sujets sur 5 : aucune etape
        // d'expression n'est finissable, donc aucune ne prend la main.
        assertThat(etapeDe(vue, premiere).locked()).isTrue();
        assertThat(etapeDe(vue, seconde).locked()).isTrue();
        // 🛑 Mais elles restent AFFICHEES, a leur place : le Plan reste
        // integralement visible (contradiction #1, tranchee le 2026-08-21).
        assertThat(competencesServies(vue))
                .contains(premiere.getCode(), seconde.getCode());
        // 🛑 MIS A JOUR LE 2026-09-20 PAR LA SECONDE MOITIE DE D-57 — et c'est
        // un CAS D'USAGE RETIRE, remonte comme tel. Ce test figeait « le
        // parcours avance quand meme : la main passe a ce qui est faisable »,
        // c'est-a-dire l'examen d'un AUTRE bloc. C'est exactement ce que D-57
        // ferme : « une epreuve en cours, c'est forcement une de ses etapes a
        // faire maintenant » — le bloc meneur (l'EE) n'offrant rien
        // d'executable a un compte gratuit, `current` est nul et l'etat LOCKED,
        // mot pour mot ce que D-1 prevoit et ce que D-18 appelle « l'effet
        // voulu ».
        assertThat(vue.current()).isNull();
        assertThat(vue.state()).isEqualTo(JourneyState.LOCKED);
        // 🛑 ET LE GESTE N'A PAS DISPARU, il a change d'endroit : l'examen
        // reste OUVERT dans son bloc, le candidat gratuit le lance depuis le
        // cycle au lieu de « À faire maintenant ». Rien ne s'est ferme.
        assertThat(vue.blocs())
                .anySatisfy(bloc -> {
                    assertThat(bloc.exam()).isNotNull();
                    assertThat(bloc.exam().locked()).isFalse();
                });
    }

    @Test
    @DisplayName("§18-37 — l'abonnement ouvre l'etape SANS aucune ecriture en base")
    void lAbonnementOuvreLEtapeSansEcriture() {
        User user = candidat();
        Skill skill = skill(SkillTaskCode.EE1);
        observationDExamen(user, skill, UUID.randomUUID());
        JourneyDto gratuit = journeyService.lire(user.getId(), Module.TCF);
        assertThat(etapeDe(gratuit, skill).locked()).isTrue();

        data.userSubscription(user, data.plan());

        JourneyDto abonne = journeyService.lire(user.getId(), Module.TCF);
        // 🛑 `locked` est DERIVE a la lecture (D-7) : la file n'a pas bouge d'une
        // ligne, seules les portes se sont ouvertes.
        assertThat(etapeDe(abonne, skill).locked()).isFalse();
        assertThat(idsServis(abonne)).containsExactlyElementsOf(idsServis(gratuit));
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

    /**
     * Une <b>serie ciblee terminee</b>, telle que
     * {@code ComprehensionObservationService} l'ecrit : une observation par
     * (competence, session), et le <b>verdict deja pose</b> dans {@code status}.
     */
    private void serie(User user, Skill skill,
                       LearningPlanSourceType source, LearningPlanSkillStatus verdict) {
        data.learningPlanObservation(user, skill, source, verdict,
                ObservationConfidence.MEDIUM, null, Instant.now(), UUID.randomUUID());
    }

    /**
     * L'etape d'une competence, cherchee dans les <b>blocs</b> — la lecture du
     * cycle depuis P6, ou {@code JourneyDto.steps} a disparu.
     */
    private static JourneyStepDto etapeDe(JourneyDto vue, Skill skill) {
        return vue.blocs().stream()
                .flatMap(bloc -> bloc.steps().stream())
                .filter(step -> skill.getCode().equals(step.skillCode()))
                .findFirst()
                .orElseThrow(() -> new AssertionError(
                        "Aucune etape pour " + skill.getCode() + " dans " + vue.blocs()));
    }

    /** Les competences servies, tous blocs confondus, dans l'ordre des blocs. */
    private static List<String> competencesServies(JourneyDto vue) {
        return vue.blocs().stream()
                .flatMap(bloc -> bloc.steps().stream())
                .map(JourneyStepDto::skillCode)
                .toList();
    }

    /**
     * Les identifiants de <b>tout</b> ce que la vue sert : les etapes de chaque
     * bloc et son examen. ⚠️ Ce n'est <b>pas</b> l'ancien {@code steps} : un
     * bloc ne sert qu'<b>un</b> examen (l'ouvert, sinon le dernier clos).
     */
    private static List<UUID> idsServis(JourneyDto vue) {
        return vue.blocs().stream()
                .flatMap(bloc -> java.util.stream.Stream.concat(
                        bloc.steps().stream(),
                        bloc.exam() == null ? java.util.stream.Stream.empty()
                                : java.util.stream.Stream.of(bloc.exam())))
                .map(JourneyStepDto::id)
                .toList();
    }

    /**
     * Les etapes du cycle en cours <b>telles qu'elles sont en base</b>, dans
     * l'ordre de la file. 🛑 « Aucune etape ajoutee » se prouve sur la file, pas
     * sur ce que l'ecran montre.
     */
    private List<UUID> etapesEnBase(User user) {
        return journeyService.getOrCreate(user.getId(), Module.TCF)
                .map(journey -> journeySteps.findAllByJourney(journey.getId()).stream()
                        .map(com.sejourfr.app.entity.JourneyStep::getId)
                        .toList())
                .orElse(List.of());
    }

    private static JourneyStepDto.JourneyProgressDto progressionDe(JourneyDto vue, Skill skill) {
        return etapeDe(vue, skill).progress();
    }
}
