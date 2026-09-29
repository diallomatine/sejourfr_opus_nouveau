package com.sejourfr.app.service.email.automation;

import com.sejourfr.app.entity.EmailDelivery;
import com.sejourfr.app.enums.EmailType;
import com.sejourfr.app.manager.EmailDeliveryManager;
import com.sejourfr.app.service.email.EmailAutomationConfig;
import com.sejourfr.app.service.email.EmailKeys;
import com.sejourfr.app.service.email.EmailOutcome;
import com.sejourfr.app.service.email.EmailRequest;
import com.sejourfr.app.service.email.EmailService;
import com.sejourfr.app.service.email.compose.AccountEmailComposer;
import com.sejourfr.app.service.email.compose.DiagnosticEmailComposer;
import com.sejourfr.app.service.email.compose.PremiumEmailComposer;
import com.sejourfr.app.service.email.compose.SecurityEmailComposer;
import com.sejourfr.app.service.email.compose.SupportEmailComposer;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;
import java.util.Arrays;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * <b>La relance DIFFEREE des mails evenementiels</b> (brief §5, decision D-2).
 *
 * <p>Reprend les cles dont toutes les lignes sont {@code FAILED}, dont la
 * PREMIERE ligne a moins de {@code eventWindowHours} (24 h) et qui n'ont pas
 * epuise leurs {@code 1 + maxDeferredAttempts} lignes. Les variables sont
 * RECONSTRUITES depuis la source, par le meme composeur que l'envoi initial —
 * jamais relues d'un stockage (il n'y en a pas).
 *
 * <p>🛑 Seuls les types {@code EmailType.DeferredRetry.EVENT_WINDOW} sont repris.
 * {@code PASSWORD_RESET} et {@code EMAIL_CHANGE_CONFIRMATION} ne le sont JAMAIS :
 * leur jeton n'est stocke que hache. Les scenarios se relancent par leur propre
 * reevaluation quotidienne.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class EmailDeferredRetryService {

    static final List<EmailType> TYPES = Arrays.stream(EmailType.values())
            .filter(t -> t.deferredRetry() == EmailType.DeferredRetry.EVENT_WINDOW)
            .toList();

    private final EmailDeliveryManager deliveries;
    private final EmailService emailService;
    private final EmailAutomationConfig config;
    private final AccountEmailComposer accounts;
    private final SecurityEmailComposer security;
    private final PremiumEmailComposer premium;
    private final SupportEmailComposer support;
    private final DiagnosticEmailComposer diagnostics;

    public Map<EmailOutcome, Integer> retry(Instant now) {
        Instant since = now.minus(Duration.ofHours(config.retry().eventWindowHours()));
        List<EmailDelivery> candidates = deliveries.findEventRetryCandidates(
                TYPES, since, config.retry().maxRowsPerKey(), config.batchSize());
        Map<EmailOutcome, Integer> outcomes = new EnumMap<>(EmailOutcome.class);
        for (EmailDelivery failed : candidates) {
            try {
                rebuild(failed).ifPresent(r -> outcomes.merge(emailService.sendAsync(r), 1, Integer::sum));
            } catch (RuntimeException e) {
                log.warn("Relance differee de {} impossible (ligne {}) : {}", failed.getEmailType(),
                        failed.getId(), e.getMessage());
            }
        }
        if (!candidates.isEmpty()) {
            log.info("Relance differee : {} cle(s) reprise(s) {}", candidates.size(), outcomes);
        }
        return outcomes;
    }

    /** Recompose la demande depuis la source ; vide si la source n'existe plus. */
    Optional<EmailRequest> rebuild(EmailDelivery d) {
        EmailRequest.Origin o = EmailRequest.Origin.DEFERRED_RETRY;
        return switch (d.getEmailType()) {
            case WELCOME -> accounts.welcome(d.getUserId(), o);
            case PREMIUM_ACCESS_STARTED, PREMIUM_ACCESS_EXTENDED ->
                    premium.accessGranted(d.getEmailType(), d.getReferenceId(), o);
            case PREMIUM_SUBSCRIPTION_CANCELED -> premium.subscriptionCanceled(d.getReferenceId(), o);
            case PASSWORD_CHANGED -> security.passwordChanged(d.getUserId(), d.getReferenceId(), d.getOccurredAt(), o);
            case EMAIL_CHANGED -> security.emailChanged(d.getUserId(), d.getRecipient(), d.getReferenceId(),
                    d.getOccurredAt(), o);
            case SUPPORT_REPLY -> support.supportReply(d.getReferenceId(), o);
            case DIAGNOSTIC_PLAN_READY -> EmailKeys.moduleOf(d.getDeduplicationKey())
                    .flatMap(module -> diagnostics.planReady(d.getUserId(), module, d.getReferenceId(), o));
            default -> Optional.empty();
        };
    }
}
