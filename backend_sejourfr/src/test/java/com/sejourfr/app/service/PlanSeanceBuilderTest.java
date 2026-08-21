package com.sejourfr.app.service;

import com.sejourfr.app.dto.LearningPlanPriorityDto;
import com.sejourfr.app.dto.PlanRecommendedExerciseDto;
import com.sejourfr.app.dto.PlanSeanceDto;
import com.sejourfr.app.dto.PlanSeanceItemDto;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.PlanExerciseKind;
import com.sejourfr.app.enums.SkillMasteryState;
import com.sejourfr.app.enums.SkillSection;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * La seance du jour : ce qu'elle contient, dans quel ordre, pour combien de
 * temps — et surtout, ce dont elle ne depend <b>pas</b>.
 */
class PlanSeanceBuilderTest {

    private final PlanSeanceBuilder builder = new PlanSeanceBuilder();

    @Test
    @DisplayName("Trois entrainements au maximum, meme avec plus de priorites")
    void laSeanceEstPlafonneeATroisEntrainements() {
        List<LearningPlanPriorityDto> priorites = List.of(
                priorite("EE1-C1", SkillSection.EE, micro(4)),
                priorite("EO1-C2", SkillSection.EO, micro(6)),
                priorite("EE2-C3", SkillSection.EE, micro(5)),
                priorite("EO2-C4", SkillSection.EO, micro(7)));

        PlanSeanceDto seance = builder.build(priorites, skills(priorites), Map.of(), null);

        assertThat(seance.items()).hasSize(PlanSeanceBuilder.MAX_ITEMS);
        assertThat(seance.items()).extracting("skillCode")
                .containsExactly("EE1-C1", "EO1-C2", "EE2-C3");
    }

    /**
     * Une competence qui demande plusieurs etapes n'occupe qu'<b>une</b> ligne :
     * c'est l'action qui change (petit sujet, puis verification en situation),
     * jamais le nombre d'items.
     */
    @Test
    @DisplayName("Une competence = un slot, meme prete a etre verifiee")
    void uneCompetenceNoccupeQuUnSeulSlot() {
        LearningPlanPriorityDto prete = new LearningPlanPriorityDto(
                UUID.randomUUID(), "EE1-C1", "Raconter dans l'ordre", SkillSection.EE,
                LearningPlanSkillStatus.TO_REINFORCE, "Explication", "Preuve",
                ObservationConfidence.HIGH, Instant.now(),
                PlanRecommendedExerciseDto.reassessment(
                        UUID.randomUUID(), UUID.randomUUID(), "EE1-C1", "Tache complete",
                        SkillSection.EE, (short) 1, 12, false),
                15, 5, 5, 5, 5, 5, true, List.of(),
                SkillMasteryState.CONSOLIDATING, true, false);

        PlanSeanceDto seance = builder.build(List.of(prete), skills(List.of(prete)), Map.of(), null);

        assertThat(seance.items()).singleElement().satisfies(item -> {
            assertThat(item.skillCode()).isEqualTo("EE1-C1");
            assertThat(item.exercise().kind()).isEqualTo(PlanExerciseKind.REASSESSMENT);
            assertThat(item.readyForReassessment()).isTrue();
            assertThat(item.stepCompleted()).isTrue();
        });
    }

    /**
     * Une serie ciblee se lance avec la <b>competence</b> et rien d'autre :
     * l'item doit donc la porter, pas un couple (type de question, palier) que
     * le front recomposerait.
     */
    @Test
    @DisplayName("Un item de serie ciblee porte son skillId et son palier")
    void lItemDeSerieCibleePorteSaCompetence() {
        UUID skillId = UUID.randomUUID();
        LearningPlanPriorityDto co = new LearningPlanPriorityDto(
                skillId, "CO-B1", "Comprendre le sens global", SkillSection.CO,
                LearningPlanSkillStatus.TO_REINFORCE, null, null,
                ObservationConfidence.HIGH, Instant.now(),
                PlanRecommendedExerciseDto.targetedQcmSeries(
                        skillId, "CO-B1", "Comprendre le sens global", SkillSection.CO,
                        20, 16, false),
                0, 0, 0, 0, 0, 0, false, List.of(),
                SkillMasteryState.TO_REINFORCE, false, false);
        Skill skill = skill("CO-B1", SkillSection.CO);
        skill.setId(skillId);
        skill.setTargetLevel("B1");

        PlanSeanceDto seance = builder.build(List.of(co), Map.of(skillId, skill), Map.of(), null);

        assertThat(seance.items()).singleElement().satisfies(item -> {
            assertThat(item.exercise().kind())
                    .isEqualTo(PlanExerciseKind.TARGETED_QCM_SERIES);
            assertThat(item.exercise().skillId()).isEqualTo(skillId);
            assertThat(item.exercise().questionCount()).isEqualTo(20);
            assertThat(item.exercise().skillPromptId()).isNull();
            assertThat(item.exercise().epreuve()).isNull();
            assertThat(item.level()).isEqualTo("B1");
        });
    }

    @Test
    @DisplayName("Le total de minutes est recalcule, jamais annonce")
    void leTotalDeMinutesEstLaSommeDesItems() {
        List<LearningPlanPriorityDto> priorites = List.of(
                priorite("EE1-C1", SkillSection.EE, micro(4)),
                priorite("EO1-C2", SkillSection.EO, micro(9)));

        PlanSeanceDto seance = builder.build(priorites, skills(priorites), Map.of(), null);

        assertThat(seance.estimatedMinutes()).isEqualTo(13);
        assertThat(seance.items()).extracting(item -> item.exercise().estimatedMinutes())
                .containsExactly(4, 9);
    }

    /**
     * 🛑 Le test qui prouve la regle « sticky » : aucune date n'entre dans la
     * construction. Les memes priorites — c'est-a-dire le meme historique, aucune
     * action du candidat — rendent exactement la meme seance, autant de fois
     * qu'on la demande. Un jour qui passe ne peut donc pas faire oublier une
     * competence.
     */
    @Test
    @DisplayName("Sans nouvelle observation, la seance est identique d'un appel a l'autre")
    void laSeanceNeDependDAucuneDate() {
        List<LearningPlanPriorityDto> priorites = List.of(
                priorite("EE1-C1", SkillSection.EE, micro(4)),
                priorite("EO1-C2", SkillSection.EO, micro(6)));
        Map<UUID, Skill> skills = skills(priorites);
        // La derniere activite est fournie : c'est un FAIT d'historique, pas une
        // horloge. La seance le recopie et ne le compare a rien.
        Map<UUID, Instant> activites = Map.of(
                priorites.getFirst().skillId(), Instant.now().minus(40, ChronoUnit.DAYS));

        PlanSeanceDto premiere = builder.build(priorites, skills, activites, null);
        PlanSeanceDto seconde = builder.build(priorites, skills, activites, null);

        assertThat(seconde).isEqualTo(premiere);
        assertThat(seconde.items()).extracting("skillCode")
                .containsExactly("EE1-C1", "EO1-C2");
    }

    /**
     * Une competence dont aucun sujet n'est publie n'a rien a faire dans une
     * seance : un item sans action n'est pas un entrainement.
     */
    @Test
    @DisplayName("Une priorite sans exercice n'entre pas dans la seance")
    void unePrioriteSansExerciceEstEcartee() {
        List<LearningPlanPriorityDto> priorites = List.of(
                priorite("EE1-C1", SkillSection.EE, null),
                priorite("EO1-C2", SkillSection.EO, micro(6)));

        PlanSeanceDto seance = builder.build(priorites, skills(priorites), Map.of(), null);

        assertThat(seance.items()).singleElement()
                .extracting("skillCode").isEqualTo("EO1-C2");
        assertThat(seance.estimatedMinutes()).isEqualTo(6);
    }

    /**
     * Quand le cycle reclame un examen blanc, c'est l'action principale : il
     * passe devant, occupe un slot, et ne porte aucune competence — il ne
     * travaille pas un moyen, il verifie ce qui a ete travaille.
     */
    @Test
    @DisplayName("Le jalon ouvre la seance et occupe un slot")
    void leJalonPasseDevantEtCompteDansLePlafond() {
        List<LearningPlanPriorityDto> priorites = List.of(
                priorite("EE1-C1", SkillSection.EE, micro(4)),
                priorite("EO1-C2", SkillSection.EO, micro(6)),
                priorite("EE2-C3", SkillSection.EE, micro(5)));
        PlanRecommendedExerciseDto jalon =
                PlanRecommendedExerciseDto.epreuveMockExam(EpreuveType.TCF_EE, 1, 30, false);

        PlanSeanceDto seance = builder.build(priorites, skills(priorites), Map.of(), jalon);

        assertThat(seance.items()).hasSize(PlanSeanceBuilder.MAX_ITEMS);
        assertThat(seance.items().getFirst()).satisfies(item -> {
            assertThat(item.exercise().kind()).isEqualTo(PlanExerciseKind.EPREUVE_MOCK_EXAM);
            assertThat(item.skillId()).isNull();
            assertThat(item.skillCode()).isNull();
            assertThat(item.masteryState()).isNull();
        });
        assertThat(seance.items()).extracting("skillCode")
                .containsExactly(null, "EE1-C1", "EO1-C2");
        assertThat(seance.estimatedMinutes()).isEqualTo(40);
    }

    /**
     * La <b>derniere activite</b> est recopiee telle quelle : c'est elle qui
     * permet aux fronts de cocher ce qui a ete fait aujourd'hui, sans que le
     * serveur ait a decider quel jour on est.
     */
    @Test
    @DisplayName("Chaque item porte la derniere activite de sa competence")
    void chaqueItemPorteLaDerniereActiviteDeSaCompetence() {
        LearningPlanPriorityDto travaillee = priorite("EE1-C1", SkillSection.EE, micro(4));
        LearningPlanPriorityDto jamaisTravaillee = priorite("EO1-C2", SkillSection.EO, micro(6));
        Instant hier = Instant.now().minus(1, ChronoUnit.DAYS);
        List<LearningPlanPriorityDto> priorites = List.of(travaillee, jamaisTravaillee);

        PlanSeanceDto seance = builder.build(priorites, skills(priorites),
                Map.of(travaillee.skillId(), hier), null);

        assertThat(seance.items()).extracting(PlanSeanceItemDto::lastActivityAt)
                .as("une competence absente de la carte n'invente pas de date")
                .containsExactly(hier, null);
    }

    /**
     * Un jalon ne travaille aucune competence : il n'a pas d'activite a dater,
     * et on ne lui en fabrique pas une.
     */
    @Test
    @DisplayName("Un jalon n'a pas de derniere activite")
    void leJalonNaPasDeDerniereActivite() {
        LearningPlanPriorityDto priorite = priorite("EE1-C1", SkillSection.EE, micro(4));
        PlanRecommendedExerciseDto jalon =
                PlanRecommendedExerciseDto.epreuveMockExam(EpreuveType.TCF_EE, 1, 30, false);

        PlanSeanceDto seance = builder.build(List.of(priorite), skills(List.of(priorite)),
                Map.of(priorite.skillId(), Instant.now()), jalon);

        assertThat(seance.items().getFirst().lastActivityAt()).isNull();
        assertThat(seance.items().getLast().lastActivityAt()).isNotNull();
    }

    @Test
    @DisplayName("Aucune priorite : une seance vide, jamais un item invente")
    void sansPrioriteLaSeanceEstVide() {
        PlanSeanceDto seance = builder.build(List.of(), Map.of(), Map.of(), null);

        assertThat(seance.items()).isEmpty();
        assertThat(seance.estimatedMinutes()).isZero();
    }

    // ------------------------------------------------------------------------
    // Fabriques
    // ------------------------------------------------------------------------

    private static LearningPlanPriorityDto priorite(
            String code, SkillSection section, PlanRecommendedExerciseDto exercise) {
        return new LearningPlanPriorityDto(
                UUID.randomUUID(), code, "Compétence " + code, section,
                LearningPlanSkillStatus.TO_REINFORCE, "Explication", "Preuve",
                ObservationConfidence.HIGH, Instant.now(), exercise,
                15, 2, 1, 5, 2, 1, false, List.of(),
                SkillMasteryState.TO_REINFORCE, false, false);
    }

    private static PlanRecommendedExerciseDto micro(int minutes) {
        return PlanRecommendedExerciseDto.microTraining(
                UUID.randomUUID(), UUID.randomUUID(), "EE1-C1", "Petit sujet",
                SkillSection.EE, minutes, false);
    }

    private static Map<UUID, Skill> skills(List<LearningPlanPriorityDto> priorites) {
        Map<UUID, Skill> out = new LinkedHashMap<>();
        for (LearningPlanPriorityDto priorite : priorites) {
            Skill skill = skill(priorite.skillCode(), priorite.section());
            skill.setId(priorite.skillId());
            out.put(priorite.skillId(), skill);
        }
        return out;
    }

    private static Skill skill(String code, SkillSection section) {
        Skill skill = new Skill();
        skill.setId(UUID.randomUUID());
        skill.setCode(code);
        skill.setTitle("Compétence " + code);
        skill.setSection(section);
        skill.setTargetLevel("A2");
        return skill;
    }
}
