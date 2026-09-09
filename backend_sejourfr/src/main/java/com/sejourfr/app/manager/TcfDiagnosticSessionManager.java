package com.sejourfr.app.manager;

import com.sejourfr.app.entity.TcfDiagnosticSession;
import com.sejourfr.app.repository.TcfDiagnosticSessionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Seule couche autorisee a toucher {@link TcfDiagnosticSessionRepository}. */
@Component
@RequiredArgsConstructor
public class TcfDiagnosticSessionManager {

    private final TcfDiagnosticSessionRepository repository;

    public TcfDiagnosticSession save(TcfDiagnosticSession session) {
        return repository.save(session);
    }

    public Optional<TcfDiagnosticSession> findById(UUID id) {
        return repository.findByIdWithParent(id);
    }

    /** Le diagnostic le plus recent, ou vide si le candidat n'en a jamais ouvert. */
    public Optional<TcfDiagnosticSession> findLatest(UUID userId) {
        List<TcfDiagnosticSession> all = repository.findByUserOrderByStartedAtDesc(userId);
        return all.isEmpty() ? Optional.empty() : Optional.of(all.get(0));
    }

    public List<TcfDiagnosticSession> findAllByUser(UUID userId) {
        return repository.findByUserOrderByStartedAtDesc(userId);
    }

    /**
     * Le diagnostic <b>clos</b> qui precede {@code session}, le plus recent
     * d'abord. Sert a la comparaison de la boucle de reevaluation (L7).
     *
     * <p>Un diagnostic encore en cours n'est jamais un point de comparaison :
     * ses sections non faites rendraient des paliers nuls, et « non evaluee »
     * n'est pas un niveau d'ou l'on progresse.
     */
    public Optional<TcfDiagnosticSession> findPreviousCompleted(
            UUID userId, TcfDiagnosticSession session) {
        return repository.findByUserOrderByStartedAtDesc(userId).stream()
                .filter(d -> !d.getId().equals(session.getId()))
                .filter(d -> d.getCompletedAt() != null)
                .filter(d -> d.getStartedAt().isBefore(session.getStartedAt()))
                .findFirst();
    }

    public long countByUser(UUID userId) {
        return repository.countByUserId(userId);
    }
}
