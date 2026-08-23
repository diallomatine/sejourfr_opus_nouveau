package com.sejourfr.app.progression;

import com.sejourfr.app.entity.Question;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.DifficultyBand;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.manager.QuestionManager;
import com.sejourfr.app.progression.repository.ProgressionContentSignalRepository;
import com.sejourfr.app.progression.service.ComprehensionSeriesComposer;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Le tirage d'une série de compréhension, sur banque réelle.
 *
 * <p>Ce qui compte ici tient en une phrase : <b>une série est calibrée ou elle
 * ne l'est pas, et le compositeur ne ment jamais sur laquelle des deux</b>.
 *
 * <p>Assertions tolérantes au seed Flyway : la banque TCF est déjà peuplée, donc
 * on tague nous-mêmes les questions du palier visé et on raisonne sur ce que le
 * test a créé — jamais sur un total de table.
 */
class ComprehensionSeriesComposerIT extends AbstractIntegrationTest {

    @Autowired ComprehensionSeriesComposer composer;
    @Autowired QuestionManager questionManager;
    @Autowired ProgressionContentSignalRepository signalRepository;
    @Autowired TestData data;

    /**
     * Le palier de test : B2 en CE, volontairement le moins susceptible d'être
     * déjà rempli par le seed pour ce qui nous intéresse.
     */
    private static final Difficulty PALIER = Difficulty.B2;

    @Test
    @DisplayName("Avec le stock requis, la série sort exactement en 6 / 10 / 4")
    void serieCalibree() {
        User user = data.user();
        taguer(DifficultyBand.EASY, 8);
        taguer(DifficultyBand.MEDIUM, 12);
        taguer(DifficultyBand.HARD, 6);

        ComprehensionSeriesComposer.SerieComposee serie =
                composer.composer(user.getId(), SkillSection.CE, TargetLevel.B2);

        assertThat(serie.calibree()).isTrue();
        assertThat(serie.questions()).hasSize(20);
        Map<DifficultyBand, Long> parBande = serie.questions().stream()
                .collect(Collectors.groupingBy(Question::getDifficultyBand,
                        Collectors.counting()));
        assertThat(parBande)
                .containsEntry(DifficultyBand.EASY, 6L)
                .containsEntry(DifficultyBand.MEDIUM, 10L)
                .containsEntry(DifficultyBand.HARD, 4L);
    }

    /**
     * 🛑 Le test le plus important du fichier.
     *
     * <p>Il manque une seule question HARD. Le compositeur ne complète pas avec
     * une question non taguée pour « faire 20 » : il rend une série jouable —
     * priver le candidat de son entraînement serait pire — mais il la marque non
     * calibrée, et il dit ce qui manque. C'est exactement ce que §12 bis.5
     * exige : le seuil ne bouge pas, l'information remonte.
     */
    @Test
    @DisplayName("Une bande incomplète donne une série jouable, non calibrée, et un signal")
    void banqueInsuffisanteNeTrichePas() {
        User user = data.user();
        taguer(DifficultyBand.EASY, 8);
        taguer(DifficultyBand.MEDIUM, 12);
        taguer(DifficultyBand.HARD, 3);
        long signauxAvant = signalRepository.count();

        ComprehensionSeriesComposer.SerieComposee serie =
                composer.composer(user.getId(), SkillSection.CE, TargetLevel.B2);

        assertThat(serie.calibree()).isFalse();
        assertThat(serie.questions()).isNotEmpty();
        assertThat(signalRepository.count()).isEqualTo(signauxAvant + 1);
    }

    /** Deux tirages successifs ne resservent pas la même série (§12 bis.5). */
    @Test
    @DisplayName("Le tirage préfère les questions les moins vues récemment")
    void tiragePrefereLeNeuf() {
        User user = data.user();
        taguer(DifficultyBand.EASY, 20);
        taguer(DifficultyBand.MEDIUM, 30);
        taguer(DifficultyBand.HARD, 15);

        ComprehensionSeriesComposer.SerieComposee premiere =
                composer.composer(user.getId(), SkillSection.CE, TargetLevel.B2);
        ComprehensionSeriesComposer.SerieComposee seconde =
                composer.composer(user.getId(), SkillSection.CE, TargetLevel.B2);

        assertThat(premiere.calibree()).isTrue();
        assertThat(seconde.calibree()).isTrue();
        assertThat(seconde.questionIds()).isNotEqualTo(premiere.questionIds());
    }

    /** Tague {@code combien} questions CE B2 neuves de cette bande. */
    private void taguer(DifficultyBand bande, int combien) {
        for (int i = 0; i < combien; i++) {
            Question question = data.question();
            question.setModule(Module.TCF);
            question.setQuestionType(QuestionType.CE);
            question.setDifficulty(PALIER);
            question.setDifficultyBand(bande);
            questionManager.save(question);
        }
    }
}
