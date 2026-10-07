package com.sejourfr.app.manager;

import com.sejourfr.app.repository.AdminProductionReadRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Lectures sans effet de bord de la console admin « Productions IA ». */
@Component
@RequiredArgsConstructor
public class AdminProductionReadManager {

    private final AdminProductionReadRepository repository;

    /**
     * Critères déjà validés par le service ; {@code null} = pas de filtre.
     *
     * @param source          {@code ASYNC | REALTIME} (filtre « Examinateur IA »)
     * @param etatSignalement {@code AUCUN | SIGNALE | VERIFIE}
     */
    public record Criteres(
            boolean includeInternal,
            UUID qUuid,
            String qPattern,
            String epreuve,
            Integer tache,
            String source,
            Instant fromTs,
            Instant toTs,
            String niveau,
            String statut,
            String etatSignalement,
            Boolean annotee
    ) {}

    public List<AdminProductionReadRepository.Ligne> findPage(Criteres c, String sort, int limit, long offset) {
        return repository.findPage(c.includeInternal(), null, c.qUuid(), c.qPattern(), c.epreuve(), c.tache(), c.source(),
                c.fromTs(), c.toTs(), c.niveau(), c.statut(), c.etatSignalement(), c.annotee(),
                sort, limit, offset);
    }

    public long count(Criteres c) {
        return repository.count(c.includeInternal(), null, c.qUuid(), c.qPattern(), c.epreuve(), c.tache(), c.source(),
                c.fromTs(), c.toTs(), c.niveau(), c.statut(), c.etatSignalement(), c.annotee());
    }

    /**
     * Compteurs du périmètre, une requête. {@code qUuid} : id utilisateur (ou de
     * production), comme la recherche de la liste ; bornes {@code null} = aucune.
     */
    public AdminProductionReadRepository.Compteurs compter(boolean includeInternal, UUID qUuid,
                                                           Instant fromTs, Instant toTs) {
        return repository.compter(includeInternal, null, qUuid, null, null, null, null, fromTs, toTs);
    }

    /**
     * La ligne d'UNE production du périmètre, comptes internes compris : la même
     * expression que la liste pour le statut IA et le signalement. Vide si la
     * production n'existe pas ou sort du périmètre (diagnostic…).
     */
    public Optional<AdminProductionReadRepository.Ligne> findLigne(UUID submissionId) {
        return repository.findPage(true, submissionId, null, null, null, null, null, null, null,
                null, null, null, null, "DATE_DESC", 1, 0).stream().findFirst();
    }
}
