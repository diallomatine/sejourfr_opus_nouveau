package com.sejourfr.app.service;

import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.manager.LearningPlanObservationManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * L'<b>unique</b> autorite sur l'ordre et la selection des priorites du Plan.
 *
 * <p>Deux lecteurs en dependent — le Plan lui-meme et {@code SkillAccessService},
 * qui ouvre la competence de la priorite n&deg;1 a un compte gratuit —, donc ce
 * qui est verrouille ici l'est pour les deux.
 */
class LearningPlanPriorityResolverTest {

    private LearningPlanObservationManager observationManager;
    private LearningPlanPriorityResolver resolver;

    private final UUID userId = UUID.randomUUID();
    private final Instant maintenant = Instant.now();

    @BeforeEach
    void setUp() {
        observationManager = mock(LearningPlanObservationManager.class);
        resolver = new LearningPlanPriorityResolver(observationManager);
    }

    // ------------------------------------------------------------------------
    // Ordre : rien de ce qui existait ne bouge
    // ------------------------------------------------------------------------

    @Test
    void lOrdreResteStatutPuisConfiancePuisRecence() {
        Skill priorite = skill("EE1-C1");
        Skill sureMaisAncienne = skill("EE2-C2");
        Skill moinsSureEtRecente = skill("EO1-C3");
        Skill quatrieme = skill("EO3-C4");

        List<LearningPlanObservation> actionable = resolver.actionable(historique(
                observation(moinsSureEtRecente, LearningPlanSkillStatus.TO_REINFORCE,
                        LearningPlanSourceType.PRODUCTION_EO, ObservationConfidence.LOW, jours(1)),
                observation(priorite, LearningPlanSkillStatus.PRIORITY,
                        LearningPlanSourceType.PRODUCTION_EE, ObservationConfidence.LOW, jours(9)),
                observation(sureMaisAncienne, LearningPlanSkillStatus.TO_REINFORCE,
                        LearningPlanSourceType.PRODUCTION_EE, ObservationConfidence.HIGH, jours(5)),
                observation(quatrieme, LearningPlanSkillStatus.TO_REINFORCE,
                        LearningPlanSourceType.PRODUCTION_EE, ObservationConfidence.LOW, jours(20))));

        assertThat(actionable).hasSize(LearningPlanPriorityResolver.MAX_PRIORITIES);
        assertThat(codes(actionable)).containsExactly("EE1-C1", "EE2-C2", "EO1-C3");
    }

    // ------------------------------------------------------------------------
    // « Une fois reussi, on passe a la competence suivante »
    // ------------------------------------------------------------------------

    /**
     * Le cas central : la verification en situation a reussi. La competence sort
     * des priorites, la suivante devient l'etape n&deg;1 — y compris pour le
     * verrou freemium, qui lit la meme methode.
     */
    @Test
    void uneReussiteEnSituationSortLaCompetenceDesPriorites() {
        Skill reussie = skill("EE1-C1");
        Skill suivante = skill("EE1-C2");
        List<LearningPlanObservation> historique = historique(
                observation(reussie, LearningPlanSkillStatus.SOLID,
                        LearningPlanSourceType.PRODUCTION_EE, ObservationConfidence.HIGH, jours(1)),
                observation(reussie, LearningPlanSkillStatus.PRIORITY,
                        LearningPlanSourceType.DIAGNOSTIC_EE, ObservationConfidence.HIGH, jours(30)),
                observation(suivante, LearningPlanSkillStatus.TO_REINFORCE,
                        LearningPlanSourceType.DIAGNOSTIC_EE, ObservationConfidence.HIGH, jours(30)));
        when(observationManager.findAllByUserWithSkill(userId)).thenReturn(historique);

        assertThat(codes(resolver.actionable(historique))).containsExactly("EE1-C2");
        assertThat(resolver.currentPrioritySkillId(userId))
                .contains(suivante.getId());
    }

    /**
     * Un examen blanc est aussi une production en situation : c'est meme la
     * preuve la moins assistee dont on dispose.
     */
    @Test
    void unExamenBlancProuveLeTransfertAuMemeTitreQuUneProduction() {
        Skill reussie = skill("EO2-C4");
        List<LearningPlanObservation> historique = historique(
                observation(reussie, LearningPlanSkillStatus.SOLID,
                        LearningPlanSourceType.MOCK_EXAM_EO, ObservationConfidence.MEDIUM, jours(2)),
                observation(reussie, LearningPlanSkillStatus.PRIORITY,
                        LearningPlanSourceType.DIAGNOSTIC_EO, ObservationConfidence.HIGH, jours(40)));

        assertThat(resolver.actionable(historique)).isEmpty();
    }

    /**
     * Un micro-exercice rate <b>apres</b> la preuve ne remet pas la competence en
     * tete : c'est exactement ce que corrige cette regle. Meme sens que
     * {@code SkillMasteryEngine}, ou seules les fragilites contextualisees
     * peuvent defaire un transfert deja prouve.
     */
    @Test
    void unMicroExerciceRateApresLaPreuveNeRamenePasLaCompetence() {
        Skill reussie = skill("EE3-C2");
        List<LearningPlanObservation> historique = historique(
                observation(reussie, LearningPlanSkillStatus.PRIORITY,
                        LearningPlanSourceType.SKILL_TRAINING, ObservationConfidence.MEDIUM,
                        jours(1)),
                observation(reussie, LearningPlanSkillStatus.SOLID,
                        LearningPlanSourceType.PRODUCTION_EE, ObservationConfidence.HIGH, jours(3)));

        assertThat(resolver.actionable(historique)).isEmpty();
    }

    /**
     * Un {@code SOLID} venu d'un <b>micro-entrainement</b> ne prouve aucun
     * transfert : l'exercice est guide vers cette seule competence.
     */
    @Test
    void unSolidDeMicroEntrainementNeSortPasLaCompetenceDesPriorites() {
        Skill skill = skill("EE1-C5");
        List<LearningPlanObservation> historique = historique(
                observation(skill, LearningPlanSkillStatus.PRIORITY,
                        LearningPlanSourceType.SKILL_TRAINING, ObservationConfidence.MEDIUM,
                        jours(1)),
                observation(skill, LearningPlanSkillStatus.SOLID,
                        LearningPlanSourceType.SKILL_TRAINING, ObservationConfidence.MEDIUM,
                        jours(4)));

        assertThat(codes(resolver.actionable(historique))).containsExactly("EE1-C5");
    }

    /** Le diagnostic est la <b>baseline</b> : il ne confirme jamais rien. */
    @Test
    void unSolidDeDiagnosticNeSortPasLaCompetenceDesPriorites() {
        Skill skill = skill("EO1-C6");
        List<LearningPlanObservation> historique = historique(
                observation(skill, LearningPlanSkillStatus.TO_REINFORCE,
                        LearningPlanSourceType.SKILL_TRAINING, ObservationConfidence.MEDIUM,
                        jours(2)),
                observation(skill, LearningPlanSkillStatus.SOLID,
                        LearningPlanSourceType.DIAGNOSTIC_EO, ObservationConfidence.HIGH, jours(30)));

        assertThat(codes(resolver.actionable(historique))).containsExactly("EO1-C6");
    }

    /**
     * <b>Rien n'est verrouille definitivement</b> : une production ulterieure qui
     * fragilise la competence la ramene parmi les priorites. C'est la derniere
     * preuve en situation qui fait foi, pas « au moins une dans toute
     * l'histoire ».
     */
    @Test
    void uneCompetenceFragiliseeParUneProductionUlterieureRedevientPriorite() {
        Skill skill = skill("EE2-C7");
        List<LearningPlanObservation> historique = historique(
                observation(skill, LearningPlanSkillStatus.TO_REINFORCE,
                        LearningPlanSourceType.PRODUCTION_EO, ObservationConfidence.HIGH, jours(1)),
                observation(skill, LearningPlanSkillStatus.SOLID,
                        LearningPlanSourceType.PRODUCTION_EE, ObservationConfidence.HIGH, jours(15)));

        assertThat(codes(resolver.actionable(historique))).containsExactly("EE2-C7");
    }

    /**
     * Une observation non probante ne contredit rien : {@code NOT_OBSERVED} veut
     * dire « aucune preuve ici », pas « le candidat a echoue ». La preuve
     * anterieure tient.
     */
    @Test
    void uneProductionSansPreuveNeDefaitPasLeTransfert() {
        Skill skill = skill("EO3-C8");
        LearningPlanObservation muette = observation(skill, LearningPlanSkillStatus.NOT_OBSERVED,
                LearningPlanSourceType.PRODUCTION_EO, ObservationConfidence.LOW, jours(1));
        muette.setObserved(false);
        muette.setEvidence(null);
        List<LearningPlanObservation> historique = historique(
                muette,
                observation(skill, LearningPlanSkillStatus.SOLID,
                        LearningPlanSourceType.PRODUCTION_EE, ObservationConfidence.HIGH, jours(6)));

        assertThat(resolver.actionable(historique)).isEmpty();
    }

    @Test
    void sansAucuneObservationIlNyAAucunePriorite() {
        when(observationManager.findAllByUserWithSkill(userId)).thenReturn(List.of());

        assertThat(resolver.actionable(List.of())).isEmpty();
        assertThat(resolver.currentPrioritySkillId(userId)).isEmpty();
    }

    // ------------------------------------------------------------------------
    // Fixtures
    // ------------------------------------------------------------------------

    /** L'historique tel que le rend la base : de la plus recente a la plus ancienne. */
    private static List<LearningPlanObservation> historique(LearningPlanObservation... items) {
        List<LearningPlanObservation> observations = new ArrayList<>(List.of(items));
        observations.sort(Comparator.comparing(LearningPlanObservation::getObservedAt).reversed());
        return List.copyOf(observations);
    }

    private static List<String> codes(List<LearningPlanObservation> observations) {
        return observations.stream().map(item -> item.getSkill().getCode()).toList();
    }

    private static LearningPlanObservation observation(
            Skill skill, LearningPlanSkillStatus status, LearningPlanSourceType source,
            ObservationConfidence confidence, Instant observedAt) {
        LearningPlanObservation observation = new LearningPlanObservation();
        observation.setId(UUID.randomUUID());
        observation.setSkill(skill);
        observation.setStatus(status);
        observation.setSourceType(source);
        observation.setSourceId(UUID.randomUUID());
        observation.setSubjectId(UUID.randomUUID());
        observation.setObserved(true);
        observation.setEvidence("Passage cité de la production");
        observation.setExplanation("Ce que le correcteur a constaté.");
        observation.setConfidence(confidence);
        observation.setObservedAt(observedAt);
        return observation;
    }

    private Instant jours(int nombre) {
        return maintenant.minus(Duration.ofDays(nombre));
    }

    private static Skill skill(String code) {
        Skill skill = new Skill();
        skill.setId(UUID.randomUUID());
        skill.setCode(code);
        skill.setTitle("Compétence " + code);
        skill.setSection(code.startsWith("EO") ? SkillSection.EO : SkillSection.EE);
        return skill;
    }
}
