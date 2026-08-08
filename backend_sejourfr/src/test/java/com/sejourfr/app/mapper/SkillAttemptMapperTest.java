package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.SkillAttemptDto;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.SkillPrompt;
import com.sejourfr.app.entity.UserSkillAttempt;
import com.sejourfr.app.enums.SkillAttemptStatut;
import com.sejourfr.app.enums.SkillCriterionStatus;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillSelfEvaluation;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.service.ProductionAudioStorageService;
import com.sejourfr.app.service.competence.CompetenceAnalysisFields;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class SkillAttemptMapperTest {

    @Mock
    private ProductionAudioStorageService audioStorage;

    private SkillAttemptMapper mapper;

    private SkillAttemptMapper mapper() {
        if (mapper == null) mapper = new SkillAttemptMapper(audioStorage);
        return mapper;
    }

    @Test
    void writtenAttemptWithoutAnalysisHasNoAnalysisBlock() {
        UserSkillAttempt attempt = attempt();
        attempt.setWrittenProduction("Bonjour cher voisin.");
        attempt.setWordsCount(3);
        attempt.setSelfEvaluation(SkillSelfEvaluation.REUSSI);

        SkillAttemptDto dto = mapper().toDto(attempt);

        // Cas nominal du parcours gratuit : pas d'analyse n'est pas une erreur.
        assertThat(dto.analysis()).isNull();
        assertThat(dto.criterionStatus()).isNull();
        assertThat(dto.statut()).isEqualTo(SkillAttemptStatut.RECORDED);
        assertThat(dto.selfEvaluation()).isEqualTo(SkillSelfEvaluation.REUSSI);
        assertThat(dto.skillPromptCode()).isEqualTo("EE1-C1-S1");
    }

    @Test
    void theRawObjectKeyIsNeverExposed() {
        UserSkillAttempt attempt = attempt();
        attempt.setAudioObjectKey("submissions/secret.webm");

        // toDto ne signe pas : la cle brute ne doit jamais sortir du backend.
        assertThat(mapper().toDto(attempt).audioUrl()).isNull();
        verify(audioStorage, never()).presignGet("submissions/secret.webm");
    }

    @Test
    void signedVariantExposesAPresignedUrl() {
        UserSkillAttempt attempt = attempt();
        attempt.setAudioObjectKey("submissions/abc.webm");
        when(audioStorage.presignGet("submissions/abc.webm")).thenReturn("https://r2/signed?x=1");

        assertThat(mapper().toDtoWithSignedAudio(attempt).audioUrl())
                .isEqualTo("https://r2/signed?x=1");
    }

    @Test
    void signedVariantOnAWrittenAttemptDoesNotCallStorage() {
        UserSkillAttempt attempt = attempt();
        attempt.setWrittenProduction("Bonjour.");

        assertThat(mapper().toDtoWithSignedAudio(attempt).audioUrl()).isNull();
        verify(audioStorage, never()).presignGet(org.mockito.ArgumentMatchers.anyString());
    }

    @Test
    void analysisJsonIsTranslatedFieldByField() {
        UserSkillAttempt attempt = attempt();
        attempt.setStatut(SkillAttemptStatut.EVALUATED);
        attempt.setAnalysisRequested(true);
        attempt.setCriterionStatus(SkillCriterionStatus.PARTIAL);
        Map<String, Object> json = new LinkedHashMap<>();
        json.put(CompetenceAnalysisFields.STATUS, "PARTIAL");
        json.put(CompetenceAnalysisFields.VERDICT, "Le ton reste hésitant.");
        json.put(CompetenceAnalysisFields.SUCCESS_POINT, "La salutation est adaptée.");
        json.put(CompetenceAnalysisFields.IMPROVEMENT_PRIORITY, "Choisir un vouvoiement constant.");
        json.put(CompetenceAnalysisFields.IMPROVED_VERSION, "Bonjour Madame, je vous préviens…");
        attempt.setAnalysisJson(json);

        SkillAttemptDto dto = mapper().toDto(attempt);

        assertThat(dto.analysis()).isNotNull();
        assertThat(dto.analysis().status()).isEqualTo(SkillCriterionStatus.PARTIAL);
        assertThat(dto.analysis().verdict()).isEqualTo("Le ton reste hésitant.");
        assertThat(dto.analysis().successPoint()).isEqualTo("La salutation est adaptée.");
        assertThat(dto.analysis().improvementPriority())
                .isEqualTo("Choisir un vouvoiement constant.");
        assertThat(dto.analysis().improvedVersion()).isEqualTo("Bonjour Madame, je vous préviens…");
    }

    @Test
    void theColumnWinsOverTheJsonForTheVerdict() {
        // Une seule source d'affichage : c'est la colonne qui derive le statut du
        // sujet, elle doit donc etre celle qui s'affiche.
        UserSkillAttempt attempt = attempt();
        attempt.setCriterionStatus(SkillCriterionStatus.VALIDATED);
        attempt.setAnalysisJson(Map.of(CompetenceAnalysisFields.STATUS, "NOT_VALIDATED"));

        assertThat(mapper().toDto(attempt).analysis().status())
                .isEqualTo(SkillCriterionStatus.VALIDATED);
    }

    @Test
    void anEmptyAnalysisJsonProducesNoAnalysisBlock() {
        UserSkillAttempt attempt = attempt();
        attempt.setAnalysisJson(Map.of());

        assertThat(mapper().toDto(attempt).analysis()).isNull();
    }

    @Test
    void failureMessageIsCarriedThrough() {
        UserSkillAttempt attempt = attempt();
        attempt.setStatut(SkillAttemptStatut.FAILED);
        attempt.setAnalysisRequested(true);
        attempt.setErrorMessage("Fournisseur indisponible");

        SkillAttemptDto dto = mapper().toDto(attempt);

        assertThat(dto.statut()).isEqualTo(SkillAttemptStatut.FAILED);
        assertThat(dto.errorMessage()).isEqualTo("Fournisseur indisponible");
        assertThat(dto.analysis()).isNull();
    }

    private static UserSkillAttempt attempt() {
        Skill skill = new Skill();
        skill.setId(UUID.randomUUID());
        skill.setSection(SkillSection.EE);
        skill.setTaskCode(SkillTaskCode.EE1);
        skill.setCode("EE1-C1");

        SkillPrompt prompt = new SkillPrompt();
        prompt.setId(UUID.randomUUID());
        prompt.setSkill(skill);
        prompt.setSection(SkillSection.EE);
        prompt.setCode("EE1-C1-S1");

        UserSkillAttempt attempt = new UserSkillAttempt();
        attempt.setId(UUID.randomUUID());
        attempt.setSkillPrompt(prompt);
        attempt.setStatut(SkillAttemptStatut.RECORDED);
        return attempt;
    }
}
