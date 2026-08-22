package com.sejourfr.app.service;

import com.sejourfr.app.config.LearningPlanProperties;
import com.sejourfr.app.dto.PlanRecentChangesDto;
import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.PlanRecentChangesWindow;
import com.sejourfr.app.enums.SkillMasteryState;
import com.sejourfr.app.enums.SkillSection;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.Duration;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.within;

/**
 * « Ce qui a change » : de vraies transitions du moteur, ou rien.
 *
 * <p>Le moteur de maitrise tourne <b>pour de vrai</b> ici — c'est tout l'objet
 * du bloc : si on le doublait, on testerait notre propre idee du changement au
 * lieu de celle qui fait foi partout ailleurs.
 */
class PlanRecentChangesResolverTest {

    private final LearningPlanProperties properties = new LearningPlanProperties();
    private final SkillMasteryEngine engine = new SkillMasteryEngine(properties);
    private final SkillMasteryResolver masteryResolver =
            new SkillMasteryResolver(null, engine, properties);
    private final PlanRecentChangesResolver resolver = new PlanRecentChangesResolver(engine);

    private final Instant now = Instant.now();

    /**
     * Le cas le plus important : un candidat qui n'a rien fait depuis un mois ne
     * lit aucun bloc. Pas de bandeau, pas d'encouragement, rien.
     */
    @Test
    @DisplayName("Rien n'a bouge : aucun bloc, jamais un message fabrique")
    void sansRienDeNeufLeBlocEstAbsent() {
        Skill skill = skill("EE1-C1", SkillSection.EE);
        List<LearningPlanObservation> historique = List.of(
                observation(skill, LearningPlanSkillStatus.TO_REINFORCE,
                        LearningPlanSourceType.PRODUCTION_EE, jours(60)));

        assertThat(resolve(historique, null)).isEqualTo(Optional.empty());
    }

    /**
     * Le cas du brief §82 : « A renforcer &rarr; Solide ». La transition est
     * <b>mesuree</b> — le meme moteur, joue au debut de la fenetre puis
     * maintenant.
     */
    @Test
    @DisplayName("Une vraie transition de maitrise est rendue, avec son sens")
    void uneTransitionReelleEstRendue() {
        Skill skill = skill("EE1-C1", SkillSection.EE);
        List<LearningPlanObservation> historique = new ArrayList<>(List.of(
                // Avant la fenetre : une fragilite, donc rien de solide.
                observation(skill, LearningPlanSkillStatus.PRIORITY,
                        LearningPlanSourceType.DIAGNOSTIC_EE, jours(20)),
                // Dans la fenetre : deux reussites en situation, sur deux sujets.
                observation(skill, LearningPlanSkillStatus.SOLID,
                        LearningPlanSourceType.PRODUCTION_EE, jours(4)),
                observation(skill, LearningPlanSkillStatus.SOLID,
                        LearningPlanSourceType.MOCK_EXAM_EE, jours(1))));

        PlanRecentChangesDto changes = resolve(historique, null).orElseThrow();

        assertThat(changes.window()).isEqualTo(PlanRecentChangesWindow.CETTE_SEMAINE);
        assertThat(changes.transitions()).singleElement().satisfies(transition -> {
            assertThat(transition.skillCode()).isEqualTo("EE1-C1");
            assertThat(transition.before()).isEqualTo(SkillMasteryState.PRIORITY);
            assertThat(transition.after()).isEqualTo(SkillMasteryState.SOLID);
            assertThat(transition.progress()).isTrue();
        });
        assertThat(changes.newPriority()).isNull();
    }

    /**
     * Decouvrir son niveau n'est pas un changement : sans cette regle, le bloc
     * serait plein de bruit le jour meme du diagnostic.
     */
    @Test
    @DisplayName("Une premiere mesure n'est pas une transition")
    void unePremiereObservationNeCompteJamaisCommeUnChangement() {
        Skill skill = skill("EO1-C1", SkillSection.EO);
        List<LearningPlanObservation> historique = List.of(
                observation(skill, LearningPlanSkillStatus.PRIORITY,
                        LearningPlanSourceType.DIAGNOSTIC_EO, jours(2)));

        assertThat(resolve(historique, null)).isEqualTo(Optional.empty());
    }

    /**
     * 🛑 Le temps seul ne fabrique pas d'evenement. Une competence sans
     * observation nouvelle n'est meme pas examinee : annoncer « Solide &rarr; En
     * consolidation » a quelqu'un qui n'a rien fait serait une punition inventee.
     */
    @Test
    @DisplayName("Une competence sans observation dans la fenetre n'est pas examinee")
    void leTempsQuiPasseNeProduitAucuneTransition() {
        Skill ancienne = skill("EE2-C1", SkillSection.EE);
        Skill recente = skill("EE3-C1", SkillSection.EE);
        List<LearningPlanObservation> historique = new ArrayList<>(List.of(
                observation(ancienne, LearningPlanSkillStatus.PRIORITY,
                        LearningPlanSourceType.DIAGNOSTIC_EE, jours(40)),
                observation(ancienne, LearningPlanSkillStatus.SOLID,
                        LearningPlanSourceType.PRODUCTION_EE, jours(35)),
                observation(ancienne, LearningPlanSkillStatus.SOLID,
                        LearningPlanSourceType.MOCK_EXAM_EE, jours(34)),
                // Celle-ci, elle, a bouge dans la fenetre.
                observation(recente, LearningPlanSkillStatus.PRIORITY,
                        LearningPlanSourceType.DIAGNOSTIC_EE, jours(20)),
                observation(recente, LearningPlanSkillStatus.SOLID,
                        LearningPlanSourceType.PRODUCTION_EE, jours(3)),
                observation(recente, LearningPlanSkillStatus.SOLID,
                        LearningPlanSourceType.MOCK_EXAM_EE, jours(2))));

        PlanRecentChangesDto changes = resolve(historique, null).orElseThrow();

        assertThat(changes.transitions()).extracting("skillCode")
                .containsExactly("EE3-C1");
    }

    /**
     * La fenetre s'elargit tant qu'il n'y a rien a raconter — mais elle ne
     * s'invente jamais de contenu : au-dela du mois, le bloc disparait.
     */
    @Test
    @DisplayName("La fenetre s'elargit quand la semaine est vide, jamais au-dela du mois")
    void laFenetreSelargitJusquAuMoisPuisSarrete() {
        Skill skill = skill("EE1-C1", SkillSection.EE);
        List<LearningPlanObservation> historique = new ArrayList<>(List.of(
                observation(skill, LearningPlanSkillStatus.PRIORITY,
                        LearningPlanSourceType.DIAGNOSTIC_EE, jours(40)),
                observation(skill, LearningPlanSkillStatus.SOLID,
                        LearningPlanSourceType.PRODUCTION_EE, jours(20)),
                observation(skill, LearningPlanSkillStatus.SOLID,
                        LearningPlanSourceType.MOCK_EXAM_EE, jours(19))));

        PlanRecentChangesDto changes = resolve(historique, null).orElseThrow();

        assertThat(changes.window()).isEqualTo(PlanRecentChangesWindow.CE_MOIS);
        assertThat(changes.since())
                .isCloseTo(now.minus(Duration.ofDays(30)), within(5, ChronoUnit.SECONDS));
        assertThat(changes.transitions()).hasSize(1);
    }

    /**
     * La priorite n&deg;1 n'est annoncee que si elle vient d'etre designee : la
     * republier chaque semaine ferait passer pour une nouveaute une etape que le
     * candidat a deja sous les yeux.
     */
    @Test
    @DisplayName("La nouvelle priorite n'est servie que si elle est nee dans la fenetre")
    void lanouvellePrioriteEstBorneeParLaFenetre() {
        Skill skill = skill("EO2-C3", SkillSection.EO);
        LearningPlanObservation recente = observation(skill,
                LearningPlanSkillStatus.TO_REINFORCE,
                LearningPlanSourceType.PRODUCTION_EO, jours(2));
        LearningPlanObservation ancienne = observation(skill,
                LearningPlanSkillStatus.TO_REINFORCE,
                LearningPlanSourceType.PRODUCTION_EO, jours(90));

        PlanRecentChangesDto changes =
                resolve(List.of(recente), recente).orElseThrow();
        assertThat(changes.window()).isEqualTo(PlanRecentChangesWindow.CETTE_SEMAINE);
        assertThat(changes.transitions()).isEmpty();
        assertThat(changes.newPriority().skillCode()).isEqualTo("EO2-C3");

        assertThat(resolve(List.of(ancienne), ancienne)).isEqualTo(Optional.empty());
    }

    // ------------------------------------------------------------------------
    // Fabriques
    // ------------------------------------------------------------------------

    /**
     * Le bloc, calcule comme le fait le Plan : le moteur d'abord sur
     * l'historique entier, le resolveur ensuite sur ces memes etats.
     */
    private Optional<PlanRecentChangesDto> resolve(
            List<LearningPlanObservation> historique, LearningPlanObservation prioriteUn) {
        List<LearningPlanObservation> triees = new ArrayList<>(historique);
        triees.sort(Comparator.comparing(
                LearningPlanObservation::getObservedAt, Comparator.reverseOrder()));
        List<UUID> skillIds = triees.stream()
                .map(item -> item.getSkill().getId())
                .distinct()
                .toList();
        Map<UUID, SkillMasteryEngine.SkillMastery> mastery =
                masteryResolver.fromObservations(triees, skillIds);
        return resolver.resolve(triees, mastery, prioriteUn, now);
    }

    private LearningPlanObservation observation(
            Skill skill, LearningPlanSkillStatus status,
            LearningPlanSourceType source, Instant quand) {
        LearningPlanObservation observation = new LearningPlanObservation();
        observation.setId(UUID.randomUUID());
        observation.setSkill(skill);
        observation.setObserved(true);
        observation.setStatus(status);
        observation.setSourceType(source);
        observation.setSubjectId(UUID.randomUUID());
        observation.setConfidence(ObservationConfidence.HIGH);
        observation.setObservedAt(quand);
        return observation;
    }

    private static Skill skill(String code, SkillSection section) {
        Skill skill = new Skill();
        skill.setId(UUID.randomUUID());
        skill.setCode(code);
        skill.setTitle("Compétence " + code);
        skill.setSection(section);
        skill.setTargetLevel("B1");
        return skill;
    }

    private Instant jours(int nombre) {
        return now.minus(Duration.ofDays(nombre));
    }
}
