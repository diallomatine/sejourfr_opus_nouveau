package com.sejourfr.app.dto;

import java.util.List;
import java.util.UUID;

/**
 * Vue front d'une situation = un SUJET d'entrainement (ex. "Vous etes
 * mecanicien, presentez-vous"), avec ses supports visuels. Les exemples-modeles
 * ne sont PAS imbriques ici : ils dependent de la tache, pas du sujet (cf.
 * {@link ProductionExampleDto} servi par /tasks/{id}/examples).
 * Le {@code niveauIndicatif} reste un simple repere, jamais un filtre bloquant.
 */
public record ProductionSituationDto(
        UUID id,
        UUID taskId,
        String titre,
        String contexte,
        String consigne,
        String roleCandidat,
        String roleExaminateur,
        String objectif,
        Declencheur declencheur,
        List<Etape> etapes,
        String niveauIndicatif,
        List<ProductionSituationMediaDto> medias
) {

    /** EE : message recu affiche avant la redaction. */
    public record Declencheur(String expediteur, String avatar, String texte) {
    }

    /** Plan d'aide : une etape = une icone + un titre + un texte d'aide. */
    public record Etape(String icon, String titre, String aide) {
    }
}
