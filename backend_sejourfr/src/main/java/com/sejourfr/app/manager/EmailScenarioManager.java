package com.sejourfr.app.manager;

import com.sejourfr.app.repository.EmailScenarioRepository;
import com.sejourfr.app.repository.EmailScenarioRepository.AccessCandidate;
import com.sejourfr.app.repository.EmailScenarioRepository.UserCandidate;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/** Les candidats des scenarios ENGAGEMENT, page par page (cf. {@link EmailScenarioRepository}). */
@Component
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class EmailScenarioManager {

    /** Borne basse du jeu de cles : PostgreSQL compare les UUID octet par octet, non signes. */
    public static final UUID FIRST = new UUID(0L, 0L);

    private final EmailScenarioRepository repository;

    public List<UserCandidate> neverPremiumCreatedBetween(Instant from, Instant to, UUID after, int limit) {
        return repository.findNeverPremiumCreatedBetween(from, to, after, limit);
    }

    public List<UserCandidate> lastActivityBetween(Instant from, Instant to, UUID after, int limit) {
        return repository.findLastActivityBetween(from, to, after, limit);
    }

    public List<UserCandidate> withOpenPaidAccess(Instant now, UUID after, int limit) {
        return repository.findWithOpenPaidAccess(now, after, limit);
    }

    public List<AccessCandidate> oneTimeAccessEndingBetween(Instant from, Instant to, UUID after, int limit) {
        return repository.findOneTimeAccessEndingBetween(from, to, after, limit);
    }
}
