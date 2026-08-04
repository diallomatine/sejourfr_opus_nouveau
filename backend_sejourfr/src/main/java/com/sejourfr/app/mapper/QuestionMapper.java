package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.ChoiceDto;
import com.sejourfr.app.dto.ChoicePublicResponse;
import com.sejourfr.app.dto.ChoiceReviewResponse;
import com.sejourfr.app.dto.MediaResponse;
import com.sejourfr.app.dto.QuestionDto;
import com.sejourfr.app.dto.QuestionPublicResponse;
import com.sejourfr.app.dto.QuestionReviewResponse;
import com.sejourfr.app.audioquestion.domain.AudioMode;
import com.sejourfr.app.entity.Choice;
import com.sejourfr.app.entity.Media;
import com.sejourfr.app.entity.Passage;
import com.sejourfr.app.entity.Question;
import com.sejourfr.app.enums.MediaType;
import com.sejourfr.app.enums.QuestionType;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import java.util.Random;
import java.util.UUID;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

@Component
public class QuestionMapper {

    private static final int PASSAGE_PREVIEW_LENGTH = 140;

    /** Label « lettre seule » d'une CO dont l'audio lit les propositions : « A » ou « Réponse A » (A-D). */
    private static final Pattern LETTER_PLACEHOLDER =
            Pattern.compile("(?i)^(r[ée]ponse\\s+)?[a-d]$");

    // ------------------------------------------------------------------------
    // Vue admin (full info : correct, active, etc.)
    // ------------------------------------------------------------------------

    public ChoiceDto toDto(Choice c) {
        return new ChoiceDto(c.getId(), c.getLabel(), c.isCorrect(), c.getDisplayOrder());
    }

    public QuestionDto toDto(Question q) {
        List<ChoiceDto> choices = q.getChoices().stream()
                .map(this::toDto)
                .toList();

        Passage passage = q.getPassage();

        return new QuestionDto(
                q.getId(),
                q.getModule(),
                q.getTheme() != null ? q.getTheme().getId() : null,
                q.getTheme() != null ? q.getTheme().getName() : null,
                passage != null ? passage.getId() : null,
                passage != null ? passage.getType() : null,
                passage != null ? truncate(passage.getContent()) : null,
                q.getMedia() != null ? q.getMedia().getId() : null,
                q.getMedia() != null ? q.getMedia().getUrl() : null,
                q.getMedia() != null ? q.getMedia().getType() : null,
                q.getMedia() != null ? q.getMedia().getInlineSvg() : null,
                q.getAudioMedia() != null ? q.getAudioMedia().getId() : null,
                q.getAudioMedia() != null ? q.getAudioMedia().getUrl() : null,
                q.getDifficulty(),
                q.getQuestionType(),
                q.getStatement(),
                q.getExplanation(),
                q.isActive(),
                q.getCreatedAt(),
                q.getUpdatedAt(),
                choices
        );
    }

    private String truncate(String s) {
        if (s == null) return null;
        String oneLine = s.replaceAll("\\s+", " ").trim();
        if (oneLine.length() <= PASSAGE_PREVIEW_LENGTH) return oneLine;
        return oneLine.substring(0, PASSAGE_PREVIEW_LENGTH).trim() + "…";
    }

    // ------------------------------------------------------------------------
    // Vue publique (runner / me-routes) : pas de bonne reponse exposee tant
    // que l'attempt n'est pas finalise ; choix shuffles deterministe.
    // ------------------------------------------------------------------------

    /**
     * @param revealCorrect si true, expose Choice.correct + Question.explanation.
     *                      Sinon (cas runner avant finalisation), ces champs valent null.
     * @param shuffleSeedId UUID utilise comme seed du shuffle. Cas usuels :
     *                      AttemptQuestion.id (ordre stable intra-session)
     *                      ou Question.id (ordre stable pour la revue / favoris).
     */
    public QuestionPublicResponse toPublic(Question q, boolean revealCorrect, UUID shuffleSeedId) {
        List<Choice> ordered = q.getChoices().stream()
                .sorted(Comparator.comparingInt(Choice::getDisplayOrder))
                .collect(Collectors.toCollection(ArrayList::new));
        // On ne shuffle PAS les questions dont les propositions sont LUES dans
        // l'audio (CO_IMAGE et CO FULL_AUDIO) : l'audio énonce les réponses dans
        // l'ordre displayOrder (« A… B… C… D… ») et fige la correspondance lettre↔
        // réponse — mélanger désynchroniserait la lettre affichée de celle dite.
        // En revanche les CO WRITTEN_QUESTION affichent le TEXTE des propositions à
        // l'écran : elles DOIVENT être mélangées, sinon la bonne réponse reste collée
        // à sa position d'origine (biais « la bonne réponse est toujours A »). Le
        // shuffle est stable (seed = AttemptQuestion.id) pour limiter la mémorisation.
        if (!choicesAreReadAloud(q)) {
            Collections.shuffle(ordered, new Random(uuidSeed(shuffleSeedId)));
        }

        List<ChoicePublicResponse> choices = new ArrayList<>(ordered.size());
        for (int i = 0; i < ordered.size(); i++) {
            Choice c = ordered.get(i);
            choices.add(new ChoicePublicResponse(
                    c.getId(),
                    c.getLabel(),
                    i,
                    revealCorrect ? c.isCorrect() : null
            ));
        }

        return new QuestionPublicResponse(
                q.getId(),
                q.getModule(),
                q.getTheme().getId(),
                q.getTheme().getName(),
                q.getDifficulty(),
                q.getQuestionType(),
                q.getStatement(),
                revealCorrect ? q.getExplanation() : null,
                q.getPassage() != null ? q.getPassage().getContent() : null,
                toMedia(q, revealCorrect),
                toAudioMedia(q, revealCorrect),
                choices
        );
    }

    /** Vue revue (apres reponse) : tous les choix dans leur displayOrder, isCorrect expose. */
    public QuestionReviewResponse toReview(Question q, List<UUID> userSelectedChoiceIds) {
        List<ChoiceReviewResponse> choices = q.getChoices().stream()
                .sorted(Comparator.comparingInt(Choice::getDisplayOrder))
                .map(c -> new ChoiceReviewResponse(c.getId(), c.getLabel(), c.getDisplayOrder(), c.isCorrect()))
                .toList();

        return new QuestionReviewResponse(
                q.getId(),
                q.getModule(),
                q.getTheme().getId(),
                q.getTheme().getName(),
                q.getDifficulty(),
                q.getQuestionType(),
                q.getStatement(),
                q.getPassage() != null ? q.getPassage().getContent() : null,
                q.getExplanation(),
                // Vue revue = correction déjà rendue : le transcript est ici
                // une aide pédagogique, pas une fuite.
                toMedia(q, true),
                toAudioMedia(q, true),
                choices,
                userSelectedChoiceIds != null ? userSelectedChoiceIds : List.of()
        );
    }

    private MediaResponse toMedia(Question q, boolean revealTranscript) {
        return toMediaResponse(q.getMedia(), revealTranscript);
    }

    /** Second média audio des questions CO_IMAGE. NULL pour les autres types. */
    private MediaResponse toAudioMedia(Question q, boolean revealTranscript) {
        return toMediaResponse(q.getAudioMedia(), revealTranscript);
    }

    /**
     * @param revealTranscript le transcript porte le script COMPLET du document
     *                         sonore <em>et</em> les propositions lues. L'exposer
     *                         pendant l'épreuve donne la réponse — et sur une
     *                         CO_IMAGE, dont l'écran n'affiche que « A/B/C/D »,
     *                         il remplace purement l'exercice. On ne le sert donc
     *                         qu'une fois la correction révélée (revue,
     *                         post-finalisation), jamais dans le runner.
     */
    private MediaResponse toMediaResponse(Media media, boolean revealTranscript) {
        if (media == null) return null;
        return new MediaResponse(
                media.getId(),
                media.getType(),
                media.getUrl(),
                media.getDurationSeconds(),
                revealTranscript ? media.getTranscript() : null,
                media.getInlineSvg()
        );
    }

    /**
     * Vrai quand les propositions sont LUES dans l'audio (l'écran n'affiche que
     * des lettres) : l'ordre affiché doit alors suivre l'audio, on ne shuffle pas.
     * Cas : CO_IMAGE, et CO en mode FULL_AUDIO.
     *
     * <p>{@code audio_mode} n'est pas fiable en base (NULL sur les seeds CO et sur
     * les questions publiées depuis un draft). On retombe donc sur la forme des
     * labels — mais uniquement pour les questions audio (présence d'un média
     * AUDIO) : quand les propositions sont lues, l'écran ne montre que des lettres
     * (« A »…« D » côté seeds, « Réponse A »…« Réponse D » côté génération). Si les
     * labels portent du vrai texte (WRITTEN_QUESTION), les propositions sont
     * affichées → on shuffle.
     */
    private static boolean choicesAreReadAloud(Question q) {
        if (q.getQuestionType() == QuestionType.CO_IMAGE) return true;
        if (q.getAudioMode() == AudioMode.FULL_AUDIO) return true;
        if (q.getAudioMode() == AudioMode.WRITTEN_QUESTION) return false;
        if (!hasAudioMedium(q)) return false;
        return allChoicesAreLetterPlaceholders(q);
    }

    private static boolean hasAudioMedium(Question q) {
        if (q.getAudioMedia() != null) return true;
        return q.getMedia() != null && q.getMedia().getType() == MediaType.AUDIO;
    }

    private static boolean allChoicesAreLetterPlaceholders(Question q) {
        List<Choice> choices = q.getChoices();
        if (choices == null || choices.isEmpty()) return false;
        for (Choice c : choices) {
            String label = c.getLabel() == null ? "" : c.getLabel().trim();
            if (!LETTER_PLACEHOLDER.matcher(label).matches()) return false;
        }
        return true;
    }

    private static long uuidSeed(UUID id) {
        return id.getMostSignificantBits() ^ id.getLeastSignificantBits();
    }
}
