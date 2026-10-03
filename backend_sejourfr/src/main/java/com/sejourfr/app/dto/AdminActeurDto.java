package com.sejourfr.app.dto;

import java.util.UUID;

/**
 * Un admin auteur d'une action (signalement…). {@code nom} = « Prénom Nom »,
 * {@code null} quand le compte n'en porte pas ; {@code email} {@code null} si le
 * compte n'existe plus.
 */
public record AdminActeurDto(UUID id, String email, String nom) {
}
