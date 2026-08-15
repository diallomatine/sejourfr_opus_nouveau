package com.sejourfr.app.service;

import com.sejourfr.app.dto.FullTcfExamResponse;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AttemptStatus;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.Instant;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Le score d'une sous-épreuve QCM d'examen blanc complet, servi sur l'échelle
 * du relevé TCF (100-499), sur base réelle.
 *
 * <p>Le hub de progression affichait « 23/50 » : le score <b>pondéré interne</b>
 * (A2=1, B1=2, B2=3), qui ne veut rien dire pour un candidat. Le DTO porte
 * désormais {@code calibratedScore}, dérivé par {@link TcfLevelEstimatorService}
 * — le même service que les examens module, jamais une seconde formule.
 *
 * <p>Ce qui se vérifie ici et pas en unitaire : les colonnes
 * {@code weighted_score} / {@code max_weighted_score} d'un sous-attempt font
 * réellement l'aller-retour en base et ressortent converties dans le DTO servi.
 */
class FullTcfExamScoreCalibreIT extends AbstractIntegrationTest {

    @Autowired FullTcfExamService service;
    @Autowired AttemptManager attemptManager;
    @Autowired TcfLevelEstimatorService levelEstimator;
    @Autowired TestData data;

    private Attempt sub(Attempt parent, EpreuveType e) {
        return attemptManager.findSubAttempts(parent.getId()).stream()
                .filter(a -> a.getEpreuve() == e)
                .findFirst()
                .orElseThrow();
    }

    private static FullTcfExamResponse.SubAttempt subOf(FullTcfExamResponse r, EpreuveType e) {
        return r.subAttempts().stream().filter(s -> s.epreuve() == e).findFirst().orElseThrow();
    }

    @Test
    @DisplayName("Une sous-epreuve QCM terminee sert son score sur 100-499, le pondere restant en repli")
    void sousEpreuveQcmTerminee_sertLeScoreCalibre() {
        User user = data.user();
        FullTcfExamResponse created = service.start(user.getId(), 1);
        Attempt parent = attemptManager.findById(created.id()).orElseThrow();

        Attempt co = sub(parent, EpreuveType.TCF_CO);
        co.setWeightedScore(23);
        co.setMaxWeightedScore(50);
        co.setCecrlLevel(NiveauCecrl.A2);
        co.setFinishedAt(Instant.now());
        co.setStatus(AttemptStatus.TERMINE);
        attemptManager.save(co);

        FullTcfExamResponse r = service.get(user.getId(), created.id());
        FullTcfExamResponse.SubAttempt served = subOf(r, EpreuveType.TCF_CO);

        assertThat(served.calibratedScore()).isEqualTo(levelEstimator.calibratedScore(23, 50));
        // Le pondéré reste servi tel quel : repli des fronts, pas leur affichage.
        assertThat(served.score()).isEqualTo(23);
        assertThat(served.maxScore()).isEqualTo(50);
    }

    @Test
    @DisplayName("Sous-epreuves non notees : aucun /499 invente (QCM sans score, EE/EO sans QCM)")
    void sousEpreuvesNonNotees_nOntPasDeScoreCalibre() {
        User user = data.user();
        FullTcfExamResponse created = service.start(user.getId(), 1);

        FullTcfExamResponse r = service.get(user.getId(), created.id());

        // CE tout juste créée : pas encore de score pondéré en base.
        assertThat(subOf(r, EpreuveType.TCF_CE).calibratedScore()).isNull();
        // EE / EO ne sont pas des QCM : le champ n'a pas de sens pour elles.
        assertThat(subOf(r, EpreuveType.TCF_EE).calibratedScore()).isNull();
        assertThat(subOf(r, EpreuveType.TCF_EO).calibratedScore()).isNull();
    }
}
