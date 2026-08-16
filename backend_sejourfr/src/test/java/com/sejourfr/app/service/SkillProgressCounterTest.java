package com.sejourfr.app.service;

import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.SkillPrompt;
import com.sejourfr.app.entity.UserSkillAttempt;
import com.sejourfr.app.enums.SkillAttemptStatut;
import com.sejourfr.app.enums.SkillCriterionStatus;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.manager.SkillPromptManager;
import com.sejourfr.app.manager.UserSkillAttemptManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyCollection;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * Les DEUX perimetres de compteurs, cote a cote : la competence entiere (la
 * semantique de {@code SkillDto}, que le Plan ne detourne pas) et l'etape du
 * Plan ({@value LearningPlanStep#PROMPTS_PAR_ETAPE} premiers sujets actifs).
 */
class SkillProgressCounterTest {

    private SkillPromptManager promptManager;
    private UserSkillAttemptManager attemptManager;
    private SkillProgressCounter counter;

    private final UUID userId = UUID.randomUUID();
    private final Skill skill = skill();
    private final List<SkillPrompt> prompts = new ArrayList<>();

    @BeforeEach
    void setUp() {
        promptManager = mock(SkillPromptManager.class);
        attemptManager = mock(UserSkillAttemptManager.class);
        counter = new SkillProgressCounter(promptManager, attemptManager, new SkillStatusResolver());
        for (int order = 1; order <= 15; order++) {
            prompts.add(prompt(order));
        }
    }

    /**
     * Le cas central : 15 sujets publies, 5 dans l'etape, 10 dehors. Les
     * compteurs de competence comptent les 15, ceux de l'etape les 5 — les
     * detourner ferait dire « /5 » au Plan et « /15 » a la fiche de competence
     * pour une seule et meme competence.
     */
    @Test
    void lesCompteursDEtapeNeRegardentQueLesCinqPremiersSujets() {
        stub(prompts, Map.of(
                prompts.get(0).getId(), analysed(prompts.get(0), SkillCriterionStatus.VALIDATED),
                prompts.get(1).getId(), recorded(prompts.get(1)),
                // Hors etape : ils comptent pour la competence, jamais pour l'etape.
                prompts.get(9).getId(), analysed(prompts.get(9), SkillCriterionStatus.VALIDATED),
                prompts.get(14).getId(), analysed(prompts.get(14), SkillCriterionStatus.PARTIAL)));

        SkillProgressCounter.SkillProgress progress = progress();

        assertThat(progress.promptCount()).isEqualTo(15);
        assertThat(progress.attemptedCount()).isEqualTo(4);
        assertThat(progress.validatedCount()).isEqualTo(2);
        assertThat(progress.step().promptCount()).isEqualTo(5);
        assertThat(progress.step().attemptedCount()).isEqualTo(2);
        assertThat(progress.step().validatedCount()).isEqualTo(1);
        assertThat(progress.step().completed()).isFalse();
    }

    /**
     * Le <b>perimetre</b> de l'etape est publie, pas seulement compte : c'est ce
     * que les fronts affichent quand on ouvre la competence depuis le Plan. Ils
     * ne rejouent pas « les cinq premiers actifs » de leur cote.
     */
    @Test
    void lePerimetreDeLEtapeEstLesCinqPremiersSujetsDansLOrdre() {
        stub(prompts, Map.of());

        SkillProgressCounter.SkillProgress progress = progress();

        assertThat(progress.step().promptIds()).containsExactly(
                prompts.get(0).getId(), prompts.get(1).getId(), prompts.get(2).getId(),
                prompts.get(3).getId(), prompts.get(4).getId());
        assertThat(progress.step().promptCount()).isEqualTo(5);
    }

    @Test
    void quatreSujetsSurCinqNeTerminentPasLEtape() {
        stub(prompts, latestOn(0, 1, 2, 3));

        assertThat(progress().step().attemptedCount()).isEqualTo(4);
        assertThat(progress().step().completed()).isFalse();
    }

    @Test
    void cinqSujetsTraitesTerminentLEtape() {
        stub(prompts, latestOn(0, 1, 2, 3, 4));

        assertThat(progress().step().completed()).isTrue();
    }

    /** Terminee n'est pas « tout valide » : les deux informations restent distinctes. */
    @Test
    void uneEtapeTermineeAvecDeuxValidesResteTermineeSansEtreToutValidee() {
        Map<UUID, UserSkillAttempt> latest = new LinkedHashMap<>();
        latest.put(prompts.get(0).getId(),
                analysed(prompts.get(0), SkillCriterionStatus.VALIDATED));
        latest.put(prompts.get(1).getId(),
                analysed(prompts.get(1), SkillCriterionStatus.VALIDATED));
        latest.put(prompts.get(2).getId(),
                analysed(prompts.get(2), SkillCriterionStatus.NOT_VALIDATED));
        latest.put(prompts.get(3).getId(), recorded(prompts.get(3)));
        latest.put(prompts.get(4).getId(), recorded(prompts.get(4)));
        stub(prompts, latest);

        SkillProgressCounter.SkillProgress progress = progress();

        assertThat(progress.step().promptCount()).isEqualTo(5);
        assertThat(progress.step().attemptedCount()).isEqualTo(5);
        assertThat(progress.step().validatedCount()).isEqualTo(2);
        assertThat(progress.step().completed()).isTrue();
    }

    /**
     * Une competence qui publie moins de cinq sujets a une etape plus courte :
     * le perimetre vaut ce qui existe, aucun denominateur n'est invente.
     */
    @Test
    void uneCompetenceDeMoinsDeCinqSujetsALeDenominateurDeCeQuiExiste() {
        List<SkillPrompt> troisSujets = prompts.subList(0, 3);
        stub(troisSujets, latestOn(0, 1, 2));

        SkillProgressCounter.SkillProgress progress = progress();

        assertThat(progress.promptCount()).isEqualTo(3);
        assertThat(progress.step().promptCount()).isEqualTo(3);
        // Aucun identifiant invente pour completer a cinq : le perimetre vaut
        // exactement ce qui est publie.
        assertThat(progress.step().promptIds()).containsExactly(
                troisSujets.get(0).getId(), troisSujets.get(1).getId(),
                troisSujets.get(2).getId());
        assertThat(progress.step().attemptedCount()).isEqualTo(3);
        assertThat(progress.step().completed()).isTrue();
    }

    @Test
    void uneCompetenceSansSujetActifNaAucunCompteurInventeEtNestJamaisTerminee() {
        stub(List.of(), Map.of());

        SkillProgressCounter.SkillProgress progress = progress();

        assertThat(progress.promptCount()).isZero();
        assertThat(progress.step().promptCount()).isZero();
        // Liste VIDE, cas normal : la competence n'a rien a proposer.
        assertThat(progress.step().promptIds()).isEmpty();
        assertThat(progress.step().attemptedCount()).isZero();
        assertThat(progress.step().completed()).isFalse();
    }

    @Test
    void uneCompetenceInconnueRessortAZeroPlutotQueAbsente() {
        UUID inconnue = UUID.randomUUID();
        when(promptManager.findActiveBySkillIds(anyCollection())).thenReturn(Map.of());
        when(attemptManager.findLatestPerPromptBySkillIds(eq(userId), anyCollection()))
                .thenReturn(Map.of());

        assertThat(counter.bySkillIds(userId, List.of(inconnue)))
                .containsEntry(inconnue, SkillProgressCounter.SkillProgress.EMPTY);
    }

    @Test
    void aucuneCompetenceDemandeeNInterrogePasLaBase() {
        assertThat(counter.bySkillIds(userId, List.of())).isEmpty();
        org.mockito.Mockito.verify(promptManager, org.mockito.Mockito.never())
                .findActiveBySkillIds(anyCollection());
    }

    // ------------------------------------------------------------------------
    // Fixtures
    // ------------------------------------------------------------------------

    private SkillProgressCounter.SkillProgress progress() {
        return counter.bySkillIds(userId, List.of(skill.getId())).get(skill.getId());
    }

    private Map<UUID, UserSkillAttempt> latestOn(int... indexes) {
        Map<UUID, UserSkillAttempt> latest = new LinkedHashMap<>();
        for (int index : indexes) {
            latest.put(prompts.get(index).getId(), recorded(prompts.get(index)));
        }
        return latest;
    }

    private void stub(List<SkillPrompt> active, Map<UUID, UserSkillAttempt> latestByPrompt) {
        Map<UUID, List<SkillPrompt>> bySkill = new LinkedHashMap<>();
        bySkill.put(skill.getId(), new ArrayList<>(active));
        when(promptManager.findActiveBySkillIds(anyCollection())).thenReturn(bySkill);
        when(attemptManager.findLatestPerPromptBySkillIds(eq(userId), anyCollection()))
                .thenReturn(new LinkedHashMap<>(latestByPrompt));
    }

    private static Skill skill() {
        Skill skill = new Skill();
        skill.setId(UUID.randomUUID());
        skill.setCode("EE1-C1");
        skill.setTitle("Compétence de test");
        skill.setSection(SkillSection.EE);
        skill.setActive(true);
        return skill;
    }

    private SkillPrompt prompt(int order) {
        SkillPrompt prompt = new SkillPrompt();
        prompt.setId(UUID.randomUUID());
        prompt.setSkill(skill);
        prompt.setSection(SkillSection.EE);
        prompt.setTitle("Sujet " + order);
        prompt.setDisplayOrder((short) order);
        prompt.setActive(true);
        return prompt;
    }

    /** Production rendue sans analyse : « Fait », donc TENTEE mais pas validee. */
    private static UserSkillAttempt recorded(SkillPrompt prompt) {
        UserSkillAttempt attempt = new UserSkillAttempt();
        attempt.setId(UUID.randomUUID());
        attempt.setSkillPrompt(prompt);
        attempt.setStatut(SkillAttemptStatut.RECORDED);
        attempt.setAnalysisRequested(false);
        attempt.setCreatedAt(Instant.now());
        return attempt;
    }

    private static UserSkillAttempt analysed(SkillPrompt prompt, SkillCriterionStatus criterion) {
        UserSkillAttempt attempt = recorded(prompt);
        attempt.setAnalysisRequested(true);
        attempt.setStatut(SkillAttemptStatut.EVALUATED);
        attempt.setCriterionStatus(criterion);
        return attempt;
    }
}
