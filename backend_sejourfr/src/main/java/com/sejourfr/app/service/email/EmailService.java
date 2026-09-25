package com.sejourfr.app.service.email;

import com.sejourfr.app.config.EmailAsyncConfig;
import com.sejourfr.app.enums.EmailCategory;
import com.sejourfr.app.enums.EmailSkipReason;
import com.sejourfr.app.enums.EmailType;
import com.sejourfr.app.manager.EmailDeliveryManager;
import com.sejourfr.app.manager.EmailDeliveryManager.NewDelivery;
import com.sejourfr.app.manager.UserEmailPreferenceManager;
import com.sejourfr.app.util.LogMask;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.core.task.TaskExecutor;
import org.springframework.core.task.TaskRejectedException;
import org.springframework.stereotype.Service;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * <b>Les regles d'envoi</b> (brief §5), dans l'ordre, pour TOUS les mails :
 *
 * <ol>
 *   <li>categorie du type ;</li>
 *   <li>preferences (REQUIRED les ignore) — un refus d'un mail evenementiel est
 *       trace {@code SKIPPED}, celui du scheduler ne l'est pas ;</li>
 *   <li>plafond ENGAGEMENT par jour calendaire Europe/Paris — refus NON trace,
 *       reevalue le lendemain ; {@code DIAGNOSTIC_PLAN_READY} n'y est jamais
 *       soumis mais le consomme (arbitrage n°18) ;</li>
 *   <li>tentatives epuisees pour la cle ;</li>
 *   <li>liste blanche de dev — refus trace {@code SKIPPED / ALLOWLIST} ;</li>
 *   <li>anti-doublon : INSERT PENDING d'abord ({@code ON CONFLICT DO NOTHING}) ;</li>
 *   <li>envoi par le port, avec relance immediate (boucle + {@link Sleeper},
 *       delais de la configuration versionnee) ;</li>
 *   <li>{@code SENT} ou {@code FAILED}, erreur assainie.</li>
 * </ol>
 *
 * <p>🛑 Rien ici ne propage d'exception vers un parcours metier : un echec
 * d'envoi n'a jamais le droit de faire echouer une inscription, un paiement, un
 * diagnostic ou un entrainement.
 *
 * <p>🛑 Logs : adresse masquee ({@link LogMask#email}), jamais de jeton, jamais
 * d'URL.
 */
@Service
@Slf4j
public class EmailService {

    private final EmailDeliveryManager deliveries;
    private final UserEmailPreferenceManager preferences;
    private final EmailSender sender;
    private final EmailAutomationConfig config;
    private final EmailAllowlist allowlist;
    private final UnsubscribeTokenService unsubscribeTokens;
    private final EmailLinks links;
    private final Sleeper sleeper;
    private final Clock clock;
    private final TaskExecutor executor;

    public EmailService(EmailDeliveryManager deliveries,
                        UserEmailPreferenceManager preferences,
                        EmailSender sender,
                        EmailAutomationConfig config,
                        EmailAllowlist allowlist,
                        UnsubscribeTokenService unsubscribeTokens,
                        EmailLinks links,
                        Sleeper sleeper,
                        Clock clock,
                        @Qualifier(EmailAsyncConfig.EMAIL_TASK_EXECUTOR) TaskExecutor executor) {
        this.deliveries = deliveries;
        this.preferences = preferences;
        this.sender = sender;
        this.config = config;
        this.allowlist = allowlist;
        this.unsubscribeTokens = unsubscribeTokens;
        this.links = links;
        this.sleeper = sleeper;
        this.clock = clock;
        this.executor = executor;
    }

    /**
     * Applique les regles puis envoie <b>dans le thread appelant</b>, relances
     * immediates comprises. Reserve aux appelants deja sur l'executor email (les
     * mails evenementiels, via {@link EmailDispatcher}).
     */
    public EmailOutcome send(EmailRequest request) {
        Preparation p = prepare(request);
        return p.refusal() != null ? p.refusal() : deliver(p.deliveryId(), p.message());
    }

    /**
     * Applique les regles et ecrit la ligne PENDING <b>dans le thread appelant</b>
     * (le plafond et la priorite du scheduler la voient aussitot), puis confie
     * l'envoi et ses relances a l'executor email. Un rejet de l'executor devient
     * une ligne FAILED, jamais une execution dans le thread appelant.
     */
    public EmailOutcome sendAsync(EmailRequest request) {
        Preparation p = prepare(request);
        if (p.refusal() != null) {
            return p.refusal();
        }
        try {
            executor.execute(() -> deliver(p.deliveryId(), p.message()));
            return EmailOutcome.QUEUED;
        } catch (TaskRejectedException e) {
            log.warn("Email {} vers {} refuse par l'executor sature", request.type(),
                    LogMask.email(request.recipient()));
            deliveries.markFailed(p.deliveryId(), clock.instant(), "rejected: email executor saturated", 0);
            return EmailOutcome.REJECTED;
        }
    }

    /**
     * Trace un mail evenementiel qui n'a pas pu etre compose : executor sature
     * (complement E) ou lecture de la source en echec. Ligne FAILED, reprise par
     * la relance differee quand le type l'autorise.
     */
    public void recordFailure(EmailIntent intent, String reason) {
        if (intent.recipient() == null || intent.recipient().isBlank()) {
            log.warn("Email {} non compose, sans destinataire connu (user={})", intent.type(), intent.userId());
            return;
        }
        deliveries.insertFailed(new NewDelivery(intent.userId(), intent.type(), intent.recipient(),
                sender.provider(), intent.deduplicationKey(), intent.referenceId(), intent.occurredAt(),
                clock.instant()), EmailErrors.sanitize(reason));
        log.warn("Email {} vers {} non compose ({}) : ligne FAILED", intent.type(),
                LogMask.email(intent.recipient()), EmailErrors.sanitize(reason));
    }

    /**
     * Consomme une cle SANS envoyer (ligne SKIPPED / KEY_CONSUMED) : l'adoption
     * d'un diagnostic invite ne declenche pas de mail, mais un diagnostic
     * ulterieur du module ne doit pas le declencher non plus (complement C).
     *
     * @return vrai si la cle etait libre et vient d'etre consommee
     */
    public boolean consumeKey(EmailIntent intent) {
        boolean consumed = deliveries.insertSkipped(new NewDelivery(intent.userId(), intent.type(),
                intent.recipient(), sender.provider(), intent.deduplicationKey(), intent.referenceId(),
                intent.occurredAt(), clock.instant()), EmailSkipReason.KEY_CONSUMED).isPresent();
        log.info("Cle {} consommee sans envoi pour {} : {}", intent.type(),
                LogMask.email(intent.recipient()), consumed);
        return consumed;
    }

    // ------------------------------------------------------------------------
    // Regles
    // ------------------------------------------------------------------------

    /** Soit un refus, soit une ligne PENDING ecrite et le message a envoyer. */
    private record Preparation(EmailOutcome refusal, UUID deliveryId, EmailMessage message) {
        static Preparation ready(UUID deliveryId, EmailMessage message) {
            return new Preparation(null, deliveryId, message);
        }
    }

    private Preparation prepare(EmailRequest req) {
        EmailType type = req.type();
        EmailCategory category = type.category();

        if (req.recipient() == null || req.recipient().isBlank()) {
            return refuse(EmailOutcome.NO_RECIPIENT, req, "sans destinataire");
        }

        // 2. Preferences. Un visiteur sans compte n'a pas de preference : il ne
        // recoit de toute facon que du REQUIRED.
        if (category != EmailCategory.REQUIRED) {
            boolean allowed = req.userId() != null
                    && EmailCategoryPolicy.allows(category, preferences.find(req.userId()));
            if (!allowed) {
                if (req.origin() != EmailRequest.Origin.SCHEDULER) {
                    deliveries.insertSkipped(newDelivery(req), EmailSkipReason.PREFERENCE);
                }
                return refuse(EmailOutcome.SKIPPED_PREFERENCE, req, "refuse par la preference");
            }
        }

        // 3. Plafond ENGAGEMENT du jour calendaire Europe/Paris.
        if (category == EmailCategory.ENGAGEMENT && !type.capExempt()
                && deliveries.countEngagementSince(req.userId(), startOfTodayParis())
                >= config.engagement().dailyCap()) {
            return refuse(EmailOutcome.CAPPED, req, "plafond du jour atteint");
        }

        // 4. Tentatives epuisees pour cette cle.
        if (req.deduplicationKey() != null
                && deliveries.countFailedByKey(req.deduplicationKey()) >= config.retry().maxRowsPerKey()) {
            return refuse(EmailOutcome.EXHAUSTED, req, "tentatives epuisees");
        }

        // 5. Liste blanche de dev : trace pour rester visible (complement G).
        if (!allowlist.allows(req.recipient())) {
            deliveries.insertSkipped(newDelivery(req), EmailSkipReason.ALLOWLIST);
            return refuse(EmailOutcome.SKIPPED_ALLOWLIST, req, "hors liste blanche de dev");
        }

        // 6. Anti-doublon : INSERT PENDING d'abord.
        Optional<UUID> id = deliveries.insertPending(newDelivery(req));
        if (id.isEmpty()) {
            return refuse(EmailOutcome.DUPLICATE, req, "cle deja occupee");
        }
        return Preparation.ready(id.get(), toMessage(req));
    }

    private Preparation refuse(EmailOutcome outcome, EmailRequest req, String motif) {
        if (outcome == EmailOutcome.DUPLICATE || outcome == EmailOutcome.CAPPED) {
            log.debug("Email {} vers {} non envoye : {}", req.type(), LogMask.email(req.recipient()), motif);
        } else {
            log.info("Email {} vers {} non envoye : {}", req.type(), LogMask.email(req.recipient()), motif);
        }
        return new Preparation(outcome, null, null);
    }

    private NewDelivery newDelivery(EmailRequest req) {
        return new NewDelivery(req.userId(), req.type(), req.recipient(), sender.provider(),
                req.deduplicationKey(), req.referenceId(), req.occurredAt(), clock.instant());
    }

    /** Le lien de desabonnement n'existe QUE pour un mail ENGAGEMENT (brief §6). */
    private EmailMessage toMessage(EmailRequest req) {
        String page = null;
        String oneClick = null;
        if (req.type().category() == EmailCategory.ENGAGEMENT && req.userId() != null) {
            String token = unsubscribeTokens.create(req.userId());
            page = links.unsubscribePage(token);
            oneClick = links.unsubscribeOneClick(token);
        }
        return new EmailMessage(req.recipient(), req.type(), req.variables(), page, oneClick);
    }

    private Instant startOfTodayParis() {
        return LocalDate.now(clock.withZone(EmailFormats.PARIS)).atStartOfDay(EmailFormats.PARIS).toInstant();
    }

    // ------------------------------------------------------------------------
    // Envoi + relance immediate
    // ------------------------------------------------------------------------

    /**
     * Une tentative, puis une par delai configure, sur la MEME ligne. La boucle
     * est explicite (arbitrage n°17) : lisible, et testable avec un
     * {@link Sleeper} qui n'attend pas.
     */
    EmailOutcome deliver(UUID deliveryId, EmailMessage message) {
        List<Duration> delays = config.retry().immediateDelays();
        int attempts = 0;
        String lastError = null;
        for (int i = 0; i <= delays.size(); i++) {
            if (i > 0) {
                try {
                    sleeper.sleep(delays.get(i - 1));
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                    lastError = "interrupted";
                    break;
                }
            }
            attempts++;
            try {
                String providerMessageId = sender.send(message);
                deliveries.markSent(deliveryId, clock.instant(), providerMessageId, attempts);
                log.info("Email {} envoye a {} (tentative {})", message.type(),
                        LogMask.email(message.recipient()), attempts);
                return EmailOutcome.SENT;
            } catch (RuntimeException e) {
                lastError = EmailErrors.sanitize(e);
                log.warn("Echec d'envoi {} vers {} (tentative {}/{}) : {}", message.type(),
                        LogMask.email(message.recipient()), attempts, delays.size() + 1, lastError);
            }
        }
        deliveries.markFailed(deliveryId, clock.instant(), lastError, attempts);
        return EmailOutcome.FAILED;
    }
}
