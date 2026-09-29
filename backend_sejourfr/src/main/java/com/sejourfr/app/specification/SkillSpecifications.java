package com.sejourfr.app.specification;

import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillTaskCode;
import jakarta.persistence.criteria.Predicate;
import org.springframework.data.jpa.domain.Specification;

/**
 * Filtres de la liste admin des competences. Tous facultatifs et cumulables :
 * un critere absent rend {@code null}, ce que {@code Specification.and(...)}
 * ignore — d'ou l'absence de branche « sinon » chez l'appelant.
 *
 * <p>Le filtrage est fait en SQL et non en memoire sur la page courante : avec
 * 48 competences seedees, filtrer apres pagination afficherait « aucun
 * resultat » sur une page qui n'en contient simplement pas.
 */
public final class SkillSpecifications {

    private SkillSpecifications() {}

    public static Specification<Skill> hasSection(SkillSection section) {
        return (root, q, cb) -> section == null ? null : cb.equal(root.get("section"), section);
    }

    public static Specification<Skill> hasTaskCode(SkillTaskCode taskCode) {
        return (root, q, cb) -> taskCode == null ? null : cb.equal(root.get("taskCode"), taskCode);
    }

    public static Specification<Skill> hasActive(Boolean active) {
        return (root, q, cb) -> active == null ? null : cb.equal(root.get("active"), active);
    }

    /**
     * Recherche libre, insensible a la casse, sur le code editorial, le titre et
     * la description. La description est incluse parce que c'est souvent la
     * seule ou figure le mot que l'editeur cherche (« destinataire »,
     * « connecteur ») : le titre, lui, est court et normalise.
     */
    public static Specification<Skill> search(String q) {
        return (root, query, cb) -> {
            if (q == null || q.isBlank()) return null;
            String like = "%" + q.trim().toLowerCase() + "%";
            Predicate onCode = cb.like(cb.lower(root.get("code")), like);
            Predicate onTitle = cb.like(cb.lower(root.get("title")), like);
            Predicate onDescription = cb.like(cb.lower(root.get("description")), like);
            return cb.or(onCode, onTitle, onDescription);
        };
    }
}
