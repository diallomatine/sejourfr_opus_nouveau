package com.sejourfr.app.manager;

import com.sejourfr.app.entity.UserSkillAttempt;
import com.sejourfr.app.enums.SkillCriterionStatus;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.repository.UserSkillAttemptRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Component;

import java.util.Collection;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/**
 * Couche d'acces aux donnees pour {@link UserSkillAttempt} (les productions des
 * candidats). Seule classe autorisee a appeler
 * {@link UserSkillAttemptRepository}.
 *
 * <p>Les methodes « derniere tentative par sujet » renvoient une map indexee
 * par identifiant de sujet : c'est la forme dont les services ont besoin pour
 * deriver un statut sujet par sujet, et cela absorbe ici le cas — theorique —
 * de deux tentatives portant exactement le meme instant de creation.
 */
@Component
@RequiredArgsConstructor
public class UserSkillAttemptManager {

    private final UserSkillAttemptRepository repository;

    public Optional<UserSkillAttempt> findById(UUID id) {
        return repository.findById(id);
    }

    /** Tentative + sujet + competence charges : lecture hors session Hibernate. */
    public Optional<UserSkillAttempt> findByIdWithPrompt(UUID id) {
        return repository.findByIdWithPrompt(id);
    }

    /**
     * Production deja rendue sous cette cle d'idempotence (V046), sujet charge.
     * Vide = premiere production sous cette cle.
     */
    public Optional<UserSkillAttempt> findByClientKey(UUID userId, UUID clientSubmissionId) {
        if (clientSubmissionId == null) {
            return Optional.empty();
        }
        return repository.findByUserAndClientSubmissionId(userId, clientSubmissionId);
    }

    public UserSkillAttempt save(UserSkillAttempt attempt) {
        return repository.save(attempt);
    }

    /**
     * Analyses IA deja consommees par l'utilisateur, a vie. Compte les analyses
     * DEMANDEES (donc acceptees), pas les analyses reussies.
     */
    public long countAnalysesRequested(UUID userId) {
        return repository.countByUserIdAndAnalysisRequestedTrue(userId);
    }

    /** Le candidat a-t-il deja produit sur ce sujet ? (garde des references) */
    public boolean hasAttempted(UUID userId, UUID promptId) {
        return repository.existsByUserIdAndSkillPromptId(userId, promptId);
    }

    public long countByUserAndPrompt(UUID userId, UUID promptId) {
        return repository.countByUserIdAndSkillPromptId(userId, promptId);
    }

    /** Historique du candidat sur un sujet, plus recente d'abord, plafonne. */
    public List<UserSkillAttempt> findByUserAndPrompt(UUID userId, UUID promptId, int limit) {
        return repository.findByUserIdAndSkillPromptIdOrderByCreatedAtDesc(
                userId, promptId, PageRequest.of(0, limit));
    }

    /** Derniere tentative du candidat sur un sujet : c'est elle qui donne le statut. */
    public Optional<UserSkillAttempt> findLatestByUserAndPrompt(UUID userId, UUID promptId) {
        return repository.findFirstByUserIdAndSkillPromptIdOrderByCreatedAtDesc(userId, promptId);
    }

    /** Derniere tentative par sujet sur les taches demandees, indexee par sujet. */
    public Map<UUID, UserSkillAttempt> findLatestPerPromptByTaskCodes(
            UUID userId, Collection<SkillTaskCode> taskCodes) {
        if (taskCodes.isEmpty()) return Map.of();
        return index(repository.findLatestPerPromptByTaskCodes(userId, taskCodes));
    }

    /** Derniere tentative par sujet d'une competence, indexee par sujet. */
    public Map<UUID, UserSkillAttempt> findLatestPerPromptBySkill(UUID userId, UUID skillId) {
        return index(repository.findLatestPerPromptBySkill(userId, skillId));
    }

    /**
     * Derniere tentative par sujet sur un ensemble de competences, indexee par
     * sujet. Une seule requete quel que soit le nombre de competences : c'est
     * ce qui evite un N+1 aux ecrans qui melangent des competences sans rapport
     * de tache (le Plan).
     */
    public Map<UUID, UserSkillAttempt> findLatestPerPromptBySkillIds(
            UUID userId, Collection<UUID> skillIds) {
        if (skillIds.isEmpty()) return Map.of();
        return index(repository.findLatestPerPromptBySkillIds(userId, skillIds));
    }

    /** Nombre de tentatives par sujet sur les taches demandees. */
    public Map<UUID, Long> countPerPromptByTaskCodes(UUID userId, Collection<SkillTaskCode> taskCodes) {
        if (taskCodes.isEmpty()) return Map.of();
        return toCountMap(repository.countPerPromptByTaskCodes(userId, taskCodes));
    }

    /** Nombre de tentatives par sujet d'une competence. */
    public Map<UUID, Long> countPerPromptBySkill(UUID userId, UUID skillId) {
        return toCountMap(repository.countPerPromptBySkill(userId, skillId));
    }

    /** Un sujet ayant recu au moins une production ne peut plus etre supprime. */
    public boolean existsForPrompt(UUID promptId) {
        return repository.existsBySkillPromptId(promptId);
    }

    /**
     * Une competence dont N'IMPORTE LEQUEL des sujets a recu une production ne
     * peut plus etre supprimee : la suppression emporterait ses sujets en
     * cascade, donc l'historique du candidat.
     */
    public boolean existsForSkill(UUID skillId) {
        return repository.existsBySkillPromptSkillId(skillId);
    }

    /** Tentatives sur un sujet, tous candidats confondus (compteur admin). */
    public long countByPrompt(UUID promptId) {
        return repository.countBySkillPromptId(promptId);
    }

    /**
     * Tentatives par sujet, tous candidats confondus. Les sujets sans tentative
     * sont <b>presents a zero</b> : la console affiche « 0 tentative » plutot
     * qu'une case vide.
     */
    public Map<UUID, Long> countPerPromptForPromptIds(Collection<UUID> promptIds) {
        Map<UUID, Long> counts = new HashMap<>();
        for (UUID id : promptIds) {
            counts.put(id, 0L);
        }
        if (promptIds.isEmpty()) return counts;
        for (Object[] row : repository.countPerPromptForPromptIds(promptIds)) {
            counts.put((UUID) row[0], ((Number) row[1]).longValue());
        }
        return counts;
    }

    /**
     * Statistiques d'usage par competence, tous candidats confondus. Les
     * competences sans tentative sont presentes avec un agregat a zero, dont un
     * {@code validatedRate} nul : « aucune analyse » et « 0 % de validation »
     * ne racontent pas la meme chose, et seul le premier est vrai d'une
     * competence que personne n'a encore travaillee.
     */
    public Map<UUID, SkillUsage> aggregateUsageBySkillIds(Collection<UUID> skillIds) {
        Map<UUID, SkillUsage> usage = new HashMap<>();
        for (UUID id : skillIds) {
            usage.put(id, SkillUsage.EMPTY);
        }
        if (skillIds.isEmpty()) return usage;
        for (Object[] row : repository.aggregateStatsBySkillIds(skillIds, SkillCriterionStatus.VALIDATED)) {
            usage.put((UUID) row[0], new SkillUsage(
                    ((Number) row[1]).longValue(),
                    ((Number) row[2]).longValue(),
                    ((Number) row[3]).longValue()));
        }
        return usage;
    }

    /**
     * Agregat d'usage d'une competence. {@code analysed} ne compte que les
     * tentatives PORTANT UN VERDICT, pas celles ayant demande une analyse : une
     * analyse partie en echec a consomme le quota du candidat mais n'a rien
     * juge, et l'inclure ferait baisser le taux de validation pour une panne
     * fournisseur.
     */
    public record SkillUsage(long attempts, long analysed, long validated) {
        public static final SkillUsage EMPTY = new SkillUsage(0, 0, 0);
    }

    private static Map<UUID, UserSkillAttempt> index(List<UserSkillAttempt> attempts) {
        Map<UUID, UserSkillAttempt> byPrompt = new LinkedHashMap<>();
        for (UserSkillAttempt a : attempts) {
            // putIfAbsent : deux tentatives au meme createdAt exact sur un meme
            // sujet ressortiraient toutes les deux de la requete. On en garde
            // une seule — laquelle importe peu, elles sont contemporaines.
            byPrompt.putIfAbsent(a.getSkillPrompt().getId(), a);
        }
        return byPrompt;
    }

    private static Map<UUID, Long> toCountMap(List<Object[]> rows) {
        Map<UUID, Long> counts = new HashMap<>();
        for (Object[] row : rows) {
            counts.put((UUID) row[0], ((Number) row[1]).longValue());
        }
        return counts;
    }
}
