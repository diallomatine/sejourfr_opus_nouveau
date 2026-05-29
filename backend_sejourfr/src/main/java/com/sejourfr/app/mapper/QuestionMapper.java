package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.ChoiceDto;
import com.sejourfr.app.dto.ChoicePublicResponse;
import com.sejourfr.app.dto.ChoiceReviewResponse;
import com.sejourfr.app.dto.MediaResponse;
import com.sejourfr.app.dto.QuestionDto;
import com.sejourfr.app.dto.QuestionPublicResponse;
import com.sejourfr.app.dto.QuestionReviewResponse;
import com.sejourfr.app.entity.Choice;
import com.sejourfr.app.entity.Passage;
import com.sejourfr.app.entity.Question;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import java.util.Random;
import java.util.UUID;
import java.util.stream.Collectors;

@Component
public class QuestionMapper {

    private static final int PASSAGE_PREVIEW_LENGTH = 140;

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
        // Questions audio (TCF CO) : l'audio énonce les réponses dans l'ordre
        // displayOrder (A→B→C→D) et fige la correspondance lettre↔réponse. On
        // ne les shuffle PAS, sinon la lettre affichée ne correspond plus à
        // celle dite dans l'audio. Les autres questions sont mélangées de façon
        // stable (seed = AttemptQuestion.id) pour limiter la mémorisation.
        if (q.getAudioMode() == null) {
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
                toMedia(q),
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
                toMedia(q),
                choices,
                userSelectedChoiceIds != null ? userSelectedChoiceIds : List.of()
        );
    }

    private MediaResponse toMedia(Question q) {
        if (q.getMedia() == null) return null;
        return new MediaResponse(
                q.getMedia().getId(),
                q.getMedia().getType(),
                q.getMedia().getUrl(),
                q.getMedia().getDurationSeconds(),
                q.getMedia().getTranscript(),
                q.getMedia().getInlineSvg()
        );
    }

    private static long uuidSeed(UUID id) {
        return id.getMostSignificantBits() ^ id.getLeastSignificantBits();
    }
}
