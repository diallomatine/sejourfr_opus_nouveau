package com.sejourfr.app.specification;

import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.SubscriptionSource;
import com.sejourfr.app.enums.SubscriptionStatus;
import jakarta.persistence.criteria.Predicate;
import org.springframework.data.jpa.domain.Specification;

public final class UserSubscriptionSpecifications {

    private UserSubscriptionSpecifications() {}

    public static Specification<UserSubscription> hasSource(SubscriptionSource source) {
        return (root, q, cb) -> source == null ? null : cb.equal(root.get("source"), source);
    }

    public static Specification<UserSubscription> hasStatus(SubscriptionStatus status) {
        return (root, q, cb) -> status == null ? null : cb.equal(root.get("status"), status);
    }

    public static Specification<UserSubscription> hasModuleAccess(ModuleAccess moduleAccess) {
        // Plan.moduleAccess est lazy : on JOIN explicitement pour pouvoir filtrer.
        return (root, q, cb) -> moduleAccess == null
                ? null
                : cb.equal(root.get("plan").get("moduleAccess"), moduleAccess);
    }

    /** Recherche LIKE (case-insensitive) sur email ou first_name+last_name du user. */
    public static Specification<UserSubscription> userSearch(String search) {
        return (root, q, cb) -> {
            if (search == null || search.isBlank()) return null;
            String like = "%" + search.toLowerCase() + "%";
            Predicate emailMatch = cb.like(cb.lower(root.get("user").get("email")), like);
            Predicate firstNameMatch = cb.like(cb.lower(root.get("user").get("firstName")), like);
            Predicate lastNameMatch = cb.like(cb.lower(root.get("user").get("lastName")), like);
            return cb.or(emailMatch, firstNameMatch, lastNameMatch);
        };
    }
}
