package com.sejourfr.app.dto;

import com.sejourfr.app.enums.SkillReferenceLevel;

/**
 * Une production de reference. Servie uniquement APRES que le candidat a rendu
 * sa propre production sur le sujet — la garde est serveur, pas seulement dans
 * l'interface.
 */
public record SkillReferenceDto(
        SkillReferenceLevel level,
        String text,
        /** Ce que cette reference demontre, adresse au candidat. */
        String pedagogicalNote
) {
}
