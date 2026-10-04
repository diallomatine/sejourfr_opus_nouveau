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
     * 🛑 <b>D-71 (2026-10-04, decision du proprietaire) : une etape EE/EO, ce
     * sont 3 sujets.</b> Ce test verrouille le chiffre : le changer est une
     * decision produit, consignee dans {@code docs/decisions/plan-parcours-tcf.md}.
     */
    @Test
    void uneEtapeCeSontTroisSujets() {
        assertThat(LearningPlanStep.PROMPTS_PAR_ETAPE).isEqualTo(3);
    }

    /**
     * Le cas central : 15 sujets publies, 3 dans l'etape, 12 dehors. Les
     * compteurs de competence comptent les 15, ceux de l'etape les 3 — les
     * detourner ferait dire « /3 » au Plan et « /15 » a la fiche de competence
     * pour une seule et meme competence.
     */
    @Test
    void lesCompteursDEtapeNeRegardentQueLesTroisPremiersSujets() {
        stub(prompts, Map.of(
                prompts.get(0).getId(), analysed(prompts.get(0), SkillCriterionStatus.VALIDATED),
                prompts.get(1).getId(), recorded(prompts.get(1)),
                // Hors etape : ils comptent pour la competence, jamais pour l'etape.
                prompts.get(3).getId(), analysed(prompts.get(3), SkillCriterionStatus.VALIDATED),
                prompts.get(14).getId(), analysed(prompts.get(14), SkillCriterionStatus.PARTIAL)));

        SkillProgressCounter.SkillProgress progress = progress();

        assertThat(progress.promptCount()).isEqualTo(15);
        assertThat(progress.attemptedCount()).isEqualTo(4);
        assertThat(progress.validatedCount()).isEqualTo(2);
        assertThat(progress.step().promptCount()).isEqualTo(3);
        assertThat(progress.step().attemptedCount()).isEqualTo(2);
        assertThat(progress.step().validatedCount()).isEqualTo(1);
        assertThat(progress.step().completed()).isFalse();
    }

    /**
     * Le <b>perimetre</b> de l'etape est publie, pas seulement compte : c'est ce
     * que les fronts affichent quand on ouvre la competence depuis le Plan. Ils
     * ne rejouent pas « les premiers actifs » de leur cote.
     */
    @Test
    void lePerimetreDeLEtapeEstLesTroisPremiersSujetsDansLOrdre() {
        stub(prompts, Map.of());

        SkillProgressCounter.SkillProgress progress = progress();

        assertThat(progress.step().promptIds()).containsExactly(
                prompts.get(0).getId(), prompts.get(1).getId(), prompts.get(2).getId());
        assertThat(progress.step().promptCount()).isEqualTo(3);
    }

    @Test
    void deuxSujetsSurTroisNeTerminentPasLEtape() {
        stub(prompts, latestOn(0, 1));

        assertThat(progress().step().attemptedCount()).isEqualTo(2);
        assertThat(progress().step().completed()).isFalse();
    }

    /**
     * Un sujet traite HORS etape (rang 4) ne compte pas : 2 sujets de l'etape
     * + 1 hors etape ne la terminent pas.
     */
    @Test
    void unSujetHorsEtapeNeTerminePasLEtape() {
        stub(prompts, latestOn(0, 1, 3));

        assertThat(progress().step().attemptedCount()).isEqualTo(2);
        assertThat(progress().step().completed()).isFalse();
    }

    @Test
    void troisSujetsTraitesTerminentLEtape() {
        stub(prompts, latestOn(0, 1, 2));

        assertThat(progress().step().completed()).isTrue();
    }

    /**
     * Terminee n'est pas « tout valide » : le critere est <b>traite</b>, les
     * deux informations restent distinctes.
     */
    @Test
    void uneEtapeTermineeAvecUnSeulValideResteTermineeSansEtreToutValidee() {
        Map<UUID, UserSkillAttempt> latest = new LinkedHashMap<>();
        latest.put(prompts.get(0).getId(),
                analysed(prompts.get(0), SkillCriterionStatus.VALIDATED));
        latest.put(prompts.get(1).getId(),
                analysed(prompts.get(1), SkillCriterionStatus.NOT_VALIDATED));
        latest.put(prompts.get(2).getId(), recorded(prompts.get(2)));
        stub(prompts, latest);

        SkillProgressCounter.SkillProgress progress = progress();

        assertThat(progress.step().promptCount()).isEqualTo(3);
        assertThat(progress.step().attemptedCount()).isEqualTo(3);
        assertThat(progress.step().validatedCount()).isEqualTo(1);
        assertThat(progress.step().completed()).isTrue();
    }

    /**
     * Une competence qui publie moins de sujets que la taille d'etape a une
     * etape plus courte : le perimetre vaut ce qui existe, aucun denominateur
     * n'est invente.
     */
    @Test
    void uneCompetenceDeMoinsDeTroisSujetsALeDenominateurDeCeQuiExiste() {
        List<SkillPrompt> deuxSujets = prompts.subList(0, 2);
        stub(deuxSujets, latestOn(0, 1));

        SkillProgressCounter.SkillProgress progress = progress();

        assertThat(progress.promptCount()).isEqualTo(2);
        assertThat(progress.step().promptCount()).isEqualTo(2);
        // Aucun identifiant invente pour completer a trois : le perimetre vaut
        // exactement ce qui est publie.
        assertThat(progress.step().promptIds()).containsExactly(
                deuxSujets.get(0).getId(), deuxSujets.get(1).getId());
        assertThat(progress.step().attemptedCount()).isEqualTo(2);
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
