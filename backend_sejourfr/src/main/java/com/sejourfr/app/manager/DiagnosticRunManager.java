package com.sejourfr.app.manager;

import com.sejourfr.app.entity.DiagnosticRun;
import com.sejourfr.app.enums.DiagnosticRunType;
import com.sejourfr.app.repository.DiagnosticRunRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collection;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

/** Seule couche autorisee a toucher {@link DiagnosticRunRepository}. */
@Component
@RequiredArgsConstructor
public class DiagnosticRunManager {

    private final DiagnosticRunRepository repository;

    /**
     * Type serveur des runs qui existent parmi {@code ids}. Une run absente de la
     * map n'existe pas. Une seule requete, quelle que soit la taille du lot.
     */
    @Transactional(readOnly = true)
    public Map<UUID, DiagnosticRunType> typesByIds(Collection<UUID> ids) {
        Map<UUID, DiagnosticRunType> types = new HashMap<>();
        if (ids == null || ids.isEmpty()) return types;
        for (DiagnosticRunRepository.RunType row : repository.findTypesByIdIn(ids)) {
            types.put(row.getId(), row.getType());
        }
        return types;
    }

    @Transactional
    public DiagnosticRun save(DiagnosticRun run) {
        return repository.save(run);
    }
}
