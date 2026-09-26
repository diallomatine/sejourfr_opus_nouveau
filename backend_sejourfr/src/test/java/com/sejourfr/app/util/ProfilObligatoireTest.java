package com.sejourfr.app.util;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AuthProvider;
import com.sejourfr.app.enums.ProfileField;
import com.sejourfr.app.enums.Role;
import com.sejourfr.app.enums.TargetProcedure;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * « Ce profil est-il complet ? » — l'autorité que les trois fronts lisent pour
 * poser, avant l'application, les questions de l'inscription.
 */
class ProfilObligatoireTest {

    private static User user(Role role, AuthProvider provider, String first, String last,
                             TargetProcedure procedure) {
        User u = new User();
        u.setRole(role);
        u.setAuthProvider(provider);
        u.setFirstName(first);
        u.setLastName(last);
        u.setTargetProcedure(procedure);
        return u;
    }

    @Test
    void inscriptionLocaleComplete_rienNeManque() {
        assertThat(ProfilObligatoire.champsManquants(
                user(Role.USER, AuthProvider.LOCAL, "Awa", "Diallo", TargetProcedure.CR))).isEmpty();
    }

    /** Le cas du bug : un compte né d'une connexion Google, sans démarche. */
    @Test
    void compteGoogleSansDemarche_laDemarcheManque() {
        assertThat(ProfilObligatoire.champsManquants(
                user(Role.USER, AuthProvider.GOOGLE, "Awa", "Diallo", null)))
                .containsExactly(ProfileField.TARGET_PROCEDURE);
    }

    /** Apple ne rend le nom qu'au premier consentement, et le candidat peut le refuser. */
    @Test
    void compteAppleSansNomNiDemarche_toutManque_dansLOrdreDuFormulaire() {
        assertThat(ProfilObligatoire.champsManquants(
                user(Role.USER, AuthProvider.APPLE, null, "  ", null)))
                .containsExactly(ProfileField.FIRST_NAME, ProfileField.LAST_NAME,
                        ProfileField.TARGET_PROCEDURE);
    }

    /** Compte local d'avant le champ, ou mobile qui a quitté l'écran de parcours. */
    @Test
    void compteLocalSansDemarche_estIncomplet_aussi() {
        assertThat(ProfilObligatoire.champsManquants(
                user(Role.USER, AuthProvider.LOCAL, "Awa", "Diallo", null)))
                .containsExactly(ProfileField.TARGET_PROCEDURE);
    }

    /** Un admin n'est pas un candidat : lui demander une démarche serait l'inventer. */
    @Test
    void admin_nAJamaisDeChampManquant() {
        assertThat(ProfilObligatoire.champsManquants(
                user(Role.ADMIN, AuthProvider.LOCAL, null, null, null))).isEmpty();
    }
}
