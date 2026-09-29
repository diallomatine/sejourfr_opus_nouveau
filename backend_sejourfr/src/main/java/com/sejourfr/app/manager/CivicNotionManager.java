package com.sejourfr.app.manager;

import com.sejourfr.app.entity.CivicNotion;
import com.sejourfr.app.enums.NotionSuggestionVerdict;
import com.sejourfr.app.repository.CivicNotionRepository;
import com.sejourfr.app.repository.QuestionNotionSuggestionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Seule couche autorisee a toucher les depots de notions civiques (L8). */
@Component
@RequiredArgsConstructor
public class CivicNotionManager {

    private final CivicNotionRepository repository;
    private final QuestionNotionSuggestionRepository suggestionRepository;

    public List<CivicNotion> findAllOrdonnees() {
        return repository.findAllOrdonnees();
    }

    public Optional<CivicNotion> findByCode(String code) {
        return repository.findByCode(code);
    }

    public Optional<CivicNotion> findById(UUID id) {
        return repository.findById(id);
    }

    public List<Object[]> couvertureParNotionEtMention() {
        return repository.couvertureParNotionEtMention();
    }

    public List<Object[]> suggestionsParNotion() {
        return repository.suggestionsParNotion();
    }

    public List<Object[]> suggestionsParQuestions(Collection<UUID> questionIds) {
        return questionIds.isEmpty() ? List.of() : suggestionRepository.parQuestions(questionIds);
    }

    public List<Object[]> choixDesQuestions(Collection<UUID> questionIds) {
        return questionIds.isEmpty() ? List.of() : repository.choixDesQuestions(questionIds);
    }

    /**
     * La suggestion la mieux notee d'une question, en <b>trois</b> etats
     * distincts (V057).
     *
     * @see MeilleureSuggestion
     */
    public MeilleureSuggestion meilleureSuggestion(UUID questionId) {
        List<Object[]> rows = suggestionRepository.meilleureSuggestion(questionId);
        if (rows.isEmpty()) return MeilleureSuggestion.AUCUNE_LIGNE;
        return new MeilleureSuggestion(true, (UUID) rows.get(0)[1]);
    }

    /**
     * <b>Trois cas, jamais deux</b> — la lecture qui distingue ce que le
     * pre-tagging a dit d'une question (V057).
     *
     * <ul>
     *   <li>{@link #AUCUNE_LIGNE} — la question n'a pas ete pre-taguee. Il n'y
     *       a rien a qualifier, et aucun verdict a inscrire.</li>
     *   <li>{@code existe} + {@code notionId} nul — le modele a conclu
     *       qu'<b>aucune notion du referentiel ne convient</b>. C'est un
     *       verdict, pas une absence : c'est lui qui revele un trou du
     *       referentiel.</li>
     *   <li>{@code existe} + {@code notionId} renseigne — la notion proposee.</li>
     * </ul>
     *
     * <p>🛑 Un {@code Optional<UUID>} confondait les deux premiers : les deux
     * rendaient {@code empty()}, et « le modele n'a rien dit » devenait
     * indiscernable de « le modele a dit non ». La metrique de qualite du
     * modele se lit sur cette difference.
     *
     * @param existe une ligne de suggestion a bien ete trouvee
     * @param notionId la notion proposee, {@code null} pour « aucune notion »
     */
    public record MeilleureSuggestion(boolean existe, UUID notionId) {

        /** Aucune campagne n'a tourne sur cette question. */
        public static final MeilleureSuggestion AUCUNE_LIGNE =
                new MeilleureSuggestion(false, null);

        /** Le modele a conclu qu'aucune notion du referentiel ne convient. */
        public boolean conclutAucuneNotion() {
            return existe && notionId == null;
        }

        /**
         * La meilleure suggestion designe-t-elle <b>cette</b> notion ?
         *
         * <p>🛑 Faux quand elle conclut « aucune notion » : poser une notion
         * alors que le modele disait non, c'est le CORRIGER, pas le valider.
         */
        public boolean designe(UUID candidate) {
            return existe && candidate != null && candidate.equals(notionId);
        }
    }

    /**
     * Inscrit le verdict de relecture sur toutes les suggestions de la question.
     *
     * @return le nombre de lignes marquees ; <b>0 est normal</b> tant qu'aucune
     *         campagne de pre-tagging n'a tourne
     */
    public int marquerVerdict(UUID questionId, NotionSuggestionVerdict verdict, UUID relecteurId) {
        return suggestionRepository.marquerVerdict(questionId, verdict.name(), relecteurId);
    }

    public boolean existeQuestionCivique(UUID questionId) {
        return repository.existeQuestionCivique(questionId);
    }

    public List<Object[]> fileDeTagging(
            String theme, Boolean tagged, Boolean suggerees, int limit, int offset) {
        return repository.fileDeTagging(theme, tagged, suggerees, limit, offset);
    }

    public long resteATaguer() {
        return repository.resteATaguer();
    }

    /** {@code notion} nul efface le tag : se tromper doit rester rattrapable. */
    public int poserNotion(UUID questionId, CivicNotion notion) {
        return repository.poserNotion(questionId, notion);
    }
}
