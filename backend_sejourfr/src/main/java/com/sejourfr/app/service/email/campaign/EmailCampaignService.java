package com.sejourfr.app.service.email.campaign;

import com.sejourfr.app.config.EmailAsyncConfig;
import com.sejourfr.app.dto.EmailCampaignRunResponse;
import com.sejourfr.app.enums.EmailCampaign;
import com.sejourfr.app.enums.EmailDeliveryStatus;
import com.sejourfr.app.manager.EmailCampaignManager;
import com.sejourfr.app.manager.EmailDeliveryManager;
import com.sejourfr.app.repository.EmailCampaignRepository.Recipient;
import com.sejourfr.app.service.email.EmailKeys;
import com.sejourfr.app.service.email.EmailOutcome;
import com.sejourfr.app.service.email.EmailRequest;
import com.sejourfr.app.service.email.EmailService;
import com.sejourfr.app.util.LogMask;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.core.task.AsyncTaskExecutor;
import org.springframework.core.task.TaskRejectedException;
import org.springframework.stereotype.Service;

import java.time.Clock;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * <b>Campagnes d'information de service</b> ({@code incident}, {@code reprise}),
 * pilotees par un admin vague par vague.
 *
 * <ul>
 *   <li>{@code dry-run} : nombre de comptes a servir et echantillon masque, rien d'ecrit ;</li>
 *   <li>{@code test} : un seul mail, vers l'adresse passee, sans toucher au journal de campagne ;</li>
 *   <li>{@code send} : une vague. Un refus PROPRE A L'ADRESSE (5xx destinataire,
 *       adresse illisible) passe la ligne en FAILED et la vague continue ; un
 *       echec SYSTEMIQUE (limite de debit, SMTP injoignable, auth) l'arrete, sans
 *       imputer la tentative au compte.</li>
 * </ul>
 *
 * <p>Selection : les comptes jamais tentes d'abord ; les FAILED ne sont repris
 * qu'une fois qu'il n'en reste plus aucun, dans la limite de
 * {@code maxAttemptsPerRecipient}.
 *
 * <p>🛑 L'envoi passe par {@link EmailService} (journal {@code email_deliveries},
 * cle anti-doublon par compte) sur {@code emailTaskExecutor}, jamais dans le
 * thread de la requete. 🛑 Ce service ne lit PAS
 * {@code sejourfr.email.automation.enabled} : ce drapeau ne garde que les
 * scenarios automatises, une campagne manuelle n'en depend pas.
 */
@Service
@Slf4j
public class EmailCampaignService {

    public enum Mode {
        DRY_RUN("dry-run"), TEST("test"), SEND("send");

        private final String wire;

        Mode(String wire) {
            this.wire = wire;
        }

        public String wire() {
            return wire;
        }

        public static Mode fromWire(String value) {
            for (Mode m : values()) {
                if (m.wire.equals(value)) return m;
            }
            throw new IllegalArgumentException("mode invalide : " + value + " (dry-run, test ou send)");
        }
    }

    private final EmailCampaignManager campaigns;
    private final EmailDeliveryManager deliveries;
    private final EmailService emailService;
    private final AsyncTaskExecutor executor;
    private final Clock clock;
    private final EmailCampaignConfig config = EmailCampaignConfig.load();
    private final AtomicBoolean running = new AtomicBoolean(false);

    public EmailCampaignService(EmailCampaignManager campaigns,
                                EmailDeliveryManager deliveries,
                                EmailService emailService,
                                @Qualifier(EmailAsyncConfig.EMAIL_TASK_EXECUTOR) AsyncTaskExecutor executor,
                                Clock clock) {
        this.campaigns = campaigns;
        this.deliveries = deliveries;
        this.emailService = emailService;
        this.executor = executor;
        this.clock = clock;
    }

    /** Compteurs d'une vague, lus par la reponse meme si la vague n'est pas finie. */
    private static final class Wave {
        volatile int sent;
        volatile int alreadyServed;
        volatile int skipped;
        volatile int rejected;
        volatile int failed;
        volatile String error;
    }

    public EmailCampaignRunResponse run(String code, String modeWire, Integer batch, String to) {
        EmailCampaign campaign = EmailCampaign.fromCode(code);
        Mode mode = Mode.fromWire(modeWire);
        return switch (mode) {
            case DRY_RUN -> response(campaign, mode, "DRY_RUN", new Wave());
            case TEST -> test(campaign, to);
            case SEND -> send(campaign, batch == null ? config.waveSize() : batch);
        };
    }

    private EmailCampaignRunResponse test(EmailCampaign campaign, String to) {
        if (to == null || to.isBlank() || !to.contains("@")) {
            throw new IllegalArgumentException("mode=test exige le parametre to (une adresse)");
        }
        String recipient = to.trim();
        Wave wave = new Wave();
        EmailRequest request = new EmailRequest(campaign.emailType(), null, recipient, Map.of(),
                EmailKeys.of(campaign.emailType(), "TEST", UUID.randomUUID()), null, null,
                EmailRequest.Origin.EVENT);
        String status = await(campaign, wave, () -> {
            EmailOutcome outcome = emailService.send(request);
            if (outcome == EmailOutcome.SENT) {
                wave.sent++;
            } else if (outcome == EmailOutcome.SKIPPED_ALLOWLIST) {
                wave.skipped++;
            } else if (outcome == EmailOutcome.RECIPIENT_REJECTED) {
                wave.rejected++;
                wave.error = outcome.name();
            } else {
                wave.failed++;
                wave.error = outcome.name();
            }
        });
        if (status.equals("COMPLETED")) {
            status = wave.failed + wave.rejected > 0 ? "STOPPED_ON_ERROR" : "TEST_SENT";
        }
        log.info("Campagne {} : test vers {} -> {}", campaign.code(), LogMask.email(recipient), status);
        return response(campaign, Mode.TEST, status, wave);
    }

    private EmailCampaignRunResponse send(EmailCampaign campaign, int batch) {
        if (batch < 1 || batch > config.maxWaveSize()) {
            throw new IllegalArgumentException("batch doit etre compris entre 1 et " + config.maxWaveSize());
        }
        List<Recipient> recipients = campaigns.findNext(campaign, config.maxAttemptsPerRecipient(), batch);
        Wave wave = new Wave();
        if (recipients.isEmpty()) {
            return response(campaign, Mode.SEND, "NOTHING_TO_SEND", wave);
        }
        String status = await(campaign, wave, () -> sendWave(campaign, recipients, wave));
        if (status.equals("COMPLETED") && wave.failed > 0) {
            status = "STOPPED_ON_ERROR";
        }
        log.info("Campagne {} : vague de {} -> {} (envoyes {}, deja servis {}, ignores {}, adresses refusees {}, "
                        + "echecs systemiques {})", campaign.code(), recipients.size(), status, wave.sent,
                wave.alreadyServed, wave.skipped, wave.rejected, wave.failed);
        return response(campaign, Mode.SEND, status, wave);
    }

    /**
     * Sur l'executor email. Un refus d'adresse ne bloque pas la vague ; un echec
     * systemique l'arrete (et la tentative est rendue au compte), comme une
     * serie de {@code maxConsecutiveRecipientFailures} refus d'adresse.
     */
    private void sendWave(EmailCampaign campaign, List<Recipient> recipients, Wave wave) {
        int consecutiveRejects = 0;
        for (Recipient r : recipients) {
            if (!campaigns.claim(campaign, r.getUserId(), clock.instant(), config.maxAttemptsPerRecipient())) {
                wave.alreadyServed++;
                continue;
            }
            String key = EmailKeys.of(campaign.emailType(), r.getUserId());
            EmailOutcome outcome;
            try {
                outcome = emailService.send(new EmailRequest(campaign.emailType(), r.getUserId(), r.getEmail(),
                        Map.of(), key, null, null, EmailRequest.Origin.EVENT));
            } catch (RuntimeException e) {
                stopSystemic(campaign, r, wave, e.getClass().getSimpleName());
                return;
            }
            switch (outcome) {
                case SENT -> {
                    campaigns.mark(campaign, r.getUserId(), EmailDeliveryStatus.SENT, clock.instant());
                    wave.sent++;
                    consecutiveRejects = 0;
                }
                case SKIPPED_ALLOWLIST -> {
                    campaigns.mark(campaign, r.getUserId(), EmailDeliveryStatus.SKIPPED, clock.instant());
                    wave.skipped++;
                }
                case RECIPIENT_REJECTED, EXHAUSTED -> {
                    campaigns.mark(campaign, r.getUserId(), EmailDeliveryStatus.FAILED, clock.instant());
                    wave.rejected++;
                    if (++consecutiveRejects >= config.maxConsecutiveRecipientFailures()) {
                        wave.failed++;
                        wave.error = consecutiveRejects + " adresses refusees d'affilee : vague arretee";
                        return;
                    }
                }
                case DUPLICATE -> {
                    boolean alreadySent = deliveries.findByKey(key).stream()
                            .anyMatch(d -> d.getStatus() == EmailDeliveryStatus.SENT);
                    if (alreadySent) {
                        campaigns.mark(campaign, r.getUserId(), EmailDeliveryStatus.SENT, clock.instant());
                        wave.alreadyServed++;
                    } else {
                        stopSystemic(campaign, r, wave, "DUPLICATE (envoi precedent encore PENDING)");
                        return;
                    }
                }
                default -> {
                    stopSystemic(campaign, r, wave, outcome.name());
                    return;
                }
            }
        }
    }

    private void stopSystemic(EmailCampaign campaign, Recipient r, Wave wave, String error) {
        campaigns.releaseAttempt(campaign, r.getUserId(), clock.instant());
        wave.failed++;
        wave.error = error;
    }

    /**
     * Confie le travail a l'executor email et attend au plus {@code waveWaitSeconds}.
     * Une seule vague (ou un seul test) a la fois.
     */
    private String await(EmailCampaign campaign, Wave wave, Runnable work) {
        if (!running.compareAndSet(false, true)) {
            throw new IllegalStateException("Une vague de campagne est deja en cours : reessayez plus tard");
        }
        Future<?> future;
        try {
            future = executor.submit(() -> {
                try {
                    work.run();
                } catch (RuntimeException e) {
                    wave.failed++;
                    wave.error = e.getClass().getSimpleName();
                    log.warn("Campagne {} interrompue : {}", campaign.code(), e.getClass().getSimpleName());
                } finally {
                    running.set(false);
                }
            });
        } catch (TaskRejectedException e) {
            running.set(false);
            throw new IllegalStateException("Executor email sature : reessayez plus tard");
        }
        try {
            future.get(config.waveWaitSeconds(), TimeUnit.SECONDS);
            return "COMPLETED";
        } catch (TimeoutException e) {
            return "IN_PROGRESS";
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            return "IN_PROGRESS";
        } catch (ExecutionException e) {
            return "STOPPED_ON_ERROR";
        }
    }

    private EmailCampaignRunResponse response(EmailCampaign campaign, Mode mode, String status, Wave wave) {
        List<String> sample = mode == Mode.DRY_RUN
                ? campaigns.findNext(campaign, config.maxAttemptsPerRecipient(), config.sampleSize()).stream()
                        .map(r -> LogMask.email(r.getEmail())).toList()
                : List.of();
        long neverAttempted = campaigns.countNeverAttempted(campaign);
        long retry = campaigns.countRetryable(campaign, config.maxAttemptsPerRecipient());
        return new EmailCampaignRunResponse(
                campaign.code(), mode.wire(), status,
                neverAttempted + retry, neverAttempted, retry,
                campaigns.countByStatus(campaign, EmailDeliveryStatus.SENT),
                campaigns.countByStatus(campaign, EmailDeliveryStatus.FAILED),
                wave.sent, wave.alreadyServed, wave.skipped, wave.rejected, wave.failed, wave.error,
                sample, config.waveSize(), config.pauseSeconds());
    }
}
