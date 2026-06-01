package com.sejourfr.app.dto;

import com.sejourfr.app.enums.EpreuveType;

import java.util.UUID;

/**
 * Vue front d'une {@link com.sejourfr.app.entity.ProductionTask}. La grille
 * d'evaluation n'est pas exposee au candidat : elle vit cote serveur dans
 * prompts/production-rubrics-&lt;version&gt;.json (par epreuve/tache).
 */
public record ProductionTaskDto(
        UUID id,
        EpreuveType epreuve,
        short tacheNumero,
        String niveauCible,
        String consigne,
        String contexte,
        Integer dureeMaxSec,
        Integer dureeMinSec,
        Integer motsMin,
        Integer motsMax
) {
}
