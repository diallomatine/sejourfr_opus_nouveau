package com.sejourfr.app.service;

import com.sejourfr.app.dto.PlanDomainAssessmentDto;
import com.sejourfr.app.dto.PlanDomainDto;
import com.sejourfr.app.dto.TcfDomainProfileDto;
import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.PlanDomainAssessmentKind;
import com.sejourfr.app.enums.PlanDomainPriority;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.enums.SkillSection;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * « Completer mon profil » : ce qu'il reste a mesurer, et par quoi.
 *
 * <p>Le brief §99 exige que le Plan fonctionne a <b>0, 1, 2, 3 et 4 domaines
 * evalues</b> : les cinq etats sont couverts ici, sur le seul composant qui
 * repond a « et pour l'evaluer, je lance quoi ? ».
 */
class PlanDomainAssessmentResolverTest {

    private final PlanDomainAssessmentResolver resolver = new PlanDomainAssessmentResolver();

    // ------------------------------------------------------------------ 0 a 4

    @Test
    @DisplayName("0 sur 4 : les quatre domaines sont a mesurer, et l'ecran n'est jamais vide")
    void aucunDomaineMesure() {
        List<PlanDomainAssessmentDto> restants = resolver.resolve(domaines(Set.of()));

        assertThat(restants).extracting(PlanDomainAssessmentDto::epreuve)
                .containsExactly(EpreuveType.TCF_CO, EpreuveType.TCF_CE,
                        EpreuveType.TCF_EO, EpreuveType.TCF_EE);
        // Les QUATRE epreuves passent par un examen blanc DEJA EXISTANT : examen
        // de module en comprehension, examen de production (3 taches) en
        // expression. Aucun moteur n'est cree pour l'occasion.
        assertThat(restants).extracting(PlanDomainAssessmentDto::kind)
                .containsExactly(
                        PlanDomainAssessmentKind.MODULE_MOCK_EXAM,
                        PlanDomainAssessmentKind.MODULE_MOCK_EXAM,
                        PlanDomainAssessmentKind.PRODUCTION_MOCK_EXAM,
                        PlanDomainAssessmentKind.PRODUCTION_MOCK_EXAM);
        assertThat(restants).allSatisfy(item ->
                assertThat(item.slotNumber()).isEqualTo(1));
    }

    @Test
    @DisplayName("1 sur 4 : un premier domaine mesure ne sort du reste a faire que lui")
    void unSeulDomaineMesure() {
        List<PlanDomainAssessmentDto> restants =
                resolver.resolve(domaines(Set.of(EpreuveType.TCF_CO)));

        assertThat(restants).hasSize(3)
                .extracting(PlanDomainAssessmentDto::epreuve)
                .doesNotContain(EpreuveType.TCF_CO);
    }

    @Test
    @DisplayName("2 sur 4 apres un diagnostic rapide : il reste la comprehension, en examen blanc")
    void apresUnDiagnosticRapideIlResteLaComprehension() {
        List<PlanDomainAssessmentDto> restants = resolver.resolve(
                domaines(Set.of(EpreuveType.TCF_EE, EpreuveType.TCF_EO)));

        assertThat(restants).extracting(PlanDomainAssessmentDto::epreuve)
                .containsExactly(EpreuveType.TCF_CO, EpreuveType.TCF_CE);
        assertThat(restants).allSatisfy(item -> {
            assertThat(item.kind()).isEqualTo(PlanDomainAssessmentKind.MODULE_MOCK_EXAM);
            // Le slot OFFERT : mesurer un domaine ne bute jamais sur le paywall.
            assertThat(item.slotNumber()).isEqualTo(1);
        });
        assertThat(restants.getFirst().moduleExamQuestionType()).isEqualTo(QuestionType.CO);
        assertThat(restants.get(1).moduleExamQuestionType()).isEqualTo(QuestionType.CE);
        // Durees lues chez DureeEpreuve, jamais ecrites en dur : CO 20 min, CE 35.
        assertThat(restants.getFirst().estimatedMinutes()).isEqualTo(20);
        assertThat(restants.get(1).estimatedMinutes()).isEqualTo(35);
    }

    @Test
    @DisplayName("3 sur 4 : un seul domaine reste, et il est nomme")
    void troisDomainesMesures() {
        List<PlanDomainAssessmentDto> restants = resolver.resolve(
                domaines(Set.of(EpreuveType.TCF_CO, EpreuveType.TCF_EE, EpreuveType.TCF_EO)));

        assertThat(restants).hasSize(1);
        assertThat(restants.getFirst().epreuve()).isEqualTo(EpreuveType.TCF_CE);
        assertThat(restants.getFirst().kind())
                .isEqualTo(PlanDomainAssessmentKind.MODULE_MOCK_EXAM);
    }

    @Test
    @DisplayName("4 sur 4 : plus rien a mesurer — vide est l'etat vise, pas une anomalie")
    void profilComplet() {
        assertThat(resolver.resolve(domaines(Set.of(EpreuveType.TCF_CO, EpreuveType.TCF_CE,
                EpreuveType.TCF_EE, EpreuveType.TCF_EO)))).isEmpty();
    }

    // ------------------------------------------------------------------ nuances

    /**
     * 🛑 L'arbitrage du proprietaire du 2026-09-16 : « Evaluer mon niveau » lance
     * un examen blanc sur les QUATRE epreuves. L'expression ne retombe plus ni
     * sur l'ancien diagnostic (1 EE + 1 EO), ni sur l'entrainement libre — aucun
     * des deux ne lancait un examen blanc.
     */
    @Test
    @DisplayName("L'expression ecrite se mesure par un examen blanc de production, slot offert")
    void lExpressionEcriteSeMesureParUnExamenBlanc() {
        PlanDomainAssessmentDto mesure = resolver.pour(EpreuveType.TCF_EE);

        assertThat(mesure.kind()).isEqualTo(PlanDomainAssessmentKind.PRODUCTION_MOCK_EXAM);
        assertThat(mesure.slotNumber()).isEqualTo(1);
        // Une production ne se compose d'aucun type de question.
        assertThat(mesure.moduleExamQuestionType()).isNull();
        // Duree lue chez DureeEpreuve, jamais ecrite en dur : 30 min a l'ecrit.
        assertThat(mesure.estimatedMinutes()).isEqualTo(30);
    }

    @Test
    @DisplayName("L'expression orale aussi — et sans minutes : elle se chronometre par tache")
    void lExpressionOraleSeMesureParUnExamenBlancSansDuree() {
        PlanDomainAssessmentDto mesure = resolver.pour(EpreuveType.TCF_EO);

        assertThat(mesure.kind()).isEqualTo(PlanDomainAssessmentKind.PRODUCTION_MOCK_EXAM);
        assertThat(mesure.slotNumber()).isEqualTo(1);
        assertThat(mesure.moduleExamQuestionType()).isNull();
        // 🛑 Pas de « 0 min » : l'EO n'a aucune duree d'epreuve opposable.
        assertThat(mesure.estimatedMinutes()).isNull();
    }

    @Test
    @DisplayName("La comprehension est INCHANGEE : examen de module CO/CE, slot offert")
    void laComprehensionEstInchangee() {
        assertThat(resolver.pour(EpreuveType.TCF_CO))
                .isEqualTo(PlanDomainAssessmentDto.moduleMockExam(
                        EpreuveType.TCF_CO, QuestionType.CO, 1, 20));
        assertThat(resolver.pour(EpreuveType.TCF_CE))
                .isEqualTo(PlanDomainAssessmentDto.moduleMockExam(
                        EpreuveType.TCF_CE, QuestionType.CE, 1, 35));
    }

    @Test
    @DisplayName("Une epreuve hors des quatre du profil ne se mesure par rien")
    void horsProfilRienNEstDesigne() {
        assertThat(resolver.pour(null)).isNull();
        assertThat(resolver.pour(EpreuveType.TCF_STRUCTURE)).isNull();
        assertThat(resolver.pour(EpreuveType.TCF_COMPLET)).isNull();
        assertThat(resolver.pour(EpreuveType.CIVIQUE)).isNull();
    }

    @Test
    @DisplayName("Un diagnostic deja termine ne change RIEN : c'est toujours l'examen blanc")
    void unDiagnosticTermineNeChangeRienALaMesure() {
        // La branche `diagnosticTermine` a disparu de `pour()` : les deux
        // domaines d'expression rendent la meme chose, quel que soit le passe du
        // candidat. Le niveau qu'un ancien diagnostic a produit continue de
        // s'afficher (TcfProfileService) — c'est l'AFFICHAGE, pas l'ACTION.
        List<PlanDomainAssessmentDto> restants = resolver.resolve(
                domaines(Set.of(EpreuveType.TCF_CO, EpreuveType.TCF_CE, EpreuveType.TCF_EE)));

        assertThat(restants).hasSize(1);
        assertThat(restants.getFirst().epreuve()).isEqualTo(EpreuveType.TCF_EO);
        assertThat(restants.getFirst().kind())
                .isEqualTo(PlanDomainAssessmentKind.PRODUCTION_MOCK_EXAM);
        assertThat(restants.getFirst().slotNumber()).isEqualTo(1);
    }

    @Test
    @DisplayName("L'ordre servi est celui des epreuves du TCF, quel que soit celui recu")
    void lOrdreEstCeluiDuServeur() {
        List<PlanDomainDto> desordre = new ArrayList<>(domaines(Set.of()));
        desordre.sort((a, b) -> b.epreuve().compareTo(a.epreuve()));

        assertThat(resolver.resolve(desordre))
                .extracting(PlanDomainAssessmentDto::epreuve)
                .containsExactlyElementsOf(TcfDomainProfileDto.ORDRE);
    }

    @Test
    @DisplayName("Aucun domaine recu : rien a proposer, et surtout aucune exception")
    void listeVide() {
        assertThat(resolver.resolve(List.of())).isEmpty();
        assertThat(resolver.resolve(null)).isEmpty();
    }

    // ------------------------------------------------- la mesure indispensable

    @Test
    @DisplayName("Une production entierement NOT_OBSERVED reste une reevaluation indispensable")
    void uneProductionRateeEstTOUJOURSRetenue() {
        // Le cas fondateur : l'oral a bien ete rendu, le correcteur n'a RIEN pu
        // y observer. Sans cette carte, le Plan proposait de l'ecrit a l'infini
        // a un candidat dont c'est l'oral qui manquait. Non-regression.
        Optional<PlanDomainAssessmentDto> mesure = resolver.indispensable(
                domaines(Set.of(EpreuveType.TCF_CO, EpreuveType.TCF_CE, EpreuveType.TCF_EE)),
                List.of(observation(SkillSection.EO, false)));

        assertThat(mesure).isPresent();
        assertThat(mesure.get().epreuve()).isEqualTo(EpreuveType.TCF_EO);
        // 🛑 Remesurer, c'est repasser l'EPREUVE : un examen blanc, pas une
        // production libre — la meme mesure que « Completer mon profil ».
        assertThat(mesure.get().kind())
                .isEqualTo(PlanDomainAssessmentKind.PRODUCTION_MOCK_EXAM);
        assertThat(mesure.get().slotNumber()).isEqualTo(1);
    }

    @Test
    @DisplayName("Une production avec au moins une competence observee n'a rien a remesurer")
    void uneProductionPartiellementObserveeNEstPasRetenue() {
        Optional<PlanDomainAssessmentDto> mesure = resolver.indispensable(
                domaines(Set.of(EpreuveType.TCF_CO, EpreuveType.TCF_CE, EpreuveType.TCF_EE)),
                List.of(observation(SkillSection.EO, false), observation(SkillSection.EO, true)));

        assertThat(mesure).isEmpty();
    }

    /**
     * 🛑 Le correctif du 2026-09-16. En comprehension, {@code NOT_OBSERVED} dit
     * « echantillon trop mince pour conclure » (sous
     * {@code comprehension.min-questions}), <b>jamais</b> « la mesure a rate ».
     * Un candidat qui venait de finir ses 25 items de CE se voyait proposer de
     * refaire la CE entiere parce qu'un de ses trois paliers manquait de deux
     * reponses.
     */
    @Test
    @DisplayName("Une comprehension aux paliers NOT_OBSERVED n'est JAMAIS « a completer »")
    void uneComprehensionSansAssezDePreuveNEstPasRetenue() {
        Optional<PlanDomainAssessmentDto> mesure = resolver.indispensable(
                domaines(Set.of(EpreuveType.TCF_CE, EpreuveType.TCF_EE, EpreuveType.TCF_EO)),
                List.of(observation(SkillSection.CO, false),
                        observation(SkillSection.CO, false),
                        observation(SkillSection.CO, false)));

        assertThat(mesure).isEmpty();
    }

    @Test
    @DisplayName("Une comprehension non observee n'eclipse pas la production ratee qui, elle, compte")
    void laComprehensionNeMasquePasUneProductionRatee() {
        // La CO passe AVANT l'EO dans l'ordre des epreuves : si elle entrait
        // dans le calcul, elle raflerait l'unique place de la seance.
        Optional<PlanDomainAssessmentDto> mesure = resolver.indispensable(
                domaines(Set.of(EpreuveType.TCF_CE, EpreuveType.TCF_EE)),
                List.of(observation(SkillSection.CO, false), observation(SkillSection.EO, false)));

        assertThat(mesure).isPresent();
        assertThat(mesure.get().epreuve()).isEqualTo(EpreuveType.TCF_EO);
    }

    @Test
    @DisplayName("Aucun historique : rien n'a echoue, donc rien n'est indispensable")
    void sansObservationRienNEstIndispensable() {
        assertThat(resolver.indispensable(domaines(Set.of()), List.of())).isEmpty();
        assertThat(resolver.indispensable(domaines(Set.of()), null)).isEmpty();
    }

    // ------------------------------------------------------------------ fixtures

    private static LearningPlanObservation observation(SkillSection section, boolean observee) {
        Skill skill = new Skill();
        skill.setId(UUID.randomUUID());
        skill.setSection(section);
        LearningPlanObservation observation = new LearningPlanObservation();
        observation.setSkill(skill);
        observation.setObserved(observee);
        observation.setStatus(observee
                ? LearningPlanSkillStatus.TO_REINFORCE : LearningPlanSkillStatus.NOT_OBSERVED);
        return observation;
    }


    /** Les quatre domaines du profil, ceux de {@code mesures} portant un niveau. */
    private static List<PlanDomainDto> domaines(Set<EpreuveType> mesures) {
        List<PlanDomainDto> domaines = new ArrayList<>();
        for (EpreuveType epreuve : TcfDomainProfileDto.ORDRE) {
            boolean mesure = mesures.contains(epreuve);
            domaines.add(PlanDomainDto.sansCompetences(
                    epreuve, mesure, mesure ? NiveauCecrl.A2 : null,
                    mesure ? PlanDomainPriority.A_TRAVAILLER : PlanDomainPriority.A_EVALUER,
                    null, null, List.of(), List.of()));
        }
        return domaines;
    }
}
