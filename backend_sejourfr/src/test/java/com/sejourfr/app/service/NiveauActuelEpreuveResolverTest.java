package com.sejourfr.app.service;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.manager.AiEvaluationManager;
import com.sejourfr.app.manager.AttemptManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * <b>Le niveau ACTUEL estimé : la moyenne des 3 derniers examens
 * qualifiants.</b> Règle du propriétaire du 2026-09-16, qui <b>révoque</b> le
 * maximum monotone de la lecture d'affichage posé le matin même.
 *
 * <p>Ce que ce test verrouille, et pourquoi chaque cas compte :
 * <ul>
 *   <li>1 examen ⇒ son niveau ; 2 ⇒ la moyenne des 2 ; 4 ⇒ <b>seuls les 3
 *       derniers</b> — le plus ancien n'a plus voix ;</li>
 *   <li>🛑 <b>un mauvais examen récent FAIT BAISSER</b> le palier : c'est le cas
 *       exact que l'ancienne règle interdisait, et il est maintenant exigé ;</li>
 *   <li>on moyenne des <b>scores</b>, jamais des labels : la moyenne d'un B2 et
 *       d'un A2 n'est pas « le meilleur des deux » ;</li>
 *   <li>aucun examen qualifiant ⇒ {@code null} (« À évaluer »), jamais un
 *       plancher fabriqué.</li>
 * </ul>
 *
 * <p>Les deux tables de bandes sont <b>réelles</b> — {@link
 * TcfLevelEstimatorService} pour le score calibré, un vrai {@link
 * ProductionBilanService} sur les seuils par défaut (B2≥15, B1≥12, A2≥7) pour
 * la compétence. Aucun seuil n'est recopié ici, sans quoi ce test ne prouverait
 * que sa propre arithmétique.
 *
 * <p>🛑 <b>Ce qui n'est PAS ici</b> : quelles sessions sont qualifiantes. Les
 * deux définitions existent ailleurs et sont verrouillées ailleurs — la requête
 * {@code findQcmEpreuvesPassees} ({@code AttemptManagerIT}) et
 * {@link EpreuvesProductionQualifiantesResolver} (son propre test, plus
 * {@code EpreuveHistoriqueServiceIT}). L'exclusion de l'entraînement se vérifie
 * bout en bout dans {@code ProgressServiceIT}.
 */
class NiveauActuelEpreuveResolverTest {

    private static final int SCAN = 200;

    private AttemptManager attemptManager;
    private EpreuvesProductionQualifiantesResolver qualifiantesResolver;
    private NiveauActuelEpreuveResolver resolver;

    private final UUID userId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        attemptManager = mock(AttemptManager.class);
        qualifiantesResolver = mock(EpreuvesProductionQualifiantesResolver.class);
        final ProductionEvaluationProperties props = new ProductionEvaluationProperties();
        final ProductionRubricsProvider rubrics = mock(ProductionRubricsProvider.class);
        lenient().when(rubrics.niveauCecrl()).thenReturn(props.getNiveauCecrl());
        resolver = new NiveauActuelEpreuveResolver(
                attemptManager, qualifiantesResolver, new TcfLevelEstimatorService(),
                new ProductionBilanService(mock(AiEvaluationManager.class),
                        new TcfLevelEstimatorService(), rubrics, props));
    }

    // ------------------------------------------------------------- fixtures --

    /**
     * Un examen QCM passé, décrit par son <b>score pondéré sur 100</b> : c'est
     * lui qui porte le score calibré 100-499, donc la valeur qu'on moyenne.
     * {@code cecrl_level} est laissé vide exprès — le palier se redérive alors
     * du score, et le couple ne peut pas mentir.
     */
    private static Attempt qcm(int pondere, int maxPondere, Instant fin) {
        final Attempt a = new Attempt();
        a.setId(UUID.randomUUID());
        a.setFinishedAt(fin);
        a.setWeightedScore(pondere);
        a.setMaxWeightedScore(maxPondere);
        return a;
    }

    /** Les examens QCM d'une épreuve, <b>du plus récent au plus ancien</b>. */
    private void stubQcm(EpreuveType epreuve, int... pondereDuPlusRecentAuPlusAncien) {
        final Instant maintenant = Instant.now();
        final Attempt[] attempts = new Attempt[pondereDuPlusRecentAuPlusAncien.length];
        for (int i = 0; i < attempts.length; i++) {
            attempts[i] = qcm(pondereDuPlusRecentAuPlusAncien[i], 100,
                    maintenant.minus(i, ChronoUnit.DAYS));
        }
        when(attemptManager.findQcmEpreuvesPassees(eq(userId), eq(epreuve), anyInt()))
                .thenReturn(List.of(attempts));
    }

    /** Les épreuves complètes d'une production, <b>de la plus récente à la plus ancienne</b>. */
    private void stubProduction(EpreuveType epreuve, String... competences) {
        final Instant maintenant = Instant.now();
        final List<EpreuvesProductionQualifiantesResolver.EpreuveQualifiante> sessions =
                new java.util.ArrayList<>();
        for (int i = 0; i < competences.length; i++) {
            final BigDecimal c = new BigDecimal(competences[i]);
            sessions.add(new EpreuvesProductionQualifiantesResolver.EpreuveQualifiante(
                    new Attempt(), maintenant.minus(i, ChronoUnit.DAYS),
                    // Le palier de la session : il n'entre PAS dans la moyenne,
                    // c'est la compétence qui la porte. Le poser cohérent évite
                    // qu'un lecteur du test croie le contraire.
                    niveauDeReference(c), c));
        }
        when(qualifiantesResolver.qualifiantes(eq(userId), eq(epreuve), anyInt()))
                .thenReturn(List.copyOf(sessions));
    }

    /** Bandes par défaut de {@code ProductionEvaluationProperties} : B2≥15, B1≥12, A2≥7. */
    private static NiveauCecrl niveauDeReference(BigDecimal competence) {
        final double c = competence.doubleValue();
        if (c >= 15) return NiveauCecrl.B2;
        if (c >= 12) return NiveauCecrl.B1;
        if (c >= 7) return NiveauCecrl.A2;
        return NiveauCecrl.A1;
    }

    // ---------------------------------------------------- aucune mesure --

    @Test
    @DisplayName("🛑 Aucun examen qualifiant ⇒ null (« À évaluer »), jamais un plancher")
    void aucunExamenQualifiant_rendNull() {
        when(attemptManager.findQcmEpreuvesPassees(eq(userId), eq(EpreuveType.TCF_CO), anyInt()))
                .thenReturn(List.of());
        when(qualifiantesResolver.qualifiantes(eq(userId), eq(EpreuveType.TCF_EO), anyInt()))
                .thenReturn(List.of());

        assertThat(resolver.qcm(userId, EpreuveType.TCF_CO, SCAN)).isNull();
        assertThat(resolver.production(userId, EpreuveType.TCF_EO, SCAN)).isNull();
    }

    // ----------------------------------------------------------- CO / CE --

    @Test
    @DisplayName("1 examen ⇒ le niveau de cet examen")
    void unSeulExamen_rendSonNiveau() {
        // 63/100 pondéré ⇒ score calibré 302 ⇒ bande B1.
        stubQcm(EpreuveType.TCF_CO, 63);

        assertThat(resolver.qcm(userId, EpreuveType.TCF_CO, SCAN)).isEqualTo(NiveauCecrl.B1);
    }

    /**
     * 🛑 <b>La moyenne n'est ni le meilleur ni le dernier.</b> Un B2 (419) et un
     * A2 (206) donnent 312,5 ⇒ B1 : un palier qu'aucun des deux examens n'a
     * obtenu, et c'est exactement ce que « niveau actuel estimé » veut dire.
     */
    @Test
    @DisplayName("2 examens ⇒ la moyenne des 2, pas le meilleur")
    void deuxExamens_moyenneDesDeux() {
        stubQcm(EpreuveType.TCF_CO, 45, 85);

        assertThat(resolver.qcm(userId, EpreuveType.TCF_CO, SCAN)).isEqualTo(NiveauCecrl.B1);
    }

    /**
     * 🛑 <b>LE cas que l'ancienne règle interdisait.</b> Deux B2 puis un examen
     * raté aujourd'hui : le maximum monotone affichait B2 pour toujours, la
     * moyenne affiche B1. Le niveau descend, et c'est la demande.
     */
    @Test
    @DisplayName("🛑 Un mauvais examen RÉCENT fait BAISSER le niveau affiché")
    void unMauvaisExamenRecentFaitBaisserLeNiveau() {
        stubQcm(EpreuveType.TCF_CO, 85, 85);
        assertThat(resolver.qcm(userId, EpreuveType.TCF_CO, SCAN))
                .as("avant la mauvaise journée")
                .isEqualTo(NiveauCecrl.B2);

        // Le même candidat, un examen raté de plus, aujourd'hui.
        stubQcm(EpreuveType.TCF_CO, 25, 85, 85);

        assertThat(resolver.qcm(userId, EpreuveType.TCF_CO, SCAN))
                .as("le maximum monotone est révoqué : le niveau redescend")
                .isEqualTo(NiveauCecrl.B1);
    }

    /**
     * 🛑 <b>Fenêtre de 3, et seulement 3.</b> Un sans-faute d'il y a quatre
     * examens ne peut plus tenir le palier : sans la fenêtre, la moyenne des
     * quatre vaudrait 279 (A2 ici, mais surtout un autre nombre).
     */
    @Test
    @DisplayName("🛑 4 examens ⇒ seuls les 3 DERNIERS comptent, le plus ancien est ignoré")
    void quatreExamens_seulsLesTroisDerniersComptent() {
        // 61/100 ⇒ 292 (A2) ; 100/100 ⇒ 499 (B2), et c'est le PLUS ANCIEN.
        // Moyenne des 3 derniers : 292 ⇒ A2. Moyenne des quatre : 343 ⇒ B1. La
        // fenêtre change donc la bande — le cas prouve quelque chose.
        stubQcm(EpreuveType.TCF_CE, 61, 61, 61, 100);

        assertThat(resolver.qcm(userId, EpreuveType.TCF_CE, SCAN)).isEqualTo(NiveauCecrl.A2);

        // Le contrôle : les mêmes 3 récents, sans le vieux sans-faute — même
        // résultat, donc le 4ᵉ n'a réellement rien pesé.
        stubQcm(EpreuveType.TCF_CE, 61, 61, 61);
        assertThat(resolver.qcm(userId, EpreuveType.TCF_CE, SCAN)).isEqualTo(NiveauCecrl.A2);
    }

    /**
     * 🛑 <b>Une moyenne entre deux bandes reste dans la bande BASSE</b> —
     * convention du dépôt, déjà celle des notes de critère. 399 et 400
     * encadrent la frontière B1/B2 : leur moyenne 399,5 reste B1.
     */
    @Test
    @DisplayName("🛑 Une moyenne entre deux bandes reste dans la bande BASSE")
    void uneMoyenneEntreDeuxBandesResteDansLaBandeBasse() {
        // Deux examens calibrés 400 (B2, pile la borne) et 399 (B1, un point
        // sous). Leur moyenne vaut 399,5 : elle tombe ENTRE les deux bandes.
        final Instant maintenant = Instant.now();
        when(attemptManager.findQcmEpreuvesPassees(eq(userId), eq(EpreuveType.TCF_CO), anyInt()))
                .thenReturn(List.of(
                        qcm(8139, 10000, maintenant),
                        qcm(8120, 10000, maintenant.minus(1, ChronoUnit.DAYS))));

        assertThat(resolver.qcm(userId, EpreuveType.TCF_CO, SCAN))
                .as("399,5 reste dans la bande BASSE")
                .isEqualTo(NiveauCecrl.B1);
    }

    /**
     * Le <b>plancher produit</b> « au moins une bonne réponse ⇒ au moins A1 »
     * survit à la moyenne : il est vrai de la moyenne dès qu'il était vrai d'un
     * des examens retenus, et il n'est pas recodé ici.
     */
    @Test
    @DisplayName("Le plancher produit A1 survit à la moyenne, sans être recodé")
    void plancherProduitA1_survitALaMoyenne() {
        stubQcm(EpreuveType.TCF_CO, 1, 1);
        assertThat(resolver.qcm(userId, EpreuveType.TCF_CO, SCAN)).isEqualTo(NiveauCecrl.A1);

        // Zéro bonne réponse partout : le plancher ne rachète rien.
        stubQcm(EpreuveType.TCF_CE, 0, 0);
        assertThat(resolver.qcm(userId, EpreuveType.TCF_CE, SCAN))
                .isEqualTo(NiveauCecrl.A1_NON_ATTEINT);
    }

    /**
     * Un examen ancien sans score pondéré n'a rien de moyennable ; son palier
     * persisté reste le repli, et c'est {@code niveauEpreuveQcm} qui le rend —
     * pas une seconde règle écrite ici.
     */
    @Test
    @DisplayName("Sans aucun score moyennable, le palier du plus récent fait foi")
    void sansScoreMoyennable_lePalierDuPlusRecentFaitFoi() {
        final Attempt legacy = new Attempt();
        legacy.setId(UUID.randomUUID());
        legacy.setFinishedAt(Instant.now());
        legacy.setCecrlLevel(NiveauCecrl.B1);
        when(attemptManager.findQcmEpreuvesPassees(eq(userId), eq(EpreuveType.TCF_CO), anyInt()))
                .thenReturn(List.of(legacy));

        assertThat(resolver.qcm(userId, EpreuveType.TCF_CO, SCAN)).isEqualTo(NiveauCecrl.B1);
    }

    // ----------------------------------------------------------- EE / EO --

    @Test
    @DisplayName("Production : 1 épreuve complète ⇒ son niveau")
    void production_uneSeuleEpreuve_rendSonNiveau() {
        stubProduction(EpreuveType.TCF_EE, "13");

        assertThat(resolver.production(userId, EpreuveType.TCF_EE, SCAN))
                .isEqualTo(NiveauCecrl.B1);
    }

    /** Un B2 (16) et un A2 (8) donnent 12 ⇒ B1. Pas le meilleur, pas le dernier. */
    @Test
    @DisplayName("Production : 2 épreuves ⇒ la moyenne des compétences, pas le meilleur palier")
    void production_deuxEpreuves_moyenneDesCompetences() {
        stubProduction(EpreuveType.TCF_EE, "8", "16");

        assertThat(resolver.production(userId, EpreuveType.TCF_EE, SCAN))
                .isEqualTo(NiveauCecrl.B1);
    }

    @Test
    @DisplayName("🛑 Production : 4 épreuves ⇒ seules les 3 dernières comptent")
    void production_quatreEpreuves_seulesLesTroisDernieresComptent() {
        // 3 dernières à 11 (A2), la plus ANCIENNE à 20. Moyenne des 3 : 11 ⇒
        // A2. Moyenne des quatre : 13,25 ⇒ B1. La fenêtre change la bande.
        stubProduction(EpreuveType.TCF_EO, "11", "11", "11", "20");

        assertThat(resolver.production(userId, EpreuveType.TCF_EO, SCAN))
                .as("un 20 d'il y a quatre épreuves ne tient plus le palier")
                .isEqualTo(NiveauCecrl.A2);

        // Le contrôle : les mêmes 3 récentes, sans la vieille épreuve.
        stubProduction(EpreuveType.TCF_EO, "11", "11", "11");
        assertThat(resolver.production(userId, EpreuveType.TCF_EO, SCAN))
                .isEqualTo(NiveauCecrl.A2);
    }

    /** 🛑 Le même cas que côté QCM : une épreuve récente ratée fait redescendre. */
    @Test
    @DisplayName("🛑 Production : une épreuve RÉCENTE ratée fait BAISSER le niveau affiché")
    void production_uneEpreuveRecenteRateeFaitBaisser() {
        stubProduction(EpreuveType.TCF_EO, "16", "16");
        assertThat(resolver.production(userId, EpreuveType.TCF_EO, SCAN))
                .isEqualTo(NiveauCecrl.B2);

        stubProduction(EpreuveType.TCF_EO, "7", "16", "16");
        assertThat(resolver.production(userId, EpreuveType.TCF_EO, SCAN))
                .as("moyenne 13 ⇒ B1 : le maximum monotone est révoqué")
                .isEqualTo(NiveauCecrl.B1);
    }

    /**
     * Une session dont le palier vient du repli sur les niveaux persistés ne
     * porte pas de compétence : le palier de la plus récente fait foi, plutôt
     * qu'une moyenne sur rien.
     */
    @Test
    @DisplayName("Production : sans compétence moyennable, le palier de la plus récente fait foi")
    void production_sansCompetence_lePalierDeLaPlusRecenteFaitFoi() {
        when(qualifiantesResolver.qualifiantes(eq(userId), eq(EpreuveType.TCF_EE), anyInt()))
                .thenReturn(Arrays.asList(
                        new EpreuvesProductionQualifiantesResolver.EpreuveQualifiante(
                                new Attempt(), Instant.now(), NiveauCecrl.A2, null),
                        new EpreuvesProductionQualifiantesResolver.EpreuveQualifiante(
                                new Attempt(), Instant.now().minus(2, ChronoUnit.DAYS),
                                NiveauCecrl.B2, null)));

        assertThat(resolver.production(userId, EpreuveType.TCF_EE, SCAN))
                .isEqualTo(NiveauCecrl.A2);
    }

    /** Tout reste plafonné B2 : l'IRN ne certifie pas au-delà. */
    @Test
    @DisplayName("Le niveau reste plafonné B2")
    void plafonneB2() {
        stubProduction(EpreuveType.TCF_EE, "20", "20");

        assertThat(resolver.production(userId, EpreuveType.TCF_EE, SCAN))
                .isEqualTo(NiveauCecrl.B2);
    }
}
