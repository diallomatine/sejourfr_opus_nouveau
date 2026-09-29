package com.sejourfr.app.service.email.automation;

import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.EmailType;
import com.sejourfr.app.manager.EmailDeliveryManager;
import com.sejourfr.app.manager.EmailScenarioManager;
import com.sejourfr.app.manager.UserSubscriptionManager;
import com.sejourfr.app.repository.EmailScenarioRepository.AccessCandidate;
import com.sejourfr.app.repository.EmailScenarioRepository.UserCandidate;
import com.sejourfr.app.service.SubscriptionService;
import com.sejourfr.app.service.email.EmailAutomationConfig;
import com.sejourfr.app.service.email.EmailAutomationConfig.ScenarioWindow;
import com.sejourfr.app.service.email.EmailFormats;
import com.sejourfr.app.service.email.EmailOutcome;
import com.sejourfr.app.service.email.EmailRequest;
import com.sejourfr.app.service.email.EmailService;
import com.sejourfr.app.service.email.compose.EngagementEmailComposer;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * <b>Le passage quotidien des scenarios ENGAGEMENT</b> (brief §7).
 *
 * <p>Les scenarios sont evalues dans l'ordre de PRIORITE ; chaque envoi ecrit sa
 * ligne PENDING dans ce thread, donc le plafond (1 par jour calendaire
 * Europe/Paris) arrete les suivants pour le meme compte. Un refus par le plafond
 * n'est pas trace : le scenario est reevalue le lendemain, tant que sa fenetre le
 * permet.
 *
 * <p>Chaque fenetre est BORNEE des deux cotes : elle rattrape un jour manque et
 * n'envoie rien retroactivement au premier deploiement. Toutes les bornes
 * viennent de {@code email-automation-config-vN.json}.
 *
 * <p>Episodes d'inactivite : la cle porte la date qui a ouvert l'episode, donc au
 * plus un mail par type et par episode ; une nouvelle activite ouvre un nouvel
 * episode. Premium : J+2 puis J+7 ; non Premium : J+7 seul.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class EmailAutomationService {

    /** 🛑 L'ordre de priorite sous plafond (brief §7) : c'est une regle, pas un reglage. */
    public static final List<EmailType> PRIORITE = List.of(
            EmailType.PREMIUM_ENDED,
            EmailType.PREMIUM_ENDING_2_DAYS,
            EmailType.PREMIUM_ENDING_7_DAYS,
            EmailType.PREMIUM_INACTIVE_2_DAYS,
            EmailType.NO_TRAINING_7_DAYS,
            EmailType.NO_PREMIUM_AFTER_7_DAYS);

    private final EmailScenarioManager scenarios;
    private final UserSubscriptionManager subscriptions;
    private final EmailDeliveryManager deliveries;
    private final EmailService emailService;
    private final EngagementEmailComposer composer;
    private final PremiumAccessEndResolver endResolver;
    private final EmailAutomationConfig config;

    /** Ce que le passage a fait, par type : ce qui est parti (ou en file) et ce qui a ete retenu. */
    public record Report(Map<EmailType, Map<EmailOutcome, Integer>> outcomes, int stalePending) {
        public int count(EmailType type, EmailOutcome outcome) {
            return outcomes.getOrDefault(type, Map.of()).getOrDefault(outcome, 0);
        }
    }

    public Report runDaily(Instant now) {
        int stale = markStalePending(now);
        Map<EmailType, Map<EmailOutcome, Integer>> outcomes = new EnumMap<>(EmailType.class);
        for (EmailType type : PRIORITE) {
            Map<EmailOutcome, Integer> counts = new EnumMap<>(EmailOutcome.class);
            try {
                run(type, now, counts);
            } catch (RuntimeException e) {
                log.error("Scenario {} interrompu : {}", type, e.getMessage(), e);
            }
            outcomes.put(type, counts);
        }
        log.info("Passage des emails d'accompagnement ({}) : {}", now, outcomes);
        return new Report(outcomes, stale);
    }

    /** Au debut de chaque passage : un PENDING de plus d'une heure est tenu pour bloque. */
    public int markStalePending(Instant now) {
        int stale = deliveries.markStalePending(
                now.minus(Duration.ofMinutes(config.retry().stalePendingMinutes())), now);
        if (stale > 0) {
            log.warn("{} email(s) PENDING bloque(s) passe(s) FAILED (stale)", stale);
        }
        return stale;
    }

    private void run(EmailType type, Instant now, Map<EmailOutcome, Integer> counts) {
        ScenarioWindow w = config.window(type);
        LocalDate today = LocalDate.ofInstant(now, EmailFormats.PARIS);
        switch (type) {
            case NO_PREMIUM_AFTER_7_DAYS -> pageUsers(counts,
                    after -> scenarios.neverPremiumCreatedBetween(startOf(today.minusDays(w.maxDays())),
                            startOf(today.minusDays(w.minDays() - 1L)), after, config.batchSize()),
                    c -> Optional.of(composer.noPremiumAfter7Days(c.getUserId(), c.getEmail(), c.getFirstName())));
            case NO_TRAINING_7_DAYS -> pageUsers(counts,
                    after -> scenarios.lastActivityBetween(startOf(today.minusDays(w.maxDays())),
                            startOf(today.minusDays(w.minDays() - 1L)), after, config.batchSize()),
                    c -> Optional.of(composer.noTraining7Days(c.getUserId(), c.getEmail(), c.getFirstName(),
                            LocalDate.ofInstant(c.getAt(), EmailFormats.PARIS))));
            case PREMIUM_INACTIVE_2_DAYS -> premiumInactive(now, today, w, counts);
            case PREMIUM_ENDING_7_DAYS, PREMIUM_ENDING_2_DAYS -> accesses(counts,
                    now.plus(w.minDays(), ChronoUnit.DAYS), now.plus(w.maxDays(), ChronoUnit.DAYS),
                    (access, all, c) -> {
                        if (!endResolver.seTermineSansRelais(access, all, now)) return Optional.empty();
                        if (access.getStartsAt() != null && access.getStartsAt()
                                .isAfter(now.minus(w.minAccessAgeDays(), ChronoUnit.DAYS))) return Optional.empty();
                        if (w.minAccessDurationDays() > 0 && (access.getStartsAt() == null
                                || Duration.between(access.getStartsAt(), access.getEndsAt())
                                .compareTo(Duration.ofDays(w.minAccessDurationDays())) < 0)) return Optional.empty();
                        return Optional.of(composer.premiumEnding(type, access, c.getEmail(), c.getFirstName(),
                                endResolver.wording(access, all, access.getEndsAt())));
                    });
            case PREMIUM_ENDED -> accesses(counts,
                    now.minus(w.maxDays(), ChronoUnit.DAYS).minusMillis(1), now,
                    (access, all, c) -> endResolver.estTermineSansRelais(access, all, now)
                            ? Optional.of(composer.premiumEnded(access, c.getEmail(), c.getFirstName(),
                                    endResolver.wording(access, all, now)))
                            : Optional.empty());
            default -> throw new IllegalArgumentException(type + " n'est pas un scenario");
        }
    }

    /**
     * Premium actif ET inactif depuis {@code [min, max]} jours, la date de
     * reference etant max(derniere activite, debut de l'acces couvrant le plus
     * recent) — un achat est une nouvelle intention (arbitrage n°19).
     */
    private void premiumInactive(Instant now, LocalDate today, ScenarioWindow w, Map<EmailOutcome, Integer> counts) {
        UUID after = EmailScenarioManager.FIRST;
        while (true) {
            List<UserCandidate> page = scenarios.withOpenPaidAccess(now, after, config.batchSize());
            if (page.isEmpty()) return;
            Map<UUID, List<UserSubscription>> subs = subsOf(page.stream().map(UserCandidate::getUserId).toList());
            for (UserCandidate c : page) {
                Optional<Instant> debut = subs.getOrDefault(c.getUserId(), List.of()).stream()
                        .filter(s -> SubscriptionService.covers(s, now))
                        .map(UserSubscription::getStartsAt)
                        .max(Instant::compareTo);
                if (debut.isEmpty()) continue;
                Instant reference = c.getAt() != null && c.getAt().isAfter(debut.get()) ? c.getAt() : debut.get();
                LocalDate refDate = LocalDate.ofInstant(reference, EmailFormats.PARIS);
                long jours = ChronoUnit.DAYS.between(refDate, today);
                if (jours >= w.minDays() && jours <= w.maxDays()) {
                    tally(counts, emailService.sendAsync(
                            composer.premiumInactive2Days(c.getUserId(), c.getEmail(), c.getFirstName(), refDate)));
                }
            }
            if (page.size() < config.batchSize()) return;
            after = page.getLast().getUserId();
        }
    }

    private void pageUsers(Map<EmailOutcome, Integer> counts,
                           Function<UUID, List<UserCandidate>> fetch,
                           Function<UserCandidate, Optional<EmailRequest>> compose) {
        UUID after = EmailScenarioManager.FIRST;
        while (true) {
            List<UserCandidate> page = fetch.apply(after);
            for (UserCandidate c : page) {
                compose.apply(c).ifPresent(r -> tally(counts, emailService.sendAsync(r)));
            }
            if (page.size() < config.batchSize()) return;
            after = page.getLast().getUserId();
        }
    }

    @FunctionalInterface
    private interface AccessRule {
        Optional<EmailRequest> apply(UserSubscription access, List<UserSubscription> all, AccessCandidate c);
    }

    private void accesses(Map<EmailOutcome, Integer> counts, Instant from, Instant to, AccessRule rule) {
        UUID after = EmailScenarioManager.FIRST;
        while (true) {
            List<AccessCandidate> page = scenarios.oneTimeAccessEndingBetween(from, to, after, config.batchSize());
            if (page.isEmpty()) return;
            Map<UUID, List<UserSubscription>> subs = subsOf(page.stream().map(AccessCandidate::getUserId).toList());
            for (AccessCandidate c : page) {
                List<UserSubscription> all = subs.getOrDefault(c.getUserId(), List.of());
                all.stream().filter(s -> s.getId().equals(c.getAccessId())).findFirst()
                        .flatMap(access -> rule.apply(access, all, c))
                        .ifPresent(r -> tally(counts, emailService.sendAsync(r)));
            }
            if (page.size() < config.batchSize()) return;
            after = page.getLast().getAccessId();
        }
    }

    /** Tous les acces de la page en UNE requete (pas de N+1), plan charge. */
    private Map<UUID, List<UserSubscription>> subsOf(List<UUID> userIds) {
        return subscriptions.findByUserIds(userIds.stream().distinct().toList()).stream()
                .collect(Collectors.groupingBy(s -> s.getUser().getId()));
    }

    private static Instant startOf(LocalDate day) {
        return day.atStartOfDay(EmailFormats.PARIS).toInstant();
    }

    private static void tally(Map<EmailOutcome, Integer> counts, EmailOutcome outcome) {
        counts.merge(outcome, 1, Integer::sum);
    }
}
