package com.sejourfr.app.manager;

import com.sejourfr.app.entity.Question;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.repository.QuestionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Component;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Couche d'acces aux donnees pour {@link Question}.
 * N'expose que les operations utilisees par les services deja migres
 * (tirage runner / examen blanc).
 */
@Component
@RequiredArgsConstructor
public class QuestionManager {

    private final QuestionRepository repository;

    public Optional<Question> findById(UUID id) {
        return repository.findById(id);
    }

    public List<Question> findAllById(Collection<UUID> ids) {
        return repository.findAllById(ids);
    }

    public long countActiveByTheme(UUID themeId) {
        return repository.countByThemeIdAndActiveTrue(themeId);
    }

    /** Compteur total (inclut les questions inactives) — vue admin. */
    public long countByTheme(UUID themeId) {
        return repository.countByThemeId(themeId);
    }

    public long countByPassage(UUID passageId) {
        return repository.countByPassageId(passageId);
    }

    public long countByModule(Module module) {
        return repository.countByModule(module);
    }

    public long countByModuleAndActive(Module module, boolean active) {
        return repository.countByModuleAndActive(module, active);
    }

    /**
     * Compte des questions actives matchant un (module, theme?, difficulty?, questionType?).
     * Les parametres null sont ignores. Utilise par le suggesteur de composition
     * d'examen blanc et par LotService pour le decompte des lots disponibles.
     */
    public long countActiveMatching(Module module, UUID themeId, Difficulty difficulty, QuestionType questionType) {
        return repository.countActiveMatching(module, themeId, difficulty, questionType);
    }

    /** Pool demo fixe (ordre stable, meme serie a chaque rejouage). */
    public List<Question> findDemoPool(Module module, int size) {
        return repository.findDemoPool(module, PageRequest.of(0, size));
    }

    /** Tirage aleatoire (entrainement / examen blanc premium). */
    public List<Question> findRandom(
            Module module,
            UUID themeId,
            Difficulty difficulty,
            QuestionType questionType,
            int size) {
        return repository.findRandom(module, themeId, difficulty, questionType, PageRequest.of(0, size));
    }

    /**
     * Tirage d'une <b>serie ciblee</b> de comprehension : les questions du bon
     * domaine et du bon niveau que ce candidat a vues le moins recemment, les
     * jamais vues d'abord, departagees au hasard a fraicheur egale.
     *
     * <p>C'est le tirage des series lancees depuis une competence CO/CE du
     * Plan. Il remplace le tirage purement aleatoire, qui n'avait aucune memoire
     * et pouvait resservir la question de la veille pendant que 200 autres
     * n'avaient jamais ete vues.
     */
    public List<Question> findLeastRecentlySeen(
            UUID userId,
            Module module,
            Difficulty difficulty,
            QuestionType questionType,
            int size) {
        return repository.findLeastRecentlySeen(
                userId, module.name(), difficulty.name(), questionType.name(), size);
    }

    /** Tirage aleatoire en excluant des ids deja tires (composition examen blanc). */
    public List<Question> findRandomExcluding(
            Module module,
            UUID themeId,
            Difficulty difficulty,
            QuestionType questionType,
            Collection<UUID> excludeIds,
            int size) {
        return repository.findRandomExcluding(
                module, themeId, difficulty, questionType, excludeIds, PageRequest.of(0, size));
    }

    /** Tirage ordonne (deterministe) en excluant des ids deja tires (demo template). */
    public List<Question> findOrderedExcluding(
            Module module,
            UUID themeId,
            Difficulty difficulty,
            QuestionType questionType,
            Collection<UUID> excludeIds,
            int size) {
        return repository.findOrderedExcluding(
                module, themeId, difficulty, questionType, excludeIds, PageRequest.of(0, size));
    }

    /**
     * Recupere la fenetre de questions correspondant a un lot. Tri stable
     * {@code created_at ASC, id ASC} (memes critères que {@link LotService}),
     * pagination par {@code lotNumero - 1} comme index 0-based. Le pool est
     * filtre par {@code module + difficulty + questionType} (theme = null).
     */
    public List<Question> findLotQuestions(
            Module module,
            QuestionType questionType,
            Difficulty difficulty,
            int lotNumero,
            int lotSize) {
        return repository.findOrdered(
                module, null, difficulty, questionType, PageRequest.of(lotNumero - 1, lotSize));
    }

    /**
     * Variante Civique : fenêtre du lot sur le pool filtré par thème.
     * Tri stable identique à {@link LotService#listCivique}.
     */
    public List<Question> findLotQuestionsCivique(
            UUID themeId,
            int lotNumero,
            int lotSize) {
        return repository.findOrdered(
                Module.CIVIQUE, themeId, null, null, PageRequest.of(lotNumero - 1, lotSize));
    }

    // ------------------------------------------------------------------------
    // CRUD admin
    // ------------------------------------------------------------------------

    /** Recherche paginee avec specifications dynamiques (filtres admin). */
    public Page<Question> search(Specification<Question> spec, Pageable pageable) {
        return repository.findAll(spec, pageable);
    }

    public Question save(Question question) {
        return repository.save(question);
    }

    public boolean existsById(UUID id) {
        return repository.existsById(id);
    }

    public void deleteById(UUID id) {
        repository.deleteById(id);
    }
}
