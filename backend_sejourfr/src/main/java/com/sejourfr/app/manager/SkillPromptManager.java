package com.sejourfr.app.manager;

import com.sejourfr.app.entity.SkillPrompt;
import com.sejourfr.app.entity.SkillReference;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.repository.SkillPromptRepository;
import com.sejourfr.app.repository.SkillReferenceRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/**
 * Couche d'acces aux donnees de l'agregat « petit sujet » : le sujet
 * ({@link SkillPrompt}) et ses productions de reference
 * ({@link SkillReference}), qui n'existent jamais sans lui. Seule classe
 * autorisee a appeler {@link SkillPromptRepository} et
 * {@link SkillReferenceRepository}.
 */
@Component
@RequiredArgsConstructor
public class SkillPromptManager {

    private final SkillPromptRepository repository;
    private final SkillReferenceRepository referenceRepository;

    public Optional<SkillPrompt> findById(UUID id) {
        return repository.findById(id);
    }

    /**
     * Sujet actif + sa competence chargee, la competence devant elle aussi etre
     * active : desactiver une competence doit retirer ses sujets de la vue du
     * candidat sans avoir a desactiver les cinq lignes une par une.
     */
    public Optional<SkillPrompt> findActiveByIdWithSkill(UUID id) {
        return repository.findByIdWithSkill(id)
                .filter(p -> p.isActive() && p.getSkill().isActive());
    }

    public Optional<SkillPrompt> findByIdWithSkill(UUID id) {
        return repository.findByIdWithSkill(id);
    }

    public Optional<SkillPrompt> findByCode(String code) {
        return repository.findByCode(code);
    }

    /** Les sujets actifs d'une competence, dans l'ordre d'affichage. */
    public List<SkillPrompt> findActiveBySkillId(UUID skillId) {
        return repository.findBySkillIdAndActiveTrueOrderByDisplayOrderAsc(skillId);
    }

    /**
     * Nombre de sujets actifs par competence active, pour un ensemble de taches.
     * Les competences sans sujet actif sont absentes de la map : c'est a
     * l'appelant, qui connait la liste des competences a afficher, de combler a
     * zero.
     */
    public Map<UUID, Long> countActiveBySkillForTaskCodes(Collection<SkillTaskCode> taskCodes) {
        Map<UUID, Long> counts = new HashMap<>();
        // Un IN vide est un SQL invalide : on n'interroge pas la base pour rien.
        if (taskCodes.isEmpty()) return counts;
        for (Object[] row : repository.countActiveBySkillForTaskCodes(taskCodes)) {
            counts.put((UUID) row[0], ((Number) row[1]).longValue());
        }
        return counts;
    }

    /**
     * Tous les sujets d'une competence, <b>desactives compris</b>, dans l'ordre
     * d'affichage. Vue admin : la console doit pouvoir rouvrir un sujet retire
     * du catalogue, donc le voir.
     */
    public List<SkillPrompt> findAllBySkillId(UUID skillId) {
        return repository.findBySkillIdOrderByDisplayOrderAsc(skillId);
    }

    /** Nombre de sujets d'une competence, desactives compris (compteur admin). */
    public long countBySkillId(UUID skillId) {
        return repository.countBySkillId(skillId);
    }

    /**
     * Nombre de sujets par competence, desactives compris. Les competences sans
     * aucun sujet sont <b>presentes a zero</b> : la console affiche « 0 sujet »
     * plutot qu'une case vide sur une competence toute neuve.
     */
    public Map<UUID, Long> countBySkillIds(Collection<UUID> skillIds) {
        Map<UUID, Long> counts = new HashMap<>();
        for (UUID id : skillIds) {
            counts.put(id, 0L);
        }
        // Un IN vide est un SQL invalide : on n'interroge pas la base pour rien.
        if (skillIds.isEmpty()) return counts;
        for (Object[] row : repository.countBySkillIds(skillIds)) {
            counts.put((UUID) row[0], ((Number) row[1]).longValue());
        }
        return counts;
    }

    public boolean existsByCode(String code) {
        return repository.existsByCode(code);
    }

    public SkillPrompt save(SkillPrompt prompt) {
        return repository.save(prompt);
    }

    /**
     * Suppression definitive d'un sujet. Ses references partent en cascade en
     * base ; ses tentatives aussi, d'ou le controle prealable de l'appelant.
     */
    public void delete(SkillPrompt prompt) {
        repository.delete(prompt);
    }

    // ------------------------------------------------------------------------
    // References (memes agregat que le sujet)
    // ------------------------------------------------------------------------

    /**
     * Les 3 references d'un sujet dans l'ordre pedagogique impose
     * (insuffisante -&gt; attendue -&gt; tres reussie). Le tri est fait ICI, en
     * memoire, sur l'ordinal de l'enum : la colonne etant un varchar, un
     * {@code ORDER BY} SQL trierait alphabetiquement et montrerait le meilleur
     * modele avant l'attendu.
     */
    public List<SkillReference> findReferencesByPromptId(UUID promptId) {
        return referenceRepository.findBySkillPromptId(promptId).stream()
                .sorted(Comparator.comparingInt(r -> r.getLevel().ordinal()))
                .toList();
    }

    /**
     * Les references de plusieurs sujets, indexees par sujet et triees dans le
     * meme ordre pedagogique que {@link #findReferencesByPromptId}. Les sujets
     * sans reference sont <b>presents avec une liste vide</b> : la console
     * affiche « A completer » au lieu de casser sur une absence de cle.
     */
    public Map<UUID, List<SkillReference>> findReferencesByPromptIds(Collection<UUID> promptIds) {
        Map<UUID, List<SkillReference>> byPrompt = new HashMap<>();
        for (UUID id : promptIds) {
            byPrompt.put(id, new ArrayList<>());
        }
        // Un IN vide est un SQL invalide : on n'interroge pas la base pour rien.
        if (promptIds.isEmpty()) return byPrompt;
        for (SkillReference reference : referenceRepository.findBySkillPromptIdIn(promptIds)) {
            byPrompt.computeIfAbsent(reference.getSkillPrompt().getId(), k -> new ArrayList<>())
                    .add(reference);
        }
        for (List<SkillReference> refs : byPrompt.values()) {
            refs.sort(Comparator.comparingInt(r -> r.getLevel().ordinal()));
        }
        return byPrompt;
    }

    public SkillReference saveReference(SkillReference reference) {
        return referenceRepository.save(reference);
    }

    /**
     * Efface les references d'un sujet, <b>immediatement</b> (edition admin).
     *
     * <p>Le {@code flush} n'est pas une precaution : il est indispensable. Une
     * suppression derivee ne fait qu'empiler des retraits dans la file d'actions
     * d'Hibernate, et cette file execute TOUS les inserts avant les deletes. Le
     * remplacement des trois references — supprimer puis reinserer les memes
     * niveaux — violait donc {@code uq_skill_references_prompt_level} : les
     * nouvelles lignes arrivaient avant le depart des anciennes. Vider la file
     * ici retablit l'ordre voulu par l'appelant.
     */
    public void deleteReferencesByPromptId(UUID promptId) {
        referenceRepository.deleteBySkillPromptId(promptId);
        referenceRepository.flush();
    }

    public long countReferencesByPromptId(UUID promptId) {
        return referenceRepository.countBySkillPromptId(promptId);
    }
}
