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
    public long countEligible(EmailCampaign campaign) {
        return repository.countEligible(campaign.code());
    }

    @Transactional(readOnly = true)
    public List<Recipient> findEligible(EmailCampaign campaign, int limit) {
        return repository.findEligible(campaign.code(), limit);
    }

    @Transactional(readOnly = true)
    public long countByStatus(EmailCampaign campaign, EmailDeliveryStatus status) {
        return repository.countByStatus(campaign.code(), status.name());
    }

    /** @return vrai si le compte est reserve pour cet envoi, faux s'il est deja servi */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public boolean claim(EmailCampaign campaign, UUID userId, Instant now) {
        return repository.claim(UUID.randomUUID(), campaign.code(), userId, now) == 1;
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void mark(EmailCampaign campaign, UUID userId, EmailDeliveryStatus status, Instant now) {
        repository.mark(campaign.code(), userId, status.name(), now);
    }
}
