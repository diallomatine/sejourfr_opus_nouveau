package com.sejourfr.app.dto;

import jakarta.validation.constraints.Size;

/**
 * Pose ou retire l'intitule editorial d'un sujet.
 *
 * <p>{@code null} ou blanc = <b>retirer le titre</b> (la colonne repasse a NULL
 * et les fronts retombent sur « Sujet N » + consigne). C'est la seule facon de
 * defaire un titre pose par erreur : sans cette semantique de remplacement, une
 * console ne saurait qu'ajouter.
 */
public record AdminProductionTaskTitreRequest(
        @Size(max = 80, message = "Le titre ne doit pas depasser 80 caracteres.")
        String titre
) {
}
