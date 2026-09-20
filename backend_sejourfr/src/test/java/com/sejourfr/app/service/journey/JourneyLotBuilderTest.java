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
            new TcfJourneyConfig(3, 3, JourneyLotSelectionStrategy.TOP_SEVERITY, 2, null, 0.80,
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

    private static Skill comprehension(SkillSection section, String code) {
        Skill skill = new Skill();
        skill.setId(UUID.randomUUID());
        skill.setSection(section);
        skill.setCode(code);
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
