package com.sejourfr.app.specification;

import com.sejourfr.app.entity.AccessOverride;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.AccessOverrideType;
import com.sejourfr.app.enums.ModuleAccess;
import jakarta.persistence.criteria.Expression;
import jakarta.persistence.criteria.Root;
import jakarta.persistence.criteria.Subquery;
import org.springframework.data.jpa.domain.Specification;

import java.time.Instant;
import java.util.Collection;
import java.util.UUID;

/**
 * Critères de la liste admin « Utilisateurs ». 🛑 Aucun ne décide d'un accès :
 * les ensembles d'ids « accès actif » sont calculés en Java par l'autorité
 * ({@code SubscriptionService}) et passés ici tels quels.
 */
public final class UserSpecifications {

    private static final String FREE_PLAN_CODE = "FREE";

    private UserSpecifications() {}

    /**
     * Recherche par identifiant exact (UUID complet) ou « contient », insensible
     * à la casse, sur l'email, le prénom, le nom ou « prénom nom ». Les jokers
     * LIKE saisis sont échappés.
     */
    public static Specification<User> search(String q) {
        return (root, query, cb) -> {
            if (q == null || q.isBlank()) return null;
            String trimmed = q.trim();
            UUID id = parseUuid(trimmed);
            if (id != null) return cb.equal(root.get("id"), id);
            String like = LikePattern.contient(trimmed);
            Expression<String> firstName = cb.coalesce(root.get("firstName"), "");
            Expression<String> lastName = cb.coalesce(root.get("lastName"), "");
            Expression<String> fullName = cb.concat(cb.concat(firstName, " "), lastName);
            return cb.or(
                    cb.like(cb.lower(root.get("email")), like, LikePattern.ESCAPE),
                    cb.like(cb.lower(root.get("firstName")), like, LikePattern.ESCAPE),
                    cb.like(cb.lower(root.get("lastName")), like, LikePattern.ESCAPE),
                    cb.like(cb.lower(fullName), like, LikePattern.ESCAPE));
        };
    }

    /** Exclut les comptes supprimés par leur titulaire (`deleted_at` posé, données anonymisées). */
    public static Specification<User> notDeleted() {
        return (root, query, cb) -> cb.isNull(root.get("deletedAt"));
    }

    public static Specification<User> idIn(Collection<UUID> ids) {
        return (root, query, cb) -> ids.isEmpty() ? cb.disjunction() : root.get("id").in(ids);
    }

    public static Specification<User> idNotIn(Collection<UUID> ids) {
        return (root, query, cb) -> ids.isEmpty() ? null : cb.not(root.get("id").in(ids));
    }

    /** A eu au moins un achat payant (tout statut) ou un GRANT admin courant (passé, présent ou futur). */
    public static Specification<User> hasPurchaseOrGrant() {
        return (root, query, cb) -> {
            Subquery<Integer> achat = query.subquery(Integer.class);
            Root<UserSubscription> s = achat.from(UserSubscription.class);
            achat.select(cb.literal(1)).where(
                    cb.equal(s.get("user").get("id"), root.get("id")),
                    cb.notEqual(s.get("plan").get("code"), FREE_PLAN_CODE),
                    cb.notEqual(s.get("plan").get("moduleAccess"), ModuleAccess.NONE));
            Subquery<Integer> grant = query.subquery(Integer.class);
            Root<AccessOverride> o = grant.from(AccessOverride.class);
            grant.select(cb.literal(1)).where(
                    cb.equal(o.get("userId"), root.get("id")),
                    cb.isNull(o.get("supersededAt")),
                    cb.equal(o.get("type"), AccessOverrideType.GRANT));
            return cb.or(cb.exists(achat), cb.exists(grant));
        };
    }

    /** Une décision admin courante qui n'est pas encore terminée à {@code now} (filtre « Accès manuel »). */
    public static Specification<User> hasOpenOverride(Instant now) {
        return (root, query, cb) -> {
            Subquery<Integer> sub = query.subquery(Integer.class);
            Root<AccessOverride> o = sub.from(AccessOverride.class);
            sub.select(cb.literal(1)).where(
                    cb.equal(o.get("userId"), root.get("id")),
                    cb.isNull(o.get("supersededAt")),
                    cb.or(cb.isNull(o.get("endsAt")), cb.greaterThan(o.get("endsAt"), now)));
            return cb.exists(sub);
        };
    }

    private static UUID parseUuid(String raw) {
        if (raw.length() != 36) return null;
        try {
            return UUID.fromString(raw);
        } catch (IllegalArgumentException e) {
            return null;
        }
    }
}
