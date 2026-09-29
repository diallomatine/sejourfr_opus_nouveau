package com.sejourfr.app.service.email;

import com.sejourfr.app.dto.EmailPreferencesDto;
import com.sejourfr.app.dto.UpdateEmailPreferencesRequest;
import com.sejourfr.app.entity.UserEmailPreference;
import com.sejourfr.app.manager.UserEmailPreferenceManager;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

/**
 * Les preferences email d'un compte : lecture (valeurs par defaut si aucune
 * ligne), modification depuis « Notifications par e-mail », desabonnement par
 * lien. La ligne nait a la premiere modification (brief §4).
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class EmailPreferenceService {

    private final UserEmailPreferenceManager manager;
    private final Clock clock;

    @Transactional(readOnly = true)
    public EmailPreferencesDto get(UUID userId) {
        Optional<UserEmailPreference> p = manager.find(userId);
        return new EmailPreferencesDto(
                p.map(UserEmailPreference::isEngagementEnabled).orElse(UserEmailPreference.ENGAGEMENT_PAR_DEFAUT),
                p.map(UserEmailPreference::isMarketingEnabled).orElse(UserEmailPreference.MARKETING_PAR_DEFAUT));
    }

    @Transactional
    public EmailPreferencesDto update(UUID userId, UpdateEmailPreferencesRequest request) {
        if (request.engagementEnabled() == null && request.marketingEnabled() == null) {
            return get(userId);
        }
        Instant now = clock.instant();
        UserEmailPreference p = loadOrNew(userId, now);
        if (request.engagementEnabled() != null) {
            p.setEngagementEnabled(request.engagementEnabled());
        }
        if (request.marketingEnabled() != null) {
            boolean optIn = request.marketingEnabled() && !p.isMarketingEnabled();
            p.setMarketingEnabled(request.marketingEnabled());
            // Preuve datee du consentement : posee a l'opt-in, conservee ensuite.
            if (optIn) {
                p.setMarketingConsentAt(now);
            }
        }
        p.setUpdatedAt(now);
        manager.save(p);
        return new EmailPreferencesDto(p.isEngagementEnabled(), p.isMarketingEnabled());
    }

    /** Le lien de desabonnement : ENGAGEMENT seulement, jamais REQUIRED. */
    @Transactional
    public void disableEngagement(UUID userId) {
        update(userId, new UpdateEmailPreferencesRequest(false, null));
        log.info("Rappels d'entrainement desactives par lien de desabonnement (user={})", userId);
    }

    private UserEmailPreference loadOrNew(UUID userId, Instant now) {
        return manager.find(userId).orElseGet(() -> {
            UserEmailPreference created = new UserEmailPreference();
            created.setUserId(userId);
            created.setCreatedAt(now);
            return created;
        });
    }
}
