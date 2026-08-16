package com.sejourfr.app.manager;

import com.sejourfr.app.entity.RealtimeSession;
import com.sejourfr.app.repository.RealtimeSessionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Optional;
import java.util.UUID;

/**
 * Couche d'acces aux donnees pour {@link RealtimeSession}.
 * Seule classe autorisee a appeler {@link RealtimeSessionRepository}.
 */
@Component
@RequiredArgsConstructor
public class RealtimeSessionManager {

    private final RealtimeSessionRepository repository;

    public RealtimeSession save(RealtimeSession session) {
        return repository.save(session);
    }

    public Optional<RealtimeSession> findById(UUID id) {
        return repository.findById(id);
    }

    /**
     * Lecture verrouillee, a utiliser des qu'on va ECRIRE sur la session : c'est
     * ce qui garantit qu'un slot n'est debite qu'une fois et qu'aucun tour de
     * transcript n'est perdu quand deux connexions du meme candidat se
     * chevauchent (reprise apres coupure). Exige une transaction ouverte.
     */
    public Optional<RealtimeSession> findByIdForUpdate(UUID id) {
        return repository.findByIdForUpdate(id);
    }
}
