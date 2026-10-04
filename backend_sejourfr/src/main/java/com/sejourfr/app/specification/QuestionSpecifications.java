package com.sejourfr.app.specification;

import com.sejourfr.app.entity.Question;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.MediaType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionMediaFilter;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.entity.Media;
import jakarta.persistence.criteria.Join;
import jakarta.persistence.criteria.JoinType;
import org.springframework.data.jpa.domain.Specification;
import java.util.UUID;

public final class QuestionSpecifications {

    private QuestionSpecifications() {}

    public static Specification<Question> hasModule(Module module) {
        return (root, q, cb) -> module == null ? null : cb.equal(root.get("module"), module);
    }

    public static Specification<Question> hasTheme(UUID themeId) {
        return (root, q, cb) -> themeId == null ? null : cb.equal(root.get("theme").get("id"), themeId);
    }

    public static Specification<Question> hasDifficulty(Difficulty difficulty) {
        return (root, q, cb) -> difficulty == null ? null : cb.equal(root.get("difficulty"), difficulty);
    }

    public static Specification<Question> hasType(QuestionType type) {
        return (root, q, cb) -> type == null ? null : cb.equal(root.get("questionType"), type);
    }

    public static Specification<Question> hasActive(Boolean active) {
        return (root, q, cb) -> active == null ? null : cb.equal(root.get("active"), active);
    }

    /**
     * Filtre « Média » de la console admin. {@code NONE} = questions sans média
     * principal ; {@code AUDIO}/{@code IMAGE}/{@code VIDEO} comparent le type du
     * média principal ; {@code IMAGE_FILE} / {@code IMAGE_SVG} distinguent une
     * image fichier d'une image SVG inline ; {@code AUDIO_MISSING} reprend
     * {@link #audioManquant()}. Porte sur {@code question.media} (celui affiché
     * en colonne « Média »), pas sur {@code audioMedia} — sauf
     * {@code AUDIO_MISSING}, dont c'est l'objet.
     *
     * <p>Sans cette specification, la console filtrait en mémoire sur la page
     * courante : « aucune question » alors que 134 existaient.
     */
    public static Specification<Question> hasMedia(QuestionMediaFilter media) {
        return (root, q, cb) -> {
            if (media == null) return null;
            return switch (media) {
                case NONE -> cb.isNull(root.get("media"));
                case AUDIO_MISSING -> audioManquant().toPredicate(root, q, cb);
                case IMAGE_FILE -> {
                    Join<Question, Media> m = root.join("media", JoinType.INNER);
                    yield cb.and(cb.equal(m.get("type"), MediaType.IMAGE), cb.isNotNull(m.get("url")));
                }
                case IMAGE_SVG -> {
                    Join<Question, Media> m = root.join("media", JoinType.INNER);
                    yield cb.and(cb.equal(m.get("type"), MediaType.IMAGE),
                            cb.isNotNull(m.get("inlineSvg")), cb.isNull(m.get("url")));
                }
                case AUDIO, IMAGE, VIDEO ->
                        cb.equal(root.join("media", JoinType.LEFT).get("type"), media.toMediaType());
            };
        };
    }

    /**
     * Forme criteria de {@code util/AudioManquant} : CO_IMAGE sans
     * {@code audio_media_id}, ou CO sans média principal AUDIO.
     */
    public static Specification<Question> audioManquant() {
        return (root, q, cb) -> {
            Join<Question, Media> m = root.join("media", JoinType.LEFT);
            return cb.or(
                    cb.and(cb.equal(root.get("questionType"), QuestionType.CO_IMAGE),
                            cb.isNull(root.get("audioMedia"))),
                    cb.and(cb.equal(root.get("questionType"), QuestionType.CO),
                            cb.or(cb.isNull(m.get("id")), cb.notEqual(m.get("type"), MediaType.AUDIO))));
        };
    }

    public static Specification<Question> statementContains(String search) {
        return (root, q, cb) -> {
            if (search == null || search.isBlank()) return null;
            return cb.like(cb.lower(root.get("statement")), "%" + search.toLowerCase() + "%");
        };
    }
}
