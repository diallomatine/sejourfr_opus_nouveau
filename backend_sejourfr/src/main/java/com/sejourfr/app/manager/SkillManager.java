package com.sejourfr.app.manager;

import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.repository.SkillRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Component;

import java.util.Collection;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/**
 * Couche d'acces aux donnees pour {@link Skill} (les micro-competences).
 * Seule classe autorisee a appeler {@link SkillRepository}.
 */
@Component
@RequiredArgsConstructor
public class SkillManager {

    private final SkillRepository repository;

    public Optional<Skill> findById(UUID id) {
        return repository.findById(id);
    }

    /** Variante filtrant les competences desactivees : vue du candidat. */
    public Optional<Skill> findActiveById(UUID id) {
        return repository.findById(id).filter(Skill::isActive);
    }

    public Optional<Skill> findByCode(String code) {
        return repository.findByCode(code);
    }

    /** Les 8 competences actives d'une tache, dans l'ordre pedagogique. */
    public List<Skill> findActiveByTaskCode(SkillTaskCode taskCode) {
        return repository.findByTaskCodeAndActiveTrueOrderByDisplayOrderAsc(taskCode);
    }

    /**
     * Toutes les competences d'une tache, <b>desactivees comprises</b>. Reserve
     * a l'admin : le candidat ne doit jamais voir une competence retiree du
     * catalogue.
     */
    public List<Skill> findAllByTaskCode(SkillTaskCode taskCode) {
        return repository.findByTaskCodeOrderByDisplayOrderAsc(taskCode);
    }

    /** Toutes les competences actives d'une epreuve (ses 3 taches). */
    public List<Skill> findActiveBySection(SkillSection section) {
        return repository.findBySectionAndActiveTrueOrderByTaskCodeAscDisplayOrderAsc(section);
    }

    /**
     * Nombre de competences actives par tache, <b>toutes les taches demandees
     * etant presentes</b> (0 si aucune competence active). Le comblement est
     * fait ici et non chez l'appelant pour qu'une epreuve pas encore seedee
     * s'affiche « 0 competence » au lieu de disparaitre de l'ecran.
     */
    public Map<SkillTaskCode, Long> countActiveByTaskCode(Collection<SkillTaskCode> taskCodes) {
        Map<SkillTaskCode, Long> counts = new EnumMap<>(SkillTaskCode.class);
        for (SkillTaskCode code : taskCodes) {
            counts.put(code, 0L);
        }
        // Un IN vide est un SQL invalide : on n'interroge pas la base pour rien.
        if (taskCodes.isEmpty()) return counts;
        for (Object[] row : repository.countActiveByTaskCodes(taskCodes)) {
            counts.put((SkillTaskCode) row[0], ((Number) row[1]).longValue());
        }
        return counts;
    }

    /**
     * Toutes les competences d'une epreuve, <b>desactivees comprises</b>, dans
     * l'ordre d'affichage de la console. {@code null} = toutes les epreuves.
     * Reserve a l'admin (statistiques).
     */
    public List<Skill> findAllForAdmin(SkillSection section) {
        return section == null
                ? repository.findAllByOrderByTaskCodeAscDisplayOrderAsc()
                : repository.findBySectionOrderByTaskCodeAscDisplayOrderAsc(section);
    }

    /** Recherche paginee et filtree de la console admin. */
    public Page<Skill> findAll(Specification<Skill> spec, Pageable pageable) {
        return repository.findAll(spec, pageable);
    }

    /** Le code editorial est unique : verifie avant insertion, pour un refus lisible. */
    public boolean existsByCode(String code) {
        return repository.existsByCode(code);
    }

    public Skill save(Skill skill) {
        return repository.save(skill);
    }

    /**
     * Suppression definitive. Les sujets et leurs references partent en cascade
     * <b>en base</b> ({@code ON DELETE CASCADE}) : c'est precisement pour cela
     * que l'appelant doit d'abord verifier qu'aucune tentative candidat n'est
     * rattachee.
     */
    public void delete(Skill skill) {
        repository.delete(skill);
    }
}
