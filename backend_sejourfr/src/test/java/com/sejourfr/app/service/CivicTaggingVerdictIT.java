package com.sejourfr.app.service;

import com.sejourfr.app.entity.Question;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.NotionSuggestionVerdict;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.CivicNotionManager;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.jdbc.core.JdbcTemplate;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * LES VERDICTS DE RELECTURE DU PRÉ-TAGGING (V054, V057), contre la vraie base.
 *
 * <p>Ce que ce test verrouille, et pourquoi chacun compte :
 * <ul>
 *   <li>🛑 <b>quatre gestes, quatre états DISTINCTS</b>. Avant V054, « rejeter »
 *       et « passer » n'écrivaient rien — indiscernables en base — et « valider »
 *       et « corriger » produisaient la MÊME écriture : on ne pouvait donc pas
 *       mesurer si le modèle avait raison, ce qui est tout l'intérêt du
 *       pré-tagging ;</li>
 *   <li>🛑 <b>seuls {@code VALIDATED} et {@code CORRECTED} posent une
 *       notion</b> : rejeter et passer ne touchent jamais la question, et elle
 *       reste dans la file ;</li>
 *   <li>🛑 <b>le SERVEUR décide de {@code VALIDATED} vs {@code CORRECTED}</b>,
 *       en comparant la notion retenue à la suggestion la mieux notée. C'est la
 *       métrique de qualité du modèle : un client qui pourrait l'annoncer
 *       pourrait la mentir ;</li>
 *   <li>🛑 <b>aucune suggestion ne s'applique toute seule</b> : la seule
 *       présence d'une proposition à confiance 1.0 ne pose aucun tag ;</li>
 *   <li>la <b>rétrocompatibilité</b> de {@code {notionCode}} seul ;</li>
 *   <li>🛑 <b>« aucune notion ne convient » est une LIGNE, pas un silence</b>
 *       (V057) : elle est servie par la file (d'où le {@code LEFT JOIN}), elle
 *       ne peut exister qu'une fois par question ({@code UNIQUE NULLS NOT
 *       DISTINCT}), et {@code CONFIRM_NONE} la confirme en stockant
 *       {@code VALIDATED} sans poser de tag. C'est ce verdict qui révélera les
 *       trous du référentiel pendant le job sur les 790 questions.</li>
 * </ul>
 */
class CivicTaggingVerdictIT extends AbstractIntegrationTest {

    private static final String MIEUX_NOTEE = "pv_laicite";
    private static final String AUTRE = "pv_symboles";

    @Autowired private CivicNotionService service;
    @Autowired private CivicNotionManager manager;
    @Autowired private TestData data;
    @Autowired private JdbcTemplate jdbc;
    @Autowired private EntityManager entityManager;

    @Test
    @DisplayName("🛑 VALIDATED : la notion la mieux notée est retenue — notion posée, suggestions marquées")
    void validated() {
        Question question = questionAvecSuggestions();
        User relecteur = data.admin();
        entityManager.flush();
        entityManager.clear();

        NotionSuggestionVerdict verdict =
                service.relire(question.getId(), MIEUX_NOTEE, null, relecteur.getId());

        assertThat(verdict).isEqualTo(NotionSuggestionVerdict.VALIDATED);
        assertThat(notionDe(question.getId())).isEqualTo(MIEUX_NOTEE);
        assertThat(verdicts(question.getId()))
                .containsOnly(NotionSuggestionVerdict.VALIDATED.name());
        // Qui a tranché, et quand : sans ces deux-là, une campagne ne se
        // rattache à rien et son taux ne veut plus rien dire.
        assertThat(relecteurs(question.getId())).containsOnly(relecteur.getId());
        assertThat(datesDeRelecture(question.getId())).doesNotContainNull();
    }

    @Test
    @DisplayName("🛑 CORRECTED : une AUTRE notion est retenue — elle est posée, et l'écart est mesuré")
    void corrected() {
        Question question = questionAvecSuggestions();
        User relecteur = data.admin();
        entityManager.flush();
        entityManager.clear();

        NotionSuggestionVerdict verdict =
                service.relire(question.getId(), AUTRE, null, relecteur.getId());

        assertThat(verdict).isEqualTo(NotionSuggestionVerdict.CORRECTED);
        // 🛑 Le tag EST posé : corriger n'est pas rejeter.
        assertThat(notionDe(question.getId())).isEqualTo(AUTRE);
        assertThat(verdicts(question.getId()))
                .containsOnly(NotionSuggestionVerdict.CORRECTED.name());
    }

    @Test
    @DisplayName("🛑 REJECTED : aucune notion posée, la suggestion porte le refus")
    void rejected() {
        Question question = questionAvecSuggestions();
        User relecteur = data.admin();
        entityManager.flush();
        entityManager.clear();

        NotionSuggestionVerdict verdict =
                service.relire(question.getId(), null, "REJECTED", relecteur.getId());

        assertThat(verdict).isEqualTo(NotionSuggestionVerdict.REJECTED);
        // 🛑 La question n'est PAS taguée : « aucune notion ne convient » n'est
        // pas un tag, et l'écrire en serait un.
        assertThat(notionDe(question.getId())).isNull();
        assertThat(verdicts(question.getId()))
                .containsOnly(NotionSuggestionVerdict.REJECTED.name());
    }

    @Test
    @DisplayName("🛑 SKIPPED : rien n'est posé, et la question RESTE dans la file")
    void skipped() {
        Question question = questionAvecSuggestions();
        User relecteur = data.admin();
        entityManager.flush();
        entityManager.clear();

        NotionSuggestionVerdict verdict =
                service.relire(question.getId(), null, "SKIPPED", relecteur.getId());

        assertThat(verdict).isEqualTo(NotionSuggestionVerdict.SKIPPED);
        assertThat(notionDe(question.getId())).isNull();
        assertThat(verdicts(question.getId()))
                .containsOnly(NotionSuggestionVerdict.SKIPPED.name());
        // 🛑 « Je passe » ne clôt rien : passer n'écarte pas la question du
        // chantier, sinon la file finirait par cacher ce qu'on a évité.
        assertThat(fileDuThemeDe(question.getId()))
                .anySatisfy(q -> assertThat(q.questionId()).isEqualTo(question.getId()));
    }

    @Test
    @DisplayName("🛑 Les quatre verdicts sont DISCERNABLES : quatre gestes, quatre écritures différentes")
    void quatreEtatsDistincts() {
        User relecteur = data.admin();
        Question validee = questionAvecSuggestions();
        Question corrigee = questionAvecSuggestions();
        Question rejetee = questionAvecSuggestions();
        Question passee = questionAvecSuggestions();
        entityManager.flush();
        entityManager.clear();

        service.relire(validee.getId(), MIEUX_NOTEE, null, relecteur.getId());
        service.relire(corrigee.getId(), AUTRE, null, relecteur.getId());
        service.relire(rejetee.getId(), null, "REJECTED", relecteur.getId());
        service.relire(passee.getId(), null, "SKIPPED", relecteur.getId());

        assertThat(Map.of(
                "VALIDATED", verdicts(validee.getId()),
                "CORRECTED", verdicts(corrigee.getId()),
                "REJECTED", verdicts(rejetee.getId()),
                "SKIPPED", verdicts(passee.getId())))
                .allSatisfy((attendu, lus) -> assertThat(lus).containsOnly(attendu));

        // 🛑 Et SEULS les deux premiers posent un `civic_notion_id`.
        assertThat(notionDe(validee.getId())).isEqualTo(MIEUX_NOTEE);
        assertThat(notionDe(corrigee.getId())).isEqualTo(AUTRE);
        assertThat(notionDe(rejetee.getId())).isNull();
        assertThat(notionDe(passee.getId())).isNull();
    }

    @Test
    @DisplayName("🛑 Un client ne peut PAS annoncer VALIDATED : le serveur seul compare")
    void leClientNePeutPasAnnoncerLeVerdict() {
        Question question = questionAvecSuggestions();
        User relecteur = data.admin();
        entityManager.flush();
        entityManager.clear();

        // Le client retient AUTRE (donc CORRECTED) mais prétend avoir validé :
        // accepter le mensonge fabriquerait un taux de réussite du modèle.
        assertThatThrownBy(() -> service.relire(
                question.getId(), AUTRE, "VALIDATED", relecteur.getId()))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("serveur");
        assertThatThrownBy(() -> service.relire(
                question.getId(), MIEUX_NOTEE, "CORRECTED", relecteur.getId()))
                .isInstanceOf(BusinessException.class);
        assertThatThrownBy(() -> service.relire(
                question.getId(), MIEUX_NOTEE, "PEUT_ETRE", relecteur.getId()))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("Verdict inconnu");

        // Rien n'a été écrit au passage.
        assertThat(notionDe(question.getId())).isNull();
        assertThat(verdicts(question.getId())).containsOnlyNulls();
    }

    @Test
    @DisplayName("Le verdict se déduit de la MIEUX NOTÉE, pas de la première venue")
    void leVerdictSuitLaConfiance() {
        Question question = data.question();
        entityManager.flush();
        // Ordre d'insertion inverse de l'ordre de confiance : si le serveur
        // lisait « la première ligne », il rendrait le mauvais verdict.
        suggerer(question.getId(), AUTRE, 0.31);
        suggerer(question.getId(), MIEUX_NOTEE, 0.93);
        entityManager.clear();

        assertThat(service.relire(question.getId(), MIEUX_NOTEE, "TAG", data.admin().getId()))
                .isEqualTo(NotionSuggestionVerdict.VALIDATED);
    }

    @Test
    @DisplayName("🛑 RÉTROCOMPATIBLE : `{notionCode}` seul pose la notion comme avant V054")
    void retrocompatibiliteNotionCodeSeul() {
        Question question = data.question();
        entityManager.flush();
        entityManager.clear();

        // Aucune suggestion en base : c'est l'état NORMAL aujourd'hui, aucune
        // campagne n'a tourné. Le geste doit marcher quand même.
        NotionSuggestionVerdict verdict = service.taguer(question.getId(), MIEUX_NOTEE);

        assertThat(verdict).isNull();
        assertThat(notionDe(question.getId())).isEqualTo(MIEUX_NOTEE);

        // Et l'effacement reste un effacement : se tromper doit rester
        // rattrapable sans passer par la base.
        assertThat(service.taguer(question.getId(), null)).isNull();
        assertThat(notionDe(question.getId())).isNull();
    }

    @Test
    @DisplayName("Un verdict sans tag refuse une notion, et « TAG » exige la sienne")
    void gestesIncoherentsRefuses() {
        Question question = questionAvecSuggestions();
        User relecteur = data.admin();
        entityManager.flush();
        entityManager.clear();

        // Rejeter ET poser une notion sont deux gestes contraires : deviner
        // lequel l'emporte produirait une base qui ne dit pas ce qui a été fait.
        assertThatThrownBy(() -> service.relire(
                question.getId(), MIEUX_NOTEE, "REJECTED", relecteur.getId()))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("notionCode");
        // « TAG » sans notion n'est pas un effacement : ce serait retirer un tag
        // que personne n'a demandé de retirer.
        assertThatThrownBy(() -> service.relire(
                question.getId(), null, "TAG", relecteur.getId()))
                .isInstanceOf(BusinessException.class);
        assertThat(verdicts(question.getId())).containsOnlyNulls();
    }

    @Test
    @DisplayName("Rejeter une question inexistante ne réussit pas en silence")
    void rejeterUneQuestionInconnue() {
        assertThatThrownBy(() -> service.relire(
                UUID.randomUUID(), null, "SKIPPED", data.admin().getId()))
                .isInstanceOf(NotFoundException.class);
    }

    @Test
    @DisplayName("🛑 AUCUN chemin d'application automatique : une suggestion à 1.0 ne tague rien")
    void aucuneApplicationAutomatique() {
        Question question = data.question();
        entityManager.flush();

        suggerer(question.getId(), MIEUX_NOTEE, 1.0);
        entityManager.clear();

        // 🛑 Ni trigger, ni règle, ni effet de bord : la certitude d'une machine
        // ne vaut pas décision. « Le job propose, un humain valide » (50_ §6.1.3).
        assertThat(notionDe(question.getId())).isNull();
        assertThat(fileDuThemeDe(question.getId()))
                .anySatisfy(q -> {
                    assertThat(q.questionId()).isEqualTo(question.getId());
                    assertThat(q.notionCode()).isNull();
                    // La suggestion est SERVIE, jamais appliquée — et le front
                    // voit qu'elle n'a pas encore été relue.
                    assertThat(q.suggestions()).singleElement().satisfies(s -> {
                        assertThat(s.notionCode()).isEqualTo(MIEUX_NOTEE);
                        assertThat(s.rationale()).isEqualTo("Parce que.");
                        assertThat(s.reviewVerdict()).isNull();
                    });
                });
    }

    @Test
    @DisplayName("La file sert la question ENTIÈRE : explication et propositions comprises")
    void laFileSertLaQuestionEntiere() {
        Question question = data.question();
        entityManager.flush();
        entityManager.clear();

        assertThat(fileDuThemeDe(question.getId()))
                .filteredOn(q -> q.questionId().equals(question.getId()))
                .singleElement()
                .satisfies(q -> {
                    assertThat(q.enonce()).isNotBlank();
                    assertThat(q.explication()).isNotBlank();
                    // Trancher sur le seul énoncé, c'est trancher sans la moitié
                    // du texte (20_ §3.2).
                    assertThat(q.choix()).isNotEmpty();
                    assertThat(q.choix()).anySatisfy(c -> assertThat(c.correct()).isTrue());
                });
    }

    @Test
    @DisplayName("🛑 `prompt_version` est obligatoire : une suggestion sans version ne s'écrit pas")
    void promptVersionObligatoire() {
        Question question = data.question();
        entityManager.flush();

        assertThatThrownBy(() -> jdbc.update("""
                INSERT INTO question_notion_suggestions (question_id, notion_id, confidence)
                VALUES (?, (SELECT id FROM civic_notions WHERE code = ?), 0.5)
                """, question.getId(), MIEUX_NOTEE))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    @DisplayName("Le CHECK borne les verdicts aux quatre valeurs connues")
    void verdictHorsListeRefuse() {
        Question question = data.question();
        entityManager.flush();
        suggerer(question.getId(), MIEUX_NOTEE, 0.5);

        assertThatThrownBy(() -> jdbc.update("""
                UPDATE question_notion_suggestions
                SET review_verdict = 'PEUT_ETRE', reviewed_at = now()
                WHERE question_id = ?
                """, question.getId()))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    // ========================================================================
    // « AUCUNE NOTION NE CONVIENT » — le verdict qui révèle les trous du
    // référentiel (V057).
    // ========================================================================

    @Test
    @DisplayName("🛑 Une suggestion « aucune notion » est SERVIE par la file (LEFT JOIN)")
    void laSuggestionAucuneNotionEstServie() {
        Question question = data.question();
        entityManager.flush();
        // Le cas réel du pilote : « Quel roi a établi l'édit de Nantes ? » —
        // AUCUNE, 0,60. Avec un JOIN interne, cette ligne disparaît en silence
        // et la question sort des métriques : 49 lignes pour 50 entrées.
        suggererAucune(question.getId(), 0.60);
        entityManager.clear();

        assertThat(fileDuThemeDe(question.getId()))
                .filteredOn(q -> q.questionId().equals(question.getId()))
                .singleElement()
                .satisfies(q -> assertThat(q.suggestions()).singleElement().satisfies(s -> {
                    // 🛑 NULL, jamais une sentinelle « AUCUNE » : le front doit
                    // pouvoir distinguer sans deviner.
                    assertThat(s.notionCode()).isNull();
                    assertThat(s.notionLabel()).isNull();
                    // Le reste est servi normalement — c'est la justification
                    // qui dira au relecteur quelle notion manque.
                    assertThat(s.confidence()).isEqualTo(0.60);
                    assertThat(s.rationale()).isEqualTo("Parce que.");
                    assertThat(s.reviewVerdict()).isNull();
                }));
    }

    @Test
    @DisplayName("🛑 UNIQUE NULLS NOT DISTINCT : une seule ligne « aucune notion » par question")
    void uneSeuleLigneAucuneNotionParQuestion() {
        Question question = data.question();
        entityManager.flush();
        suggererAucune(question.getId(), 0.60);
        assertThat(nombreDeSuggestions(question.getId())).isEqualTo(1);

        // Sans NULLS NOT DISTINCT, Postgres tient deux NULL pour distincts :
        // rien n'empêcherait dix lignes « aucune notion » sur la même question,
        // et un trou du référentiel se compterait dix fois.
        assertThatThrownBy(() -> suggererAucune(question.getId(), 0.42))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    @DisplayName("🛑 CONFIRM_NONE sur une suggestion « aucune » : stocké VALIDATED, AUCUN tag posé")
    void confirmNoneStockeValidated() {
        Question question = data.question();
        entityManager.flush();
        suggererAucune(question.getId(), 0.60);
        User relecteur = data.admin();
        entityManager.flush();
        entityManager.clear();

        NotionSuggestionVerdict verdict =
                service.relire(question.getId(), null, "CONFIRM_NONE", relecteur.getId());

        // 🛑 VALIDATED, parce que la proposition du modèle — « aucune » — était
        // juste. C'est exactement ce qui rend la métrique mesurable.
        assertThat(verdict).isEqualTo(NotionSuggestionVerdict.VALIDATED);
        assertThat(verdicts(question.getId()))
                .containsOnly(NotionSuggestionVerdict.VALIDATED.name());
        // 🛑 Et aucun tag : confirmer un trou n'est pas ranger la question.
        assertThat(notionDe(question.getId())).isNull();
        assertThat(relecteurs(question.getId())).containsOnly(relecteur.getId());
    }

    @Test
    @DisplayName("🛑 CONFIRM_NONE est REFUSÉ quand la meilleure suggestion propose une vraie notion")
    void confirmNoneRefuseSurUneVraieNotion() {
        Question question = questionAvecSuggestions();
        User relecteur = data.admin();
        entityManager.flush();
        entityManager.clear();

        // Le client affirmerait que le modèle n'a proposé aucune notion alors
        // qu'il en a proposé une : c'est un mensonge sur sa qualité, au même
        // titre qu'annoncer VALIDATED soi-même.
        assertThatThrownBy(() -> service.relire(
                question.getId(), null, "CONFIRM_NONE", relecteur.getId()))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("CONFIRM_NONE");
        assertThat(verdicts(question.getId())).containsOnlyNulls();
        assertThat(notionDe(question.getId())).isNull();
    }

    @Test
    @DisplayName("CONFIRM_NONE sur une question JAMAIS pré-taguée est refusé lui aussi")
    void confirmNoneRefuseSansAucuneSuggestion() {
        Question question = data.question();
        entityManager.flush();
        entityManager.clear();

        // « Le modèle a eu raison de dire non » n'a aucun sens quand le modèle
        // n'a rien dit : l'absence de ligne n'est pas un verdict.
        assertThatThrownBy(() -> service.relire(
                question.getId(), null, "CONFIRM_NONE", data.admin().getId()))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("pas ete pre-taguee");
    }

    @Test
    @DisplayName("CONFIRM_NONE avec un notionCode est refusé : deux gestes contraires")
    void confirmNoneAvecNotionCodeRefuse() {
        Question question = data.question();
        entityManager.flush();
        suggererAucune(question.getId(), 0.60);
        entityManager.clear();

        assertThatThrownBy(() -> service.relire(
                question.getId(), MIEUX_NOTEE, "CONFIRM_NONE", data.admin().getId()))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("notionCode");
        assertThat(verdicts(question.getId())).containsOnlyNulls();
    }

    @Test
    @DisplayName("🛑 Corriger une suggestion « aucune » donne CORRECTED, pas VALIDATED")
    void corrigerUneSuggestionAucuneDonneCorrected() {
        Question question = data.question();
        entityManager.flush();
        suggererAucune(question.getId(), 0.60);
        entityManager.clear();

        NotionSuggestionVerdict verdict =
                service.relire(question.getId(), MIEUX_NOTEE, null, data.admin().getId());

        // ⚠️ Le modèle s'était trompé : il disait « rien », le relecteur trouve
        // une notion. Rendre VALIDATED ici gonflerait le taux d'accord.
        assertThat(verdict).isEqualTo(NotionSuggestionVerdict.CORRECTED);
        assertThat(notionDe(question.getId())).isEqualTo(MIEUX_NOTEE);
        assertThat(verdicts(question.getId()))
                .containsOnly(NotionSuggestionVerdict.CORRECTED.name());
    }

    @Test
    @DisplayName("🛑 Les TROIS cas de meilleureSuggestion se distinguent sans ambiguïté")
    void troisCasDeMeilleureSuggestion() {
        Question sansSuggestion = data.question();
        Question aucuneNotion = data.question();
        Question avecNotion = data.question();
        entityManager.flush();
        suggererAucune(aucuneNotion.getId(), 0.60);
        suggerer(avecNotion.getId(), MIEUX_NOTEE, 0.88);
        entityManager.clear();

        // 1. La question n'a pas été pré-taguée : rien à qualifier.
        CivicNotionManager.MeilleureSuggestion absente =
                manager.meilleureSuggestion(sansSuggestion.getId());
        assertThat(absente.existe()).isFalse();
        assertThat(absente.conclutAucuneNotion()).isFalse();

        // 2. Le modèle a conclu « aucune notion » : c'est un VERDICT.
        CivicNotionManager.MeilleureSuggestion aucune =
                manager.meilleureSuggestion(aucuneNotion.getId());
        assertThat(aucune.existe()).isTrue();
        assertThat(aucune.conclutAucuneNotion()).isTrue();
        assertThat(aucune.designe(idDeLaNotion(MIEUX_NOTEE))).isFalse();

        // 3. Le modèle a proposé une notion.
        CivicNotionManager.MeilleureSuggestion notion =
                manager.meilleureSuggestion(avecNotion.getId());
        assertThat(notion.existe()).isTrue();
        assertThat(notion.conclutAucuneNotion()).isFalse();
        assertThat(notion.designe(idDeLaNotion(MIEUX_NOTEE))).isTrue();
    }

    @Test
    @DisplayName("« Aucune » cohabite avec une alternative, et la CONFIANCE départage")
    void aucuneNotionEtAlternativeCohabitent() {
        // Le tool-schema du job accepte « AUCUNE » en notion ET en alternative
        // (règle 8 : donner l'autre option quand on hésite). « Probablement
        // rien, sinon pv_laicite » est une hésitation honnête : l'interdire
        // ferait taire l'une des deux moitiés.
        Question question = data.question();
        entityManager.flush();
        suggererAucune(question.getId(), 0.62);
        suggerer(question.getId(), MIEUX_NOTEE, 0.31);
        entityManager.clear();

        assertThat(nombreDeSuggestions(question.getId())).isEqualTo(2);
        assertThat(service.relire(question.getId(), null, "CONFIRM_NONE", data.admin().getId()))
                .isEqualTo(NotionSuggestionVerdict.VALIDATED);
        // Les DEUX lignes portent le verdict : la relecture qualifie la
        // QUESTION, jamais une ligne isolée (V054).
        assertThat(verdicts(question.getId()))
                .hasSize(2)
                .containsOnly(NotionSuggestionVerdict.VALIDATED.name());
    }

    @Test
    @DisplayName("À confiance ÉGALE, la notion nommée passe avant « aucune » (NULLS LAST)")
    void aConfianceEgaleLaNotionNommeePasseDevant() {
        Question question = data.question();
        entityManager.flush();
        suggererAucune(question.getId(), 0.70);
        suggerer(question.getId(), MIEUX_NOTEE, 0.70);
        entityManager.clear();

        // Le tri doit rester déterministe avec un NULL : sans NULLS LAST, deux
        // exécutions pourraient rendre deux verdicts différents.
        assertThat(manager.meilleureSuggestion(question.getId()).designe(idDeLaNotion(MIEUX_NOTEE)))
                .isTrue();
        assertThatThrownBy(() -> service.relire(
                question.getId(), null, "CONFIRM_NONE", data.admin().getId()))
                .isInstanceOf(BusinessException.class);
    }

    // ------------------------------------------------------------------------

    /** Une question civique et deux suggestions, la mieux notée d'abord. */
    private Question questionAvecSuggestions() {
        Question question = data.question();
        entityManager.flush();
        suggerer(question.getId(), MIEUX_NOTEE, 0.88);
        suggerer(question.getId(), AUTRE, 0.42);
        return question;
    }

    /**
     * Écrit une suggestion comme une campagne le ferait.
     *
     * <p>🛑 <b>Aucun LLM n'est appelé</b> : le pilote est une décision du
     * propriétaire. On écrit en base ce qu'une campagne produirait.
     */
    private void suggerer(UUID questionId, String notionCode, double confidence) {
        jdbc.update("""
                INSERT INTO question_notion_suggestions
                    (question_id, notion_id, confidence, model, prompt_version, rationale, batch_id)
                VALUES (?, (SELECT id FROM civic_notions WHERE code = ?), ?,
                        'test-model', 'PROMPT_TAG_NOTION_v1', 'Parce que.', ?)
                """, questionId, notionCode, confidence, UUID.randomUUID());
    }

    /**
     * Écrit la suggestion « <b>aucune notion du référentiel ne convient</b> »
     * (V057) — telle que l'import d'un lot l'écrit quand le modèle répond
     * {@code AUCUNE}.
     *
     * <p>🛑 {@code notion_id NULL}, et <b>aucune notion technique
     * « AUCUNE »</b> dans {@code civic_notions} : le référentiel ne contient
     * que de vraies notions pédagogiques.
     */
    private void suggererAucune(UUID questionId, double confidence) {
        jdbc.update("""
                INSERT INTO question_notion_suggestions
                    (question_id, notion_id, confidence, model, prompt_version, rationale, batch_id)
                VALUES (?, NULL, ?, 'test-model', 'PROMPT_TAG_NOTION_v1', 'Parce que.', ?)
                """, questionId, confidence, UUID.randomUUID());
    }

    private int nombreDeSuggestions(UUID questionId) {
        Integer n = jdbc.queryForObject(
                "SELECT COUNT(*) FROM question_notion_suggestions WHERE question_id = ?",
                Integer.class, questionId);
        return n == null ? 0 : n;
    }

    private UUID idDeLaNotion(String code) {
        return jdbc.queryForObject(
                "SELECT id FROM civic_notions WHERE code = ?", UUID.class, code);
    }

    /**
     * La file restreinte au theme de CETTE question.
     *
     * <p>La file est ordonnee par {@code created_at} sur les 1 016 questions
     * seedees : une question creee a l'instant est en QUEUE, pas en tete. Filtrer
     * par son theme est la seule facon stable de la retrouver.
     */
    private List<com.sejourfr.app.dto.QuestionTaggingDto> fileDuThemeDe(UUID questionId) {
        String themeCode = jdbc.queryForObject("""
                SELECT t.code FROM questions q JOIN themes t ON t.id = q.theme_id
                WHERE q.id = ?
                """, String.class, questionId);
        return service.fileDeTagging(themeCode, false, 100, 0).questions();
    }

    private String notionDe(UUID questionId) {
        return jdbc.queryForObject("""
                SELECT n.code FROM questions q
                         LEFT JOIN civic_notions n ON n.id = q.civic_notion_id
                WHERE q.id = ?
                """, String.class, questionId);
    }

    private List<String> verdicts(UUID questionId) {
        return jdbc.queryForList(
                "SELECT review_verdict FROM question_notion_suggestions WHERE question_id = ?",
                String.class, questionId);
    }

    private List<UUID> relecteurs(UUID questionId) {
        return jdbc.queryForList(
                "SELECT reviewed_by FROM question_notion_suggestions WHERE question_id = ?",
                UUID.class, questionId);
    }

    private List<Instant> datesDeRelecture(UUID questionId) {
        return jdbc.queryForList(
                "SELECT reviewed_at FROM question_notion_suggestions WHERE question_id = ?",
                Instant.class, questionId);
    }
}
