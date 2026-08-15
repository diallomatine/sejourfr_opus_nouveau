package com.sejourfr.app.service;

import com.sejourfr.app.config.LearningPlanProperties;
import com.sejourfr.app.dto.PlanRecommendedExerciseDto;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.enums.DureeEpreuve;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.PlanExerciseKind;
import com.sejourfr.app.enums.SkillMasteryState;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.manager.AttemptManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

/**
 * Les deux barreaux du haut de l'echelle : quand le Plan cesse de proposer des
 * exercices et propose de se <b>mesurer</b>.
 *
 * <p>Ce qui est verrouille ici n'est pas un nombre mais une regle produit : on
 * n'envoie en examen blanc qu'une epreuve dont les competences travaillees ont
 * <b>transfere</b>, on ne represente pas un jalon qu'on vient de franchir, et un
 * jalon verrouille reste <b>designe</b> — le Plan ne cache jamais ou l'on en est.
 */
class PlanMilestoneSelectorTest {

    private final LearningPlanProperties properties = new LearningPlanProperties();
    private ProductionAccessService productionAccess;
    private AttemptManager attemptManager;
    private PlanMilestoneSelector selector;

    private final UUID userId = UUID.randomUUID();
    private final Instant now = Instant.parse("2026-08-14T10:00:00Z");

    @BeforeEach
    void setUp() {
        productionAccess = mock(ProductionAccessService.class);
        attemptManager = mock(AttemptManager.class);
        selector = new PlanMilestoneSelector(properties, productionAccess, attemptManager);
        when(attemptManager.countProductionExamSessions(eq(userId), any(EpreuveType.class)))
                .thenReturn(0L);
        when(attemptManager.findByUserAndEpreuve(eq(userId), eq(EpreuveType.TCF_COMPLET), anyInt()))
                .thenReturn(List.of());
    }

    // ------------------------------------------------------------------------
    // Rien de merite : rien propose, et rien demande a la base
    // ------------------------------------------------------------------------

    @Test
    @DisplayName("Une epreuve encore fragile ne declenche aucun jalon")
    void uneEpreuveFragileNeDeclencheAucunJalon() {
        Etat etat = etat();
        etat.add("EE1-C1", SkillMasteryState.TO_REINFORCE);
        etat.add("EE1-C2", SkillMasteryState.CONSOLIDATING);

        assertThat(select(etat)).isEmpty();
    }

    @Test
    @DisplayName("Sans jalon atteint, la base n'est pas interrogee du tout")
    void sansJalonAucuneRequete() {
        Etat etat = etat();
        etat.add("EE1-C1", SkillMasteryState.CONSOLIDATING);

        selector.select(userId, etat.latest, etat.mastery, etat.all, now);

        verifyNoInteractions(attemptManager);
        verifyNoInteractions(productionAccess);
    }

    @Test
    @DisplayName("Une seule competence transferee ne suffit pas a mesurer une epreuve")
    void uneSeuleCompetenceTransfereeNeSuffitPas() {
        Etat etat = etat();
        etat.add("EE1-C1", SkillMasteryState.SOLID);

        assertThat(select(etat)).isEmpty();
    }

    @Test
    @DisplayName("Deux competences transferees noyees dans cinq fragiles : pas encore")
    void laMajoriteEstExigee() {
        Etat etat = etat();
        etat.add("EE1-C1", SkillMasteryState.SOLID);
        etat.add("EE1-C2", SkillMasteryState.SOLID);
        etat.add("EE1-C3", SkillMasteryState.PRIORITY);
        etat.add("EE2-C1", SkillMasteryState.PRIORITY);
        etat.add("EE2-C2", SkillMasteryState.TO_REINFORCE);

        assertThat(select(etat)).isEmpty();
    }

    // ------------------------------------------------------------------------
    // Jalon d'epreuve
    // ------------------------------------------------------------------------

    @Test
    @DisplayName("Une epreuve majoritairement transferee ouvre son examen blanc")
    void uneEpreuveTransfereeOuvreSonExamenBlanc() {
        Etat etat = etat();
        etat.add("EE1-C1", SkillMasteryState.SOLID);
        etat.add("EE1-C2", SkillMasteryState.SOLID);
        etat.add("EE2-C1", SkillMasteryState.CONSOLIDATING);

        PlanRecommendedExerciseDto jalon = select(etat).orElseThrow();

        assertThat(jalon.kind()).isEqualTo(PlanExerciseKind.EPREUVE_MOCK_EXAM);
        assertThat(jalon.epreuve()).isEqualTo(EpreuveType.TCF_EE);
        assertThat(jalon.slotNumber()).isEqualTo(1);
        assertThat(jalon.estimatedMinutes()).isEqualTo(30);
        assertThat(jalon.locked()).isFalse();
        // Un jalon ne designe aucun contenu editorial : ni sujet, ni competence.
        assertThat(jalon.skillPromptId()).isNull();
        assertThat(jalon.productionTaskId()).isNull();
        assertThat(jalon.skillId()).isNull();
        assertThat(jalon.title()).isNull();
    }

    @Test
    @DisplayName("Le jalon vise le premier slot que ce candidat n'a pas joue")
    void leJalonViseLeProchainSlot() {
        when(attemptManager.countProductionExamSessions(userId, EpreuveType.TCF_EE)).thenReturn(2L);

        assertThat(select(epreuvePrete(SkillSection.EE)).orElseThrow().slotNumber()).isEqualTo(3);
    }

    @Test
    @DisplayName("Le slot ne depasse jamais la grille, meme apres un parcours complet")
    void leSlotEstPlafonneParLaGrille() {
        when(attemptManager.countProductionExamSessions(userId, EpreuveType.TCF_EE))
                .thenReturn(999L);

        assertThat(select(epreuvePrete(SkillSection.EE)).orElseThrow().slotNumber())
                .isEqualTo(ProductionExamCompositionService.EXAM_SLOTS_PER_EPREUVE);
    }

    @Test
    @DisplayName("Un jalon verrouille reste DESIGNE, avec son cadenas")
    void unJalonVerrouilleResteDesigne() {
        when(productionAccess.isProductionExamLocked(userId)).thenReturn(true);

        PlanRecommendedExerciseDto jalon = select(epreuvePrete(SkillSection.EE)).orElseThrow();

        assertThat(jalon.kind()).isEqualTo(PlanExerciseKind.EPREUVE_MOCK_EXAM);
        assertThat(jalon.locked()).isTrue();
        assertThat(jalon.epreuve()).isEqualTo(EpreuveType.TCF_EE);
    }

    @Test
    @DisplayName("L'oral annonce son temps de parole, pas un chrono d'epreuve")
    void loralASonPropreJalon() {
        PlanRecommendedExerciseDto jalon = select(epreuvePrete(SkillSection.EO)).orElseThrow();

        assertThat(jalon.epreuve()).isEqualTo(EpreuveType.TCF_EO);
        // L'EO n'a AUCUN chrono d'epreuve : le temps se compte par tache. La
        // duree annoncee est donc le temps de parole cumule des 3 taches
        // (3 + 3,5 + 3,5 min), jamais le garde-fou de session.
        assertThat(jalon.estimatedMinutes())
                .isEqualTo(DureeEpreuve.EO_TEMPS_DE_PAROLE_SECONDS / 60)
                .isEqualTo(10);
    }

    @Test
    @DisplayName("Un examen blanc recent de cette epreuve ferme son jalon")
    void unExamenBlancRecentFermeLeJalon() {
        Etat etat = epreuvePrete(SkillSection.EE);
        etat.preuveExamenBlanc(LearningPlanSourceType.MOCK_EXAM_EE, now.minus(Duration.ofDays(3)));

        assertThat(select(etat)).isEmpty();
    }

    @Test
    @DisplayName("Une preuve d'examen blanc perimee rouvre le jalon")
    void unePreuvePerimeeRouvreLeJalon() {
        Etat etat = epreuvePrete(SkillSection.EE);
        etat.preuveExamenBlanc(LearningPlanSourceType.MOCK_EXAM_EE, now.minus(Duration.ofDays(200)));

        assertThat(select(etat)).isPresent();
    }

    @Test
    @DisplayName("A egalite, l'ecrit passe devant l'oral")
    void aEgaliteLecritPasseDevant() {
        Etat etat = etat();
        etat.add("EE1-C1", SkillMasteryState.SOLID);
        etat.add("EE1-C2", SkillMasteryState.SOLID);
        etat.add("EO1-C1", SkillMasteryState.SOLID);
        etat.add("EO1-C2", SkillMasteryState.SOLID);

        assertThat(select(etat).orElseThrow().epreuve()).isEqualTo(EpreuveType.TCF_EE);
    }

    // ------------------------------------------------------------------------
    // Jalon final : l'examen blanc complet
    // ------------------------------------------------------------------------

    @Test
    @DisplayName("Les deux epreuves mesurees separement ouvrent l'examen complet")
    void lesDeuxEpreuvesMesureesOuvrentLexamenComplet() {
        Etat etat = deuxEpreuvesPretesEtMesurees();

        PlanRecommendedExerciseDto jalon = select(etat).orElseThrow();

        assertThat(jalon.kind()).isEqualTo(PlanExerciseKind.FULL_TCF_MOCK_EXAM);
        assertThat(jalon.epreuve()).isEqualTo(EpreuveType.TCF_COMPLET);
        assertThat(jalon.slotNumber()).isEqualTo(1);
        // Somme des 4 epreuves (20 + 35 + 30 + 10), plus l'ancienne enveloppe
        // globale de 90 min : elle a ete supprimee, et la CE vaut 35 min
        // partout.
        assertThat(jalon.estimatedMinutes()).isEqualTo(95);
    }

    @Test
    @DisplayName("Une seule epreuve mesuree renvoie au jalon de l'autre, pas au complet")
    void uneSeuleEpreuveMesureeNouvrePasLeComplet() {
        Etat etat = deuxEpreuvesPretesEtMesurees();
        etat.all.removeIf(item -> item.getSourceType() == LearningPlanSourceType.MOCK_EXAM_EO);

        PlanRecommendedExerciseDto jalon = select(etat).orElseThrow();

        assertThat(jalon.kind()).isEqualTo(PlanExerciseKind.EPREUVE_MOCK_EXAM);
        assertThat(jalon.epreuve()).isEqualTo(EpreuveType.TCF_EO);
    }

    @Test
    @DisplayName("Un examen complet recent ferme le jalon final : c'est une etape, pas une boucle")
    void unExamenCompletRecentFermeLeJalonFinal() {
        when(attemptManager.findByUserAndEpreuve(eq(userId), eq(EpreuveType.TCF_COMPLET), anyInt()))
                .thenReturn(List.of(examenComplet(now.minus(Duration.ofDays(5)))));

        assertThat(select(deuxEpreuvesPretesEtMesurees())).isEmpty();
    }

    @Test
    @DisplayName("Le jalon final vise le prochain slot et reporte le verrou des productions")
    void leJalonFinalViseLeProchainSlotEtReporteLeVerrou() {
        when(attemptManager.findByUserAndEpreuve(eq(userId), eq(EpreuveType.TCF_COMPLET), anyInt()))
                .thenReturn(List.of(examenComplet(now.minus(Duration.ofDays(200)))));
        when(productionAccess.isFullExamProductionLocked(userId)).thenReturn(true);

        PlanRecommendedExerciseDto jalon = select(deuxEpreuvesPretesEtMesurees()).orElseThrow();

        assertThat(jalon.kind()).isEqualTo(PlanExerciseKind.FULL_TCF_MOCK_EXAM);
        assertThat(jalon.slotNumber()).isEqualTo(2);
        assertThat(jalon.locked()).isTrue();
    }

    // ------------------------------------------------------------------------
    // Fabriques
    // ------------------------------------------------------------------------

    private Optional<PlanRecommendedExerciseDto> select(Etat etat) {
        return selector.select(userId, etat.latest, etat.mastery, etat.all, now);
    }

    private Etat epreuvePrete(SkillSection section) {
        String prefixe = section == SkillSection.EO ? "EO1-C" : "EE1-C";
        Etat etat = etat();
        etat.add(prefixe + "1", SkillMasteryState.SOLID);
        etat.add(prefixe + "2", SkillMasteryState.SOLID);
        return etat;
    }

    private Etat deuxEpreuvesPretesEtMesurees() {
        Etat etat = etat();
        etat.add("EE1-C1", SkillMasteryState.SOLID);
        etat.add("EE1-C2", SkillMasteryState.SOLID);
        etat.add("EO1-C1", SkillMasteryState.SOLID);
        etat.add("EO1-C2", SkillMasteryState.SOLID);
        etat.preuveExamenBlanc(LearningPlanSourceType.MOCK_EXAM_EE, now.minus(Duration.ofDays(4)));
        etat.preuveExamenBlanc(LearningPlanSourceType.MOCK_EXAM_EO, now.minus(Duration.ofDays(2)));
        return etat;
    }

    private static Attempt examenComplet(Instant startedAt) {
        Attempt attempt = new Attempt();
        attempt.setId(UUID.randomUUID());
        attempt.setEpreuve(EpreuveType.TCF_COMPLET);
        attempt.setStartedAt(startedAt);
        return attempt;
    }

    private Etat etat() {
        return new Etat();
    }

    /** L'historique et les etats de maitrise tels que le Plan les a deja charges. */
    private final class Etat {
        private final List<LearningPlanObservation> latest = new ArrayList<>();
        private final List<LearningPlanObservation> all = new ArrayList<>();
        private final Map<UUID, SkillMasteryEngine.SkillMastery> mastery = new HashMap<>();

        private void add(String code, SkillMasteryState state) {
            Skill skill = new Skill();
            skill.setId(UUID.randomUUID());
            skill.setCode(code);
            skill.setTitle("Compétence " + code);
            skill.setSection(code.startsWith("EO") ? SkillSection.EO : SkillSection.EE);

            LearningPlanObservation observation = new LearningPlanObservation();
            observation.setSkill(skill);
            observation.setObserved(true);
            observation.setStatus(state == SkillMasteryState.SOLID
                    ? LearningPlanSkillStatus.SOLID : LearningPlanSkillStatus.TO_REINFORCE);
            observation.setSourceType(skill.getSection() == SkillSection.EO
                    ? LearningPlanSourceType.PRODUCTION_EO : LearningPlanSourceType.PRODUCTION_EE);
            observation.setConfidence(ObservationConfidence.HIGH);
            observation.setObservedAt(now.minus(Duration.ofDays(2)));
            latest.add(observation);
            all.add(observation);
            mastery.put(skill.getId(), new SkillMasteryEngine.SkillMastery(
                    state, 1.0, 3, 2, 1, 2, false, false, observation.getObservedAt()));
        }

        /** Une production d'examen blanc deja observee sur cette epreuve. */
        private void preuveExamenBlanc(LearningPlanSourceType source, Instant quand) {
            LearningPlanObservation observation = new LearningPlanObservation();
            observation.setSkill(latest.getFirst().getSkill());
            observation.setObserved(true);
            observation.setStatus(LearningPlanSkillStatus.SOLID);
            observation.setSourceType(source);
            observation.setConfidence(ObservationConfidence.HIGH);
            observation.setObservedAt(quand);
            all.add(observation);
        }
    }
}
