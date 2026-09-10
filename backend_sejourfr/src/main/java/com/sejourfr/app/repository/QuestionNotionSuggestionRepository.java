package com.sejourfr.app.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;
import java.util.UUID;

/**
 * Les propositions de tagging d'une machine (V051, lot L8).
 *
 * <p>🛑 <b>Aucune de ces lignes ne vaut decision.</b> Le tag qui fait foi est
 * {@code questions.civic_notion_id}, pose par un humain. « Le job propose, un
 * humain valide » ({@code 50_} §6.1.3).
 *
 * <p>🛑 <b>Cette table est creee VIDE</b> et rien dans le depot ne la
 * remplit : la remplir coute un appel LLM paye pour 1 016 questions, et c'est
 * une decision du proprietaire.
 */
@Repository
public interface QuestionNotionSuggestionRepository
        extends JpaRepository<com.sejourfr.app.entity.CivicNotion, UUID> {

    /** Les suggestions de PLUSIEURS questions, en une requete : l'ecran en affiche 25 d'un coup. */
    @Query(value = """
            SELECT s.question_id, n.code, n.label, s.confidence
            FROM question_notion_suggestions s
                     JOIN civic_notions n ON n.id = s.notion_id
            WHERE s.question_id IN (:questionIds)
            ORDER BY s.question_id, s.confidence DESC
            """, nativeQuery = true)
    List<Object[]> parQuestions(@Param("questionIds") Collection<UUID> questionIds);
}
