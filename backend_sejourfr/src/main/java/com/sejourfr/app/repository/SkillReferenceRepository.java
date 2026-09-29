package com.sejourfr.app.repository;

import com.sejourfr.app.entity.SkillReference;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;
import java.util.UUID;

@Repository
public interface SkillReferenceRepository extends JpaRepository<SkillReference, UUID> {

    /**
     * Les 3 references d'un sujet, <b>sans ordre garanti</b> : le tri
     * pedagogique (INSUFFICIENT, EXPECTED, EXCELLENT) est applique par le
     * manager. Il ne peut pas l'etre ici parce que {@code level} est persiste en
     * varchar : un {@code ORDER BY level} trierait alphabetiquement et placerait
     * « EXCELLENT » avant « EXPECTED », donc le meilleur modele avant l'attendu.
     */
    List<SkillReference> findBySkillPromptId(UUID skillPromptId);

    /**
     * Les references de plusieurs sujets d'un coup — la console admin affiche
     * un badge « 3/3 » sur chacun des sujets d'une competence, ce qui ferait
     * autant de requetes que de sujets. Ordre non garanti ici non plus : c'est
     * le manager qui trie.
     */
    List<SkillReference> findBySkillPromptIdIn(Collection<UUID> skillPromptIds);

    /** Remplacement atomique des 3 references d'un sujet (edition admin). */
    void deleteBySkillPromptId(UUID skillPromptId);

    long countBySkillPromptId(UUID skillPromptId);
}
