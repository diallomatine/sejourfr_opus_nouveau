package com.sejourfr.app.manager;

import com.sejourfr.app.dto.LigneStrateQcm;
import com.sejourfr.app.dto.StrateQcm;
import com.sejourfr.app.entity.AttemptQuestion;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.repository.AttemptQuestionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Couche d'acces aux donnees pour {@link AttemptQuestion}.
 */
@Component
@RequiredArgsConstructor
public class AttemptQuestionManager {

    private final AttemptQuestionRepository repository;

    public AttemptQuestion save(AttemptQuestion aq) {
        return repository.save(aq);
    }

    public Optional<AttemptQuestion> findById(UUID id) {
        return repository.findById(id);
    }
    /**
     * Items poses et reussis d'un attempt, ventiles par palier
     * ({@code [Difficulty, posés, réussis]}). Sert au calcul de niveau du
     * diagnostic TCF, qui lit un taux PAR PALIER et jamais sur le total.
     */
    public java.util.List<Object[]> aggregateByDifficulty(UUID attemptId) {
        return repository.aggregateByDifficulty(attemptId);
    }

    /** {@code [themeId, QuestionType, poses, reussis]} — diagnostic civique (L9). */
    public java.util.List<Object[]> aggregateByThemeAndType(UUID attemptId) {
        return repository.aggregateByThemeAndType(attemptId);
    }


    public List<AttemptQuestion> findByAttemptOrderedByPosition(UUID attemptId) {
        return repository.findByAttemptIdOrderByPositionAsc(attemptId);
    }

    /**
     * 🛑 <b>Le seul acces aux donnees du niveau QCM.</b> Items poses et reussis
     * de TOUTES les tentatives demandees, en <b>une requete</b>, ventiles par
     * epreuve et par palier.
     *
     * <p>Appele avec la page entiere (historique, profil, « Voir mes
     * resultats », liste des examens blancs) : le niveau n'etant plus persiste,
     * une boucle d'appels unitaires ferait un N+1 sur chaque ecran de liste.
     *
     * <p>Liste vide en entree ⇒ liste vide en sortie, <b>sans requete</b> : un
     * {@code IN ()} vide n'a rien a demander.
     */
    public List<LigneStrateQcm> stratesParAttempt(Collection<UUID> attemptIds) {
        if (attemptIds == null || attemptIds.isEmpty()) return List.of();
        List<Object[]> rows = repository.aggregateStratesByAttempts(attemptIds);
        List<LigneStrateQcm> out = new java.util.ArrayList<>(rows.size());
        for (Object[] r : rows) {
            out.add(new LigneStrateQcm(
                    (UUID) r[0],
                    (QuestionType) r[1],
                    new StrateQcm(
                            (Difficulty) r[2],
                            ((Number) r[3]).intValue(),
                            r[4] == null ? 0 : ((Number) r[4]).intValue(),
                            r[5] == null ? 0 : ((Number) r[5]).intValue())));
        }
        return out;
    }
}
