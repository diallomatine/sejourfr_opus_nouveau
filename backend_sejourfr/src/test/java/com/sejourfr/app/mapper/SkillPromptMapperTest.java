package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.SkillDto;
import com.sejourfr.app.dto.SkillPromptDto;
import com.sejourfr.app.dto.SkillPromptSummaryDto;
import com.sejourfr.app.dto.SkillReferenceDto;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.SkillConstraintTag;
import com.sejourfr.app.entity.SkillPrompt;
import com.sejourfr.app.entity.SkillReference;
import com.sejourfr.app.enums.SkillConstraintIcon;
import com.sejourfr.app.enums.SkillDifficulty;
import com.sejourfr.app.enums.SkillPromptStatus;
import com.sejourfr.app.enums.SkillReferenceLevel;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillTaskCode;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.tuple;

/** Mappers purs du module competences : aucune dependance, aucune doublure. */
class SkillPromptMapperTest {

    private final SkillPromptMapper promptMapper = new SkillPromptMapper();
    private final SkillMapper skillMapper = new SkillMapper();
    private final SkillReferenceMapper referenceMapper = new SkillReferenceMapper();

    @Test
    void summaryCarriesTheCriterionAndTheProgress() {
        SkillPrompt prompt = writtenPrompt();
        Instant lastAttemptAt = Instant.parse("2026-08-01T10:15:30Z");

        SkillPromptSummaryDto dto = promptMapper.toSummaryDto(
                prompt, SkillPromptStatus.TO_REINFORCE, 3, lastAttemptAt, false);

        assertThat(dto.uniqueCriterion()).isEqualTo("Adapter le ton au destinataire.");
        assertThat(dto.difficultyLevel()).isEqualTo(SkillDifficulty.MEDIUM);
        assertThat(dto.status()).isEqualTo(SkillPromptStatus.TO_REINFORCE);
        assertThat(dto.attemptCount()).isEqualTo(3);
        assertThat(dto.lastAttemptAt()).isEqualTo(lastAttemptAt);
        assertThat(dto.recommendedMinWords()).isEqualTo(15);
        assertThat(dto.recommendedDurationSeconds()).isNull();
    }

    @Test
    void fullPromptExposesTheOfficialTaskTitleFromTheEnum() {
        SkillPrompt prompt = writtenPrompt();
        UUID nextPromptId = UUID.randomUUID();
        UUID lastAttemptId = UUID.randomUUID();

        SkillPromptDto dto = promptMapper.toDto(prompt, prompt.getSkill(), 5,
                SkillPromptStatus.TREATED, 1, Instant.EPOCH, lastAttemptId, nextPromptId, false);

        // Le libelle de tache vient du referentiel officiel (enum), pas de la base.
        assertThat(dto.taskTitle()).isEqualTo("Écrire un message court");
        assertThat(dto.taskCode()).isEqualTo(SkillTaskCode.EE1);
        assertThat(dto.skillCode()).isEqualTo("EE1-C1");
        assertThat(dto.skillTitle()).isEqualTo("Adapter le message au destinataire");
        assertThat(dto.section()).isEqualTo(SkillSection.EE);
        assertThat(dto.lastAttemptId()).isEqualTo(lastAttemptId);
        assertThat(dto.nextPromptId()).isEqualTo(nextPromptId);
    }

    /**
     * L'ecran de production doit pouvoir afficher « Sujet i/5 » et l'encart
     * « Pourquoi cet exercice ? » sans second appel a {@code GET /api/skills/…}.
     */
    @Test
    void fullPromptCarriesTheSkillTextsAndItsPromptCount() {
        SkillPrompt prompt = writtenPrompt();

        SkillPromptDto dto = promptMapper.toDto(prompt, prompt.getSkill(), 5,
                SkillPromptStatus.TODO, 0, null, null, null, false);

        assertThat(dto.skillPromptCount()).isEqualTo(5);
        assertThat(dto.skillTargetLevel()).isEqualTo("A2");
        assertThat(dto.skillDescription()).isEqualTo("Choisir un ton adapté au destinataire.");
        assertThat(dto.skillGeneralCriterion())
                .isEqualTo("Le ton et les formules sont adaptés au destinataire.");
        // Le critere du SUJET reste distinct de celui de la COMPETENCE.
        assertThat(dto.uniqueCriterion()).isNotEqualTo(dto.skillGeneralCriterion());
    }

    /**
     * L'ecran de saisie ne montre plus le critere brut : il montre une
     * check-list, des etiquettes, une amorce et une astuce. S'ils ne sont pas
     * servis, l'ecran retombe sur l'ancienne forme sans que rien n'echoue —
     * d'ou ce test, qui verifie qu'ils font bien le voyage jusqu'au DTO.
     */
    @Test
    void fullPromptServesTheFourGuidanceFields() {
        SkillPrompt prompt = writtenPrompt();
        prompt.setChecklist(List.of("Saluez votre voisine", "Dites qui vous êtes", "Écrivez deux phrases"));
        prompt.setConstraintTags(List.of(
                new SkillConstraintTag("Vouvoiement", SkillConstraintIcon.PERSON),
                new SkillConstraintTag("Ton poli", SkillConstraintIcon.TONE)));
        prompt.setAnswerStarter("Bonjour Madame, je suis votre voisin du…");
        prompt.setTip("commencez par bonjour, puis présentez-vous");

        SkillPromptDto dto = promptMapper.toDto(prompt, prompt.getSkill(), 5,
                SkillPromptStatus.TODO, 0, null, null, null, false);

        assertThat(dto.checklist())
                .containsExactly("Saluez votre voisine", "Dites qui vous êtes", "Écrivez deux phrases");
        assertThat(dto.constraintTags())
                .extracting(SkillConstraintTag::label, SkillConstraintTag::icon)
                .containsExactly(
                        tuple("Vouvoiement", SkillConstraintIcon.PERSON),
                        tuple("Ton poli", SkillConstraintIcon.TONE));
        assertThat(dto.answerStarter()).isEqualTo("Bonjour Madame, je suis votre voisin du…");
        // L'astuce est servie SANS le prefixe « Astuce : » : c'est le front qui l'ajoute.
        assertThat(dto.tip()).isEqualTo("commencez par bonjour, puis présentez-vous")
                .doesNotStartWith("Astuce");
    }

    /**
     * Un sujet cree depuis la console peut naitre sans guidage : les colonnes
     * sont nullables (V026). Il doit alors etre servi <b>sans exception</b>, en
     * laissant les quatre champs a {@code null} — c'est aux fronts de retomber
     * sur la consigne. Une valeur de repli fabriquee ici leur cacherait
     * l'absence et remplirait la carte « Ce qu'il faut faire » avec du vide.
     */
    @Test
    void promptWithoutGuidanceIsServedWithNullsAndNoFailure() {
        SkillPrompt prompt = writtenPrompt();

        SkillPromptDto dto = promptMapper.toDto(prompt, prompt.getSkill(), 5,
                SkillPromptStatus.TODO, 0, null, null, null, false);
        SkillPromptSummaryDto summary = promptMapper.toSummaryDto(
                prompt, SkillPromptStatus.TODO, 0, null, false);

        assertThat(dto.checklist()).isNull();
        assertThat(dto.constraintTags()).isNull();
        assertThat(dto.answerStarter()).isNull();
        assertThat(dto.tip()).isNull();
        // La carte du sujet reste servie : le guidage ne conditionne rien d'autre.
        assertThat(dto.instruction()).isEqualTo("Rédigez trois phrases.");
        assertThat(summary.uniqueCriterion()).isEqualTo("Adapter le ton au destinataire.");
    }

    @Test
    void oralPromptCarriesADurationAndNoWordBounds() {
        SkillPrompt prompt = writtenPrompt();
        prompt.setSection(SkillSection.EO);
        prompt.setRecommendedMinWords(null);
        prompt.setRecommendedMaxWords(null);
        prompt.setRecommendedDurationSeconds(45);

        SkillPromptSummaryDto dto = promptMapper.toSummaryDto(
                prompt, SkillPromptStatus.TODO, 0, null, false);

        assertThat(dto.recommendedDurationSeconds()).isEqualTo(45);
        assertThat(dto.recommendedMinWords()).isNull();
        assertThat(dto.recommendedMaxWords()).isNull();
        assertThat(dto.lastAttemptAt()).isNull();
    }

    @Test
    void skillCountersArePassedThroughUntouched() {
        SkillDto dto = skillMapper.toDto(skill(), 5, 3, 2, 1, null, false);

        assertThat(dto.promptCount()).isEqualTo(5);
        assertThat(dto.attemptedCount()).isEqualTo(3);
        assertThat(dto.validatedCount()).isEqualTo(2);
        assertThat(dto.toReinforceCount()).isEqualTo(1);
        assertThat(dto.code()).isEqualTo("EE1-C1");
        assertThat(dto.targetLevel()).isEqualTo("A2");
        // Deux textes distincts : l'explication et le critere general. Les
        // confondre obligeait les fronts a rendre le meme texte a deux endroits.
        assertThat(dto.description()).isEqualTo("Choisir un ton adapté au destinataire.");
        assertThat(dto.generalCriterion())
                .isEqualTo("Le ton et les formules sont adaptés au destinataire.");
    }

    @Test
    void referenceCarriesItsLevelAndPedagogicalNote() {
        SkillReference reference = new SkillReference();
        reference.setLevel(SkillReferenceLevel.EXCELLENT);
        reference.setText("Bonjour Madame, je me permets de vous signaler…");
        reference.setPedagogicalNote("Le registre est tenu de bout en bout.");

        SkillReferenceDto dto = referenceMapper.toDto(reference);

        assertThat(dto.level()).isEqualTo(SkillReferenceLevel.EXCELLENT);
        assertThat(dto.pedagogicalNote()).isEqualTo("Le registre est tenu de bout en bout.");
    }

    private static Skill skill() {
        Skill skill = new Skill();
        skill.setId(UUID.randomUUID());
        skill.setSection(SkillSection.EE);
        skill.setTaskCode(SkillTaskCode.EE1);
        skill.setCode("EE1-C1");
        skill.setTitle("Adapter le message au destinataire");
        skill.setDescription("Choisir un ton adapté au destinataire.");
        skill.setGeneralCriterion("Le ton et les formules sont adaptés au destinataire.");
        skill.setTargetLevel("A2");
        skill.setDisplayOrder((short) 1);
        skill.setActive(true);
        return skill;
    }

    private static SkillPrompt writtenPrompt() {
        SkillPrompt prompt = new SkillPrompt();
        prompt.setId(UUID.randomUUID());
        prompt.setSkill(skill());
        prompt.setSection(SkillSection.EE);
        prompt.setCode("EE1-C1-S1");
        prompt.setTitle("Prévenir son propriétaire");
        prompt.setContext("Vous écrivez à votre propriétaire.");
        prompt.setInstruction("Rédigez trois phrases.");
        prompt.setUniqueCriterion("Adapter le ton au destinataire.");
        prompt.setRecommendedMinWords(15);
        prompt.setRecommendedMaxWords(50);
        prompt.setDifficultyLevel(SkillDifficulty.MEDIUM);
        prompt.setDisplayOrder((short) 1);
        prompt.setActive(true);
        return prompt;
    }
}
