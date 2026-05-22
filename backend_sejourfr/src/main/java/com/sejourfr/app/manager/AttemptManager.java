package com.sejourfr.app.manager;

import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.repository.AttemptRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Component;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/**
 * Couche d'acces aux donnees pour {@link Attempt}.
 * Seule classe autorisee a appeler {@link AttemptRepository}.
 */
@Component
@RequiredArgsConstructor
public class AttemptManager {

    private final AttemptRepository repository;

    public Attempt save(Attempt attempt) {
        return repository.save(attempt);
    }

    public Optional<Attempt> findById(UUID id) {
        return repository.findById(id);
    }

    public long countByUserId(UUID userId) {
        return repository.countByUserId(userId);
    }

    public long countByExamTemplateId(UUID examTemplateId) {
        return repository.countByExamTemplateId(examTemplateId);
    }

    /**
     * Lookup sécurisé d'un attempt guest : exige user IS NULL ET même IP.
     */
    public Optional<Attempt> findGuestByIdAndIp(UUID id, String clientIp) {
        return repository.findByIdAndClientIpAndUserIsNull(id, clientIp);
    }

    /**
     * Historique utilisateur filtre, plafonne par {@code limit}. Le filtre
     * {@code moduleExamQuestionType} permet d'isoler les examens module TCF
     * (CO ou CE) ; null pour la requete generale.
     */
    public List<Attempt> findByUserFiltered(
            UUID userId,
            AttemptType type,
            Module module,
            QuestionType moduleExamQuestionType,
            int limit) {
        return repository.findByUserFiltered(
                userId, type, module, moduleExamQuestionType, PageRequest.of(0, limit));
    }

    /**
     * Pour un user + (module, questionType, difficulty), renvoie le dernier
     * attempt fini par numero de lot (cle = lot_numero, valeur = attempt le
     * plus recent). Renvoie une map vide si aucun lot n'a ete fini.
     */
    public Map<Integer, Attempt> findLastFinishedByLots(
            UUID userId, Module module, QuestionType questionType, Difficulty difficulty) {
        List<Attempt> attempts = repository.findFinishedByUserAndLot(
                userId, module, questionType, difficulty);
        // Repository trie par finishedAt DESC → premier rencontre pour chaque
        // lot_numero = le plus recent. putIfAbsent garantit qu'on ne l'ecrase pas.
        Map<Integer, Attempt> latest = new HashMap<>();
        for (Attempt a : attempts) {
            if (a.getLotNumero() != null) {
                latest.putIfAbsent(a.getLotNumero(), a);
            }
        }
        return latest;
    }

    /**
     * Variante Civique : pour un user + thème, renvoie le dernier attempt
     * fini par numéro de lot. Cle = lot_numero, valeur = attempt le plus
     * recent. Sert à enrichir `GET /api/lots?module=CIVIQUE&themeId=...`.
     */
    public Map<Integer, Attempt> findLastFinishedByLotsCivique(UUID userId, UUID themeId) {
        List<Attempt> attempts = repository.findFinishedByUserAndLotCivique(userId, themeId);
        Map<Integer, Attempt> latest = new HashMap<>();
        for (Attempt a : attempts) {
            if (a.getLotNumero() != null) {
                latest.putIfAbsent(a.getLotNumero(), a);
            }
        }
        return latest;
    }

    /** Sous-attempts d'un examen blanc complet, ordre de création (= ordre des épreuves). */
    public List<Attempt> findSubAttempts(UUID parentAttemptId) {
        return repository.findByParentAttemptIdOrderByStartedAtAsc(parentAttemptId);
    }

    /**
     * Lookup avec parent eager-loaded. Utilisé hors transaction longue pour
     * pouvoir lire {@code parentAttempt.epreuve} sans LazyInitializationException
     * (cf. {@code ProductionEvaluationService.finishSubAttemptIfFullExam}).
     */
    public Optional<Attempt> findByIdWithParent(UUID id) {
        return repository.findByIdWithParent(id);
    }

    /** Historique des examens blancs TCF complets d'un user (parent TCF_COMPLET uniquement). */
    public List<Attempt> findByUserAndEpreuve(UUID userId, EpreuveType epreuve, int limit) {
        return repository.findByUserAndEpreuve(userId, epreuve, PageRequest.of(0, limit));
    }
}
