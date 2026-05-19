package com.sejourfr.app.dto;

import com.sejourfr.app.enums.EpreuveType;

import java.util.UUID;

/**
 * Vue front d'une {@link com.sejourfr.app.entity.ProductionTask}. La grille
 * d'evaluation (criteresEvaluation) n'est volontairement pas exposee : elle
 * reste cote serveur pour ne pas donner d'indice sur la grille au candidat.
 */
public record ProductionTaskDto(
        UUID id,
        EpreuveType epreuve,
        short tacheNumero,
        String niveauCible,
        String consigne,
        String contexte,
        Integer dureeMaxSec,
        Integer motsMin,
        Integer motsMax
) {
}
