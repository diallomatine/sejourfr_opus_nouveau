package com.sejourfr.app.service.journey;

import com.sejourfr.app.dto.JourneyDto;
import com.sejourfr.app.dto.JourneyStepDto;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.JourneyAssessmentKind;
import com.sejourfr.app.enums.JourneyState;
import com.sejourfr.app.enums.JourneyStepPurpose;
import com.sejourfr.app.enums.JourneyStepStatus;
import com.sejourfr.app.enums.JourneyStepType;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.enums.TargetProcedure;
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
 * <b>Le parcours se construit a partir des evaluations, et d'elles seules.</b>
 *
 * <p>Ces tests montent le contexte complet (Postgres embarque, vraies
 * migrations) parce que ce qu'ils verifient est de <b>l'orchestration</b> :
 * l'ordre de la file, ce qu'une evaluation ferme, ce qu'elle ouvre, et ce
 * qu'elle refuse de refaire. Rien de tout cela ne se teste sur des mocks sans
 * reecrire la moitie du service.
 *
 * <h2>🛑 Pourquoi ces tests ne sont PAS transactionnels</h2>
 * <p>{@code JourneyService} ecrit en {@link Propagation#REQUIRES_NEW} — c'est ce
 * qui garantit qu'un bug d'orchestration ne fasse jamais echouer la correction
 * d'un QCM ni la livraison d'une evaluation payante. Une transaction de test qui
 * les envelopperait <b>suspendrait</b> la sienne, et la transaction neuve ne
 * verrait <b>rien</b> de ce que le test vient d'ecrire : le service sortirait
 * silencieusement, et les assertions passeraient pour de mauvaises raisons.
 * C'est exactement ce qui s'est produit avant ce commentaire.
 *
 * <p>Chaque test cree donc son propre candidat et n'assertionne que sur lui : les
 * lignes survivent a la classe, et c'est sans consequence puisque rien n'est
 * partage.
 */
@Transactional(propagation = Propagation.NOT_SUPPORTED)
class JourneyServiceIT extends AbstractIntegrationTest {

    @Autowired private JourneyService journeyService;
    @Autowired private TestData data;
    @Autowired private SkillManager skillManager;
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
    private static final Instant MAINTENANT = Instant.now().minusSeconds(60);

    // =====================================================================
    // R18 / D-3 — pas de parcours sans objectif
    // =====================================================================

    @Test
    @DisplayName("§18-39 — aucune demarche declaree : NEEDS_OBJECTIVE, et AUCUNE ligne creee")
    void sansObjectifAucunParcoursNEstCree() {
        User user = nouveauCandidat();
        user.setTargetProcedure(null);
        user.setTargetLevel(null);
        data.saveUser(user);

        JourneyDto vue = journeyService.lire(user.getId(), false);

        assertThat(vue.state()).isEqualTo(JourneyState.NEEDS_OBJECTIVE);
        assertThat(vue.targetLevel()).isNull();
        assertThat(vue.current()).isNull();
        assertThat(vue.steps()).isEmpty();
        // 🛑 Creer un parcours « par defaut » reviendrait a choisir un objectif a
        // sa place, puis a batir une file entiere sur cette supposition.
        assertThat(journeyService.getOrCreate(user.getId())).isEmpty();
    }

    @Test
    @DisplayName("§18-40 — la demarche declaree ensuite amorce le parcours depuis l'historique")
    void laDemarcheDeclareeEnsuiteAmorceLeParcours() {
        User user = nouveauCandidat();
        user.setTargetProcedure(null);
        user.setTargetLevel(null);
        data.saveUser(user);
        UUID examen = UUID.randomUUID();
        observationDExamen(user, skill(SkillTaskCode.EE1), examen, HIER);

        assertThat(journeyService.lire(user.getId(), false).state())
                .isEqualTo(JourneyState.NEEDS_OBJECTIVE);

        declarer(user, TargetProcedure.NAT);
        JourneyDto vue = journeyService.lire(user.getId(), false);

        assertThat(vue.state()).isEqualTo(JourneyState.IN_PROGRESS);
        // 🛑 Pas de diagnostic : une evaluation exploitable existe (R19.8).
        assertThat(typesDe(vue)).doesNotContain(JourneyStepType.DIAGNOSTIC);
    }

    // =====================================================================
    // R19 — bootstrap
    // =====================================================================

    @Test
    @DisplayName("§18-1 / §18-25 — aucune evaluation : l'etape courante est le DIAGNOSTIC")
    void sansEvaluationLeParcoursProposeLeDiagnostic() {
        User user = candidat(TargetProcedure.NAT);

        JourneyDto vue = journeyService.lire(user.getId(), false);

        assertThat(vue.current()).isNotNull();
        assertThat(vue.current().type()).isEqualTo(JourneyStepType.DIAGNOSTIC);
        assertThat(vue.current().status()).isEqualTo(JourneyStepStatus.CURRENT);
        // 🛑 Aucune priorite inventee : le Plan n'apprend rien tant qu'il n'a
        // rien mesure.
        assertThat(typesDe(vue)).containsOnly(JourneyStepType.DIAGNOSTIC);
    }

    @Test
    @DisplayName("§18-33 — un candidat qui n'a QUE des entrainements n'a pas de lot (R1)")
    void lesEntrainementsSeulsNAmorcentRien() {
        User user = candidat(TargetProcedure.CR);
        // Un petit sujet et une production d'entrainement libre : deux vraies
        // observations, aucune evaluation.
        data.learningPlanObservation(user, skill(SkillTaskCode.EE1),
                LearningPlanSourceType.SKILL_TRAINING, LearningPlanSkillStatus.PRIORITY,
                ObservationConfidence.HIGH, null, HIER);
        data.learningPlanObservation(user, skill(SkillTaskCode.EO1),
                LearningPlanSourceType.PRODUCTION_EO, LearningPlanSkillStatus.PRIORITY,
                ObservationConfidence.HIGH, null, HIER);

        JourneyDto vue = journeyService.lire(user.getId(), false);

        assertThat(typesDe(vue)).containsOnly(JourneyStepType.DIAGNOSTIC);
    }

    @Test
    @DisplayName("§18-24 / §18-28 — bootstrap depuis l'historique : ni diagnostic, ni etape close")
    void leBootstrapNeFabriqueAucuneEtapeClose() {
        User user = candidat(TargetProcedure.NAT);
        UUID examen = UUID.randomUUID();
        observationDExamen(user, skill(SkillTaskCode.EE1), examen, HIER);
        observationDExamen(user, skill(SkillTaskCode.EE2), examen, HIER);

        JourneyDto vue = journeyService.lire(user.getId(), true);

        assertThat(typesDe(vue)).doesNotContain(JourneyStepType.DIAGNOSTIC);
        // 🛑 La timeline d'un nouveau parcours commence par ce qu'il RESTE a
        // faire : inventer des etapes « deja faites » donnerait au candidat un
        // parcours qu'il n'a pas vecu.
        assertThat(vue.steps()).allSatisfy(step ->
                assertThat(step.status()).isIn(
                        JourneyStepStatus.CURRENT, JourneyStepStatus.UPCOMING));
    }

    @Test
    @DisplayName("§18-27 — un examen fait reference, meme si un diagnostic rapide est plus recent")
    void lExamenFaitReferenceDevantLeDiagnosticRapide() {
        User user = candidat(TargetProcedure.NAT);
        Skill parLExamen = skill(SkillTaskCode.EE1, 0);
        Skill parLeDiagnostic = skill(SkillTaskCode.EE1, 1);
        observationDExamen(user, parLExamen, UUID.randomUUID(), HIER);
        data.learningPlanObservation(user, parLeDiagnostic,
                LearningPlanSourceType.DIAGNOSTIC_EE, LearningPlanSkillStatus.PRIORITY,
                ObservationConfidence.HIGH, null, MAINTENANT);

        JourneyDto vue = journeyService.lire(user.getId(), true);

        // R19.2 : la plus recente qui MESURE l'emporte sur un diagnostic rapide,
        // meme plus frais — une baseline n'a pas l'autorite d'une mesure.
        assertThat(codesDEntrainement(vue)).containsExactly(parLExamen.getCode());
    }

    @Test
    @DisplayName("§18-2 — un lot EE est suivi de son examen, puis des epreuves non mesurees")
    void unLotEstSuiviDeSonExamenPuisDesEpreuvesNonMesurees() {
        User user = candidat(TargetProcedure.NAT);
        UUID examen = UUID.randomUUID();
        observationDExamen(user, skill(SkillTaskCode.EE1), examen, HIER);
        observationDExamen(user, skill(SkillTaskCode.EE2), examen, HIER);
        observationDExamen(user, skill(SkillTaskCode.EE3), examen, HIER);

        List<JourneyStepDto> steps = journeyService.lire(user.getId(), true).steps();

        assertThat(steps).hasSize(3 + 1 + 3);
        assertThat(steps.subList(0, 3)).allSatisfy(step ->
                assertThat(step.type()).isEqualTo(JourneyStepType.TRAIN_SKILL));
        // R3 — le lot est TOUJOURS clos par un examen de son epreuve.
        assertThat(steps.get(3).type()).isEqualTo(JourneyStepType.SECTION_EXAM);
        assertThat(steps.get(3).purpose()).isEqualTo(JourneyStepPurpose.REASSESS);
        assertThat(steps.get(3).examType()).isEqualTo(EpreuveType.TCF_EE);
        // R12 — puis les epreuves non mesurees, dans l'ordre CO, CE, EO.
        // 🛑 PAS d'« Evaluer mon niveau » pour l'EE : son examen de reevaluation
        // est deja prevu, et R12 ne propose que ce qu'aucune etape ne couvre —
        // sinon le candidat verrait deux examens EE d'affilee.
        assertThat(steps.subList(4, 7)).allSatisfy(step -> {
            assertThat(step.type()).isEqualTo(JourneyStepType.SECTION_EXAM);
            assertThat(step.purpose()).isEqualTo(JourneyStepPurpose.INITIAL_ASSESSMENT);
        });
        assertThat(steps.subList(4, 7).stream().map(JourneyStepDto::examType)).containsExactly(
                EpreuveType.TCF_CO, EpreuveType.TCF_CE, EpreuveType.TCF_EO);
    }

    // =====================================================================
    // R7 / R14 — une evaluation arrive
    // =====================================================================

    @Test
    @DisplayName("§18-11 — examen EE hors Plan, entrainements en cours : le lot est REMPLACE")
    void unExamenRemplaceUnLotInacheve() {
        User user = candidat(TargetProcedure.NAT);
        Skill duPremierLot = skill(SkillTaskCode.EE1, 0);
        Skill duSecondLot = skill(SkillTaskCode.EE1, 1);
        observationDExamen(user, duPremierLot, UUID.randomUUID(), HIER);
        journeyService.lire(user.getId(), true);
        assertThat(codesDEntrainement(journeyService.lire(user.getId(), true)))
                .containsExactly(duPremierLot.getCode());

        UUID second = UUID.randomUUID();
        observationDExamen(user, duSecondLot, second, MAINTENANT);
        journeyService.onAssessmentCompleted(user.getId(), examenDe(second, MAINTENANT));

        JourneyDto vue = journeyService.lire(user.getId(), true);
        // 🛑 L'examen fait autorite : le lot inacheve est REMPLACE, et ses etapes
        // deviennent OBSOLETE donc invisibles — le candidat n'a pas a lire une
        // etape que la mesure a rendue caduque.
        assertThat(codesDEntrainement(vue)).containsExactly(duSecondLot.getCode());
        assertThat(vue.steps()).noneSatisfy(step ->
                assertThat(step.status()).isEqualTo(JourneyStepStatus.OBSOLETE));
    }

    @Test
    @DisplayName("§18-16 / §18-29 — la meme evaluation deux fois : le second passage est sans effet")
    void uneEvaluationNestTraiteeQuUneFois() {
        User user = candidat(TargetProcedure.NAT);
        UUID examen = UUID.randomUUID();
        observationDExamen(user, skill(SkillTaskCode.EE1), examen, MAINTENANT);
        journeyService.lire(user.getId(), true);
        int avant = journeyService.lire(user.getId(), true).steps().size();

        journeyService.onAssessmentCompleted(user.getId(), examenDe(examen, MAINTENANT));
        journeyService.onAssessmentCompleted(user.getId(), examenDe(examen, MAINTENANT));

        // Le bootstrap a deja enregistre cette evaluation : la rejouer ne
        // dedouble ni le lot, ni ses etapes.
        assertThat(journeyService.lire(user.getId(), true).steps()).hasSize(avant);
    }

    @Test
    @DisplayName("§18-17 — une evaluation plus ANCIENNE ne defait pas une plus recente")
    void uneEvaluationTardiveNeDefaitPasLaPlusRecente() {
        User user = candidat(TargetProcedure.NAT);
        UUID recente = UUID.randomUUID();
        observationDExamen(user, skill(SkillTaskCode.EE1), recente, MAINTENANT);
        journeyService.lire(user.getId(), true);
        List<String> avant = codesDEntrainement(journeyService.lire(user.getId(), true));

        // Une session jouee hors ligne sur mobile, synchronisee apres coup.
        UUID tardive = UUID.randomUUID();
        observationDExamen(user, skill(SkillTaskCode.EE2), tardive, HIER);
        journeyService.onAssessmentCompleted(user.getId(), examenDe(tardive, HIER));

        assertThat(codesDEntrainement(journeyService.lire(user.getId(), true)))
                .containsExactlyElementsOf(avant);
    }

    @Test
    @DisplayName("§18-13 — un examen sans priorite ne cree aucun lot et ne redemande rien")
    void unExamenSansPrioriteNeCreeAucunLot() {
        User user = candidat(TargetProcedure.NAT);
        UUID examen = UUID.randomUUID();
        data.learningPlanObservation(user, skill(SkillTaskCode.EE1),
                LearningPlanSourceType.MOCK_EXAM_EE, LearningPlanSkillStatus.SOLID,
                ObservationConfidence.HIGH, null, MAINTENANT, examen);

        journeyService.onAssessmentCompleted(user.getId(), examenDe(examen, MAINTENANT));
        JourneyDto vue = journeyService.lire(user.getId(), true);

        // R9 — « aucune priorite detectee » n'est pas une declaration de
        // maitrise, et ce n'est pas une anomalie : zero fragilite, zero lot.
        assertThat(codesDEntrainement(vue)).isEmpty();
        assertThat(vue.steps()).noneSatisfy(step ->
                assertThat(step.purpose()).isEqualTo(JourneyStepPurpose.REASSESS));
    }

    @Test
    @DisplayName("§18-15 — un diagnostic rapide ne touche pas un lot deja ouvert (R11)")
    void unDiagnosticRapideNeRemplaceJamaisUnLotOuvert() {
        User user = candidat(TargetProcedure.NAT);
        UUID examen = UUID.randomUUID();
        observationDExamen(user, skill(SkillTaskCode.EE1), examen, HIER);
        journeyService.lire(user.getId(), true);
        List<String> avant = codesDEntrainement(journeyService.lire(user.getId(), true));

        UUID diagnostic = UUID.randomUUID();
        data.learningPlanObservation(user, skill(SkillTaskCode.EE2),
                LearningPlanSourceType.DIAGNOSTIC_EE, LearningPlanSkillStatus.PRIORITY,
                ObservationConfidence.HIGH, null, MAINTENANT, diagnostic);
        journeyService.onAssessmentCompleted(
                user.getId(), JourneyEvaluation.diagnosticRapide(diagnostic, MAINTENANT));

        assertThat(codesDEntrainement(journeyService.lire(user.getId(), true)))
                .containsExactlyElementsOf(avant);
    }

    @Test
    @DisplayName("§18-9 — un lot d'une autre epreuve s'ajoute APRES, sans deplacer l'existant")
    void unNouveauLotSAjouteEnFinDeFile() {
        User user = candidat(TargetProcedure.NAT);
        UUID examenEe = UUID.randomUUID();
        observationDExamen(user, skill(SkillTaskCode.EE1), examenEe, HIER);
        journeyService.lire(user.getId(), true);
        long positionPremiere = journeyService.lire(user.getId(), true)
                .steps().getFirst().position();

        UUID examenEo = UUID.randomUUID();
        Skill deLEo = skill(SkillTaskCode.EO1);
        data.learningPlanObservation(user, deLEo,
                LearningPlanSourceType.MOCK_EXAM_EO, LearningPlanSkillStatus.PRIORITY,
                ObservationConfidence.HIGH, null, MAINTENANT, examenEo);
        journeyService.onAssessmentCompleted(user.getId(),
                new JourneyEvaluation(examenEo, JourneyAssessmentKind.SECTION_EXAM,
                        EpreuveType.TCF_EO, MAINTENANT));

        List<JourneyStepDto> steps = journeyService.lire(user.getId(), true).steps();
        // R4 — la nouvelle etape ne remplace jamais l'etape courante et ne passe
        // jamais devant un examen deja prevu.
        assertThat(steps.getFirst().position()).isEqualTo(positionPremiere);
        assertThat(steps.getFirst().skillCode()).isNotNull();
        JourneyStepDto nouvelle = steps.stream()
                .filter(step -> deLEo.getCode().equals(step.skillCode()))
                .findFirst().orElseThrow();
        assertThat(nouvelle.examType()).isEqualTo(EpreuveType.TCF_EO);
        assertThat(nouvelle.position()).isGreaterThan(positionPremiere);
        // §18-12 — l'« Evaluer mon niveau » de l'EO est CLOS : on ne demande
        // jamais de refaire un examen qu'on vient de passer (R7). Il reste
        // AFFICHE, coche : une etape franchie ne disparait pas du parcours.
        JourneyStepDto evaluerLEo = steps.stream()
                .filter(step -> step.purpose() == JourneyStepPurpose.INITIAL_ASSESSMENT)
                .filter(step -> step.examType() == EpreuveType.TCF_EO)
                .findFirst().orElseThrow();
        assertThat(evaluerLEo.status())
                .isIn(JourneyStepStatus.COMPLETED, JourneyStepStatus.SKIPPED);
    }

    // =====================================================================
    // R18 — changement d'objectif
    // =====================================================================

    @Test
    @DisplayName("§18-22 / §18-23 — changer d'objectif bascule sans redemander de diagnostic")
    void changerDObjectifNeForceJamaisUnDiagnostic() {
        User user = candidat(TargetProcedure.CR);
        observationDExamen(user, skill(SkillTaskCode.EE1), UUID.randomUUID(), HIER);
        JourneyDto b1 = journeyService.lire(user.getId(), true);
        assertThat(b1.targetLevel().name()).isEqualTo("B1");

        declarer(user, TargetProcedure.NAT);
        JourneyDto b2 = journeyService.lire(user.getId(), true);

        assertThat(b2.targetLevel().name()).isEqualTo("B2");
        // 🛑 Le parcours du nouveau niveau est amorce depuis l'historique : les
        // observations ne dependent pas du niveau cible, seule leur SELECTION en
        // depend. Aucun appel LLM, aucun diagnostic.
        assertThat(typesDe(b2)).doesNotContain(JourneyStepType.DIAGNOSTIC);
        assertThat(codesDEntrainement(b2)).isNotEmpty();
        // L'ancien parcours est CONSERVE tel quel.
        assertThat(journeyService.getOrCreate(user.getId())).isPresent();
    }

    // ------------------------------------------------------------- fabriques

    private User candidat(TargetProcedure procedure) {
        return declarer(nouveauCandidat(), procedure);
    }

    private User nouveauCandidat() {
        User user = data.user();
        candidats.add(user.getId());
        return user;
    }

    private User declarer(User user, TargetProcedure procedure) {
        user.setTargetProcedure(procedure);
        user.setTargetLevel(procedure.getRequiredTcfLevel());
        return data.saveUser(user);
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

    private void observationDExamen(User user, Skill skill, UUID examen, Instant quand) {
        data.learningPlanObservation(user, skill,
                skill.getSection() == com.sejourfr.app.enums.SkillSection.EO
                        ? LearningPlanSourceType.MOCK_EXAM_EO
                        : LearningPlanSourceType.MOCK_EXAM_EE,
                LearningPlanSkillStatus.PRIORITY, ObservationConfidence.HIGH, null, quand, examen);
    }

    private static JourneyEvaluation examenDe(UUID id, Instant quand) {
        return new JourneyEvaluation(
                id, JourneyAssessmentKind.SECTION_EXAM, EpreuveType.TCF_EE, quand);
    }

    private static List<JourneyStepType> typesDe(JourneyDto vue) {
        return vue.steps().stream().map(JourneyStepDto::type).distinct().toList();
    }

    private static List<String> codesDEntrainement(JourneyDto vue) {
        return vue.steps().stream()
                .filter(step -> step.type() == JourneyStepType.TRAIN_SKILL)
                .map(JourneyStepDto::skillCode)
                .toList();
    }
}
