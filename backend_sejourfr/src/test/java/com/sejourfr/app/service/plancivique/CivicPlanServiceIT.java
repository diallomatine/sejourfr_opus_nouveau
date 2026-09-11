package com.sejourfr.app.service.plancivique;

import com.sejourfr.app.dto.AttemptResponse;
import com.sejourfr.app.dto.CivicPlanDto;
import com.sejourfr.app.entity.CivicDiagnosticSession;
import com.sejourfr.app.config.CivicPlanProperties;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import com.sejourfr.app.service.diagnosticcivique.CivicDiagnosticService;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.access.AccessDeniedException;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * LE PLAN CIVIQUE (L10), contre la vraie base et le vrai catalogue.
 *
 * <p>Ce que ce test verrouille, et pourquoi chacun compte :
 * <ul>
 *   <li>🛑 <b>sans diagnostic, aucune cible</b> — un plan bâti sur une mesure
 *       qui n'existe pas serait une invention. L'écran doit savoir POURQUOI il
 *       n'a rien à montrer, d'où {@code disponible} plutôt qu'une liste
 *       vide ;</li>
 *   <li>🛑 <b>le mode dégradé est le régime NORMAL au lancement</b> : 0 question
 *       sur 1 016 est taguée, donc les cinq thèmes travaillent au grain thème
 *       ({@code 20_} §3.3 phase 1). Si ce test tombe en NOTION, c'est que le
 *       seuil a été contourné ;</li>
 *   <li>🛑 <b>le grain bascule PAR THÈME</b>, et il se mesure : taguer un thème
 *       suffit à le faire passer en notions sans toucher aux autres ;</li>
 *   <li>🛑 <b>un thème n'est JAMAIS maîtrisé</b> — quatre bonnes réponses sur
 *       deux cents questions ne prouvent rien, et l'annoncer acquis
 *       reproduirait « NON FRAGILE ≠ PLUS RIEN À APPRENDRE » ;</li>
 *   <li>🛑 <b>le verrou porte sur la SÉRIE, pas sur le constat</b>, et il est
 *       opposable : le {@code locked} servi et le 403 sont la même règle ;</li>
 *   <li>🛑 <b>zéro question dans la mention n'est pas « il manque de la
 *       matière »</b> : c'est {@code NON_APPLICABLE}, la notion n'est pas au
 *       programme de cette démarche. V058 l'a mesuré sur le corpus réel — CSP,
 *       CR et NAT sont trois programmes différents ;</li>
 *   <li>la série ciblée remet en tête ce qui a été <b>raté</b> : sans cet ordre,
 *       « travailler ce point » redonnerait les questions déjà réussies.</li>
 * </ul>
 */
class CivicPlanServiceIT extends AbstractIntegrationTest {

    @Autowired private CivicPlanService service;
    @Autowired private CivicDiagnosticService diagnosticService;
    @Autowired private TestData testData;
    @Autowired private EntityManager entityManager;
    @Autowired private JdbcTemplate jdbc;
    @Autowired private CivicPlanProperties props;

    /** Ouvre un diagnostic, y répond faux partout, et le clôt. */
    private CivicDiagnosticSession diagnosticTermine(User user) {
        CivicDiagnosticSession session = diagnosticService.ouvrir(user.getId());
        entityManager.flush();
        repondre(session.getAttempt().getId(), false, Integer.MAX_VALUE);
        diagnosticService.cloturer(user.getId(), session.getId());
        entityManager.flush();
        entityManager.clear();
        return session;
    }

    /**
     * Écrit des réponses directement, comme le runner le ferait.
     *
     * <p>On passe par SQL plutôt que par le service de soumission : ce test
     * porte sur le PLAN, et faire jouer un runner entier n'ajouterait qu'un
     * point de rupture sans rien verrouiller de plus.
     */
    private void repondre(UUID attemptId, boolean correcte, int combien) {
        List<UUID> aqs = jdbc.queryForList("""
                SELECT id FROM attempt_questions
                WHERE attempt_id = ? ORDER BY position LIMIT ?
                """, UUID.class, attemptId, combien);
        for (UUID aq : aqs) {
            jdbc.update("""
                    INSERT INTO answers (id, attempt_question_id, user_id, selected_choice_ids,
                                         is_correct, answered_at)
                    SELECT gen_random_uuid(), ?, a.user_id, '[]'::jsonb, ?, now()
                    FROM attempt_questions aq JOIN attempts a ON a.id = aq.attempt_id
                    WHERE aq.id = ?
                    """, aq, correcte, aq);
        }
    }

    @Test
    @DisplayName("🛑 Sans diagnostic terminé, le plan n'invente aucune cible")
    void sansDiagnosticAucuneCible() {
        User user = testData.user();

        CivicPlanDto plan = service.plan(user.getId());

        assertThat(plan.disponible()).isFalse();
        assertThat(plan.priorites()).isEmpty();
        assertThat(plan.prochaine()).isNull();
        assertThat(plan.resultat()).isNull();
        // La mention est servie quand même : l'écran peut déjà dire sur quel
        // programme le candidat sera mesuré.
        assertThat(plan.mention()).isNotNull();
    }

    @Test
    @DisplayName("🛑 Au lancement, le plan travaille par THÈME — c'est le mode prévu, pas une panne")
    void modeDegradeParTheme() {
        User user = testData.user();
        diagnosticTermine(user);

        CivicPlanDto plan = service.plan(user.getId());

        assertThat(plan.disponible()).isTrue();
        assertThat(plan.grain().courant()).isEqualTo(CivicPlanGrain.THEME);
        assertThat(plan.grain().themesParNotion()).isZero();
        assertThat(plan.grain().total()).isPositive();
        // Une cible par thème, et toutes au grain thème.
        assertThat(plan.priorites()).isNotEmpty();
        assertThat(plan.priorites()).allSatisfy(
                c -> assertThat(c.grain()).isEqualTo(CivicPlanGrain.THEME));
        // 🛑 Plafond d'AFFICHAGE : trois servies, le reste COMPTÉ.
        assertThat(plan.priorites()).hasSizeLessThanOrEqualTo(3);
        assertThat(plan.autresPriorites()).isNotNegative();
        assertThat(plan.prochaine()).isEqualTo(plan.priorites().getFirst());
    }

    @Test
    @DisplayName("Le résultat servi est celui du diagnostic, directement comparable au seuil")
    void resultatComparableAuSeuil() {
        User user = testData.user();
        diagnosticTermine(user);

        CivicPlanDto.Resultat resultat = service.plan(user.getId()).resultat();

        assertThat(resultat).isNotNull();
        assertThat(resultat.format()).isEqualTo(40);
        assertThat(resultat.seuil()).isEqualTo(32);
        assertThat(resultat.posees()).isPositive();
        assertThat(resultat.bonnes()).isZero();
    }

    @Test
    @DisplayName("🛑 Un thème n'est JAMAIS annoncé maîtrisé, même avec une série de bonnes réponses")
    void unThemeNestJamaisMaitrise() {
        User user = testData.user();
        CivicDiagnosticSession session = diagnosticService.ouvrir(user.getId());
        entityManager.flush();
        // Tout juste : au grain notion, ce serait MAITRISEE.
        repondre(session.getAttempt().getId(), true, Integer.MAX_VALUE);
        diagnosticService.cloturer(user.getId(), session.getId());
        entityManager.flush();
        entityManager.clear();

        CivicPlanDto plan = service.plan(user.getId());

        assertThat(plan.solides()).isEmpty();
        assertThat(plan.priorites()).allSatisfy(c ->
                assertThat(c.maitrise()).isNotEqualTo(CivicMaitrise.MAITRISEE));
    }

    @Test
    @DisplayName("🛑 Le verrou porte sur la SÉRIE : le constat reste entier pour un compte gratuit")
    void constatGratuitSerieVerrouillee() {
        User user = testData.user();
        diagnosticTermine(user);

        CivicPlanDto plan = service.plan(user.getId());

        // Les priorités sont servies ENTIÈRES, avec leurs états et leurs compteurs.
        assertThat(plan.priorites()).isNotEmpty();
        assertThat(plan.priorites()).allSatisfy(c -> {
            assertThat(c.label()).isNotBlank();
            assertThat(c.maitrise()).isNotNull();
            assertThat(c.locked()).isTrue();
        });

        // 🛑 Et le verrou est OPPOSABLE : le `locked` servi et ce refus sont la
        // même règle. Un front dont le statut premium est périmé reçoit un 403.
        UUID cible = plan.priorites().getFirst().id();
        assertThatThrownBy(() -> service.demarrerSerie(
                user.getId(), cible, CivicPlanGrain.THEME))
                .isInstanceOf(AccessDeniedException.class);
    }

    @Test
    @DisplayName("Un abonné ouvre sa série ciblée, et elle remet en tête ce qu'il a raté")
    void serieCibleeAbonne() {
        User user = testData.user();
        testData.userSubscription(user, testData.plan());
        CivicDiagnosticSession session = diagnosticTermine(user);
        entityManager.flush();
        entityManager.clear();

        CivicPlanDto plan = service.plan(user.getId());
        assertThat(plan.priorites()).allSatisfy(c -> assertThat(c.locked()).isFalse());

        CivicPlanDto.Cible cible = plan.priorites().getFirst();
        AttemptResponse attempt =
                service.demarrerSerie(user.getId(), cible.id(), CivicPlanGrain.THEME);
        entityManager.flush();

        assertThat(attempt.questions()).hasSize(cible.questionsSerie());
        // 🛑 C'est un TRAINING : le candidat le joue dans le runner existant, et
        // il ne consomme aucun slot d'examen blanc.
        assertThat(attempt.type().name()).isEqualTo("TRAINING");

        // 🛑 L'ordre porte l'intention du plan : les questions ratées au
        // diagnostic reviennent d'abord. Sans ça, « travailler ce thème »
        // redonnerait ce qui est déjà acquis.
        List<UUID> ratees = jdbc.queryForList("""
                SELECT aq.question_id FROM answers a
                         JOIN attempt_questions aq ON aq.id = a.attempt_question_id
                WHERE aq.attempt_id = ? AND a.is_correct = false
                """, UUID.class, session.getAttempt().getId());
        List<UUID> tirees = attempt.questions().stream()
                .map(q -> q.question().id()).toList();
        assertThat(tirees).anyMatch(ratees::contains);
    }

    @Test
    @DisplayName("🛑 Le grain bascule PAR THÈME dès que son tagging franchit le seuil")
    void bascuceDuGrainParTheme() {
        User user = testData.user();
        diagnosticTermine(user);

        // On tague toutes les questions de CONNAISSANCE d'un seul thème, sur la
        // première notion de ce thème. Les autres thèmes ne bougent pas.
        String themeCode = jdbc.queryForObject("""
                SELECT t.code FROM civic_notions n JOIN themes t ON t.code = n.theme_code
                WHERE n.is_active = true ORDER BY n.theme_code, n.display_order LIMIT 1
                """, String.class);
        int taguees = taguerLesConnaissances(themeCode, premiereNotion(themeCode));
        assertThat(taguees).isPositive();

        CivicPlanDto plan = service.plan(user.getId());

        // 🛑 Ce thème seul est passé en notions ; le plan ne se dit pas plus
        // précis qu'il ne l'est tant que les autres n'ont pas suivi.
        assertThat(plan.grain().themesParNotion()).isEqualTo(1);
        assertThat(plan.grain().courant()).isEqualTo(CivicPlanGrain.THEME);
        assertThat(plan.grain().taguees()).isEqualTo(taguees);
    }

    @Test
    @DisplayName("🛑 LA BASCULE NE COMPTE QUE LES CONNAISSANCE : un thème 100 % tagué "
            + "bascule même avec ses mises en situation non taguées")
    void laBasculeNeCompteQueLesConnaissances() {
        User user = testData.user();
        diagnosticTermine(user);

        // 🛑 On choisit exprès un thème que l'ANCIENNE règle n'aurait JAMAIS
        // fait basculer : ses mises en situation pèsent assez pour le maintenir
        // sous 80 % quand bien même 100 % de ses connaissances seraient taguées.
        // C'est la situation mesurée sur trois thèmes sur cinq (77,9 / 77,9 /
        // 79,0 %) : le grain notion leur était inaccessible par construction.
        String themeCode = jdbc.queryForObject("""
                SELECT t.code
                FROM questions q JOIN themes t ON t.id = q.theme_id
                WHERE q.module = 'CIVIQUE' AND q.is_active = true
                GROUP BY t.code
                HAVING COUNT(*) FILTER (WHERE q.question_type = 'CONNAISSANCE')::numeric
                           / COUNT(*) < 0.80
                ORDER BY t.code
                LIMIT 1
                """, String.class);
        assertThat(themeCode)
                .as("le catalogue doit contenir un thème sous 80 % de connaissances")
                .isNotNull();

        int taguees = taguerLesConnaissances(themeCode, premiereNotion(themeCode));

        // Les mises en situation restent VOLONTAIREMENT non taguées : elles
        // relèvent des domaines `sit_*` (50_ §6.2), pas des notions.
        Long misesEnSituationNonTaguees = jdbc.queryForObject("""
                SELECT COUNT(*) FROM questions q
                WHERE q.module = 'CIVIQUE' AND q.is_active = true
                  AND q.question_type = 'MISE_SITUATION'
                  AND q.civic_notion_id IS NULL
                  AND q.theme_id = (SELECT id FROM themes WHERE code = ?)
                """, Long.class, themeCode);
        assertThat(misesEnSituationNonTaguees).isPositive();

        CivicPlanDto plan = service.plan(user.getId());

        // 🛑 LE test de ce lot : le thème bascule quand même. Sous l'ancienne
        // règle il plafonnait sous 80 % et restait au grain THÈME à jamais.
        assertThat(plan.grain().themesParNotion()).isEqualTo(1);
        // 🛑 Et les deux métriques ne se mélangent pas : le dénominateur servi
        // ignore les mises en situation, sinon l'écran annoncerait un chantier
        // qui ne se termine jamais.
        assertThat(plan.grain().taguees()).isEqualTo(taguees);
        assertThat(plan.grain().total()).isEqualTo(totalConnaissancesCiviques());

        // Et le grain bascule jusqu'au bout : les CINQ thèmes tagués sur leurs
        // seules connaissances, le plan travaille entièrement par notion — alors
        // que 173 mises en situation restent volontairement sans notion.
        for (String autre : jdbc.queryForList(
                "SELECT DISTINCT theme_code FROM civic_notions WHERE is_active = true",
                String.class)) {
            taguerLesConnaissances(autre, premiereNotion(autre));
        }
        CivicPlanDto entierementTague = service.plan(user.getId());

        assertThat(entierementTague.grain().courant()).isEqualTo(CivicPlanGrain.NOTION);
        assertThat(entierementTague.priorites()).isNotEmpty();
        assertThat(entierementTague.priorites()).allSatisfy(
                c -> assertThat(c.grain()).isEqualTo(CivicPlanGrain.NOTION));
        assertThat(misesEnSituationNonTaguees()).isPositive();
    }

    @Test
    @DisplayName("🛑 Le seuil de contenu est à 5 : 4 questions dans la mention ne suffisent pas")
    void seuilDeContenuACinq() {
        User user = testData.user();
        diagnosticTermine(user);
        CivicPlanDto initial = service.plan(user.getId());
        String mention = initial.mention().name();

        // Un thème au grain NOTION avec DEUX notions actives : tout part sur la
        // seconde, et on dote la première d'exactement 4 questions de la mention.
        String themeCode = themeAvecAssezDeQuestions(mention);
        List<UUID> notions = jdbc.queryForList("""
                SELECT id FROM civic_notions
                WHERE theme_code = ? AND is_active = true ORDER BY display_order LIMIT 2
                """, UUID.class, themeCode);
        jdbc.update("""
                UPDATE civic_notions SET is_active = false
                WHERE theme_code = ? AND id <> ? AND id <> ?
                """, themeCode, notions.get(0), notions.get(1));
        taguerLesConnaissances(themeCode, notions.get(1));
        deplacerVersNotion(themeCode, mention, notions.get(0), 4, 0);

        int proposablesA4 = proposables(service.plan(user.getId()));

        // La 5ᵉ question suffit : la notion devient une unité de parcours.
        deplacerVersNotion(themeCode, mention, notions.get(0), 1, 4);
        int proposablesA5 = proposables(service.plan(user.getId()));

        // 🛑 Exactement une cible a changé de statut, et c'est la notion dotée :
        // à 4 sa dotation est `CONTENU_INSUFFISANT` donc jamais proposable, à 5
        // elle devient `SERVABLE`. « Une notion à 4 questions est trop fragile pour devenir une
        // vraie unité de parcours adaptatif » (arbitrage propriétaire).
        assertThat(proposablesA5).isEqualTo(proposablesA4 + 1);
    }

    @Test
    @DisplayName("Le seuil de contenu servi par la configuration vaut bien 5")
    void seuilDeContenuConfigure() {
        assertThat(props.getQuestionsMinParNotion()).isEqualTo(5);
    }

    /** Tague toutes les questions de CONNAISSANCE actives d'un thème. */
    private int taguerLesConnaissances(String themeCode, UUID notionId) {
        return jdbc.update("""
                UPDATE questions SET civic_notion_id = ?
                WHERE module = 'CIVIQUE' AND is_active = true
                  AND question_type = 'CONNAISSANCE'
                  AND theme_id = (SELECT id FROM themes WHERE code = ?)
                """, notionId, themeCode);
    }

    private UUID premiereNotion(String themeCode) {
        return jdbc.queryForObject("""
                SELECT id FROM civic_notions
                WHERE theme_code = ? AND is_active = true ORDER BY display_order LIMIT 1
                """, UUID.class, themeCode);
    }

    private long misesEnSituationNonTaguees() {
        Long total = jdbc.queryForObject("""
                SELECT COUNT(*) FROM questions
                WHERE module = 'CIVIQUE' AND is_active = true
                  AND question_type = 'MISE_SITUATION' AND civic_notion_id IS NULL
                """, Long.class);
        return total == null ? 0L : total;
    }

    private long totalConnaissancesCiviques() {
        Long total = jdbc.queryForObject("""
                SELECT COUNT(*) FROM questions
                WHERE module = 'CIVIQUE' AND is_active = true
                  AND question_type = 'CONNAISSANCE'
                """, Long.class);
        return total == null ? 0L : total;
    }

    private String themeAvecAssezDeQuestions(String mention) {
        return jdbc.queryForObject("""
                SELECT t.code
                FROM questions q JOIN themes t ON t.id = q.theme_id
                WHERE q.module = 'CIVIQUE' AND q.is_active = true
                  AND q.question_type = 'CONNAISSANCE'
                  AND q.difficulty = CAST(? AS varchar)
                GROUP BY t.code
                HAVING COUNT(*) >= 6
                ORDER BY t.code
                LIMIT 1
                """, String.class, mention);
    }

    /** Déplace {@code combien} questions de la mention vers une autre notion. */
    private void deplacerVersNotion(String themeCode, String mention, UUID notionId,
                                    int combien, int depuis) {
        jdbc.update("""
                UPDATE questions SET civic_notion_id = ?
                WHERE id IN (
                    SELECT q.id FROM questions q
                    WHERE q.module = 'CIVIQUE' AND q.is_active = true
                      AND q.question_type = 'CONNAISSANCE'
                      AND q.difficulty = CAST(? AS varchar)
                      AND q.theme_id = (SELECT id FROM themes WHERE code = ?)
                    ORDER BY q.id LIMIT ? OFFSET ?
                )
                """, notionId, mention, themeCode, combien, depuis);
    }

    /** Les cibles réellement proposables : servies en priorité + celles comptées. */
    private int proposables(CivicPlanDto plan) {
        return plan.priorites().size() + plan.autresPriorites();
    }

    @Test
    @DisplayName("🛑 Seule une cible SERVABLE est servie — en priorité comme en révision")
    void seulLeServableEstServi() {
        User user = testData.user();
        diagnosticTermine(user);

        CivicPlanDto plan = service.plan(user.getId());

        assertThat(plan.priorites())
                .allSatisfy(c -> assertThat(c.dotation()).isEqualTo(CivicDotation.SERVABLE));
        assertThat(plan.aRevoir())
                .allSatisfy(c -> assertThat(c.dotation()).isEqualTo(CivicDotation.SERVABLE));
    }

    @Test
    @DisplayName("🛑 Zéro question dans la mention : la notion n'est pas au programme, et le plan l'ignore")
    void zeroQuestionDansLaMentionNestPasUnManque() {
        User user = testData.user();
        diagnosticTermine(user);
        CivicPlanDto initial = service.plan(user.getId());
        String mention = initial.mention().name();

        // Un thème au grain NOTION avec DEUX notions actives : tout part sur la
        // seconde. La première n'a donc AUCUNE question dans la mention — c'est
        // le cas réel mesuré par V058 (« Devenir français » : 10 questions en
        // NAT, zéro en CSP), pas un cas de laboratoire.
        String themeCode = themeAvecAssezDeQuestions(mention);
        List<UUID> notions = jdbc.queryForList("""
                SELECT id FROM civic_notions
                WHERE theme_code = ? AND is_active = true ORDER BY display_order LIMIT 2
                """, UUID.class, themeCode);
        jdbc.update("""
                UPDATE civic_notions SET is_active = false
                WHERE theme_code = ? AND id <> ? AND id <> ?
                """, themeCode, notions.get(0), notions.get(1));
        taguerLesConnaissances(themeCode, notions.get(1));

        CivicPlanDto aZero = service.plan(user.getId());

        // 🛑 Elle n'apparaît NI dans les priorités, NI dans « à revoir » : elle
        // n'existe pas pour ce candidat.
        assertThat(aZero.priorites()).noneMatch(c -> c.id().equals(notions.get(0)));
        assertThat(aZero.aRevoir()).noneMatch(c -> c.id().equals(notions.get(0)));
        assertThat(aZero.prochaine()).isNotNull();
        assertThat(aZero.prochaine().id()).isNotEqualTo(notions.get(0));

        // Une seule question suffit à la faire EXISTER — elle reste hors du plan
        // (contenu insuffisant), mais ce n'est déjà plus le même verdict.
        deplacerVersNotion(themeCode, mention, notions.get(0), 1, 0);
        CivicPlanDto aUn = service.plan(user.getId());
        assertThat(proposables(aUn)).isEqualTo(proposables(aZero));
        assertThat(aUn.priorites()).noneMatch(c -> c.id().equals(notions.get(0)));

        // Et à 5, elle devient une unité de parcours.
        deplacerVersNotion(themeCode, mention, notions.get(0), 4, 1);
        CivicPlanDto aCinq = service.plan(user.getId());
        assertThat(proposables(aCinq)).isEqualTo(proposables(aZero) + 1);
    }
}
