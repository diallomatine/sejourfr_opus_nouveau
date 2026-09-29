package com.sejourfr.app.specification;

import com.sejourfr.app.entity.Question;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.MediaType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionMediaFilter;
import com.sejourfr.app.enums.QuestionType;
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
     * principal ; sinon on compare le type du média principal. Porte sur
     * {@code question.media} (celui affiché en colonne « Média »), pas sur
     * {@code audioMedia} — l'audio secondaire d'une CO_IMAGE reste rattaché à
     * une question dont le média principal est l'IMAGE.
     *
     * <p>Sans cette specification, la console filtrait en mémoire sur la page
     * courante : « aucune question » alors que 134 existaient.
     */
    public static Specification<Question> hasMedia(QuestionMediaFilter media) {
        return (root, q, cb) -> {
            if (media == null) return null;
            if (media == QuestionMediaFilter.NONE) return cb.isNull(root.get("media"));
            MediaType type = media.toMediaType();
            return cb.equal(root.join("media", JoinType.LEFT).get("type"), type);
        };
    }

    public static Specification<Question> statementContains(String search) {
        return (root, q, cb) -> {
            if (search == null || search.isBlank()) return null;
            return cb.like(cb.lower(root.get("statement")), "%" + search.toLowerCase() + "%");
        };
    }
}
