package com.sejourfr.app.repository;

import com.sejourfr.app.entity.CivicOfficialUnit;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

/**
 * Les <b>16 unites du programme officiel</b> de l'examen civique (V068 / V115).
 *
 * <p>🛑 <b>LECTURE SEULE, et c'est le garde-fou 1 de D-38.</b> Aucune ecriture
 * n'est exposee, et aucun endpoint d'administration n'existe : la table est
 * seedee par migration, et une valeur d'arrete ne se modifie pas depuis une
 * interface. {@link JpaRepository} apporte {@code save} et {@code delete} par
 * heritage — ils ne doivent jamais etre appeles sur cette entite.
 */
@Repository
public interface CivicOfficialUnitRepository extends JpaRepository<CivicOfficialUnit, UUID> {

    /**
     * Les 16 unites dans l'ordre du programme : thematique par thematique, puis
     * l'ordre de l'annexe I a l'interieur de chacune.
     *
     * <p>🛑 L'ordre des thematiques vient de {@code themes.display_order}, seule
     * autorite — le recopier ici en ferait une 2<sup>e</sup> declaration.
     */
    @Query("""
            SELECT u FROM CivicOfficialUnit u
            WHERE u.themeCode IN (
                SELECT t.code FROM Theme t WHERE t.module = com.sejourfr.app.enums.Module.CIVIQUE)
            ORDER BY (SELECT t.displayOrder FROM Theme t WHERE t.code = u.themeCode),
                     u.displayOrder
            """)
    List<CivicOfficialUnit> findAllDansLOrdreDuProgramme();
}
