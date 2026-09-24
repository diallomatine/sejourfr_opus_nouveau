package com.sejourfr.app.service.progres;

import com.sejourfr.app.dto.CivicDiagnosticResultDto;
import com.sejourfr.app.dto.CivicPlanDto;
import com.sejourfr.app.dto.PlanDomainAssessmentDto;
import com.sejourfr.app.dto.ProgressDto;
import com.sejourfr.app.dto.TcfLevelProfile;
import com.sejourfr.app.entity.CivicDiagnosticSession;
import com.sejourfr.app.entity.TcfDiagnosticSession;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.CivicThemeState;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.PlanDomainAssessmentKind;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.enums.StatutObjectif;
import com.sejourfr.app.enums.TcfDiagnosticSectionState;
import com.sejourfr.app.enums.TcfDiagnosticStatus;
import com.sejourfr.app.manager.CivicDiagnosticSessionManager;
import com.sejourfr.app.manager.TcfDiagnosticSessionManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.service.PlanDomainAssessmentResolver;
import com.sejourfr.app.service.TcfProfileService;
import com.sejourfr.app.service.diagnosticcivique.CivicDiagnosticViewService;
import com.sejourfr.app.service.diagnostictcf.TcfDiagnosticReadService;
import com.sejourfr.app.service.diagnostictcf.TcfDiagnosticService;
import com.sejourfr.app.service.plancivique.CivicPlanGrain;
import com.sejourfr.app.service.plancivique.CivicPlanService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.tuple;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * <b>« Où vous en êtes »</b> de l'Accueil ({@code GET /api/me/progress}) : les
 * 4 épreuves, leur statut face à l'objectif, leur descripteur de mesure, et le
 * détail civique par thème.
 *
 * <p>⚠️ Les tests des compteurs de compétences, de l'activité et de la courbe
 * des diagnostics sont partis le 2026-09-24 avec l'ancien écran « Votre
 * progression », leur seul lecteur.
 */
class ProgressServiceTest {

    private UserManager userManager;
    private TcfDiagnosticSessionManager tcfSessionManager;
    private TcfDiagnosticReadService tcfReadService;
    private TcfDiagnosticService tcfDiagnosticService;
    private TcfProfileService tcfProfileService;
    private CivicDiagnosticSessionManager civicSessionManager;
    private CivicDiagnosticViewService civicViewService;
    private CivicPlanService civicPlanService;
    private ProgressService service;

    private final UUID userId = UUID.randomUUID();
    private User user;

    @BeforeEach
    void setUp() {
        userManager = mock(UserManager.class);
        tcfSessionManager = mock(TcfDiagnosticSessionManager.class);
        tcfReadService = mock(TcfDiagnosticReadService.class);
        tcfDiagnosticService = mock(TcfDiagnosticService.class);
        tcfProfileService = mock(TcfProfileService.class);
        civicSessionManager = mock(CivicDiagnosticSessionManager.class);
        civicViewService = mock(CivicDiagnosticViewService.class);
        civicPlanService = mock(CivicPlanService.class);

        service = new ProgressService(
                userManager,
                tcfSessionManager,
                tcfReadService,
                tcfDiagnosticService,
                tcfProfileService,
                civicSessionManager,
                civicViewService,
                civicPlanService,
                // 🛑 Le VRAI resolveur : c'est lui l'autorite du statut, et le
                // mocker ne verrouillerait que le fait de l'appeler.
                new StatutObjectifResolver(),
                // 🛑 Le VRAI resolveur, la encore : ce test verrouille QUEL
                // parcours est designe, pas le fait d'appeler quelqu'un.
                new PlanDomainAssessmentResolver());

        user = new User();
        user.setId(userId);
        when(userManager.findById(userId)).thenReturn(Optional.of(user));
        // Le profil TCF est lu a CHAQUE lecture depuis le 2026-09-16, y compris
        // sans diagnostic clos : les 4 epreuves ne dependent plus de lui.
        //
        // 🛑 `levelProfileAccueil`, PAS `levelProfile` : c'est la lecture ou EE
        // et EO n'existent que par une EPREUVE COMPLETE. Que ce soit un stub
        // different est justement ce qui rend visible, ici, que l'ecran ne lit
        // pas la meme chose que le Plan.
        when(tcfProfileService.levelProfileAccueil(userId)).thenReturn(
                new TcfLevelProfile(null, null, null, null, null));
    }

    @Test
    @DisplayName("Le statut de chaque epreuve est derive serveur de actuel vs objectif")
    void leStatutEstServiParEpreuve() {
        // Objectif B2 (naturalisation) : CO au-dessus, CE pile dessus, EE un
        // cran en dessous, EO jamais evaluee.
        diagnosticClos(NiveauCecrl.A2, NiveauCecrl.A2, NiveauCecrl.A2, null);
        when(tcfDiagnosticService.cible(user)).thenReturn(Optional.of(NiveauCecrl.B2));
        when(tcfProfileService.levelProfileAccueil(userId)).thenReturn(new TcfLevelProfile(
                NiveauCecrl.B2, NiveauCecrl.B2, NiveauCecrl.B1, null, NiveauCecrl.B1));

        Map<EpreuveType, ProgressDto.Epreuve> parEpreuve = service.progres(userId).tcf()
                .epreuves().stream()
                .collect(java.util.stream.Collectors.toMap(
                        ProgressDto.Epreuve::epreuve, e -> e));

        assertThat(parEpreuve).hasSize(4);
        assertThat(parEpreuve.get(EpreuveType.TCF_CO).status())
                .isEqualTo(StatutObjectif.TARGET_REACHED);
        assertThat(parEpreuve.get(EpreuveType.TCF_CE).status())
                .isEqualTo(StatutObjectif.TARGET_REACHED);
        assertThat(parEpreuve.get(EpreuveType.TCF_EE).status())
                .isEqualTo(StatutObjectif.CLOSE_TO_TARGET);
        assertThat(parEpreuve.get(EpreuveType.TCF_EO).status())
                .isEqualTo(StatutObjectif.TO_REINFORCE);
        // 🛑 POINT 17 de l'audit : « jamais mesuré » ne se fond PAS dans
        // « mesuré faible ». Le statut est le même, le niveau tranche.
        assertThat(parEpreuve.get(EpreuveType.TCF_EO).niveau()).isNull();
        assertThat(parEpreuve.get(EpreuveType.TCF_EE).niveau()).isEqualTo(NiveauCecrl.B1);
    }

    /**
     * 🛑 Aucune démarche déclarée : pas de palier exigé, donc pas de statut. On
     * ne range personne dans le verdict le plus bas faute d'objectif.
     */
    @Test
    @DisplayName("🛑 Sans demarche declaree, aucun statut n'est servi")
    void sansObjectifAucunStatut() {
        diagnosticClos(NiveauCecrl.B1, NiveauCecrl.B1, NiveauCecrl.B1, NiveauCecrl.B1);
        when(tcfDiagnosticService.cible(user)).thenReturn(Optional.empty());
        when(tcfProfileService.levelProfileAccueil(userId)).thenReturn(new TcfLevelProfile(
                NiveauCecrl.B1, NiveauCecrl.B1, NiveauCecrl.B1, NiveauCecrl.B1,
                NiveauCecrl.B1));

        ProgressDto.Tcf tcf = service.progres(userId).tcf();

        assertThat(tcf.objectif()).isNull();
        assertThat(tcf.epreuves()).isNotEmpty();
        assertThat(tcf.epreuves()).allSatisfy(e -> assertThat(e.status()).isNull());
    }

    /**
     * 🛑 <b>L'Accueil ne lit JAMAIS la lecture du Plan</b> (arbitrage du
     * 2026-09-16). {@code levelProfile} voit les entraînements EE/EO évalués —
     * utile aux priorités et aux compétences, jamais à l'affichage d'un niveau
     * global. Un retour à {@code levelProfile} ici reproduirait le défaut du
     * compte qui affichait « expression orale : A2 » sans avoir passé d'épreuve.
     * Le comportement bout en bout est verrouillé par
     * {@code ProgressServiceIT.lEntrainementRenseigneLePlanPasLAccueil}.
     */
    @Test
    @DisplayName("🛑 L'Accueil lit levelProfileAccueil, jamais la lecture du Plan")
    void lAccueilNeLitQueSaPropreLecture() {
        service.progres(userId);

        verify(tcfProfileService).levelProfileAccueil(userId);
        verify(tcfProfileService, never()).levelProfile(userId);
    }

    // ------------------------------------------------------------------------
    // « Ou vous en etes » — la section n'attend plus le diagnostic 4 epreuves
    // ------------------------------------------------------------------------

    /**
     * 🛑 Le défaut du 2026-09-16 : un candidat dont la CO et la CE étaient
     * mesurées par des examens de module ne voyait <b>aucune</b> carte
     * d'épreuve sur l'Accueil, parce que la réponse entière était coupée faute
     * de diagnostic 4 épreuves clos. Le palier, lui, existait déjà — il vient
     * du profil TCF, pas du diagnostic.
     */
    @Test
    @DisplayName("🛑 Les 4 epreuves sont servies MEME sans diagnostic 4 epreuves clos")
    void lesEpreuvesNeDependentPlusDuDiagnostic() {
        // Aucun diagnostic TCF clos, mais une CO et une CE deja mesurees.
        when(tcfSessionManager.findAllByUser(userId)).thenReturn(List.of());
        when(tcfDiagnosticService.cible(user)).thenReturn(Optional.of(NiveauCecrl.B1));
        when(tcfProfileService.levelProfileAccueil(userId)).thenReturn(new TcfLevelProfile(
                NiveauCecrl.B1, NiveauCecrl.A2, null, null, NiveauCecrl.A2));

        ProgressDto.Tcf tcf = service.progres(userId).tcf();

        assertThat(tcf.epreuves()).hasSize(4);

        Map<EpreuveType, ProgressDto.Epreuve> parEpreuve = parEpreuve(tcf);
        assertThat(parEpreuve.get(EpreuveType.TCF_CO).niveau()).isEqualTo(NiveauCecrl.B1);
        assertThat(parEpreuve.get(EpreuveType.TCF_CE).niveau()).isEqualTo(NiveauCecrl.A2);
        assertThat(parEpreuve.get(EpreuveType.TCF_EE).niveau()).isNull();
        // 🛑 Aucun diagnostic clos : pas de palier INITIAL, donc pas d'evolution
        // fabriquee. INCONNUE, jamais STABLE.
        assertThat(tcf.epreuves()).allSatisfy(e ->
                assertThat(e.niveauInitial()).isNull());
    }

    /**
     * 🛑 Le vrai travail de la passe : la carte d'une épreuve jamais mesurée
     * porte <b>de quoi la lancer</b>, et c'est le descripteur du Plan — pas un
     * second mécanisme. CO/CE partent sur l'examen blanc de module, EE/EO sur
     * l'examen blanc de production, tous sur le <b>slot offert</b>.
     */
    @Test
    @DisplayName("Epreuve jamais evaluee : le descripteur de mesure du Plan est servi")
    void uneEpreuveJamaisEvalueePorteSaMesure() {
        when(tcfSessionManager.findAllByUser(userId)).thenReturn(List.of());
        when(tcfDiagnosticService.cible(user)).thenReturn(Optional.of(NiveauCecrl.B1));
        when(tcfProfileService.levelProfileAccueil(userId)).thenReturn(
                new TcfLevelProfile(null, null, null, null, null));

        Map<EpreuveType, ProgressDto.Epreuve> parEpreuve = parEpreuve(service.progres(userId).tcf());

        PlanDomainAssessmentDto co = parEpreuve.get(EpreuveType.TCF_CO).evaluation();
        assertThat(co).isNotNull();
        assertThat(co.kind()).isEqualTo(PlanDomainAssessmentKind.MODULE_MOCK_EXAM);
        assertThat(co.epreuve()).isEqualTo(EpreuveType.TCF_CO);
        assertThat(co.moduleExamQuestionType()).isEqualTo(QuestionType.CO);
        // 🛑 Le slot OFFERT : mesurer un domaine ne doit jamais buter sur le
        // paywall.
        assertThat(co.slotNumber()).isEqualTo(1);
        assertThat(co.estimatedMinutes()).isPositive();

        assertThat(parEpreuve.get(EpreuveType.TCF_CE).evaluation().moduleExamQuestionType())
                .isEqualTo(QuestionType.CE);

        // 🛑 L'expression aussi : un examen blanc de production, slot offert.
        assertThat(parEpreuve.get(EpreuveType.TCF_EE).evaluation().kind())
                .isEqualTo(PlanDomainAssessmentKind.PRODUCTION_MOCK_EXAM);
        assertThat(parEpreuve.get(EpreuveType.TCF_EE).evaluation().slotNumber()).isEqualTo(1);
        assertThat(parEpreuve.get(EpreuveType.TCF_EO).evaluation().kind())
                .isEqualTo(PlanDomainAssessmentKind.PRODUCTION_MOCK_EXAM);
        assertThat(parEpreuve.get(EpreuveType.TCF_EO).evaluation().slotNumber()).isEqualTo(1);
    }

    /**
     * 🛑 Un diagnostic terminé ne change <b>rien</b> à la mesure proposée
     * (arbitrage du propriétaire, 2026-09-16) : une épreuve d'expression encore
     * vide repart sur son <b>examen blanc</b>, jamais sur l'entraînement libre.
     * C'est exactement la règle de {@code PlanDomainAssessmentResolver},
     * appelée et non recopiée.
     */
    @Test
    @DisplayName("Diagnostic termine : EE/EO jamais evaluees repartent sur l'examen blanc")
    void diagnosticTermineRenvoieVersLExamenBlanc() {
        diagnosticClos(NiveauCecrl.A2, NiveauCecrl.A2, null, null);
        when(tcfDiagnosticService.cible(user)).thenReturn(Optional.of(NiveauCecrl.B1));
        when(tcfProfileService.levelProfileAccueil(userId)).thenReturn(new TcfLevelProfile(
                NiveauCecrl.A2, NiveauCecrl.A2, null, null, NiveauCecrl.A2));

        Map<EpreuveType, ProgressDto.Epreuve> parEpreuve = parEpreuve(service.progres(userId).tcf());

        assertThat(parEpreuve.get(EpreuveType.TCF_EE).evaluation().kind())
                .isEqualTo(PlanDomainAssessmentKind.PRODUCTION_MOCK_EXAM);
        assertThat(parEpreuve.get(EpreuveType.TCF_EO).evaluation().kind())
                .isEqualTo(PlanDomainAssessmentKind.PRODUCTION_MOCK_EXAM);
        // 🛑 Et rien a lancer sur ce qui est deja mesure : on ne propose pas de
        // refaire une mesure qui existe.
        assertThat(parEpreuve.get(EpreuveType.TCF_CO).evaluation()).isNull();
        assertThat(parEpreuve.get(EpreuveType.TCF_CE).evaluation()).isNull();
    }

    // ------------------------------------------------------------------------
    // Le DETAIL civique par theme (audit §D)
    // ------------------------------------------------------------------------

    /**
     * 🛑 Le détail par thème est <b>réexposé</b>, pas recalculé : il sort du même
     * {@code CivicPlanService.themesAccueil(userId)}, donc du même
     * passage du moteur que le Plan — et il arrive en {@code CivicThemeState} brut, les
     * fronts posant le libellé.
     */
    @Test
    @DisplayName("Le detail civique par theme est reexpose tel quel, etat brut compris")
    void leDetailCiviqueParThemeEstReexpose() {
        diagnosticCiviqueClos();
        when(civicPlanService.themesAccueil(userId)).thenReturn(List.of(
                themeLigne("CIV_PRINCIPES", "Principes", CivicThemeState.SOLIDE),
                themeLigne("CIV_SOCIETE", "Société", CivicThemeState.FAIBLE),
                themeLigne("CIV_HISTOIRE", "Histoire", CivicThemeState.NON_EVALUE)));

        ProgressDto.Civique civique = service.progres(userId).civique();

        assertThat(civique.themes())
                .extracting(CivicPlanDto.ThemeLigne::code, CivicPlanDto.ThemeLigne::etat)
                .containsExactly(
                        tuple("CIV_PRINCIPES", CivicThemeState.SOLIDE),
                        // 🛑 FAIBLE (mesuré bas) et NON_EVALUE (jamais posé) ne
                        // se confondent pas : c'est la doctrine du module, et
                        // l'incident V040/V041/V042 sous un autre déguisement.
                        tuple("CIV_SOCIETE", CivicThemeState.FAIBLE),
                        tuple("CIV_HISTOIRE", CivicThemeState.NON_EVALUE));
        // 🛑 Le moteur civique n'est relu QU'UNE fois pour la même requête.
        verify(civicPlanService, times(1)).themesAccueil(userId);
        // Et le dernier score du diagnostic, que l'Accueil affiche.
        assertThat(civique.historique()).singleElement()
                .satisfies(sc -> assertThat(sc.bonnes()).isEqualTo(28));
    }

    /** Aucun diagnostic civique clos : rien n'est inventé, pas même une liste. */
    @Test
    @DisplayName("Sans diagnostic civique clos, le detail par theme est vide")
    void sansDiagnosticCiviqueAucunTheme() {
        ProgressDto.Civique civique = service.progres(userId).civique();

        assertThat(civique.historique()).isEmpty();
        assertThat(civique.themes()).isEmpty();
    }

    // ------------------------------------------------------------------------

    private static Map<EpreuveType, ProgressDto.Epreuve> parEpreuve(ProgressDto.Tcf tcf) {
        return tcf.epreuves().stream().collect(java.util.stream.Collectors.toMap(
                ProgressDto.Epreuve::epreuve, e -> e));
    }

    private static TcfDiagnosticSession session(TcfDiagnosticStatus status) {
        TcfDiagnosticSession session = new TcfDiagnosticSession();
        session.setId(UUID.randomUUID());
        session.setStatus(status);
        session.setCompletedAt(Instant.now().minus(3, ChronoUnit.DAYS));
        return session;
    }

    /** Un diagnostic TCF clos, dont les 4 sections portent les niveaux donnés. */
    private void diagnosticClos(
            NiveauCecrl co, NiveauCecrl ce, NiveauCecrl ee, NiveauCecrl eo) {
        TcfDiagnosticSession session = session(TcfDiagnosticStatus.COMPLETED);
        when(tcfSessionManager.findAllByUser(userId)).thenReturn(List.of(session));
        when(tcfReadService.sections(session)).thenReturn(List.of(
                section(EpreuveType.TCF_CO, co),
                section(EpreuveType.TCF_CE, ce),
                section(EpreuveType.TCF_EE, ee),
                section(EpreuveType.TCF_EO, eo)));
    }

    private static TcfDiagnosticReadService.Section section(
            EpreuveType epreuve, NiveauCecrl niveau) {
        UUID attemptId = UUID.randomUUID();
        return new TcfDiagnosticReadService.Section(
                epreuve, attemptId, TcfDiagnosticSectionState.TERMINEE,
                null, niveau, null, false, niveau == null ? null : attemptId);
    }

    private void diagnosticCiviqueClos() {
        CivicDiagnosticSession session = new CivicDiagnosticSession();
        session.setId(UUID.randomUUID());
        session.setStatus(TcfDiagnosticStatus.COMPLETED);
        session.setCompletedAt(Instant.now().minus(1, ChronoUnit.DAYS));
        when(civicSessionManager.findAllByUser(userId)).thenReturn(List.of(session));
        when(civicViewService.resultat(session)).thenReturn(new CivicDiagnosticResultDto(
                session.getId(), Difficulty.NAT, 28, 40, null, 32, 40,
                List.of(), null, List.of(), session.getCompletedAt()));
    }

    private static CivicPlanDto.ThemeLigne themeLigne(
            String code, String label, CivicThemeState etat) {
        return new CivicPlanDto.ThemeLigne(
                UUID.randomUUID(), code, label, etat,
                CivicPlanGrain.THEME, 5, 1, 3, null);
    }
}
