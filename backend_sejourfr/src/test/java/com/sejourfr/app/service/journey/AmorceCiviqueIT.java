package com.sejourfr.app.service.journey;

import com.sejourfr.app.dto.CivicPlanDto;
import com.sejourfr.app.entity.CivicDiagnosticSession;
import com.sejourfr.app.entity.Journey;
import com.sejourfr.app.entity.JourneyStep;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.JourneyStepPurpose;
import com.sejourfr.app.enums.JourneyStepType;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.manager.CivicNotionManager;
import com.sejourfr.app.manager.JourneyStepManager;
import com.sejourfr.app.service.AccountDeletionService;
import com.sejourfr.app.service.CivicObservationService;
import com.sejourfr.app.service.diagnosticcivique.CivicDiagnosticService;
import com.sejourfr.app.service.plancivique.CivicPlanService;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * <b>L'amorce d'un cycle civique</b> — spec §2, transposée sans écart.
 *
 * <h2>🛑 Un cycle civique n'est JAMAIS vide (A60 est fermée ici)</h2>
 * <p>Depuis le point 2, un cycle civique naissait sans une seule étape. C'était
 * un <b>état de transition</b>, pas un comportement : une ligne muette qui a
 * l'air d'un cycle sans en être un. Le pire cas est désormais <b>cinq examens à
 * passer</b>.
 *
 * <h2>🛑 L'ordre est LU, jamais recalculé</h2>
 * <p>D-36 : le cycle se superpose au plan dérivé. Les priorités arrivent de
 * {@link CivicPlanService#ordrePourLeCycle}, qui rend les cibles
 * <b>proposables</b> — sans le plafond d'affichage de trois.
 *
 * <p>⚠️ Ces tests <b>ne sont pas transactionnels</b>, pour la même raison que
 * {@code JourneyServiceIT} : {@code JourneyService} écrit en
 * {@code REQUIRES_NEW}, et une transaction de test qui l'envelopperait
 * suspendrait la sienne — le service ne verrait rien de ce que le test vient
 * d'écrire.
 */
@Transactional(propagation = Propagation.NOT_SUPPORTED)
class AmorceCiviqueIT extends AbstractIntegrationTest {

    @Autowired private JourneyService journeyService;
    @Autowired private CivicPlanService civicPlanService;
    @Autowired private CivicDiagnosticService diagnosticService;
    @Autowired private CivicNotionManager notionManager;
    @Autowired private JourneyStepManager stepManager;
    @Autowired private AccountDeletionService accountDeletionService;
    @Autowired private TestData data;
    @Autowired private EntityManager entityManager;
    @Autowired private JdbcTemplate jdbc;
    @Autowired private CivicObservationService observationService;
    @Autowired private TcfJourneyConfig config;

    private final List<UUID> candidats = new ArrayList<>();

    @AfterEach
    void menage() {
        candidats.forEach(id -> accountDeletionService.deleteAccount(id));
        candidats.clear();
    }

    // ------------------------------------------------------------------------
    // Amorce C — rien de fait
    // ------------------------------------------------------------------------

    @Test
    @DisplayName("Aucun diagnostic : les CINQ thematiques passent en « Évaluer mon niveau »")
    void sansDiagnosticLesCinqThematiquesSontAEvaluer() {
        User user = candidatCivique();

        Journey cycle = journeyService
                .getOrCreate(user.getId(), Module.CIVIQUE).orElseThrow();
        List<Etape> etapes = etapes(cycle);

        // 🛑 A60 EST FERMEE : le pire cas est cinq examens, pas un cycle vide.
        assertThat(etapes).hasSize(5);
        assertThat(etapes).allSatisfy(etape -> {
            assertThat(etape.type()).isEqualTo("SECTION_EXAM");
            // « Évaluer mon niveau » : cette thematique n'a jamais ete mesuree.
            assertThat(etape.purpose()).isEqualTo("INITIAL_ASSESSMENT");
            assertThat(etape.lotId()).isNull();
            assertThat(etape.unite()).isNull();
            assertThat(etape.thematique()).startsWith("CIV_");
        });
        // Les cinq thematiques de l'arrete, chacune une fois.
        assertThat(etapes.stream().map(Etape::thematique).distinct()).hasSize(5);
    }

    // ------------------------------------------------------------------------
    // Amorce A — diagnostic fait
    // ------------------------------------------------------------------------

    @Test
    @DisplayName("Diagnostic fait : les thematiques prioritaires sont PEUPLEES d'unites officielles")
    void avecDiagnosticLesThematiquesPrioritairesSontPeuplees() {
        User user = candidatCivique();
        diagnosticTermine(user);

        Journey cycle = journeyService
                .getOrCreate(user.getId(), Module.CIVIQUE).orElseThrow();
        List<Etape> etapes = etapes(cycle);

        List<Etape> travail = etapes.stream()
                .filter(e -> e.type().equals("TRAIN_SKILL"))
                .toList();
        assertThat(travail).as("le diagnostic a produit des priorites").isNotEmpty();

        // 🛑 LE GRAIN EST L'UNITE OFFICIELLE (D-48), jamais la notion : une
        // etape civique porte `official_unit_id` et AUCUN `skill_id`.
        assertThat(travail).allSatisfy(etape -> {
            assertThat(etape.unite()).isNotNull();
            assertThat(etape.skillId()).isNull();
            assertThat(etape.lotId()).isNotNull();
            assertThat(etape.thematique()).startsWith("CIV_");
        });

        // D-20 — au plus TROIS priorites par lot, la meme borne que cote TCF.
        Map<UUID, Long> parLot = travail.stream().collect(
                Collectors.groupingBy(Etape::lotId, Collectors.counting()));
        assertThat(parLot.values()).allSatisfy(n -> assertThat(n).isLessThanOrEqualTo(3L));

        // R3 — chaque lot est clos par l'examen de SON bloc.
        for (UUID lot : parLot.keySet()) {
            List<Etape> examens = etapes.stream()
                    .filter(e -> e.type().equals("SECTION_EXAM"))
                    .filter(e -> lot.equals(e.lotId()))
                    .toList();
            assertThat(examens).hasSize(1);
            assertThat(examens.getFirst().purpose()).isEqualTo("REASSESS");
        }

        // 🛑 LES CINQ THEMATIQUES SONT COUVERTES : celles que rien ne peuple
        // passent en « Évaluer mon niveau ». Le cycle porte TOUT le programme de
        // l'arrete, pas seulement ce que le diagnostic a pointe.
        assertThat(etapes.stream().map(Etape::thematique).distinct()).hasSize(5);
    }

    @Test
    @DisplayName("🛑 L'ordre vient du PLAN DERIVE : le cycle ne reclasse rien (D-36)")
    void lOrdreVientDuPlanDerive() {
        User user = candidatCivique();
        diagnosticTermine(user);

        CivicPlanService.OrdreDuPlan ordre = civicPlanService.ordrePourLeCycle(user.getId());
        assertThat(ordre.estVide()).isFalse();

        // L'unite de la PREMIERE cible proposable du plan derive. Lue en SQL :
        // `CivicNotion.officialUnit` est paresseux, et ce test n'est pas
        // transactionnel (le service ecrit en REQUIRES_NEW).
        String attendue = ordre.cibles().stream()
                .map(CivicPlanDto.Cible::id)
                .map(this::uniteDeLaNotion)
                .filter(java.util.Objects::nonNull)
                .findFirst()
                .orElse(null);
        assertThat(attendue).as("au moins une cible se rattache a une unite").isNotNull();

        Journey cycle = journeyService
                .getOrCreate(user.getId(), Module.CIVIQUE).orElseThrow();
        Etape premiere = etapes(cycle).stream()
                .filter(e -> e.type().equals("TRAIN_SKILL"))
                .findFirst()
                .orElseThrow();

        // 🛑 Le cycle N'A PAS son propre ordre. S'il en avait un, cette egalite
        // ne tiendrait que par coincidence -- et c'est exactement ce que
        // l'arbitrage interdit : lire l'ordre existant, ne pas en creer un
        // second au motif qu'il serait meilleur.
        assertThat(premiere.unite()).isEqualTo(attendue);
    }

    // ------------------------------------------------------------------------
    // Point 6 — R2 au grain de l'unite, et la cloture qui en decoule
    // ------------------------------------------------------------------------

    @Test
    @DisplayName("R2 — une unite se clot sur le quota de series REUSSIES, lu chez son autorite")
    void uneUniteSeClotSurSonQuota() {
        User user = candidatCivique();
        diagnosticTermine(user);
        Journey cycle = journeyService
                .getOrCreate(user.getId(), Module.CIVIQUE).orElseThrow();

        Etape aTravailler = etapes(cycle).stream()
                .filter(e -> e.type().equals("TRAIN_SKILL"))
                .findFirst()
                .orElseThrow();
        UUID unite = uniteParCode(aTravailler.unite());

        // Autant de series REUSSIES que le quota en demande -- lu chez son
        // autorite, jamais ecrit ici : si D-16 rebouge, ce test suit.
        for (int i = 0; i < config.trainSeriesQuota(); i++) {
            observationService.record(user.getId(), UUID.randomUUID(),
                    LearningPlanSourceType.CIVIQUE_SERIE, Instant.now(),
                    reussite(unite));
        }
        journeyService.onTrainingProgressCivique(user.getId(), Set.of(unite));

        // 🛑 La MEME fonction que celle qui affiche l'avancement
        // (`etapesAuQuota`) : une etape ne se clot jamais sur une regle
        // differente de celle qui l'a calculee.
        // ⚠️ Un statut d'etape ne se PERSISTE pas : la base porte la date de
        // cloture et son MOTIF, le statut se derive a la lecture.
        Map<String, Object> close = jdbc.queryForMap("""
                SELECT closed_at, resolution FROM journey_step
                WHERE journey_id = ? AND official_unit_id = ?
                """, cycle.getId(), unite);
        assertThat(close.get("closed_at")).isNotNull();
        assertThat(close.get("resolution")).isEqualTo("QUOTA_REACHED");
    }

    @Test
    @DisplayName("Une seule serie reussie ne clot rien : le quota n'est pas atteint")
    void uneSerieNeSuffitPas() {
        User user = candidatCivique();
        diagnosticTermine(user);
        Journey cycle = journeyService
                .getOrCreate(user.getId(), Module.CIVIQUE).orElseThrow();
        Etape aTravailler = etapes(cycle).stream()
                .filter(e -> e.type().equals("TRAIN_SKILL"))
                .findFirst()
                .orElseThrow();
        UUID unite = uniteParCode(aTravailler.unite());

        observationService.record(user.getId(), UUID.randomUUID(),
                LearningPlanSourceType.CIVIQUE_SERIE, Instant.now(), reussite(unite));
        journeyService.onTrainingProgressCivique(user.getId(), Set.of(unite));

        assertThat(jdbc.queryForObject("""
                SELECT count(*) FROM journey_step
                WHERE journey_id = ? AND official_unit_id = ? AND closed_at IS NULL
                """, Integer.class, cycle.getId(), unite))
                .as("l'etape reste ouverte tant que le quota n'est pas atteint")
                .isEqualTo(1);
    }

    private List<CivicObservationService.ReponseCivique> reussite(UUID unite) {
        return java.util.stream.IntStream.range(0, 10)
                .mapToObj(i -> new CivicObservationService.ReponseCivique(unite, true, true))
                .toList();
    }

    private UUID uniteParCode(String code) {
        return jdbc.queryForObject(
                "SELECT id FROM civic_official_units WHERE code = ?", UUID.class, code);
    }

    // ------------------------------------------------------------------------
    // Point 7 — R1 : l'examen clot ce qui etait DEBLOQUE, et le journal le dit
    // ------------------------------------------------------------------------

    @Test
    @DisplayName("R1 — l'examen COMPLET clot les cinq blocs debloques, et ecrit SIX lignes")
    void lExamenCompletClotLesBlocsDebloques() {
        // Sans diagnostic : les cinq blocs ne portent QUE leur examen, tous
        // debloques -- c'est exactement la forme du cycle de mesure.
        User user = candidatCivique();
        Journey cycle = journeyService
                .getOrCreate(user.getId(), Module.CIVIQUE).orElseThrow();
        UUID examen = UUID.randomUUID();

        journeyService.onAssessmentCompleted(user.getId(),
                JourneyEvaluation.examenCivique(examen, Instant.now()));

        // 🛑 PASSEE, PAS REUSSIE : aucune note n'entre ici. L'examen mesure.
        assertThat(etapes(cycle)).allSatisfy(etape ->
                assertThat(etape.closedAt()).isNotNull());
        assertThat(jdbc.queryForObject("""
                SELECT count(*) FROM journey_step
                WHERE journey_id = ? AND resolution = 'SATISFIED_BY_ASSESSMENT'
                """, Integer.class, cycle.getId())).isEqualTo(5);

        // SIX lignes pour UN attempt : une globale sans axe, cinq par
        // thematique (D-51).
        assertThat(jdbc.queryForObject("""
                SELECT count(*) FROM journey_assessment_event
                WHERE journey_id = ? AND source_assessment_id = ?
                """, Integer.class, cycle.getId(), examen)).isEqualTo(6);
        assertThat(jdbc.queryForObject("""
                SELECT count(*) FROM journey_assessment_event
                WHERE source_assessment_id = ? AND assessment_kind = 'CIVIC_EXAM'
                  AND theme_id IS NULL
                """, Integer.class, examen)).isEqualTo(1);
        assertThat(jdbc.queryForObject("""
                SELECT count(*) FROM journey_assessment_event
                WHERE source_assessment_id = ? AND assessment_kind = 'CIVIC_THEME_EXAM'
                  AND theme_id IS NOT NULL
                """, Integer.class, examen)).isEqualTo(5);
    }

    @Test
    @DisplayName("🛑 R1 / D-15 — un bloc qui a encore une unite due n'est PAS valide")
    void unBlocAvecUneUniteDueNEstPasValide() {
        User user = candidatCivique();
        diagnosticTermine(user);
        Journey cycle = journeyService
                .getOrCreate(user.getId(), Module.CIVIQUE).orElseThrow();

        String blocPeuple = etapes(cycle).stream()
                .filter(e -> e.type().equals("TRAIN_SKILL"))
                .map(Etape::thematique)
                .findFirst()
                .orElseThrow();
        UUID theme = jdbc.queryForObject(
                "SELECT id FROM themes WHERE code = ?", UUID.class, blocPeuple);

        journeyService.onAssessmentCompleted(user.getId(),
                JourneyEvaluation.examenDeTheme(UUID.randomUUID(), theme, Instant.now()));

        // L'examen est JOURNALISE -- il a bien eu lieu --, mais il ne valide
        // rien : une unite du bloc reste ouverte.
        assertThat(etapes(cycle)).filteredOn(e -> e.thematique().equals(blocPeuple))
                .allSatisfy(etape -> assertThat(etape.closedAt()).isNull());
    }

    @Test
    @DisplayName("R1 — un examen de theme clot SON bloc, et lui seul")
    void lExamenDeThemeClotSonBlocEtLuiSeul() {
        User user = candidatCivique();
        Journey cycle = journeyService
                .getOrCreate(user.getId(), Module.CIVIQUE).orElseThrow();
        Etape premier = etapes(cycle).getFirst();
        UUID theme = jdbc.queryForObject(
                "SELECT id FROM themes WHERE code = ?", UUID.class, premier.thematique());

        journeyService.onAssessmentCompleted(user.getId(),
                JourneyEvaluation.examenDeTheme(UUID.randomUUID(), theme, Instant.now()));

        List<Etape> apres = etapes(cycle);
        assertThat(apres).filteredOn(e -> e.thematique().equals(premier.thematique()))
                .allSatisfy(e -> assertThat(e.closedAt()).isNotNull());
        // Les quatre autres blocs n'ont pas bouge : un examen de theme ne
        // valide que SA thematique.
        assertThat(apres).filteredOn(e -> !e.thematique().equals(premier.thematique()))
                .allSatisfy(e -> assertThat(e.closedAt()).isNull());
    }

    // ------------------------------------------------------------------------

    /**
     * Une etape du cycle, <b>lue en base</b>.
     *
     * <p>⚠️ Ces tests ne sont pas transactionnels : une entite rendue par un
     * manager est <b>detachee</b>, et toucher son bloc ou son unite leve un
     * {@code LazyInitializationException}. On lit donc les colonnes.
     */
    private record Etape(String type, String purpose, UUID lotId, UUID skillId,
                         String thematique, String unite, java.sql.Timestamp closedAt) {}

    private List<Etape> etapes(Journey cycle) {
        return jdbc.query("""
                SELECT s.type, s.purpose, s.lot_id, s.skill_id, t.code AS theme_code,
                       u.code AS unite_code, s.closed_at
                FROM journey_step s
                LEFT JOIN themes t ON t.id = s.theme_id
                LEFT JOIN civic_official_units u ON u.id = s.official_unit_id
                WHERE s.journey_id = ?
                ORDER BY s.position
                """,
                (rs, i) -> new Etape(
                        rs.getString("type"), rs.getString("purpose"),
                        rs.getObject("lot_id", UUID.class),
                        rs.getObject("skill_id", UUID.class),
                        rs.getString("theme_code"), rs.getString("unite_code"),
                        rs.getTimestamp("closed_at")),
                cycle.getId());
    }

    private String uniteDeLaNotion(UUID notionId) {
        List<String> codes = jdbc.queryForList("""
                SELECT u.code FROM civic_notions n
                JOIN civic_official_units u ON u.id = n.official_unit_id
                WHERE n.id = ?
                """, String.class, notionId);
        return codes.isEmpty() ? null : codes.getFirst();
    }

    private User candidatCivique() {
        User user = data.user();
        candidats.add(user.getId());
        user.setTargetProcedure(TargetProcedure.NAT);
        user.setTargetLevel(TargetProcedure.NAT.getRequiredTcfLevel());
        return data.saveUser(user);
    }

    /** Ouvre un diagnostic civique, y repond faux partout, et le clot. */
    private CivicDiagnosticSession diagnosticTermine(User user) {
        CivicDiagnosticSession session = diagnosticService.ouvrir(user.getId());
        // On ecrit les reponses en SQL, comme `CivicPlanServiceIT` : ce test
        // porte sur l'AMORCE, faire jouer un runner entier n'ajouterait qu'un
        // point de rupture sans rien verrouiller de plus.
        for (UUID aq : jdbc.queryForList("""
                SELECT id FROM attempt_questions WHERE attempt_id = ? ORDER BY position
                """, UUID.class, session.getAttempt().getId())) {
            jdbc.update("""
                    INSERT INTO answers (id, attempt_question_id, user_id, selected_choice_ids,
                                         is_correct, answered_at)
                    SELECT gen_random_uuid(), ?, a.user_id, '[]'::jsonb, false, now()
                    FROM attempt_questions aq JOIN attempts a ON a.id = aq.attempt_id
                    WHERE aq.id = ?
                    """, aq, aq);
        }
        diagnosticService.cloturer(user.getId(), session.getId());
        entityManager.clear();
        return session;
    }
}
