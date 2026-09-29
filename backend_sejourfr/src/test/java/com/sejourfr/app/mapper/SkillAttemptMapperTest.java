package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.SkillAttemptDto;
import com.sejourfr.app.dto.SkillLevelProgressDto;
import com.sejourfr.app.dto.SkillNiveauViseDto;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.SkillPrompt;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSkillAttempt;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.SituationNiveauVise;
import com.sejourfr.app.enums.SkillAttemptStatut;
import com.sejourfr.app.enums.SkillCriterionStatus;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillSelfEvaluation;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.service.competence.CompetenceAnalysisFields;
import com.sejourfr.app.service.competence.niveauvise.CompetenceNiveauViseFields;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class SkillAttemptMapperTest {

    private SkillAttemptMapper mapper;

    private SkillAttemptMapper mapper() {
        if (mapper == null) mapper = new SkillAttemptMapper();
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

    /**
     * L'audio d'un candidat n'est pas conserve : le DTO ne porte AUCUNE URL, pas
     * meme sur une ligne LEGACY qui garde encore sa cle R2. Ce qui est rendu
     * d'une production orale, c'est sa transcription.
     */
    @Test
    void aLegacyObjectKeyIsNeverTurnedIntoAnUrl() {
        UserSkillAttempt attempt = attempt();
        attempt.setAudioObjectKey("submissions/secret.webm");
        attempt.setAudioDurationSec(42);
        attempt.setTranscript("je voudrais reserver une salle");

        SkillAttemptDto dto = mapper().toDto(attempt);

        assertThat(dto.transcript()).isEqualTo("je voudrais reserver une salle");
        assertThat(dto.audioDurationSec()).isEqualTo(42);
        // Aucun accesseur audioUrl n'existe : le contrat lui-meme l'interdit.
        assertThat(SkillAttemptDto.class.getRecordComponents())
                .noneMatch(c -> c.getName().toLowerCase().contains("audiourl"));
    }

    /**
     * LEGACY : une analyse produite sous le contrat v1/v2. Rien n'a ete migre,
     * elle doit continuer de s'afficher — et surtout ne fabriquer NI jauge de
     * niveau (elle n'en porte aucun), NI bloc « pour viser ».
     */
    @Test
    void aLegacyAnalysisIsStillReadAndBuildsNoLevelBlock() {
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
        assertThat(dto.analysis().strengthTag()).isNull();
        assertThat(dto.analysis().focusTag()).isNull();
        assertThat(dto.analysis().levelProgress())
                .as("sans niveau persiste, il n'y a rien a situer")
                .isNull();
        assertThat(dto.analysis().niveauVise()).isNull();
    }

    /** Une analyse v3 : champs traduits un par un, jauge derivee cote serveur. */
    @Test
    void aV3AnalysisIsTranslatedFieldByFieldAndCarriesTheDerivedGauge() {
        UserSkillAttempt attempt = attempt();
        attempt.setStatut(SkillAttemptStatut.EVALUATED);
        attempt.setAnalysisRequested(true);
        attempt.setCriterionStatus(SkillCriterionStatus.PARTIAL);
        attempt.setUser(candidat(TargetProcedure.NAT, TargetLevel.B1));
        attempt.setAnalysisJson(analyseV3());

        SkillAttemptDto dto = mapper().toDto(attempt);

        assertThat(dto.analysis()).isNotNull();
        assertThat(dto.analysis().status()).isEqualTo(SkillCriterionStatus.PARTIAL);
        assertThat(dto.analysis().verdict()).isEqualTo("Le ton reste hésitant.");
        assertThat(dto.analysis().strengthTag()).isEqualTo("Salutation adaptée");
        assertThat(dto.analysis().focusTag()).isEqualTo("Vouvoiement constant");
        assertThat(dto.analysis().successPoint()).isNull();
        assertThat(dto.analysis().improvementPriority()).isNull();
        assertThat(dto.analysis().improvedVersion()).isNull();

        // La demarche fait plancher : NAT exige le B2, meme avec un targetLevel
        // herite a B1. C'est le serveur qui tranche, pas le front.
        SkillLevelProgressDto progres = dto.analysis().levelProgress();
        assertThat(progres).isNotNull();
        assertThat(progres.levelReached()).isEqualTo(NiveauCecrl.A2);
        assertThat(progres.targetLevel()).isEqualTo(TargetLevel.B2);
        assertThat(progres.situation()).isEqualTo(SituationNiveauVise.EN_CHEMIN);
        assertThat(progres.situationLabel()).isEqualTo("Encore du chemin vers ton objectif");
        assertThat(progres.scale())
                .containsExactly(NiveauCecrl.A2, NiveauCecrl.B1, NiveauCecrl.B2);
        assertThat(progres.cursorIndex()).isZero();
    }

    /** Le bloc du SECOND appel, quand il a abouti : traduit champ par champ. */
    @Test
    void theSecondCallBlockIsTranslatedWhenPresent() {
        UserSkillAttempt attempt = attempt();
        attempt.setUser(candidat(TargetProcedure.CR, null));
        Map<String, Object> json = analyseV3();
        json.put(CompetenceAnalysisFields.BLOC_POUR_VISER, blocPourViser());
        attempt.setAnalysisJson(json);

        SkillNiveauViseDto bloc = mapper().toDto(attempt).analysis().niveauVise();

        assertThat(bloc).isNotNull();
        assertThat(bloc.niveauVise()).isEqualTo(TargetLevel.B1);
        assertThat(bloc.niveauConstate()).isEqualTo(NiveauCecrl.A2);
        assertThat(bloc.leviers()).hasSize(2);
        assertThat(bloc.leviers().get(0).action()).isEqualTo("Formule ta demande plus poliment");
        assertThat(bloc.leviers().get(0).exemple()).isEqualTo("Serait-il possible de");
        assertThat(bloc.exempleCible().texte()).contains("serait-il possible");
        assertThat(bloc.exempleCible().segments()).hasSize(2);
        assertThat(bloc.exempleCible().segments().get(0).extrait())
                .as("le front surligne cet extrait : il est garanti sous-chaine du texte")
                .isEqualTo("serait-il possible d'obtenir un rendez-vous");
        assertThat(bloc.exempleCible().texte())
                .contains(bloc.exempleCible().segments().get(0).extrait());
        assertThat(bloc.aRetenir().formule()).isEqualTo("Serait-il possible de + infinitif");
    }

    /**
     * Une analyse v3 SANS bloc « pour viser » : cas nominal, pas une erreur. Le
     * second appel est best-effort — objectif deja atteint, fournisseur muet,
     * sortie refusee.
     */
    @Test
    void aV3AnalysisWithoutTheSecondCallBlockYieldsNull() {
        UserSkillAttempt attempt = attempt();
        attempt.setUser(candidat(TargetProcedure.NAT, null));
        attempt.setAnalysisJson(analyseV3());

        assertThat(mapper().toDto(attempt).analysis().niveauVise()).isNull();
    }

    /**
     * Sans demarche ni palier declare, on retombe sur le palier EDITORIAL de la
     * competence — et le candidat qui l'atteint le sait.
     */
    @Test
    void theSkillOwnLevelIsTheFallbackTarget() {
        UserSkillAttempt attempt = attempt();
        attempt.setUser(candidat(null, null));
        attempt.setAnalysisJson(analyseV3());

        SkillLevelProgressDto progres = mapper().toDto(attempt).analysis().levelProgress();

        assertThat(progres).isNotNull();
        assertThat(progres.targetLevel()).isEqualTo(TargetLevel.A2);
        assertThat(progres.situation()).isEqualTo(SituationNiveauVise.OBJECTIF_ATTEINT);
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

    private static Map<String, Object> analyseV3() {
        Map<String, Object> json = new LinkedHashMap<>();
        json.put(CompetenceAnalysisFields.STATUS, "PARTIAL");
        json.put(CompetenceAnalysisFields.LEVEL_REACHED, "A2");
        json.put(CompetenceAnalysisFields.VERDICT, "Le ton reste hésitant.");
        json.put(CompetenceAnalysisFields.STRENGTH_TAG, "Salutation adaptée");
        json.put(CompetenceAnalysisFields.FOCUS_TAG, "Vouvoiement constant");
        return json;
    }

    private static Map<String, Object> blocPourViser() {
        String texte = "Bonjour, serait-il possible d'obtenir un rendez-vous jeudi prochain ? "
                + "Je vous remercie par avance.";
        Map<String, Object> bloc = new LinkedHashMap<>();
        bloc.put(CompetenceNiveauViseFields.NIVEAU_VISE, "B1");
        bloc.put(CompetenceNiveauViseFields.NIVEAU_CONSTATE, "A2");
        bloc.put(CompetenceNiveauViseFields.LEVIERS, List.of(
                Map.of(CompetenceNiveauViseFields.ACTION, "Formule ta demande plus poliment",
                        CompetenceNiveauViseFields.EXEMPLE, "Serait-il possible de"),
                Map.of(CompetenceNiveauViseFields.ACTION, "Remercie à la fin",
                        CompetenceNiveauViseFields.EXEMPLE, "Je vous remercie par avance")));
        bloc.put(CompetenceNiveauViseFields.EXEMPLE_CIBLE, Map.of(
                CompetenceNiveauViseFields.TEXTE, texte,
                CompetenceNiveauViseFields.SEGMENTS, List.of(
                        Map.of(CompetenceNiveauViseFields.EXTRAIT,
                                "serait-il possible d'obtenir un rendez-vous",
                                CompetenceNiveauViseFields.APPORT, "plus poli"),
                        Map.of(CompetenceNiveauViseFields.EXTRAIT, "Je vous remercie par avance",
                                CompetenceNiveauViseFields.APPORT, "clôture soignée"))));
        bloc.put(CompetenceNiveauViseFields.A_RETENIR, Map.of(
                CompetenceNiveauViseFields.FORMULE, "Serait-il possible de + infinitif",
                CompetenceNiveauViseFields.EXPLICATION,
                "Pour demander sans donner d'ordre à quelqu'un qu'on ne connaît pas."));
        return bloc;
    }

    private static User candidat(TargetProcedure procedure, TargetLevel declare) {
        User user = new User();
        user.setId(UUID.randomUUID());
        user.setTargetProcedure(procedure);
        user.setTargetLevel(declare);
        return user;
    }

    private static UserSkillAttempt attempt() {
        Skill skill = new Skill();
        skill.setId(UUID.randomUUID());
        skill.setSection(SkillSection.EE);
        skill.setTaskCode(SkillTaskCode.EE1);
        skill.setCode("EE1-C1");
        skill.setTargetLevel("A2");

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
