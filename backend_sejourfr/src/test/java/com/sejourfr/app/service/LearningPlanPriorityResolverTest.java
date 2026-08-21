package com.sejourfr.app.service;

import com.sejourfr.app.config.LearningPlanProperties;
import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.SkillMasteryState;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.manager.LearningPlanObservationManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * L'<b>unique</b> autorite sur l'ordre et la selection des priorites du Plan.
 *
 * <p>Deux lecteurs en dependent — le Plan lui-meme et {@code SkillAccessService},
 * qui ouvre la competence de la priorite n&deg;1 a un compte gratuit —, donc ce
 * qui est verrouille ici l'est pour les deux.
 */
class LearningPlanPriorityResolverTest {

    private LearningPlanObservationManager observationManager;
    private SkillMasteryResolver masteryResolver;
    private LearningPlanPriorityResolver resolver;

    private final UUID userId = UUID.randomUUID();
    private final Instant maintenant = Instant.now();

    @BeforeEach
    void setUp() {
        observationManager = mock(LearningPlanObservationManager.class);
        // Le moteur de maitrise tourne POUR DE VRAI, sur les valeurs de
        // configuration par defaut : c'est LUI qui decide desormais qu'une
        // competence a prouve son transfert, et le doubler ici reviendrait a
        // tester une seconde definition — exactement le defaut corrige.
        LearningPlanProperties properties = new LearningPlanProperties();
        masteryResolver = new SkillMasteryResolver(
                observationManager, new SkillMasteryEngine(properties), properties);
        resolver = new LearningPlanPriorityResolver(observationManager, masteryResolver);
    }

    // ------------------------------------------------------------------------
    // Ordre : rien de ce qui existait ne bouge
    // ------------------------------------------------------------------------

    @Test
    void lOrdreResteStatutPuisConfiancePuisRecence() {
        Skill priorite = skill("EE1-C1");
        Skill sureMaisAncienne = skill("EE2-C2");
        Skill moinsSureEtRecente = skill("EO1-C3");
        Skill quatrieme = skill("EO3-C4");

        List<LearningPlanObservation> actionable = resolver.actionable(historique(
                observation(moinsSureEtRecente, LearningPlanSkillStatus.TO_REINFORCE,
                        LearningPlanSourceType.PRODUCTION_EO, ObservationConfidence.LOW, jours(1)),
                observation(priorite, LearningPlanSkillStatus.PRIORITY,
                        LearningPlanSourceType.PRODUCTION_EE, ObservationConfidence.LOW, jours(9)),
                observation(sureMaisAncienne, LearningPlanSkillStatus.TO_REINFORCE,
                        LearningPlanSourceType.PRODUCTION_EE, ObservationConfidence.HIGH, jours(5)),
                observation(quatrieme, LearningPlanSkillStatus.TO_REINFORCE,
                        LearningPlanSourceType.PRODUCTION_EE, ObservationConfidence.LOW, jours(20))));

        // Le plafond est passe de 3 a 5 le 2026-08-21 : les quatre fragilites
        // tiennent desormais toutes dans « Mes priorites ». Ce qui est verifie
        // ici, c'est l'ORDRE, et il n'a pas bouge d'un pouce.
        assertThat(actionable).hasSize(4);
        assertThat(actionable.size())
                .isLessThanOrEqualTo(LearningPlanPriorityResolver.MAX_PRIORITIES);
        assertThat(codes(actionable))
                .containsExactly("EE1-C1", "EE2-C2", "EO1-C3", "EO3-C4");
    }

    // ------------------------------------------------------------------------
    // « Une fois reussi, on passe a la competence suivante »
    // ------------------------------------------------------------------------

    /**
     * Le cas central : la verification en situation a reussi. La competence sort
     * des priorites, la suivante devient l'etape n&deg;1 — y compris pour le
     * verrou freemium, qui lit la meme methode.
     */
    @Test
    void uneReussiteEnSituationSortLaCompetenceDesPriorites() {
        Skill reussie = skill("EE1-C1");
        Skill suivante = skill("EE1-C2");
        List<LearningPlanObservation> historique = historique(
                observation(reussie, LearningPlanSkillStatus.SOLID,
                        LearningPlanSourceType.PRODUCTION_EE, ObservationConfidence.HIGH, jours(1)),
                observation(reussie, LearningPlanSkillStatus.PRIORITY,
                        LearningPlanSourceType.DIAGNOSTIC_EE, ObservationConfidence.HIGH, jours(30)),
                observation(suivante, LearningPlanSkillStatus.TO_REINFORCE,
                        LearningPlanSourceType.DIAGNOSTIC_EE, ObservationConfidence.HIGH, jours(30)));
        when(observationManager.findAllByUserWithSkill(userId)).thenReturn(historique);

        assertThat(codes(resolver.actionable(historique))).containsExactly("EE1-C2");
        assertThat(resolver.currentPrioritySkillId(userId))
                .contains(suivante.getId());
    }

    /**
     * Un examen blanc est aussi une production en situation : c'est meme la
     * preuve la moins assistee dont on dispose.
     */
    @Test
    void unExamenBlancProuveLeTransfertAuMemeTitreQuUneProduction() {
        Skill reussie = skill("EO2-C4");
        List<LearningPlanObservation> historique = historique(
                observation(reussie, LearningPlanSkillStatus.SOLID,
                        LearningPlanSourceType.MOCK_EXAM_EO, ObservationConfidence.MEDIUM, jours(2)),
                observation(reussie, LearningPlanSkillStatus.PRIORITY,
                        LearningPlanSourceType.DIAGNOSTIC_EO, ObservationConfidence.HIGH, jours(40)));

        assertThat(resolver.actionable(historique)).isEmpty();
    }

    /**
     * Un micro-exercice rate <b>apres</b> la preuve ne remet pas la competence en
     * tete : c'est exactement ce que corrige cette regle. Meme sens que
     * {@code SkillMasteryEngine}, ou seules les fragilites contextualisees
     * peuvent defaire un transfert deja prouve.
     */
    @Test
    void unMicroExerciceRateApresLaPreuveNeRamenePasLaCompetence() {
        Skill reussie = skill("EE3-C2");
        List<LearningPlanObservation> historique = historique(
                observation(reussie, LearningPlanSkillStatus.PRIORITY,
                        LearningPlanSourceType.SKILL_TRAINING, ObservationConfidence.MEDIUM,
                        jours(1)),
                observation(reussie, LearningPlanSkillStatus.SOLID,
                        LearningPlanSourceType.PRODUCTION_EE, ObservationConfidence.HIGH, jours(3)));

        assertThat(resolver.actionable(historique)).isEmpty();
    }

    /**
     * Un {@code SOLID} venu d'un <b>micro-entrainement</b> ne prouve aucun
     * transfert : l'exercice est guide vers cette seule competence.
     */
    @Test
    void unSolidDeMicroEntrainementNeSortPasLaCompetenceDesPriorites() {
        Skill skill = skill("EE1-C5");
        List<LearningPlanObservation> historique = historique(
                observation(skill, LearningPlanSkillStatus.PRIORITY,
                        LearningPlanSourceType.SKILL_TRAINING, ObservationConfidence.MEDIUM,
                        jours(1)),
                observation(skill, LearningPlanSkillStatus.SOLID,
                        LearningPlanSourceType.SKILL_TRAINING, ObservationConfidence.MEDIUM,
                        jours(4)));

        assertThat(codes(resolver.actionable(historique))).containsExactly("EE1-C5");
    }

    /** Le diagnostic est la <b>baseline</b> : il ne confirme jamais rien. */
    @Test
    void unSolidDeDiagnosticNeSortPasLaCompetenceDesPriorites() {
        Skill skill = skill("EO1-C6");
        List<LearningPlanObservation> historique = historique(
                observation(skill, LearningPlanSkillStatus.TO_REINFORCE,
                        LearningPlanSourceType.SKILL_TRAINING, ObservationConfidence.MEDIUM,
                        jours(2)),
                observation(skill, LearningPlanSkillStatus.SOLID,
                        LearningPlanSourceType.DIAGNOSTIC_EO, ObservationConfidence.HIGH, jours(30)));

        assertThat(codes(resolver.actionable(historique))).containsExactly("EO1-C6");
    }

    /**
     * <b>Rien n'est verrouille definitivement</b> : quand les fragilites en
     * situation depassent la tolerance du moteur ({@code fragility-tolerance},
     * 2), la competence revient parmi les priorites.
     *
     * <p>C'est la <b>meme</b> tolerance que celle qui protege {@code SOLID} : une
     * seule production moins bonne ne defait pas un transfert, deux si.
     */
    @Test
    void deuxEchecsEnSituationRamenentLaCompetenceParmiLesPriorites() {
        Skill skill = skill("EE2-C7");
        List<LearningPlanObservation> historique = historique(
                observation(skill, LearningPlanSkillStatus.PRIORITY,
                        LearningPlanSourceType.PRODUCTION_EO, ObservationConfidence.HIGH, jours(1)),
                observation(skill, LearningPlanSkillStatus.PRIORITY,
                        LearningPlanSourceType.PRODUCTION_EE, ObservationConfidence.HIGH, jours(3)),
                observation(skill, LearningPlanSkillStatus.SOLID,
                        LearningPlanSourceType.PRODUCTION_EE, ObservationConfidence.HIGH, jours(15)));

        assertThat(codes(resolver.actionable(historique))).containsExactly("EE2-C7");
    }

    /**
     * <b>Le defaut mesure sur le compte {@code user@sejourfr.fr}, competence
     * {@code EE1-C8}</b> (2026-08-15). Trois preuves en situation, puis une
     * production moins bonne, puis les cinq sujets de l'etape valides — et la
     * competence restait priorite n&deg;1 <b>definitivement</b> : l'ancienne
     * regle ne regardait que la <b>derniere</b> observation contextualisee, donc
     * une seule production moyenne revoquait trois {@code SOLID}. Aucun
     * micro-entrainement n'en sortait (la voie ciblee n'ecrit jamais
     * d'observation contextualisee) et le moteur, lui, refusait le signal de
     * verification puisqu'il jugeait la preuve deja faite.
     */
    @Test
    void troisPreuvesEnSituationNeSontPasRevoqueesParUneProductionMoinsBonne() {
        Skill bloquee = skill("EE1-C8");
        Skill suivante = skill("EO1-C4");
        List<LearningPlanObservation> historique = new ArrayList<>(List.of(
                observation(bloquee, LearningPlanSkillStatus.SOLID,
                        LearningPlanSourceType.PRODUCTION_EE, ObservationConfidence.HIGH, jours(6)),
                observation(bloquee, LearningPlanSkillStatus.SOLID,
                        LearningPlanSourceType.PRODUCTION_EE, ObservationConfidence.HIGH, jours(6)),
                observation(bloquee, LearningPlanSkillStatus.SOLID,
                        LearningPlanSourceType.PRODUCTION_EE, ObservationConfidence.HIGH, jours(5)),
                // La production moins bonne du 12/08 : elle n'est meme pas une
                // fragilite au sens du moteur, qui ne compte que les PRIORITY.
                observation(bloquee, LearningPlanSkillStatus.TO_REINFORCE,
                        LearningPlanSourceType.PRODUCTION_EE, ObservationConfidence.MEDIUM,
                        jours(4)),
                observation(suivante, LearningPlanSkillStatus.TO_REINFORCE,
                        LearningPlanSourceType.PRODUCTION_EO, ObservationConfidence.MEDIUM,
                        jours(5))));
        // Les 5 sujets de l'etape, tous valides : c'est ce que le module
        // Competences ecrit apres un critere valide.
        for (int sujet = 0; sujet < 5; sujet++) {
            historique.add(observation(bloquee, LearningPlanSkillStatus.TO_REINFORCE,
                    LearningPlanSourceType.SKILL_TRAINING, ObservationConfidence.MEDIUM,
                    jours(1)));
        }
        List<LearningPlanObservation> trie = historique(
                historique.toArray(new LearningPlanObservation[0]));

        assertThat(codes(resolver.actionable(trie))).containsExactly("EO1-C4");
        assertThat(codes(resolver.franchies(trie, maitrise(trie)))).containsExactly("EE1-C8");
    }

    /**
     * <b>« Une reussite suffit » tient</b> : le parcours normal — les cinq sujets
     * de l'etape valides, puis <b>une</b> verification en situation reussie —
     * libere l'etape.
     *
     * <p>⚠️ Et il la libere <b>sans</b> que l'etat agrege atteigne {@code SOLID} :
     * cinq micro-entrainements valent {@code 0.5} chacun et diluent la moyenne
     * ponderee sous {@code solid-score}. S'en tenir a {@code SOLID} aurait donc
     * redemande une <b>seconde</b> preuve en situation — c'est pour ca que
     * « transfert prouve » est une conclusion propre du moteur, et pas un simple
     * alias de son etat.
     */
    @Test
    void leParcoursNormalCinqSujetsPuisUneVerificationLibereLetape() {
        Skill skill = skill("EE1-C1");
        List<LearningPlanObservation> historique = new ArrayList<>(List.of(
                observation(skill, LearningPlanSkillStatus.PRIORITY,
                        LearningPlanSourceType.DIAGNOSTIC_EE, ObservationConfidence.HIGH, jours(30))));
        for (int sujet = 0; sujet < 5; sujet++) {
            historique.add(observation(skill, LearningPlanSkillStatus.TO_REINFORCE,
                    LearningPlanSourceType.SKILL_TRAINING, ObservationConfidence.MEDIUM,
                    jours(10 - sujet)));
        }
        historique.add(observation(skill, LearningPlanSkillStatus.SOLID,
                LearningPlanSourceType.PRODUCTION_EE, ObservationConfidence.HIGH, jours(1)));
        List<LearningPlanObservation> trie = historique(
                historique.toArray(new LearningPlanObservation[0]));

        assertThat(resolver.actionable(trie)).isEmpty();
        assertThat(maitrise(trie).get(skill.getId()).state())
                .isNotEqualTo(SkillMasteryState.SOLID);
    }

    // ------------------------------------------------------------------------
    // Les etapes FRANCHIES : le complement exact des priorites
    // ------------------------------------------------------------------------

    /**
     * Une etape franchie ne disparait pas du parcours : elle change de liste.
     * Les deux listes sont exclusives et couvrent tout ce qui a ete observe.
     */
    @Test
    void uneEtapeFranchieQuitteLesPrioritesMaisResteDansLeParcours() {
        Skill reussie = skill("EE1-C1");
        Skill aFaire = skill("EE1-C2");
        List<LearningPlanObservation> historique = historique(
                observation(reussie, LearningPlanSkillStatus.SOLID,
                        LearningPlanSourceType.PRODUCTION_EE, ObservationConfidence.HIGH, jours(1)),
                observation(aFaire, LearningPlanSkillStatus.TO_REINFORCE,
                        LearningPlanSourceType.DIAGNOSTIC_EE, ObservationConfidence.HIGH, jours(30)));

        assertThat(codes(resolver.actionable(historique))).containsExactly("EE1-C2");
        assertThat(codes(resolver.franchies(historique, maitrise(historique))))
                .containsExactly("EE1-C1");
    }

    /** Ordre stable : la plus recente d'abord, puis le code de la competence. */
    @Test
    void lesEtapesFranchiesSontRenduesDeLaPlusRecenteALaPlusAncienne() {
        Skill ancienne = skill("EE1-C1");
        Skill recente = skill("EO2-C3");
        Skill memeInstantA = skill("EE3-C1");
        Skill memeInstantB = skill("EE3-C2");
        List<LearningPlanObservation> historique = historique(
                observation(ancienne, LearningPlanSkillStatus.SOLID,
                        LearningPlanSourceType.PRODUCTION_EE, ObservationConfidence.HIGH, jours(20)),
                observation(recente, LearningPlanSkillStatus.SOLID,
                        LearningPlanSourceType.MOCK_EXAM_EO, ObservationConfidence.HIGH, jours(1)),
                observation(memeInstantB, LearningPlanSkillStatus.SOLID,
                        LearningPlanSourceType.PRODUCTION_EE, ObservationConfidence.HIGH, jours(10)),
                observation(memeInstantA, LearningPlanSkillStatus.SOLID,
                        LearningPlanSourceType.PRODUCTION_EE, ObservationConfidence.HIGH, jours(10)));

        assertThat(codes(resolver.franchies(historique, maitrise(historique))))
                .containsExactly("EO2-C3", "EE3-C1", "EE3-C2", "EE1-C1");
    }

    @Test
    void sansTransfertProuveIlNyAAucuneEtapeFranchie() {
        Skill skill = skill("EE1-C5");
        List<LearningPlanObservation> historique = historique(
                observation(skill, LearningPlanSkillStatus.TO_REINFORCE,
                        LearningPlanSourceType.SKILL_TRAINING, ObservationConfidence.MEDIUM,
                        jours(1)));

        assertThat(resolver.franchies(historique, maitrise(historique))).isEmpty();
    }

    /**
     * Une observation non probante ne contredit rien : {@code NOT_OBSERVED} veut
     * dire « aucune preuve ici », pas « le candidat a echoue ». La preuve
     * anterieure tient.
     */
    @Test
    void uneProductionSansPreuveNeDefaitPasLeTransfert() {
        Skill skill = skill("EO3-C8");
        LearningPlanObservation muette = observation(skill, LearningPlanSkillStatus.NOT_OBSERVED,
                LearningPlanSourceType.PRODUCTION_EO, ObservationConfidence.LOW, jours(1));
        muette.setObserved(false);
        muette.setEvidence(null);
        List<LearningPlanObservation> historique = historique(
                muette,
                observation(skill, LearningPlanSkillStatus.SOLID,
                        LearningPlanSourceType.PRODUCTION_EE, ObservationConfidence.HIGH, jours(6)));

        assertThat(resolver.actionable(historique)).isEmpty();
    }

    @Test
    void sansAucuneObservationIlNyAAucunePriorite() {
        when(observationManager.findAllByUserWithSkill(userId)).thenReturn(List.of());

        assertThat(resolver.actionable(List.of())).isEmpty();
        assertThat(resolver.currentPrioritySkillId(userId)).isEmpty();
    }

    // ------------------------------------------------------------------------
    // Fixtures
    // ------------------------------------------------------------------------

    /** L'historique tel que le rend la base : de la plus recente a la plus ancienne. */
    // ------------------------------------------------------------------------
    // Derniere activite : le fait que la seance publie pour les coches du jour
    // ------------------------------------------------------------------------

    /**
     * 🛑 Le point du contrat : « le candidat a travaille cette competence » n'est
     * pas « le correcteur a pu l'observer ». Une production rendue aujourd'hui
     * qui ne prouve rien reste une activite d'aujourd'hui — sinon la coche
     * disparaitrait pour un travail reel.
     */
    @Test
    void laDerniereActiviteCompteAussiUneObservationNonProbante() {
        Skill competence = skill("EE1-C1");
        LearningPlanObservation nonProbanteAujourdhui = observation(
                competence, LearningPlanSkillStatus.NOT_OBSERVED,
                LearningPlanSourceType.PRODUCTION_EE, ObservationConfidence.LOW, jours(0));
        nonProbanteAujourdhui.setObserved(false);
        List<LearningPlanObservation> historique = historique(
                nonProbanteAujourdhui,
                observation(competence, LearningPlanSkillStatus.TO_REINFORCE,
                        LearningPlanSourceType.PRODUCTION_EE, ObservationConfidence.HIGH,
                        jours(3)));

        Map<UUID, Instant> activites = resolver.lastActivityBySkill(historique);

        assertThat(activites).containsEntry(competence.getId(), jours(0));
        assertThat(resolver.latestObservedBySkill(historique)
                .get(competence.getId()).getObservedAt())
                .as("la derniere observation PROBANTE reste plus ancienne : deux questions distinctes")
                .isEqualTo(jours(3));
    }

    @Test
    void laDerniereActiviteEstVideSansHistorique() {
        assertThat(resolver.lastActivityBySkill(List.of())).isEmpty();
    }

    private static List<LearningPlanObservation> historique(LearningPlanObservation... items) {
        List<LearningPlanObservation> observations = new ArrayList<>(List.of(items));
        observations.sort(Comparator.comparing(LearningPlanObservation::getObservedAt).reversed());
        return List.copyOf(observations);
    }

    /** Les etats de maitrise du meme historique — ce que le Plan calcule une fois. */
    private Map<UUID, SkillMasteryEngine.SkillMastery> maitrise(
            List<LearningPlanObservation> historique) {
        return masteryResolver.fromObservations(
                historique, resolver.latestObservedBySkill(historique).keySet());
    }

    private static List<String> codes(List<LearningPlanObservation> observations) {
        return observations.stream().map(item -> item.getSkill().getCode()).toList();
    }

    private static LearningPlanObservation observation(
            Skill skill, LearningPlanSkillStatus status, LearningPlanSourceType source,
            ObservationConfidence confidence, Instant observedAt) {
        LearningPlanObservation observation = new LearningPlanObservation();
        observation.setId(UUID.randomUUID());
        observation.setSkill(skill);
        observation.setStatus(status);
        observation.setSourceType(source);
        observation.setSourceId(UUID.randomUUID());
        observation.setSubjectId(UUID.randomUUID());
        observation.setObserved(true);
        observation.setEvidence("Passage cité de la production");
        observation.setExplanation("Ce que le correcteur a constaté.");
        observation.setConfidence(confidence);
        observation.setObservedAt(observedAt);
        return observation;
    }

    private Instant jours(int nombre) {
        return maintenant.minus(Duration.ofDays(nombre));
    }

    private static Skill skill(String code) {
        Skill skill = new Skill();
        skill.setId(UUID.randomUUID());
        skill.setCode(code);
        skill.setTitle("Compétence " + code);
        skill.setSection(code.startsWith("EO") ? SkillSection.EO : SkillSection.EE);
        return skill;
    }
}
