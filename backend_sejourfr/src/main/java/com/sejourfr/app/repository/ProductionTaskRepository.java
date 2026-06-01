package com.sejourfr.app.repository;

import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ProductionTaskRepository extends JpaRepository<ProductionTask, UUID> {

    /** Catalogue actif filtre par epreuve + niveau (lookup principal cote app). */
    List<ProductionTask> findByEpreuveAndNiveauCibleAndActiveTrueOrderByTacheNumeroAsc(
            EpreuveType epreuve, String niveauCible
    );

    /** Catalogue actif filtre par epreuve + niveau + numero de tache (hub d'entrainement). */
    List<ProductionTask> findByEpreuveAndNiveauCibleAndTacheNumeroAndActiveTrueOrderByCreatedAtAsc(
            EpreuveType epreuve, String niveauCible, Short tacheNumero
    );

    /** Catalogue actif filtre par epreuve + numero de tache, tous niveaux (entrainement
     *  par tache sans niveau impose). */
    List<ProductionTask> findByEpreuveAndTacheNumeroAndActiveTrueOrderByNiveauCibleAscCreatedAtAsc(
            EpreuveType epreuve, Short tacheNumero
    );

    /** Toutes les taches actives d'une epreuve (sans filtre niveau). */
    List<ProductionTask> findByEpreuveAndActiveTrueOrderByNiveauCibleAscTacheNumeroAsc(EpreuveType epreuve);

    /** Inclut les inactives : reserve a l'admin. */
    List<ProductionTask> findByEpreuveOrderByNiveauCibleAscTacheNumeroAsc(EpreuveType epreuve);

    /** Toutes les taches actives, tous epreuves/niveaux : validation des rubriques au boot. */
    List<ProductionTask> findByActiveTrue();
}
