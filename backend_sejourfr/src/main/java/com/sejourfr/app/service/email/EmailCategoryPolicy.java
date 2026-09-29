package com.sejourfr.app.service.email;

import com.sejourfr.app.entity.UserEmailPreference;
import com.sejourfr.app.enums.EmailCategory;

import java.util.Optional;

/**
 * <b>Ce qu'une preference autorise</b>, par categorie — la regle, en un seul
 * endroit.
 *
 * <ul>
 *   <li>{@code REQUIRED} : toujours. Aucune preference ne le desactive.</li>
 *   <li>{@code ENGAGEMENT} : sauf desabonnement ; ligne absente = autorise.</li>
 *   <li>{@code MARKETING} : seulement sur opt-in explicite ; ligne absente = refuse.</li>
 * </ul>
 */
public final class EmailCategoryPolicy {

    private EmailCategoryPolicy() {
    }

    public static boolean allows(EmailCategory category, Optional<UserEmailPreference> preference) {
        return switch (category) {
            case REQUIRED -> true;
            case ENGAGEMENT -> preference.map(UserEmailPreference::isEngagementEnabled)
                    .orElse(UserEmailPreference.ENGAGEMENT_PAR_DEFAUT);
            case MARKETING -> preference.map(UserEmailPreference::isMarketingEnabled)
                    .orElse(UserEmailPreference.MARKETING_PAR_DEFAUT);
        };
    }
}
