package com.sejourfr.app.service;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.LocalDate;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * La date d'examen du candidat (V047) : sa persistance, son effacement
 * volontaire, et sa disparition a la suppression du compte.
 */
class DateExamenIT extends AbstractIntegrationTest {

    @Autowired
    private TestData testData;
    @Autowired
    private MeService meService;
    @Autowired
    private UserManager userManager;
    @Autowired
    private EntityManager entityManager;

    @Test
    @DisplayName("La date déclarée est conservée telle quelle, sans décalage de fuseau")
    void laDateEstConserveeTelleQuelle() {
        User user = testData.user();
        LocalDate jour = LocalDate.of(2026, 10, 18);

        meService.updateExamDate(user.getId(), jour);
        entityManager.flush();
        entityManager.clear();

        assertThat(userManager.findById(user.getId()))
                .map(User::getExamDate)
                .contains(jour);
    }

    /**
     * « Pas encore de date » est une reponse PLEINE : le candidat doit pouvoir
     * revenir dessus. Passer null efface, ce n'est pas une absence de mise a
     * jour.
     */
    @Test
    @DisplayName("Passer null efface la date, ce n'est pas ignoré")
    void nullEfface() {
        User user = testData.user();
        meService.updateExamDate(user.getId(), LocalDate.of(2026, 10, 18));
        entityManager.flush();

        meService.updateExamDate(user.getId(), null);
        entityManager.flush();
        entityManager.clear();

        assertThat(userManager.findById(user.getId()))
                .map(User::getExamDate)
                .isEmpty();
    }

    /**
     * Une date depassee est une information VRAIE (l'examen a eu lieu). La
     * refuser empecherait de corriger une faute de frappe, et la contrainte
     * vieillirait toute seule.
     */
    @Test
    @DisplayName("Une date passée est acceptée : c'est au serveur d'en décider à la lecture")
    void uneDatePasseeEstAcceptee() {
        User user = testData.user();
        LocalDate hier = LocalDate.now().minusDays(1);

        meService.updateExamDate(user.getId(), hier);
        entityManager.flush();
        entityManager.clear();

        assertThat(userManager.findById(user.getId()))
                .map(User::getExamDate)
                .contains(hier);
    }

    /**
     * 🛑 RGPD. La date d'examen designe un evenement de la vie administrative du
     * candidat : c'est une donnee personnelle, elle part avec le compte.
     */
    @Test
    @DisplayName("La suppression du compte efface la date d'examen")
    void laSuppressionDuCompteEffaceLaDate() {
        User user = testData.user();
        meService.updateExamDate(user.getId(), LocalDate.of(2026, 10, 18));
        entityManager.flush();

        User aSupprimer = userManager.findById(user.getId()).orElseThrow();
        aSupprimer.anonymize();
        userManager.save(aSupprimer);
        entityManager.flush();
        entityManager.clear();

        assertThat(userManager.findById(user.getId()))
                .map(User::getExamDate)
                .isEmpty();
    }
}
