package com.sejourfr.app.manager;

import com.sejourfr.app.entity.PurchaseIntent;
import com.sejourfr.app.repository.PurchaseIntentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

/** Seule couche autorisee a toucher {@link PurchaseIntentRepository}. */
@Component
@RequiredArgsConstructor
public class PurchaseIntentManager {

    private final PurchaseIntentRepository repository;

    public PurchaseIntent save(PurchaseIntent intent) {
        return repository.save(intent);
    }

    public Optional<PurchaseIntent> findById(UUID id) {
        return repository.findById(id);
    }

    /** Usage unique, atomique : {@code true} si l'appelant vient de la consommer. */
    public boolean consume(UUID id, UUID userId, String productId, Instant at, Instant now) {
        return repository.consume(id, userId, productId, at, now) == 1;
    }

    /** {@code journeyId} s'il existe et appartient a {@code userId}, vide sinon. */
    public Optional<UUID> ownedJourney(UUID journeyId, UUID userId) {
        if (journeyId == null || userId == null) return Optional.empty();
        return repository.ownedJourney(journeyId, userId).stream().findFirst();
    }
}
