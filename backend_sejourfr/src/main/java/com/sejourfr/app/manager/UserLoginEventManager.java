package com.sejourfr.app.manager;

import com.sejourfr.app.entity.UserLoginEvent;
import com.sejourfr.app.repository.UserLoginEventRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/** Seule couche autorisee a toucher {@link UserLoginEventRepository}. */
@Component
@RequiredArgsConstructor
public class UserLoginEventManager {

    private final UserLoginEventRepository repository;

    public UserLoginEvent save(UserLoginEvent event) {
        return repository.save(event);
    }

    @Transactional(readOnly = true)
    public List<UserLoginEvent> findByUserId(UUID userId) {
        return repository.findByUserIdOrderByOccurredAtAsc(userId);
    }

    /** Un lot de purge, dans sa propre transaction. */
    @Transactional
    public int deleteOlderThan(Instant cutoff, int limit) {
        return repository.deleteOlderThan(cutoff, limit);
    }

    @Transactional
    public int deleteByUserId(UUID userId) {
        return repository.deleteByUserId(userId);
    }
}
