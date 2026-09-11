package com.sejourfr.app.service;

import com.sejourfr.app.dto.PreparationDto;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.DiagnosticSessionStatus;
import com.sejourfr.app.enums.PreparationEtape;
import com.sejourfr.app.service.diagnosticcivique.CivicDiagnosticService;
import com.sejourfr.app.service.diagnostictcf.TcfDiagnosticService;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * L'ÉTAT UNIQUE DE PRÉPARATION (arbitrage du 2026-09-10).
 *
 * <p>🛑 Ce que ce test verrouille : l'Accueil, le Plan et les Examens lisent
 * <b>le même</b> état, donc proposent forcément la même prochaine action. Trois
 * écrans qui déduiraient chacun leur version finiraient par proposer trois
 * choses différentes au même candidat.
 *
 * <p>Et l'<b>asymétrie assumée</b> : le TCF a deux diagnostics, le civique un
 * seul. `ESTIMATION_FAITE` n'existe donc que côté TCF.
 */
class PreparationServiceIT extends AbstractIntegrationTest {

    @Autowired private PreparationService service;
    @Autowired private TcfDiagnosticService tcfService;
    @Autowired private CivicDiagnosticService civicService;
    @Autowired private TestData testData;
    @Autowired private EntityManager entityManager;

    @Test
    @DisplayName("Un compte neuf : les deux modules demandent leur diagnostic")
    void compteNeuf() {
        User user = testData.user();

        PreparationDto prep = service.lire(user.getId());

        assertThat(prep.tcf().etape()).isEqualTo(PreparationEtape.DIAGNOSTIC_A_FAIRE);
        assertThat(prep.civique().etape()).isEqualTo(PreparationEtape.DIAGNOSTIC_A_FAIRE);
        // 🛑 Aucun niveau, aucun compte : rien n'a été mesuré, et `null` le dit.
        assertThat(prep.tcf().niveau()).isNull();
        assertThat(prep.civique().aRenforcer()).isNull();
    }

    @Test
    @DisplayName("Le diagnostic TCF complet ouvert met le module EN COURS, avec son avancement")
    void tcfComplerEnCours() {
        User user = testData.user();
        tcfService.ouvrir(user.getId());
        entityManager.flush();
        entityManager.clear();

        PreparationDto prep = service.lire(user.getId());

        assertThat(prep.tcf().etape()).isEqualTo(PreparationEtape.DIAGNOSTIC_EN_COURS);
        // L'avancement réel : c'est ce que l'Accueil affiche (« 0 / 4 »).
        assertThat(prep.tcf().fait()).isZero();
        assertThat(prep.tcf().total()).isEqualTo(4);
        assertThat(prep.tcf().sessionId()).isNotNull();
        // 🛑 Aucun niveau tant que le diagnostic n'est pas clos.
        assertThat(prep.tcf().niveau()).isNull();
    }

    @Test
    @DisplayName("Le diagnostic TCF clos rend le Plan prêt")
    void tcfClosRendLePlanPret() {
        User user = testData.user();
        var session = tcfService.ouvrir(user.getId());
        tcfService.cloturer(user.getId(), session.getId());
        entityManager.flush();
        entityManager.clear();

        assertThat(service.lire(user.getId()).tcf().etape())
                .isEqualTo(PreparationEtape.PLAN_PRET);
    }

    @Test
    @DisplayName("🛑 Le diagnostic RAPIDE clos reste désigné quand le COMPLET est en cours")
    void estimationSurvitAuDemarrageDuComplet() {
        User user = testData.user();
        var rapide = testData.diagnosticSession(user, DiagnosticSessionStatus.COMPLETED);
        tcfService.ouvrir(user.getId());
        entityManager.flush();
        entityManager.clear();

        PreparationDto.ModulePreparation tcf = service.lire(user.getId()).tcf();

        // L'étape suit le COMPLET, c'est inchangé…
        assertThat(tcf.etape()).isEqualTo(PreparationEtape.DIAGNOSTIC_EN_COURS);
        assertThat(tcf.fait()).isZero();
        assertThat(tcf.total()).isEqualTo(4);
        // …et `sessionId` désigne toujours le complet, celui qu'on reprend.
        assertThat(tcf.sessionId()).isNotEqualTo(rapide.getId());
        // 🛑 …mais le rapport du RAPIDE reste atteignable. Sans ce champ, la
        // porte du Plan perdait le seul résultat que le candidat possède entre
        // la fin du rapide et la fin du complet — deux sens sur `sessionId`
        // n'auraient pas pu les porter tous les deux.
        assertThat(tcf.estimationSessionId()).isEqualTo(rapide.getId());
    }

    @Test
    @DisplayName("Le diagnostic RAPIDE clos, sans complet : l'étape ET l'estimation le désignent")
    void estimationFaiteDesigneLaMemeSession() {
        User user = testData.user();
        var rapide = testData.diagnosticSession(user, DiagnosticSessionStatus.COMPLETED);
        entityManager.flush();
        entityManager.clear();

        PreparationDto.ModulePreparation tcf = service.lire(user.getId()).tcf();

        assertThat(tcf.etape()).isEqualTo(PreparationEtape.ESTIMATION_FAITE);
        assertThat(tcf.sessionId()).isEqualTo(rapide.getId());
        assertThat(tcf.estimationSessionId()).isEqualTo(rapide.getId());
    }

    @Test
    @DisplayName("🛑 Un diagnostic rapide INACHEVÉ n'est pas une estimation")
    void rapideInacheveNEstPasUneEstimation() {
        User user = testData.user();
        testData.diagnosticSession(user, DiagnosticSessionStatus.IN_PROGRESS);
        entityManager.flush();
        entityManager.clear();

        // `null` = rien à relire, et c'est le seul état où la porte du Plan
        // n'affiche aucun rapport. On n'invente pas un rapport à partir d'une
        // session qui n'a jamais été analysée.
        assertThat(service.lire(user.getId()).tcf().estimationSessionId()).isNull();
    }

    @Test
    @DisplayName("Le civique ne porte jamais d'estimation : il n'a qu'un diagnostic")
    void civiqueNaPasDEstimation() {
        User user = testData.user();
        civicService.ouvrir(user.getId());
        entityManager.flush();
        entityManager.clear();

        assertThat(service.lire(user.getId()).civique().estimationSessionId()).isNull();
    }

    @Test
    @DisplayName("Le civique en cours porte son avancement en QUESTIONS, pas en épreuves")
    void civiqueEnCours() {
        User user = testData.user();
        civicService.ouvrir(user.getId());
        entityManager.flush();
        entityManager.clear();

        PreparationDto prep = service.lire(user.getId());

        assertThat(prep.civique().etape()).isEqualTo(PreparationEtape.DIAGNOSTIC_EN_COURS);
        assertThat(prep.civique().fait()).isZero();
        // 🛑 L'asymétrie est visible ici : le civique se compte en questions
        // (24), le TCF en épreuves (4). Un seul dénominateur pour les deux
        // aurait force l'un des deux à mentir.
        assertThat(prep.civique().total()).isGreaterThan(4);
    }

    @Test
    @DisplayName("Le civique clos rend le Plan prêt et compte les thèmes à renforcer")
    void civiqueClos() {
        User user = testData.user();
        var session = civicService.ouvrir(user.getId());
        civicService.cloturer(user.getId(), session.getId());
        entityManager.flush();
        entityManager.clear();

        PreparationDto prep = service.lire(user.getId());

        assertThat(prep.civique().etape()).isEqualTo(PreparationEtape.PLAN_PRET);
        // 🛑 Le compte n'est plus `null` : il a été mesuré. Aucune réponse
        // donnée ⇒ tous les thèmes tirés sont faibles.
        assertThat(prep.civique().aRenforcer()).isNotNull().isPositive();
    }

    @Test
    @DisplayName("🛑 Les deux modules avancent INDÉPENDAMMENT")
    void lesDeuxModulesSontIndependants() {
        User user = testData.user();
        civicService.ouvrir(user.getId());
        entityManager.flush();
        entityManager.clear();

        PreparationDto prep = service.lire(user.getId());

        // Commencer le civique ne dit rien du TCF, et l'Accueil doit pouvoir
        // afficher les deux états côte à côte sans que l'un contamine l'autre.
        assertThat(prep.civique().etape()).isEqualTo(PreparationEtape.DIAGNOSTIC_EN_COURS);
        assertThat(prep.tcf().etape()).isEqualTo(PreparationEtape.DIAGNOSTIC_A_FAIRE);
    }
}
