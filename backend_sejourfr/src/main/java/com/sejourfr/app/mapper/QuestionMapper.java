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
import com.sejourfr.app.util.ReferenceChoixLettre;
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
        List<Choice> ordered = ordreAffiche(q, shuffleSeedId);

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
                revealCorrect ? explication(q, ordered) : null,
                q.getPassage() != null ? q.getPassage().getContent() : null,
                toMedia(q, revealCorrect),
                toAudioMedia(q, revealCorrect),
                choices
        );
    }

    /**
     * Vue revue (apres reponse) : <b>meme ordre affiche que le runner hors
     * session</b> — meme melange, meme graine ({@code Question.id}) que
     * {@code toPublic(q, false, q.getId())}, qui alimente les listes favoris et
     * erreurs d'ou l'on ouvre cette vue. Sans ca les propositions se
     * reordonnaient sous les yeux du candidat entre la liste et le detail, et
     * l'explication citait des lettres d'un troisieme ordre encore.
     *
     * <p>{@code displayOrder} porte donc l'index d'affichage, comme
     * {@link ChoicePublicResponse} — jamais le {@code display_order} de la base,
     * qui permettrait de defaire le melange.
     */
    public QuestionReviewResponse toReview(Question q, List<UUID> userSelectedChoiceIds) {
        List<Choice> ordered = ordreAffiche(q, q.getId());

        List<ChoiceReviewResponse> choices = new ArrayList<>(ordered.size());
        for (int i = 0; i < ordered.size(); i++) {
            Choice c = ordered.get(i);
            choices.add(new ChoiceReviewResponse(c.getId(), c.getLabel(), i, c.isCorrect()));
        }

        return new QuestionReviewResponse(
                q.getId(),
                q.getModule(),
                q.getTheme().getId(),
                q.getTheme().getName(),
                q.getDifficulty(),
                q.getQuestionType(),
                q.getStatement(),
                q.getPassage() != null ? q.getPassage().getContent() : null,
                explication(q, ordered),
                // Vue revue = correction déjà rendue : le transcript est ici
                // une aide pédagogique, pas une fuite.
                toMedia(q, true),
                toAudioMedia(q, true),
                choices,
                userSelectedChoiceIds != null ? userSelectedChoiceIds : List.of()
        );
    }

    /**
     * Explication d'une question servie hors mapper (correction immediate en
     * TRAINING) : meme graine, donc mêmes lettres que l'écran qui l'affiche.
     */
    public String explication(Question q, UUID shuffleSeedId) {
        return explication(q, ordreAffiche(q, shuffleSeedId));
    }

    /**
     * L'ordre de REFERENCE d'une question : celui sur lequel l'explication est
     * redigee, et le point de depart de l'ordre affiche.
     *
     * <p>C'est {@code display_order} croissant, SAUF quand les propositions sont
     * des <b>reperes alphabetiques</b> (« A »…« D », « Reponse A »…) : la lettre
     * est alors le contenu meme de la proposition — celle que l'audio enonce et
     * que l'explication cite —, et c'est ELLE qui fait foi, pas la colonne.
     *
     * <p>Le serveur garantit ainsi qu'une question a reperes alphabetiques est
     * <b>toujours servie dans l'ordre de ses lettres</b>, quel que soit le
     * {@code display_order} saisi en console : la pastille A/B/C/D — que les
     * trois fronts derivent de l'INDEX dans la liste recue — tombe toujours en
     * face du libelle de la meme lettre. Sans cette garantie serveur, web et
     * mobile la reconstituaient chacun a sa facon (le web sur tout type de
     * question, le mobile sur les seules CO/CO_IMAGE), et pouvaient defaire
     * l'ordre servi.
     */
    private List<Choice> ordreReference(Question q) {
        List<Choice> ordered = q.getChoices().stream()
                .sorted(Comparator.comparingInt(Choice::getDisplayOrder))
                .collect(Collectors.toCollection(ArrayList::new));
        if (estRepereAlphabetique(q)) {
            ordered.sort(Comparator.comparing(QuestionMapper::lettreRepere)
                    .thenComparingInt(Choice::getDisplayOrder));
        }
        return ordered;
    }

    /**
     * L'ordre reellement affiche : {@link #ordreReference(Question)}, puis
     * melange deterministe sauf quand l'ordre est deja porte par le contenu
     * (propositions lues dans l'audio, ou reperes alphabetiques).
     */
    private List<Choice> ordreAffiche(Question q, UUID shuffleSeedId) {
        List<Choice> ordered = ordreReference(q);
        // On ne shuffle PAS les questions dont les propositions sont LUES dans
        // l'audio (CO_IMAGE et CO FULL_AUDIO) : l'audio énonce les réponses dans
        // l'ordre displayOrder (« A… B… C… D… ») et fige la correspondance lettre↔
        // réponse — mélanger désynchroniserait la lettre affichée de celle dite.
        // En revanche les CO WRITTEN_QUESTION affichent le TEXTE des propositions à
        // l'écran : elles DOIVENT être mélangées, sinon la bonne réponse reste collée
        // à sa position d'origine (biais « la bonne réponse est toujours A »). Le
        // shuffle est stable (seed = AttemptQuestion.id) pour limiter la mémorisation.
        // Un repere alphabetique ne se melange jamais non plus : la lettre EST la
        // proposition, la brasser ne supprimerait aucun biais de position et
        // decorrelerait la pastille du libelle.
        if (!estRepereAlphabetique(q) && !choicesAreReadAloud(q)) {
            Collections.shuffle(ordered, new Random(uuidSeed(shuffleSeedId)));
        }
        return ordered;
    }

    /**
     * L'explication est redigee sur l'ordre {@code display_order} et cite des
     * lettres (« Seule B… A indique une duree »). Des que les propositions sont
     * melangees, ces lettres designent la mauvaise ligne : on les remappe avec
     * <b>exactement</b> la permutation appliquee aux propositions.
     *
     * @see ReferenceChoixLettre
     */
    private String explication(Question q, List<Choice> ordered) {
        return ReferenceChoixLettre.remappe(q.getExplanation(), permutation(q, ordered));
    }

    /**
     * {@code permutation[r]} = index d'affichage de la proposition de rang
     * {@code r} dans l'{@link #ordreReference(Question) ordre de reference} —
     * celui sur lequel l'explication est redigee. Une question a reperes
     * alphabetiques a donc une permutation IDENTITE : son ordre de reference est
     * deja celui des lettres, qui est aussi celui qu'on sert.
     */
    private int[] permutation(Question q, List<Choice> ordered) {
        List<Choice> origine = ordreReference(q);
        int[] permutation = new int[origine.size()];
        for (int rang = 0; rang < origine.size(); rang++) {
            permutation[rang] = ordered.indexOf(origine.get(rang));
        }
        return permutation;
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
     * Vrai quand les propositions sont ÉNONCÉES dans l'audio : l'ordre affiché
     * doit alors suivre l'audio, on ne shuffle pas — sinon la lettre entendue
     * (« B ») désigne une autre ligne que la lettre affichée, et le candidat qui
     * avait compris se trompe en cliquant.
     *
     * <p>Trois cas, tous portés par la DONNÉE et non par une heuristique :
     * <ul>
     *   <li>{@code CO_IMAGE} — l'écran ne montre qu'une image et des lettres ;</li>
     *   <li>{@link AudioMode#FULL_AUDIO} — tout est lu, l'écran est réduit aux
     *       lettres ;</li>
     *   <li>{@link AudioMode#WRITTEN_QUESTION_SPOKEN_CHOICES} — l'audio énonce les
     *       propositions avec leurs lettres <em>et</em> l'écran affiche leur
     *       texte. C'est le seul cas où de vrais libellés ne doivent pourtant pas
     *       être mélangés, d'où la valeur d'{@code audio_mode} dédiée (V037/V590)
     *       plutôt qu'une devinette sur la forme des labels.</li>
     * </ul>
     *
     * <p>Repli sur la forme des labels uniquement quand {@code audio_mode} est
     * NULL (seeds CO antérieurs) : sur une question audio, des labels réduits à
     * une lettre (« A »…« D », « Réponse A »…« Réponse D ») signent un audio qui
     * porte le contenu. Des labels en vrai texte et un mode NULL valent
     * {@code WRITTEN_QUESTION} → on shuffle.
     */
    private static boolean choicesAreReadAloud(Question q) {
        if (q.getQuestionType() == QuestionType.CO_IMAGE) return true;
        if (q.getAudioMode() == AudioMode.FULL_AUDIO) return true;
        if (q.getAudioMode() == AudioMode.WRITTEN_QUESTION_SPOKEN_CHOICES) return true;
        if (q.getAudioMode() == AudioMode.WRITTEN_QUESTION) return false;
        if (!hasAudioMedium(q)) return false;
        return allChoicesAreLetterPlaceholders(q);
    }

    private static boolean hasAudioMedium(Question q) {
        if (q.getAudioMedia() != null) return true;
        return q.getMedia() != null && q.getMedia().getType() == MediaType.AUDIO;
    }

    /**
     * Vrai quand les propositions sont des <b>reperes alphabetiques</b> : leurs
     * libelles se reduisent tous a une lettre A-D, qui n'est pas une reponse
     * mais la CLE de la reponse — le contenu vit ailleurs (dans l'audio).
     *
     * <p>Restreint aux types CO et CO_IMAGE, comme le fait deja le mobile : sans
     * ce garde-fou une question STRUCTURE dont les reponses seraient des lettres
     * isolees (« a », « d »…) basculerait a tort dans ce mode et cesserait
     * d'etre melangee.
     */
    private static boolean estRepereAlphabetique(Question q) {
        QuestionType type = q.getQuestionType();
        if (type != QuestionType.CO && type != QuestionType.CO_IMAGE) return false;
        return allChoicesAreLetterPlaceholders(q);
    }

    /** La lettre-repere d'une proposition (dernier caractere, majuscule). */
    private static String lettreRepere(Choice c) {
        String label = c.getLabel() == null ? "" : c.getLabel().trim();
        if (label.isEmpty()) return "";
        return label.substring(label.length() - 1).toUpperCase();
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
