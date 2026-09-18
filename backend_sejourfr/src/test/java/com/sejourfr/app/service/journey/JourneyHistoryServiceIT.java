package com.sejourfr.app.service.journey;

import com.sejourfr.app.dto.JourneyHistoryBlocDto;
import com.sejourfr.app.dto.JourneyHistoryCycleDto;
import com.sejourfr.app.dto.JourneyHistoryDto;
import com.sejourfr.app.entity.Journey;
import com.sejourfr.app.entity.JourneyLot;
import com.sejourfr.app.entity.JourneyStep;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.JourneyLotStatus;
import com.sejourfr.app.enums.JourneyStatus;
import com.sejourfr.app.enums.JourneyStepPurpose;
import com.sejourfr.app.enums.JourneyStepResolution;
import com.sejourfr.app.enums.JourneyStepType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.manager.SkillManager;
import com.sejourfr.app.repository.JourneyLotRepository;
import com.sejourfr.app.repository.JourneyRepository;
import com.sejourfr.app.repository.JourneyStepRepository;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import org.hibernate.SessionFactory;
import org.hibernate.stat.Statistics;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * <b>L'historique des cycles</b> — ce que sert
 * {@code GET /api/me/plan/journey/history} a la page « Ma progression ».
 *
 * <p>Ce qui est verrouille ici : ce qu'un cycle ferme <b>raconte</b>, ce qu'il
 * ne raconte <b>jamais</b> (une etape encore ouverte, un cycle en attente, un
 * niveau qu'on ne connait pas), et le <b>cout</b> de la lecture.
 *
 * <p>🛑 <b>Les cycles sont montes a la main</b>, avec leurs dates : ce qui est
 * teste est la <b>lecture</b> de l'historique, pas la construction d'un
 * parcours — celle-la est verrouillee par {@link JourneyServiceIT}, et les
 * transitions qui historisent par {@link JourneyCycleServiceIT}. Les dates sont
 * posees explicitement parce que l'ordre servi et le <b>rang</b> en dependent :
 * deux cycles crees dans la meme milliseconde ne prouveraient rien.
 */
class JourneyHistoryServiceIT extends AbstractIntegrationTest {

    @Autowired private JourneyHistoryService historyService;
    @Autowired private JourneyService journeyService;
    @Autowired private JourneyRepository journeys;
    @Autowired private JourneyLotRepository lots;
    @Autowired private JourneyStepRepository steps;
    @Autowired private SkillManager skillManager;
    @Autowired private TestData data;
    @Autowired private EntityManager entityManager;

    private static final Instant IL_Y_A_LONGTEMPS = jours(60);

    // =====================================================================
    // Le cas vide
    // =====================================================================

    @Test
    @DisplayName("Aucun cycle ferme : cycles VIDE et statistiques a ZERO — jamais null")
    void sansCycleFermeToutEstVideEtAZero() {
        User user = candidat();

        JourneyHistoryDto vue = historyService.lire(user.getId());

        // 🛑 L'ecran sait dire « rien encore » ; il ne sait pas dire « inconnu ».
        assertThat(vue.cycles()).isNotNull().isEmpty();
        assertThat(vue.stats()).isNotNull();
        assertThat(vue.stats().cyclesTermines()).isZero();
        assertThat(vue.stats().competencesTravaillees()).isZero();
        assertThat(vue.stats().examensPasses()).isZero();
    }

    // =====================================================================
    // L'ordre servi, et le rang
    // =====================================================================

    @Test
    @DisplayName("Deux cycles fermes : du plus RECENT au plus ancien, et le rang suit la CREATION")
    void deuxCyclesDuPlusRecentAuPlusAncien() {
        User user = candidat();
        Journey premier = cycleHistorise(user, jours(40), jours(30), null, TargetLevel.A2);
        Journey second = cycleHistorise(user, jours(29), jours(10), TargetLevel.A2, TargetLevel.B1);

        JourneyHistoryDto vue = historyService.lire(user.getId());

        // L'ORDRE servi est celui de la maquette : le plus recent d'abord. Aucun
        // front ne retrie — il lirait autre chose que ce que le serveur a decide.
        assertThat(vue.cycles()).extracting(JourneyHistoryCycleDto::numero)
                .containsExactly(2, 1);
        assertThat(vue.cycles().getFirst().debut()).isEqualTo(second.getCreatedAt());
        assertThat(vue.cycles().getFirst().fin()).isEqualTo(second.getHistoriseAt());
        assertThat(vue.cycles().getLast().debut()).isEqualTo(premier.getCreatedAt());
        // Les niveaux sont LUS TELS QUELS sur la ligne : aucun recalcul
        // retroactif, et le `null` du premier cycle reste `null`.
        assertThat(vue.cycles().getLast().entryLevel()).isNull();
        assertThat(vue.cycles().getLast().exitLevel()).isEqualTo(TargetLevel.A2);
        assertThat(vue.cycles().getFirst().entryLevel()).isEqualTo(TargetLevel.A2);
        assertThat(vue.cycles().getFirst().exitLevel()).isEqualTo(TargetLevel.B1);
        assertThat(vue.stats().cyclesTermines()).isEqualTo(2);
    }

    @Test
    @DisplayName("🛑 Le rang de l'historique et celui du Plan sont LE MEME NOMBRE (JourneyCycleRank)")
    void leRangNePeutPasDivergerDeCeluiDuPlan() {
        User user = candidat();
        cycleHistorise(user, jours(40), jours(30), null, TargetLevel.A2);
        cycleHistorise(user, jours(29), jours(10), TargetLevel.A2, TargetLevel.B1);

        // Le cycle EN COURS, lu par le Plan : il vient APRES les deux fermes.
        int numeroDuPlan = journeyService.lire(user.getId()).cycle().numero();
        List<Integer> numerosDeLHistorique = historyService.lire(user.getId()).cycles()
                .stream().map(JourneyHistoryCycleDto::numero).toList();

        // 🛑 Deux lectures d'un meme nombre ne doivent pas pouvoir diverger : le
        // Plan dit « Cycle 3 », l'historique dit « Cycle 2 » et « Cycle 1 », et
        // il n'y a ni trou ni doublon. Sans la regle partagee, un candidat
        // pouvait lire deux fois le meme numero sur deux ecrans.
        assertThat(numeroDuPlan).isEqualTo(3);
        assertThat(numerosDeLHistorique).containsExactly(2, 1);
        assertThat(numerosDeLHistorique).doesNotContain(numeroDuPlan);
    }

    // =====================================================================
    // Les blocs
    // =====================================================================

    @Test
    @DisplayName("Les competences se groupent par epreuve dans l'ORDRE, et un bloc sans "
            + "competence n'apparait pas")
    void lesCompetencesSeGroupentParEpreuveDansLOrdre() {
        User user = candidat();
        Journey cycle = cycleHistorise(user, jours(40), jours(30), null, TargetLevel.B1);
        Skill ee = expression(SkillTaskCode.EE1);
        Skill coPremiere = comprehension(SkillSection.CO, 0);
        Skill coSeconde = comprehension(SkillSection.CO, 1);
        // L'ordre de CREATION est EE, CO, CO : l'ordre des BLOCS est CO puis EE.
        entrainement(cycle, ee, EpreuveType.TCF_EE, true);
        entrainement(cycle, coPremiere, EpreuveType.TCF_CO, true);
        entrainement(cycle, coSeconde, EpreuveType.TCF_CO, true);
        examen(cycle, EpreuveType.TCF_EE, true);
        // L'EO n'a recu qu'un examen : aucune competence travaillee.
        examen(cycle, EpreuveType.TCF_EO, true);

        JourneyHistoryCycleDto vue = historyService.lire(user.getId()).cycles().getFirst();

        // 🛑 L'ordre est TcfDomainProfileDto.ORDRE (CO, CE, EO, EE), pas l'ordre
        // de la file : c'est une lecture par epreuve, non configurable.
        assertThat(vue.blocs()).extracting(JourneyHistoryBlocDto::examType)
                .containsExactly(EpreuveType.TCF_CO, EpreuveType.TCF_EE);
        // Dans un bloc, les titres suivent l'ordre de la FILE : celui dans lequel
        // le candidat a travaille.
        assertThat(vue.blocs().getFirst().skillTitles())
                .containsExactly(coPremiere.getTitle(), coSeconde.getTitle());
        assertThat(vue.blocs().getFirst().examens()).isZero();
        assertThat(vue.blocs().getLast().skillTitles()).containsExactly(ee.getTitle());
        assertThat(vue.blocs().getLast().examens()).isEqualTo(1);
        // 🛑 Le bloc EO est ABSENT : un historique montre ce qui a ete
        // TRAVAILLE. Son examen reste compte au niveau du cycle — sinon il
        // disparaitrait purement et simplement.
        assertThat(vue.competences()).isEqualTo(3);
        assertThat(vue.examens()).isEqualTo(2);
    }

    // =====================================================================
    // Ce qui ne se compte jamais
    // =====================================================================

    @Test
    @DisplayName("🛑 Une etape encore OUVERTE n'est jamais comptee, meme dans un cycle ferme")
    void uneEtapeOuverteNEstJamaisComptee() {
        User user = candidat();
        Journey cycle = cycleHistorise(user, jours(40), jours(30), null, null);
        Skill faite = expression(SkillTaskCode.EE1);
        Skill jamaisFaite = expression(SkillTaskCode.EE2);
        entrainement(cycle, faite, EpreuveType.TCF_EE, true);
        // Un cycle se ferme par un GESTE (« actualiser mon plan »), pas par
        // l'achevement de tout : il peut donc porter des etapes ouvertes.
        entrainement(cycle, jamaisFaite, EpreuveType.TCF_EE, false);
        examen(cycle, EpreuveType.TCF_EE, false);

        JourneyHistoryCycleDto vue = historyService.lire(user.getId()).cycles().getFirst();

        assertThat(vue.competences()).isEqualTo(1);
        assertThat(vue.examens()).isZero();
        assertThat(vue.blocs()).hasSize(1);
        assertThat(vue.blocs().getFirst().skillTitles()).containsExactly(faite.getTitle());
        assertThat(vue.blocs().getFirst().examens()).isZero();
    }

    @Test
    @DisplayName("🛑 Une etape OBSOLETE (SUPERSEDED) ne compte pas : le candidat ne l'a pas faite")
    void uneEtapeObsoleteNeCompteJamais() {
        User user = candidat();
        Journey cycle = cycleHistorise(user, jours(40), jours(30), null, null);
        Skill faite = expression(SkillTaskCode.EE1);
        Skill caduque = expression(SkillTaskCode.EE2);
        entrainement(cycle, faite, EpreuveType.TCF_EE, true);
        etape(cycle, caduque, EpreuveType.TCF_EE, JourneyStepResolution.SUPERSEDED);

        JourneyHistoryCycleDto vue = historyService.lire(user.getId()).cycles().getFirst();

        // Une etape rendue caduque par une evaluation plus recente est OBSOLETE :
        // invisible du Plan, exclue de `etapesTerminees`, donc exclue d'ici.
        // La compter feliciterait le candidat pour du travail qu'il n'a pas fait.
        assertThat(vue.competences()).isEqualTo(1);
        assertThat(vue.blocs().getFirst().skillTitles())
                .containsExactly(faite.getTitle())
                .doesNotContain(caduque.getTitle());
    }

    @Test
    @DisplayName("🛑 Le cycle EN ATTENTE n'apparait JAMAIS, et ne compte dans aucune statistique")
    void leCycleEnAttenteNApparaitJamais() {
        User user = candidat();
        cycleHistorise(user, jours(40), jours(30), null, TargetLevel.A2);
        Journey attente = journeys.saveAndFlush(
                cycle(user, JourneyStatus.EN_ATTENTE, jours(5), null, null, null));
        entrainement(attente, expression(SkillTaskCode.EE3), EpreuveType.TCF_EE, true);

        JourneyHistoryDto vue = historyService.lire(user.getId());

        // Il est invisible du candidat par construction (D-13) : le servir
        // raconterait un cycle qui n'a pas encore commence pour lui — et
        // decalerait tous les rangs.
        assertThat(vue.cycles()).hasSize(1);
        assertThat(vue.stats().cyclesTermines()).isEqualTo(1);
        assertThat(vue.stats().competencesTravaillees()).isZero();
    }

    // =====================================================================
    // Les statistiques
    // =====================================================================

    @Test
    @DisplayName("« Tout ce que vous avez deja travaille » COMPTE le cycle en cours")
    void lesStatsComptentLeCycleEnCours() {
        User user = candidat();
        Journey ferme = cycleHistorise(user, jours(40), jours(30), null, TargetLevel.A2);
        entrainement(ferme, expression(SkillTaskCode.EE1), EpreuveType.TCF_EE, true);
        examen(ferme, EpreuveType.TCF_EE, true);

        Journey courant = journeys.saveAndFlush(
                cycle(user, JourneyStatus.EN_COURS, jours(5), null, TargetLevel.A2, null));
        entrainement(courant, expression(SkillTaskCode.EE2), EpreuveType.TCF_EE, true);
        entrainement(courant, expression(SkillTaskCode.EE3), EpreuveType.TCF_EE, false);

        JourneyHistoryDto vue = historyService.lire(user.getId());

        // 🛑 L'ecran dit « tout ce que vous avez DEJA travaille », pas « dans vos
        // cycles clos ». Exclure le cycle en cours ferait reculer le compteur au
        // demarrage du suivant, et afficherait « 0 » a un candidat qui vient de
        // clore quatre competences.
        assertThat(vue.stats().competencesTravaillees()).isEqualTo(2);
        assertThat(vue.stats().examensPasses()).isEqualTo(1);
        // Mais « cycles termines » ne compte que ce qui est ferme : le cycle en
        // cours ne l'est pas.
        assertThat(vue.stats().cyclesTermines()).isEqualTo(1);
        assertThat(vue.cycles()).hasSize(1);
        assertThat(vue.cycles().getFirst().competences()).isEqualTo(1);
    }

    // =====================================================================
    // Le cout
    // =====================================================================

    @Test
    @DisplayName("Le cout est FIXE : un cycle ou trois, le meme nombre de requetes")
    void leCoutNeBougePasAvecLeNombreDeCycles() {
        User unSeul = candidat();
        Journey seul = cycleHistorise(unSeul, jours(40), jours(30), null, TargetLevel.A2);
        entrainement(seul, expression(SkillTaskCode.EE1), EpreuveType.TCF_EE, true);
        examen(seul, EpreuveType.TCF_EE, true);

        User trois = candidat();
        for (int rang = 0; rang < 3; rang++) {
            Journey cycle = cycleHistorise(
                    trois, jours(40 - rang * 10), jours(35 - rang * 10),
                    null, TargetLevel.A2);
            entrainement(cycle, comprehension(SkillSection.CO, rang),
                    EpreuveType.TCF_CO, true);
            entrainement(cycle, comprehension(SkillSection.CE, rang),
                    EpreuveType.TCF_CE, true);
            examen(cycle, EpreuveType.TCF_CO, true);
        }

        long petit = requetes(unSeul);
        long grand = requetes(trois);

        // 🛑 UNE EGALITE, jamais un `<=` : c'est la seule facon d'attraper un N+1
        // ou une requete revenue par la bande. Deux requetes, et deux
        // seulement : les cycles, puis TOUTES leurs etapes closes en un lot,
        // competence JOIN FETCH comprise. Une requete par cycle aurait fait
        // payer l'anciennete du compte.
        assertThat(petit).as("cout de l'historique, fixe et assume").isEqualTo(2);
        assertThat(grand)
                .as("un cycle ou trois, six competences ou deux : le meme cout")
                .isEqualTo(petit);
    }

    // ------------------------------------------------------------- fabriques

    /** Requetes reellement preparees par une lecture de l'historique. */
    private long requetes(User user) {
        entityManager.flush();
        entityManager.clear();
        Statistics statistics = entityManager.getEntityManagerFactory()
                .unwrap(SessionFactory.class).getStatistics();
        statistics.setStatisticsEnabled(true);
        statistics.clear();
        historyService.lire(user.getId());
        return statistics.getPrepareStatementCount();
    }

    private User candidat() {
        User user = data.user();
        user.setTargetProcedure(TargetProcedure.NAT);
        user.setTargetLevel(TargetProcedure.NAT.getRequiredTcfLevel());
        return data.saveUser(user);
    }

    private Journey cycleHistorise(
            User user, Instant creation, Instant historisation,
            TargetLevel entree, TargetLevel sortie) {
        return journeys.saveAndFlush(cycle(
                user, JourneyStatus.HISTORISE, creation, historisation, entree, sortie));
    }

    private static Journey cycle(
            User user, JourneyStatus status, Instant creation, Instant historisation,
            TargetLevel entree, TargetLevel sortie) {
        Journey journey = new Journey();
        journey.setUser(user);
        journey.setModule(Module.TCF);
        journey.setStatus(status);
        journey.setTargetLevel(TargetLevel.B2);
        journey.setCreatedAt(creation);
        journey.setUpdatedAt(creation);
        journey.setHistoriseAt(historisation);
        journey.setEntryLevel(entree);
        journey.setExitLevel(sortie);
        return journey;
    }

    /**
     * Une etape d'entrainement <b>et son lot</b> :
     * {@code chk_journey_step_train_skill} exige les deux ensemble — une
     * competence sans lot serait une priorite qu'aucune evaluation n'a designee.
     */
    private void entrainement(
            Journey journey, Skill competence, EpreuveType epreuve, boolean close) {
        etape(journey, competence, epreuve,
                close ? JourneyStepResolution.QUOTA_REACHED : null);
    }

    /**
     * 🛑 <b>Un seul lot OUVERT par (cycle, epreuve)</b> — {@code
     * uq_journey_lot_open_par_epreuve} l'impose en base, et c'est la regle du
     * produit : un lot est ce qu'<b>une</b> evaluation a retenu pour une
     * epreuve. Deux competences de la meme epreuve partagent donc leur lot.
     */
    private final Map<String, JourneyLot> lotsOuverts = new HashMap<>();

    private void etape(
            Journey journey, Skill competence, EpreuveType epreuve,
            JourneyStepResolution resolution) {
        JourneyLot lot = lotsOuverts.computeIfAbsent(
                journey.getId() + "/" + epreuve,
                cle -> {
                    JourneyLot neuf = new JourneyLot();
                    neuf.setJourney(journey);
                    neuf.setExamType(epreuve);
                    neuf.setStatus(JourneyLotStatus.OPEN);
                    neuf.setSourceAssessmentId(UUID.randomUUID());
                    return lots.saveAndFlush(neuf);
                });

        JourneyStep step = new JourneyStep();
        step.setJourney(journey);
        step.setLot(lot);
        step.setType(JourneyStepType.TRAIN_SKILL);
        step.setExamType(epreuve);
        step.setSkill(competence);
        step.setPosition(journey.consommerPosition());
        if (resolution != null) step.clore(resolution, null, Instant.now());
        journeys.saveAndFlush(journey);
        steps.saveAndFlush(step);
    }

    private void examen(Journey journey, EpreuveType epreuve, boolean close) {
        JourneyStep step = new JourneyStep();
        step.setJourney(journey);
        step.setType(JourneyStepType.SECTION_EXAM);
        step.setPurpose(JourneyStepPurpose.REASSESS);
        step.setExamType(epreuve);
        step.setPosition(journey.consommerPosition());
        if (close) {
            step.clore(JourneyStepResolution.SATISFIED_BY_ASSESSMENT,
                    UUID.randomUUID(), Instant.now());
        }
        journeys.saveAndFlush(journey);
        steps.saveAndFlush(step);
    }

    /** Une competence d'expression du referentiel seede (V318), jamais creee. */
    private Skill expression(SkillTaskCode taskCode) {
        List<Skill> seedees = skillManager.findActiveByTaskCode(taskCode);
        assertThat(seedees).as("referentiel seede pour " + taskCode).isNotEmpty();
        return seedees.getFirst();
    }

    /** Un palier de comprehension : la competence EST le palier (D-19). */
    private Skill comprehension(SkillSection section, int rang) {
        List<Skill> seedees = skillManager.findAllComprehensionBySection(section);
        assertThat(seedees).as("referentiel seede " + section).hasSizeGreaterThan(rang);
        return seedees.get(rang);
    }

    private static Instant jours(int combien) {
        return Instant.now().minus(combien, ChronoUnit.DAYS);
    }
}
