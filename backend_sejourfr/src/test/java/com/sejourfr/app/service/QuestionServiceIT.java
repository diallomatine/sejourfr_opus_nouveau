package com.sejourfr.app.service;

import com.sejourfr.app.dto.ChoiceWriteRequest;
import com.sejourfr.app.dto.QuestionDto;
import com.sejourfr.app.dto.QuestionWriteRequest;
import com.sejourfr.app.entity.Question;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.MediaType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionMediaFilter;
import com.sejourfr.app.enums.QuestionStatus;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class QuestionServiceIT extends AbstractIntegrationTest {

    @Autowired
    private QuestionService questionService;

    @Autowired
    private TestData testData;

    @Autowired
    private com.sejourfr.app.manager.QuestionManager questionManager;

    private QuestionWriteRequest req(UUID themeId, List<ChoiceWriteRequest> choices) {
        return new QuestionWriteRequest(
                Module.CIVIQUE, themeId, null, null,
                Difficulty.CSP, QuestionType.CONNAISSANCE,
                "Quel est le drapeau ?", "Explication.", true, choices);
    }

    private List<ChoiceWriteRequest> validChoices() {
        return List.of(
                new ChoiceWriteRequest("Bleu blanc rouge", true, 0),
                new ChoiceWriteRequest("Vert", false, 1));
    }

    @Test
    void createThenGetById() {
        Theme theme = testData.theme();
        QuestionDto created = questionService.create(req(theme.getId(), validChoices()));

        assertThat(created.id()).isNotNull();
        assertThat(created.themeId()).isEqualTo(theme.getId());
        assertThat(created.choices()).hasSize(2);
        assertThat(created.active()).isTrue();

        QuestionDto fetched = questionService.getById(created.id());
        assertThat(fetched.statement()).isEqualTo("Quel est le drapeau ?");
        assertThat(fetched.difficulty()).isEqualTo(Difficulty.CSP);
    }

    @Test
    void createWithoutCorrectChoiceIsRejected() {
        Theme theme = testData.theme();
        List<ChoiceWriteRequest> noCorrect = List.of(
                new ChoiceWriteRequest("A", false, 0),
                new ChoiceWriteRequest("B", false, 1));
        assertThatThrownBy(() -> questionService.create(req(theme.getId(), noCorrect)))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("au moins un choix correct");
    }

    @Test
    void createWithAbsentThemeThrowsNotFound() {
        assertThatThrownBy(() -> questionService.create(req(UUID.randomUUID(), validChoices())))
                .isInstanceOf(NotFoundException.class);
    }

    @Test
    void updateChangesFieldsAndReplacesChoices() {
        Theme theme = testData.theme();
        QuestionDto created = questionService.create(req(theme.getId(), validChoices()));

        QuestionWriteRequest update = new QuestionWriteRequest(
                Module.CIVIQUE, theme.getId(), null, null,
                Difficulty.NAT, QuestionType.MISE_SITUATION,
                "Énoncé modifié", "Maj.", true,
                List.of(
                        new ChoiceWriteRequest("X", true, 0),
                        new ChoiceWriteRequest("Y", false, 1),
                        new ChoiceWriteRequest("Z", false, 2)));

        QuestionDto updated = questionService.update(created.id(), update);
        assertThat(updated.statement()).isEqualTo("Énoncé modifié");
        assertThat(updated.difficulty()).isEqualTo(Difficulty.NAT);
        assertThat(updated.questionType()).isEqualTo(QuestionType.MISE_SITUATION);
        assertThat(updated.choices()).hasSize(3);
    }

    @Test
    void setActiveTogglesFlag() {
        Theme theme = testData.theme();
        QuestionDto created = questionService.create(req(theme.getId(), validChoices()));

        QuestionDto deactivated = questionService.setActive(created.id(), false);
        assertThat(deactivated.active()).isFalse();
        assertThat(questionService.getById(created.id()).active()).isFalse();
    }

    /**
     * {@code updatedAt} était posé par @PreUpdate au flush, donc APRÈS le
     * mapping : la réponse (et la colonne « modifiée le » de la console)
     * gardait l'ancienne date après un changement de statut.
     */
    @Test
    void setActiveTouchesUpdatedAt() {
        Theme theme = testData.theme();
        QuestionDto created = questionService.create(req(theme.getId(), validChoices()));

        QuestionDto updated = questionService.setActive(created.id(), false);

        assertThat(updated.updatedAt()).isAfter(created.updatedAt());
        assertThat(questionService.getById(created.id()).updatedAt())
                .isEqualTo(updated.updatedAt());
    }

    @Test
    void deleteRemovesQuestion() {
        Theme theme = testData.theme();
        QuestionDto created = questionService.create(req(theme.getId(), validChoices()));
        questionService.delete(created.id());

        assertThatThrownBy(() -> questionService.getById(created.id()))
                .isInstanceOf(NotFoundException.class);
    }

    @Test
    void deleteAbsentThrowsNotFound() {
        assertThatThrownBy(() -> questionService.delete(UUID.randomUUID()))
                .isInstanceOf(NotFoundException.class);
    }

    @Test
    void searchFiltersByTheme() {
        Theme themeA = testData.theme(Module.CIVIQUE, "ta", "Theme A");
        Theme themeB = testData.theme(Module.CIVIQUE, "tb", "Theme B");
        questionService.create(req(themeA.getId(), validChoices()));
        questionService.create(req(themeA.getId(), validChoices()));
        questionService.create(req(themeB.getId(), validChoices()));

        Page<QuestionDto> page = questionService.search(
                null, themeA.getId(), null, null, null, null, null, PageRequest.of(0, 50));

        assertThat(page.getContent()).isNotEmpty();
        assertThat(page.getContent()).allMatch(q -> q.themeId().equals(themeA.getId()));
        assertThat(page.getTotalElements()).isEqualTo(2);
    }

    /**
     * Le filtre « Média » de la console ne portait que sur la page affichée
     * (filtrage navigateur) : « aucune question » alors que 134 existaient.
     * Il est désormais dans la requête, donc paginé correctement.
     */
    @Test
    void searchFiltersByMedia() {
        Theme theme = testData.theme(Module.CIVIQUE, "media-th", "Thème média");
        UUID audioId = testData.media(MediaType.AUDIO).getId();
        UUID imageId = testData.media(MediaType.IMAGE).getId();
        QuestionDto withAudio = questionService.create(reqWithMedia(theme.getId(), audioId));
        QuestionDto withImage = questionService.create(reqWithMedia(theme.getId(), imageId));
        QuestionDto without = questionService.create(req(theme.getId(), validChoices()));

        assertThat(searchInTheme(theme.getId(), QuestionMediaFilter.AUDIO))
                .containsExactly(withAudio.id());
        assertThat(searchInTheme(theme.getId(), QuestionMediaFilter.IMAGE))
                .containsExactly(withImage.id());
        assertThat(searchInTheme(theme.getId(), QuestionMediaFilter.VIDEO)).isEmpty();
        assertThat(searchInTheme(theme.getId(), QuestionMediaFilter.NONE))
                .containsExactly(without.id());
        assertThat(searchInTheme(theme.getId(), null))
                .containsExactlyInAnyOrder(withAudio.id(), withImage.id(), without.id());
    }

    private List<UUID> searchInTheme(UUID themeId, QuestionMediaFilter media) {
        return questionService.search(null, themeId, null, null, null, media, null,
                        PageRequest.of(0, 50))
                .getContent().stream().map(QuestionDto::id).toList();
    }

    private QuestionWriteRequest reqWithMedia(UUID themeId, UUID mediaId) {
        return new QuestionWriteRequest(
                Module.CIVIQUE, themeId, null, mediaId,
                Difficulty.CSP, QuestionType.CONNAISSANCE,
                "Question avec média ?", "Explication.", true, validChoices());
    }
    // ------------------------------------------------------------------------
    // Activation : is_active et status bougent ENSEMBLE (les tirages exigent
    // les deux, QuestionRepository.SERVABLE_JPQL).
    // ------------------------------------------------------------------------

    @Test
    void activerUneQuestionDraftLaPublie() {
        UUID id = questionService.create(req(testData.theme().getId(), validChoices())).id();
        poserStatut(id, false, QuestionStatus.DRAFT);

        QuestionDto dto = questionService.setActive(id, true);

        assertThat(dto.active()).isTrue();
        assertThat(statut(id)).isEqualTo(QuestionStatus.ACTIVE);
    }

    @Test
    void desactiverUneQuestionActiveLArchiveJamaisDraft() {
        UUID id = questionService.create(req(testData.theme().getId(), validChoices())).id();

        questionService.setActive(id, false);

        assertThat(statut(id)).isEqualTo(QuestionStatus.ARCHIVED);
        questionService.setActive(id, true);
        assertThat(statut(id)).as("une archivee se reactive").isEqualTo(QuestionStatus.ACTIVE);
    }

    @Test
    void uneQuestionArchiveeResteVisibleAvecLesFiltresParDefautEtSeReactive() {
        Theme theme = testData.theme(Module.TCF, "archive", "Thème archive");
        Question q = testData.questionTcf(QuestionType.CO_IMAGE, Difficulty.A2);
        q.setTheme(theme);
        UUID id = questionManager.save(q).getId();
        questionService.setActive(id, false);
        assertThat(statut(id)).isEqualTo(QuestionStatus.ARCHIVED);

        // Requete par defaut de /questions/tcf : module seul, aucun filtre d'activite
        // ni de statut, premiere page triee par date de creation (comme le controleur).
        assertThat(questionService.search(Module.TCF, null, null, null, null, null, null,
                PageRequest.of(0, 20, Sort.by(Sort.Direction.DESC, "createdAt")))
                .map(QuestionDto::id).getContent()).contains(id);
        assertThat(rechercheActivite(theme.getId(), false)).containsExactly(id);
        assertThat(rechercheActivite(theme.getId(), true)).isEmpty();

        QuestionDto reactivee = questionService.setActive(id, true);

        assertThat(reactivee.active()).isTrue();
        assertThat(statut(id)).isEqualTo(QuestionStatus.ACTIVE);
        assertThat(rechercheActivite(theme.getId(), true)).containsExactly(id);
    }

    private List<UUID> rechercheActivite(UUID themeId, boolean active) {
        return questionService.search(null, themeId, null, null, active, null, null,
                PageRequest.of(0, 50)).map(QuestionDto::id).getContent();
    }

    @Test
    void desactiverUneQuestionDraftLaLaisseDraft() {
        UUID id = questionService.create(req(testData.theme().getId(), validChoices())).id();
        poserStatut(id, true, QuestionStatus.DRAFT);

        questionService.setActive(id, false);

        assertThat(statut(id)).isEqualTo(QuestionStatus.DRAFT);
    }

    @Test
    void lEditionCompleteSynchroniseAussiLeStatut() {
        Theme theme = testData.theme();
        UUID id = questionService.create(req(theme.getId(), validChoices())).id();
        poserStatut(id, false, QuestionStatus.DRAFT);

        questionService.update(id, req(theme.getId(), validChoices()));

        assertThat(statut(id)).isEqualTo(QuestionStatus.ACTIVE);
    }

    @Test
    void searchFiltreImageFichierImageSvgEtAudioManquantAvecIndicateur() {
        Theme theme = testData.theme(Module.TCF, "co-img", "Thème CO image");
        Question fichier = coImage(theme, testData.media(MediaType.IMAGE), testData.media(MediaType.AUDIO));
        com.sejourfr.app.entity.Media svg = testData.media(MediaType.IMAGE);
        svg.setUrl(null);
        svg.setInlineSvg("<svg/>");
        Question sansAudio = coImage(theme, svg, null);

        assertThat(searchInTheme(theme.getId(), QuestionMediaFilter.IMAGE_FILE)).containsExactly(fichier.getId());
        assertThat(searchInTheme(theme.getId(), QuestionMediaFilter.IMAGE_SVG)).containsExactly(sansAudio.getId());
        assertThat(searchInTheme(theme.getId(), QuestionMediaFilter.AUDIO_MISSING)).containsExactly(sansAudio.getId());
        assertThat(questionService.getById(sansAudio.getId()).audioMissing()).isTrue();
        assertThat(questionService.getById(fichier.getId()).audioMissing()).isFalse();
    }

    private Question coImage(Theme theme, com.sejourfr.app.entity.Media image, com.sejourfr.app.entity.Media audio) {
        Question q = testData.questionTcf(QuestionType.CO_IMAGE, Difficulty.A2);
        q.setTheme(theme);
        q.setMedia(image);
        q.setAudioMedia(audio);
        return questionManager.save(q);
    }

    private void poserStatut(UUID id, boolean active, QuestionStatus status) {
        Question q = questionManager.findById(id).orElseThrow();
        q.setActive(active);
        q.setStatus(status);
        questionManager.save(q);
    }

    private QuestionStatus statut(UUID id) {
        return questionManager.findById(id).orElseThrow().getStatus();
    }
}
