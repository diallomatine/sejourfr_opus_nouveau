package com.sejourfr.app.specification;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.SubscriptionSource;
import com.sejourfr.app.enums.SubscriptionStatus;
import jakarta.persistence.criteria.Expression;
import jakarta.persistence.criteria.Path;
import org.springframework.data.jpa.domain.Specification;

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

    private static String escapeLike(String raw) {
        return raw.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_");
    }
}
