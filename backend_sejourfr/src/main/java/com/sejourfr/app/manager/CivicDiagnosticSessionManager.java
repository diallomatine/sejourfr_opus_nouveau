package com.sejourfr.app.manager;

import com.sejourfr.app.entity.CivicDiagnosticSession;
import com.sejourfr.app.repository.CivicDiagnosticSessionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Seule couche autorisee a toucher {@link CivicDiagnosticSessionRepository}. */
@Component
@RequiredArgsConstructor
public class CivicDiagnosticSessionManager {

    private final CivicDiagnosticSessionRepository repository;

    public CivicDiagnosticSession save(CivicDiagnosticSession session) {
        return repository.save(session);
    }

    public Optional<CivicDiagnosticSession> findById(UUID id) {
        return repository.findByIdWithAttempt(id);
    }

    /**
     * Tous les diagnostics d'un candidat, du plus recent au plus ancien.
     *
     * <p>Sert l'ecran Progres (T28), qui trace l'historique des scores. La
     * requete est deja bornee par la nature de l'objet : un diagnostic civique
     * ne se relance qu'apres un delai.
     */
    public List<CivicDiagnosticSession> findAllByUser(UUID userId) {
        return repository.findByUserOrderByStartedAtDesc(userId);
    }

    /** Le diagnostic le plus recent, ou vide si le candidat n'en a jamais ouvert. */
    public Optional<CivicDiagnosticSession> findLatest(UUID userId) {
        List<CivicDiagnosticSession> all = repository.findByUserOrderByStartedAtDesc(userId);
        return all.isEmpty() ? Optional.empty() : Optional.of(all.getFirst());
    }

    public long countByUser(UUID userId) {
        return repository.countByUserId(userId);
    }
}
