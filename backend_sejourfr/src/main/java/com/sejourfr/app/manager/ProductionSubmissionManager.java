package com.sejourfr.app.manager;

import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.SubmissionStatut;
import com.sejourfr.app.repository.ProductionSubmissionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.Collection;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Couche d'acces aux donnees pour {@link ProductionSubmission}.
 * Seule classe autorisee a appeler {@link ProductionSubmissionRepository}.
 */
@Component
@RequiredArgsConstructor
public class ProductionSubmissionManager {

    private final ProductionSubmissionRepository repository;

    public Optional<ProductionSubmission> findById(UUID id) {
        return repository.findById(id);
    }

    /** Submission avec sa {@code productionTask} eager-loadée (retry hors session Hibernate). */
    public Optional<ProductionSubmission> findByIdWithTask(UUID id) {
        return repository.findByIdWithTask(id);
    }

    /** Submission avec sa {@code productionTask} ET son {@code user} eager-loadés. */
    public Optional<ProductionSubmission> findByIdWithTaskAndUser(UUID id) {
        return repository.findByIdWithTaskAndUser(id);
    }

    /**
     * Soumission deja rendue sous cette cle d'idempotence (V046), tache et
     * attempt charges. Vide = premiere soumission sous cette cle.
     */
    public Optional<ProductionSubmission> findByClientKey(UUID userId, UUID clientSubmissionId) {
        if (clientSubmissionId == null) {
            return Optional.empty();
        }
        return repository.findByUserAndClientSubmissionId(userId, clientSubmissionId);
    }

    public ProductionSubmission save(ProductionSubmission submission) {
        return repository.save(submission);
    }

    /** Toutes les submissions liées à un attempt EE/EO (utile pour assembler un examen blanc complet). */
    public List<ProductionSubmission> findByAttemptId(UUID attemptId) {
        return repository.findByAttemptIdOrderBySubmittedAtAsc(attemptId);
    }

    /**
     * Les submissions de plusieurs attempts, <b>groupées par attempt</b>, en une
     * seule requête et avec leur {@code productionTask} jointe — cf. le javadoc
     * de la requête : c'est ce qui rend constant le coût du profil TCF.
     *
     * <p>Aucun accès base sur une liste vide : le candidat qui n'a passé aucune
     * épreuve ne paie rien.
     */
    public Map<UUID, List<ProductionSubmission>> findByAttemptIdsGrouped(Collection<UUID> attemptIds) {
        if (attemptIds == null || attemptIds.isEmpty()) return Map.of();
        return repository.findByAttemptIdsWithTask(attemptIds).stream()
                .collect(Collectors.groupingBy(s -> s.getAttempt().getId()));
    }

    /**
     * Les <b>identifiants</b> des soumissions de plusieurs attempts, en une
     * requete et sans charger d'entite. Aucun acces base sur une liste vide.
     */
    public List<UUID> findIdsByAttemptIds(Collection<UUID> attemptIds) {
        if (attemptIds == null || attemptIds.isEmpty()) return List.of();
        return repository.findIdsByAttemptIds(attemptIds);
    }

    /**
     * L'attempt de chacune de ces soumissions, en une requete. Une soumission
     * sans attempt (entrainement libre) est simplement absente du resultat.
     */
    public Map<UUID, UUID> findAttemptIdBySubmissionIds(Collection<UUID> submissionIds) {
        if (submissionIds == null || submissionIds.isEmpty()) return Map.of();
        Map<UUID, UUID> parSoumission = new LinkedHashMap<>();
        for (Object[] ligne : repository.findAttemptIdsBySubmissionIds(submissionIds)) {
            if (ligne.length < 2 || ligne[0] == null || ligne[1] == null) continue;
            parSoumission.put((UUID) ligne[0], (UUID) ligne[1]);
        }
        return parSoumission;
    }

    /** Soumissions déjà faites sur une tâche précise d'une session (plafond d'examen). */
    public long countByAttemptAndTache(UUID attemptId, short tacheNumero) {
        return repository.countByAttemptAndTache(attemptId, tacheNumero);
    }

    public long countByAttempt(UUID attemptId) { return repository.countByAttemptId(attemptId); }

    /** Tâches distinctes soumises dans un attempt, restreint à son épreuve. */
    public long countDistinctTachesByAttemptAndEpreuve(UUID attemptId, EpreuveType epreuve) {
        return repository.countDistinctTachesByAttemptAndEpreuve(attemptId, epreuve);
    }

    /**
     * Sujets de production deja rendus par ce candidat, avec la date de leur
     * derniere soumission. Une requete, quel que soit le nombre de competences
     * a resoudre.
     */
    public Map<UUID, Instant> findLastSubmittedAtByTask(UUID userId) {
        Map<UUID, Instant> out = new HashMap<>();
        for (Object[] row : repository.findLastSubmittedAtByTask(userId)) {
            if (row.length < 2 || row[0] == null) continue;
            out.put((UUID) row[0], (Instant) row[1]);
        }
        return out;
    }

    public long countByUserAndEpreuve(UUID userId, EpreuveType epreuve) {
        return repository.countByUserAndEpreuve(userId, epreuve);
    }

    /** Soumissions d'entrainement seules (hors sessions d'examen blanc). */
    public long countTrainingByUserAndEpreuve(UUID userId, EpreuveType epreuve) {
        return repository.countTrainingByUserAndEpreuve(userId, epreuve);
    }

    /** Historique utilisateur, tri descendant, plafonne par {@code limit}. */
    public List<ProductionSubmission> findRecentByUser(UUID userId, int limit) {
        return repository.findStandardByUser(userId, PageRequest.of(0, limit));
    }

    /** Historique utilisateur filtre par epreuve, tri descendant, plafonne par {@code limit}. */
    public List<ProductionSubmission> findRecentByUserAndEpreuve(UUID userId, EpreuveType epreuve, int limit) {
        return repository.findByUserAndEpreuve(userId, epreuve, PageRequest.of(0, limit));
    }

    /** 0 a 3 lignes : derniere submission par numero de tache (hub d'entrainement). */
    public List<ProductionSubmission> findLatestPerTask(UUID userId, EpreuveType epreuve, String niveauCible) {
        return repository.findLatestPerTask(userId, epreuve.name(), niveauCible);
    }

    /** Submissions par statut, tri par date de soumission asc (calibration admin). */
    public List<ProductionSubmission> findByStatutOrderedBySubmittedAt(SubmissionStatut statut) {
        return repository.findStandardByStatut(statut);
    }
}
