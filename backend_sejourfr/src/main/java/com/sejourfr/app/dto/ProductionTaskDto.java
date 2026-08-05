package com.sejourfr.app.dto;

import com.sejourfr.app.enums.EpreuveType;

import java.util.UUID;

/**
 * Vue front d'une {@link com.sejourfr.app.entity.ProductionTask}. La grille
 * d'evaluation n'est pas exposee au candidat : elle vit cote serveur dans
 * prompts/production-rubrics-&lt;version&gt;.json (par epreuve/tache).
 *
 * <p><b>La fiche de scenario T2</b> ({@code ProductionTask.agentRoleCard})
 * n'est deliberement PAS exposee : ses {@code valeur} sont les reponses que le
 * candidat doit obtenir en posant ses questions — les envoyer au client
 * reviendrait a lui donner le corrige. Elle ne sort du serveur que verrouillee
 * dans la system instruction de l'agent vocal (token ephemere). Ne rien ajouter
 * ici sans un besoin front precis, et jamais les {@code valeur}.
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
