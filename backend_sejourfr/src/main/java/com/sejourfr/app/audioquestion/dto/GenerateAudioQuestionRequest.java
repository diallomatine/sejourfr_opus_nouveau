package com.sejourfr.app.audioquestion.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/**
 * Requete d'admin pour generer une question audio CO.
 * Seul `niveau` est obligatoire ; tout le reste est laisse au choix du LLM
 * si non fourni.
 */
public record GenerateAudioQuestionRequest(

    @NotNull(message = "Le niveau est obligatoire")
    @Pattern(regexp = "^(A2|B1|B2)$", message = "Le niveau doit etre A2, B1 ou B2")
    String niveau,

    @Pattern(
        regexp = "^(vie_pratique_logement|travail|sante|administratif|transports|consommation|medias_numerique|environnement)$",
        message = "Theme non autorise"
    )
    @Size(max = 64)
    String theme,

    @Pattern(
        regexp = "^(annonce|monologue|dialogue|interview|reportage)$",
        message = "Type de support non autorise"
    )
    String typeSouhaite,

    @Pattern(
        regexp = "^co_(reperage_explicite|detail_specifique|idee_principale|inference_intention|ton_attitude|reformulation)$",
        message = "Code competence non autorise"
    )
    @Size(max = 64)
    String competenceVisee,

    @Size(max = 500, message = "Les consignes specifiques sont limitees a 500 caracteres")
    String consignesSpecifiques
) {}
