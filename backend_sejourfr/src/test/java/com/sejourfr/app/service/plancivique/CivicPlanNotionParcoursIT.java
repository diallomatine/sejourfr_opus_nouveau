package com.sejourfr.app.service.plancivique;

import com.sejourfr.app.dto.AttemptResponse;
import com.sejourfr.app.dto.CivicPlanDto;
import com.sejourfr.app.entity.CivicDiagnosticSession;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.service.diagnosticcivique.CivicDiagnosticService;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

import java.sql.Timestamp;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * <b>LA CHAÎNE ENTIÈRE DU PLAN CIVIQUE, AU GRAIN NOTION</b> — d'un bout à
 * l'autre, sur la vraie base et le vrai catalogue.
 *
 * <pre>
 * diagnostic → priorités → cible NOTION → série ciblée → validation
 *            → sortie des priorités → révision à l'échéance
 * </pre>
 *
 * <p>Les ITs existants ({@code CivicPlanServiceIT}) verrouillent chaque maillon
 * <b>séparément</b> : la bascule du grain, le seuil de dotation, le verrou de la
 * série. Aucun ne suivait un candidat du diagnostic jusqu'à la révision — or
 * c'est précisément là que les maillons se décrochent, parce que chacun a
 * raison tout seul.
 *
 * <h2>Ce que ce test prouve, et pourquoi chaque point compte</h2>
 * <ul>
 *   <li>🛑 <b>Seules les cibles {@code SERVABLE} sont servies.</b> Le thème
 *       porte les trois dotations à la fois — une notion pleine, une à trois
 *       questions, une à zéro — et les deux dernières ne doivent apparaître
 *       <b>nulle part</b> : ni en priorité, ni en « à revoir », ni en
 *       « prochaine ». C'est l'invariant qui commande tout le reste ;</li>
 *   <li>🛑 <b>La bascule est PAR THÈME</b> : un seul thème passe au grain
 *       notion, les quatre autres continuent de travailler au grain thème dans
 *       le <b>même</b> plan. Une bascule qui viderait le plan se verrait ici ;</li>
 *   <li>🛑 <b>La série ciblée tire dans LA notion</b>, et dans la mention du
 *       candidat. Un tirage qui déborderait ferait progresser une autre cible
 *       que celle affichée — le défaut déjà payé côté TCF avec
 *       {@code findDemoPool} ;</li>
 *   <li>🛑 <b>Le Leitner avance et l'échéance se franchit toute seule.</b> Rien
 *       n'est persisté : on vieillit l'historique en base, on relit, et la cible
 *       passe de « acquise » à « à revoir » sans qu'aucun job ne tourne ;</li>
 *   <li>🛑 <b>Une notion hors programme ne fait pas planter la série</b> : elle
 *       la refuse, en le disant.</li>
 * </ul>
 *
 * <h2>Le montage, et pourquoi il est dans cet ordre</h2>
 *
 * <p>Le diagnostic est joué <b>avant</b> le tagging, exprès : c'est la
 * <b>rétroactivité</b> que tout le module paie de ne rien persister. Les
 * réponses déjà données doivent compter pour la notion que la question reçoit
 * ensuite — si elles ne comptaient pas, une table de progression aurait été le
 * meilleur choix, et tout le dessin du module serait à refaire.
 *
 * <p>Chaque réponse reçoit un instant <b>distinct</b>. 🛑 Ce n'est pas une
 * coquetterie : dans une seule transaction, {@code now()} rend l'instant de
 * DÉBUT de transaction pour toutes les lignes, l'ordre retomberait sur un UUID
 * tiré au hasard, et « l'ORDRE fait la boîte ». Un test qui s'en remettrait à
 * {@code now()} serait vert ou rouge au tirage.
 */
class CivicPlanNotionParcoursIT extends AbstractIntegrationTest {

    @Autowired private CivicPlanService service;
    @Autowired private CivicDiagnosticService diagnosticService;
    @Autowired private TestData testData;
    @Autowired private EntityManager entityManager;
    @Autowired private JdbcTemplate jdbc;

    /** Le diagnostic est joué il y a deux jours : ses erreurs sont « chaudes ». */
    private static final Instant DIAGNOSTIC_A = Instant.now()
            .truncatedTo(ChronoUnit.SECONDS).minus(2, ChronoUnit.DAYS);

    /** La série ciblée, jouée après — l'ordre fait la boîte. */
    private static final Instant SERIE_A = Instant.now()
            .truncatedTo(ChronoUnit.SECONDS).minus(1, ChronoUnit.HOURS);

    /** Assez pour franchir l'intervalle de la dernière boîte (21 jours). */
    private static final int JOURS_DE_VIEILLISSEMENT = 22;

    /**
     * Le thème passé au grain notion et ses quatre cibles.
     *
     * @param servable     ≥ 5 questions dans la mention, et <b>déjà travaillée</b>
     *                     au diagnostic
     * @param jamaisVue    ≥ 5 questions dans la mention, <b>aucune réponse</b> —
     *                     c'est elle qui distingue « proposable » de
     *                     « travaillée »
     * @param insuffisante 3 questions dans la mention : le sujet existe, la
     *                     matière manque
     * @param horsProgramme aucune question dans la mention : ce n'est pas la
     *                     démarche de ce candidat
     */
    private record Fixture(
            String themeCode, UUID themeId, UUID attemptDiagnostic,
            UUID servable, UUID jamaisVue, UUID insuffisante, UUID horsProgramme) {
    }

    // ------------------------------------------------------------------------
    // LE test
    // ------------------------------------------------------------------------

    @Test
    @DisplayName("🛑 DE BOUT EN BOUT au grain NOTION : le diagnostic pointe, le plan sert, "
            + "la série cible, la maîtrise sort des priorités et revient à l'échéance")
    void laChaineEntiereAuGrainNotion() {
        User user = testData.user();
        testData.userSubscription(user, testData.plan());
        // La mention est servie meme sans diagnostic : c'est la seule autorite.
        String mention = service.plan(user.getId()).mention().name();
        Fixture fx = monterUnThemeAuGrainNotion(user);

        // --------------------------------------------------------------------
        // 1. Les trois dotations sont bien montées, et c'est la BASE qui le dit
        // --------------------------------------------------------------------
        assertThat(dotation(fx.servable(), mention)).isEqualTo(CivicDotation.SERVABLE);
        assertThat(dotation(fx.jamaisVue(), mention)).isEqualTo(CivicDotation.SERVABLE);
        assertThat(dotation(fx.insuffisante(), mention))
                .isEqualTo(CivicDotation.CONTENU_INSUFFISANT);
        assertThat(dotation(fx.horsProgramme(), mention))
                .isEqualTo(CivicDotation.NON_APPLICABLE);
        // 🛑 `NON_APPLICABLE` n'est pas « vide » : la notion EXISTE, ailleurs.
        // C'est le cas mesuré par V058 (« Devenir français » : 10 questions en
        // NAT, zéro en CSP), et c'est ce qui la distingue d'un manque.
        assertThat(questionsToutesMentions(fx.horsProgramme())).isPositive();

        // --------------------------------------------------------------------
        // 2. Le plan : un thème au grain NOTION, les quatre autres au grain THÈME
        // --------------------------------------------------------------------
        CivicPlanDto plan = service.plan(user.getId());
        assertThat(plan.disponible()).isTrue();
        assertThat(plan.grain().themesParNotion()).isEqualTo(1);
        // 🛑 Le plan ne se dit jamais plus précis qu'il ne l'est : un seul thème
        // basculé ne fait pas un plan « par notion ».
        assertThat(plan.grain().courant()).isEqualTo(CivicPlanGrain.THEME);

        List<CivicPlanDto.Cible> toutes = servies(plan);
        assertThat(toutes).isNotEmpty();
        // 🛑 La bascule n'a pas vidé le plan : les autres thèmes travaillent
        // toujours, dans le MÊME plan et au MÊME moment.
        assertThat(toutes).anySatisfy(c -> {
            assertThat(c.grain()).isEqualTo(CivicPlanGrain.NOTION);
            assertThat(c.themeId()).isEqualTo(fx.themeId());
        });
        assertThat(toutes).anySatisfy(c -> {
            assertThat(c.grain()).isEqualTo(CivicPlanGrain.THEME);
            assertThat(c.themeId()).isNotEqualTo(fx.themeId());
        });

        // --------------------------------------------------------------------
        // 3. 🛑 L'INVARIANT : ni CONTENU_INSUFFISANT ni NON_APPLICABLE, nulle part
        // --------------------------------------------------------------------
        seulLeServableEstServi(plan, fx);

        // --------------------------------------------------------------------
        // 4. Le diagnostic a pointé le thème ; le plan sert une NOTION en tête
        // --------------------------------------------------------------------
        // 🛑 Au grain notion, « pointé par le diagnostic » vaut toujours false :
        // le diagnostic mesure des THÈMES, et son signal passe par le poids du
        // thème — le compter une seconde fois par notion doublerait le même fait.
        CivicPlanDto.Cible prochaine = plan.prochaine();
        assertThat(prochaine).isNotNull();
        assertThat(prochaine.grain()).isEqualTo(CivicPlanGrain.NOTION);
        assertThat(prochaine.id()).isEqualTo(fx.servable());
        assertThat(prochaine.themeId()).isEqualTo(fx.themeId());
        assertThat(prochaine.etatDuTheme().name()).isEqualTo("FAIBLE");
        assertThat(prochaine.maitrise()).isEqualTo(CivicMaitrise.A_TRAVAILLER);
        assertThat(prochaine.locked()).isFalse();
        // La notion jamais vue est proposée elle aussi — « à acquérir » n'est
        // pas « à renforcer », et une notion qu'on n'a pas mesurée reste du
        // programme.
        assertThat(plan.priorites()).anyMatch(c -> c.id().equals(fx.jamaisVue()));
        parcoursCoherent(prochaine, false);

        // --------------------------------------------------------------------
        // 5. 🛑 « Travaillée » veut dire TRAVAILLÉE, pas « proposable »
        // --------------------------------------------------------------------
        CivicPlanService.Compteurs compteurs = service.compteurs(user.getId());
        assertThat(compteurs.travaillees()).isEqualTo(ciblesReellementRepondues(user, fx));
        assertThat(compteurs.maitrisees()).isZero();
        assertThat(compteurs.grainNotion()).isFalse();
        // 🛑 Et le compteur est STRICTEMENT sous le nombre de cibles proposables :
        // `jamaisVue` est éligible sans avoir jamais été touchée. C'est ce qui
        // rendait l'écran Progrès faux au grain notion, où l'immense majorité
        // des notions n'a aucune réponse.
        assertThat(compteurs.travaillees())
                .isLessThan(plan.priorites().size() + plan.autresPriorites());

        // --------------------------------------------------------------------
        // 6. La série ciblée tire DANS la notion, et dans la mention
        // --------------------------------------------------------------------
        AttemptResponse serie = service.demarrerSerie(
                user.getId(), fx.servable(), CivicPlanGrain.NOTION);
        entityManager.flush();

        List<UUID> tirees = serie.questions().stream().map(q -> q.question().id()).toList();
        assertThat(tirees).isNotEmpty();
        assertThat(serie.type().name()).isEqualTo("TRAINING");
        for (UUID questionId : tirees) {
            Map<String, Object> q = jdbc.queryForMap(
                    "SELECT civic_notion_id, difficulty FROM questions WHERE id = ?", questionId);
            assertThat(q.get("civic_notion_id")).isEqualTo(fx.servable());
            assertThat(q.get("difficulty")).isEqualTo(mention);
        }

        // 🛑 Et une notion hors programme ne « rend pas une série vide » : elle
        // refuse, en le disant. Un tirage vide silencieux enverrait le candidat
        // dans un runner sans question.
        assertThatThrownBy(() -> service.demarrerSerie(
                user.getId(), fx.horsProgramme(), CivicPlanGrain.NOTION))
                .isInstanceOf(BusinessException.class);

        // --------------------------------------------------------------------
        // 7. Tout juste : la maîtrise monte, la cible SORT des priorités
        // --------------------------------------------------------------------
        repondre(serie.id(), q -> true, SERIE_A);
        entityManager.flush();
        entityManager.clear();

        CivicPlanDto apres = service.plan(user.getId());
        CivicPlanDto.Cible acquise = trouver(apres, fx.servable());
        assertThat(acquise).isNotNull();
        assertThat(acquise.maitrise()).isEqualTo(CivicMaitrise.MAITRISEE);
        assertThat(acquise.boite()).isEqualTo(CivicLeitner.DERNIERE);
        parcoursCoherent(acquise, true);
        assertThat(apres.priorites()).noneMatch(c -> c.id().equals(fx.servable()));
        assertThat(apres.solides()).anyMatch(c -> c.id().equals(fx.servable()));
        // Pas encore l'heure : l'échéance de la dernière boîte est à 21 jours.
        assertThat(apres.aRevoir()).noneMatch(c -> c.id().equals(fx.servable()));
        assertThat(acquise.prochaineRevue()).isNotNull().isAfter(Instant.now());
        // 🛑 Une autre cible prend la tête : le plan ne reste pas bloqué sur ce
        // qui vient d'être acquis.
        assertThat(apres.prochaine()).isNotNull();
        assertThat(apres.prochaine().id()).isNotEqualTo(fx.servable());
        seulLeServableEstServi(apres, fx);

        // Ce qui a bougé est DIT, et le progrès est dérivé serveur.
        assertThat(apres.changements()).isNotNull();
        assertThat(apres.changements().transitions())
                .anySatisfy(t -> {
                    assertThat(t.cibleId()).isEqualTo(fx.servable());
                    assertThat(t.grain()).isEqualTo(CivicPlanGrain.NOTION);
                    assertThat(t.apres()).isEqualTo(CivicMaitrise.MAITRISEE);
                    assertThat(t.progres()).isTrue();
                });

        // Et l'écran Progrès compte enfin une cible tenue.
        assertThat(service.compteurs(user.getId()).maitrisees()).isEqualTo(1);

        // --------------------------------------------------------------------
        // 8. 🛑 L'échéance se franchit TOUTE SEULE : aucun job, aucune table
        // --------------------------------------------------------------------
        vieillirLHistorique(user, JOURS_DE_VIEILLISSEMENT);
        CivicPlanDto aLEcheance = service.plan(user.getId());

        CivicPlanDto.Cible aReviser = trouver(aLEcheance, fx.servable());
        assertThat(aReviser).isNotNull();
        assertThat(aReviser.aRevoir()).isTrue();
        assertThat(aLEcheance.aRevoir()).anyMatch(c -> c.id().equals(fx.servable()));
        // 🛑 Une révision n'est JAMAIS une priorité rouge : elle reste acquise.
        assertThat(aReviser.maitrise()).isEqualTo(CivicMaitrise.MAITRISEE);
        assertThat(aLEcheance.priorites()).noneMatch(c -> c.id().equals(fx.servable()));
        seulLeServableEstServi(aLEcheance, fx);
    }

    @Test
    @DisplayName("🛑 Une erreur renvoie en première étape, quelle que soit la hauteur atteinte")
    void uneErreurRameneAuDebutDuParcours() {
        User user = testData.user();
        testData.userSubscription(user, testData.plan());
        Fixture fx = monterUnThemeAuGrainNotion(user);

        AttemptResponse montee = service.demarrerSerie(
                user.getId(), fx.servable(), CivicPlanGrain.NOTION);
        entityManager.flush();
        repondre(montee.id(), q -> true, SERIE_A);
        entityManager.flush();
        entityManager.clear();
        assertThat(trouver(service.plan(user.getId()), fx.servable()).boite())
                .isEqualTo(CivicLeitner.DERNIERE);

        // Une seule erreur, après cinq bonnes réponses d'affilée.
        AttemptResponse rechute = service.demarrerSerie(
                user.getId(), fx.servable(), CivicPlanGrain.NOTION);
        entityManager.flush();
        repondre(rechute.id(), q -> false, SERIE_A.plus(1, ChronoUnit.HOURS));
        entityManager.flush();
        entityManager.clear();

        CivicPlanDto.Cible cible = trouver(service.plan(user.getId()), fx.servable());
        assertThat(cible.boite()).isEqualTo(CivicLeitner.PREMIERE);
        assertThat(cible.maitrise()).isEqualTo(CivicMaitrise.A_TRAVAILLER);
        // ⚠️ Le parcours RECULE avec la boîte — c'est voulu, c'est exactement ce
        // que le candidat doit voir.
        assertThat(cible.parcours())
                .containsExactly(CivicEtapeEtat.EN_COURS, CivicEtapeEtat.A_VENIR,
                        CivicEtapeEtat.A_VENIR, CivicEtapeEtat.A_VENIR,
                        CivicEtapeEtat.A_VENIR);
        // Et elle revient en priorité : ce qui vient d'être raté passe devant.
        assertThat(service.plan(user.getId()).priorites())
                .anyMatch(c -> c.id().equals(fx.servable()));
    }

    // ------------------------------------------------------------------------
    // Les invariants, écrits une fois
    // ------------------------------------------------------------------------

    /**
     * 🛑 L'invariant qui commande tout : une cible non {@code SERVABLE} n'est
     * <b>servie nulle part</b>.
     */
    @Test
    @DisplayName("🛑 Les trois invariants de sûreté du grain NOTION : « solides », "
            + "« Progression détectée » et le grain annoncé par le client")
    void lesTroisInvariantsDeSurete() {
        User user = testData.user();
        testData.userSubscription(user, testData.plan());
        Fixture fx = monterUnThemeAuGrainNotion(user);

        UUID attempt = service.demarrerSerie(
                user.getId(), fx.servable(), CivicPlanGrain.NOTION).id();
        repondre(attempt, id -> true, SERIE_A);
        CivicPlanDto plan = service.plan(user.getId());

        // ---- 1. `solides` ne liste que du servable, comme `priorites` et
        // `aRevoir`. Une cible maitrisee puis devenue non servable — le
        // candidat change de demarche et sa notion n'a plus de question dans
        // sa nouvelle mention — s'affichait comme un acquis : le plan
        // annoncait un acquis sur un point qu'il ne sait plus enseigner.
        assertThat(plan.solides())
                .allSatisfy(c -> assertThat(c.dotation()).isEqualTo(CivicDotation.SERVABLE));

        // ---- 2. « Progression detectee » ne nomme jamais une cible non
        // servable. Elle peut pourtant en avoir l'historique : c'est
        // precisement le cas qui laissait lire un progres sur un point
        // impossible a travailler, et sans carte nulle part ailleurs.
        List<UUID> nonServables = List.of(fx.insuffisante(), fx.horsProgramme());
        if (plan.changements() != null) {
            assertThat(plan.changements().transitions())
                    .as("aucune transition ne nomme une cible non servable")
                    .noneMatch(t -> nonServables.contains(t.cibleId()));
            if (plan.changements().nouvellePriorite() != null) {
                assertThat(nonServables)
                        .doesNotContain(plan.changements().nouvellePriorite().id());
            }
        }

        // ---- 3. Le grain annonce par le client n'est pas une autorite : le
        // serveur retrouve la cible dans le plan et en deduit son grain.
        UUID servableRestante = plan.priorites().getFirst().id();
        assertThat(service.demarrerSerie(
                user.getId(), servableRestante, CivicPlanGrain.THEME).id())
                .as("le serveur corrige un grain faux au lieu de tirer dans le vide")
                .isNotNull();

        // Et une cible non servable est REFUSEE, quel que soit le grain annonce.
        assertThatThrownBy(() -> service.demarrerSerie(
                user.getId(), fx.insuffisante(), CivicPlanGrain.NOTION))
                .isInstanceOf(BusinessException.class);
        assertThatThrownBy(() -> service.demarrerSerie(
                user.getId(), fx.horsProgramme(), CivicPlanGrain.THEME))
                .isInstanceOf(BusinessException.class);
    }

    private static void seulLeServableEstServi(CivicPlanDto plan, Fixture fx) {
        List<UUID> interdites = List.of(fx.insuffisante(), fx.horsProgramme());
        assertThat(plan.priorites()).noneMatch(c -> interdites.contains(c.id()));
        assertThat(plan.aRevoir()).noneMatch(c -> interdites.contains(c.id()));
        assertThat(plan.solides()).noneMatch(c -> interdites.contains(c.id()));
        if (plan.prochaine() != null) {
            assertThat(interdites).doesNotContain(plan.prochaine().id());
        }
        // Et la règle vaut pour TOUT ce qui est servi, pas seulement pour le
        // montage de ce test : aucune liste ne porte une dotation autre.
        assertThat(plan.priorites())
                .allSatisfy(c -> assertThat(c.dotation()).isEqualTo(CivicDotation.SERVABLE));
        assertThat(plan.aRevoir())
                .allSatisfy(c -> assertThat(c.dotation()).isEqualTo(CivicDotation.SERVABLE));
    }

    /**
     * Le parcours sert <b>exactement</b> cinq états, avec <b>au plus une</b>
     * étape en cours — et aucune quand la cible est tenue.
     */
    private static void parcoursCoherent(CivicPlanDto.Cible cible, boolean maitrisee) {
        assertThat(cible.parcours()).hasSize(CivicLeitner.DERNIERE);
        long enCours = cible.parcours().stream()
                .filter(e -> e == CivicEtapeEtat.EN_COURS).count();
        if (maitrisee) {
            assertThat(cible.parcours())
                    .allSatisfy(e -> assertThat(e).isEqualTo(CivicEtapeEtat.FRANCHIE));
        } else {
            assertThat(enCours).isEqualTo(1);
        }
    }

    // ------------------------------------------------------------------------
    // Le montage
    // ------------------------------------------------------------------------

    /**
     * Fait passer <b>un seul</b> thème au grain notion, avec les trois dotations
     * représentées dans la mention du candidat.
     *
     * <p>Le diagnostic est joué <b>avant</b> le tagging : c'est la rétroactivité
     * que le module paie de ne rien persister.
     */
    private Fixture monterUnThemeAuGrainNotion(User user) {
        CivicDiagnosticSession session = diagnosticService.ouvrir(user.getId());
        entityManager.flush();
        UUID attemptId = session.getAttempt().getId();

        String themeCode = themeLePlusDote();
        UUID themeId = jdbc.queryForObject(
                "SELECT id FROM themes WHERE code = ?", UUID.class, themeCode);

        // 🛑 Faux sur CE thème, juste ailleurs : il devient FAIBLE (et lui seul),
        // donc ses notions portent le poids du diagnostic sans qu'aucune autre
        // cible ne vienne les concurrencer par hasard.
        repondre(attemptId, q -> !themeId.equals(q), DIAGNOSTIC_A);
        diagnosticService.cloturer(user.getId(), session.getId());
        entityManager.flush();
        entityManager.clear();

        List<UUID> notions = jdbc.queryForList("""
                SELECT id FROM civic_notions
                WHERE theme_code = ? AND is_active = true ORDER BY display_order LIMIT 4
                """, UUID.class, themeCode);
        assertThat(notions)
                .as("il faut quatre notions actives sur ce thème pour porter les trois dotations")
                .hasSize(4);
        UUID servable = notions.get(0);
        UUID jamaisVue = notions.get(1);
        UUID insuffisante = notions.get(2);
        UUID horsProgramme = notions.get(3);

        // Les autres notions du thème sortent : elles n'auraient aucune question
        // et ajouteraient du bruit `NON_APPLICABLE` aux assertions.
        jdbc.update("""
                UPDATE civic_notions SET is_active = false
                WHERE theme_code = ? AND id <> ? AND id <> ? AND id <> ? AND id <> ?
                """, themeCode, servable, jamaisVue, insuffisante, horsProgramme);

        // 100 % des CONNAISSANCE du thème sont taguées : il bascule. Les mises
        // en situation restent volontairement sans notion (domaines `sit_*`).
        int taguees = jdbc.update("""
                UPDATE questions SET civic_notion_id = ?
                WHERE module = 'CIVIQUE' AND is_active = true
                  AND question_type = 'CONNAISSANCE' AND theme_id = ?
                """, servable, themeId);
        assertThat(taguees).isPositive();

        String mention = service.plan(user.getId()).mention().name();
        // Les deux notions dotées ne prennent QUE des questions jamais posées au
        // diagnostic : sans ça, « jamais vue » ne le serait pas, et le compteur
        // « travaillées » ne prouverait rien.
        deplacer(themeId, mention, servable, jamaisVue, attemptId, 5);
        deplacer(themeId, mention, servable, insuffisante, attemptId, 3);
        // 🛑 Hors programme : la notion existe, mais dans une AUTRE mention.
        deplacerHorsMention(themeId, mention, servable, horsProgramme, 4);

        return new Fixture(themeCode, themeId, attemptId,
                servable, jamaisVue, insuffisante, horsProgramme);
    }

    /** Le thème le mieux doté : il faut de quoi remplir trois notions distinctes. */
    private String themeLePlusDote() {
        return jdbc.queryForObject("""
                SELECT t.code
                FROM questions q JOIN themes t ON t.id = q.theme_id
                WHERE q.module = 'CIVIQUE' AND q.is_active = true
                  AND q.question_type = 'CONNAISSANCE'
                GROUP BY t.code
                HAVING COUNT(*) FILTER (WHERE q.difficulty = 'CSP') >= 20
                ORDER BY COUNT(*) DESC, t.code
                LIMIT 1
                """, String.class);
    }

    /** Déplace {@code combien} questions <b>jamais posées</b> vers une notion. */
    private void deplacer(UUID themeId, String mention, UUID depuis, UUID vers,
                          UUID attemptExclu, int combien) {
        int bouges = jdbc.update("""
                UPDATE questions SET civic_notion_id = ?
                WHERE id IN (
                    SELECT q.id FROM questions q
                    WHERE q.module = 'CIVIQUE' AND q.is_active = true
                      AND q.question_type = 'CONNAISSANCE'
                      AND q.theme_id = ? AND q.civic_notion_id = ?
                      AND q.difficulty = CAST(? AS varchar)
                      AND NOT EXISTS (SELECT 1 FROM attempt_questions aq
                                      WHERE aq.attempt_id = ? AND aq.question_id = q.id)
                    ORDER BY q.id LIMIT ?
                )
                """, vers, themeId, depuis, mention, attemptExclu, combien);
        assertThat(bouges).isEqualTo(combien);
    }

    /** Même geste, mais sur des questions d'une AUTRE mention que celle du candidat. */
    private void deplacerHorsMention(UUID themeId, String mention, UUID depuis, UUID vers,
                                     int combien) {
        int bouges = jdbc.update("""
                UPDATE questions SET civic_notion_id = ?
                WHERE id IN (
                    SELECT q.id FROM questions q
                    WHERE q.module = 'CIVIQUE' AND q.is_active = true
                      AND q.question_type = 'CONNAISSANCE'
                      AND q.theme_id = ? AND q.civic_notion_id = ?
                      AND q.difficulty <> CAST(? AS varchar)
                    ORDER BY q.id LIMIT ?
                )
                """, vers, themeId, depuis, mention, combien);
        assertThat(bouges).isEqualTo(combien);
    }

    // ------------------------------------------------------------------------
    // Réponses et mesures
    // ------------------------------------------------------------------------

    /**
     * Écrit les réponses d'un attempt, <b>une par une et à des instants
     * distincts</b>.
     *
     * <p>🛑 L'instant distinct n'est pas cosmétique : dans une transaction,
     * {@code now()} est le même pour toutes les lignes, et le repli Leitner
     * retomberait alors sur l'ordre des UUID — donc sur le hasard.
     *
     * @param juste dit, pour le thème d'une question, si la réponse est bonne
     */
    private void repondre(UUID attemptId,
                          java.util.function.Predicate<UUID> juste,
                          Instant premiere) {
        List<Map<String, Object>> lignes = jdbc.queryForList("""
                SELECT aq.id AS aq_id, q.theme_id AS theme_id
                FROM attempt_questions aq JOIN questions q ON q.id = aq.question_id
                WHERE aq.attempt_id = ? ORDER BY aq.position
                """, attemptId);
        int i = 0;
        for (Map<String, Object> ligne : lignes) {
            jdbc.update("""
                    INSERT INTO answers (id, attempt_question_id, user_id, selected_choice_ids,
                                         is_correct, answered_at)
                    SELECT gen_random_uuid(), ?, a.user_id, '[]'::jsonb, ?, ?
                    FROM attempt_questions aq JOIN attempts a ON a.id = aq.attempt_id
                    WHERE aq.id = ?
                    """,
                    ligne.get("aq_id"),
                    juste.test((UUID) ligne.get("theme_id")),
                    Timestamp.from(premiere.plusSeconds(i++)),
                    ligne.get("aq_id"));
        }
        assertThat(i).as("l'attempt doit porter des questions").isPositive();
    }

    /** Recule tout l'historique : l'échéance se franchit alors d'elle-même. */
    private void vieillirLHistorique(User user, int jours) {
        jdbc.update("""
                UPDATE answers SET answered_at = answered_at - make_interval(days => ?)
                WHERE user_id = ?
                """, jours, user.getId());
        entityManager.flush();
        entityManager.clear();
    }

    /** La dotation, relue en base et dérivée par l'<b>unique</b> autorité. */
    private CivicDotation dotation(UUID notionId, String mention) {
        Long n = jdbc.queryForObject("""
                SELECT COUNT(*) FROM questions
                WHERE module = 'CIVIQUE' AND is_active = true
                  AND civic_notion_id = ? AND difficulty = CAST(? AS varchar)
                """, Long.class, notionId, mention);
        return CivicDotation.depuis(n == null ? 0L : n, 5);
    }

    private long questionsToutesMentions(UUID notionId) {
        Long n = jdbc.queryForObject("""
                SELECT COUNT(*) FROM questions
                WHERE module = 'CIVIQUE' AND is_active = true AND civic_notion_id = ?
                """, Long.class, notionId);
        return n == null ? 0L : n;
    }

    /**
     * Le nombre de cibles portant <b>au moins une réponse</b>, recompté en SQL —
     * volontairement <b>hors</b> du moteur : un compteur qui se vérifierait
     * contre lui-même ne vérifierait rien.
     */
    private int ciblesReellementRepondues(User user, Fixture fx) {
        Integer n = jdbc.queryForObject("""
                SELECT COUNT(DISTINCT cible) FROM (
                    SELECT CASE WHEN q.theme_id = ? THEN q.civic_notion_id ELSE q.theme_id END
                               AS cible
                    FROM answers a
                             JOIN attempt_questions aq ON aq.id = a.attempt_question_id
                             JOIN attempts at ON at.id = aq.attempt_id
                             JOIN questions q ON q.id = aq.question_id
                    WHERE at.user_id = ? AND q.module = 'CIVIQUE' AND a.is_correct IS NOT NULL
                ) s WHERE cible IS NOT NULL
                """, Integer.class, fx.themeId(), user.getId());
        return n == null ? 0 : n;
    }

    /** Une cible, où qu'elle soit servie. */
    private static CivicPlanDto.Cible trouver(CivicPlanDto plan, UUID cibleId) {
        return servies(plan).stream()
                .filter(c -> c.id().equals(cibleId))
                .findFirst()
                .orElse(null);
    }

    private static List<CivicPlanDto.Cible> servies(CivicPlanDto plan) {
        return java.util.stream.Stream.of(
                        plan.priorites(), plan.aRevoir(), plan.solides())
                .flatMap(List::stream)
                .toList();
    }

}
