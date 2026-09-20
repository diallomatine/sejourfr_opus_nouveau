package com.sejourfr.app.service.journey;

import com.sejourfr.app.dto.AttemptResponse;
import com.sejourfr.app.dto.JourneySerieDto;
import com.sejourfr.app.dto.JourneyStepDetailDto;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.JourneyStep;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AttemptMode;
import com.sejourfr.app.enums.AttemptStatus;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.JourneyAssessmentKind;
import com.sejourfr.app.enums.JourneyObjectifKind;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.JourneyStepManager;
import com.sejourfr.app.manager.SkillManager;
import com.sejourfr.app.service.AccountDeletionService;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * <b>L'ECRAN D'ETAPE et ses cartes de serie</b> (2026-09-20).
 *
 * <p>Une etape de comprehension se valide par <b>deux series reussies</b>.
 * Jusqu'ici, le Plan lancait la serie <b>directement</b> : le candidat ne voyait
 * ni combien il lui en restait, ni ce qu'il avait deja obtenu.
 *
 * <p>Ce qui est verrouille ici, ce sont les cinq regles que le proprietaire a
 * fermees :
 * <ol>
 *   <li>une serie est reussie a <b>16 bonnes reponses sur 20</b> —
 *       <b>litteral</b>, lu sur l'attempt, derive de
 *       {@code learning-plan.comprehension.solid-ratio} x la taille de la serie ;</li>
 *   <li>la <b>serie 2 ne se debloque qu'apres REUSSITE</b> de la serie 1 (pas
 *       « faite » : reussie), et le refus est <b>opposable serveur</b> ;</li>
 *   <li>une carte reussie une fois est <b>definitivement validee</b> — la refaire
 *       et la rater ne la devalide pas, et la carte affiche le <b>dernier</b>
 *       score ;</li>
 *   <li>« refaire » <b>ajoute</b> un essai, il n'en ecrase aucun ;</li>
 *   <li>la session se joue <b>sans correction</b> : {@code mode = EXAMEN} est
 *       <b>servi</b> sur {@code AttemptResponse}, jamais deduit d'une route.</li>
 * </ol>
 *
 * <p>Non transactionnel, pour la meme raison que {@link JourneyProgressionIT} :
 * {@code onAssessmentCompleted} ecrit en {@link Propagation#REQUIRES_NEW}.
 */
@Transactional(propagation = Propagation.NOT_SUPPORTED)
class JourneyStepSeriesIT extends AbstractIntegrationTest {

    @Autowired private JourneyStepDetailService detailService;
    @Autowired private JourneyService journeyService;
    @Autowired private JourneyStepManager stepManager;
    @Autowired private TcfJourneyConfig config;
    @Autowired private AttemptManager attemptManager;
    @Autowired private SkillManager skillManager;
    @Autowired private AccountDeletionService accountDeletionService;
    @Autowired private TestData data;
    @Autowired private JdbcTemplate jdbc;

    private final List<UUID> candidats = new ArrayList<>();

    @AfterEach
    void menage() {
        candidats.forEach(id -> accountDeletionService.deleteAccount(id));
        candidats.clear();
    }

    private static final Instant HIER = Instant.now().minusSeconds(86_400);

    // ------------------------------------------------------------------ contrat

    /**
     * 🛑 <b>Le seuil est SERVI, jamais ecrit dans un front</b> : 0,80 x 20 = 16.
     * Un « 16 » recopie dans deux fronts serait la 8<sup>e</sup> declaration de
     * ce ratio, et ne bougerait plus quand il bouge.
     */
    @Test
    @DisplayName("Le contrat servi : 2 cartes de 20 questions, reussies a 16, et aucune phrase")
    void leContratServi() {
        User user = abonne();
        JourneyStep etape = etapeDeComprehension(user, SkillSection.CO);

        JourneyStepDetailDto vue = detailService.lire(user.getId(), etape.getId());

        assertThat(vue.stepId()).isEqualTo(etape.getId());
        assertThat(vue.quota()).isEqualTo(config.trainSeriesQuota());
        assertThat(vue.questionsParSerie()).isEqualTo(20);
        assertThat(vue.seuilReussite())
                .as("16/20 se DERIVE du ratio et de la taille, il n'est ecrit nulle part")
                .isEqualTo(16);
        assertThat(vue.dureeEstimeeMin()).isEqualTo(16);
        assertThat(vue.section()).isEqualTo(SkillSection.CO);
        // 🛑 Le bloc et l'objectif sont SERVIS avec leur libelle (D-47) : aucun
        // front ne branche sur le module pour composer « CO · B2 ».
        assertThat(vue.bloc().code()).isEqualTo(EpreuveType.TCF_CO.name());
        assertThat(vue.bloc().label()).isNotBlank();
        assertThat(vue.objectif().kind()).isEqualTo(JourneyObjectifKind.NIVEAU);
        assertThat(vue.objectif().label()).isNotBlank();
        assertThat(vue.unite().code()).isNotBlank();
        assertThat(vue.unite().label()).isNotBlank();
        assertThat(vue.locked()).isFalse();
        assertThat(vue.validees()).isZero();

        assertThat(vue.series()).hasSize(config.trainSeriesQuota());
        JourneySerieDto une = vue.series().getFirst();
        assertThat(une.index()).isEqualTo(1);
        assertThat(une.locked()).isFalse();
        assertThat(une.validee()).isFalse();
        // 🛑 null = jamais jouee. Surtout pas zero : un score de zero se
        // meriterait.
        assertThat(une.dernierScore()).isNull();
        assertThat(une.dernierAttemptId()).isNull();
        assertThat(une.dernierEssaiAt()).isNull();
        assertThat(vue.series().get(1).locked())
                .as("la serie 2 attend la REUSSITE de la 1")
                .isTrue();
    }

    // ------------------------------------------------------------------ verrous

    /**
     * 🛑 <b>« Reussie », pas « faite ».</b> Une serie 1 jouee et <b>ratee</b>
     * laisse la serie 2 verrouillee, et le refus est <b>serveur</b> : un ecran
     * dont l'etat en cache est perime recoit un 403 la ou son interface croyait
     * la carte ouverte.
     */
    @Test
    @DisplayName("La serie 2 reste verrouillee tant que la 1 n'est pas REUSSIE — 403 serveur")
    void laSerieDeuxAttendLaReussiteDeLaPremiere() {
        User user = abonne();
        JourneyStep etape = etapeDeComprehension(user, SkillSection.CO);

        assertThatThrownBy(() -> detailService.demarrer(user.getId(), etape.getId(), 2))
                .isInstanceOf(AccessDeniedException.class)
                .hasMessageContaining("Reussissez d'abord la serie 1");

        // Une serie 1 jouee mais RATEE (15/20, le cas limite) : toujours verrouillee.
        essai(etape, 1, user, 15);
        assertThat(detailService.lire(user.getId(), etape.getId()).series().get(1).locked())
                .isTrue();
        assertThatThrownBy(() -> detailService.demarrer(user.getId(), etape.getId(), 2))
                .isInstanceOf(AccessDeniedException.class);

        // Reussie (16/20) : la carte 2 s'ouvre.
        essai(etape, 1, user, 16);
        JourneyStepDetailDto apres = detailService.lire(user.getId(), etape.getId());
        assertThat(apres.series().getFirst().validee()).isTrue();
        assertThat(apres.series().get(1).locked()).isFalse();
        assertThat(apres.validees()).isEqualTo(1);
    }

    @Test
    @DisplayName("Un compte gratuit recoit 403 sur la serie d'une competence verrouillee")
    void unCompteGratuitEstRefuse() {
        User user = candidat();
        JourneyStep etape = etapeDeComprehension(user, SkillSection.CE);
        assertThat(detailService.lire(user.getId(), etape.getId()).locked())
                .as("le verrou est SERVI, et c'est la meme autorite que le refus")
                .isTrue();

        assertThatThrownBy(() -> detailService.demarrer(user.getId(), etape.getId(), 1))
                .isInstanceOf(AccessDeniedException.class);
    }

    @Test
    @DisplayName("Une carte hors quota est refusee, et l'etape d'un autre candidat est un 404")
    void lesRefusDeSurface() {
        User user = abonne();
        JourneyStep etape = etapeDeComprehension(user, SkillSection.CO);

        assertThatThrownBy(() -> detailService.demarrer(user.getId(), etape.getId(), 3))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("2 series");

        User autre = abonne();
        // 🛑 404, jamais 403 : repondre « interdit » confirmerait l'existence du
        // cycle d'un tiers.
        assertThatThrownBy(() -> detailService.lire(autre.getId(), etape.getId()))
                .isInstanceOf(NotFoundException.class);
    }

    // ------------------------------------------------------- validee, definitif

    /**
     * 🛑 <b>Une carte reussie une fois l'est DEFINITIVEMENT</b>, et « refaire »
     * <b>ajoute</b> un essai au lieu d'en ecraser un. Les deux regles se
     * verifient sur la meme sequence : la carte reste validee, le score servi
     * est celui du dernier essai, et la base porte bien trois lignes.
     */
    @Test
    @DisplayName("Validee reste validee apres un echec, et le score servi est le DERNIER")
    void valideeResteValideeEtLeScoreEstLeDernier() {
        User user = abonne();
        JourneyStep etape = etapeDeComprehension(user, SkillSection.CO);

        essai(etape, 1, user, 18);
        essai(etape, 1, user, 3);
        Attempt troisieme = essai(etape, 1, user, 11);

        JourneySerieDto carte = detailService.lire(user.getId(), etape.getId())
                .series().getFirst();
        assertThat(carte.validee())
                .as("le travail acquis reste acquis")
                .isTrue();
        assertThat(carte.dernierScore())
                .as("le candidat vient de faire 11 : le lui cacher serait mentir")
                .isEqualTo(11);
        assertThat(carte.dernierAttemptId()).isEqualTo(troisieme.getId());

        assertThat(jdbc.queryForObject("""
                SELECT count(*) FROM journey_step_series
                WHERE step_id = ? AND series_index = 1
                """, Integer.class, etape.getId()))
                .as("refaire AJOUTE une ligne : aucun essai n'est perdu")
                .isEqualTo(3);
    }

    /**
     * De bout en bout : deux cartes reussies closent l'etape, et c'est la
     * <b>meme</b> fonction qui a servi {@code validee} et qui clot.
     */
    @Test
    @DisplayName("Deux cartes reussies closent l'etape — une seule autorite de quota")
    void deuxCartesReussiesClosentLEtape() {
        User user = abonne();
        JourneyStep etape = etapeDeComprehension(user, SkillSection.CO);

        essai(etape, 1, user, 16);
        essai(etape, 2, user, 20);
        assertThat(detailService.lire(user.getId(), etape.getId()).validees()).isEqualTo(2);

        journeyService.onTrainingProgress(
                user.getId(), List.of(etape.getSkill().getId()));

        assertThat(stepManager.findDetail(etape.getId()).orElseThrow().estOuverte())
                .as("l'etape est close sur son quota")
                .isFalse();
    }

    // ------------------------------------------------------------------ lancement

    /**
     * 🛑 <b>Le regime de passation est SERVI</b> : la session reste un
     * {@code TRAINING} — freemium, historique et observations inchanges — mais
     * elle se joue en {@code EXAMEN}, donc <b>sans aucune correction</b> pendant
     * la passation, et l'audio de CO ne se joue qu'une fois. Aucun front n'a a
     * deduire ce fait d'une route ni d'un parametre d'URL.
     */
    @Test
    @DisplayName("Le lancement delegue la composition et sert mode = EXAMEN")
    void leLancementSertLeRegimeDePassation() {
        User user = abonne();
        JourneyStep etape = etapeDeComprehension(user, SkillSection.CO);

        AttemptResponse serie = detailService.demarrer(user.getId(), etape.getId(), 1);

        assertThat(serie.type()).isEqualTo(AttemptType.TRAINING);
        assertThat(serie.mode())
                .as("aucune correction pendant la passation, audio joue une fois")
                .isEqualTo(AttemptMode.EXAMEN);
        assertThat(serie.questions()).hasSize(20);
        // Aucune correction n'est servie AVANT la fin : c'est deja le contrat du
        // mapper, et c'est ce que le regime rend vrai pendant la session.
        assertThat(serie.questions()).allSatisfy(q -> assertThat(q.correct()).isNull());

        // Le LIEN est ecrit : c'est lui, et lui seul, qui rattache la session a
        // la carte 1 de cette etape.
        assertThat(jdbc.queryForObject("""
                SELECT count(*) FROM journey_step_series
                WHERE step_id = ? AND series_index = 1 AND attempt_id = ?
                """, Integer.class, etape.getId(), serie.id()))
                .isEqualTo(1);

        JourneySerieDto carte = detailService.lire(user.getId(), etape.getId())
                .series().getFirst();
        assertThat(carte.dernierAttemptId()).isEqualTo(serie.id());
        assertThat(carte.dernierScore())
                .as("une session en cours n'a pas de score : null = inconnu, jamais zero")
                .isNull();
        assertThat(carte.validee()).isFalse();
    }

    // ------------------------------------------------------------------ outils

    /** Un essai joue jusqu'au bout sur une carte, avec son score. */
    private Attempt essai(JourneyStep etape, int carte, User user, int score) {
        return data.serieDEtape(etape, carte, user, Module.TCF, score).getAttempt();
    }

    /**
     * Une etape de comprehension ouverte, creee par le seul chemin qui en cree :
     * une <b>evaluation</b> (R1).
     */
    private JourneyStep etapeDeComprehension(User user, SkillSection section) {
        Skill skill = skillManager.findAllComprehensionBySection(section).getFirst();
        EpreuveType epreuve = section == SkillSection.CO
                ? EpreuveType.TCF_CO : EpreuveType.TCF_CE;
        UUID examen = examenBlanc(user, epreuve);
        data.learningPlanObservation(user, skill, section == SkillSection.CO
                        ? LearningPlanSourceType.TCF_CO : LearningPlanSourceType.TCF_CE,
                LearningPlanSkillStatus.PRIORITY, ObservationConfidence.HIGH, null,
                HIER, examen);
        journeyService.onAssessmentCompleted(user.getId(), new JourneyEvaluation(
                examen, JourneyAssessmentKind.SECTION_EXAM, epreuve, HIER));

        return journeyService.getOrCreate(user.getId(), Module.TCF)
                .map(journey -> stepManager.findAll(journey.getId()).stream()
                        .filter(step -> step.getSkill() != null
                                && step.getSkill().getId().equals(skill.getId()))
                        .findFirst()
                        .orElseThrow(() -> new AssertionError(
                                "Aucune etape pour " + skill.getCode())))
                .orElseThrow(() -> new AssertionError("Aucun parcours"));
    }

    private UUID examenBlanc(User user, EpreuveType epreuve) {
        Attempt attempt = new Attempt();
        attempt.setUser(user);
        attempt.setType(AttemptType.MOCK_EXAM);
        attempt.setMode(AttemptMode.EXAMEN);
        attempt.setStatus(AttemptStatus.TERMINE);
        attempt.setModule(Module.TCF);
        attempt.setEpreuve(epreuve);
        attempt.setStartedAt(HIER);
        attempt.setFinishedAt(HIER);
        return attemptManager.save(attempt).getId();
    }

    private User abonne() {
        User user = candidat();
        data.userSubscription(user, data.plan());
        return user;
    }

    private User candidat() {
        User user = data.user();
        user.setTargetProcedure(TargetProcedure.NAT);
        user.setTargetLevel(TargetProcedure.NAT.getRequiredTcfLevel());
        user = data.saveUser(user);
        candidats.add(user.getId());
        return user;
    }
}
