package com.sejourfr.app.service;

import com.sejourfr.app.config.LearningPlanProperties;
import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.manager.LearningPlanObservationManager;
import com.sejourfr.app.manager.SkillManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.service.ComprehensionObservationService.ReponseComprehension;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Le producteur d'observations CO / CE : ventilation par niveau, seuils,
 * plancher de fiabilite et perimetre.
 */
class ComprehensionObservationServiceTest {

    private static final UUID USER_ID = UUID.randomUUID();
    private static final UUID ATTEMPT_ID = UUID.randomUUID();
    private static final Instant QUAND = Instant.parse("2026-08-21T10:00:00Z");

    private LearningPlanProperties properties;
    private LearningPlanObservationManager observationManager;
    private ComprehensionObservationService service;

    @BeforeEach
    void setUp() {
        properties = new LearningPlanProperties();
        observationManager = mock(LearningPlanObservationManager.class);
        SkillManager skillManager = mock(SkillManager.class);
        UserManager userManager = mock(UserManager.class);

        when(skillManager.findActiveComprehension()).thenReturn(List.of(
                skill(SkillSection.CO, "A2"), skill(SkillSection.CO, "B1"), skill(SkillSection.CO, "B2"),
                skill(SkillSection.CE, "A2"), skill(SkillSection.CE, "B1"), skill(SkillSection.CE, "B2")));
        User user = new User();
        user.setId(USER_ID);
        when(userManager.findById(USER_ID)).thenReturn(Optional.of(user));
        when(observationManager.findBySource(any(), any(), any(), any())).thenReturn(Optional.empty());
        when(observationManager.save(any())).thenAnswer(inv -> inv.getArgument(0));

        service = new ComprehensionObservationService(
                properties, observationManager, skillManager, userManager);
    }

    // ------------------------------------------------------------------ ventilation

    @Test
    void ventileParNiveauEtNonSurLeScoreTotal() {
        // Composition d'un examen d'epreuve CO : 8 A2 + 9 B1 + 8 B2. Le score
        // TOTAL vaut 16/25 (64 %), qui se lirait « priorite » ; la verite par
        // niveau est tout autre, et c'est elle qui alimente le Plan.
        List<ReponseComprehension> reponses = new ArrayList<>();
        reponses.addAll(co(Difficulty.A2, 8, 8));
        reponses.addAll(co(Difficulty.B1, 9, 6));
        reponses.addAll(co(Difficulty.B2, 8, 2));

        service.record(USER_ID, ATTEMPT_ID, QUAND, reponses);

        Map<String, LearningPlanObservation> ecrites = ecrites();
        assertThat(ecrites).containsOnlyKeys("CO-A2", "CO-B1", "CO-B2");
        assertThat(ecrites.get("CO-A2").getStatus()).isEqualTo(LearningPlanSkillStatus.SOLID);
        // 6/9 = 66,7 %, dans la bande intermediaire.
        assertThat(ecrites.get("CO-B1").getStatus()).isEqualTo(LearningPlanSkillStatus.TO_REINFORCE);
        assertThat(ecrites.get("CO-B2").getStatus()).isEqualTo(LearningPlanSkillStatus.PRIORITY);
        assertThat(ecrites.values())
                .allSatisfy(o -> assertThat(o.getSourceType()).isEqualTo(LearningPlanSourceType.TCF_CO));
    }

    @Test
    void coImageEstCompteeAvecCo() {
        // Un filtre CO inclut CO_IMAGE partout dans le depot : c'est un FORMAT
        // de question de comprehension orale, pas un domaine a part.
        List<ReponseComprehension> reponses = new ArrayList<>();
        reponses.addAll(co(Difficulty.B1, 5, 5));
        for (int i = 0; i < 5; i++) {
            reponses.add(new ReponseComprehension(QuestionType.CO_IMAGE, Difficulty.B1, true, true));
        }

        service.record(USER_ID, ATTEMPT_ID, QUAND, reponses);

        Map<String, LearningPlanObservation> ecrites = ecrites();
        // Une seule observation : les 10 questions ont ete regroupees, et le
        // total de 10 passe le plancher que 5 seules n'auraient pas passe.
        assertThat(ecrites).containsOnlyKeys("CO-B1");
        assertThat(ecrites.get("CO-B1").isObserved()).isTrue();
        assertThat(ecrites.get("CO-B1").getEvidence()).isEqualTo("10 / 10 bonnes réponses");
    }

    @Test
    void structureEstHorsPerimetre() {
        List<ReponseComprehension> reponses = new ArrayList<>();
        for (int i = 0; i < 20; i++) {
            reponses.add(new ReponseComprehension(QuestionType.STRUCTURE, Difficulty.B1, true, true));
        }

        // STRUCTURE n'a aucune competence au referentiel : la session ne
        // concerne AUCUNE competence, et n'ecrit donc rien.
        assertThat(service.record(USER_ID, ATTEMPT_ID, QUAND, reponses)).isEmpty();
        verify(observationManager, never()).save(any());
    }

    @Test
    void lesDifficultesCiviquesNeSontJamaisUnPalierCecrl() {
        List<ReponseComprehension> reponses = new ArrayList<>();
        for (int i = 0; i < 20; i++) {
            reponses.add(new ReponseComprehension(QuestionType.CONNAISSANCE, Difficulty.CSP, true, true));
        }

        assertThat(service.record(USER_ID, ATTEMPT_ID, QUAND, reponses)).isEmpty();
    }

    // ------------------------------------------------------------------ seuils

    @Test
    void lesTroisBandesSeSeparentAuxFrontieresExactes() {
        // 100 questions : le taux vaut exactement le nombre de bonnes reponses.
        assertThat(statutSur100(80)).isEqualTo(LearningPlanSkillStatus.SOLID);
        assertThat(statutSur100(79)).isEqualTo(LearningPlanSkillStatus.TO_REINFORCE);
        assertThat(statutSur100(65)).isEqualTo(LearningPlanSkillStatus.TO_REINFORCE);
        assertThat(statutSur100(64)).isEqualTo(LearningPlanSkillStatus.PRIORITY);
    }

    @Test
    void seizeSurVingtEstLeSeuilDeReussiteDUneSerieCiblee() {
        // La valeur du brief : 16/20 (80 %) reussit, 15/20 (75 %) non.
        assertThat(statutSerie(16)).isEqualTo(LearningPlanSkillStatus.SOLID);
        assertThat(statutSerie(15)).isEqualTo(LearningPlanSkillStatus.TO_REINFORCE);
    }

    // ------------------------------------------------------------------ plancher

    @Test
    void sousLePlancherDeFiabiliteLObservationEstNonObserveeEtJamaisUneFragilite() {
        properties.getComprehension().setMinQuestions(6);
        // 1 bonne reponse sur 5 : un taux catastrophique, sur un echantillon
        // qui ne dit rien. « Non observe » = inconnu, jamais mauvais.
        service.record(USER_ID, ATTEMPT_ID, QUAND, ce(Difficulty.B2, 5, 1));

        LearningPlanObservation observation = ecrites().get("CE-B2");
        assertThat(observation.isObserved()).isFalse();
        assertThat(observation.getStatus()).isEqualTo(LearningPlanSkillStatus.NOT_OBSERVED);
        // chk_learning_plan_observation_coherence : pas de preuve sans observation.
        assertThat(observation.getEvidence()).isNull();
        assertThat(observation.getConfidence()).isEqualTo(ObservationConfidence.LOW);
    }

    @Test
    void auPlancherExactLObservationCompte() {
        properties.getComprehension().setMinQuestions(6);

        service.record(USER_ID, ATTEMPT_ID, QUAND, ce(Difficulty.B2, 6, 4));

        LearningPlanObservation observation = ecrites().get("CE-B2");
        assertThat(observation.isObserved()).isTrue();
        // 4/6 = 66,7 % : la bande intermediaire est atteignable des 6 questions,
        // ce qui est precisement la raison de ce plancher.
        assertThat(observation.getStatus()).isEqualTo(LearningPlanSkillStatus.TO_REINFORCE);
    }

    // ------------------------------------------------------- questions non repondues

    @Test
    void uneSessionSansAucuneReponseNEcritRienDuTout() {
        // Le cas mesure en base (session CO terminee, 25 questions posees, zero
        // reponse) : il produisait 3 observations, dont une PRIORITY a 0/8 —
        // une fragilite qui n'a jamais ete observee. « Aucune preuve » n'est
        // pas « mauvaise preuve » : cette session n'a rien a apprendre au Plan.
        List<ReponseComprehension> reponses = new ArrayList<>();
        reponses.addAll(nonRepondues(QuestionType.CO, Difficulty.A2, 8));
        reponses.addAll(nonRepondues(QuestionType.CO, Difficulty.B1, 9));
        reponses.addAll(nonRepondues(QuestionType.CO, Difficulty.B2, 8));

        assertThat(service.record(USER_ID, ATTEMPT_ID, QUAND, reponses)).isEmpty();
        verify(observationManager, never()).save(any());
    }

    @Test
    void seulesLesQuestionsRepondueEntrentDansLeDenominateur() {
        // 3 repondues sur 5, toutes justes. Si les 2 questions laissees vides
        // comptaient fausses, le taux serait 3/5 = 60 % => PRIORITY. Elles ne
        // comptent pas du tout : 3/3, et 3 reste sous le plancher de 6.
        properties.getComprehension().setMinQuestions(6);
        List<ReponseComprehension> reponses = new ArrayList<>(ce(Difficulty.B1, 3, 3));
        reponses.addAll(nonRepondues(QuestionType.CE, Difficulty.B1, 2));

        service.record(USER_ID, ATTEMPT_ID, QUAND, reponses);

        LearningPlanObservation observation = ecrites().get("CE-B1");
        assertThat(observation.getStatus()).isEqualTo(LearningPlanSkillStatus.NOT_OBSERVED);
        assertThat(observation.isObserved()).isFalse();
    }

    @Test
    void lePlancherSeDecideSurLesReponsesPasSurLesQuestionsPosees() {
        // 6 repondues (5 justes) + 6 laissees vides. Compter les questions
        // POSEES donnerait 12 et un taux de 5/12 = 41 % => PRIORITY ; compter
        // les REPONSES donne 6 (le plancher exact) et 5/6 = 83 % => SOLID.
        properties.getComprehension().setMinQuestions(6);
        List<ReponseComprehension> reponses = new ArrayList<>(co(Difficulty.B2, 6, 5));
        reponses.addAll(nonRepondues(QuestionType.CO, Difficulty.B2, 6));

        service.record(USER_ID, ATTEMPT_ID, QUAND, reponses);

        LearningPlanObservation observation = ecrites().get("CO-B2");
        assertThat(observation.isObserved()).isTrue();
        assertThat(observation.getStatus()).isEqualTo(LearningPlanSkillStatus.SOLID);
        assertThat(observation.getEvidence()).isEqualTo("5 / 6 bonnes réponses");
    }

    // ------------------------------------------------------------------ confiance

    @Test
    void laConfianceSuitLaTailleDeLEchantillonPasLaPerformance() {
        // Une serie ciblee de 20 questions est une preuve plus assuree que les
        // 8 questions A2 noyees dans un examen d'epreuve — quel qu'en soit le
        // resultat : la confiance dit la certitude de l'observateur.
        service.record(USER_ID, ATTEMPT_ID, QUAND, ce(Difficulty.A2, 20, 2));
        assertThat(ecrites().get("CE-A2").getConfidence()).isEqualTo(ObservationConfidence.HIGH);

        setUp();
        service.record(USER_ID, ATTEMPT_ID, QUAND, ce(Difficulty.A2, 8, 8));
        assertThat(ecrites().get("CE-A2").getConfidence()).isEqualTo(ObservationConfidence.MEDIUM);
    }

    // ------------------------------------------------------------------ idempotence

    @Test
    void uneSessionDejaObserveeNEcritRien() {
        when(observationManager.findBySource(any(), any(), any(), any()))
                .thenReturn(Optional.of(new LearningPlanObservation()));

        // 🛑 La session CONCERNE toujours la competence — le rejeu ne doit pas
        // faire disparaitre ce qu'elle a enseigne (c'est ce dont le parcours TCF
        // se sert, §7.3) — mais elle n'ECRIT rien : la cle est
        // (user, competence, source, attempt).
        assertThat(service.record(USER_ID, ATTEMPT_ID, QUAND, ce(Difficulty.B1, 20, 20)))
                .isNotEmpty();
        verify(observationManager, never()).save(any());
    }

    @Test
    void laSessionEstAlaFoisLaSourceEtLeSujet() {
        // Deux series distinctes = deux attempts = deux sujets, donc deux
        // preuves independantes pour le moteur de maitrise. Une meme session
        // rejouee garde son identite : c'est ce qui tient l'idempotence.
        service.record(USER_ID, ATTEMPT_ID, QUAND, ce(Difficulty.B1, 20, 20));

        LearningPlanObservation observation = ecrites().get("CE-B1");
        assertThat(observation.getSourceId()).isEqualTo(ATTEMPT_ID);
        assertThat(observation.getSubjectId()).isEqualTo(ATTEMPT_ID);
        assertThat(observation.isBaseline()).isFalse();
        assertThat(observation.getObservedAt()).isEqualTo(QUAND);
    }

    @Test
    void uneSessionInviteeNAlimenteRien() {
        assertThat(service.record(null, ATTEMPT_ID, QUAND, ce(Difficulty.B1, 20, 20))).isEmpty();
        verify(observationManager, never()).save(any());
    }

    // ------------------------------------------------------------------ fixtures

    private LearningPlanSkillStatus statutSur100(int correctes) {
        setUp();
        service.record(USER_ID, ATTEMPT_ID, QUAND, ce(Difficulty.B1, 100, correctes));
        return ecrites().get("CE-B1").getStatus();
    }

    private LearningPlanSkillStatus statutSerie(int correctes) {
        setUp();
        service.record(USER_ID, ATTEMPT_ID, QUAND, co(Difficulty.B2, 20, correctes));
        return ecrites().get("CO-B2").getStatus();
    }

    private Map<String, LearningPlanObservation> ecrites() {
        ArgumentCaptor<LearningPlanObservation> captor =
                ArgumentCaptor.forClass(LearningPlanObservation.class);
        verify(observationManager, org.mockito.Mockito.atLeast(0)).save(captor.capture());
        return captor.getAllValues().stream()
                .collect(Collectors.toMap(o -> o.getSkill().getCode(), Function.identity()));
    }

    private static List<ReponseComprehension> co(Difficulty difficulty, int total, int correctes) {
        return reponses(QuestionType.CO, difficulty, total, correctes);
    }

    private static List<ReponseComprehension> ce(Difficulty difficulty, int total, int correctes) {
        return reponses(QuestionType.CE, difficulty, total, correctes);
    }

    /** Des questions POSEES et laissees vides : ni bonnes, ni mauvaises, ni comptees. */
    private static List<ReponseComprehension> nonRepondues(
            QuestionType type, Difficulty difficulty, int total) {
        List<ReponseComprehension> liste = new ArrayList<>();
        for (int i = 0; i < total; i++) {
            liste.add(new ReponseComprehension(type, difficulty, false, false));
        }
        return liste;
    }

    private static List<ReponseComprehension> reponses(
            QuestionType type, Difficulty difficulty, int total, int correctes) {
        List<ReponseComprehension> liste = new ArrayList<>();
        for (int i = 0; i < total; i++) {
            liste.add(new ReponseComprehension(type, difficulty, true, i < correctes));
        }
        return liste;
    }

    private static Skill skill(SkillSection section, String level) {
        Skill skill = new Skill();
        skill.setId(UUID.randomUUID());
        skill.setSection(section);
        skill.setTargetLevel(level);
        skill.setCode(section.name() + "-" + level);
        return skill;
    }
}
