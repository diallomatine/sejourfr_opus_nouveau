package com.sejourfr.app.repository;

import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ProductionTaskRepository extends JpaRepository<ProductionTask, UUID> {

    /** Catalogue actif filtre par epreuve + niveau (lookup principal cote app). */
    List<ProductionTask> findByEpreuveAndNiveauCibleAndActiveTrueAndDiagnosticCodeIsNullOrderByTacheNumeroAsc(
            EpreuveType epreuve, String niveauCible
    );

    /** Catalogue actif filtre par epreuve + niveau + numero de tache (hub d'entrainement). */
    List<ProductionTask> findByEpreuveAndNiveauCibleAndTacheNumeroAndActiveTrueAndDiagnosticCodeIsNullOrderByCreatedAtAsc(
            EpreuveType epreuve, String niveauCible, Short tacheNumero
    );

    /** Catalogue actif filtre par epreuve + numero de tache, tous niveaux (entrainement
     *  par tache sans niveau impose). */
    List<ProductionTask> findByEpreuveAndTacheNumeroAndActiveTrueAndDiagnosticCodeIsNullOrderByNiveauCibleAscCreatedAtAsc(
            EpreuveType epreuve, Short tacheNumero
    );

    /** Toutes les taches actives d'une epreuve (sans filtre niveau). */
    List<ProductionTask> findByEpreuveAndActiveTrueAndDiagnosticCodeIsNullOrderByNiveauCibleAscTacheNumeroAsc(
            EpreuveType epreuve);

    /** Inclut les inactives : reserve a l'admin. */
    List<ProductionTask> findByEpreuveOrderByNiveauCibleAscTacheNumeroAsc(EpreuveType epreuve);

    /** Toutes les taches actives, tous epreuves/niveaux : validation des rubriques au boot. */
    List<ProductionTask> findByActiveTrueAndDiagnosticCodeIsNull();

    /** Sujet diagnostic actif d'une modalité/version, hors tirage aléatoire. */
    Optional<ProductionTask> findByDiagnosticCodeAndDiagnosticVersionAndEpreuveAndActiveTrue(
            String diagnosticCode, Integer diagnosticVersion, EpreuveType epreuve);

    /**
     * Le <b>pool</b> de sujets diagnostic d'une modalité/version (L3).
     *
     * <p>Le diagnostic rapide tire au sort parmi plusieurs énoncés du même
     * patron. L'ordre est <b>déterministe</b> ({@code created_at}, puis
     * {@code id} pour départager) : le tirage se fait ensuite explicitement, il
     * ne doit jamais dépendre de l'ordre que Postgres a bien voulu rendre.
     *
     * <p>Le variant {@code Optional} ci-dessus reste utilisé partout où le
     * couple (code, version, épreuve) n'a qu'une ligne — il lèverait sinon
     * {@code IncorrectResultSizeDataAccessException}.
     */
    List<ProductionTask> findByDiagnosticCodeAndDiagnosticVersionAndEpreuveAndActiveTrueOrderByCreatedAtAscIdAsc(
            String diagnosticCode, Integer diagnosticVersion, EpreuveType epreuve);

    /** Version active la plus récente du diagnostic, déterminée par le contenu. */
    @Query("""
            SELECT MAX(t.diagnosticVersion) FROM ProductionTask t
            WHERE t.diagnosticCode = :code AND t.active = true
            """)
    Optional<Integer> findLatestActiveDiagnosticVersion(@Param("code") String code);
}
