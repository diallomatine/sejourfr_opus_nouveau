package com.sejourfr.app.entitlement;

import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.FreeEntitlementUsage;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.FreeEntitlementCode;
import com.sejourfr.app.repository.FreeEntitlementUsageRepository;
import com.sejourfr.app.service.AccountDeletionService;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.hibernate.exception.ConstraintViolationException;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * <b>« Offert une fois » est tenu par la BASE</b>, pas par un service.
 *
 * <p>Ce qui est en jeu : le freebie d'examen blanc EE/EO paie une correction LLM
 * complete (D-17 bis). Deux requetes concurrentes ne se voient pas l'une
 * l'autre — une garde applicative en offrirait donc deux. C'est
 * {@code uq_free_entitlement_usage} qui tranche, et c'est lui qu'on verifie ici.
 * Meme demarche que {@code IdempotenceSoumissionIT} pour V046.
 *
 * <p>⚠️ Rien ne lit encore ce ledger : la bascule des quatre implementations ad
 * hoc de « premiere fois gratuite » est en P4. Ce test verrouille le
 * <b>schema</b>, pour qu'elle ait un socle sur lequel s'appuyer.
 */
class FreeEntitlementUsageIT extends AbstractIntegrationTest {

    @Autowired private TestData data;
    @Autowired private FreeEntitlementUsageRepository ledger;
    @Autowired private AccountDeletionService accountDeletionService;

    @PersistenceContext private EntityManager em;

    @Test
    @DisplayName("La même gratuité ne se consomme qu'une fois : la base refuse la seconde")
    void memeGratuiteDeuxFois() {
        User user = data.user();
        data.freeEntitlementUsage(user, FreeEntitlementCode.EXAM_BLANC_EE);
        em.flush();

        FreeEntitlementUsage seconde = new FreeEntitlementUsage();
        seconde.setUser(user);
        seconde.setCode(FreeEntitlementCode.EXAM_BLANC_EE);

        assertThatThrownBy(() -> {
            ledger.save(seconde);
            em.flush();
        })
                .isInstanceOfAny(DataIntegrityViolationException.class,
                        ConstraintViolationException.class)
                .hasStackTraceContaining("uq_free_entitlement_usage");
    }

    /**
     * 🛑 <b>Deux freebies nominatifs, pas un au choix</b> (D-17 bis). Un candidat
     * qui a use son examen blanc EE garde le sien en EO : l'unicite porte sur le
     * couple, jamais sur le seul candidat.
     */
    @Test
    @DisplayName("Les deux épreuves de production ont chacune leur gratuité")
    void unFreebieParEpreuveDeProduction() {
        User user = data.user();
        data.freeEntitlementUsage(user, FreeEntitlementCode.EXAM_BLANC_EE);
        data.freeEntitlementUsage(user, FreeEntitlementCode.EXAM_BLANC_EO);
        em.flush();

        assertThat(ledger.existsByUserIdAndCode(user.getId(), FreeEntitlementCode.EXAM_BLANC_EE))
                .isTrue();
        assertThat(ledger.existsByUserIdAndCode(user.getId(), FreeEntitlementCode.EXAM_BLANC_EO))
                .isTrue();
        assertThat(ledger.findAllByUserId(user.getId())).hasSize(2);
    }

    /**
     * L'unicite est bornee au candidat, et ce test est la raison d'etre de cette
     * borne : avec une unicite globale, le premier candidat a consommer son
     * examen blanc EE le fermerait pour tout le monde.
     */
    @Test
    @DisplayName("Le même code chez deux comptes différents ne pose aucun problème")
    void memeCodeChezDeuxComptes() {
        User premier = data.user();
        User second = data.user();
        data.freeEntitlementUsage(premier, FreeEntitlementCode.EXAM_BLANC_EO);
        data.freeEntitlementUsage(second, FreeEntitlementCode.EXAM_BLANC_EO);
        em.flush();

        assertThat(ledger.findByUserIdAndCode(premier.getId(), FreeEntitlementCode.EXAM_BLANC_EO))
                .isPresent();
        assertThat(ledger.findByUserIdAndCode(second.getId(), FreeEntitlementCode.EXAM_BLANC_EO))
                .isPresent();
    }

    @Test
    @DisplayName("La gratuité survit à la disparition de la session qui l'a consommée")
    void laGratuiteSurvitASaSession() {
        User user = data.user();
        Attempt source = data.attempt(user);
        FreeEntitlementUsage usage =
                data.freeEntitlementUsage(user, FreeEntitlementCode.EXAM_BLANC_EE, source);
        em.flush();
        UUID id = usage.getId();

        // 🛑 ON DELETE SET NULL, et c'est le point : si la disparition de la
        // session rendait la gratuite, un menage technique offrirait une
        // correction LLM deja honoree. Le fait survit a sa preuve.
        em.createNativeQuery("DELETE FROM attempt_questions WHERE attempt_id = :id")
                .setParameter("id", source.getId()).executeUpdate();
        em.createNativeQuery("DELETE FROM attempts WHERE id = :id")
                .setParameter("id", source.getId()).executeUpdate();
        em.clear();

        assertThat(ledger.findById(id))
                .get()
                .satisfies(restante -> {
                    assertThat(restante.getSourceAttempt()).isNull();
                    assertThat(restante.getCode()).isEqualTo(FreeEntitlementCode.EXAM_BLANC_EE);
                });
    }

    @Test
    @DisplayName("Un code inconnu de la base est refusé, même si l'enum Java l'ignore")
    void unCodeHorsEnumEstRefuse() {
        User user = data.user();

        // Le CHECK est l'autorite, l'enum Java n'en est que le miroir : un code
        // libre ferait qu'une faute de frappe rendrait gratuite une gratuite
        // deja consommee, sans que rien ne le signale.
        assertThatThrownBy(() -> em.createNativeQuery(
                "INSERT INTO free_entitlement_usage (id, user_id, code) "
                        + "VALUES (:id, :user, 'EXAM_BLANC_CO')")
                .setParameter("id", UUID.randomUUID())
                .setParameter("user", user.getId())
                .executeUpdate())
                .hasStackTraceContaining("chk_free_entitlement_code");
    }

    @Test
    @DisplayName("La suppression de compte purge le ledger")
    void laSuppressionDeCompteVideLeLedger() {
        User user = data.user();
        data.freeEntitlementUsage(user, FreeEntitlementCode.EXAM_BLANC_EE);
        data.freeEntitlementUsage(user, FreeEntitlementCode.EXAM_BLANC_EO);
        em.flush();

        // « Cette personne a eu son examen blanc offert tel jour » est de la
        // donnee nominative : elle ne survit pas a l'anonymisation. La cascade
        // base ne suffit pas — la ligne `users` reste.
        accountDeletionService.deleteAccount(user.getId());
        em.flush();

        assertThat(ledger.findAllByUserId(user.getId())).isEmpty();
    }
}
