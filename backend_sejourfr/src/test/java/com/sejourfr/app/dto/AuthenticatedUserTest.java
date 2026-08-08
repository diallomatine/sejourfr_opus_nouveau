package com.sejourfr.app.dto;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.enums.TargetProcedure;
import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Ce que les trois fronts lisent de l'utilisateur courant.
 *
 * <p><b>Le palier servi est DÉRIVÉ</b> ({@link TargetProcedure#niveauVise}), pas
 * recopié : c'est ce qui rend un couple incohérent stocké invisible des clients,
 * sans migration et sans attendre que l'utilisateur repasse par l'écran de
 * parcours. Un front ne peut donc pas afficher « Naturalisation » à côté de
 * « niveau B1 ».
 */
class AuthenticatedUserTest {

    private static User user(TargetProcedure procedure, TargetLevel level) {
        User u = new User();
        u.setId(UUID.randomUUID());
        u.setEmail("candidat@sejourfr.test");
        u.setTargetProcedure(procedure);
        u.setTargetLevel(level);
        return u;
    }

    private static AuthenticatedUser dto(TargetProcedure procedure, TargetLevel level) {
        return AuthenticatedUser.from(user(procedure, level), ModuleAccess.NONE, null);
    }

    /** Le défaut d'origine, vu du front : NAT + B1 hérité ⇒ B2 servi. */
    @Test
    void unCoupleIncoherentHerite_sortCorrige() {
        assertThat(dto(TargetProcedure.NAT, TargetLevel.B1).targetLevel())
            .isEqualTo(TargetLevel.B2);
    }

    @Test
    void viserPlusHautQueSaDemarche_estRespecte() {
        assertThat(dto(TargetProcedure.CSP, TargetLevel.B2).targetLevel())
            .isEqualTo(TargetLevel.B2);
    }

    @Test
    void sansNiveauStocke_laDemarcheFaitFoi() {
        assertThat(dto(TargetProcedure.CR, null).targetLevel()).isEqualTo(TargetLevel.B1);
    }

    /** Aucune démarche, aucun niveau : on ne devine rien pour le candidat. */
    @Test
    void sansRien_aucunPalierNEstInvente() {
        assertThat(dto(null, null).targetLevel()).isNull();
        assertThat(dto(null, null).targetProcedure()).isNull();
    }

    @Test
    void sansDemarche_leNiveauDeclareEstServiTelQuel() {
        assertThat(dto(null, TargetLevel.B1).targetLevel()).isEqualTo(TargetLevel.B1);
    }
}
