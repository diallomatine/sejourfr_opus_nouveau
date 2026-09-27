package com.sejourfr.app.specification;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.SubscriptionSource;
import com.sejourfr.app.enums.SubscriptionStatus;
import jakarta.persistence.criteria.Expression;
import jakarta.persistence.criteria.Path;
import org.springframework.data.jpa.domain.Specification;

import com.sejourfr.app.util.FenetreMesure;

import java.time.Instant;
import java.time.YearMonth;
import java.util.Locale;

public final class UserSubscriptionSpecifications {

    private static final char LIKE_ESCAPE = '\\';

    private UserSubscriptionSpecifications() {}

    public static Specification<UserSubscription> hasSource(SubscriptionSource source) {
        return (root, q, cb) -> source == null ? null : cb.equal(root.get("source"), source);
    }

    public static Specification<UserSubscription> hasStatus(SubscriptionStatus status) {
        return (root, q, cb) -> status == null ? null : cb.equal(root.get("status"), status);
    }

    public static Specification<UserSubscription> hasModuleAccess(ModuleAccess moduleAccess) {
        return (root, q, cb) -> moduleAccess == null
                ? null
                : cb.equal(root.get("plan").get("moduleAccess"), moduleAccess);
    }

    /**
     * Recherche « contient », insensible à la casse, sur l'email, le prénom, le nom
     * ou « prénom nom ». Les jokers LIKE saisis ({@code %}, {@code _}) sont
     * échappés : un {@code _} est courant dans un email et ne doit pas valoir
     * « n'importe quel caractère ».
     */
    public static Specification<UserSubscription> userSearch(String search) {
        return (root, q, cb) -> {
            if (search == null || search.isBlank()) return null;
            String like = "%" + escapeLike(search.trim().toLowerCase(Locale.ROOT)) + "%";
            Path<User> user = root.get("user");
            Expression<String> firstName = cb.coalesce(user.get("firstName"), "");
            Expression<String> lastName = cb.coalesce(user.get("lastName"), "");
            Expression<String> fullName = cb.concat(cb.concat(firstName, " "), lastName);
            return cb.or(
                    cb.like(cb.lower(user.get("email")), like, LIKE_ESCAPE),
                    cb.like(cb.lower(user.get("firstName")), like, LIKE_ESCAPE),
                    cb.like(cb.lower(user.get("lastName")), like, LIKE_ESCAPE),
                    cb.like(cb.lower(fullName), like, LIKE_ESCAPE));
        };
    }

    /**
     * Achats d'un mois civil, en heure de Paris : {@code purchased_at} dans
     * [1er du mois 00:00, 1er du mois suivant 00:00[. Une ligne sans
     * {@code purchased_at} (antérieure à la mesure, V074) n'appartient à aucun
     * mois : inconnu, jamais rattaché par défaut.
     */
    public static Specification<UserSubscription> purchasedIn(YearMonth month) {
        return (root, q, cb) -> {
            if (month == null) return null;
            Instant debut = month.atDay(1).atStartOfDay(FenetreMesure.PARIS).toInstant();
            Instant fin = month.plusMonths(1).atDay(1).atStartOfDay(FenetreMesure.PARIS).toInstant();
            Path<Instant> purchasedAt = root.get("purchasedAt");
            return cb.and(cb.greaterThanOrEqualTo(purchasedAt, debut), cb.lessThan(purchasedAt, fin));
        };
    }

    private static String escapeLike(String raw) {
        return raw.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_");
    }
}
