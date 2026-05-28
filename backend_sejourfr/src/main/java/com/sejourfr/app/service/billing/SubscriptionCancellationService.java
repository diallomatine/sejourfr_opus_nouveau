package com.sejourfr.app.service.billing;

import com.sejourfr.app.dto.CancelSubscriptionResponse;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.SubscriptionStatus;
import com.sejourfr.app.manager.UserSubscriptionManager;
import com.sejourfr.app.service.SubscriptionService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.UUID;

/**
 * Aiguille la résiliation à la demande de l'utilisateur selon la
 * {@code source} de l'abonnement actif. Trois cas, trois sémantiques :
 *
 * <ul>
 *   <li><b>Stripe</b> — annulation 100 % serveur via API ({@code cancel_at_period_end}).
 *       L'utilisateur garde Premium jusqu'à {@code endsAt}. On met aussi la
 *       ligne locale à {@code CANCELED + autoRenew=false} pour une UX immédiate
 *       (sans attendre le webhook qui arrivera quelques secondes plus tard).</li>
 *   <li><b>Apple</b> — IMPOSSIBLE côté serveur (App Store Server API ne le
 *       permet pas, c'est une règle du store). On renvoie une REDIRECT vers
 *       {@code https://apps.apple.com/account/subscriptions} qui ouvre
 *       directement les Settings → Subscriptions sur iOS. Le statut local
 *       N'EST PAS modifié — c'est le webhook
 *       {@code DID_CHANGE_RENEWAL_STATUS} (cf. {@code AppleSubscriptionService})
 *       qui le posera à CANCELED si l'utilisateur valide.</li>
 *   <li><b>Google</b> — l'API Play permet techniquement
 *       {@code purchases.subscriptions.cancel}, mais on garde la même UX que
 *       Apple par symétrie et pour rester conforme aux guidelines Play
 *       (l'utilisateur gère ses abonnements depuis le store). Redirect vers
 *       {@code https://play.google.com/store/account/subscriptions}.</li>
 * </ul>
 *
 * <p>Source de vérité : c'est toujours le webhook qui pose le statut
 * définitif. Le marquage local Stripe ici est une optimisation UX, pas une
 * substitution.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class SubscriptionCancellationService {

    private static final String APPLE_SUBSCRIPTIONS_URL =
            "https://apps.apple.com/account/subscriptions";
    private static final String GOOGLE_SUBSCRIPTIONS_URL =
            "https://play.google.com/store/account/subscriptions";

    private final SubscriptionService subscriptionService;
    private final UserSubscriptionManager userSubscriptionManager;
    private final StripeSubscriptionService stripeSubscriptionService;

    @Transactional
    public CancelSubscriptionResponse cancelForUser(UUID userId) {
        UserSubscription sub = subscriptionService.currentSubscription(userId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Aucun abonnement actif à résilier."
                ));
        return routeCancel(sub);
    }

    /**
     * Annule un abonnement précis par son ID. Cas admin/support : permet
     * d'annuler un abo Stripe pour un autre user. Pour Apple/Google, renvoie
     * la même {@code REDIRECT} que côté user — l'admin ne peut PAS annuler à
     * leur place, c'est une règle des stores ; à charge pour le support de
     * communiquer l'URL au client.
     */
    @Transactional
    public CancelSubscriptionResponse cancelSubscriptionById(UUID subscriptionId) {
        UserSubscription sub = userSubscriptionManager.findById(subscriptionId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Abonnement introuvable : " + subscriptionId
                ));
        if (!isCancellable(sub.getStatus())) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Cet abonnement n'est pas annulable (statut " + sub.getStatus() + ")."
            );
        }
        return routeCancel(sub);
    }

    private static boolean isCancellable(SubscriptionStatus status) {
        // ACTIVE / TRIAL / IN_GRACE = Premium ouvert, annulation utile.
        // CANCELED = déjà annulé, on no-op via 409 plutôt que de re-poster
        //            cancel_at_period_end (Stripe l'accepterait mais l'UI
        //            doit refléter qu'il n'y a rien à faire).
        return status == SubscriptionStatus.ACTIVE
                || status == SubscriptionStatus.TRIAL
                || status == SubscriptionStatus.IN_GRACE;
    }

    private CancelSubscriptionResponse routeCancel(UserSubscription sub) {
        return switch (sub.getSource()) {
            case STRIPE -> cancelStripe(sub);
            case APPLE -> CancelSubscriptionResponse.redirect(
                    APPLE_SUBSCRIPTIONS_URL,
                    "Cet abonnement est géré par Apple. Vous allez être redirigé vers "
                            + "les abonnements App Store pour le résilier."
            );
            case GOOGLE -> CancelSubscriptionResponse.redirect(
                    GOOGLE_SUBSCRIPTIONS_URL,
                    "Cet abonnement est géré par Google Play. Vous allez être redirigé "
                            + "vers les abonnements Play Store pour le résilier."
            );
        };
    }

    private CancelSubscriptionResponse cancelStripe(UserSubscription sub) {
        String stripeSubId = sub.getOriginalTransactionId();
        if (stripeSubId == null || stripeSubId.isBlank()) {
            log.error("UserSubscription {} (STRIPE) sans originalTransactionId — annulation impossible.",
                    sub.getId());
            throw new ResponseStatusException(
                    HttpStatus.INTERNAL_SERVER_ERROR,
                    "Cet abonnement ne peut pas être résilié automatiquement. Contactez le support."
            );
        }

        stripeSubscriptionService.cancelAtPeriodEnd(stripeSubId);

        // UX immédiate : on bascule localement sans attendre le webhook
        // customer.subscription.updated. Le webhook réappliquera le même état
        // (CANCELED + autoRenew=false) — opération idempotente.
        sub.setStatus(SubscriptionStatus.CANCELED);
        sub.setAutoRenew(false);
        userSubscriptionManager.save(sub);

        return CancelSubscriptionResponse.done(buildStripeDoneMessage(sub.getEndsAt()));
    }

    private String buildStripeDoneMessage(Instant endsAt) {
        if (endsAt == null) {
            return "Résiliation enregistrée. Votre accès Premium restera ouvert jusqu'à la "
                    + "fin de la période en cours.";
        }
        LocalDate endDate = endsAt.atZone(ZoneId.of("Europe/Paris")).toLocalDate();
        return "Résiliation enregistrée. Votre accès Premium reste ouvert jusqu'au "
                + formatFrenchDate(endDate) + ".";
    }

    private static final String[] FRENCH_MONTHS = {
            "janvier", "février", "mars", "avril", "mai", "juin",
            "juillet", "août", "septembre", "octobre", "novembre", "décembre"
    };

    private static String formatFrenchDate(LocalDate d) {
        return d.getDayOfMonth() + " " + FRENCH_MONTHS[d.getMonthValue() - 1] + " " + d.getYear();
    }
}
