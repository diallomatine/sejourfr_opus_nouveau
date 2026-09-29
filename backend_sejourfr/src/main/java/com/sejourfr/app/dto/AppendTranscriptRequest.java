package com.sejourfr.app.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.PositiveOrZero;

/**
 * Fragment de transcript relaye par le client au fil de la conversation. Le
 * client agrege les events de transcription (entree candidat + sortie
 * examinateur) et les pousse ici pour une capture serveur fiable du dialogue —
 * artefact de notation.
 *
 * @param speaker          {@code CANDIDATE} ou {@code EXAMINER}.
 * @param text             le texte du fragment.
 * @param turnIndex        index du tour, strictement croissant sur la duree de
 *                         la session ({@code 0, 1, 2…}), attribue par le client.
 *                         Rend l'appel IDEMPOTENT : un tour deja applique est
 *                         ignore, donc un reessai apres timeout reseau ne
 *                         duplique plus rien. {@code null} = comportement
 *                         historique (chaque appel ajoute une ligne) : les
 *                         clients qui ne l'envoient pas ne changent pas de
 *                         comportement, mais restent exposes au doublon.
 * @param resumptionHandle dernier handle de reprise reçu du fournisseur, s'il y
 *                         en a un de plus recent. Voyage ici plutot que dans un
 *                         appel dedie : le client POSTe deja regulierement, le
 *                         serveur reste a jour sans un aller-retour de plus.
 *                         {@code null} = rien de neuf a signaler.
 */
public record AppendTranscriptRequest(
        @NotBlank String speaker,
        @NotBlank String text,
        @PositiveOrZero Integer turnIndex,
        String resumptionHandle
) {}
