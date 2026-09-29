package com.sejourfr.app.dto;

import com.sejourfr.app.enums.EpreuveType;

import java.util.UUID;

/**
 * Vue console d'un sujet de production (EO/EE). Contrairement a
 * {@link ProductionTaskDto}, elle inclut les sujets <b>desactives</b> et le
 * drapeau {@code active} : l'admin doit voir ce qu'il edite, meme depublie.
 *
 * <p>Lecture seule sur tout sauf le {@code titre} : cette surface existe pour
 * l'intitule editorial des cartes de sujet, pas pour un CRUD complet du
 * catalogue (consigne, bornes et fiche de scenario restent pilotees par les
 * migrations de contenu).
 */
public record AdminProductionTaskDto(
        UUID id,
        EpreuveType epreuve,
        short tacheNumero,
        String niveauCible,
        String titre,
        String consigne,
        String contexte,
        boolean active
) {
}
