package com.sejourfr.app.manager;

import com.sejourfr.app.enums.EmailCampaign;
import com.sejourfr.app.enums.EmailDeliveryStatus;
import com.sejourfr.app.repository.EmailCampaignRepository;
import com.sejourfr.app.repository.EmailCampaignRepository.Recipient;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Le journal des campagnes de service ({@code email_campaign_log}). Ecritures en
 * {@code REQUIRES_NEW} comme {@link EmailDeliveryManager} : l'etat d'un compte
 * servi ne depend jamais d'une transaction appelante.
 */
@Component
@RequiredArgsConstructor
public class EmailCampaignManager {

    private final EmailCampaignRepository repository;

    @Transactional(readOnly = true)
    public long countNeverAttempted(EmailCampaign campaign) {
        return repository.countNeverAttempted(campaign.code());
    }

    @Transactional(readOnly = true)
    public long countRetryable(EmailCampaign campaign, int maxAttempts) {
        return repository.countRetryable(campaign.code(), maxAttempts);
    }

    /**
     * Les prochains destinataires : les comptes jamais tentes ; s'il n'en reste
     * aucun, les comptes a reprendre (« a la fin »).
     */
    @Transactional(readOnly = true)
    public List<Recipient> findNext(EmailCampaign campaign, int maxAttempts, int limit) {
        List<Recipient> fresh = repository.findNeverAttempted(campaign.code(), limit);
        return fresh.isEmpty() ? repository.findRetryable(campaign.code(), maxAttempts, limit) : fresh;
    }

    @Transactional(readOnly = true)
    public long countByStatus(EmailCampaign campaign, EmailDeliveryStatus status) {
        return repository.countByStatus(campaign.code(), status.name());
    }

    /** @return vrai si le compte est reserve pour cet envoi, faux s'il est deja servi */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public boolean claim(EmailCampaign campaign, UUID userId, Instant now, int maxAttempts) {
        return repository.claim(UUID.randomUUID(), campaign.code(), userId, now, maxAttempts) == 1;
    }

    /** Echec systemique : FAILED, sans imputer la tentative au compte. */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void releaseAttempt(EmailCampaign campaign, UUID userId, Instant now) {
        repository.releaseAttempt(campaign.code(), userId, now);
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void mark(EmailCampaign campaign, UUID userId, EmailDeliveryStatus status, Instant now) {
        repository.mark(campaign.code(), userId, status.name(), now);
    }
}
