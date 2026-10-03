package com.sejourfr.app.manager;

import com.sejourfr.app.entity.UserActivityDay;
import com.sejourfr.app.enums.ClientPlatform;
import com.sejourfr.app.repository.UserActivityDayRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/** Seule couche autorisee a toucher {@link UserActivityDayRepository}. */
@Component
@RequiredArgsConstructor
public class UserActivityManager {

    private final UserActivityDayRepository repository;

    /** Upsert de la presence (une ligne par compte × jour × plateforme). */
    @Transactional
    public void touch(UUID userId, LocalDate day, ClientPlatform platform, Instant at) {
        repository.touch(userId, day, platform.name(), at);
    }

    @Transactional(readOnly = true)
    public List<UserActivityDay> findByUserId(UUID userId) {
        return repository.findByIdUserId(userId);
    }

    /** Un lot de purge, dans sa propre transaction. */
    @Transactional
    public int deleteBefore(LocalDate before, int limit) {
        return repository.deleteBefore(before, limit);
    }

    @Transactional
    public int deleteByUserId(UUID userId) {
        return repository.deleteByUserId(userId);
    }
}
