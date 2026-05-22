package com.sejourfr.app.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * Payload pour POST /api/contact. Endpoint **public** (pas d'auth requise) :
 * un utilisateur non connecté doit pouvoir nous joindre via le formulaire.
 * Le sujet est libre (et non un enum) pour rester souple côté UX, mais on
 * cape la taille pour éviter qu'on s'en serve comme champ libre indésirable.
 */
public record ContactRequest(
        @NotBlank @Size(max = 120) String name,
        @NotBlank @Email @Size(max = 255) String email,
        @NotBlank @Size(max = 200) String subject,
        @NotBlank @Size(max = 4000) String message
) {}
