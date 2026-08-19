package com.sejourfr.app.manager;

import com.sejourfr.app.entity.LegacyPassCompensation;
import com.sejourfr.app.repository.LegacyPassCompensationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.List;

/** Couche d'accès aux données pour {@link LegacyPassCompensation}. */
@Component
@RequiredArgsConstructor
public class LegacyPassCompensationManager {

    private final LegacyPassCompensationRepository repository;

    /** Destinataires restants de l'e-mail d'annonce (comptes supprimés exclus). */
    public List<LegacyPassCompensation> findAEnvoyer() {
        return repository.findAEnvoyer();
    }

    public long countTotal() {
        return repository.count();
    }

    public long countDejaEnvoyes() {
        return repository.countByMailedAtIsNotNull();
    }

    public LegacyPassCompensation save(LegacyPassCompensation compensation) {
        return repository.save(compensation);
    }
}
