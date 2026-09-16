package com.sejourfr.app.service.progres;

import com.sejourfr.app.dto.CivicDiagnosticResultDto;
import com.sejourfr.app.dto.CivicPlanDto;
import com.sejourfr.app.dto.PlanDomainAssessmentDto;
import com.sejourfr.app.dto.ProgressDto;
import com.sejourfr.app.dto.TcfLevelProfile;
import com.sejourfr.app.entity.CivicDiagnosticSession;
import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.TcfDiagnosticSession;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.CivicThemeState;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.PlanDomainAssessmentKind;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.enums.SkillMasteryState;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.StatutObjectif;
import com.sejourfr.app.enums.TcfDiagnosticSectionState;
import com.sejourfr.app.enums.TcfDiagnosticStatus;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.CivicDiagnosticSessionManager;
import com.sejourfr.app.manager.LearningPlanObservationManager;
import com.sejourfr.app.manager.TcfDiagnosticSessionManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.service.PlanDomainAssessmentResolver;
import com.sejourfr.app.service.SkillMasteryEngine;
import com.sejourfr.app.service.SkillMasteryResolver;
import com.sejourfr.app.service.SubscriptionService;
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
import static org.mockito.ArgumentMatchers.anyCollection;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * <b>« X compétences maîtrisées »</b> — le compteur de la carte « Votre
 * progression », servi tel quel au web et au mobile.
 *
 * <p>🛑 <b>Le défaut du 2026-09-16.</b> Cet écran filtrait encore sur
 * {@code state() == SOLID} pendant que le Plan de la même app rangeait la
 * compétence dans {@code completedSteps} / {@code ACQUIS} sur
 * {@code transferProven()}. Le parcours <b>normal</b> — cinq petits sujets puis
 * une vérification réussie — plafonne autour de {@code 0,68} et n'atteint donc
 * jamais {@code SOLID} : le candidat lisait « 0 compétence maîtrisée » en face
 * d'un Plan qui en cochait plusieurs.
 *
 * <p>Une règle, une autorité : c'est {@link SkillMasteryEngine.SkillMastery#transferProven()}
 * qui dit « acquis », ici comme ailleurs.
 */
class ProgressServiceTest {

    private UserManager userManager;
    private LearningPlanObservationManager observationManager;
    private SkillMasteryResolver masteryResolver;
    private SubscriptionService subscriptionService;
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
        observationManager = mock(LearningPlanObservationManager.class);
        masteryResolver = mock(SkillMasteryResolver.class);
        subscriptionService = mock(SubscriptionService.class);
        tcfSessionManager = mock(TcfDiagnosticSessionManager.class);
        tcfReadService = mock(TcfDiagnosticReadService.class);
        tcfDiagnosticService = mock(TcfDiagnosticService.class);
        tcfProfileService = mock(TcfProfileService.class);
        civicSessionManager = mock(CivicDiagnosticSessionManager.class);
        civicViewService = mock(CivicDiagnosticViewService.class);
        civicPlanService = mock(CivicPlanService.class);

        service = new ProgressService(
                userManager,
                mock(AttemptManager.class),
                tcfSessionManager,
                tcfReadService,
                tcfDiagnosticService,
                tcfProfileService,
                civicSessionManager,
                civicViewService,
                civicPlanService,
                observationManager,
                masteryResolver,
                subscriptionService,
                mock(ActiviteResolver.class),
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
        // Abonne : le DETAIL est servi, donc le test voit aussi QUELLES
        // competences sont tenues, pas seulement combien.
        when(subscriptionService.hasTcf(userId)).thenReturn(true);
    }

    /**
     * 🛑 Le cas du parcours normal : le transfert est prouvé, l'état agrégé ne
     * dit que {@code CONSOLIDATING}. La compétence est maîtrisée.
     */
    @Test
    @DisplayName("Transfert prouve sans SOLID : la competence compte comme maitrisee")
    void leTransfertProuveCompteMemeSansSolid() {
        Skill tenue = competence("EE1_ARGUMENTER", "Argumenter", SkillSection.EE);
        Skill fragile = competence("EO2_RACONTER", "Raconter", SkillSection.EO);
        Instant preuve = Instant.now().minus(2, ChronoUnit.DAYS);

        when(observationManager.findAllByUserWithSkill(userId)).thenReturn(List.of(
                observation(tenue, LearningPlanSkillStatus.SOLID, preuve),
                observation(fragile, LearningPlanSkillStatus.PRIORITY, preuve)));
        when(masteryResolver.bySkillIds(eq(userId), anyCollection())).thenReturn(Map.of(
                tenue.getId(), moteur(SkillMasteryState.CONSOLIDATING, true),
                fragile.getId(), moteur(SkillMasteryState.TO_REINFORCE, false)));

        ProgressDto.Competences competences = service.progres(userId).tcf().competences();

        assertThat(competences.travaillees()).isEqualTo(2);
        assertThat(competences.maitrisees()).isEqualTo(1);
        assertThat(competences.dernieres())
                .extracting(ProgressDto.CompetenceAcquise::code)
                .containsExactly("EE1_ARGUMENTER");
        // La date servie reste celle de la derniere observation SOLID : c'est
        // la preuve, et elle existe forcement — `transferProven` par la seconde
        // voie exige justement une reussite contextualisee.
        assertThat(competences.dernieres().getFirst().preuveA()).isEqualTo(preuve);
    }

    /** {@code SOLID} implique {@code transferProven} : rien ne se perd. */
    @Test
    @DisplayName("SOLID compte toujours, et une competence sans preuve ne compte pas")
    void solidCompteToujoursEtLeResteNon() {
        Skill solide = competence("CE1_LIRE", "Lire", SkillSection.CE);
        Skill jamaisTenue = competence("CO1_ECOUTER", "Ecouter", SkillSection.CO);

        when(observationManager.findAllByUserWithSkill(userId)).thenReturn(List.of(
                observation(solide, LearningPlanSkillStatus.SOLID, Instant.now()),
                observation(jamaisTenue, LearningPlanSkillStatus.TO_REINFORCE, Instant.now())));
        when(masteryResolver.bySkillIds(eq(userId), anyCollection())).thenReturn(Map.of(
                solide.getId(), moteur(SkillMasteryState.SOLID, true),
                jamaisTenue.getId(), SkillMasteryEngine.SkillMastery.NONE));

        ProgressDto.Competences competences = service.progres(userId).tcf().competences();

        assertThat(competences.travaillees()).isEqualTo(2);
        assertThat(competences.maitrisees()).isEqualTo(1);
    }

    /** Sans aucune observation, on ne conclut rien — et on n'invente aucun compteur. */
    @Test
    @DisplayName("Aucune observation : deux zeros, pas une estimation")
    void aucuneObservation() {
        when(observationManager.findAllByUserWithSkill(userId)).thenReturn(List.of());

        ProgressDto.Competences competences = service.progres(userId).tcf().competences();

        assertThat(competences.travaillees()).isZero();
        assertThat(competences.maitrisees()).isZero();
        assertThat(competences.dernieres()).isEmpty();
    }

    // ------------------------------------------------------------------------
    // Le STATUT d'une epreuve face a l'objectif (spec V2 §2)
    // ------------------------------------------------------------------------

    /**
     * 🛑 Le cas qui fait mal : trois épreuves mesurées à trois distances de
     * l'objectif, et une <b>jamais mesurée</b>. Les quatre sont servies, chacune
     * avec son statut — et l'épreuve non mesurée reste reconnaissable à son
     * {@code niveau == null}, pas à son statut.
     */
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

        // 🛑 Le booleen garde son sens : aucun diagnostic 4 epreuves n'est clos,
        // donc pas de courbe. Ce n'est plus lui qui commande la liste.
        assertThat(tcf.disponible()).isFalse();
        assertThat(tcf.historique()).isEmpty();
        assertThat(tcf.epreuves()).hasSize(4);
        assertThat(tcf.niveauActuel()).isEqualTo(NiveauCecrl.A2);

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
     * {@code CivicPlanService.compteurs(userId)} que les compteurs, donc du même
     * passage du moteur — et il arrive en {@code CivicThemeState} brut, les
     * fronts posant le libellé.
     */
    @Test
    @DisplayName("Le detail civique par theme est reexpose tel quel, etat brut compris")
    void leDetailCiviqueParThemeEstReexpose() {
        diagnosticCiviqueClos();
        when(civicPlanService.compteurs(userId)).thenReturn(new CivicPlanService.Compteurs(
                12, 3, false,
                List.of(
                        themeLigne("CIV_PRINCIPES", "Principes", CivicThemeState.SOLIDE),
                        themeLigne("CIV_SOCIETE", "Société", CivicThemeState.FAIBLE),
                        themeLigne("CIV_HISTOIRE", "Histoire", CivicThemeState.NON_EVALUE))));

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
        verify(civicPlanService, times(1)).compteurs(userId);
    }

    /** Aucun diagnostic civique clos : rien n'est inventé, pas même une liste. */
    @Test
    @DisplayName("Sans diagnostic civique clos, le detail par theme est vide")
    void sansDiagnosticCiviqueAucunTheme() {
        ProgressDto.Civique civique = service.progres(userId).civique();

        assertThat(civique.disponible()).isFalse();
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
        return new TcfDiagnosticReadService.Section(
                epreuve, UUID.randomUUID(), TcfDiagnosticSectionState.TERMINEE,
                null, niveau, null, false);
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

    private static Skill competence(String code, String titre, SkillSection section) {
        Skill skill = new Skill();
        skill.setId(UUID.randomUUID());
        skill.setCode(code);
        skill.setTitle(titre);
        skill.setSection(section);
        return skill;
    }

    private static LearningPlanObservation observation(
            Skill skill, LearningPlanSkillStatus status, Instant quand) {
        LearningPlanObservation observation = new LearningPlanObservation();
        observation.setSkill(skill);
        observation.setStatus(status);
        observation.setObservedAt(quand);
        return observation;
    }

    private static SkillMasteryEngine.SkillMastery moteur(
            SkillMasteryState state, boolean transferProven) {
        return new SkillMasteryEngine.SkillMastery(
                state, 0, 0, 0, 0, 0, false, false, transferProven, false, null);
    }
}
