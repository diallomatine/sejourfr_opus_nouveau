package com.sejourfr.app.service;

import com.sejourfr.app.dto.PlanDomainAssessmentDto;
import com.sejourfr.app.dto.PlanDomainDto;
import com.sejourfr.app.dto.TcfDomainProfileDto;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.PlanDomainAssessmentKind;
import com.sejourfr.app.enums.PlanDomainPriority;
import com.sejourfr.app.enums.QuestionType;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.List;
import java.util.Set;

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
        List<PlanDomainAssessmentDto> restants = resolver.resolve(domaines(Set.of()), false);

        assertThat(restants).extracting(PlanDomainAssessmentDto::epreuve)
                .containsExactly(EpreuveType.TCF_CO, EpreuveType.TCF_CE,
                        EpreuveType.TCF_EO, EpreuveType.TCF_EE);
        // La comprehension passe par un examen blanc DEJA EXISTANT, l'expression
        // par le diagnostic : aucun moteur n'est cree pour l'occasion.
        assertThat(restants).extracting(PlanDomainAssessmentDto::kind)
                .containsExactly(
                        PlanDomainAssessmentKind.MODULE_MOCK_EXAM,
                        PlanDomainAssessmentKind.MODULE_MOCK_EXAM,
                        PlanDomainAssessmentKind.DIAGNOSTIC,
                        PlanDomainAssessmentKind.DIAGNOSTIC);
    }

    @Test
    @DisplayName("1 sur 4 : un premier domaine mesure ne sort du reste a faire que lui")
    void unSeulDomaineMesure() {
        List<PlanDomainAssessmentDto> restants =
                resolver.resolve(domaines(Set.of(EpreuveType.TCF_CO)), false);

        assertThat(restants).hasSize(3)
                .extracting(PlanDomainAssessmentDto::epreuve)
                .doesNotContain(EpreuveType.TCF_CO);
    }

    @Test
    @DisplayName("2 sur 4 apres un diagnostic rapide : il reste la comprehension, en examen blanc")
    void apresUnDiagnosticRapideIlResteLaComprehension() {
        List<PlanDomainAssessmentDto> restants = resolver.resolve(
                domaines(Set.of(EpreuveType.TCF_EE, EpreuveType.TCF_EO)), true);

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
                domaines(Set.of(EpreuveType.TCF_CO, EpreuveType.TCF_EE, EpreuveType.TCF_EO)),
                true);

        assertThat(restants).hasSize(1);
        assertThat(restants.getFirst().epreuve()).isEqualTo(EpreuveType.TCF_CE);
        assertThat(restants.getFirst().kind())
                .isEqualTo(PlanDomainAssessmentKind.MODULE_MOCK_EXAM);
    }

    @Test
    @DisplayName("4 sur 4 : plus rien a mesurer — vide est l'etat vise, pas une anomalie")
    void profilComplet() {
        assertThat(resolver.resolve(domaines(Set.of(EpreuveType.TCF_CO, EpreuveType.TCF_CE,
                EpreuveType.TCF_EE, EpreuveType.TCF_EO)), true)).isEmpty();
    }

    // ------------------------------------------------------------------ nuances

    @Test
    @DisplayName("Le diagnostic est designe sur les DEUX domaines d'expression : une porte, deux domaines")
    void leDiagnosticCouvreLesDeuxDomainesDExpression() {
        List<PlanDomainAssessmentDto> restants = resolver.resolve(
                domaines(Set.of(EpreuveType.TCF_CO, EpreuveType.TCF_CE)), false);

        assertThat(restants).extracting(PlanDomainAssessmentDto::kind)
                .containsExactly(PlanDomainAssessmentKind.DIAGNOSTIC,
                        PlanDomainAssessmentKind.DIAGNOSTIC);
        assertThat(restants).extracting(PlanDomainAssessmentDto::epreuve)
                .containsExactly(EpreuveType.TCF_EO, EpreuveType.TCF_EE);
    }

    @Test
    @DisplayName("Diagnostic deja termine et expression toujours vide : une production, pas un rejeu")
    void unDiagnosticTermineNeSeRejouePas() {
        List<PlanDomainAssessmentDto> restants = resolver.resolve(
                domaines(Set.of(EpreuveType.TCF_CO, EpreuveType.TCF_CE, EpreuveType.TCF_EE)),
                true);

        assertThat(restants).hasSize(1);
        assertThat(restants.getFirst().epreuve()).isEqualTo(EpreuveType.TCF_EO);
        assertThat(restants.getFirst().kind()).isEqualTo(PlanDomainAssessmentKind.PRODUCTION);
        // Une production n'est ni chronometree par epreuve ni tiree d'une grille.
        assertThat(restants.getFirst().slotNumber()).isNull();
        assertThat(restants.getFirst().estimatedMinutes()).isNull();
        assertThat(restants.getFirst().moduleExamQuestionType()).isNull();
    }

    @Test
    @DisplayName("L'ordre servi est celui des epreuves du TCF, quel que soit celui recu")
    void lOrdreEstCeluiDuServeur() {
        List<PlanDomainDto> desordre = new ArrayList<>(domaines(Set.of()));
        desordre.sort((a, b) -> b.epreuve().compareTo(a.epreuve()));

        assertThat(resolver.resolve(desordre, false))
                .extracting(PlanDomainAssessmentDto::epreuve)
                .containsExactlyElementsOf(TcfDomainProfileDto.ORDRE);
    }

    @Test
    @DisplayName("Aucun domaine recu : rien a proposer, et surtout aucune exception")
    void listeVide() {
        assertThat(resolver.resolve(List.of(), false)).isEmpty();
        assertThat(resolver.resolve(null, true)).isEmpty();
    }

    // ------------------------------------------------------------------ fixtures

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
