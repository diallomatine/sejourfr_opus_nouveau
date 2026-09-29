package com.sejourfr.app.service;

import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.DiagnosticSession;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.DureeEpreuve;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.DiagnosticSessionManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.security.access.AccessDeniedException;

import java.time.Instant;
import java.util.UUID;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyShort;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Gardes de session partagées par les deux voies de notation EE/EO
 * (asynchrone et temps réel) : propriété, épreuve terminée, chrono,
 * correspondance épreuve tâche ⇄ attempt, et plafond « une soumission par
 * tâche » en session d'examen.
 */
class ProductionAccessServiceTest {

    private SubscriptionService subscriptionService;
    private AttemptManager attemptManager;
    private ProductionSubmissionManager submissionManager;
    private DiagnosticSessionManager diagnosticSessionManager;
    private FreeExamEntitlementService freeExamEntitlementService;
    private ProductionAccessService service;

    private final UUID userId = UUID.randomUUID();
    private final UUID attemptId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        subscriptionService = mock(SubscriptionService.class);
        attemptManager = mock(AttemptManager.class);
        submissionManager = mock(ProductionSubmissionManager.class);
        diagnosticSessionManager = mock(DiagnosticSessionManager.class);
        freeExamEntitlementService = mock(FreeExamEntitlementService.class);
        service = new ProductionAccessService(
                subscriptionService, attemptManager, submissionManager,
                diagnosticSessionManager, freeExamEntitlementService);
    }

    private User user(UUID id) {
        User u = new User();
        u.setId(id);
        return u;
    }

    private Attempt attempt(EpreuveType epreuve) {
        Attempt a = new Attempt();
        a.setId(attemptId);
        a.setUser(user(userId));
        a.setEpreuve(epreuve);
        a.setStartedAt(Instant.now());
        return a;
    }

    private ProductionTask task(EpreuveType epreuve, short tache) {
        ProductionTask t = new ProductionTask();
        t.setId(UUID.randomUUID());
        t.setEpreuve(epreuve);
        t.setTacheNumero(tache);
        t.setActive(true);
        return t;
    }

    // ------------------------------------------------------------------------
    // Propriété / état de session
    // ------------------------------------------------------------------------

    @Test
    void attempt_d_autrui_refuse() {
        Attempt foreign = attempt(EpreuveType.TCF_EE);
        foreign.setUser(user(UUID.randomUUID()));

        assertThatThrownBy(() -> service.assertCanSubmit(userId, foreign, task(EpreuveType.TCF_EE, (short) 1)))
                .isInstanceOf(AccessDeniedException.class);
    }

    @Test
    void epreuve_terminee_refuse() {
        Attempt finished = attempt(EpreuveType.TCF_EE);
        finished.setFinishedAt(Instant.now());

        assertThatThrownBy(() -> service.assertCanSubmit(userId, finished, task(EpreuveType.TCF_EE, (short) 1)))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void chrono_ecoule_refuse_mais_la_grace_de_60s_passe() {
        // Le chrono d'épreuve ne concerne plus que l'expression ÉCRITE : 30 min
        // pour les 3 tâches. L'oral se compte tâche par tâche.
        Attempt expired = attempt(EpreuveType.TCF_EE);
        expired.setTimeLimitSeconds(1800);
        expired.setStartedAt(Instant.now().minusSeconds(1800 + 120));
        assertThatThrownBy(() -> service.assertCanSubmit(userId, expired, task(EpreuveType.TCF_EE, (short) 1)))
                .isInstanceOf(BusinessException.class);

        Attempt inGrace = attempt(EpreuveType.TCF_EE);
        inGrace.setTimeLimitSeconds(1800);
        inGrace.setStartedAt(Instant.now().minusSeconds(1800 + 10));
        assertThatCode(() -> service.assertCanSubmit(userId, inGrace, task(EpreuveType.TCF_EE, (short) 1)))
                .doesNotThrowAnyException();
    }

    @Test
    void session_orale_sans_chrono_depreuve_reste_ouverte_longtemps() {
        // L'oral n'a AUCUN compte à rebours d'épreuve : une session ouverte
        // depuis une heure accepte encore la tâche suivante — le candidat vient
        // peut-être de lire sa consigne.
        Attempt orale = attempt(EpreuveType.TCF_EO);
        orale.setStartedAt(Instant.now().minusSeconds(3600));

        assertThatCode(() -> service.assertCanSubmit(userId, orale, task(EpreuveType.TCF_EO, (short) 2)))
                .doesNotThrowAnyException();
    }

    @Test
    void session_orale_eternelle_refusee_par_le_garde_fou() {
        // Garde-fou anti-abus, pas un chrono d'examen : sans lui, une session
        // orale restait ouverte indéfiniment et un compte gratuit pouvait y
        // accumuler des évaluations IA payantes.
        Attempt eternelle = attempt(EpreuveType.TCF_EO);
        eternelle.setStartedAt(Instant.now()
                .minusSeconds(DureeEpreuve.EO_GARDE_SESSION_SECONDS + 60));

        assertThatThrownBy(() -> service.assertCanSubmit(
                userId, eternelle, task(EpreuveType.TCF_EO, (short) 1)))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("trop longtemps");
    }

    @Test
    void sous_epreuve_orale_dun_examen_complet_echappe_au_garde_fou() {
        // Son started_at date de la CRÉATION de l'examen, des dizaines de
        // minutes avant que l'oral ne s'ouvre : l'y opposer fermerait une
        // épreuve légitime. Son coût IA est déjà borné par « une soumission par
        // tâche ».
        Attempt parent = new Attempt();
        parent.setId(UUID.randomUUID());
        parent.setEpreuve(EpreuveType.TCF_COMPLET);
        Attempt sousEpreuve = attempt(EpreuveType.TCF_EO);
        sousEpreuve.setParentAttempt(parent);
        sousEpreuve.setStartedAt(Instant.now()
                .minusSeconds(DureeEpreuve.EO_GARDE_SESSION_SECONDS + 3600));
        when(submissionManager.countByAttemptAndTache(any(), anyShort())).thenReturn(0L);

        assertThatCode(() -> service.assertCanSubmit(
                userId, sousEpreuve, task(EpreuveType.TCF_EO, (short) 1)))
                .doesNotThrowAnyException();
    }

    // ------------------------------------------------------------------------
    // Correspondance épreuve tâche ⇄ session (défaut : oral noté dans une écrite)
    // ------------------------------------------------------------------------

    @Test
    void tache_orale_dans_une_session_ecrite_refuse() {
        Attempt ecrite = attempt(EpreuveType.TCF_EE);

        assertThatThrownBy(() -> service.assertCanSubmit(userId, ecrite, task(EpreuveType.TCF_EO, (short) 1)))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("TCF_EO")
                .hasMessageContaining("TCF_EE");
    }

    @Test
    void tache_ecrite_dans_une_session_orale_refuse() {
        Attempt orale = attempt(EpreuveType.TCF_EO);

        assertThatThrownBy(() -> service.assertCanSubmit(userId, orale, task(EpreuveType.TCF_EE, (short) 2)))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void tache_dans_une_session_qcm_refuse() {
        Attempt qcm = attempt(EpreuveType.TCF_CO);

        assertThatThrownBy(() -> service.assertCanSubmit(userId, qcm, task(EpreuveType.TCF_EO, (short) 1)))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void epreuve_concordante_passe() {
        assertThatCode(() -> service.assertCanSubmit(
                userId, attempt(EpreuveType.TCF_EE), task(EpreuveType.TCF_EE, (short) 1)))
                .doesNotThrowAnyException();
    }

    // ------------------------------------------------------------------------
    // Plafond « une soumission par tâche » en session d'examen
    // ------------------------------------------------------------------------

    @Test
    void examen_refuse_une_seconde_soumission_sur_la_meme_tache() {
        Attempt exam = attempt(EpreuveType.TCF_EO);
        exam.setSlotNumber(1);
        when(submissionManager.countByAttemptAndTache(attemptId, (short) 2)).thenReturn(1L);

        assertThatThrownBy(() -> service.assertCanSubmit(userId, exam, task(EpreuveType.TCF_EO, (short) 2)))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("déjà été rendue");
    }

    @Test
    void examen_accepte_les_autres_taches() {
        Attempt exam = attempt(EpreuveType.TCF_EO);
        exam.setSlotNumber(1);
        when(submissionManager.countByAttemptAndTache(attemptId, (short) 3)).thenReturn(0L);

        assertThatCode(() -> service.assertCanSubmit(userId, exam, task(EpreuveType.TCF_EO, (short) 3)))
                .doesNotThrowAnyException();
    }

    @Test
    void sous_epreuve_d_examen_complet_est_aussi_plafonnee() {
        Attempt parent = new Attempt();
        parent.setId(UUID.randomUUID());
        parent.setEpreuve(EpreuveType.TCF_COMPLET);
        Attempt sub = attempt(EpreuveType.TCF_EE);
        sub.setParentAttempt(parent);
        when(submissionManager.countByAttemptAndTache(attemptId, (short) 1)).thenReturn(1L);

        assertThatThrownBy(() -> service.assertCanSubmit(userId, sub, task(EpreuveType.TCF_EE, (short) 1)))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void entrainement_libre_n_est_pas_plafonne_par_tache() {
        Attempt training = attempt(EpreuveType.TCF_EE); // slot null + parent null

        assertThatCode(() -> service.assertCanSubmit(userId, training, task(EpreuveType.TCF_EE, (short) 1)))
                .doesNotThrowAnyException();
        verify(submissionManager, never()).countByAttemptAndTache(any(), anyShort());
    }

    // ------------------------------------------------------------------------
    // Freemium refondu — D-17 / D-17 bis (2026-09-18) : deux examens blancs de
    // production offerts a vie, un par epreuve, analyse IA complete incluse.
    // ------------------------------------------------------------------------

    @Test
    void quota_premium_passe_sans_lire_le_ledger() {
        when(subscriptionService.hasTcf(userId)).thenReturn(true);

        service.enforceQuota(userId, EpreuveType.TCF_EO, attemptId);

        verify(freeExamEntitlementService, never())
                .analyseOffertePossible(any(), any(), any());
    }

    /** D-17 bis — le 1er examen blanc EE d'un compte gratuit est corrige en entier. */
    @Test
    void premierExamenBlancDUneEpreuvePasse() {
        Attempt exam = attempt(EpreuveType.TCF_EE);
        exam.setSlotNumber(1);
        when(subscriptionService.hasTcf(userId)).thenReturn(false);
        when(attemptManager.findById(attemptId)).thenReturn(Optional.of(exam));
        when(freeExamEntitlementService.analyseOffertePossible(
                userId, EpreuveType.TCF_EE, attemptId)).thenReturn(true);

        assertThatCode(() -> service.enforceQuota(userId, EpreuveType.TCF_EE, attemptId))
                .doesNotThrowAnyException();
    }

    /**
     * D-17 bis — <b>le rejeu est ouvert, c'est l'ANALYSE qui est premium</b>, et
     * le refus tombe <b>avant</b> tout appel paye : ni Whisper, ni correcteur.
     */
    @Test
    void rejeuDUnExamenDontLaGratuiteEstConsommeeRefuseAvantTouteDepense() {
        Attempt rejeu = attempt(EpreuveType.TCF_EE);
        rejeu.setSlotNumber(2);
        when(subscriptionService.hasTcf(userId)).thenReturn(false);
        when(attemptManager.findById(attemptId)).thenReturn(Optional.of(rejeu));
        when(freeExamEntitlementService.analyseOffertePossible(
                userId, EpreuveType.TCF_EE, attemptId)).thenReturn(false);

        assertThatThrownBy(() -> service.enforceQuota(userId, EpreuveType.TCF_EE, attemptId))
                .isInstanceOf(AccessDeniedException.class)
                .hasMessageContaining("déjà été corrigé")
                .hasMessageContaining("accès TCF");
    }

    /**
     * D-17 — l'<b>entrainement libre</b> EE/EO est premium sans exception :
     * {@code FREE_TRAINING_PER_EPREUVE = 1} est <b>supprime</b>.
     */
    @Test
    void entrainementLibreEstPremiumSansExceptionD17() {
        Attempt training = attempt(EpreuveType.TCF_EO); // slot null + parent null
        when(subscriptionService.hasTcf(userId)).thenReturn(false);
        when(attemptManager.findById(attemptId)).thenReturn(Optional.of(training));

        assertThatThrownBy(() -> service.enforceQuota(userId, EpreuveType.TCF_EO, attemptId))
                .isInstanceOf(AccessDeniedException.class)
                .hasMessage(ProductionAccessService.ENTRAINEMENT_PREMIUM_MESSAGE);
        verify(freeExamEntitlementService, never())
                .analyseOffertePossible(any(), any(), any());
    }

    /**
     * Une sous-epreuve EE/EO pre-terminee par le verrou d'un examen complet
     * gratuit reste fermee, quel que soit le ledger : un client ne contourne pas
     * le verrou en postant quand meme.
     */
    @Test
    void uneEpreuveDejaTermineeRefuseToujours() {
        Attempt fermee = attempt(EpreuveType.TCF_EE);
        fermee.setSlotNumber(1);
        fermee.setFinishedAt(Instant.now());
        when(subscriptionService.hasTcf(userId)).thenReturn(false);
        when(attemptManager.findById(attemptId)).thenReturn(Optional.of(fermee));

        assertThatThrownBy(() -> service.enforceQuota(userId, EpreuveType.TCF_EE, attemptId))
                .isInstanceOf(AccessDeniedException.class)
                .hasMessage(ProductionAccessService.EPREUVE_TERMINEE_MESSAGE);
    }

    // ------------------------------------------------------------------------
    // Diagnostic : bypass quota uniquement pour la paire task/attempt/session.
    // ------------------------------------------------------------------------

    @Test
    void diagnosticCorrectementAppariePasseSansConsommerLeQuotaEntrainement() {
        Attempt written = attempt(EpreuveType.TCF_EE);
        Attempt oral = attempt(EpreuveType.TCF_EO);
        oral.setId(UUID.randomUUID());
        ProductionTask writtenTask = task(EpreuveType.TCF_EE, (short) 3);
        writtenTask.setDiagnosticCode("INITIAL_TCF");
        writtenTask.setDiagnosticVersion(1);
        ProductionTask oralTask = task(EpreuveType.TCF_EO, (short) 3);
        oralTask.setDiagnosticCode("INITIAL_TCF");
        oralTask.setDiagnosticVersion(1);
        DiagnosticSession session = diagnosticSession(written, oral, writtenTask, oralTask);
        when(diagnosticSessionManager.findByAttemptIdWithContent(written.getId()))
                .thenReturn(Optional.of(session));
        when(attemptManager.findById(written.getId())).thenReturn(Optional.of(written));

        assertThatCode(() -> service.assertCanSubmit(userId, written, writtenTask))
                .doesNotThrowAnyException();
        assertThatCode(() -> service.enforceQuota(userId, writtenTask, written.getId()))
                .doesNotThrowAnyException();

        verify(subscriptionService, never()).hasTcf(any());
        verify(freeExamEntitlementService, never())
                .analyseOffertePossible(any(), any(), any());
    }

    @Test
    void uneTacheDiagnosticSeuleNeSuffitJamaisAContournerLeQuota() {
        Attempt written = attempt(EpreuveType.TCF_EE);
        ProductionTask diagnostic = task(EpreuveType.TCF_EE, (short) 3);
        diagnostic.setDiagnosticCode("INITIAL_TCF");
        diagnostic.setDiagnosticVersion(1);
        when(diagnosticSessionManager.findByAttemptIdWithContent(written.getId()))
                .thenReturn(Optional.empty());
        when(attemptManager.findById(written.getId())).thenReturn(Optional.of(written));

        assertThatThrownBy(() -> service.enforceQuota(userId, diagnostic, written.getId()))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("hors de votre session");
    }

    @Test
    void uneTacheStandardEstRefuseeDansUnAttemptDiagnostic() {
        Attempt written = attempt(EpreuveType.TCF_EE);
        Attempt oral = attempt(EpreuveType.TCF_EO);
        ProductionTask diagnosticWritten = task(EpreuveType.TCF_EE, (short) 3);
        diagnosticWritten.setDiagnosticCode("INITIAL_TCF");
        diagnosticWritten.setDiagnosticVersion(1);
        ProductionTask diagnosticOral = task(EpreuveType.TCF_EO, (short) 3);
        diagnosticOral.setDiagnosticCode("INITIAL_TCF");
        diagnosticOral.setDiagnosticVersion(1);
        DiagnosticSession session = diagnosticSession(
                written, oral, diagnosticWritten, diagnosticOral);
        when(diagnosticSessionManager.findByAttemptIdWithContent(written.getId()))
                .thenReturn(Optional.of(session));

        assertThatThrownBy(() -> service.assertCanSubmit(
                userId, written, task(EpreuveType.TCF_EE, (short) 1)))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("réservé au diagnostic");
    }

    // ------------------------------------------------------------------------
    // Le MEME budget, lu sans rien consommer (cadenas du Plan et du parcours)
    // ------------------------------------------------------------------------

    @Test
    void unAbonneTcfNaJamaisDeCadenasSurUneVerification() {
        when(subscriptionService.hasTcf(userId)).thenReturn(true);

        assertThat(service.isTrainingLocked(userId, EpreuveType.TCF_EE)).isFalse();
        assertThat(service.isTrainingLocked(userId, EpreuveType.TCF_EO)).isFalse();
    }

    /**
     * D-17 — l'essai gratuit d'entrainement par epreuve est <b>revoque</b> :
     * sans acces TCF, la verification en situation est <b>toujours</b>
     * verrouillee, et la lecture dit exactement ce que l'ecriture refuserait.
     */
    @Test
    void sansAccesTcfLaVerificationEstToujoursVerrouilleeD17() {
        when(subscriptionService.hasTcf(userId)).thenReturn(false);

        assertThat(service.isTrainingLocked(userId, EpreuveType.TCF_EE)).isTrue();
        assertThat(service.isTrainingLocked(userId, EpreuveType.TCF_EO)).isTrue();
        assertThatThrownBy(() -> service.enforceQuota(userId, EpreuveType.TCF_EE, null))
                .isInstanceOf(AccessDeniedException.class);
    }

    /** D-17 bis — deux gratuites NOMINATIVES : l'une consommee ne ferme pas l'autre. */
    @Test
    void lesDeuxGratuitesSontNominativesD17bis() {
        when(subscriptionService.hasTcf(userId)).thenReturn(false);
        when(freeExamEntitlementService.estConsomme(userId, EpreuveType.TCF_EE))
                .thenReturn(true);
        when(freeExamEntitlementService.estConsomme(userId, EpreuveType.TCF_EO))
                .thenReturn(false);

        assertThat(service.isProductionExamLocked(userId, EpreuveType.TCF_EE)).isTrue();
        assertThat(service.isProductionExamLocked(userId, EpreuveType.TCF_EO)).isFalse();
        // Le cadenas de l'examen blanc COMPLET n'a qu'un booleen a servir : il ne
        // se pose que quand la production n'apporte plus RIEN.
        assertThat(service.isFullExamProductionLocked(userId)).isFalse();
    }

    @Test
    void lesDeuxGratuitesConsommeesFermentLaProductionDeLExamenComplet() {
        when(subscriptionService.hasTcf(userId)).thenReturn(false);
        when(freeExamEntitlementService.estConsomme(any(), any())).thenReturn(true);

        assertThat(service.isFullExamProductionLocked(userId)).isTrue();
        assertThat(service.isFullExamProductionLocked(userId, EpreuveType.TCF_EO)).isTrue();
    }

    /** CO/CE gardent leur regle : slot 1 offert ET rejouable a volonte (D-17). */
    @Test
    void lesEpreuvesQcmNeSontJamaisVerrouilleesParCeLedger() {
        when(subscriptionService.hasTcf(userId)).thenReturn(false);

        assertThat(service.isProductionExamLocked(userId, EpreuveType.TCF_CO)).isFalse();
        assertThat(service.isProductionExamLocked(userId, EpreuveType.TCF_CE)).isFalse();
        verify(freeExamEntitlementService, never()).estConsomme(any(), any());
    }

    // ------------------------------------------------------------------------
    // D-17 bis — le paywall de l'ORAL se presente AU DEMARRAGE
    // ------------------------------------------------------------------------

    /**
     * Sans Whisper, un rejeu EO ne laisse <b>rien</b> a lire : aucun audio de
     * candidat n'est conserve. Faire produire dans le vide est un mauvais
     * geste — le refus tombe donc au demarrage.
     */
    @Test
    void leRejeuOralEstRefuseAuDemarrageD17bis() {
        when(subscriptionService.hasTcf(userId)).thenReturn(false);
        when(freeExamEntitlementService.estConsomme(userId, EpreuveType.TCF_EO))
                .thenReturn(true);

        assertThatThrownBy(() ->
                service.assertCanStartProductionExam(userId, EpreuveType.TCF_EO, 1))
                .isInstanceOf(AccessDeniedException.class)
                .hasMessageContaining("jamais conservé");
    }

    /**
     * A l'ecrit, le texte reste sous les yeux du candidat : le rejeu y est
     * <b>ouvert</b>, et c'est {@code enforceQuota} qui refusera l'analyse.
     */
    @Test
    void leRejeuEcritResteOuvertAuDemarrageD17bis() {
        when(subscriptionService.hasTcf(userId)).thenReturn(false);
        when(freeExamEntitlementService.estConsomme(userId, EpreuveType.TCF_EE))
                .thenReturn(true);

        assertThatCode(() ->
                service.assertCanStartProductionExam(userId, EpreuveType.TCF_EE, 1))
                .doesNotThrowAnyException();
    }

    /**
     * 🛑 La grille servie et le démarrage lisent la même règle
     * ({@code isProductionExamSlotLocked}) : créneau 1 offert (fermé à l'oral une
     * fois la gratuité consommée), 2+ aux abonnés TCF, tout ouvert à l'abonné.
     */
    @Test
    void creneauDeLaGrilleDeProduction_compteGratuitEtAbonne() {
        when(subscriptionService.hasTcf(userId)).thenReturn(false);
        when(freeExamEntitlementService.estConsomme(userId, EpreuveType.TCF_EO)).thenReturn(true);

        assertThat(service.isProductionExamSlotLocked(userId, EpreuveType.TCF_EE, 1)).isFalse();
        assertThat(service.isProductionExamSlotLocked(userId, EpreuveType.TCF_EE, 2)).isTrue();
        assertThat(service.isProductionExamSlotLocked(userId, EpreuveType.TCF_EO, 1)).isTrue();
        assertThatThrownBy(() -> service.assertCanStartProductionExam(userId, EpreuveType.TCF_EE, 2))
                .isInstanceOf(AccessDeniedException.class)
                .hasMessageContaining("au-delà du premier");

        when(subscriptionService.hasTcf(userId)).thenReturn(true);
        assertThat(service.isProductionExamSlotLocked(userId, EpreuveType.TCF_EO, 1)).isFalse();
        assertThat(service.isProductionExamSlotLocked(userId, EpreuveType.TCF_EE, 10)).isFalse();
    }

    private DiagnosticSession diagnosticSession(
            Attempt written, Attempt oral, ProductionTask writtenTask, ProductionTask oralTask) {
        DiagnosticSession session = new DiagnosticSession();
        session.setId(UUID.randomUUID());
        session.setUser(user(userId));
        session.setWrittenAttempt(written);
        session.setOralAttempt(oral);
        session.setWrittenTask(writtenTask);
        session.setOralTask(oralTask);
        return session;
    }
}
