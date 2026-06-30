package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.ChoiceDto;
import com.sejourfr.app.dto.ChoicePublicResponse;
import com.sejourfr.app.dto.QuestionDto;
import com.sejourfr.app.dto.QuestionPublicResponse;
import com.sejourfr.app.dto.QuestionReviewResponse;
import com.sejourfr.app.entity.Choice;
import com.sejourfr.app.entity.Media;
import com.sejourfr.app.entity.Passage;
import com.sejourfr.app.entity.Question;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.MediaType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.PassageType;
import com.sejourfr.app.enums.QuestionType;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class QuestionMapperTest {

    private final QuestionMapper mapper = new QuestionMapper();

    private Theme theme(UUID id) {
        Theme t = new Theme();
        t.setId(id);
        t.setName("Symboles");
        t.setModule(Module.CIVIQUE);
        t.setCode("SYM");
        return t;
    }

    private Choice choice(String label, boolean correct, int displayOrder) {
        Choice c = new Choice();
        c.setId(UUID.randomUUID());
        c.setLabel(label);
        c.setCorrect(correct);
        c.setDisplayOrder(displayOrder);
        return c;
    }

    private Question baseQuestion(QuestionType type) {
        Question q = new Question();
        q.setId(UUID.randomUUID());
        q.setModule(Module.CIVIQUE);
        q.setTheme(theme(UUID.randomUUID()));
        q.setDifficulty(Difficulty.CSP);
        q.setQuestionType(type);
        q.setStatement("Quelle est la devise ?");
        q.setExplanation("Liberté, Égalité, Fraternité");
        q.setActive(true);
        return q;
    }

    @Test
    void toDto_choice_mapsAllFields() {
        Choice c = choice("Réponse A", true, 2);

        ChoiceDto dto = mapper.toDto(c);

        assertThat(dto.id()).isEqualTo(c.getId());
        assertThat(dto.label()).isEqualTo("Réponse A");
        assertThat(dto.correct()).isTrue();
        assertThat(dto.displayOrder()).isEqualTo(2);
    }

    @Test
    void toDto_question_mapsAllFieldsAndCollapsesPassagePreview() {
        Question q = baseQuestion(QuestionType.CO_IMAGE);
        Instant created = Instant.parse("2026-01-01T00:00:00Z");
        Instant updated = Instant.parse("2026-02-01T00:00:00Z");
        q.setCreatedAt(created);
        q.setUpdatedAt(updated);

        UUID passageId = UUID.randomUUID();
        Passage passage = new Passage();
        passage.setId(passageId);
        passage.setType(PassageType.TEXTE);
        passage.setContent("Première ligne\n   seconde   ligne");
        q.setPassage(passage);

        UUID mediaId = UUID.randomUUID();
        Media media = new Media();
        media.setId(mediaId);
        media.setType(MediaType.IMAGE);
        media.setUrl("https://r2.example/img.png");
        media.setInlineSvg("<svg/>");
        q.setMedia(media);

        UUID audioId = UUID.randomUUID();
        Media audio = new Media();
        audio.setId(audioId);
        audio.setType(MediaType.AUDIO);
        audio.setUrl("https://r2.example/a.mp3");
        q.setAudioMedia(audio);

        Choice c = choice("A", true, 0);
        q.setChoices(new ArrayList<>(List.of(c)));

        QuestionDto dto = mapper.toDto(q);

        assertThat(dto.id()).isEqualTo(q.getId());
        assertThat(dto.module()).isEqualTo(Module.CIVIQUE);
        assertThat(dto.themeId()).isEqualTo(q.getTheme().getId());
        assertThat(dto.themeName()).isEqualTo("Symboles");
        assertThat(dto.passageId()).isEqualTo(passageId);
        assertThat(dto.passageType()).isEqualTo(PassageType.TEXTE);
        assertThat(dto.passagePreview()).isEqualTo("Première ligne seconde ligne");
        assertThat(dto.mediaId()).isEqualTo(mediaId);
        assertThat(dto.mediaUrl()).isEqualTo("https://r2.example/img.png");
        assertThat(dto.mediaType()).isEqualTo(MediaType.IMAGE);
        assertThat(dto.mediaInlineSvg()).isEqualTo("<svg/>");
        assertThat(dto.audioMediaId()).isEqualTo(audioId);
        assertThat(dto.audioMediaUrl()).isEqualTo("https://r2.example/a.mp3");
        assertThat(dto.difficulty()).isEqualTo(Difficulty.CSP);
        assertThat(dto.questionType()).isEqualTo(QuestionType.CO_IMAGE);
        assertThat(dto.statement()).isEqualTo("Quelle est la devise ?");
        assertThat(dto.explanation()).isEqualTo("Liberté, Égalité, Fraternité");
        assertThat(dto.active()).isTrue();
        assertThat(dto.createdAt()).isEqualTo(created);
        assertThat(dto.updatedAt()).isEqualTo(updated);
        assertThat(dto.choices()).hasSize(1);
        assertThat(dto.choices().get(0).id()).isEqualTo(c.getId());
    }

    @Test
    void toDto_question_nullAssociations() {
        Question q = baseQuestion(QuestionType.CONNAISSANCE);
        q.setTheme(null);
        q.setChoices(new ArrayList<>());

        QuestionDto dto = mapper.toDto(q);

        assertThat(dto.themeId()).isNull();
        assertThat(dto.themeName()).isNull();
        assertThat(dto.passageId()).isNull();
        assertThat(dto.passageType()).isNull();
        assertThat(dto.passagePreview()).isNull();
        assertThat(dto.mediaId()).isNull();
        assertThat(dto.mediaUrl()).isNull();
        assertThat(dto.mediaType()).isNull();
        assertThat(dto.mediaInlineSvg()).isNull();
        assertThat(dto.audioMediaId()).isNull();
        assertThat(dto.audioMediaUrl()).isNull();
        assertThat(dto.choices()).isEmpty();
    }

    @Test
    void toDto_question_truncatesLongPassagePreview() {
        Question q = baseQuestion(QuestionType.CE);
        Passage passage = new Passage();
        passage.setId(UUID.randomUUID());
        passage.setType(PassageType.TEXTE);
        passage.setContent("a".repeat(200));
        q.setPassage(passage);
        q.setChoices(new ArrayList<>());

        QuestionDto dto = mapper.toDto(q);

        assertThat(dto.passagePreview()).hasSize(141); // 140 chars + ellipsis
        assertThat(dto.passagePreview()).endsWith("…");
        assertThat(dto.passagePreview()).startsWith("a".repeat(140));
    }

    @Test
    void toPublic_revealFalse_hidesCorrectAndExplanation_shuffleDeterministic() {
        Question q = baseQuestion(QuestionType.CONNAISSANCE);
        Choice a = choice("A", true, 0);
        Choice b = choice("B", false, 1);
        Choice c = choice("C", false, 2);
        Choice d = choice("D", false, 3);
        q.setChoices(new ArrayList<>(List.of(a, b, c, d)));
        UUID seed = UUID.randomUUID();

        QuestionPublicResponse r1 = mapper.toPublic(q, false, seed);
        QuestionPublicResponse r2 = mapper.toPublic(q, false, seed);

        assertThat(r1.id()).isEqualTo(q.getId());
        assertThat(r1.module()).isEqualTo(Module.CIVIQUE);
        assertThat(r1.themeId()).isEqualTo(q.getTheme().getId());
        assertThat(r1.themeName()).isEqualTo("Symboles");
        assertThat(r1.difficulty()).isEqualTo(Difficulty.CSP);
        assertThat(r1.questionType()).isEqualTo(QuestionType.CONNAISSANCE);
        assertThat(r1.statement()).isEqualTo("Quelle est la devise ?");
        assertThat(r1.explanation()).isNull();
        assertThat(r1.passageText()).isNull();
        assertThat(r1.media()).isNull();
        assertThat(r1.audioMedia()).isNull();

        assertThat(r1.choices()).hasSize(4);
        assertThat(r1.choices()).extracting(ChoicePublicResponse::correct).containsOnlyNulls();
        // displayOrder is rewritten to the rendered index 0..n-1.
        assertThat(r1.choices()).extracting(ChoicePublicResponse::displayOrder)
                .containsExactly(0, 1, 2, 3);
        assertThat(r1.choices()).extracting(ChoicePublicResponse::label)
                .containsExactlyInAnyOrder("A", "B", "C", "D");
        // Same seed -> stable order.
        assertThat(r2.choices()).extracting(ChoicePublicResponse::id)
                .containsExactlyElementsOf(r1.choices().stream().map(ChoicePublicResponse::id).toList());
    }

    @Test
    void toPublic_revealTrue_exposesCorrectAndExplanationAndMedia() {
        Question q = baseQuestion(QuestionType.CONNAISSANCE);
        Choice a = choice("A", true, 0);
        Choice b = choice("B", false, 1);
        q.setChoices(new ArrayList<>(List.of(a, b)));

        Media media = new Media();
        media.setId(UUID.randomUUID());
        media.setType(MediaType.IMAGE);
        media.setUrl("https://r2.example/i.png");
        media.setDurationSec(null);
        media.setTranscript("t");
        media.setInlineSvg("<svg/>");
        q.setMedia(media);

        QuestionPublicResponse r = mapper.toPublic(q, true, UUID.randomUUID());

        assertThat(r.explanation()).isEqualTo("Liberté, Égalité, Fraternité");
        assertThat(r.choices()).anySatisfy(ch -> {
            if (ch.label().equals("A")) {
                assertThat(ch.correct()).isTrue();
            }
        });
        assertThat(r.choices()).extracting(ChoicePublicResponse::correct).doesNotContainNull();
        assertThat(r.media()).isNotNull();
        assertThat(r.media().id()).isEqualTo(media.getId());
        assertThat(r.media().type()).isEqualTo(MediaType.IMAGE);
        assertThat(r.media().url()).isEqualTo("https://r2.example/i.png");
        assertThat(r.media().transcript()).isEqualTo("t");
        assertThat(r.media().inlineSvg()).isEqualTo("<svg/>");
    }

    @Test
    void toPublic_audioQuestion_keepsDisplayOrderWithoutShuffle() {
        Question q = baseQuestion(QuestionType.CO_IMAGE);
        // Inserted out of order; mapper sorts by displayOrder and must NOT shuffle.
        Choice third = choice("third", false, 2);
        Choice first = choice("first", true, 0);
        Choice second = choice("second", false, 1);
        q.setChoices(new ArrayList<>(List.of(third, first, second)));

        Media audio = new Media();
        audio.setId(UUID.randomUUID());
        audio.setType(MediaType.AUDIO);
        audio.setUrl("https://r2.example/a.mp3");
        q.setAudioMedia(audio);

        QuestionPublicResponse r = mapper.toPublic(q, false, UUID.randomUUID());

        assertThat(r.choices()).extracting(ChoicePublicResponse::label)
                .containsExactly("first", "second", "third");
        assertThat(r.choices()).extracting(ChoicePublicResponse::displayOrder)
                .containsExactly(0, 1, 2);
        assertThat(r.audioMedia()).isNotNull();
        assertThat(r.audioMedia().type()).isEqualTo(MediaType.AUDIO);
    }

    private Media audioMedia() {
        Media audio = new Media();
        audio.setId(UUID.randomUUID());
        audio.setType(MediaType.AUDIO);
        audio.setUrl("https://r2.example/a.mp3");
        return audio;
    }

    private Question coQuestion(String l0, String l1, String l2, String l3) {
        Question q = baseQuestion(QuestionType.CO);
        q.setModule(Module.TCF);
        q.setMedia(audioMedia()); // CO : l'audio est porté par media_id
        q.setChoices(new ArrayList<>(List.of(
                choice(l0, true, 0), // bonne réponse en position d'origine 0 (« A »)
                choice(l1, false, 1),
                choice(l2, false, 2),
                choice(l3, false, 3))));
        return q;
    }

    /** Index de l'unique choix correct dans la réponse publique, pour un seed donné. */
    private int correctIndex(Question q, UUID seed) {
        QuestionPublicResponse r = mapper.toPublic(q, true, seed);
        for (int i = 0; i < r.choices().size(); i++) {
            if (Boolean.TRUE.equals(r.choices().get(i).correct())) return i;
        }
        throw new IllegalStateException("pas de choix correct");
    }

    @Test
    void toPublic_coWrittenQuestion_shufflesSoCorrectAnswerIsNotAlwaysFirst() {
        // CO « WRITTEN_QUESTION » : propositions affichées en TEXTE, audio_mode NULL
        // (publié depuis un draft). La bonne réponse est en position 0 en base.
        // Régression visée : elle ne doit PAS rester collée à l'index 0 (« toujours A »).
        Question q = coQuestion(
                "Mon parcours associatif, je pense.",
                "Dès la fin de l'été dernier, en réalité.",
                "Devant un jury de cinq personnes.",
                "Plutôt avec une certaine émotion, à vrai dire.");

        java.util.Set<Integer> positions = new java.util.HashSet<>();
        for (long i = 1; i <= 60; i++) {
            positions.add(correctIndex(q, new UUID(i, 0L)));
        }
        // Le shuffle est actif : la bonne réponse atterrit à plusieurs positions,
        // et pas uniquement à l'index 0.
        assertThat(positions).hasSizeGreaterThan(1);
        assertThat(positions).anyMatch(p -> p != 0);
    }

    @Test
    void toPublic_coWrittenQuestion_shuffleIsStablePerSeed() {
        Question q = coQuestion("Texte un", "Texte deux", "Texte trois", "Texte quatre");
        UUID seed = new UUID(7L, 0L);

        QuestionPublicResponse r1 = mapper.toPublic(q, false, seed);
        QuestionPublicResponse r2 = mapper.toPublic(q, false, seed);

        assertThat(r2.choices()).extracting(ChoicePublicResponse::id)
                .containsExactlyElementsOf(r1.choices().stream().map(ChoicePublicResponse::id).toList());
    }

    @Test
    void toPublic_coLetterLabels_keepsDisplayOrderWithoutShuffle() {
        // CO « lue dans l'audio » façon seeds : labels lettres seules, audio_mode NULL.
        // L'ordre doit suivre l'audio (displayOrder), jamais mélangé.
        Question q = coQuestion("A", "B", "C", "D");
        for (long i = 1; i <= 20; i++) {
            QuestionPublicResponse r = mapper.toPublic(q, false, new UUID(i, 0L));
            assertThat(r.choices()).extracting(ChoicePublicResponse::label)
                    .containsExactly("A", "B", "C", "D");
        }
    }

    @Test
    void toPublic_coFullAudioMode_keepsDisplayOrderWithoutShuffle() {
        Question q = coQuestion("Réponse A", "Réponse B", "Réponse C", "Réponse D");
        q.setAudioMode(com.sejourfr.app.audioquestion.domain.AudioMode.FULL_AUDIO);

        QuestionPublicResponse r = mapper.toPublic(q, false, new UUID(3L, 0L));

        assertThat(r.choices()).extracting(ChoicePublicResponse::label)
                .containsExactly("Réponse A", "Réponse B", "Réponse C", "Réponse D");
    }

    @Test
    void toReview_sortsByDisplayOrderExposesCorrectAndSelection() {
        Question q = baseQuestion(QuestionType.CONNAISSANCE);
        Choice a = choice("A", false, 1);
        Choice b = choice("B", true, 0);
        q.setChoices(new ArrayList<>(List.of(a, b)));

        Passage passage = new Passage();
        passage.setId(UUID.randomUUID());
        passage.setType(PassageType.TEXTE);
        passage.setContent("Un texte complet de passage.");
        q.setPassage(passage);

        List<UUID> selected = List.of(a.getId());

        QuestionReviewResponse r = mapper.toReview(q, selected);

        assertThat(r.id()).isEqualTo(q.getId());
        assertThat(r.themeId()).isEqualTo(q.getTheme().getId());
        assertThat(r.themeName()).isEqualTo("Symboles");
        assertThat(r.difficulty()).isEqualTo(Difficulty.CSP);
        assertThat(r.questionType()).isEqualTo(QuestionType.CONNAISSANCE);
        assertThat(r.statement()).isEqualTo("Quelle est la devise ?");
        assertThat(r.passageText()).isEqualTo("Un texte complet de passage.");
        assertThat(r.explanation()).isEqualTo("Liberté, Égalité, Fraternité");
        // Sorted by displayOrder ascending: B (0) then A (1).
        assertThat(r.choices()).extracting("label").containsExactly("B", "A");
        assertThat(r.choices().get(0).correct()).isTrue();
        assertThat(r.choices().get(0).displayOrder()).isZero();
        assertThat(r.choices().get(1).correct()).isFalse();
        assertThat(r.userSelectedChoiceIds()).containsExactly(a.getId());
    }

    @Test
    void toReview_nullSelection_yieldEmptyList() {
        Question q = baseQuestion(QuestionType.CONNAISSANCE);
        q.setChoices(new ArrayList<>(List.of(choice("A", true, 0))));

        QuestionReviewResponse r = mapper.toReview(q, null);

        assertThat(r.userSelectedChoiceIds()).isEmpty();
        assertThat(r.passageText()).isNull();
    }
}
