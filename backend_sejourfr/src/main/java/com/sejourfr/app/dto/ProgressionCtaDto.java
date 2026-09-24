package com.sejourfr.app.dto;

/**
 * Le bouton « Nouvel examen blanc » d'un écran de progression.
 *
 * <p>🛑 <b>Arbitrage D20 du 2026-09-24</b> : tous les RÉSULTATS sont visibles
 * d'un compte gratuit ; seul ce bouton peut porter un cadenas. Il est servi
 * pour que les fronts ne le déduisent pas.
 *
 * @param locked {@code true} quand la grille ouverte par ce bouton n'offre plus
 *               rien que ce candidat puisse lancer ou faire corriger sans
 *               abonnement. Lu chez les jumelles en lecture des verrous
 *               serveur, jamais recalculé
 */
public record ProgressionCtaDto(boolean locked) {
}
