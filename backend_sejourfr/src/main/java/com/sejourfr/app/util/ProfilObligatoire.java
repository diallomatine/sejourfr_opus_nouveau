package com.sejourfr.app.util;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.ProfileField;
import com.sejourfr.app.enums.Role;

import java.util.ArrayList;
import java.util.List;

/**
 * <b>L'autorité unique</b> de « ce profil est-il complet ? », servie aux trois
 * fronts par {@code AuthenticatedUser.missingProfileFields} /
 * {@code profileIncomplete}. Aucun front ne décide seul qu'un {@code null}
 * rend un profil incomplet : il lit ce fait et affiche l'écran de complétion.
 *
 * <p>Obligatoire = ce que l'inscription locale demande : prénom, nom, démarche
 * visée. Un compte créé par Google ou Apple naît sans démarche (et, chez Apple,
 * parfois sans nom) : il répond aux mêmes questions à sa première connexion.
 * Un compte plus ancien au profil incomplet aussi, à sa prochaine connexion.
 *
 * <p>🛑 <b>{@code null} = inconnu.</b> Un champ manquant se DEMANDE au candidat,
 * il ne se remplit jamais d'une valeur par défaut (aucune démarche CSP
 * inventée, aucune migration de remplissage).
 *
 * <p>Un compte {@link Role#ADMIN} n'est pas un candidat : lui demander une
 * démarche serait inventer une donnée. Il n'a donc jamais de champ manquant.
 *
 * <p>Dérivé, jamais persisté : il se relit à chaque {@code /api/auth/me}.
 */
public final class ProfilObligatoire {

    private ProfilObligatoire() {
    }

    /** Les champs obligatoires absents, dans l'ordre du formulaire d'inscription. */
    public static List<ProfileField> champsManquants(User u) {
        List<ProfileField> manquants = new ArrayList<>();
        if (u.getRole() == Role.ADMIN) return List.copyOf(manquants);
        if (isBlank(u.getFirstName())) manquants.add(ProfileField.FIRST_NAME);
        if (isBlank(u.getLastName())) manquants.add(ProfileField.LAST_NAME);
        if (u.getTargetProcedure() == null) manquants.add(ProfileField.TARGET_PROCEDURE);
        return List.copyOf(manquants);
    }

    private static boolean isBlank(String s) {
        return s == null || s.isBlank();
    }
}
