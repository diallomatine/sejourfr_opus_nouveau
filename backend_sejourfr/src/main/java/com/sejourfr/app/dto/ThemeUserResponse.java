package com.sejourfr.app.dto;

import com.sejourfr.app.enums.Module;

import java.util.UUID;

/**
 * Vue user d'un thème : ne contient pas le 'questionCount' admin
 * (mais le frontend peut s'en servir donc on l'inclut quand même).
 */
public record ThemeUserResponse(
        UUID id,
        Module module,
        String code,
        String name,
        String description,
        int displayOrder,
        int questionCount
) {}
