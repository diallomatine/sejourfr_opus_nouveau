package com.sejourfr.app.service;

import com.sejourfr.app.dto.FullTcfExamResponse;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.service.journey.JourneyProductionBridge;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Verrouille le freemium de l'examen blanc TCF complet pour les comptes
 * gratuits (cf. {@link FullTcfExamService#start}) :
 *
 * <ul>
 *   <li>chaque épreuve de production est offerte <b>une seule fois à vie</b>,
 *       et les <b>deux gratuités sont NOMINATIVES</b> — une EE, une EO
 *       (D-17 bis, 2026-09-18). Celle qui est consommée ferme <b>sa</b>
 *       sous-épreuve, jamais les deux ;</li>
 *   <li>le freebie se lit sur le <b>ledger</b> {@code free_entitlement_usage},
 *       écrit à la <b>remise de l'analyse</b> —
 *       {@code hasFullExamProductionSubmission} est <b>révoqué</b> par D-17 : il
 *       devinait la gratuité à partir de l'existence d'une <b>soumission</b>,
 *       donc la consommait dès le dépôt d'une tâche, avant toute correction, et
 *       sans savoir sur quelle épreuve.</li>
 * </ul>
 *
 * Test unitaire pur (mocks Mockito, pas de contexte Spring ni de DB) : on pilote
 * directement le ledger et on vérifie l'état des sous-épreuves EE/EO dans la
 * réponse.
 */
class FullTcfExamServiceFreemiumTest {

    private AttemptManager attemptManager;
    private ProductionSubmissionManager productionSubmissionManager;
    private SubscriptionService subscriptionService;
    private JourneyProductionBridge journeyProductionBridge;
    private FreeExamEntitlementService freeExamEntitlementService;
    private FullTcfExamService service;

    private final UUID userId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        attemptManager = mock(AttemptManager.class);
        UserManager userManager = mock(UserManager.class);
        productionSubmissionManager = mock(ProductionSubmissionManager.class);
        subscriptionService = mock(SubscriptionService.class);
        AttemptService attemptService = mock(AttemptService.class);
        journeyProductionBridge = mock(JourneyProductionBridge.class);
        TcfLevelEstimatorService levelEstimator = mock(TcfLevelEstimatorService.class);
        ProductionBilanService productionBilanService = mock(ProductionBilanService.class);
        freeExamEntitlementService = mock(FreeExamEntitlementService.class);

        FullTcfExamResponseBuilder responseBuilder = new FullTcfExamResponseBuilder(
                attemptManager, mock(com.sejourfr.app.manager.AnswerManager.class),
                productionSubmissionManager, levelEstimator, productionBilanService);
        // Le verrou EE/EO d'un examen complet vit desormais dans
        // ProductionAccessService, qui le sert AUSSI en lecture au jalon du
        // Plan. On le construit ICI POUR DE VRAI, sur les memes mocks : c'est ce
        // qui garantit que le cadenas affiche et le verrou applique restent la
        // meme regle.
        ProductionAccessService productionAccessService = new ProductionAccessService(
                subscriptionService, attemptManager, productionSubmissionManager,
                mock(com.sejourfr.app.manager.DiagnosticSessionManager.class),
                freeExamEntitlementService);
        service = new FullTcfExamService(
                attemptManager, userManager, attemptService,
                mock(com.sejourfr.app.service.attempt.AttemptInteractionService.class),
                productionAccessService, responseBuilder, journeyProductionBridge);

        when(userManager.findById(userId)).thenReturn(Optional.of(new User()));
        // Compte gratuit (pas d'abonnement TCF).
        when(subscriptionService.hasTcf(userId)).thenReturn(false);
        // save renvoie l'entité telle quelle (pas de DB).
        when(attemptManager.save(any(Attempt.class))).thenAnswer(inv -> inv.getArgument(0));
        // Les 4 sous-attempts "créés" par AttemptService (mocké) sont fournis via
        // findSubAttempts — même liste pour le verrouillage et pour buildResponse,
        // donc les mutations (finishedAt) sont visibles dans la réponse.
        List<Attempt> subs = List.of(
                sub(EpreuveType.TCF_CO), sub(EpreuveType.TCF_CE),
                sub(EpreuveType.TCF_EE), sub(EpreuveType.TCF_EO));
        when(attemptManager.findSubAttempts(any())).thenReturn(subs);
        when(productionSubmissionManager.findByAttemptId(any())).thenReturn(List.of());
        // capB2 neutre : renvoie son argument (le niveau n'est pas l'objet du test).
        when(levelEstimator.capB2(any())).thenAnswer(inv -> inv.getArgument(0));
    }

    /** Les deux gratuites sont encore disponibles. */
    private void gratuitesIntactes() {
        when(freeExamEntitlementService.estConsomme(any(), any())).thenReturn(false);
    }

    /** Ces gratuites-la sont consommees, les autres non (D-17 bis : nominatives). */
    private void gratuitesConsommees(EpreuveType... epreuves) {
        when(freeExamEntitlementService.estConsomme(any(), any())).thenReturn(false);
        for (EpreuveType epreuve : epreuves) {
            when(freeExamEntitlementService.estConsomme(userId, epreuve)).thenReturn(true);
        }
    }

    private static Attempt sub(EpreuveType e) {
        Attempt a = new Attempt();
        a.setEpreuve(e);
        return a;
    }

    private static FullTcfExamResponse.SubAttempt subOf(FullTcfExamResponse r, EpreuveType e) {
        return r.subAttempts().stream()
                .filter(s -> s.epreuve() == e)
                .findFirst()
                .orElseThrow();
    }

    @Test
    void eeEoDeverrouillees_quandAucuneGratuiteConsommee() {
        // Les deux gratuités sont intactes : les deux épreuves sont jouables et
        // corrigées par l'IA.
        gratuitesIntactes();

        FullTcfExamResponse r = service.start(userId, 1);

        // EE/EO jouables : ni verrouillées, ni pré-terminées.
        assertThat(subOf(r, EpreuveType.TCF_EE).locked()).isFalse();
        assertThat(subOf(r, EpreuveType.TCF_EO).locked()).isFalse();
        assertThat(subOf(r, EpreuveType.TCF_EE).finishedAt()).isNull();
        assertThat(subOf(r, EpreuveType.TCF_EO).finishedAt()).isNull();
    }

    @Test
    void eeEoVerrouillees_quandLesDeuxGratuitesSontConsommees() {
        // Les deux gratuités sont consommées : l'examen reste jouable en CO+CE.
        gratuitesConsommees(EpreuveType.TCF_EE, EpreuveType.TCF_EO);

        FullTcfExamResponse r = service.start(userId, 1);

        // EE/EO verrouillées (réservées à l'abonnement) + pré-terminées. Leur
        // restitution (pas de niveau, hors plancher) est verrouillée par
        // FullTcfExamResponseBuilderTest — ici on ne teste que le VERROU.
        assertThat(subOf(r, EpreuveType.TCF_EE).locked()).isTrue();
        assertThat(subOf(r, EpreuveType.TCF_EO).locked()).isTrue();
        assertThat(subOf(r, EpreuveType.TCF_EE).finishedAt()).isNotNull();
        assertThat(subOf(r, EpreuveType.TCF_EO).finishedAt()).isNotNull();
        // La compréhension (CO/CE) reste jouable même au refaire.
        assertThat(subOf(r, EpreuveType.TCF_CO).locked()).isFalse();
        assertThat(subOf(r, EpreuveType.TCF_CE).locked()).isFalse();
    }

    @Test
    void demarrerNeConsommeJamaisLeFreebie_D17() {
        gratuitesIntactes();

        service.start(userId, 1);

        // 🛑 D-17 : la gratuité ne s'écrit qu'à la REMISE DE L'ANALYSE. Démarrer
        // — puis abandonner — un examen ne consomme donc RIEN, et le candidat
        // retrouve ses deux examens offerts. Sinon « offert une fois » voudrait
        // dire « perdu une fois ».
        verify(productionSubmissionManager, never()).save(any());
        verify(freeExamEntitlementService, never()).consommerApresAnalyse(any());
    }

    /**
     * 🛑 <b>D-17 bis — DEUX gratuités NOMINATIVES, pas « une au choix ».</b> Un
     * candidat qui a usé son examen blanc EE garde son examen blanc EO, et
     * l'examen complet doit le lui donner : un verrou global aurait fermé les
     * deux dès la première consommée.
     */
    @Test
    void uneSeuleGratuiteConsommee_neFermeQueSonEpreuve_D17bis() {
        gratuitesConsommees(EpreuveType.TCF_EE);

        FullTcfExamResponse r = service.start(userId, 1);

        assertThat(subOf(r, EpreuveType.TCF_EE).locked()).isTrue();
        assertThat(subOf(r, EpreuveType.TCF_EE).finishedAt()).isNotNull();
        // L'oral reste offert, corrigé en entier.
        assertThat(subOf(r, EpreuveType.TCF_EO).locked()).isFalse();
        assertThat(subOf(r, EpreuveType.TCF_EO).finishedAt()).isNull();
    }

    /**
     * 🛑 <b>{@code lockProductionSubAttempts} ne declenche AUCUNE etape du
     * parcours</b> (D-24, point 4, exclusion explicite).
     *
     * <p>Il pose {@code TERMINE} sur les EE/EO d'un examen complet gratuit
     * <b>sans qu'aucun examen n'ait ete passe</b> : le freebie est consomme, les
     * deux epreuves sont fermees avant meme que l'examen ne commence. Le
     * signaler au parcours aurait <b>invente une mesure</b>, et clos au passage
     * l'etape « Évaluer mon niveau » d'une epreuve que le candidat n'a jamais
     * ouverte. C'est le seul des quatre points de branchement qui est exclu, et
     * ce test est la preuve que l'exclusion tient.
     */
    @Test
    void preTerminerEeEo_neDeclencheAucuneEtapeDeParcours() {
        gratuitesConsommees(EpreuveType.TCF_EE, EpreuveType.TCF_EO);

        service.start(userId, 1);

        verify(journeyProductionBridge, never()).onProductionAttemptClosed(any());
        verify(journeyProductionBridge, never()).onFullExamCompleted(any());
    }

    // ------------------------------------------------------------------ slots

    /**
     * La grille compte 20 slots : un {@code slotNumber} hors borne était
     * persisté tel quel (999, -3), là où les MOCK_EXAM QCM sont bornés depuis
     * le lot précédent.
     */
    @Test
    void slotHorsBorne_refuse() {
        gratuitesIntactes();

        assertThatThrownBy(() -> service.start(userId, 999))
                .isInstanceOf(BusinessException.class);
        assertThatThrownBy(() -> service.start(userId, 0))
                .isInstanceOf(BusinessException.class);
        assertThatThrownBy(() -> service.start(userId, -3))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void slotAuxBornes_accepte() {
        gratuitesIntactes();

        assertThat(service.start(userId, 1)).isNotNull();
        assertThat(service.start(userId, FullTcfExamService.EXAM_SLOTS)).isNotNull();
    }

    /** Sans slot demandé, on retombe sur le slot 1 (et pas sur NULL en base). */
    @Test
    void slotAbsent_vautUn() {
        gratuitesIntactes();

        service.start(userId, null);

        org.mockito.ArgumentCaptor<Attempt> captor =
                org.mockito.ArgumentCaptor.forClass(Attempt.class);
        verify(attemptManager, org.mockito.Mockito.atLeastOnce()).save(captor.capture());
        assertThat(captor.getAllValues())
                .filteredOn(a -> a.getEpreuve() == EpreuveType.TCF_COMPLET)
                .allMatch(a -> Integer.valueOf(1).equals(a.getSlotNumber()));
    }
}
