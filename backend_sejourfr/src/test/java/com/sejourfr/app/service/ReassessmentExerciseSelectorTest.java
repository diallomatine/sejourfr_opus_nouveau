package com.sejourfr.app.service;

import com.sejourfr.app.dto.PlanRecommendedExerciseDto;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.PlanExerciseKind;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.manager.ProductionTaskManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * La verification en situation : quel <b>vrai sujet TCF</b> le Plan propose quand
 * une competence a assez ete travaillee en cible.
 *
 * <p>Ce qui est verrouille ici : du contenu <b>neuf</b> d'abord, un sujet
 * <b>stable</b> d'une lecture a l'autre (un sujet qui change a chaque
 * rafraichissement est illisible et impossible a supporter), et l'absence
 * silencieuse quand la tache n'a rien de publie.
 */
class ReassessmentExerciseSelectorTest {

    private ProductionTaskManager taskManager;
    private ProductionSubmissionManager submissionManager;
    private ProductionAccessService accessService;
    private ReassessmentExerciseSelector selector;

    private final UUID userId = UUID.randomUUID();
    private final Instant now = Instant.parse("2026-08-12T10:00:00Z");

    @BeforeEach
    void setUp() {
        taskManager = mock(ProductionTaskManager.class);
        submissionManager = mock(ProductionSubmissionManager.class);
        accessService = mock(ProductionAccessService.class);
        when(submissionManager.findLastSubmittedAtByTask(userId)).thenReturn(Map.of());
        when(accessService.isTrainingLocked(eq(userId), any())).thenReturn(false);
        selector = new ReassessmentExerciseSelector(
                taskManager, submissionManager, accessService);
    }

    // ------------------------------------------------------------------------
    // Du contenu neuf d'abord
    // ------------------------------------------------------------------------

    @Test
    @DisplayName("Un sujet jamais rendu passe avant tous ceux qui l'ont ete")
    void unSujetJamaisRenduPasseDabord() {
        Skill skill = skill(SkillTaskCode.EE3);
        List<ProductionTask> pool = pool(EpreuveType.TCF_EE, (short) 3, 6);
        stub(SkillTaskCode.EE3, pool);
        // Tous rendus SAUF un seul : c'est forcement lui.
        ProductionTask neuf = pool.get(4);
        Map<UUID, Instant> played = new HashMap<>();
        pool.stream().filter(task -> !task.equals(neuf))
                .forEach(task -> played.put(task.getId(), now.minusSeconds(3600)));
        when(submissionManager.findLastSubmittedAtByTask(userId)).thenReturn(played);

        assertThat(selector.select(userId, skill))
                .get().extracting(PlanRecommendedExerciseDto::productionTaskId)
                .isEqualTo(neuf.getId());
    }

    @Test
    @DisplayName("Le sujet propose ne bouge pas d'une lecture a l'autre")
    void leSujetProposeEstStableDuneLectureALautre() {
        Skill skill = skill(SkillTaskCode.EO2);
        stub(SkillTaskCode.EO2, pool(EpreuveType.TCF_EO, (short) 2, 8));

        UUID premiere = selector.select(userId, skill).orElseThrow().productionTaskId();
        UUID seconde = selector.select(userId, skill).orElseThrow().productionTaskId();

        assertThat(seconde).isEqualTo(premiere);
    }

    @Test
    @DisplayName("Rendre un AUTRE sujet de la tache ne change pas celui qui est propose")
    void jouerUnAutreSujetNeRedistribuePasLesCartes() {
        Skill skill = skill(SkillTaskCode.EE2);
        List<ProductionTask> pool = pool(EpreuveType.TCF_EE, (short) 2, 6);
        stub(SkillTaskCode.EE2, pool);
        UUID avant = selector.select(userId, skill).orElseThrow().productionTaskId();

        ProductionTask autre = pool.stream()
                .filter(task -> !task.getId().equals(avant)).findFirst().orElseThrow();
        when(submissionManager.findLastSubmittedAtByTask(userId))
                .thenReturn(Map.of(autre.getId(), now));

        assertThat(selector.select(userId, skill).orElseThrow().productionTaskId())
                .isEqualTo(avant);
    }

    @Test
    @DisplayName("Deux candidats ne tombent pas mecaniquement sur le meme sujet")
    void deuxCandidatsNontPasLeMemeSujet() {
        Skill skill = skill(SkillTaskCode.EE3);
        stub(SkillTaskCode.EE3, pool(EpreuveType.TCF_EE, (short) 3, 12));

        UUID autreUser = UUID.randomUUID();
        when(submissionManager.findLastSubmittedAtByTask(autreUser)).thenReturn(Map.of());
        when(accessService.isTrainingLocked(eq(autreUser), any())).thenReturn(false);

        // Sur 12 sujets, deux graines differentes doivent pouvoir diverger : on
        // verifie qu'au moins un candidat sur cinq recoit autre chose.
        UUID reference = selector.select(userId, skill).orElseThrow().productionTaskId();
        boolean auMoinsUneDivergence = false;
        for (int i = 0; i < 5; i++) {
            UUID other = UUID.randomUUID();
            when(submissionManager.findLastSubmittedAtByTask(other)).thenReturn(Map.of());
            when(accessService.isTrainingLocked(eq(other), any())).thenReturn(false);
            if (!reference.equals(selector.select(other, skill).orElseThrow().productionTaskId())) {
                auMoinsUneDivergence = true;
            }
        }
        assertThat(auMoinsUneDivergence).isTrue();
    }

    // ------------------------------------------------------------------------
    // Tous rendus : un tirage stable, jamais la copie qu'on vient de rendre
    // ------------------------------------------------------------------------

    @Test
    @DisplayName("Tous les sujets rendus : le tirage reste stable et reproductible")
    void tousRendusLeTirageResteStable() {
        Skill skill = skill(SkillTaskCode.EE1);
        List<ProductionTask> pool = pool(EpreuveType.TCF_EE, (short) 1, 5);
        stub(SkillTaskCode.EE1, pool);
        Map<UUID, Instant> played = new HashMap<>();
        for (int i = 0; i < pool.size(); i++) {
            played.put(pool.get(i).getId(), now.minusSeconds(3600L * (i + 1)));
        }
        when(submissionManager.findLastSubmittedAtByTask(userId)).thenReturn(played);

        PlanRecommendedExerciseDto first = selector.select(userId, skill).orElseThrow();
        PlanRecommendedExerciseDto second = selector.select(userId, skill).orElseThrow();

        assertThat(first.productionTaskId()).isEqualTo(second.productionTaskId());
        assertThat(pool).extracting(ProductionTask::getId).contains(first.productionTaskId());
    }

    @Test
    @DisplayName("Tous les sujets rendus : on ne resert pas celui qui vient de l'etre")
    void tousRendusOnNeResertPasLeDernier() {
        Skill skill = skill(SkillTaskCode.EO3);
        List<ProductionTask> pool = pool(EpreuveType.TCF_EO, (short) 3, 4);
        stub(SkillTaskCode.EO3, pool);

        for (ProductionTask dernier : pool) {
            Map<UUID, Instant> played = new HashMap<>();
            pool.forEach(task -> played.put(task.getId(), now.minusSeconds(7200)));
            played.put(dernier.getId(), now);
            when(submissionManager.findLastSubmittedAtByTask(userId)).thenReturn(played);

            assertThat(selector.select(userId, skill).orElseThrow().productionTaskId())
                    .isNotEqualTo(dernier.getId());
        }
    }

    @Test
    @DisplayName("Un seul sujet publie, deja rendu : il est propose quand meme")
    void unSeulSujetDejaRenduResteProposable() {
        Skill skill = skill(SkillTaskCode.EE1);
        List<ProductionTask> pool = pool(EpreuveType.TCF_EE, (short) 1, 1);
        stub(SkillTaskCode.EE1, pool);
        when(submissionManager.findLastSubmittedAtByTask(userId))
                .thenReturn(Map.of(pool.getFirst().getId(), now));

        assertThat(selector.select(userId, skill))
                .get().extracting(PlanRecommendedExerciseDto::productionTaskId)
                .isEqualTo(pool.getFirst().getId());
    }

    // ------------------------------------------------------------------------
    // Rien a proposer : c'est un cas normal
    // ------------------------------------------------------------------------

    @Test
    @DisplayName("Aucun sujet publie sur la tache : rien n'est propose, rien ne casse")
    void aucunSujetPublieRienNestPropose() {
        Skill skill = skill(SkillTaskCode.EE3);
        stub(SkillTaskCode.EE3, List.of());

        assertThat(selector.select(userId, skill)).isEmpty();
        assertThat(selector.selectAll(userId, List.of(skill))).isEmpty();
    }

    @Test
    @DisplayName("Competence sans tache connue : absente, sans requete de catalogue")
    void competenceSansTacheEstIgnoree() {
        Skill orpheline = new Skill();
        orpheline.setId(UUID.randomUUID());
        orpheline.setCode("EE3-C9");
        orpheline.setSection(SkillSection.EE);

        assertThat(selector.select(userId, orpheline)).isEmpty();
        assertThat(selector.select(userId, null)).isEmpty();
    }

    // ------------------------------------------------------------------------
    // Verrou et duree
    // ------------------------------------------------------------------------

    @Test
    @DisplayName("Un sujet verrouille est designe QUAND MEME, avec son cadenas")
    void unSujetVerrouilleResteDesigne() {
        Skill skill = skill(SkillTaskCode.EE3);
        stub(SkillTaskCode.EE3, pool(EpreuveType.TCF_EE, (short) 3, 4));
        when(accessService.isTrainingLocked(userId, EpreuveType.TCF_EE)).thenReturn(true);

        PlanRecommendedExerciseDto exercise = selector.select(userId, skill).orElseThrow();

        assertThat(exercise.locked()).isTrue();
        assertThat(exercise.productionTaskId()).isNotNull();
        assertThat(exercise.kind()).isEqualTo(PlanExerciseKind.REASSESSMENT);
    }

    @Test
    @DisplayName("Le DTO dit ou aller : nature, sujet de production, epreuve et numero de tache")
    void leDtoDitOuAller() {
        Skill skill = skill(SkillTaskCode.EO2);
        List<ProductionTask> pool = pool(EpreuveType.TCF_EO, (short) 2, 3);
        stub(SkillTaskCode.EO2, pool);

        PlanRecommendedExerciseDto exercise = selector.select(userId, skill).orElseThrow();

        assertThat(exercise.kind()).isEqualTo(PlanExerciseKind.REASSESSMENT);
        assertThat(exercise.skillPromptId()).isNull();
        assertThat(exercise.productionTaskId()).isNotNull();
        assertThat(exercise.tacheNumero()).isEqualTo((short) 2);
        assertThat(exercise.section()).isEqualTo(SkillSection.EO);
        assertThat(exercise.skillId()).isEqualTo(skill.getId());
    }

    @Test
    @DisplayName("La duree annoncee vient du sujet, pas d'une constante d'epreuve")
    void laDureeVientDuSujet() {
        ProductionTask oral = task(EpreuveType.TCF_EO, (short) 3, "Sujet oral");
        oral.setDureeMaxSec(120);
        ProductionTask ecrit = task(EpreuveType.TCF_EE, (short) 3, "Sujet ecrit");
        ecrit.setMotsMin(40);
        ecrit.setMotsMax(90);
        ProductionTask sansDonnee = task(EpreuveType.TCF_EE, (short) 3, "Sans conseil");

        // 120 s de parole x 3 = 360 s => 6 min ; (40+90)/2 = 65 mots / 12 => 6 min.
        assertThat(ReassessmentExerciseSelector.estimatedMinutes(oral)).isEqualTo(6);
        assertThat(ReassessmentExerciseSelector.estimatedMinutes(ecrit)).isEqualTo(6);
        assertThat(ReassessmentExerciseSelector.estimatedMinutes(sansDonnee)).isEqualTo(4);
    }

    @Test
    @DisplayName("Sans titre editorial, le repli reste « Sujet N »")
    void sansTitreLeRepliEstSujetN() {
        Skill skill = skill(SkillTaskCode.EE1);
        List<ProductionTask> pool = pool(EpreuveType.TCF_EE, (short) 1, 3);
        pool.forEach(task -> task.setTitre(null));
        stub(SkillTaskCode.EE1, pool);

        assertThat(selector.select(userId, skill).orElseThrow().title())
                .matches("Sujet [123]");
    }

    // ------------------------------------------------------------------------
    // Fabriques
    // ------------------------------------------------------------------------

    private void stub(SkillTaskCode taskCode, List<ProductionTask> pool) {
        EpreuveType epreuve = taskCode.getSection() == SkillSection.EO
                ? EpreuveType.TCF_EO : EpreuveType.TCF_EE;
        when(taskManager.findActive(epreuve, null, (short) taskCode.getTacheNumero()))
                .thenReturn(pool);
    }

    private Skill skill(SkillTaskCode taskCode) {
        Skill skill = new Skill();
        skill.setId(UUID.randomUUID());
        skill.setCode(taskCode.name() + "-C1");
        skill.setTitle("Competence " + taskCode.name());
        skill.setTaskCode(taskCode);
        skill.setSection(taskCode.getSection());
        return skill;
    }

    private List<ProductionTask> pool(EpreuveType epreuve, short tache, int count) {
        List<ProductionTask> pool = new java.util.ArrayList<>();
        for (int i = 1; i <= count; i++) {
            ProductionTask task = task(epreuve, tache, "Sujet editorial " + i);
            task.setCreatedAt(now.minusSeconds(86400L * (count - i)));
            pool.add(task);
        }
        return pool;
    }

    private ProductionTask task(EpreuveType epreuve, short tache, String titre) {
        ProductionTask task = new ProductionTask();
        task.setId(UUID.randomUUID());
        task.setEpreuve(epreuve);
        task.setTacheNumero(tache);
        task.setNiveauCible("B1");
        task.setTitre(titre);
        task.setConsigne("Consigne du sujet.");
        task.setActive(true);
        task.setCreatedAt(now);
        return task;
    }

    /** Le selecteur ne doit jamais rendre {@code null} la ou il promet un Optional. */
    @Test
    @DisplayName("selectAll ignore les competences nulles sans lever")
    void selectAllIgnoreLesNulls() {
        Optional<PlanRecommendedExerciseDto> vide = selector.select(userId, null);
        assertThat(vide).isEmpty();
        assertThat(selector.selectAll(userId, java.util.Arrays.asList((Skill) null))).isEmpty();
    }
}
