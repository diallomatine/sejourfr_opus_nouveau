package com.sejourfr.app.service.plancivique;

import java.time.Instant;
import java.util.UUID;

/**
 * Une réponse civique du candidat, réduite à ce dont le moteur a besoin.
 *
 * <p>🛑 <b>Toutes les réponses comptent, quelle que soit leur provenance</b> :
 * diagnostic, série ciblée, examen blanc. {@code 20_} §8.2 est explicite —
 * « chaque réponse d'examen blanc alimente les boîtes Leitner exactement comme
 * une série ciblée ». Filtrer une source ici rendrait le plan sourd à la moitié
 * de ce que le candidat produit.
 *
 * @param notionId   la notion <b>validée</b> de la question, ou {@code null} si
 *                   elle n'est pas encore taguée — {@code null} veut dire
 *                   « pas encore », jamais « hors programme »
 * @param themeId    le thème, toujours présent : c'est le grain de repli
 * @param correcte   {@code null} en base signifie « non corrigée » ; l'appelant
 *                   ne construit une {@code CivicReponse} que pour une réponse
 *                   réellement corrigée
 * @param repondueA  l'instant de la réponse. C'est l'<b>ordre</b> qui construit
 *                   la boîte : deux réponses inversées donnent deux boîtes
 *                   différentes
 */
public record CivicReponse(
        UUID notionId,
        UUID themeId,
        boolean correcte,
        Instant repondueA
) {
}
