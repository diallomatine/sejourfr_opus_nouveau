package com.sejourfr.app.service;

import com.sejourfr.app.config.LearningPlanProperties;
import com.sejourfr.app.dto.PlanCycleDto;
import com.sejourfr.app.dto.PlanDomainDto;
import com.sejourfr.app.dto.PlanPathStepDto;
import com.sejourfr.app.dto.TcfLevelProfile;
import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.PlanCycleState;
import com.sejourfr.app.enums.PlanDomainPriority;
import com.sejourfr.app.enums.PlanPathStepKind;
import com.sejourfr.app.enums.PlanPathStepStatus;
import com.sejourfr.app.enums.SkillMasteryState;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.manager.LearningPlanObservationManager;
import com.sejourfr.app.manager.SkillManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.ArrayList;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * Le cycle de palier et les quatre domaines : ce que le Plan repond a « ou j'en
 * suis » et « ou je vais ».
 *
 * <p>Trois invariants y sont particulierement surveilles, parce qu'ils ont deja
 * ete casses ailleurs dans ce depot :
 * <ol>
 *   <li>un domaine <b>non evalue</b> n'est jamais une faiblesse — c'est le
 *       principe {@code null = inconnu, jamais mauvais} ;</li>
 *   <li>le cycle vise le <b>cran au-dessus</b>, pas l'objectif directement ;</li>
 *   <li>l'objectif suit la <b>demarche</b> du candidat, jamais une constante.</li>
 * </ol>
 */
class PlanCycleResolverTest {

    private TcfProfileService profileService;
    private SkillManager skillManager;
    private PlanCycleResolver resolver;
    private final UUID userId = UUID.randomUUID();
    private final Map<SkillSection, Map<TargetLevel, Skill>> comprehension =
            new EnumMap<>(SkillSection.class);

    @BeforeEach
    void setUp() {
        profileService = mock(TcfProfileService.class);
        skillManager = mock(SkillManager.class);
        LearningPlanProperties properties = new LearningPlanProperties();
        SkillMasteryResolver masteryResolver = new SkillMasteryResolver(
                mock(LearningPlanObservationManager.class),
                new SkillMasteryEngine(properties), properties);
        resolver = new PlanCycleResolver(profileService, new ComprehensionLevelResolver(),
                masteryResolver, skillManager);

        List<Skill> competences = new ArrayList<>();
        for (SkillSection section : List.of(SkillSection.CO, SkillSection.CE)) {
            for (TargetLevel palier : List.of(TargetLevel.A2, TargetLevel.B1, TargetLevel.B2)) {
                Skill skill = comprehensionSkill(section, palier);
                comprehension.computeIfAbsent(section, key -> new EnumMap<>(TargetLevel.class))
                        .put(palier, skill);
                competences.add(skill);
            }
        }
        when(skillManager.findActiveComprehension()).thenReturn(competences);
        // Le referentiel d'EXPRESSION est desormais lu ligne par ligne : les
        // comptes par tache s'en derivent, et c'est ce meme lot qui servira la
        // liste des competences de chaque epreuve. Une requete, pas deux.
        List<Skill> taches = new ArrayList<>();
        for (SkillTaskCode code : SkillTaskCode.values()) {
            for (int rang = 1; rang <= 8; rang++) {
                taches.add(expression(code.name() + "-C" + rang));
            }
        }
        when(skillManager.findActiveExpression()).thenReturn(taches);
    }

    // ------------------------------------------------------------------------
    // Les quatre domaines
    // ------------------------------------------------------------------------

    @Test
    @DisplayName("Les quatre domaines sont TOUJOURS servis, l'ordre est decide par le serveur")
    void lesQuatreDomainesSontToujoursLa() {
        profil(null, null, null, null);

        PlanCycleResolver.Resolution resolution = resolve(nat(), List.of(), List.of());

        assertThat(resolution.domaines()).extracting(PlanDomainDto::epreuve)
                .containsExactly(EpreuveType.TCF_CO, EpreuveType.TCF_CE,
                        EpreuveType.TCF_EO, EpreuveType.TCF_EE);
        assertThat(resolution.domaines()).allSatisfy(domaine -> {
            assertThat(domaine.evaluated()).isFalse();
            assertThat(domaine.niveau()).isNull();
            assertThat(domaine.priority()).isEqualTo(PlanDomainPriority.A_EVALUER);
        });
    }

    /**
     * Le piege que le brief nomme explicitement (§96) : une absence de donnee ne
     * se lit pas comme un mauvais resultat. Elle ne descend pas non plus le
     * niveau global — le plancher ne porte que sur les domaines mesures.
     */
    @Test
    @DisplayName("Un domaine non evalue ne devient jamais une fausse faiblesse")
    void unDomaineNonEvalueNestPasUneFaiblesse() {
        profil(null, NiveauCecrl.B1, NiveauCecrl.B1, NiveauCecrl.B1);

        PlanCycleResolver.Resolution resolution = resolve(nat(), List.of(), List.of());

        PlanDomainDto co = domaine(resolution, EpreuveType.TCF_CO);
        assertThat(co.evaluated()).isFalse();
        assertThat(co.niveau()).isNull();
        assertThat(co.priority()).isEqualTo(PlanDomainPriority.A_EVALUER);
        // Le niveau de depart reste celui des domaines mesures.
        assertThat(resolution.cycle().startingLevel()).isEqualTo(NiveauCecrl.B1);
        assertThat(resolution.cycle().profileComplete()).isFalse();
        assertThat(resolution.cycle().domainsEvaluated()).isEqualTo(3);
        assertThat(resolution.cycle().domainsExpected()).isEqualTo(4);
    }

    @Test
    @DisplayName("Les cinq valeurs de priorite de domaine se distinguent")
    void lesCinqValeursDePriorite() {
        // CO A2 (sous le palier vise), CE B2 (objectif atteint), EE B1 (deja
        // au-dessus du palier vise), EO A2 et porteuse de la priorite n°1.
        profil(NiveauCecrl.A2, NiveauCecrl.B2, NiveauCecrl.B1, NiveauCecrl.A2);
        LearningPlanObservation prioriteUn = observation(expression("EO1-C3"),
                LearningPlanSkillStatus.PRIORITY, LearningPlanSourceType.PRODUCTION_EO,
                UUID.randomUUID(), Instant.now());

        PlanCycleResolver.Resolution resolution =
                resolve(nat(), List.of(prioriteUn), List.of(prioriteUn));

        assertThat(resolution.cycle().targetLevel()).isEqualTo(TargetLevel.B1);
        assertThat(domaine(resolution, EpreuveType.TCF_EO).priority())
                .isEqualTo(PlanDomainPriority.FORTE);
        assertThat(domaine(resolution, EpreuveType.TCF_CO).priority())
                .isEqualTo(PlanDomainPriority.A_TRAVAILLER);
        assertThat(domaine(resolution, EpreuveType.TCF_CE).priority())
                .isEqualTo(PlanDomainPriority.ENTRETIEN);
        assertThat(domaine(resolution, EpreuveType.TCF_EE).priority())
                .isEqualTo(PlanDomainPriority.PAS_ENCORE_PRIORITAIRE);

        // Et l'ordre servi est celui de l'urgence, decide serveur.
        assertThat(resolution.domaines()).extracting(PlanDomainDto::priority)
                .containsExactly(PlanDomainPriority.FORTE, PlanDomainPriority.A_TRAVAILLER,
                        PlanDomainPriority.ENTRETIEN, PlanDomainPriority.PAS_ENCORE_PRIORITAIRE);

        profil(null, NiveauCecrl.B2, NiveauCecrl.B1, NiveauCecrl.A2);
        assertThat(domaine(resolve(nat(), List.of(), List.of()), EpreuveType.TCF_CO).priority())
                .isEqualTo(PlanDomainPriority.A_EVALUER);
    }

    @Test
    @DisplayName("Un domaine de comprehension porte ses trois paliers et celui qui bloque")
    void lesPaliersDeComprehension() {
        profil(NiveauCecrl.A2, null, null, null);
        List<LearningPlanObservation> historique = new ArrayList<>();
        solide(historique, comprehension.get(SkillSection.CO).get(TargetLevel.A2),
                LearningPlanSourceType.TCF_CO);

        PlanDomainDto co = domaine(resolve(nat(), historique, List.of()), EpreuveType.TCF_CO);

        assertThat(co.paliers()).extracting(palier -> palier.niveau())
                .containsExactly(TargetLevel.A2, TargetLevel.B1, TargetLevel.B2);
        assertThat(co.paliers().getFirst().masteryState()).isEqualTo(SkillMasteryState.SOLID);
        assertThat(co.paliers().getFirst().blocking()).isFalse();
        // Jamais observe : aucun etat invente, et c'est LUI qui bloque.
        assertThat(co.paliers().get(1).masteryState()).isNull();
        assertThat(co.paliers().get(1).blocking()).isTrue();
        assertThat(co.paliers().get(2).blocking()).isFalse();
        assertThat(co.consolidatedLevel()).isEqualTo(TargetLevel.A2);
        assertThat(co.blockingLevel()).isEqualTo(TargetLevel.B1);
        assertThat(co.taches()).isEmpty();
    }

    @Test
    @DisplayName("Un domaine d'expression porte ses trois taches et leur couverture")
    void lesTachesDExpression() {
        profil(null, null, NiveauCecrl.A2, null);
        List<LearningPlanObservation> historique = new ArrayList<>();
        historique.add(observation(expression("EE2-C1"), LearningPlanSkillStatus.TO_REINFORCE,
                LearningPlanSourceType.PRODUCTION_EE, UUID.randomUUID(), Instant.now()));
        historique.add(observation(expression("EE2-C5"), LearningPlanSkillStatus.SOLID,
                LearningPlanSourceType.PRODUCTION_EE, UUID.randomUUID(), Instant.now()));

        PlanDomainDto ee = domaine(resolve(nat(), historique, List.of()), EpreuveType.TCF_EE);

        assertThat(ee.taches()).extracting(tache -> tache.taskCode())
                .containsExactly(SkillTaskCode.EE1, SkillTaskCode.EE2, SkillTaskCode.EE3);
        assertThat(ee.taches().get(1).observedSkills()).isEqualTo(2);
        assertThat(ee.taches().get(1).totalSkills()).isEqualTo(8);
        assertThat(ee.taches().getFirst().observedSkills()).isZero();
        assertThat(ee.paliers()).isEmpty();
        assertThat(ee.consolidatedLevel()).isNull();
    }

    // ------------------------------------------------------------------------
    // Le cycle
    // ------------------------------------------------------------------------

    @Test
    @DisplayName("Depuis A2 avec un objectif B2, le cycle vise B1 — jamais B2 directement")
    void leCycleViseLeCranAuDessus() {
        profil(NiveauCecrl.A2, NiveauCecrl.A2, NiveauCecrl.A2, NiveauCecrl.A2);

        PlanCycleDto cycle = resolve(nat(), List.of(), List.of()).cycle();

        assertThat(cycle.startingLevel()).isEqualTo(NiveauCecrl.A2);
        assertThat(cycle.objectiveLevel()).isEqualTo(TargetLevel.B2);
        assertThat(cycle.targetLevel()).isEqualTo(TargetLevel.B1);
    }

    /**
     * L'objectif n'est pas « B2 » en dur : il vient de la demarche, qui fait
     * plancher ({@code TargetProcedure.niveauVise}). Cette table a vecu en six
     * copies divergentes dans ce depot — elle n'en aura pas une septieme ici.
     */
    @Test
    @DisplayName("L'objectif suit la demarche du candidat : NAT vise B2, CSP vise A2")
    void lObjectifSuitLaDemarche() {
        profil(NiveauCecrl.A1, NiveauCecrl.A1, NiveauCecrl.A1, NiveauCecrl.A1);

        assertThat(resolve(nat(), List.of(), List.of()).cycle().objectiveLevel())
                .isEqualTo(TargetLevel.B2);
        assertThat(resolve(user(TargetProcedure.CSP, null), List.of(), List.of())
                .cycle().objectiveLevel()).isEqualTo(TargetLevel.A2);
        assertThat(resolve(user(TargetProcedure.CR, null), List.of(), List.of())
                .cycle().objectiveLevel()).isEqualTo(TargetLevel.B1);
        // Le plancher de la demarche l'emporte sur un palier declare plus bas.
        assertThat(resolve(user(TargetProcedure.NAT, TargetLevel.B1), List.of(), List.of())
                .cycle().objectiveLevel()).isEqualTo(TargetLevel.B2);
        // Ni demarche ni palier : on ne devine pas a la place du candidat.
        assertThat(resolve(user(null, null), List.of(), List.of()).cycle().objectiveLevel())
                .isNull();
    }

    @Test
    @DisplayName("Le palier vise ne depasse jamais l'objectif")
    void lePalierVisePlafonneALObjectif() {
        profil(NiveauCecrl.A2, NiveauCecrl.A2, NiveauCecrl.A2, NiveauCecrl.A2);

        PlanCycleDto cycle = resolve(user(TargetProcedure.CSP, null), List.of(), List.of()).cycle();

        assertThat(cycle.targetLevel()).isEqualTo(TargetLevel.A2);
        assertThat(cycle.state()).isEqualTo(PlanCycleState.TARGET_STABILIZATION);
    }

    @Test
    @DisplayName("Le chemin garde les paliers acquis, coches, et n'a qu'une seule etape en cours")
    void leCheminNaQuUneEtapeCourante() {
        profil(NiveauCecrl.A2, NiveauCecrl.A2, NiveauCecrl.A2, NiveauCecrl.A2);

        List<PlanPathStepDto> chemin = resolve(nat(), List.of(), List.of()).cycle().path();

        assertThat(chemin).extracting(PlanPathStepDto::kind).containsExactly(
                PlanPathStepKind.COMPLETE_PROFILE, PlanPathStepKind.BUILD_LEVEL,
                PlanPathStepKind.BUILD_LEVEL, PlanPathStepKind.BUILD_LEVEL,
                PlanPathStepKind.STABILIZE);
        assertThat(chemin).filteredOn(etape -> etape.status() == PlanPathStepStatus.CURRENT)
                .singleElement()
                .satisfies(etape -> assertThat(etape.level()).isEqualTo(TargetLevel.B1));
        assertThat(chemin.get(1).status()).isEqualTo(PlanPathStepStatus.DONE);
        assertThat(chemin.get(3).status()).isEqualTo(PlanPathStepStatus.UPCOMING);
    }

    @Test
    @DisplayName("Profil incomplet : c'est COMPLETER LE PROFIL qui est en cours, pas un palier")
    void leProfilIncompletPasseAvantTout() {
        profil(null, NiveauCecrl.A2, NiveauCecrl.A2, NiveauCecrl.A2);

        PlanCycleDto cycle = resolve(nat(), List.of(), List.of()).cycle();

        assertThat(cycle.state()).isEqualTo(PlanCycleState.BUILDING_BASELINE);
        assertThat(cycle.path()).filteredOn(etape -> etape.status() == PlanPathStepStatus.CURRENT)
                .singleElement()
                .satisfies(etape ->
                        assertThat(etape.kind()).isEqualTo(PlanPathStepKind.COMPLETE_PROFILE));
    }

    // ------------------------------------------------------------------------
    // Le gate de palier
    // ------------------------------------------------------------------------

    /**
     * Brief §77 : un profil a 3/4 ne declenche pas d'examen de palier, meme si
     * tout ce qui est connu est solide. On ne confirme pas un palier sur un
     * domaine qu'on n'a jamais mesure.
     */
    @Test
    @DisplayName("A 3 domaines sur 4, le gate ne se declenche pas — meme sans aucune priorite")
    void leGateNeSeDeclenchePasSurUnProfilIncomplet() {
        profil(null, NiveauCecrl.A2, NiveauCecrl.A2, NiveauCecrl.A2);

        PlanCycleDto cycle = resolve(nat(), List.of(), List.of()).cycle();

        assertThat(cycle.state()).isEqualTo(PlanCycleState.BUILDING_BASELINE);
        assertThat(cycle.state()).isNotEqualTo(PlanCycleState.READY_FOR_GATE_MOCK);
    }

    @Test
    @DisplayName("A 4 sur 4 et sans priorite restante, le Plan reclame l'examen de palier")
    void leGateSeDeclencheQuandLeTravailDuPalierEstFait() {
        profil(NiveauCecrl.A2, NiveauCecrl.A2, NiveauCecrl.A2, NiveauCecrl.A2);

        PlanCycleDto cycle = resolve(nat(), List.of(), List.of()).cycle();

        assertThat(cycle.profileComplete()).isTrue();
        assertThat(cycle.targetLevel()).isEqualTo(TargetLevel.B1);
        assertThat(cycle.state()).isEqualTo(PlanCycleState.READY_FOR_GATE_MOCK);
    }

    @Test
    @DisplayName("Une seule priorite restante suffit a refermer le gate")
    void unePrioriteRestanteReferme() {
        profil(NiveauCecrl.A2, NiveauCecrl.A2, NiveauCecrl.A2, NiveauCecrl.A2);
        LearningPlanObservation priorite = observation(expression("EE3-C2"),
                LearningPlanSkillStatus.TO_REINFORCE, LearningPlanSourceType.PRODUCTION_EE,
                UUID.randomUUID(), Instant.now());

        PlanCycleDto cycle = resolve(nat(), List.of(priorite), List.of(priorite)).cycle();

        assertThat(cycle.state()).isEqualTo(PlanCycleState.TRAINING);
    }

    @Test
    @DisplayName("Objectif atteint : plus de gate, on stabilise")
    void objectifAtteintOnStabilise() {
        profil(NiveauCecrl.B2, NiveauCecrl.B2, NiveauCecrl.B2, NiveauCecrl.B2);

        PlanCycleDto cycle = resolve(nat(), List.of(), List.of()).cycle();

        assertThat(cycle.state()).isEqualTo(PlanCycleState.TARGET_STABILIZATION);
        assertThat(cycle.path().getLast().status()).isEqualTo(PlanPathStepStatus.CURRENT);
    }

    // ------------------------------------------------------------------------
    // Fabriques
    // ------------------------------------------------------------------------

    private PlanCycleResolver.Resolution resolve(
            User user, List<LearningPlanObservation> historique,
            List<LearningPlanObservation> actionable) {
        return resolver.resolve(user, historique, actionable);
    }

    private void profil(NiveauCecrl co, NiveauCecrl ce, NiveauCecrl ee, NiveauCecrl eo) {
        NiveauCecrl global = null;
        for (NiveauCecrl niveau : new NiveauCecrl[]{co, ce, ee, eo}) {
            if (niveau == null) continue;
            if (global == null || niveau.ordinal() < global.ordinal()) global = niveau;
        }
        when(profileService.levelProfile(userId))
                .thenReturn(new TcfLevelProfile(co, ce, ee, eo, global));
    }

    private static PlanDomainDto domaine(
            PlanCycleResolver.Resolution resolution, EpreuveType epreuve) {
        return resolution.domaines().stream()
                .filter(item -> item.epreuve() == epreuve)
                .findFirst()
                .orElseThrow();
    }

    /** Deux preuves contextualisees sur des sujets differents : de quoi etre solide. */
    private static void solide(
            List<LearningPlanObservation> historique, Skill skill, LearningPlanSourceType source) {
        historique.add(observation(skill, LearningPlanSkillStatus.SOLID, source,
                UUID.randomUUID(), Instant.now()));
        historique.add(observation(skill, LearningPlanSkillStatus.SOLID, source,
                UUID.randomUUID(), Instant.now().minusSeconds(86_400)));
    }

    private User nat() {
        return user(TargetProcedure.NAT, null);
    }

    private User user(TargetProcedure procedure, TargetLevel declare) {
        User user = new User();
        user.setId(userId);
        user.setTargetProcedure(procedure);
        user.setTargetLevel(declare);
        return user;
    }

    private static Skill comprehensionSkill(SkillSection section, TargetLevel palier) {
        Skill skill = new Skill();
        skill.setId(UUID.randomUUID());
        skill.setSection(section);
        skill.setTargetLevel(palier.name());
        skill.setCode(section.name() + "-" + palier.name());
        skill.setTitle("Compétence " + skill.getCode());
        return skill;
    }

    private static Skill expression(String code) {
        Skill skill = new Skill();
        skill.setId(UUID.randomUUID());
        skill.setCode(code);
        skill.setTitle("Compétence " + code);
        skill.setTaskCode(SkillTaskCode.valueOf(code.substring(0, 3)));
        skill.setSection(skill.getTaskCode().getSection());
        return skill;
    }

    private static LearningPlanObservation observation(
            Skill skill, LearningPlanSkillStatus status, LearningPlanSourceType source,
            UUID subjectId, Instant at) {
        LearningPlanObservation observation = new LearningPlanObservation();
        observation.setId(UUID.randomUUID());
        observation.setSkill(skill);
        observation.setObserved(true);
        observation.setStatus(status);
        observation.setSourceType(source);
        observation.setSubjectId(subjectId);
        observation.setEvidence("Preuve");
        observation.setConfidence(ObservationConfidence.HIGH);
        observation.setObservedAt(at);
        return observation;
    }
}
