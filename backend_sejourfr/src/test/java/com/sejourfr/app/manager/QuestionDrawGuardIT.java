package com.sejourfr.app.manager;

import com.sejourfr.app.entity.Question;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.DifficultyBand;
import com.sejourfr.app.enums.MediaType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionStatus;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.repository.QuestionRepository;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 🛑 Garde-fou des tirages candidats ({@code QuestionRepository.SERVABLE_JPQL} /
 * {@code SERVABLE_SQL}) : une question active mais encore {@code DRAFT} n'est
 * jamais tiree, une CO_IMAGE sans audio non plus ; une CO_IMAGE avec audio
 * l'est toujours. Et chaque stock qui annonce un tirage compte exactement ce
 * que le tirage peut servir.
 *
 * <p>Toutes les questions vivent dans un theme et un palier propres au test, et
 * les tirages sans filtre de theme sont lus en entier (taille de page
 * superieure au stock) : on assertionne l'appartenance, jamais un ordre.
 */
class QuestionDrawGuardIT extends AbstractIntegrationTest {

    private static final int TOUT = 100_000;

    @Autowired private QuestionManager manager;
    @Autowired private QuestionRepository repository;
    @Autowired private TestData testData;

    private Theme theme;
    private Question ceServie;
    private Question ceDraftActive;
    private Question ceArchiveeActive;
    private Question coImageAvecAudio;
    private Question coImageSansAudio;
    private Question coClassique;

    @BeforeEach
    void stock() {
        theme = testData.theme(Module.TCF, "garde", "Thème garde-fou");
        ceServie = question(QuestionType.CE, QuestionStatus.ACTIVE);
        ceDraftActive = question(QuestionType.CE, QuestionStatus.DRAFT);
        ceArchiveeActive = question(QuestionType.CE, QuestionStatus.ARCHIVED);
        coImageAvecAudio = question(QuestionType.CO_IMAGE, QuestionStatus.ACTIVE);
        coImageAvecAudio.setMedia(testData.media(MediaType.IMAGE));
        coImageAvecAudio.setAudioMedia(testData.media(MediaType.AUDIO));
        coImageAvecAudio = repository.saveAndFlush(coImageAvecAudio);
        coImageSansAudio = question(QuestionType.CO_IMAGE, QuestionStatus.ACTIVE);
        coImageSansAudio.setMedia(testData.media(MediaType.IMAGE));
        coImageSansAudio = repository.saveAndFlush(coImageSansAudio);
        coClassique = question(QuestionType.CO, QuestionStatus.ACTIVE);
        coClassique.setMedia(testData.media(MediaType.AUDIO));
        coClassique = repository.saveAndFlush(coClassique);
    }

    private Set<UUID> exclues() {
        return Set.of(ceDraftActive.getId(), ceArchiveeActive.getId(), coImageSansAudio.getId());
    }

    @Test
    void tirages_aleatoires_et_ordonnes_du_theme() {
        assertThat(ids(manager.findRandom(Module.TCF, theme.getId(), null, null, TOUT)))
                .containsExactlyInAnyOrder(ceServie.getId(), coImageAvecAudio.getId(), coClassique.getId());
        assertThat(ids(manager.findRandomExcluding(Module.TCF, theme.getId(), null, QuestionType.CO,
                Set.of(UUID.randomUUID()), TOUT)))
                .as("CO inclut CO_IMAGE, mais seulement avec sa bande")
                .containsExactlyInAnyOrder(coImageAvecAudio.getId(), coClassique.getId());
        assertThat(ids(manager.findOrderedExcluding(Module.TCF, theme.getId(), null, QuestionType.CE,
                Set.of(), TOUT)))
                .containsExactly(ceServie.getId());
        assertThat(ids(manager.findOrderedExcluding(Module.TCF, theme.getId(), null, QuestionType.CE,
                Set.of(UUID.randomUUID()), TOUT)))
                .containsExactly(ceServie.getId());
    }

    @Test
    void tirages_sans_theme_lus_en_entier() {
        assertThat(ids(manager.findDemoPool(Module.TCF, TOUT)))
                .contains(ceServie.getId(), coImageAvecAudio.getId())
                .doesNotContainAnyElementsOf(exclues());
        assertThat(ids(manager.findLotQuestions(Module.TCF, QuestionType.CE, Difficulty.A2, 1, TOUT)))
                .contains(ceServie.getId())
                .doesNotContainAnyElementsOf(exclues());

        User candidat = testData.user();
        assertThat(ids(manager.findLeastRecentlySeen(candidat.getId(), Module.TCF, Difficulty.A2,
                QuestionType.CE, TOUT)))
                .contains(ceServie.getId())
                .doesNotContainAnyElementsOf(exclues());
        assertThat(ids(manager.findLeastRecentlySeen(candidat.getId(), Module.TCF, Difficulty.A2,
                QuestionType.CO, TOUT)))
                .contains(coImageAvecAudio.getId(), coClassique.getId())
                .doesNotContain(coImageSansAudio.getId());
        assertThat(ids(manager.findLeastRecentlySeenInBand(candidat.getId(), Module.TCF, Difficulty.A2,
                QuestionType.CO, DifficultyBand.HARD, TOUT)))
                .contains(coImageAvecAudio.getId())
                .doesNotContain(coImageSansAudio.getId());
    }

    @Test
    void les_stocks_comptent_ce_que_les_tirages_servent() {
        assertThat(manager.countActiveMatching(Module.TCF, theme.getId(), null, null))
                .isEqualTo(manager.findRandom(Module.TCF, theme.getId(), null, null, TOUT).size())
                .isEqualTo(3);
        assertThat(manager.countActiveMatching(Module.TCF, theme.getId(), null, QuestionType.CO)).isEqualTo(2);
        assertThat(manager.countActiveByTheme(theme.getId())).isEqualTo(3);
    }

    @Test
    void les_stocks_agreges_ignorent_les_exclues() {
        long bandeAvant = manager.countInBand(Module.TCF, Difficulty.A2, QuestionType.CO, DifficultyBand.HARD);
        Map<QuestionType, Map<Difficulty, Long>> avant =
                manager.countActiveByTypeAndDifficulty(List.of(QuestionType.CE, QuestionType.CO, QuestionType.CO_IMAGE));

        question(QuestionType.CE, QuestionStatus.DRAFT);
        question(QuestionType.CO_IMAGE, QuestionStatus.ACTIVE);
        Question coImageServie = question(QuestionType.CO_IMAGE, QuestionStatus.ACTIVE);
        coImageServie.setAudioMedia(testData.media(MediaType.AUDIO));
        repository.saveAndFlush(coImageServie);

        Map<QuestionType, Map<Difficulty, Long>> apres =
                manager.countActiveByTypeAndDifficulty(List.of(QuestionType.CE, QuestionType.CO, QuestionType.CO_IMAGE));
        assertThat(apres.get(QuestionType.CE).get(Difficulty.A2)).isEqualTo(avant.get(QuestionType.CE).get(Difficulty.A2));
        assertThat(apres.get(QuestionType.CO).get(Difficulty.A2)).isEqualTo(avant.get(QuestionType.CO).get(Difficulty.A2) + 1);
        assertThat(manager.countInBand(Module.TCF, Difficulty.A2, QuestionType.CO, DifficultyBand.HARD))
                .isEqualTo(bandeAvant + 1);
    }

    private Question question(QuestionType type, QuestionStatus status) {
        Question q = testData.questionTcf(type, Difficulty.A2);
        q.setTheme(theme);
        q.setStatus(status);
        q.setActive(true);
        q.setDifficultyBand(DifficultyBand.HARD);
        return repository.saveAndFlush(q);
    }

    private static List<UUID> ids(List<Question> questions) {
        return questions.stream().map(Question::getId).toList();
    }
}
