package com.sejourfr.app.service.email.automation;

import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.EmailType;
import com.sejourfr.app.manager.EmailDeliveryManager;
import com.sejourfr.app.manager.EmailScenarioManager;
import com.sejourfr.app.repository.EmailScenarioRepository.AccessCandidate;
import com.sejourfr.app.repository.EmailScenarioRepository.UserCandidate;
import com.sejourfr.app.service.SubscriptionService;
import com.sejourfr.app.service.SubscriptionService.DonneesAcces;
import com.sejourfr.app.service.access.AccesEffectifResolver;
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
 *
 * <p>🛑 Décisions admin (D-32, révise D-09) : les scénarios Premium fondés sur
 * les ACHATS ({@code NO_PREMIUM_AFTER_7_DAYS}, {@code PREMIUM_INACTIVE_2_DAYS},
 * {@code PREMIUM_ENDING_*}, {@code PREMIUM_ENDED}) écartent un compte seulement
 * si une décision admin rend l'accès effectif différent de celui des seuls
 * achats, maintenant ou d'ici la date que le message annonce
 * ({@link AccesEffectifResolver#decisionsChangentLAcces}). Le SQL ne fait que
 * borner les candidats ; la décision est prise ici, par l'autorité de l'accès.
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
    private final SubscriptionService subscriptions;
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
                    now,
                    c -> Optional.of(composer.noPremiumAfter7Days(c.getUserId(), c.getEmail(), c.getFirstName())));
            case NO_TRAINING_7_DAYS -> pageUsers(counts,
                    after -> scenarios.lastActivityBetween(startOf(today.minusDays(w.maxDays())),
                            startOf(today.minusDays(w.minDays() - 1L)), after, config.batchSize()),
                    null,
                    c -> Optional.of(composer.noTraining7Days(c.getUserId(), c.getEmail(), c.getFirstName(),
                            LocalDate.ofInstant(c.getAt(), EmailFormats.PARIS))));
            case PREMIUM_INACTIVE_2_DAYS -> premiumInactive(now, today, w, counts);
            case PREMIUM_ENDING_7_DAYS, PREMIUM_ENDING_2_DAYS -> accesses(counts,
                    now.plus(w.minDays(), ChronoUnit.DAYS), now.plus(w.maxDays(), ChronoUnit.DAYS),
                    (access, acces, c) -> {
                        List<UserSubscription> all = acces.achats();
                        if (!endResolver.seTermineSansRelais(access, all, now)) return Optional.empty();
                        // « Se termine le … » : faux si une décision change l'accès d'ici là.
                        if (decisionsChangentLAcces(acces, now, access.getEndsAt())) return Optional.empty();
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
                    (access, acces, c) -> {
                        List<UserSubscription> all = acces.achats();
                        // Le message dit « s'est terminé le … » : la fenêtre part de l'instant
                        // juste avant cette fin, quand l'achat couvrait encore.
                        if (access.getEndsAt() == null
                                || decisionsChangentLAcces(acces, access.getEndsAt().minusMillis(1), now)) {
                            return Optional.empty();
                        }
                        return endResolver.estTermineSansRelais(access, all, now)
                                ? Optional.of(composer.premiumEnded(access, c.getEmail(), c.getFirstName(),
                                        endResolver.wording(access, all, now)))
                                : Optional.empty();
                    });
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
            Map<UUID, DonneesAcces> acces = accesOf(page.stream().map(UserCandidate::getUserId).toList());
            for (UserCandidate c : page) {
                DonneesAcces d = acces.getOrDefault(c.getUserId(), DonneesAcces.VIDE);
                if (decisionsChangentLAcces(d, now, now)) continue;
                Optional<Instant> debut = d.achats().stream()
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

    /**
     * @param premiumAt {@code null} pour un scénario sans rapport avec l'accès ;
     *                  sinon l'instant où le message parle de l'accès : un compte
     *                  dont une décision admin change l'accès à cet instant est écarté.
     */
    private void pageUsers(Map<EmailOutcome, Integer> counts,
                           Function<UUID, List<UserCandidate>> fetch,
                           Instant premiumAt,
                           Function<UserCandidate, Optional<EmailRequest>> compose) {
        UUID after = EmailScenarioManager.FIRST;
        while (true) {
            List<UserCandidate> page = fetch.apply(after);
            Map<UUID, DonneesAcces> acces = premiumAt == null || page.isEmpty()
                    ? Map.of() : accesOf(page.stream().map(UserCandidate::getUserId).toList());
            for (UserCandidate c : page) {
                if (premiumAt != null && decisionsChangentLAcces(
                        acces.getOrDefault(c.getUserId(), DonneesAcces.VIDE), premiumAt, premiumAt)) continue;
                compose.apply(c).ifPresent(r -> tally(counts, emailService.sendAsync(r)));
            }
            if (page.size() < config.batchSize()) return;
            after = page.getLast().getUserId();
        }
    }

    @FunctionalInterface
    private interface AccessRule {
        Optional<EmailRequest> apply(UserSubscription access, DonneesAcces acces, AccessCandidate c);
    }

    private void accesses(Map<EmailOutcome, Integer> counts, Instant from, Instant to, AccessRule rule) {
        UUID after = EmailScenarioManager.FIRST;
        while (true) {
            List<AccessCandidate> page = scenarios.oneTimeAccessEndingBetween(from, to, after, config.batchSize());
            if (page.isEmpty()) return;
            Map<UUID, DonneesAcces> acces = accesOf(page.stream().map(AccessCandidate::getUserId).toList());
            for (AccessCandidate c : page) {
                DonneesAcces d = acces.getOrDefault(c.getUserId(), DonneesAcces.VIDE);
                d.achats().stream().filter(s -> s.getId().equals(c.getAccessId())).findFirst()
                        .flatMap(access -> rule.apply(access, d, c))
                        .ifPresent(r -> tally(counts, emailService.sendAsync(r)));
            }
            if (page.size() < config.batchSize()) return;
            after = page.getLast().getAccessId();
        }
    }

    /**
     * Achats et décisions admin courantes de la page, en deux requêtes (pas de
     * N+1), chargés par l'autorité de l'accès.
     */
    private Map<UUID, DonneesAcces> accesOf(List<UUID> userIds) {
        return subscriptions.charger(userIds.stream().distinct().toList());
    }

    private static boolean decisionsChangentLAcces(DonneesAcces d, Instant de, Instant a) {
        return AccesEffectifResolver.decisionsChangentLAcces(d.achats(), d.decisions(), de, a);
    }

    private static Instant startOf(LocalDate day) {
        return day.atStartOfDay(EmailFormats.PARIS).toInstant();
    }

    private static void tally(Map<EmailOutcome, Integer> counts, EmailOutcome outcome) {
        counts.merge(outcome, 1, Integer::sum);
    }
}
