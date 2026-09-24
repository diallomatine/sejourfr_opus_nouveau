package com.sejourfr.app.service.examenblanc;

import com.sejourfr.app.dto.ExamSlotsDto;
import com.sejourfr.app.dto.ProductionAttemptStartRequest;
import com.sejourfr.app.dto.StartAttemptRequest;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.FreeEntitlementCode;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.service.AttemptService;
import com.sejourfr.app.service.FullTcfExamService;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.EnumSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.AccessDeniedException;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * 🛑 <b>La grille SERVIE des examens blancs</b> (arbitrage du 2026-09-24,
 * « c'est le serveur qui décide du verrouillage ») : un {@code locked} par
 * créneau, lu chez l'autorité que le démarrage oppose en 403. Chaque grille est
 * vérifiée des deux côtés — le {@code locked} servi ET le démarrage réel — pour
 * que les deux ne puissent pas diverger.
 */
class ExamSlotsServiceIT extends AbstractIntegrationTest {

    @Autowired ExamSlotsService service;
    @Autowired AttemptService attemptService;
    @Autowired FullTcfExamService fullTcfExamService;
    @Autowired TestData data;

    private static List<Boolean> locks(ExamSlotsDto dto) {
        return dto.slots().stream().map(ExamSlotsDto.Slot::locked).toList();
    }

    private static void creneau1OuvertLeResteVerrouille(ExamSlotsDto dto, int taille) {
        assertThat(dto.slots()).hasSize(taille);
        assertThat(dto.slots().getFirst()).isEqualTo(new ExamSlotsDto.Slot(1, false));
        assertThat(dto.slots().subList(1, taille)).allMatch(ExamSlotsDto.Slot::locked);
    }

    private StartAttemptRequest examenEpreuve(QuestionType type, int slot) {
        return new StartAttemptRequest(AttemptType.MOCK_EXAM, Module.TCF, null, null,
                null, null, null, null, type, slot, null);
    }

    private StartAttemptRequest examenCiviqueGlobal(int slot) {
        return new StartAttemptRequest(AttemptType.MOCK_EXAM, Module.CIVIQUE, null, null,
                null, null, null, null, null, slot, null);
    }

    // ------------------------------------------------------------ épreuves QCM

    @ParameterizedTest(name = "{0} · compte gratuit : créneau 1 ouvert, 2+ verrouillés")
    @EnumSource(value = EpreuveType.class, names = {"TCF_CO", "TCF_CE", "TCF_STRUCTURE"})
    void epreuveQcm_compteGratuit(EpreuveType epreuve) {
        User user = data.user();

        ExamSlotsDto dto = service.slots(user.getId(), epreuve);

        assertThat(dto.epreuve()).isEqualTo(epreuve);
        creneau1OuvertLeResteVerrouille(dto, AttemptService.MOCK_EXAM_SLOTS);
    }

    @Test
    @DisplayName("CO · le locked servi et le 403 du démarrage lisent la même règle")
    void epreuveQcm_servieEtDemarrageConcordent() {
        User user = data.user();

        assertThat(locks(service.slots(user.getId(), EpreuveType.TCF_CO)).subList(0, 2))
                .containsExactly(false, true);
        assertThatCode(() -> attemptService.start(user.getId(), examenEpreuve(QuestionType.CO, 1)))
                .doesNotThrowAnyException();
        assertThatThrownBy(() -> attemptService.start(user.getId(), examenEpreuve(QuestionType.CO, 2)))
                .isInstanceOf(AccessDeniedException.class);
    }

    @Test
    @DisplayName("CO · visiteur : créneau 1 ouvert (démo), 2+ verrouillés")
    void epreuveQcm_visiteur() {
        creneau1OuvertLeResteVerrouille(service.slots(null, EpreuveType.TCF_CO), AttemptService.MOCK_EXAM_SLOTS);
    }

    @Test
    @DisplayName("CO · abonné TCF : tout est ouvert ; un pass Civique seul n'ouvre rien de plus")
    void epreuveQcm_abonne() {
        User abonne = data.user();
        data.userSubscription(abonne, data.plan());
        User passCivique = data.user();
        data.userSubscription(passCivique, data.plan(com.sejourfr.app.enums.ModuleAccess.CIVIQUE));

        assertThat(locks(service.slots(abonne.getId(), EpreuveType.TCF_CO))).containsOnly(false);
        creneau1OuvertLeResteVerrouille(
                service.slots(passCivique.getId(), EpreuveType.TCF_CO), AttemptService.MOCK_EXAM_SLOTS);
    }

    // ------------------------------------------------------------ examen complet

    @Test
    @DisplayName("TCF complet · compte gratuit : créneau 1 ouvert et rejouable, 2 → 403")
    void examenComplet_compteGratuit() {
        User user = data.user();

        creneau1OuvertLeResteVerrouille(
                service.slots(user.getId(), EpreuveType.TCF_COMPLET), FullTcfExamService.EXAM_SLOTS);
        assertThatCode(() -> fullTcfExamService.start(user.getId(), 1)).doesNotThrowAnyException();
        assertThatThrownBy(() -> fullTcfExamService.start(user.getId(), 2))
                .isInstanceOf(AccessDeniedException.class);
    }

    @Test
    @DisplayName("TCF complet · abonné : tout est ouvert")
    void examenComplet_abonne() {
        User user = data.user();
        data.userSubscription(user, data.plan());

        assertThat(locks(service.slots(user.getId(), EpreuveType.TCF_COMPLET))).containsOnly(false);
        assertThatCode(() -> fullTcfExamService.start(user.getId(), 2)).doesNotThrowAnyException();
    }

    @Test
    @DisplayName("TCF complet · visiteur : l'examen offert (gabarit gratuit) au créneau 1, rien d'autre")
    void examenComplet_visiteur() {
        creneau1OuvertLeResteVerrouille(
                service.slots(null, EpreuveType.TCF_COMPLET), FullTcfExamService.EXAM_SLOTS);
    }

    // ------------------------------------------------------------ civique global

    @Test
    @DisplayName("Civique global · compte gratuit : créneau 1 ouvert, 2 → 403")
    void civiqueGlobal_compteGratuit() {
        User user = data.user();

        creneau1OuvertLeResteVerrouille(
                service.slots(user.getId(), EpreuveType.CIVIQUE), AttemptService.MOCK_EXAM_SLOTS);
        assertThatCode(() -> attemptService.start(user.getId(), examenCiviqueGlobal(1)))
                .doesNotThrowAnyException();
        assertThatThrownBy(() -> attemptService.start(user.getId(), examenCiviqueGlobal(2)))
                .isInstanceOf(AccessDeniedException.class);
    }

    @Test
    @DisplayName("Civique global · visiteur : créneau 1 ouvert ; abonné Civique : tout ouvert")
    void civiqueGlobal_visiteurEtAbonne() {
        User abonne = data.user();
        data.userSubscription(abonne, data.plan());

        creneau1OuvertLeResteVerrouille(service.slots(null, EpreuveType.CIVIQUE), AttemptService.MOCK_EXAM_SLOTS);
        assertThat(locks(service.slots(abonne.getId(), EpreuveType.CIVIQUE))).containsOnly(false);
    }

    // ------------------------------------------------------------ production

    private ProductionAttemptStartRequest examenProduction(EpreuveType epreuve, int slot) {
        return new ProductionAttemptStartRequest(Module.TCF, epreuve, null, true, slot);
    }

    @ParameterizedTest(name = "{0} · compte gratuit : créneau 1 ouvert, 2 → 403")
    @EnumSource(value = EpreuveType.class, names = {"TCF_EE", "TCF_EO"})
    void production_compteGratuit(EpreuveType epreuve) {
        User user = data.user();

        creneau1OuvertLeResteVerrouille(service.slots(user.getId(), epreuve), 10);
        assertThatCode(() -> attemptService.startProductionAttempt(user.getId(), examenProduction(epreuve, 1)))
                .doesNotThrowAnyException();
        assertThatThrownBy(() -> attemptService.startProductionAttempt(
                user.getId(), examenProduction(epreuve, 2)))
                .isInstanceOf(AccessDeniedException.class);
    }

    @Test
    @DisplayName("EO · gratuité consommée : le créneau 1 se ferme (D-17 bis) ; l'écrit reste rejouable")
    void production_gratuiteConsommee() {
        User user = data.user();
        data.freeEntitlementUsage(user, FreeEntitlementCode.EXAM_BLANC_EO);
        data.freeEntitlementUsage(user, FreeEntitlementCode.EXAM_BLANC_EE);

        assertThat(locks(service.slots(user.getId(), EpreuveType.TCF_EO))).containsOnly(true);
        assertThatThrownBy(() -> attemptService.startProductionAttempt(
                user.getId(), examenProduction(EpreuveType.TCF_EO, 1)))
                .isInstanceOf(AccessDeniedException.class);
        assertThat(service.slots(user.getId(), EpreuveType.TCF_EE).slots().getFirst().locked()).isFalse();
    }

    @Test
    @DisplayName("EE/EO · visiteur : tout est fermé ; abonné : tout est ouvert")
    void production_visiteurEtAbonne() {
        User abonne = data.user();
        data.userSubscription(abonne, data.plan());

        assertThat(locks(service.slots(null, EpreuveType.TCF_EE))).hasSize(10).containsOnly(true);
        assertThat(locks(service.slots(abonne.getId(), EpreuveType.TCF_EO))).containsOnly(false);
    }

    @Test
    @DisplayName("Un identifiant inconnu n'ouvre rien de plus qu'un compte gratuit")
    void compteInconnu() {
        creneau1OuvertLeResteVerrouille(
                service.slots(UUID.randomUUID(), EpreuveType.TCF_CE), AttemptService.MOCK_EXAM_SLOTS);
    }
}
