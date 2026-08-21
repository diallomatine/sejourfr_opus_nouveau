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
import java.util.LinkedHashMap;
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

    /**
     * Resolution en lot de codes editoriaux, indexee par code. Les codes
     * inconnus sont simplement absents de la map — un code que le correcteur a
     * invente n'existe pas, il ne doit pas faire echouer la lecture.
     */
    public Map<String, Skill> findByCodes(Collection<String> codes) {
        Map<String, Skill> bySkillCode = new LinkedHashMap<>();
        // Un IN vide est un SQL invalide : on n'interroge pas la base pour rien.
        if (codes.isEmpty()) return bySkillCode;
        for (Skill skill : repository.findByCodeIn(codes)) {
            bySkillCode.put(skill.getCode(), skill);
        }
        return bySkillCode;
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
     * La premiere competence active de chaque tache, indexee par tache. Une
     * tache sans aucune competence active est simplement absente de la map.
     *
     * <p>Une seule requete de 6 lignes : c'est le socle du verrou freemium du
     * module, evalue a chaque ecran.
     */
    public Map<SkillTaskCode, UUID> findFirstActiveIdPerTaskCode() {
        Map<SkillTaskCode, UUID> firstIds = new EnumMap<>(SkillTaskCode.class);
        for (Object[] row : repository.findFirstActiveIdPerTaskCode()) {
            firstIds.put((SkillTaskCode) row[0], (UUID) row[1]);
        }
        return firstIds;
    }

    /**
     * La premiere competence active de chaque domaine de COMPREHENSION, indexee
     * par domaine. Un domaine sans competence active est simplement absent de
     * la map.
     *
     * <p>Une seule requete de deux lignes au plus : c'est le pendant du verrou
     * freemium pour les competences sans tache.
     */
    public Map<SkillSection, UUID> findFirstActiveIdPerComprehensionSection() {
        Map<SkillSection, UUID> firstIds = new EnumMap<>(SkillSection.class);
        for (Object[] row : repository.findFirstActiveIdPerComprehensionSection()) {
            firstIds.put((SkillSection) row[0], (UUID) row[1]);
        }
        return firstIds;
    }

    /**
     * Toutes les competences SANS tache d'un domaine, <b>desactivees
     * comprises</b>. Pendant de {@link #findAllByTaskCode} pour la
     * comprehension : l'admin y verifie qu'un rang d'affichage est libre.
     */
    public List<Skill> findAllComprehensionBySection(SkillSection section) {
        return repository.findBySectionAndTaskCodeIsNullOrderByDisplayOrderAsc(section);
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
