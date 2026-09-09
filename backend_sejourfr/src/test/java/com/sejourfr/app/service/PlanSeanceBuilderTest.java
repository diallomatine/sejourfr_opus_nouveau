package com.sejourfr.app.service;

import com.sejourfr.app.service.plan.PlanConfig;
import com.sejourfr.app.service.plan.PlanConfigLoader;
import com.sejourfr.app.dto.LearningPlanPriorityDto;
import com.sejourfr.app.dto.PlanDomainAssessmentDto;
import com.sejourfr.app.dto.PlanRecommendedExerciseDto;
import com.sejourfr.app.dto.PlanSeanceDto;
import com.sejourfr.app.dto.PlanSeanceItemDto;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.PlanActionNature;
import com.sejourfr.app.enums.PlanDomainAssessmentKind;
import com.sejourfr.app.enums.PlanExerciseKind;
import com.sejourfr.app.enums.QuestionType;
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

    /** La configuration livree : le test lit le vrai plafond, jamais un 3 en dur. */
    private static final PlanConfig PLAN_CONFIG = PlanConfigLoader.load(1);

    private final PlanSeanceBuilder builder = new PlanSeanceBuilder(PLAN_CONFIG);

    @Test
    @DisplayName("Trois entrainements au maximum, meme avec plus de priorites")
    void laSeanceEstPlafonneeATroisEntrainements() {
        List<LearningPlanPriorityDto> priorites = List.of(
                priorite("EE1-C1", SkillSection.EE, micro(4)),
                priorite("EO1-C2", SkillSection.EO, micro(6)),
                priorite("EE2-C3", SkillSection.EE, micro(5)),
                priorite("EO2-C4", SkillSection.EO, micro(7)));

        PlanSeanceDto seance = builder.build(null, priorites, skills(priorites), Map.of(), null);

        assertThat(seance.items()).hasSize(PLAN_CONFIG.display().todayMaxActions());
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
                PlanActionNature.A_VERIFIER,
                LearningPlanSkillStatus.TO_REINFORCE, "Explication", "Preuve",
                ObservationConfidence.HIGH, Instant.now(),
                PlanRecommendedExerciseDto.reassessment(
                        UUID.randomUUID(), UUID.randomUUID(), "EE1-C1", "Tache complete",
                        SkillSection.EE, (short) 1, 12, false),
                15, 5, 5, 5, 5, 5, true, List.of(),
                SkillMasteryState.CONSOLIDATING, true, false);

        PlanSeanceDto seance =
                builder.build(null, List.of(prete), skills(List.of(prete)), Map.of(), null);

        assertThat(seance.items()).singleElement().satisfies(item -> {
            assertThat(item.skillCode()).isEqualTo("EE1-C1");
            assertThat(item.nature()).isEqualTo(PlanActionNature.A_VERIFIER);
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
                PlanActionNature.A_RENFORCER,
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

        PlanSeanceDto seance =
                builder.build(null, List.of(co), Map.of(skillId, skill), Map.of(), null);

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

        PlanSeanceDto seance = builder.build(null, priorites, skills(priorites), Map.of(), null);

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

        PlanSeanceDto premiere = builder.build(null, priorites, skills, activites, null);
        PlanSeanceDto seconde = builder.build(null, priorites, skills, activites, null);

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

        PlanSeanceDto seance = builder.build(null, priorites, skills(priorites), Map.of(), null);

        assertThat(seance.items()).singleElement()
                .extracting("skillCode").isEqualTo("EO1-C2");
        assertThat(seance.estimatedMinutes()).isEqualTo(6);
    }

    // ------------------------------------------------------------------------
    // L'ordre de choix : mesurer, reparer, apprendre, puis verifier
    // ------------------------------------------------------------------------

    /**
     * 🛑 Le premier maillon de l'ordre de choix : tant qu'un domaine <b>deja
     * travaille</b> n'a pas pu etre observe, les exercices qui suivent avancent a
     * l'aveugle. La mesure passe donc devant, y compris devant une fragilite
     * reelle — c'est le cas mesure sur un compte reel, dont l'oral etait
     * inexploitable et a qui le Plan ne proposait que de l'ecrit.
     */
    @Test
    @DisplayName("La mesure indispensable ouvre la seance et occupe un slot")
    void laMesureIndispensableOuvreLaSeance() {
        List<LearningPlanPriorityDto> priorites = List.of(
                priorite("EE1-C1", SkillSection.EE, micro(4)),
                priorite("EE2-C3", SkillSection.EE, micro(5)),
                priorite("EE3-C2", SkillSection.EE, micro(6)));
        PlanDomainAssessmentDto mesure = PlanDomainAssessmentDto.production(EpreuveType.TCF_EO);

        PlanSeanceDto seance = builder.build(mesure, priorites, skills(priorites), Map.of(), null);

        assertThat(seance.items()).hasSize(PLAN_CONFIG.display().todayMaxActions());
        assertThat(seance.items().getFirst()).satisfies(item -> {
            assertThat(item.nature()).isEqualTo(PlanActionNature.A_EVALUER);
            assertThat(item.assessment().epreuve()).isEqualTo(EpreuveType.TCF_EO);
            assertThat(item.assessment().kind()).isEqualTo(PlanDomainAssessmentKind.PRODUCTION);
            assertThat(item.exercise())
                    .as("une mesure n'est pas un entrainement : les deux champs s'excluent")
                    .isNull();
            assertThat(item.skillId()).isNull();
            assertThat(item.masteryState()).isNull();
            assertThat(item.lastActivityAt()).isNull();
        });
        assertThat(seance.items()).extracting("skillCode")
                .as("la mesure prend le slot de la troisieme fragilite, elle ne s'ajoute pas")
                .containsExactly(null, "EE1-C1", "EE2-C3");
    }

    /**
     * Une mesure dont rien n'est chronometre par epreuve — une production, le
     * diagnostic — compte pour <b>zero</b> minute plutot que pour un chiffre
     * invente. Un examen de module, lui, porte la duree de son epreuve.
     */
    @Test
    @DisplayName("Les minutes d'une mesure : celles de l'epreuve, ou zero — jamais inventees")
    void lesMinutesDUneMesureNeSInvententPas() {
        LearningPlanPriorityDto priorite = priorite("EE1-C1", SkillSection.EE, micro(4));
        Map<UUID, Skill> skills = skills(List.of(priorite));

        PlanSeanceDto sansDuree = builder.build(
                PlanDomainAssessmentDto.production(EpreuveType.TCF_EO),
                List.of(priorite), skills, Map.of(), null);
        PlanSeanceDto avecDuree = builder.build(
                PlanDomainAssessmentDto.moduleMockExam(
                        EpreuveType.TCF_CO, QuestionType.CO, 1, 20),
                List.of(priorite), skills, Map.of(), null);

        assertThat(sansDuree.estimatedMinutes()).isEqualTo(4);
        assertThat(avecDuree.estimatedMinutes()).isEqualTo(24);
    }

    /**
     * 🛑 Une competence <b>a acquerir</b> n'a rien d'observe, et la seance ne
     * fabrique pas de verdict pour remplir un champ : son etat de maitrise reste
     * {@code null}. C'est la nature qui la designe, jamais la nullite d'un champ
     * — et elle ne se dit <b>jamais</b> « a renforcer », puisque rien n'a echoue.
     */
    @Test
    @DisplayName("Une competence a acquerir porte sa nature, sans verdict invente")
    void uneCompetenceAAcquerirNaAucunVerdict() {
        LearningPlanPriorityDto aAcquerir = acquisition("EE2-C7", SkillSection.EE, micro(8));

        PlanSeanceDto seance = builder.build(
                null, List.of(aAcquerir), skills(List.of(aAcquerir)), Map.of(), null);

        assertThat(seance.items()).singleElement().satisfies(item -> {
            assertThat(item.nature()).isEqualTo(PlanActionNature.A_ACQUERIR);
            assertThat(item.nature().getLabel()).isEqualTo("À acquérir");
            assertThat(item.masteryState()).isNull();
            assertThat(item.readyForReassessment()).isFalse();
            assertThat(item.stepAttemptedCount())
                    .as("rien n'a encore ete fait : zero est exact")
                    .isZero();
            assertThat(item.lastActivityAt()).isNull();
        });
    }

    /**
     * Le jalon <b>ferme</b> la seance depuis le 2026-08-21 : un examen blanc de
     * 30 a 60 minutes n'a rien a prouver tant qu'une mesure manque ou qu'une
     * fragilite bloque, et le mettre en tete chassait le vrai travail du jour. Il
     * reste servi sur {@code LearningPlanDto.milestone} : il n'est pas perdu, il
     * n'est simplement pas prioritaire.
     */
    @Test
    @DisplayName("Le jalon ferme la seance et occupe le dernier slot")
    void leJalonFermeLaSeance() {
        List<LearningPlanPriorityDto> priorites = List.of(
                priorite("EE1-C1", SkillSection.EE, micro(4)),
                priorite("EO1-C2", SkillSection.EO, micro(6)));
        PlanRecommendedExerciseDto jalon =
                PlanRecommendedExerciseDto.epreuveMockExam(EpreuveType.TCF_EE, 1, 30, false);

        PlanSeanceDto seance = builder.build(null, priorites, skills(priorites), Map.of(), jalon);

        assertThat(seance.items()).hasSize(PLAN_CONFIG.display().todayMaxActions());
        assertThat(seance.items().getLast()).satisfies(item -> {
            assertThat(item.nature()).isEqualTo(PlanActionNature.A_VERIFIER);
            assertThat(item.exercise().kind()).isEqualTo(PlanExerciseKind.EPREUVE_MOCK_EXAM);
            assertThat(item.skillId()).isNull();
            assertThat(item.skillCode()).isNull();
            assertThat(item.masteryState()).isNull();
        });
        assertThat(seance.items()).extracting("skillCode")
                .containsExactly("EE1-C1", "EO1-C2", null);
        assertThat(seance.estimatedMinutes()).isEqualTo(40);
    }

    /**
     * Corollaire du precedent : le plafond ne cede pas au jalon. Une journee deja
     * pleine de travail reel ne se fait pas amputer d'une fragilite par un examen
     * blanc — celui-ci attendra la seance suivante.
     */
    @Test
    @DisplayName("Une seance deja pleine ne cede pas un slot au jalon")
    void leJalonNeChassePasLeTravailDuJour() {
        List<LearningPlanPriorityDto> priorites = List.of(
                priorite("EE1-C1", SkillSection.EE, micro(4)),
                priorite("EO1-C2", SkillSection.EO, micro(6)),
                priorite("EE2-C3", SkillSection.EE, micro(5)));
        PlanRecommendedExerciseDto jalon =
                PlanRecommendedExerciseDto.epreuveMockExam(EpreuveType.TCF_EE, 1, 30, false);

        PlanSeanceDto seance = builder.build(null, priorites, skills(priorites), Map.of(), jalon);

        assertThat(seance.items()).extracting("skillCode")
                .containsExactly("EE1-C1", "EO1-C2", "EE2-C3");
        assertThat(seance.estimatedMinutes()).isEqualTo(15);
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

        PlanSeanceDto seance = builder.build(null, priorites, skills(priorites),
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

        PlanSeanceDto seance = builder.build(null, List.of(priorite), skills(List.of(priorite)),
                Map.of(priorite.skillId(), Instant.now()), jalon);

        assertThat(seance.items().getFirst().lastActivityAt()).isNotNull();
        assertThat(seance.items().getLast().lastActivityAt()).isNull();
    }

    @Test
    @DisplayName("Aucune priorite : une seance vide, jamais un item invente")
    void sansPrioriteLaSeanceEstVide() {
        PlanSeanceDto seance = builder.build(null, List.of(), Map.of(), Map.of(), null);

        assertThat(seance.items()).isEmpty();
        assertThat(seance.estimatedMinutes()).isZero();
    }

    /**
     * 🛑 {@code MAX_ITEMS} est un <b>plafond</b>, pas un quota : deux actions
     * vraies rendent deux items. Rien n'est fabrique pour remplir l'ecran.
     */
    @Test
    @DisplayName("Deux actions vraies rendent deux items, jamais trois")
    void lePlafondNestPasUnQuota() {
        List<LearningPlanPriorityDto> priorites = List.of(
                priorite("EE1-C1", SkillSection.EE, micro(4)),
                acquisition("EE2-C7", SkillSection.EE, micro(8)));

        PlanSeanceDto seance = builder.build(null, priorites, skills(priorites), Map.of(), null);

        assertThat(seance.items()).hasSize(2);
        assertThat(seance.items()).extracting(PlanSeanceItemDto::nature)
                .containsExactly(PlanActionNature.A_RENFORCER, PlanActionNature.A_ACQUERIR);
    }

    // ------------------------------------------------------------------------
    // Fabriques
    // ------------------------------------------------------------------------

    private static LearningPlanPriorityDto priorite(
            String code, SkillSection section, PlanRecommendedExerciseDto exercise) {
        return new LearningPlanPriorityDto(
                UUID.randomUUID(), code, "Compétence " + code, section,
                PlanActionNature.A_RENFORCER,
                LearningPlanSkillStatus.TO_REINFORCE, "Explication", "Preuve",
                ObservationConfidence.HIGH, Instant.now(), exercise,
                15, 2, 1, 5, 2, 1, false, List.of(),
                SkillMasteryState.TO_REINFORCE, false, false);
    }

    /**
     * Une competence <b>a acquerir</b>, telle que {@code LearningPlanService} la
     * construit : aucun verdict, aucun etat de maitrise, aucun compteur.
     */
    private static LearningPlanPriorityDto acquisition(
            String code, SkillSection section, PlanRecommendedExerciseDto exercise) {
        return new LearningPlanPriorityDto(
                UUID.randomUUID(), code, "Compétence " + code, section,
                PlanActionNature.A_ACQUERIR,
                null, null, null, null, null, exercise,
                15, 0, 0, 5, 0, 0, false, List.of(),
                null, false, false);
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
