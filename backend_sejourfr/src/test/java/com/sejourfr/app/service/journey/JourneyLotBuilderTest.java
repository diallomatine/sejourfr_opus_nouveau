package com.sejourfr.app.service.journey;

import com.sejourfr.app.dto.TcfLevelProfile;
import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.JourneyLotSelectionStrategy;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.enums.TargetLevel;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * <b>Ce qu'une evaluation retient, et dans quel ordre ses lots entrent dans la
 * file</b> — R2 et R10 bis.
 *
 * <p>Test unitaire : aucune base, aucune requete. Ce qui est verrouille ici,
 * c'est de la <b>regle pure</b>, et elle doit pouvoir etre relue sans monter un
 * contexte Spring.
 */
class JourneyLotBuilderTest {

    private static final Instant T0 = Instant.parse("2026-09-17T10:00:00Z");

    private final JourneyLotBuilder builder = new JourneyLotBuilder(
            new TcfJourneyConfig(4, 3, JourneyLotSelectionStrategy.TOP_SEVERITY, 2, null, null, 3,
                    new TcfJourneyConfig.Display(3, 5)));

    // ------------------------------------------------------------------ R2

    @Test
    @DisplayName("§18-3 — six priorites EE : seules les TROIS plus graves entrent")
    void seulesLesTroisPlusGravesEntrent() {
        UUID evaluation = UUID.randomUUID();
        List<LearningPlanObservation> observations = new ArrayList<>();
        for (int i = 1; i <= 6; i++) {
            observations.add(observation(evaluation, skill(SkillTaskCode.EE1, "EE1-C" + i),
                    // Les trois premieres sont PRIORITY, les suivantes seulement
                    // TO_REINFORCE : l'ordre de gravite doit les departager.
                    i <= 3 ? LearningPlanSkillStatus.PRIORITY
                            : LearningPlanSkillStatus.TO_REINFORCE,
                    ObservationConfidence.HIGH, T0));
        }

        List<JourneyLotBuilder.Lot> lots = builder.depuisEvaluation(
                sources(evaluation), observations, Set.of(), TargetLevel.B2, profil(null, null, null, null));

        assertThat(lots).hasSize(1);
        assertThat(lots.getFirst().priorites()).hasSize(3);
        assertThat(lots.getFirst().priorites().stream().map(p -> p.skill().getCode()))
                .containsExactly("EE1-C1", "EE1-C2", "EE1-C3");
        // Le rang est celui du LOT, pas un score : 0, 1, 2.
        assertThat(lots.getFirst().priorites().stream().map(JourneyLotBuilder.Priorite::rang))
                .containsExactly(0, 1, 2);
    }

    @Test
    @DisplayName("L'ordre de gravite est celui du Plan : statut, puis confiance, puis recence")
    void lOrdreDeGraviteEstCeluiDuPlan() {
        UUID evaluation = UUID.randomUUID();
        List<LearningPlanObservation> observations = List.of(
                observation(evaluation, skill(SkillTaskCode.EE1, "EE1-C9"),
                        LearningPlanSkillStatus.TO_REINFORCE, ObservationConfidence.HIGH, T0),
                observation(evaluation, skill(SkillTaskCode.EE1, "EE1-C2"),
                        LearningPlanSkillStatus.PRIORITY, ObservationConfidence.LOW, T0),
                observation(evaluation, skill(SkillTaskCode.EE1, "EE1-C5"),
                        LearningPlanSkillStatus.PRIORITY, ObservationConfidence.HIGH, T0));

        List<JourneyLotBuilder.Lot> lots = builder.depuisEvaluation(
                sources(evaluation), observations, Set.of(), TargetLevel.B2, profil(null, null, null, null));

        // PRIORITY passe devant TO_REINFORCE, et a statut egal la confiance la
        // mieux etablie d'abord. C'est exactement la regle de
        // LearningPlanPriorityResolver.actionable(), reproduite et non reinventee.
        assertThat(lots.getFirst().priorites().stream().map(p -> p.skill().getCode()))
                .containsExactly("EE1-C5", "EE1-C2", "EE1-C9");
    }

    @Test
    @DisplayName("SOLID et NOT_OBSERVED ne deviennent jamais une priorite")
    void seulesLesFragilitesEntrent() {
        UUID evaluation = UUID.randomUUID();
        List<LearningPlanObservation> observations = List.of(
                observation(evaluation, skill(SkillTaskCode.EE1, "EE1-C1"),
                        LearningPlanSkillStatus.SOLID, ObservationConfidence.HIGH, T0),
                observation(evaluation, skill(SkillTaskCode.EE1, "EE1-C2"),
                        LearningPlanSkillStatus.NOT_OBSERVED, ObservationConfidence.LOW, T0));

        // 🛑 « Le correcteur n'a rien pu observer » veut dire INCONNU, jamais
        // faible : c'est la confusion qui a produit les faux A1_NON_ATTEINT de
        // V040/V041/V042. Zero fragilite ⇒ zero lot, et c'est legitime (R9).
        assertThat(builder.depuisEvaluation(sources(evaluation), observations, Set.of(),
                TargetLevel.B2, profil(null, null, null, null))).isEmpty();
    }

    @Test
    @DisplayName("§18-26 — une competence deja maitrisee aujourd'hui n'entre pas")
    void uneCompetenceMaitriseeNEntrePas() {
        UUID evaluation = UUID.randomUUID();
        Skill maitrisee = skill(SkillTaskCode.EE1, "EE1-C1");
        Skill fragile = skill(SkillTaskCode.EE1, "EE1-C2");
        List<LearningPlanObservation> observations = List.of(
                observation(evaluation, maitrisee, LearningPlanSkillStatus.PRIORITY,
                        ObservationConfidence.HIGH, T0),
                observation(evaluation, fragile, LearningPlanSkillStatus.PRIORITY,
                        ObservationConfidence.HIGH, T0));

        List<JourneyLotBuilder.Lot> lots = builder.depuisEvaluation(sources(evaluation), observations,
                Set.of(maitrisee.getId()), TargetLevel.B2, profil(null, null, null, null));

        // Redemander ce qui est acquis ferait tourner le parcours en rond.
        assertThat(lots.getFirst().priorites()).hasSize(1);
        assertThat(lots.getFirst().priorites().getFirst().skill().getCode()).isEqualTo("EE1-C2");
    }

    @Test
    @DisplayName("R13 — la meme competence observee deux fois ne compte qu'une")
    void laMemeCompetenceNeCompteQuUneFois() {
        UUID evaluation = UUID.randomUUID();
        Skill skill = skill(SkillTaskCode.EE1, "EE1-C1");
        List<LearningPlanObservation> observations = List.of(
                observation(evaluation, skill, LearningPlanSkillStatus.PRIORITY,
                        ObservationConfidence.HIGH, T0),
                observation(evaluation, skill, LearningPlanSkillStatus.PRIORITY,
                        ObservationConfidence.MEDIUM, T0.minusSeconds(10)));

        assertThat(builder.depuisEvaluation(sources(evaluation), observations, Set.of(),
                TargetLevel.B2, profil(null, null, null, null))
                .getFirst().priorites()).hasSize(1);
    }

    // -------------------------------------------------------------- R10 bis

    @Test
    @DisplayName("§18-14 — les lots sont ordonnes par ecart au niveau cible decroissant")
    void lesLotsSontOrdonnesParEcartDecroissant() {
        UUID evaluation = UUID.randomUUID();
        List<LearningPlanObservation> observations = List.of(
                observation(evaluation, comprehension(SkillSection.CO, "CO-B1"),
                        LearningPlanSkillStatus.PRIORITY, ObservationConfidence.HIGH, T0),
                observation(evaluation, skill(SkillTaskCode.EE1, "EE1-C1"),
                        LearningPlanSkillStatus.PRIORITY, ObservationConfidence.HIGH, T0),
                observation(evaluation, skill(SkillTaskCode.EO1, "EO1-C1"),
                        LearningPlanSkillStatus.PRIORITY, ObservationConfidence.HIGH, T0));

        // Objectif B2. EE est a A2 (deux crans de retard), EO a B1 (un cran),
        // CO deja a B2 (aucun).
        List<JourneyLotBuilder.Lot> lots = builder.depuisEvaluation(
                sources(evaluation), observations, Set.of(), TargetLevel.B2,
                profil(NiveauCecrl.B2, null, NiveauCecrl.A2, NiveauCecrl.B1));

        assertThat(lots.stream().map(JourneyLotBuilder.Lot::epreuve))
                .containsExactly(EpreuveType.TCF_EE, EpreuveType.TCF_EO, EpreuveType.TCF_CO);
    }

    @Test
    @DisplayName("§18-38 — a ecart egal, l'ordre est celui des epreuves du TCF : CO, CE, EO, EE")
    void aEcartEgalLOrdreEstCeluiDesEpreuves() {
        UUID evaluation = UUID.randomUUID();
        List<LearningPlanObservation> observations = List.of(
                observation(evaluation, skill(SkillTaskCode.EE1, "EE1-C1"),
                        LearningPlanSkillStatus.PRIORITY, ObservationConfidence.HIGH, T0),
                observation(evaluation, skill(SkillTaskCode.EO1, "EO1-C1"),
                        LearningPlanSkillStatus.PRIORITY, ObservationConfidence.HIGH, T0),
                observation(evaluation, comprehension(SkillSection.CE, "CE-B1"),
                        LearningPlanSkillStatus.PRIORITY, ObservationConfidence.HIGH, T0),
                observation(evaluation, comprehension(SkillSection.CO, "CO-B1"),
                        LearningPlanSkillStatus.PRIORITY, ObservationConfidence.HIGH, T0));

        List<JourneyLotBuilder.Lot> lots = builder.depuisEvaluation(
                sources(evaluation), observations, Set.of(), TargetLevel.B1,
                profil(NiveauCecrl.A2, NiveauCecrl.A2, NiveauCecrl.A2, NiveauCecrl.A2));

        // 🛑 CO, CE, EO, EE — l'ordre EXISTANT (TcfDomainProfileDto.ORDRE,
        // arbitrage D-9), pas celui que la premiere redaction de la spec
        // proposait (EE avant EO).
        assertThat(lots.stream().map(JourneyLotBuilder.Lot::epreuve)).containsExactly(
                EpreuveType.TCF_CO, EpreuveType.TCF_CE, EpreuveType.TCF_EO, EpreuveType.TCF_EE);
    }

    @Test
    @DisplayName("Un ecart INCONNU passe apres les ecarts connus, jamais devant")
    void unEcartInconnuPasseApres() {
        UUID evaluation = UUID.randomUUID();
        List<LearningPlanObservation> observations = List.of(
                observation(evaluation, comprehension(SkillSection.CO, "CO-B1"),
                        LearningPlanSkillStatus.PRIORITY, ObservationConfidence.HIGH, T0),
                observation(evaluation, skill(SkillTaskCode.EE1, "EE1-C1"),
                        LearningPlanSkillStatus.PRIORITY, ObservationConfidence.HIGH, T0));

        // CO n'a jamais ete mesuree (null), EE est a B1 sous un objectif B2.
        List<JourneyLotBuilder.Lot> lots = builder.depuisEvaluation(
                sources(evaluation), observations, Set.of(), TargetLevel.B2,
                profil(null, null, NiveauCecrl.B1, null));

        // 🛑 « Pas de mesure » ne devient pas « urgence maximale » : ce serait la
        // confusion « null = mauvais » que le depot a deja payee.
        assertThat(lots.stream().map(JourneyLotBuilder.Lot::epreuve))
                .containsExactly(EpreuveType.TCF_EE, EpreuveType.TCF_CO);
    }

    @Test
    @DisplayName("Le bootstrap ne retient qu'une evaluation de reference par epreuve")
    void leBootstrapNeRetientQueLesReferences() {
        UUID recente = UUID.randomUUID();
        UUID ancienne = UUID.randomUUID();
        List<LearningPlanObservation> observations = List.of(
                observation(recente, skill(SkillTaskCode.EE1, "EE1-C1"),
                        LearningPlanSkillStatus.PRIORITY, ObservationConfidence.HIGH, T0),
                observation(ancienne, skill(SkillTaskCode.EE1, "EE1-C9"),
                        LearningPlanSkillStatus.PRIORITY, ObservationConfidence.HIGH,
                        T0.minusSeconds(86400)));

        List<JourneyLotBuilder.Lot> lots = builder.depuisHistorique(
                Map.of(EpreuveType.TCF_EE, sources(recente)), observations, Set.of(), TargetLevel.B2,
                profil(null, null, NiveauCecrl.A2, null));

        // R19.2 : une seule evaluation de reference par epreuve — la plus
        // recente qui mesure. L'ancienne ne repeuple pas le lot.
        assertThat(lots).hasSize(1);
        assertThat(lots.getFirst().priorites().stream().map(p -> p.skill().getCode()))
                .containsExactly("EE1-C1");
    }

    // ------------------------------------------------------------- fabriques

    /**
     * Une evaluation et les {@code source_id} de ses observations.
     *
     * <p>🛑 Ici les deux se confondent, et c'est <b>volontaire</b> : ce test
     * verrouille la regle pure du constructeur de lots, pas la jointure. Dans
     * la vraie vie elles divergent des qu'il s'agit d'une production — une
     * observation EE/EO est clavetee sur sa <b>soumission</b>, l'evaluation sur
     * son <b>attempt</b> —, et c'est {@link JourneyObservationSources} qui fait
     * le lien, seul et pour tout le monde.
     */
    // ------------------------------------------------------------- D-70

    @Test
    @DisplayName("D-72 — CO a A1 sous un objectif B2 : le SEUL palier A2 (D-70 posait A2, B1, B2)")
    void unDomaineSousLObjectifRecoitSonSeulPalier() {
        List<Skill> referentiel = referentielComprehension();
        UUID examen = UUID.randomUUID();

        JourneyLotBuilder.Lot lot = builder.versLObjectif(EpreuveType.TCF_CO, examen,
                NiveauCecrl.A1, TargetLevel.B2, referentiel, Set.of());

        assertThat(lot.epreuve()).isEqualTo(EpreuveType.TCF_CO);
        assertThat(lot.sourceAssessmentId()).isEqualTo(examen);
        assertThat(lot.priorites().stream().map(p -> p.skill().getCode()))
                .containsExactly("CO-A2");
    }

    @Test
    @DisplayName("D-72 — le palier suit le niveau mesure : A2 ⇒ B1, B1 ⇒ B2, A1 non atteint ⇒ A2")
    void lePalierSuitLeNiveauMesure() {
        List<Skill> referentiel = referentielComprehension();

        assertThat(codes(builder.versLObjectif(EpreuveType.TCF_CE, UUID.randomUUID(),
                NiveauCecrl.A2, TargetLevel.B2, referentiel, Set.of())))
                .containsExactly("CE-B1");
        assertThat(codes(builder.versLObjectif(EpreuveType.TCF_CE, UUID.randomUUID(),
                NiveauCecrl.B1, TargetLevel.B2, referentiel, Set.of())))
                .containsExactly("CE-B2");
        assertThat(codes(builder.versLObjectif(EpreuveType.TCF_CE, UUID.randomUUID(),
                NiveauCecrl.A1_NON_ATTEINT, TargetLevel.B2, referentiel, Set.of())))
                .containsExactly("CE-A2");
        // L'objectif plafonne : A2 vise B1 ⇒ B1.
        assertThat(codes(builder.versLObjectif(EpreuveType.TCF_CE, UUID.randomUUID(),
                NiveauCecrl.A2, TargetLevel.B1, referentiel, Set.of())))
                .containsExactly("CE-B1");
    }

    @Test
    @DisplayName("D-72 — le palier prouve aujourd'hui ne fait PAS sauter au suivant : examen seul")
    void unPalierProuveNeFaitPasSauterAuSuivant() {
        List<Skill> referentiel = referentielComprehension();
        Skill ceA2 = referentiel.stream().filter(s -> s.getCode().equals("CE-A2")).findFirst()
                .orElseThrow();

        assertThat(builder.versLObjectif(EpreuveType.TCF_CE, UUID.randomUUID(),
                NiveauCecrl.A1, TargetLevel.B2, referentiel, Set.of(ceA2.getId()))).isNull();
    }

    @Test
    @DisplayName("D-72 — budget D-67 tenu A L'INTERIEUR du palier : quatre competences A2, trois retenues")
    void leBudgetD67SeDepenseDansLePalier() {
        List<Skill> referentiel = new ArrayList<>(referentielComprehension());
        for (int i = 2; i <= 4; i++) {
            Skill autre = comprehension(SkillSection.CO, "CO-A2-" + i);
            autre.setTargetLevel("A2");
            referentiel.add(autre);
        }

        JourneyLotBuilder.Lot lot = builder.versLObjectif(EpreuveType.TCF_CO, UUID.randomUUID(),
                NiveauCecrl.A1, TargetLevel.B2, referentiel, Set.of());

        assertThat(lot.priorites()).hasSize(3)
                .allSatisfy(p -> assertThat(p.skill().getTargetLevel()).isEqualTo("A2"));
    }

    @Test
    @DisplayName("D-70 — rien a proposer : objectif atteint, niveau INCONNU, expression")
    void rienAProposerDonneNull() {
        List<Skill> referentiel = referentielComprehension();
        assertThat(builder.versLObjectif(EpreuveType.TCF_CO, UUID.randomUUID(),
                NiveauCecrl.B2, TargetLevel.B2, referentiel, Set.of())).isNull();
        // 🛑 null = inconnu, jamais « A1 » : aucun palier n'est fabrique.
        assertThat(builder.versLObjectif(EpreuveType.TCF_CO, UUID.randomUUID(),
                null, TargetLevel.B2, referentiel, Set.of())).isNull();
        assertThat(builder.versLObjectif(EpreuveType.TCF_EE, UUID.randomUUID(),
                NiveauCecrl.A1, TargetLevel.B2, referentiel, Set.of())).isNull();
    }

    // ----------------------------------------------- D-72 — lot d'une evaluation

    @Test
    @DisplayName("D-72 — examen CE a A1, fragilites A2/B1/B2 : le lot ne retient que l'A2")
    void lExamenDeComprehensionNeRetientQueLePalierDuCycle() {
        UUID evaluation = UUID.randomUUID();
        List<LearningPlanObservation> observations = new ArrayList<>();
        for (Skill skill : referentielComprehension()) {
            if (skill.getSection() != SkillSection.CE) continue;
            observations.add(observation(evaluation, skill, LearningPlanSkillStatus.PRIORITY,
                    ObservationConfidence.HIGH, T0));
        }

        List<JourneyLotBuilder.Lot> lots = builder.depuisEvaluation(sources(evaluation),
                observations, Set.of(), TargetLevel.B2, profil(null, NiveauCecrl.A1, null, null));

        assertThat(lots).hasSize(1);
        assertThat(codes(lots.getFirst())).containsExactly("CE-A2");
    }

    @Test
    @DisplayName("D-72 — aucune fragilite AU palier : pas de lot (D-70 completera le bloc)")
    void sansFragiliteAuPalierPasDeLot() {
        UUID evaluation = UUID.randomUUID();
        Skill coB2 = comprehension(SkillSection.CO, "CO-B2");
        coB2.setTargetLevel("B2");

        assertThat(builder.depuisEvaluation(sources(evaluation),
                List.of(observation(evaluation, coB2, LearningPlanSkillStatus.PRIORITY,
                        ObservationConfidence.HIGH, T0)),
                Set.of(), TargetLevel.B2, profil(NiveauCecrl.A2, null, null, null))).isEmpty();
    }

    @Test
    @DisplayName("D-72 — niveau INCONNU ou objectif ATTEINT, et expression : composition inchangee")
    void horsDuPerimetreLaCompositionEstInchangee() {
        UUID evaluation = UUID.randomUUID();
        List<LearningPlanObservation> observations = new ArrayList<>();
        for (Skill skill : referentielComprehension()) {
            if (skill.getSection() != SkillSection.CO) continue;
            observations.add(observation(evaluation, skill, LearningPlanSkillStatus.PRIORITY,
                    ObservationConfidence.HIGH, T0));
        }
        for (int i = 1; i <= 3; i++) {
            observations.add(observation(evaluation, skill(SkillTaskCode.EE1, "EE1-C" + i),
                    LearningPlanSkillStatus.PRIORITY, ObservationConfidence.HIGH, T0));
        }

        // 🛑 null = inconnu, jamais le plus bas : les trois paliers restent.
        assertThat(lot(builder.depuisEvaluation(sources(evaluation), observations, Set.of(),
                TargetLevel.B2, profil(null, null, NiveauCecrl.A1, null)), EpreuveType.TCF_CO)
                .priorites()).hasSize(3);
        // Objectif atteint : rien ne change non plus.
        assertThat(lot(builder.depuisEvaluation(sources(evaluation), observations, Set.of(),
                TargetLevel.B1, profil(NiveauCecrl.B1, null, NiveauCecrl.A1, null)),
                EpreuveType.TCF_CO).priorites()).hasSize(3);
        // L'expression n'est jamais filtree, meme a A1 sous B2.
        assertThat(lot(builder.depuisEvaluation(sources(evaluation), observations, Set.of(),
                TargetLevel.B2, profil(NiveauCecrl.A1, null, NiveauCecrl.A1, null)),
                EpreuveType.TCF_EE).priorites()).hasSize(3);
    }

    @Test
    @DisplayName("D-72 — le palier du cycle : CO/CE seulement, null si inconnu ou atteint")
    void lePalierDuCycle() {
        TcfLevelProfile profil = profil(NiveauCecrl.A1, NiveauCecrl.B1, NiveauCecrl.A1, null);
        assertThat(JourneyLotBuilder.palierDuCycle(EpreuveType.TCF_CO, profil, TargetLevel.B2))
                .isEqualTo(TargetLevel.A2);
        assertThat(JourneyLotBuilder.palierDuCycle(EpreuveType.TCF_CE, profil, TargetLevel.B2))
                .isEqualTo(TargetLevel.B2);
        assertThat(JourneyLotBuilder.palierDuCycle(EpreuveType.TCF_CE, profil, TargetLevel.B1))
                .isNull();
        assertThat(JourneyLotBuilder.palierDuCycle(EpreuveType.TCF_EE, profil, TargetLevel.B2))
                .isNull();
        assertThat(JourneyLotBuilder.palierDuCycle(EpreuveType.TCF_CO,
                profil(null, null, null, null), TargetLevel.B2)).isNull();
    }

    @Test
    @DisplayName("🔴 AR-3 — à égalité parfaite, le lot suit le rang éditorial, pas le code ni l'ordre d'écriture")
    void aEgaliteLeLotSuitLeRangEditorial() {
        UUID evaluation = UUID.randomUUID();
        // Ecrites dans le desordre editorial, toutes au MEME instant (une
        // production = un instant), et des codes qui contrediraient le rang.
        List<LearningPlanObservation> observations = List.of(
                observation(evaluation, skill(SkillTaskCode.EE1, "EE1-C8", 8),
                        LearningPlanSkillStatus.TO_REINFORCE, ObservationConfidence.MEDIUM, T0),
                observation(evaluation, skill(SkillTaskCode.EE3, "EE3-C2", 2),
                        LearningPlanSkillStatus.TO_REINFORCE, ObservationConfidence.MEDIUM, T0),
                observation(evaluation, skill(SkillTaskCode.EE2, "EE2-C7", 7),
                        LearningPlanSkillStatus.TO_REINFORCE, ObservationConfidence.MEDIUM, T0),
                observation(evaluation, skill(SkillTaskCode.EE1, "EE1-C7", 5),
                        LearningPlanSkillStatus.TO_REINFORCE, ObservationConfidence.MEDIUM, T0));

        List<JourneyLotBuilder.Lot> lots = builder.depuisEvaluation(
                sources(evaluation), observations, Set.of(), TargetLevel.B2, profil(null, null, null, null));

        assertThat(lots.getFirst().priorites().stream().map(p -> p.skill().getCode()))
                .containsExactly("EE3-C2", "EE1-C7", "EE2-C7");
    }

    private static List<String> codes(JourneyLotBuilder.Lot lot) {
        return lot.priorites().stream().map(p -> p.skill().getCode()).toList();
    }

    private static JourneyLotBuilder.Lot lot(List<JourneyLotBuilder.Lot> lots, EpreuveType epreuve) {
        return lots.stream().filter(l -> l.epreuve() == epreuve).findFirst().orElseThrow();
    }

    private static Skill skill(SkillTaskCode taskCode, String code, int rang) {
        Skill skill = skill(taskCode, code);
        skill.setDisplayOrder((short) rang);
        return skill;
    }

    private static List<Skill> referentielComprehension() {
        List<Skill> referentiel = new ArrayList<>();
        for (SkillSection section : List.of(SkillSection.CO, SkillSection.CE)) {
            for (String palier : List.of("B2", "A2", "B1")) {
                Skill skill = comprehension(section, section.name() + "-" + palier);
                skill.setTargetLevel(palier);
                referentiel.add(skill);
            }
        }
        return referentiel;
    }

    private static JourneyObservationSources.Sources sources(UUID evaluation) {
        return new JourneyObservationSources.Sources(evaluation, Set.of(evaluation));
    }

    private static TcfLevelProfile profil(
            NiveauCecrl co, NiveauCecrl ce, NiveauCecrl ee, NiveauCecrl eo) {
        return new TcfLevelProfile(co, ce, ee, eo, null);
    }

    private static Skill skill(SkillTaskCode taskCode, String code) {
        Skill skill = new Skill();
        skill.setId(UUID.randomUUID());
        skill.setSection(taskCode.getSection());
        skill.setTaskCode(taskCode);
        skill.setCode(code);
        skill.setTitle("Competence " + code);
        return skill;
    }

    /** Une competence de comprehension ; son palier se lit sur le code (« CO-B1 » ⇒ B1). */
    private static Skill comprehension(SkillSection section, String code) {
        Skill skill = new Skill();
        skill.setId(UUID.randomUUID());
        skill.setSection(section);
        skill.setCode(code);
        String[] parts = code.split("-");
        if (parts.length > 1 && List.of("A2", "B1", "B2").contains(parts[1])) {
            skill.setTargetLevel(parts[1]);
        }
        skill.setTitle("Competence " + code);
        return skill;
    }

    private static LearningPlanObservation observation(
            UUID sourceId, Skill skill, LearningPlanSkillStatus status,
            ObservationConfidence confidence, Instant observedAt) {
        LearningPlanObservation observation = new LearningPlanObservation();
        observation.setSkill(skill);
        observation.setSourceId(sourceId);
        observation.setStatus(status);
        observation.setConfidence(confidence);
        observation.setObserved(status != LearningPlanSkillStatus.NOT_OBSERVED);
        observation.setObservedAt(observedAt);
        return observation;
    }
}
