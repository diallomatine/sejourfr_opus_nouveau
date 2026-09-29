package com.sejourfr.app.service.email.compose;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.EmailType;
import com.sejourfr.app.manager.UserSubscriptionManager;
import com.sejourfr.app.service.email.EmailFormats;
import com.sejourfr.app.service.email.EmailKeys;
import com.sejourfr.app.service.email.EmailLinks;
import com.sejourfr.app.service.email.EmailRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/**
 * Les mails REQUIRED de l'acces Premium, composes depuis la ligne
 * {@code user_subscriptions} (un achat = une ligne = un {@code accessId}).
 *
 * <p>{@code offerName} = {@code plans.name} (« Intégral — pass 7 jours ») :
 * « pass » est le vocabulaire client (arbitrage n°4), jamais « abonnement ».
 */
@Component
@RequiredArgsConstructor
public class PremiumEmailComposer {

    static final String TERMES_ACHAT_UNIQUE =
            "Achat unique, sans abonnement ni renouvellement automatique : votre accès reste ouvert jusqu'au";
    /** Mode recurrent DORMANT seulement (reversibilite, docs/regles/paiements.md). */
    static final String TERMES_RECURRENT =
            "Votre accès est renouvelé automatiquement. Prochain renouvellement le";

    private final UserSubscriptionManager subscriptions;
    private final EmailLinks links;

    /**
     * {@code PREMIUM_ACCESS_STARTED} (premier acces) ou {@code PREMIUM_ACCESS_EXTENDED}
     * (achat qui prolonge un acces en cours) — le type est decide a l'octroi,
     * seul instant ou « prolongation » a un sens, puis relu sur le journal.
     */
    @Transactional(readOnly = true)
    public Optional<EmailRequest> accessGranted(EmailType type, UUID accessId, EmailRequest.Origin origin) {
        if (type != EmailType.PREMIUM_ACCESS_STARTED && type != EmailType.PREMIUM_ACCESS_EXTENDED) {
            throw new IllegalArgumentException("type d'octroi inattendu : " + type);
        }
        return load(accessId).map(sub -> {
            User user = sub.getUser();
            return new EmailRequest(type, user.getId(), user.getEmail(),
                    Map.of("firstName", EmailFormats.firstName(user.getFirstName()),
                            "greeting", EmailFormats.greeting(user.getFirstName()),
                            "offerName", offerName(sub),
                            "accessStartDate", EmailFormats.date(sub.getStartsAt()),
                            "accessEndDate", EmailFormats.date(sub.getEndsAt()),
                            "accessTerms", sub.isAutoRenew() ? TERMES_RECURRENT : TERMES_ACHAT_UNIQUE,
                            "appUrl", links.dashboard()),
                    EmailKeys.byReference(type, accessId), accessId, null, origin);
        });
    }

    /** Mode abonnement recurrent DORMANT : resiliation enregistree. */
    @Transactional(readOnly = true)
    public Optional<EmailRequest> subscriptionCanceled(UUID accessId, EmailRequest.Origin origin) {
        return load(accessId).map(sub -> {
            User user = sub.getUser();
            return new EmailRequest(EmailType.PREMIUM_SUBSCRIPTION_CANCELED, user.getId(), user.getEmail(),
                    Map.of("firstName", EmailFormats.firstName(user.getFirstName()),
                            "greeting", EmailFormats.greeting(user.getFirstName()),
                            "offerName", offerName(sub),
                            "accessEndDate", EmailFormats.date(sub.getEndsAt()),
                            "reactivateHint", reactivateHint(sub),
                            "appUrl", links.dashboard()),
                    EmailKeys.byReference(EmailType.PREMIUM_SUBSCRIPTION_CANCELED, accessId), accessId, null, origin);
        });
    }

    private Optional<UserSubscription> load(UUID accessId) {
        return subscriptions.findById(accessId)
                .filter(s -> s.getUser() != null && s.getUser().getDeletedAt() == null && s.getUser().isActive());
    }

    private static String offerName(UserSubscription sub) {
        String name = sub.getPlan() == null ? null : sub.getPlan().getName();
        return name == null || name.isBlank() ? "Premium" : name;
    }

    private static String reactivateHint(UserSubscription sub) {
        return switch (sub.getSource()) {
            case APPLE -> "Vous pouvez réactiver votre abonnement depuis Réglages → [votre nom] → Abonnements.";
            case GOOGLE -> "Vous pouvez réactiver votre abonnement depuis Play Store → Abonnements.";
            default -> "Vous pouvez réactiver votre abonnement à tout moment depuis votre profil.";
        };
    }
}
