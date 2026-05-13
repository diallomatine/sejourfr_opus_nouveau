package com.sejourfr.app.specification;

import com.sejourfr.app.entity.Question;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionType;
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

    public static Specification<Question> statementContains(String search) {
        return (root, q, cb) -> {
            if (search == null || search.isBlank()) return null;
            return cb.like(cb.lower(root.get("statement")), "%" + search.toLowerCase() + "%");
        };
    }
}
