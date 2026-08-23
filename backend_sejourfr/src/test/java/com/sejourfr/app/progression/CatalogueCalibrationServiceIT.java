package com.sejourfr.app.progression;

import com.sejourfr.app.entity.Question;
import com.sejourfr.app.enums.DifficultyBand;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.manager.QuestionManager;
import com.sejourfr.app.progression.calibration.CatalogueCalibrationService;
import com.sejourfr.app.progression.dto.CatalogueCalibrationDto;
import com.sejourfr.app.progression.dto.QuestionBandAssignmentRequest;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * L'outillage du tagging, sur banque réelle.
 *
 * <p>Assertions tolérantes au seed Flyway : on ne raisonne que sur les questions
 * créées par le test, jamais sur un total de table.
 */
class CatalogueCalibrationServiceIT extends AbstractIntegrationTest {

    @Autowired CatalogueCalibrationService service;
    @Autowired QuestionManager questionManager;
    @Autowired TestData data;

    /**
     * 🛑 Le test le plus important du fichier.
     *
     * <p>La bande la plus pauvre décide <b>seule</b>. Deux cents questions
     * MEDIUM ne valent rien s'il n'y a que trois HARD : le compteur doit dire
     * zéro série constructible, et nommer HARD. Une moyenne dirait « on y est
     * presque » et enverrait produire du contenu au mauvais endroit.
     */
    @Test
    @DisplayName("Le compteur suit la bande la plus pauvre, et la nomme")
    void laBandeLaPlusPauvreDecideSeule() {
        creer(DifficultyBand.EASY, 60);
        creer(DifficultyBand.MEDIUM, 200);
        creer(DifficultyBand.HARD, 3);

        CatalogueCalibrationDto couple = coupleTeste();

        assertThat(couple.easy()).isGreaterThanOrEqualTo(60);
        assertThat(couple.medium()).isGreaterThanOrEqualTo(200);
        assertThat(couple.hard()).isGreaterThanOrEqualTo(3);
        assertThat(couple.seriesConstructibles()).isZero();
        assertThat(couple.bandeLimitante()).isEqualTo("HARD");
    }

    @Test
    @DisplayName("Avec le stock, le compteur dit combien de séries sont constructibles")
    void compteLesSeriesConstructibles() {
        creer(DifficultyBand.EASY, 18);
        creer(DifficultyBand.MEDIUM, 30);
        creer(DifficultyBand.HARD, 12);

        assertThat(coupleTeste().seriesConstructibles()).isEqualTo(3);
    }

    /**
     * Un import de 300 lignes dont une porte une coquille doit poser les 299
     * bonnes. Sinon on relance l'import entier et on ne sait plus ce qui a été
     * appliqué.
     */
    @Test
    @DisplayName("Un identifiant inconnu est compté et ignoré, il n'annule pas le lot")
    void unIdentifiantInconnuNAnnulePasLeLot() {
        List<Question> questions = creer(null, 3);
        List<QuestionBandAssignmentRequest.Affectation> lot = new ArrayList<>();
        questions.forEach(q -> lot.add(new QuestionBandAssignmentRequest.Affectation(
                q.getId(), DifficultyBand.MEDIUM)));
        lot.add(new QuestionBandAssignmentRequest.Affectation(
                UUID.randomUUID(), DifficultyBand.HARD));

        CatalogueCalibrationService.Resultat resultat =
                service.affecter(new QuestionBandAssignmentRequest(lot));

        assertThat(resultat.posees()).isEqualTo(3);
        assertThat(resultat.introuvables()).hasSize(1);
        questions.forEach(q -> assertThat(
                questionManager.findById(q.getId()).orElseThrow().getDifficultyBand())
                .isEqualTo(DifficultyBand.MEDIUM));
    }

    /**
     * Retirer un tag qu'on sait faux vaut mieux que le remplacer par un tag
     * douteux. La série contenant la question redevient simplement
     * {@code UNCALIBRATED}, ce qui est la vérité.
     */
    @Test
    @DisplayName("Une bande nulle dé-tague, et c'est un cas légitime")
    void bandeNulleDetague() {
        Question question = creer(DifficultyBand.HARD, 1).getFirst();

        CatalogueCalibrationService.Resultat resultat = service.affecter(
                new QuestionBandAssignmentRequest(List.of(
                        new QuestionBandAssignmentRequest.Affectation(question.getId(), null))));

        assertThat(resultat.retirees()).isEqualTo(1);
        assertThat(questionManager.findById(question.getId()).orElseThrow()
                .getDifficultyBand()).isNull();
    }

    /**
     * L'export sert à travailler hors application : les questions non taguées
     * doivent venir en premier, sinon la liste se referme sans être lue.
     */
    @Test
    @DisplayName("L'export CSV met le travail restant en tête")
    void exportMetLeTravailRestantEnTete() {
        creer(DifficultyBand.EASY, 2);
        creer(null, 2);

        String csv = service.exporterCsv(SkillSection.CE, TargetLevel.B2);
        List<String> lignes = csv.lines().toList();

        assertThat(lignes.getFirst()).isEqualTo("questionId,domain,level,difficulty_band,enonce");
        List<String> corps = lignes.subList(1, lignes.size());
        int premiereTaguee = -1;
        int derniereNonTaguee = -1;
        for (int i = 0; i < corps.size(); i++) {
            boolean taguee = corps.get(i).split(",", -1)[3].isBlank() == false;
            if (taguee && premiereTaguee < 0) premiereTaguee = i;
            if (!taguee) derniereNonTaguee = i;
        }
        assertThat(premiereTaguee).isGreaterThan(derniereNonTaguee);
    }

    private CatalogueCalibrationDto coupleTeste() {
        return service.inventaire().couples().stream()
                .filter(c -> c.section() == SkillSection.CE && c.level() == TargetLevel.B2)
                .findFirst().orElseThrow();
    }

    /** {@code bande} nulle = questions volontairement non taguées. */
    private List<Question> creer(DifficultyBand bande, int combien) {
        List<Question> creees = new ArrayList<>(combien);
        for (int i = 0; i < combien; i++) {
            Question question = data.question();
            question.setModule(Module.TCF);
            question.setQuestionType(QuestionType.CE);
            question.setDifficulty(Difficulty.B2);
            question.setDifficultyBand(bande);
            creees.add(questionManager.save(question));
        }
        return creees;
    }
}
