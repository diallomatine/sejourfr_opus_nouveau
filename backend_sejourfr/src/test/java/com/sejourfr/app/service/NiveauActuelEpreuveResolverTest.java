package com.sejourfr.app.service;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.dto.LigneStrateQcm;
import com.sejourfr.app.dto.StrateQcm;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.manager.AiEvaluationManager;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.AttemptQuestionManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
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
 *   <li>🛑 <b>un historique récent dégradé FAIT BAISSER</b> le palier : c'est
 *       le cas exact que l'ancienne règle interdisait, et il est maintenant
 *       exigé ;</li>
 *   <li>on moyenne des <b>mesures</b>, jamais des labels : le résultat de deux
 *       examens n'est ni le meilleur ni le dernier.</li>
 *   <li>aucun examen qualifiant ⇒ {@code null} (« À évaluer »), jamais un
 *       plancher fabriqué.</li>
 * </ul>
 *
 * <p>🛑 <b>Côté CO/CE, « moyenner » veut dire CUMULER LES ITEMS</b> depuis le
 * 2026-09-20 : il n'existe plus de table « score → palier » à moyenner, le
 * palier se lit strate par strate. Les strates des examens retenus sont donc
 * additionnées, puis relues par l'autorité unique. Conséquence assumée, et
 * visible dans les cas ci-dessous : le palier est plus <b>inerte</b> qu'une
 * moyenne de scores — un seul mauvais examen sur trois ne le fait pas tomber,
 * un historique récent dégradé si.
 *
 * <p>Les tables sont <b>réelles</b> — le vrai {@link TcfLevelEstimatorService}
 * pour le palier QCM, un vrai {@link ProductionBilanService} sur les seuils par
 * défaut (B2≥15, B1≥12, A2≥7) pour la compétence. Aucun seuil n'est recopié
 * ici, sans quoi ce test ne prouverait que sa propre arithmétique.
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
    private AttemptQuestionManager attemptQuestionManager;
    /** Ce que les réponses de chaque examen QCM ont réellement mesuré. */
    private final Map<UUID, List<StrateQcm>> strates = new HashMap<>();

    @BeforeEach
    void setUp() {
        attemptManager = mock(AttemptManager.class);
        qualifiantesResolver = mock(EpreuvesProductionQualifiantesResolver.class);
        final ProductionEvaluationProperties props = new ProductionEvaluationProperties();
        final ProductionRubricsProvider rubrics = mock(ProductionRubricsProvider.class);
        lenient().when(rubrics.niveauCecrl()).thenReturn(props.getNiveauCecrl());
        attemptQuestionManager = mock(AttemptQuestionManager.class);
        strates.clear();
        lenient().when(attemptQuestionManager.stratesParAttempt(any())).thenAnswer(inv -> {
            final List<LigneStrateQcm> out = new ArrayList<>();
            for (final UUID id : (Collection<UUID>) inv.getArgument(0)) {
                for (final StrateQcm st : strates.getOrDefault(id, List.of())) {
                    out.add(new LigneStrateQcm(id, QuestionType.CO, st));
                }
            }
            return out;
        });
        final TcfLevelEstimatorService estimator =
                new TcfLevelEstimatorService(attemptQuestionManager);
        resolver = new NiveauActuelEpreuveResolver(
                attemptManager, qualifiantesResolver, estimator,
                new ProductionBilanService(mock(AiEvaluationManager.class),
                        estimator, rubrics, props));
    }

    // ------------------------------------------------------------- fixtures --

    /**
     * Un examen QCM passé, décrit par <b>ce qu'il a mesuré</b> : combien
     * d'items réussis dans chacune des trois strates, sur la composition
     * 10 A2 / 8 B1 / 7 B2. 🛑 Aucun palier n'est déclaré — il n'existe que
     * dérivé, et c'est précisément ce que ce test doit éprouver.
     */
    private Attempt qcm(int a2, int b1, int b2, Instant fin) {
        final Attempt a = new Attempt();
        a.setId(UUID.randomUUID());
        a.setFinishedAt(fin);
        strates.put(a.getId(), List.of(
                StrateQcm.mesuree(Difficulty.A2, 10, a2),
                StrateQcm.mesuree(Difficulty.B1, 8, b1),
                StrateQcm.mesuree(Difficulty.B2, 7, b2)));
        return a;
    }

    /**
     * Les examens QCM d'une épreuve, <b>du plus récent au plus ancien</b>,
     * décrits par {@code {a2, b1, b2}} items réussis.
     */
    private void stubQcm(EpreuveType epreuve, int[]... duPlusRecentAuPlusAncien) {
        final Instant maintenant = Instant.now();
        final List<Attempt> attempts = new ArrayList<>();
        for (int i = 0; i < duPlusRecentAuPlusAncien.length; i++) {
            final int[] r = duPlusRecentAuPlusAncien[i];
            attempts.add(qcm(r[0], r[1], r[2], maintenant.minus(i, ChronoUnit.DAYS)));
        }
        when(attemptManager.findQcmEpreuvesPassees(eq(userId), eq(epreuve), anyInt()))
                .thenReturn(List.copyOf(attempts));
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
                    niveauDeReference(c), c, null));
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
        // A2 et B1 maitrisés (10/10 et 8/8), B2 non (0/7) ⇒ B1.
        stubQcm(EpreuveType.TCF_CO, new int[] {10, 8, 0});

        assertThat(resolver.qcm(userId, EpreuveType.TCF_CO, SCAN)).isEqualTo(NiveauCecrl.B1);
    }

    /**
     * 🛑 <b>Le résultat n'est ni le meilleur ni le dernier.</b> Un B1 récent et
     * un A2 plus ancien donnent A2 : sur les items cumulés, l'A2 tient
     * (16/20, il en faut 12) mais le B1 non (8/16, il en faut 10). C'est
     * exactement ce que « niveau actuel estimé » veut dire — ni un trophée, ni
     * la dernière humeur.
     */
    @Test
    @DisplayName("2 examens ⇒ la moyenne des 2, ni le meilleur ni le dernier")
    void deuxExamens_moyenneDesDeux() {
        stubQcm(EpreuveType.TCF_CO, new int[] {10, 8, 0}, new int[] {6, 0, 0});

        assertThat(resolver.qcm(userId, EpreuveType.TCF_CO, SCAN)).isEqualTo(NiveauCecrl.A2);
    }

    /**
     * 🛑 <b>LE cas que l'ancienne règle interdisait.</b> Deux B2 puis deux
     * examens ratés : le maximum monotone affichait B2 pour toujours, le cumul
     * des trois derniers affiche A1. Le niveau descend, et c'est la demande.
     *
     * <p>⚠️ Il faut bien <b>deux</b> mauvais examens, et c'est la propriété à
     * connaître : sur trois examens cumulés, un seul zéro ne suffit pas à
     * défaire deux sans-faute (20 A2 réussis sur 30 posés, il en faut 18). Le
     * palier affiché est inerte à un accident, sensible à une tendance.
     */
    @Test
    @DisplayName("🛑 Un historique récent dégradé fait BAISSER le niveau affiché")
    void unHistoriqueRecentDegradeFaitBaisserLeNiveau() {
        stubQcm(EpreuveType.TCF_CO, new int[] {10, 8, 7}, new int[] {10, 8, 7});
        assertThat(resolver.qcm(userId, EpreuveType.TCF_CO, SCAN))
                .as("avant la mauvaise passe")
                .isEqualTo(NiveauCecrl.B2);

        // Un accident isolé ne défait pas deux sans-faute.
        stubQcm(EpreuveType.TCF_CO,
                new int[] {0, 0, 0}, new int[] {10, 8, 7}, new int[] {10, 8, 7});
        assertThat(resolver.qcm(userId, EpreuveType.TCF_CO, SCAN))
                .as("un seul mauvais examen sur trois : le palier tient")
                .isEqualTo(NiveauCecrl.B2);

        // Deux ratés récents : la fenêtre ne contient plus qu'un bon examen.
        stubQcm(EpreuveType.TCF_CO,
                new int[] {0, 0, 0}, new int[] {0, 0, 0},
                new int[] {10, 8, 7}, new int[] {10, 8, 7});
        assertThat(resolver.qcm(userId, EpreuveType.TCF_CO, SCAN))
                .as("le maximum monotone est révoqué : le niveau redescend")
                .isEqualTo(NiveauCecrl.A1);
    }

    /**
     * 🛑 <b>Fenêtre de 3, et seulement 3.</b> Trois examens récents juste sous
     * le seuil A2 (5/10 chacun, soit 15/30 quand il en faut 18) ⇒ A1. Ajouter
     * un sans-faute PLUS ANCIEN le ferait remonter à A2 (25/40 pour 24
     * requis) : la fenêtre change donc bien le résultat, le cas prouve quelque
     * chose.
     */
    @Test
    @DisplayName("🛑 4 examens ⇒ seuls les 3 DERNIERS comptent, le plus ancien est ignoré")
    void quatreExamens_seulsLesTroisDerniersComptent() {
        stubQcm(EpreuveType.TCF_CE,
                new int[] {5, 0, 0}, new int[] {5, 0, 0}, new int[] {5, 0, 0},
                new int[] {10, 8, 7});

        assertThat(resolver.qcm(userId, EpreuveType.TCF_CE, SCAN)).isEqualTo(NiveauCecrl.A1);

        // Le contrôle : les mêmes 3 récents, sans le vieux sans-faute — même
        // résultat, donc le 4ᵉ n'a réellement rien pesé.
        stubQcm(EpreuveType.TCF_CE,
                new int[] {5, 0, 0}, new int[] {5, 0, 0}, new int[] {5, 0, 0});
        assertThat(resolver.qcm(userId, EpreuveType.TCF_CE, SCAN)).isEqualTo(NiveauCecrl.A1);
    }

    /**
     * 🛑 <b>Le seuil de 60 % s'arrondit à l'entier SUPÉRIEUR, y compris sur les
     * items cumulés</b> — il n'est pas recodé ici, c'est l'autorité unique qui
     * le porte. Deux examens : 20 items A2 posés, il en faut 12.
     */
    @Test
    @DisplayName("🛑 Le seuil s'applique aux items CUMULÉS, arrondi au supérieur")
    void leSeuilSappliqueAuxItemsCumules() {
        stubQcm(EpreuveType.TCF_CO, new int[] {6, 0, 0}, new int[] {5, 0, 0}); // 11/20
        assertThat(resolver.qcm(userId, EpreuveType.TCF_CO, SCAN)).isEqualTo(NiveauCecrl.A1);

        stubQcm(EpreuveType.TCF_CO, new int[] {6, 0, 0}, new int[] {6, 0, 0}); // 12/20
        assertThat(resolver.qcm(userId, EpreuveType.TCF_CO, SCAN)).isEqualTo(NiveauCecrl.A2);
    }

    /**
     * {@code A1} est le plancher réel : une bonne réponse quelque part suffit.
     * {@code A1_NON_ATTEINT} reste réservé à zéro bonne réponse sur tous les
     * examens retenus.
     */
    @Test
    @DisplayName("A1 dès une bonne réponse ; A1_NON_ATTEINT seulement si zéro partout")
    void plancherBas() {
        stubQcm(EpreuveType.TCF_CO, new int[] {1, 0, 0}, new int[] {1, 0, 0});
        assertThat(resolver.qcm(userId, EpreuveType.TCF_CO, SCAN)).isEqualTo(NiveauCecrl.A1);

        stubQcm(EpreuveType.TCF_CE, new int[] {0, 0, 0}, new int[] {0, 0, 0});
        assertThat(resolver.qcm(userId, EpreuveType.TCF_CE, SCAN))
                .isEqualTo(NiveauCecrl.A1_NON_ATTEINT);
    }

    /**
     * 🛑 <b>Un examen ancien reste parfaitement lisible.</b> Il n'a jamais porté
     * de score pondéré (donnée antérieure) : ça ne change rien, ses RÉPONSES
     * sont en base, donc ses strates aussi. C'est tout l'intérêt d'un dérivé
     * qui ne se persiste pas.
     */
    @Test
    @DisplayName("Un examen sans score pondéré garde son niveau : il se relit sur ses réponses")
    void unExamenSansScorePondere_seRelitSurSesReponses() {
        stubQcm(EpreuveType.TCF_CO, new int[] {10, 8, 0});

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
                                new Attempt(), Instant.now(), NiveauCecrl.A2, null, null),
                        new EpreuvesProductionQualifiantesResolver.EpreuveQualifiante(
                                new Attempt(), Instant.now().minus(2, ChronoUnit.DAYS),
                                NiveauCecrl.B2, null, null)));

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
