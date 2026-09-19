package com.sejourfr.app.service.journey;

import com.sejourfr.app.dto.JourneyBlocDto;
import com.sejourfr.app.dto.JourneyDto;
import com.sejourfr.app.dto.JourneyObjectifRefDto;
import com.sejourfr.app.dto.JourneyStepDto;
import com.sejourfr.app.entity.Journey;
import com.sejourfr.app.entity.JourneyStep;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.JourneyAssessmentKind;
import com.sejourfr.app.enums.JourneyBlocStatus;
import com.sejourfr.app.enums.JourneyState;
import com.sejourfr.app.enums.JourneyStatus;
import com.sejourfr.app.enums.JourneyObjectifKind;
import com.sejourfr.app.enums.JourneyStepResolution;
import com.sejourfr.app.enums.JourneyStepPurpose;
import com.sejourfr.app.enums.JourneyStepStatus;
import com.sejourfr.app.enums.JourneyStepType;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.PlanDomainAssessmentKind;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.manager.SkillManager;
import com.sejourfr.app.repository.JourneyRepository;
import com.sejourfr.app.repository.JourneyStepRepository;
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
import java.util.stream.Stream;

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
    @Autowired private JourneyRepository journeys;
    @Autowired private JourneyStepRepository journeySteps;

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

        JourneyDto vue = journeyService.lire(user.getId(), Module.TCF);

        assertThat(vue.state()).isEqualTo(JourneyState.NEEDS_OBJECTIVE);
        assertThat(vue.objectif()).isNull();
        assertThat(vue.current()).isNull();
        // Aucun parcours : aucun bloc, aucun cycle. Un cycle « vide » aurait
        // laisse croire qu'un parcours existe.
        assertThat(vue.blocs()).isEmpty();
        assertThat(vue.cycle()).isNull();
        // 🛑 Creer un parcours « par defaut » reviendrait a choisir un objectif a
        // sa place, puis a batir une file entiere sur cette supposition.
        assertThat(journeyService.getOrCreate(user.getId(), Module.TCF)).isEmpty();
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

        assertThat(journeyService.lire(user.getId(), Module.TCF).state())
                .isEqualTo(JourneyState.NEEDS_OBJECTIVE);

        declarer(user, TargetProcedure.NAT);
        JourneyDto vue = journeyService.lire(user.getId(), Module.TCF);

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

        JourneyDto vue = journeyService.lire(user.getId(), Module.TCF);

        assertThat(vue.current()).isNotNull();
        assertThat(vue.current().type()).isEqualTo(JourneyStepType.DIAGNOSTIC);
        assertThat(vue.current().status()).isEqualTo(JourneyStepStatus.CURRENT);
        // 🛑 Aucune priorite inventee : le Plan n'apprend rien tant qu'il n'a
        // rien mesure. ⚠️ Lu sur la FILE : une etape DIAGNOSTIC ne porte aucune
        // epreuve, donc elle n'appartient a aucun bloc — `blocs` ne peut pas la
        // montrer, et c'est `current` qui la sert (assertion ci-dessus).
        assertThat(etapes(user, JourneyStatus.EN_COURS))
                .extracting(JourneyStep::getType)
                .containsOnly(JourneyStepType.DIAGNOSTIC);
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

        JourneyDto vue = journeyService.lire(user.getId(), Module.TCF);

        // ⚠️ Lu sur la FILE, pour la meme raison qu'en §18-32 : une etape
        // DIAGNOSTIC n'a pas d'epreuve, donc aucun bloc ne la porte.
        assertThat(vue.current().type()).isEqualTo(JourneyStepType.DIAGNOSTIC);
        assertThat(etapes(user, JourneyStatus.EN_COURS))
                .extracting(JourneyStep::getType)
                .containsOnly(JourneyStepType.DIAGNOSTIC);
    }

    @Test
    @DisplayName("§18-24 / §18-28 — bootstrap depuis l'historique : ni diagnostic, ni etape close")
    void leBootstrapNeFabriqueAucuneEtapeClose() {
        User user = candidat(TargetProcedure.NAT);
        UUID examen = UUID.randomUUID();
        observationDExamen(user, skill(SkillTaskCode.EE1), examen, HIER);
        observationDExamen(user, skill(SkillTaskCode.EE2), examen, HIER);

        JourneyDto vue = journeyService.lire(user.getId(), Module.TCF);

        assertThat(typesDe(vue)).doesNotContain(JourneyStepType.DIAGNOSTIC);
        // 🛑 La timeline d'un nouveau parcours commence par ce qu'il RESTE a
        // faire : inventer des etapes « deja faites » donnerait au candidat un
        // parcours qu'il n'a pas vecu. Lu sur la FILE, pas sur l'ecran : c'est
        // l'absence de cloture qui se prouve, et le DTO n'en montre que le
        // statut derive.
        assertThat(etapes(user, JourneyStatus.EN_COURS))
                .isNotEmpty()
                .allMatch(JourneyStep::estOuverte);
        assertThat(etapesServies(vue)).allSatisfy(step ->
                assertThat(step.status()).isIn(
                        JourneyStepStatus.CURRENT, JourneyStepStatus.UPCOMING));
        assertThat(vue.cycle().etapesTerminees()).isZero();
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

        JourneyDto vue = journeyService.lire(user.getId(), Module.TCF);

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

        JourneyDto vue = journeyService.lire(user.getId(), Module.TCF);

        // Le bloc EE porte ses trois competences, et SON examen a part : c'est
        // l'ecran qui l'imbrique en fin de bloc, il n'est pas une ligne de plus.
        JourneyBlocDto ee = blocDe(vue, EpreuveType.TCF_EE);
        assertThat(ee.steps()).hasSize(3);
        assertThat(ee.steps()).allSatisfy(step ->
                assertThat(step.type()).isEqualTo(JourneyStepType.TRAIN_SKILL));
        // R3 — le lot est TOUJOURS clos par un examen de son epreuve.
        assertThat(ee.exam()).isNotNull();
        assertThat(ee.exam().type()).isEqualTo(JourneyStepType.SECTION_EXAM);
        assertThat(ee.exam().purpose()).isEqualTo(JourneyStepPurpose.REASSESS);
        assertThat(ee.exam().bloc().code()).isEqualTo(EpreuveType.TCF_EE.name());
        // R12 — les trois epreuves non mesurees portent chacune leur « Evaluer
        // mon niveau », et rien d'autre.
        for (EpreuveType epreuve : List.of(
                EpreuveType.TCF_CO, EpreuveType.TCF_CE, EpreuveType.TCF_EO)) {
            JourneyBlocDto bloc = blocDe(vue, epreuve);
            assertThat(bloc.steps()).as("bloc " + epreuve).isEmpty();
            assertThat(bloc.exam()).as("examen du bloc " + epreuve).isNotNull();
            assertThat(bloc.exam().purpose())
                    .isEqualTo(JourneyStepPurpose.INITIAL_ASSESSMENT);
            assertThat(bloc.exam().bloc().code()).isEqualTo(epreuve.name());
        }
        // Sept etapes en tout : 3 competences + le point d'etape EE + 3 mesures.
        assertThat(vue.cycle().etapesTotal()).isEqualTo(3 + 1 + 3);
        // 🛑 PAS d'« Evaluer mon niveau » pour l'EE : son examen de reevaluation
        // est deja prevu, et R12 ne propose que ce qu'aucune etape ne couvre —
        // sinon le candidat verrait deux examens EE d'affilee. Lu sur la FILE :
        // un bloc ne sert qu'UN examen, donc un doublon y serait invisible.
        assertThat(etapes(user, JourneyStatus.EN_COURS))
                .filteredOn(step -> step.getExamType() == EpreuveType.TCF_EE
                        && step.getType() == JourneyStepType.SECTION_EXAM)
                .hasSize(1);
        // R12 cree ses mesures dans l'ordre CO, CE, EO — un fait de la FILE, que
        // le groupement par bloc ne prouve plus (les blocs sont TOUJOURS dans
        // cet ordre, peuples ou non).
        assertThat(etapes(user, JourneyStatus.EN_COURS).stream()
                .filter(step -> step.getPurpose() == JourneyStepPurpose.INITIAL_ASSESSMENT)
                .map(JourneyStep::getExamType))
                .containsExactly(
                        EpreuveType.TCF_CO, EpreuveType.TCF_CE, EpreuveType.TCF_EO);
    }

    // =====================================================================
    // R7 / R14 — une evaluation arrive
    // =====================================================================

    @Test
    @DisplayName("D-15 — examen EE hors Plan, competences dues : RIEN n'est valide, aucun SUPERSEDED")
    void unExamenNeSauteJamaisLeTravailRestant() {
        User user = candidat(TargetProcedure.NAT);
        Skill duPremierLot = skill(SkillTaskCode.EE1, 0);
        Skill detecteeEnsuite = skill(SkillTaskCode.EE1, 1);
        observationDExamen(user, duPremierLot, UUID.randomUUID(), HIER);
        journeyService.lire(user.getId(), Module.TCF);
        assertThat(codesDEntrainement(journeyService.lire(user.getId(), Module.TCF)))
                .containsExactly(duPremierLot.getCode());

        UUID second = UUID.randomUUID();
        observationDExamen(user, detecteeEnsuite, second, MAINTENANT);
        journeyService.onAssessmentCompleted(user.getId(), examenDe(second, MAINTENANT));

        JourneyDto vue = journeyService.lire(user.getId(), Module.TCF);
        // 🛑 CE QUE D-15 A REVOQUE. La regle du 2026-09-17 disait : « des etapes
        // TRAIN_SKILL du lot sont encore en attente → les etapes non cloturees
        // du lot ET son checkpoint sont cloturees SUPERSEDED, lot SUPERSEDED ».
        // Passer un examen ne saute plus le travail restant : il reste DU.
        assertThat(codesDEntrainement(vue)).containsExactly(duPremierLot.getCode());
        assertThat(etapes(user, JourneyStatus.EN_COURS))
                .noneMatch(step -> step.getResolution() == JourneyStepResolution.SUPERSEDED);
        // Le point d'etape du lot reste ouvert : l'examen ne l'a pas satisfait,
        // parce qu'il etait VERROUILLE au moment du passage. Meme question posee
        // a l'ecriture et a la lecture.
        assertThat(etapes(user, JourneyStatus.EN_COURS))
                .filteredOn(step -> step.getType() == JourneyStepType.SECTION_EXAM
                        && step.getExamType() == EpreuveType.TCF_EE)
                .allMatch(JourneyStep::estOuverte);
        // Et la priorite nouvellement detectee n'est pas perdue : elle attend
        // dans le cycle EN ATTENTE, invisible du candidat (D-13).
        assertThat(codesDEntrainement(vue)).doesNotContain(detecteeEnsuite.getCode());
        assertThat(competencesEnAttente(user)).containsExactly(detecteeEnsuite.getCode());
    }

    @Test
    @DisplayName("D-15 — examen hors Plan sur un bloc SANS competence due : l'etape est cloturee")
    void unExamenClotLEtapeDUnBlocPret() {
        User user = candidat(TargetProcedure.NAT);
        Skill competence = skill(SkillTaskCode.EE1, 0);
        observationDExamen(user, competence, UUID.randomUUID(), HIER);
        journeyService.lire(user.getId(), Module.TCF);
        // La competence du bloc EE est faite : le bloc est pret, son examen est
        // debloque.
        cloreLEntrainement(user, competence);

        // 🛑 Une epreuve REELLEMENT passee, pas un identifiant tire au hasard :
        // sans elle, l'EE resterait « jamais mesuree » pour son autorite et R12
        // rajouterait aussitot un « Evaluer mon niveau » — le test ne lirait
        // plus ce qu'il croit lire.
        UUID examen = data.epreuveProductionPassee(
                user, EpreuveType.TCF_EE, NiveauCecrl.B1).getId();
        observationDExamen(user, competence, examen, MAINTENANT);
        journeyService.onAssessmentCompleted(user.getId(), examenDe(examen, MAINTENANT));

        // ✅ L'etape SECTION_EXAM de l'EE est cloturee : on ne demande jamais de
        // refaire un examen qu'on vient de passer (R7), et le bloc etait pret.
        assertThat(etapes(user, JourneyStatus.EN_COURS))
                .filteredOn(step -> step.getType() == JourneyStepType.SECTION_EXAM
                        && step.getExamType() == EpreuveType.TCF_EE)
                .isNotEmpty()
                .allMatch(step -> !step.estOuverte()
                        && step.getResolution()
                        == JourneyStepResolution.SATISFIED_BY_ASSESSMENT);
        // Le bloc EE est termine : le cycle le lit ainsi.
        assertThat(blocDe(journeyService.lire(user.getId(), Module.TCF), EpreuveType.TCF_EE).status())
                .isEqualTo(JourneyBlocStatus.TERMINE);
    }

    @Test
    @DisplayName("D-15 — une SOUS-EPREUVE d'examen complet clot l'etape de son bloc comme les autres")
    void uneSousEpreuveDExamenCompletClotLEtapeDeSonBloc() {
        User user = candidat(TargetProcedure.NAT);
        observationDExamen(user, skill(SkillTaskCode.EE1), UUID.randomUUID(), HIER);
        journeyService.lire(user.getId(), Module.TCF);

        // Une sous-epreuve EO d'examen blanc complet : un attempt a part
        // entiere, donc une evaluation a part entiere — et reellement passee,
        // pour que l'EO compte comme mesuree (sinon R12 rajoute son examen).
        UUID sousEpreuve = data.epreuveProductionPassee(
                user, EpreuveType.TCF_EO, NiveauCecrl.B1).getId();
        data.learningPlanObservation(user, skill(SkillTaskCode.EO1),
                LearningPlanSourceType.MOCK_EXAM_EO, LearningPlanSkillStatus.PRIORITY,
                ObservationConfidence.HIGH, null, MAINTENANT, sousEpreuve);
        journeyService.onAssessmentCompleted(user.getId(), new JourneyEvaluation(
                sousEpreuve, JourneyAssessmentKind.MOCK_EXAM, EpreuveType.TCF_EO, MAINTENANT));

        // Le bloc EO ne portait que son « Evaluer mon niveau » : il etait pret.
        assertThat(etapes(user, JourneyStatus.EN_COURS))
                .filteredOn(step -> step.getType() == JourneyStepType.SECTION_EXAM
                        && step.getExamType() == EpreuveType.TCF_EO)
                .isNotEmpty()
                .allMatch(step -> !step.estOuverte());
    }

    // =====================================================================
    // D-13 — le cycle EN ATTENTE
    // =====================================================================

    @Test
    @DisplayName("D-13 — une competence deja CLOTUREE n'est pas recreee sur un TO_REINFORCE")
    void uneCompetenceClotureeNEstPasRecreeeSansRegression() {
        User user = candidat(TargetProcedure.NAT);
        Skill competence = skill(SkillTaskCode.EE1, 0);
        observationDExamen(user, competence, UUID.randomUUID(), HIER);
        journeyService.lire(user.getId(), Module.TCF);
        cloreLEntrainement(user, competence);

        UUID examen = UUID.randomUUID();
        data.learningPlanObservation(user, competence, LearningPlanSourceType.MOCK_EXAM_EE,
                LearningPlanSkillStatus.TO_REINFORCE, ObservationConfidence.MEDIUM, null,
                MAINTENANT, examen);
        journeyService.onAssessmentCompleted(user.getId(), examenDe(examen, MAINTENANT));

        // 🛑 Un TO_REINFORCE sur une competence deja travaillee ne rouvre RIEN :
        // sinon chaque examen rendrait tout le cycle precedent a refaire, et le
        // candidat ne finirait jamais un cycle.
        assertThat(competencesEnAttente(user)).isEmpty();
        // Creation paresseuse : rien a mettre en attente, aucune ligne creee.
        assertThat(cycle(user, JourneyStatus.EN_ATTENTE)).isNull();
    }

    @Test
    @DisplayName("D-13 — une competence deja CLOTUREE revient si l'examen la classe PRIORITY")
    void uneRegressionMesureeRemetLaCompetenceEnAttente() {
        User user = candidat(TargetProcedure.NAT);
        Skill competence = skill(SkillTaskCode.EE1, 0);
        observationDExamen(user, competence, UUID.randomUUID(), HIER);
        journeyService.lire(user.getId(), Module.TCF);
        cloreLEntrainement(user, competence);

        UUID examen = UUID.randomUUID();
        observationDExamen(user, competence, examen, MAINTENANT);
        journeyService.onAssessmentCompleted(user.getId(), examenDe(examen, MAINTENANT));

        // PRIORITY est le signal le plus fort : la regression est MESUREE, la
        // competence revient — dans le cycle SUIVANT, jamais dans celui-ci
        // (une cloture ne se reouvre jamais, D-7).
        assertThat(competencesEnAttente(user)).containsExactly(competence.getCode());
        // 🛑 Elle ne redevient PAS due dans le cycle en cours : une cloture ne se
        // reouvre jamais (D-7). L'etape close reste affichee, cochee — une
        // etape franchie ne disparait pas du parcours.
        assertThat(etapes(user, JourneyStatus.EN_COURS))
                .filteredOn(JourneyStep::estOuverte)
                .noneMatch(step -> step.getType() == JourneyStepType.TRAIN_SKILL);
    }

    @Test
    @DisplayName("§18-16 / §18-29 — la meme evaluation deux fois : le second passage est sans effet")
    void uneEvaluationNestTraiteeQuUneFois() {
        User user = candidat(TargetProcedure.NAT);
        UUID examen = UUID.randomUUID();
        observationDExamen(user, skill(SkillTaskCode.EE1), examen, MAINTENANT);
        journeyService.lire(user.getId(), Module.TCF);
        // 🛑 Compte sur la FILE, pas sur l'ecran : « ne dedouble ni le lot ni
        // ses etapes » est un fait de la base, et un doublon d'examen dans un
        // bloc ne se verrait pas dans `exam`, qui n'en sert qu'un.
        int avant = etapes(user, JourneyStatus.EN_COURS).size();

        journeyService.onAssessmentCompleted(user.getId(), examenDe(examen, MAINTENANT));
        journeyService.onAssessmentCompleted(user.getId(), examenDe(examen, MAINTENANT));

        // Le bootstrap a deja enregistre cette evaluation : la rejouer ne
        // dedouble ni le lot, ni ses etapes.
        assertThat(etapes(user, JourneyStatus.EN_COURS)).hasSize(avant);
    }

    @Test
    @DisplayName("§18-17 — une evaluation plus ANCIENNE ne defait pas une plus recente")
    void uneEvaluationTardiveNeDefaitPasLaPlusRecente() {
        User user = candidat(TargetProcedure.NAT);
        UUID recente = UUID.randomUUID();
        observationDExamen(user, skill(SkillTaskCode.EE1), recente, MAINTENANT);
        journeyService.lire(user.getId(), Module.TCF);
        List<String> avant = codesDEntrainement(journeyService.lire(user.getId(), Module.TCF));

        // Une session jouee hors ligne sur mobile, synchronisee apres coup.
        UUID tardive = UUID.randomUUID();
        observationDExamen(user, skill(SkillTaskCode.EE2), tardive, HIER);
        journeyService.onAssessmentCompleted(user.getId(), examenDe(tardive, HIER));

        assertThat(codesDEntrainement(journeyService.lire(user.getId(), Module.TCF)))
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
        JourneyDto vue = journeyService.lire(user.getId(), Module.TCF);

        // R9 — « aucune priorite detectee » n'est pas une declaration de
        // maitrise, et ce n'est pas une anomalie : zero fragilite, zero lot.
        assertThat(codesDEntrainement(vue)).isEmpty();
        // Aucun point d'etape n'a ete cree : lu sur la FILE, la ou un examen de
        // lot existerait s'il y en avait un.
        assertThat(etapes(user, JourneyStatus.EN_COURS))
                .noneMatch(step -> step.getPurpose() == JourneyStepPurpose.REASSESS);
    }

    @Test
    @DisplayName("§18-15 — un diagnostic rapide ne touche pas un lot deja ouvert (R11)")
    void unDiagnosticRapideNeRemplaceJamaisUnLotOuvert() {
        User user = candidat(TargetProcedure.NAT);
        UUID examen = UUID.randomUUID();
        observationDExamen(user, skill(SkillTaskCode.EE1), examen, HIER);
        journeyService.lire(user.getId(), Module.TCF);
        List<String> avant = codesDEntrainement(journeyService.lire(user.getId(), Module.TCF));

        UUID diagnostic = UUID.randomUUID();
        data.learningPlanObservation(user, skill(SkillTaskCode.EE2),
                LearningPlanSourceType.DIAGNOSTIC_EE, LearningPlanSkillStatus.PRIORITY,
                ObservationConfidence.HIGH, null, MAINTENANT, diagnostic);
        journeyService.onAssessmentCompleted(
                user.getId(), JourneyEvaluation.diagnosticRapide(diagnostic, MAINTENANT));

        assertThat(codesDEntrainement(journeyService.lire(user.getId(), Module.TCF)))
                .containsExactlyElementsOf(avant);
    }

    @Test
    @DisplayName("§18-9 / D-13 — une evaluation d'une AUTRE epreuve ne deplace rien, et sa "
            + "priorite attend le cycle suivant")
    void uneEvaluationDUneAutreEpreuveNeDeplaceRien() {
        User user = candidat(TargetProcedure.NAT);
        UUID examenEe = UUID.randomUUID();
        observationDExamen(user, skill(SkillTaskCode.EE1), examenEe, HIER);
        journeyService.lire(user.getId(), Module.TCF);
        // 🛑 « Rien ne bouge devant » se lit sur la FILE : le groupement par
        // epreuve range les etapes par bloc, il ne dit plus qui est en tete de
        // file. C'est `position` qui porte cet ordre, et elle est monotone.
        long positionPremiere = etapes(user, JourneyStatus.EN_COURS)
                .getFirst().getPosition();

        UUID examenEo = data.epreuveProductionPassee(
                user, EpreuveType.TCF_EO, NiveauCecrl.B1).getId();
        Skill deLEo = skill(SkillTaskCode.EO1);
        data.learningPlanObservation(user, deLEo,
                LearningPlanSourceType.MOCK_EXAM_EO, LearningPlanSkillStatus.PRIORITY,
                ObservationConfidence.HIGH, null, MAINTENANT, examenEo);
        journeyService.onAssessmentCompleted(user.getId(),
                new JourneyEvaluation(examenEo, JourneyAssessmentKind.SECTION_EXAM,
                        EpreuveType.TCF_EO, MAINTENANT));

        JourneyDto vue = journeyService.lire(user.getId(), Module.TCF);
        // R4 — rien ne bouge devant : la nouvelle priorite ne remplace jamais
        // l'etape courante et ne passe jamais devant un examen deja prevu.
        JourneyStep premiere = etapes(user, JourneyStatus.EN_COURS).getFirst();
        assertThat(premiere.getPosition()).isEqualTo(positionPremiere);
        assertThat(premiere.getSkill()).isNotNull();
        // 🛑 CE QUE D-13 A CHANGE. Le cycle en cours est BORNE : il ne grossit
        // plus. La priorite detectee par cet examen part dans le cycle EN
        // ATTENTE, invisible du candidat, et deviendra son prochain cycle.
        // ⚠️ Avant le 2026-09-18, elle s'ajoutait en fin de file du cycle en
        // cours — un parcours qui s'allongeait indefiniment, sans jamais finir.
        assertThat(codesDEntrainement(vue)).doesNotContain(deLEo.getCode());
        assertThat(competencesEnAttente(user)).containsExactly(deLEo.getCode());
        // §18-12 — l'« Evaluer mon niveau » de l'EO est CLOS : on ne demande
        // jamais de refaire un examen qu'on vient de passer (R7), et le bloc EO
        // ne portait aucune competence due. Il reste AFFICHE, coche : une etape
        // franchie ne disparait pas du parcours.
        // Le bloc EO ne porte qu'un examen : c'est celui-la, et il est servi
        // ferme — « le dernier clos » quand il n'y a plus d'examen ouvert.
        JourneyStepDto evaluerLEo = blocDe(vue, EpreuveType.TCF_EO).exam();
        assertThat(evaluerLEo).isNotNull();
        assertThat(evaluerLEo.purpose())
                .isEqualTo(JourneyStepPurpose.INITIAL_ASSESSMENT);
        assertThat(evaluerLEo.status())
                .isIn(JourneyStepStatus.COMPLETED, JourneyStepStatus.SKIPPED);
    }

    // =====================================================================
    // R18 — changement d'objectif
    // =====================================================================

    @Test
    @DisplayName("§18-22 / §18-23 — changer d'objectif garde le cycle, sans redemander de diagnostic")
    void changerDObjectifNeForceJamaisUnDiagnostic() {
        User user = candidat(TargetProcedure.CR);
        observationDExamen(user, skill(SkillTaskCode.EE1), UUID.randomUUID(), HIER);
        JourneyDto b1 = journeyService.lire(user.getId(), Module.TCF);
        assertThat(b1.objectif().code()).isEqualTo("B1");
        UUID cycle = journeyService.getOrCreate(user.getId(), Module.TCF).orElseThrow().getId();

        declarer(user, TargetProcedure.NAT);
        JourneyDto b2 = journeyService.lire(user.getId(), Module.TCF);

        assertThat(b2.objectif().code()).isEqualTo("B2");
        // 🛑 Le cycle EN COURS SURVIT et son niveau cible est mis a jour (D-13) :
        // l'historiser jetterait le plan que le candidat a sous les yeux, et les
        // priorites deja designees ne deviennent pas fausses parce que la cible
        // a bouge — seul l'ORDRE des lots est recalcule, et il est derive.
        assertThat(journeyService.getOrCreate(user.getId(), Module.TCF).orElseThrow().getId())
                .isEqualTo(cycle);
        // Aucun appel LLM, aucun diagnostic : les observations ne dependent pas
        // du niveau cible, seule leur SELECTION en depend.
        assertThat(typesDe(b2)).doesNotContain(JourneyStepType.DIAGNOSTIC);
        assertThat(codesDEntrainement(b2)).isNotEmpty();
    }

    // =====================================================================
    // §16 / A24 — l'action d'une etape d'examen est SERVIE
    // =====================================================================

    @Test
    @DisplayName("§16-3 — le checkpoint d'un lot porte SA mesure, alors que l'epreuve est deja mesuree")
    void leCheckpointDUnLotPorteSaMesure() {
        User user = candidat(TargetProcedure.NAT);
        observationDExamen(user, skill(SkillTaskCode.EE1), UUID.randomUUID(), HIER);

        JourneyDto vue = journeyService.lire(user.getId(), Module.TCF);

        JourneyStepDto checkpoint = blocDe(vue, EpreuveType.TCF_EE).exam();
        assertThat(checkpoint).isNotNull();
        assertThat(checkpoint.purpose()).isEqualTo(JourneyStepPurpose.REASSESS);
        // 🛑 L'EE vient d'etre mesuree — c'est elle qui a cree le lot. Elle ne
        // figure donc PAS dans `domainesAEvaluer`, qui ne liste que le
        // jamais-mesure, et la seance ne porte que la mesure indispensable.
        // Sans cette ligne servie, les fronts ne resolvaient AUCUNE action pour
        // le checkpoint de chaque lot — le cas le plus courant du parcours — et
        // retombaient sur `currentPriority`, une AUTRE competence que celle que
        // la carte annoncait.
        assertThat(checkpoint.assessment()).isNotNull();
        assertThat(checkpoint.assessment().epreuve()).isEqualTo(EpreuveType.TCF_EE);
        assertThat(checkpoint.assessment().kind())
                .isEqualTo(PlanDomainAssessmentKind.PRODUCTION_MOCK_EXAM);
        // Le slot OFFERT, celui que `PlanDomainAssessmentResolver` sert partout
        // ailleurs : mesurer un domaine ne bute jamais sur le paywall.
        assertThat(checkpoint.assessment().slotNumber()).isEqualTo(1);
    }

    @Test
    @DisplayName("§16-4 — une etape d'entrainement ne mesure rien, et l'examen CO porte son type de questions")
    void seulesLesEtapesDExamenPortentUneMesure() {
        User user = candidat(TargetProcedure.NAT);
        observationDExamen(user, skill(SkillTaskCode.EE1), UUID.randomUUID(), HIER);

        JourneyDto vue = journeyService.lire(user.getId(), Module.TCF);

        assertThat(vue.blocs().stream()
                .flatMap(bloc -> bloc.steps().stream())
                .map(JourneyStepDto::assessment))
                .isNotEmpty()
                .containsOnlyNulls();
        // R12 — la CO n'est pas mesuree, son « Evaluer mon niveau » est dans la
        // file : sa mesure est l'examen de module, avec le type de questions que
        // `StartAttemptRequest` attend. Rien n'est compose par les fronts.
        JourneyStepDto co = blocDe(vue, EpreuveType.TCF_CO).exam();
        assertThat(co).isNotNull();
        assertThat(co.assessment()).isNotNull();
        assertThat(co.assessment().kind())
                .isEqualTo(PlanDomainAssessmentKind.MODULE_MOCK_EXAM);
        assertThat(co.assessment().moduleExamQuestionType()).isEqualTo(QuestionType.CO);
    }

    // ------------------------------------------------------------- fabriques

    // =====================================================================
    // D-50 — LE CYCLE CIVIQUE : son module, son objectif, et les deux ensemble
    // =====================================================================

    @Test
    @DisplayName("§18-46 — un cycle CIVIQUE porte sa MENTION, et aucun palier")
    void leCycleCiviquePorteSaMention() {
        User user = candidat(TargetProcedure.NAT);

        Journey civique = journeyService
                .getOrCreate(user.getId(), Module.CIVIQUE).orElseThrow();

        assertThat(civique.getModule()).isEqualTo(Module.CIVIQUE);
        assertThat(civique.getTargetProcedure()).isEqualTo(TargetProcedure.NAT);
        // 🛑 `chk_journey_objectif` (V069) exige EXACTEMENT un objectif : le
        // palier reste nul, et `poserObjectif` le garantit a la source.
        assertThat(civique.getTargetLevel()).isNull();
    }

    @Test
    @DisplayName("§18-47 — 🛑 le meme candidat a DEUX cycles distincts, un par module")
    void unCycleParModuleEtIlsNeSeConfondentPas() {
        User user = candidat(TargetProcedure.CSP);

        Journey tcf = journeyService.getOrCreate(user.getId(), Module.TCF).orElseThrow();
        Journey civique = journeyService
                .getOrCreate(user.getId(), Module.CIVIQUE).orElseThrow();

        // ⚠️ LE PIEGE QUE CE TEST FERME. `getOrCreate` etait cable `Module.TCF` :
        // un candidat civique obtenait le cycle TCF — cree, lui, parce que
        // `niveauVise(CSP, null)` rend A2 par PLANCHER et jamais null — et
        // n'avait JAMAIS de cycle civique. Deux questions, deux reponses : la
        // mention dit la demarche visee, le palier dit le francais qu'elle exige.
        assertThat(civique.getId()).isNotEqualTo(tcf.getId());
        assertThat(tcf.getTargetLevel()).isEqualTo(TargetLevel.A2);
        assertThat(tcf.getTargetProcedure()).isNull();
        assertThat(civique.getTargetProcedure()).isEqualTo(TargetProcedure.CSP);
    }

    @Test
    @DisplayName("§18-48 — changer de mention garde le MEME cycle civique (D-34)")
    void changerDeMentionGardeLeCycleCivique() {
        User user = candidat(TargetProcedure.CR);
        UUID cycle = journeyService
                .getOrCreate(user.getId(), Module.CIVIQUE).orElseThrow().getId();

        declarer(user, TargetProcedure.NAT);
        Journey apres = journeyService
                .getOrCreate(user.getId(), Module.CIVIQUE).orElseThrow();

        // A27, transposee : le cycle SURVIT avec le meme id et son objectif est
        // mis a jour. L'historiser jetterait le plan que le candidat a sous les
        // yeux, et un ping-pong de mention remplirait son historique de cycles
        // fantomes.
        assertThat(apres.getId()).isEqualTo(cycle);
        assertThat(apres.getTargetProcedure()).isEqualTo(TargetProcedure.NAT);
    }

    @Test
    @DisplayName("§18-49 — aucune mention declaree : AUCUN cycle civique (D-3 transpose)")
    void sansMentionAucunCycleCivique() {
        User user = nouveauCandidat();
        user.setTargetProcedure(null);
        user.setTargetLevel(TargetLevel.B2);
        data.saveUser(user);

        // 🛑 Un palier declare n'ouvre PAS un cycle civique : ce serait choisir
        // une demarche a la place du candidat. L'objectif civique ne se derive
        // pas de `niveauVise`, qui ne parle que de francais.
        assertThat(journeyService.getOrCreate(user.getId(), Module.CIVIQUE)).isEmpty();
        assertThat(journeyService.getOrCreate(user.getId(), Module.TCF)).isPresent();
    }

    @Test
    @DisplayName("§18-50 — l'objectif est SERVI : sa nature, son code, son libelle")
    void lObjectifEstServi() {
        User user = candidat(TargetProcedure.NAT);

        Journey tcf = journeyService.getOrCreate(user.getId(), Module.TCF).orElseThrow();
        Journey civique = journeyService
                .getOrCreate(user.getId(), Module.CIVIQUE).orElseThrow();

        assertThat(tcf.objectifRef())
                .isEqualTo(new JourneyObjectifRefDto(JourneyObjectifKind.NIVEAU, "B2", "B2"));
        // 🛑 Le LIBELLE est servi, comme celui du bloc (A48) : c'est le mot du
        // livret, et aucun front ne le fabrique.
        assertThat(civique.objectifRef()).isEqualTo(new JourneyObjectifRefDto(
                JourneyObjectifKind.PROCEDURE, "NAT", "Naturalisation"));
    }

    // =====================================================================

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

    /** Le cycle du candidat dans cet etat, ou {@code null} s'il n'existe pas. */
    private Journey cycle(User user, JourneyStatus status) {
        return journeys.findByUserIdAndModuleAndStatus(user.getId(), Module.TCF, status)
                .orElse(null);
    }

    /** Les etapes reellement en base — y compris celles que le DTO n'affiche pas. */
    private List<JourneyStep> etapes(User user, JourneyStatus status) {
        Journey journey = cycle(user, status);
        return journey == null ? List.of() : journeySteps.findAllByJourney(journey.getId());
    }

    /**
     * Les competences que le cycle EN ATTENTE porte. 🛑 Il est <b>invisible du
     * candidat</b> : aucun endpoint ne le sert, donc un test qui veut le voir
     * lit la base.
     */
    private List<String> competencesEnAttente(User user) {
        return etapes(user, JourneyStatus.EN_ATTENTE).stream()
                .filter(step -> step.getType() == JourneyStepType.TRAIN_SKILL)
                .map(step -> step.getSkill().getCode())
                .toList();
    }

    /**
     * Clot l'etape d'entrainement de cette competence, comme le ferait le quota
     * atteint (R8). Ecrit directement : ce qui est teste ici est ce que
     * l'EVALUATION suivante fait d'une etape deja close, pas le comptage du
     * quota — celui-la est verrouille par {@code JourneyProgressionIT}.
     */
    private void cloreLEntrainement(User user, Skill competence) {
        JourneyStep etape = etapes(user, JourneyStatus.EN_COURS).stream()
                .filter(step -> step.getType() == JourneyStepType.TRAIN_SKILL)
                .filter(step -> step.getSkill() != null
                        && step.getSkill().getId().equals(competence.getId()))
                .findFirst()
                .orElseThrow(() -> new AssertionError(
                        "Aucune etape d'entrainement pour " + competence.getCode()));
        etape.clore(JourneyStepResolution.QUOTA_REACHED, null, Instant.now());
        journeySteps.saveAndFlush(etape);
    }

    private static JourneyBlocDto blocDe(JourneyDto vue, EpreuveType epreuve) {
        return vue.blocs().stream()
                .filter(bloc -> epreuve.name().equals(bloc.bloc().code()))
                .findFirst()
                .orElseThrow(() -> new AssertionError("Aucun bloc " + epreuve));
    }

    /**
     * <b>Tout ce que la vue sert</b> : les etapes de chaque bloc et son examen.
     *
     * <p>⚠️ Ce n'est <b>pas</b> l'ancien {@code JourneyDto.steps}, disparu en
     * P6 : {@code JourneyBlocDto.steps} exclut l'examen, et {@code exam} n'en
     * porte qu'<b>un</b> par bloc (l'ouvert, sinon le dernier clos). Une
     * assertion qui a besoin de <b>toutes</b> les etapes — un doublon, un
     * compte, un ordre de file — lit {@code etapes(user, status)}, la base.
     */
    private static List<JourneyStepDto> etapesServies(JourneyDto vue) {
        return vue.blocs().stream()
                .flatMap(bloc -> Stream.concat(
                        bloc.steps().stream(),
                        bloc.exam() == null ? Stream.empty() : Stream.of(bloc.exam())))
                .toList();
    }

    private static List<JourneyStepType> typesDe(JourneyDto vue) {
        return etapesServies(vue).stream()
                .map(JourneyStepDto::type).distinct().toList();
    }

    private static List<String> codesDEntrainement(JourneyDto vue) {
        return vue.blocs().stream()
                .flatMap(bloc -> bloc.steps().stream())
                .map(JourneyStepDto::skillCode)
                .toList();
    }
}
