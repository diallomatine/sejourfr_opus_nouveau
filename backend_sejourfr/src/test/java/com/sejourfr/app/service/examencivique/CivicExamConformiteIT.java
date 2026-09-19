package com.sejourfr.app.service.examencivique;

import com.sejourfr.app.entity.CivicOfficialUnit;
import com.sejourfr.app.entity.Question;
import com.sejourfr.app.enums.CivicExamFormat;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.support.AbstractIntegrationTest;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;
import java.util.stream.IntStream;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * <b>L'examen civique est conforme à l'arrêté — mesuré sur 20 examens générés.</b>
 *
 * <p>Source de droit : <b>arrêté du 10 octobre 2025</b> (JORF n° 0240 du
 * 12 octobre 2025, NOR <b>INTV2527907A</b>), article 3 et annexe I.
 *
 * <h2>Pourquoi 20 examens et non un seul</h2>
 * <p>Le tirage est <b>aléatoire dans chaque unité</b> ({@code ORDER BY random()}).
 * Un examen conforme par chance ne prouve rien ; c'est la <b>répétition</b> qui
 * distingue une contrainte d'un heureux hasard. Avant P8.A, la mesure sur les
 * <b>33</b> examens réellement passés donnait <b>0 conforme</b> : 8/8/8/8/8 au
 * lieu de 11/6/11/8/4, <b>7,7</b> mises en situation au lieu de 12, et
 * <b>58 %</b> de celles-ci hors des deux thématiques autorisées.
 *
 * <h2>🛑 Ce test ne construit AUCUNE fixture</h2>
 * <p>Il tire sur le contenu <b>réellement seedé</b> — les 976 questions civiques
 * actives et les 16 unités de V115. Un examen conforme sur des questions inventées
 * ne dirait rien du produit.
 */
class CivicExamConformiteIT extends AbstractIntegrationTest {

    /** Le nombre d'examens générés. Un tirage aléatoire se juge sur la répétition. */
    private static final int EXAMENS = 20;

    @Autowired
    private CivicExamCompositionService service;

    @Autowired
    private JdbcTemplate jdbc;

    @Test
    @DisplayName("🛑 20 examens générés : TOUS conformes, par thématique ET par unité")
    void vingtExamensTousConformes() {
        Map<String, String> uniteParQuestion = uniteParQuestion();
        Map<String, Integer> quotaParUnite = service.unitesParCode().values().stream()
                .collect(Collectors.toMap(CivicOfficialUnit::getCode,
                        u -> (int) u.getExamQuota()));
        Map<String, Integer> quotaParTheme = service.repartitionParThematique();

        for (int n = 1; n <= EXAMENS; n++) {
            List<Question> examen = service.composerExamenConforme();
            String ou = " (examen n° " + n + " sur " + EXAMENS + ")";

            // --- 1. Le compte total
            assertThat(examen).as("40 questions" + ou).hasSize(CivicExamFormat.QUESTIONS);

            // --- 2. Aucun doublon : un candidat ne voit jamais deux fois la même
            assertThat(examen.stream().map(Question::getId).distinct().count())
                    .as("aucun doublon intra-examen" + ou).isEqualTo(CivicExamFormat.QUESTIONS);

            // --- 3. La répartition par THÉMATIQUE : 11 / 6 / 11 / 8 / 4
            // 🛑 GROUPÉ PAR LA THÉMATIQUE DE L'UNITÉ, PAS PAR `questions.theme_id`
            // (D-47). 22 questions ont un `theme_id` qui contredit l'annexe I :
            // l'égalité, les libertés de la DDHC et la République comme régime sont
            // rangées sous « Principes » par notre taxonomie éditoriale, et sous
            // « Droits fondamentaux » / « Démocratie et droit de vote » par
            // l'arrêté. Grouper par `theme_id` donnait 13 questions de Principes
            // pour 11 attendues — et c'est notre classement qui a tort, pas le
            // tirage : il vient du corpus, comme les 46 notions qu'on a déjà
            // écartées comme autorité.
            Map<String, Long> parTheme = examen.stream().collect(Collectors.groupingBy(
                    service::thematiqueOfficielle, Collectors.counting()));
            assertThat(parTheme)
                    .as("répartition par thématique, dérivée des quotas d'unité" + ou)
                    .containsOnlyKeys(quotaParTheme.keySet());
            quotaParTheme.forEach((theme, attendu) -> assertThat(parTheme.get(theme))
                    .as("thématique %s : %d questions attendues%s", theme, attendu, ou)
                    .isEqualTo(attendu.longValue()));

            // --- 4. La répartition par UNITÉ OFFICIELLE — le cœur de l'arrêté
            Map<String, Integer> parUnite = new HashMap<>();
            for (Question q : examen) {
                String code = uniteParQuestion.get(q.getId().toString());
                assertThat(code)
                        .as("chaque question tirée relève d'une unité officielle" + ou)
                        .isNotNull();
                parUnite.merge(code, 1, Integer::sum);
            }
            assertThat(parUnite)
                    .as("les 16 unités sont toutes servies" + ou)
                    .containsOnlyKeys(quotaParUnite.keySet());
            quotaParUnite.forEach((code, attendu) -> assertThat(parUnite.get(code))
                    .as("unité %s : quota officiel %d%s", code, attendu, ou)
                    .isEqualTo(attendu));

            // --- 5. Les 12 mises en situation, et leur PLACEMENT
            List<Question> mes = examen.stream()
                    .filter(q -> q.getQuestionType() == QuestionType.MISE_SITUATION).toList();
            assertThat(mes)
                    .as("%d mises en situation%s", CivicExamFormat.MISES_EN_SITUATION, ou)
                    .hasSize(CivicExamFormat.MISES_EN_SITUATION);

            // Pour une mise en situation, la thématique officielle EST son
            // `theme_id` : elle ne porte pas de notion, son unité se rejoint par
            // le thème. Les deux lectures coïncident donc ici, et c'est voulu.
            Map<String, Long> mesParTheme = mes.stream().collect(Collectors.groupingBy(
                    service::thematiqueOfficielle, Collectors.counting()));
            // 🛑 6 en Principes, 6 en Droits et devoirs, AUCUNE ailleurs. C'est
            // l'axe sur lequel le produit était le plus loin : 58 % des mises en
            // situation tirées l'étaient dans les trois thématiques interdites.
            assertThat(mesParTheme)
                    .as("les mises en situation ne vivent que dans deux thématiques" + ou)
                    .containsOnlyKeys("CIV_PRINCIPES", "CIV_DROITS_DEVOIRS");
            assertThat(mesParTheme.get("CIV_PRINCIPES")).as("6 en Principes" + ou).isEqualTo(6L);
            assertThat(mesParTheme.get("CIV_DROITS_DEVOIRS"))
                    .as("6 en Droits et devoirs" + ou).isEqualTo(6L);

            // --- 6. Les 28 connaissances, par complément
            assertThat(examen.size() - mes.size())
                    .as("%d connaissances%s", CivicExamFormat.CONNAISSANCES, ou)
                    .isEqualTo(CivicExamFormat.CONNAISSANCES);
        }
    }

    @Test
    @DisplayName("Deux examens consécutifs ne sont pas identiques — le tirage varie dans l'unité")
    void leTirageVarie() {
        // Un tirage conforme mais figé rendrait l'examen blanc inutile au 2ᵉ
        // passage. La conformité borne les QUOTAS, pas les questions.
        List<String> a = service.composerExamenConforme().stream()
                .map(q -> q.getId().toString()).sorted().toList();
        List<String> b = service.composerExamenConforme().stream()
                .map(q -> q.getId().toString()).sorted().toList();
        assertThat(a).isNotEqualTo(b);
    }

    @Test
    @DisplayName("🛑 Le tirage ÉCHOUE bruyamment si une unité ne peut pas fournir son quota")
    void echoueBruyammentPlutotQueDeSeDegrader() {
        // On vide « Laïcité », l'unité la plus fragile du référentiel (9 questions).
        jdbc.update("""
                UPDATE questions SET is_active = false
                WHERE civic_notion_id IN (
                    SELECT n.id FROM civic_notions n JOIN civic_official_units u
                      ON u.id = n.official_unit_id
                    WHERE u.code = 'P2_LAICITE')
                """);

        // 🛑 D-29 exigence 3 : il lève, il ne rend pas un examen de 38 questions
        // ni un examen complété hors règles. C'est le défaut le plus grave de
        // l'audit, et c'est ce test qui le tient.
        assertThatThrownBy(() -> service.composerExamenConforme())
                .hasMessageContaining("P2_LAICITE")
                .hasMessageContaining("exige 2")
                .hasMessageContaining("arrete du 10 octobre 2025");
    }

    @Test
    @DisplayName("Les totaux par thématique sont DÉRIVÉS : 11 / 6 / 11 / 8 / 4")
    void lesTotauxSontDerives() {
        // 🛑 Ces cinq nombres ne sont déclarés nulle part (D-38). Cette assertion
        // et celle du seed IT sont les deux seuls endroits du dépôt qui les
        // écrivent, et les deux les comparent à une SOMME.
        assertThat(service.repartitionParThematique())
                .containsEntry("CIV_PRINCIPES", 11)
                .containsEntry("CIV_INSTITUTIONS", 6)
                .containsEntry("CIV_DROITS_DEVOIRS", 11)
                .containsEntry("CIV_HISTOIRE_GEO", 8)
                .containsEntry("CIV_SOCIETE", 4);
        assertThat(service.repartitionParThematique().values().stream()
                .mapToInt(Integer::intValue).sum()).isEqualTo(CivicExamFormat.QUESTIONS);
    }

    @Test
    @DisplayName("Aucun filtre de mention : les trois mentions sont représentées sur 20 examens")
    void aucunFiltreDeMention() {
        // 🛑 L'arrêté pose UN programme pour TOUTES les mentions (D-42). Si un
        // filtre revenait, une seule valeur de `difficulty` sortirait.
        var mentions = IntStream.rangeClosed(1, EXAMENS)
                .boxed()
                .flatMap(n -> service.composerExamenConforme().stream())
                .map(q -> q.getDifficulty().name())
                .collect(Collectors.toSet());
        assertThat(mentions).containsExactlyInAnyOrder("CSP", "CR", "NAT");
    }

    @Test
    @DisplayName("🛑 L'examen de thème respecte les proportions officielles internes (D-31, D-47)")
    void examenDeThemeAuxProportionsOfficielles() {
        // « Principes » vaut 3 + 2 + 6 = 11 au programme ; sur 20 questions, les
        // plus forts restes donnent 5 / 4 / 11. Les mises en situation y sont donc
        // MAJORITAIRES — c'est la structure de l'arrêté, pas un choix produit.
        for (String theme : List.of("CIV_PRINCIPES", "CIV_INSTITUTIONS",
                "CIV_DROITS_DEVOIRS", "CIV_HISTOIRE_GEO", "CIV_SOCIETE")) {
            List<Question> examen = service.composerExamenDeTheme(theme);

            assertThat(examen)
                    .as("%d questions sur le thème %s", CivicExamFormat.QUESTIONS_THEME, theme)
                    .hasSize(CivicExamFormat.QUESTIONS_THEME);

            // 🛑 TOUTES du thème visé, au sens de l'UNITÉ (D-47). Tirer par
            // `theme_id` ramenait des questions rangées ailleurs par l'arrêté.
            assertThat(examen).extracting(service::thematiqueOfficielle)
                    .as("toutes les questions relèvent de la thématique %s", theme)
                    .containsOnly(theme);

            // 🛑 Des mises en situation SEULEMENT là où l'examen réel en pose.
            long mes = examen.stream()
                    .filter(q -> q.getQuestionType() == QuestionType.MISE_SITUATION).count();
            boolean autorisees = theme.equals("CIV_PRINCIPES")
                    || theme.equals("CIV_DROITS_DEVOIRS");
            if (autorisees) {
                assertThat(mes).as("%s en porte, au prorata de son quota de 6", theme)
                        .isPositive();
            } else {
                assertThat(mes)
                        .as("🛑 %s n'en porte AUCUNE : l'arrêté n'en place pas dans cette "
                                + "thématique", theme)
                        .isZero();
            }
        }
    }

    /** L'unité officielle de chaque question civique active, par son id. */
    private Map<String, String> uniteParQuestion() {
        Map<String, String> m = new HashMap<>();
        jdbc.query("""
                SELECT q.id::text AS qid, u.code AS ucode
                FROM questions q
                JOIN civic_notions n ON n.id = q.civic_notion_id
                JOIN civic_official_units u ON u.id = n.official_unit_id
                WHERE q.module = 'CIVIQUE' AND q.is_active AND q.status = 'ACTIVE'
                UNION ALL
                SELECT q.id::text, u.code
                FROM questions q
                JOIN themes t ON t.id = q.theme_id
                JOIN civic_official_units u
                  ON u.theme_code = t.code AND u.question_type = 'MISE_SITUATION'
                WHERE q.module = 'CIVIQUE' AND q.is_active AND q.status = 'ACTIVE'
                  AND q.question_type = 'MISE_SITUATION'
                """, rs -> { m.put(rs.getString("qid"), rs.getString("ucode")); });
        return m;
    }
}
