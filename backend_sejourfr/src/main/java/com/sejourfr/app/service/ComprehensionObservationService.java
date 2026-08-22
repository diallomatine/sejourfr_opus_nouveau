package com.sejourfr.app.service;

import com.sejourfr.app.config.LearningPlanProperties;
import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.manager.LearningPlanObservationManager;
import com.sejourfr.app.manager.SkillManager;
import com.sejourfr.app.manager.UserManager;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/**
 * <b>LE</b> producteur d'observations de COMPREHENSION : ce qu'une session QCM
 * terminee apprend au Plan sur les competences {@code CO-*} et {@code CE-*}.
 *
 * <p>Jusqu'ici, {@link LearningPlanSourceType#TCF_CO} / {@code TCF_CE} etaient
 * declarees et {@code SkillMasteryEngine} savait deja les ponderer
 * ({@code weight-comprehension}), mais <b>aucun code ne les ecrivait</b> : la
 * plomberie existait sans producteur. C'est lui.
 *
 * <h2>Ce qu'il fait, en une phrase</h2>
 * Il ne regarde <b>jamais</b> le score total de la session — il <b>ventile les
 * reponses par niveau de question</b> ({@code questions.difficulty}, qui porte
 * bien {@code A2|B1|B2}) et produit <b>une observation par (domaine x niveau)
 * reellement represente</b>, vers la competence correspondante. Un examen
 * d'epreuve CO (8 A2 + 9 B1 + 8 B2) alimente donc les trois competences CO d'un
 * coup, chacune sur ses propres questions ; une serie ciblee de 20 questions
 * B1 n'en alimente qu'une, avec vingt observations elementaires derriere.
 *
 * <h2>Perimetre</h2>
 * <ul>
 *   <li>Module {@code TCF} et compte identifie ({@code user != null} — un
 *       attempt invite n'a personne a qui attribuer un progres).</li>
 *   <li>Types de question {@code CO} et {@code CO_IMAGE} regroupes sous
 *       {@code CO} (partout ailleurs dans le depot, un filtre CO inclut
 *       CO_IMAGE), et {@code CE}.</li>
 *   <li><b>{@code STRUCTURE} est hors perimetre</b> : le referentiel ne lui
 *       donne aucune competence, et on ne lui en invente pas une.</li>
 *   <li>Niveaux {@code A2}, {@code B1}, {@code B2} seulement — les valeurs
 *       civiques de {@link Difficulty} ({@code CSP}/{@code CR}/{@code NAT}) ne
 *       decrivent pas un palier CECRL.</li>
 * </ul>
 * L'examen blanc comme la serie d'entrainement ciblee nourrissent le profil :
 * la source ne distingue pas les deux, contrairement a l'expression ou
 * {@code MOCK_EXAM_EE} pese plus que {@code PRODUCTION_EE}. Motif : en
 * comprehension, <b>une bonne reponse est une bonne reponse</b> — il n'y a ni
 * assistance ni filet dont l'absence rendrait l'examen plus probant. Ce qui
 * varie, c'est la <b>taille de l'echantillon</b>, et c'est la confiance qui la
 * porte.
 *
 * <h2>Plancher de fiabilite</h2>
 * Sous {@code comprehension.min-questions} questions d'un niveau, l'observation
 * est ecrite {@code NOT_OBSERVED} : deux questions B2 dans un examen ne disent
 * rien, et le depot tient que <b>« non observe » = inconnu, jamais mauvais</b>.
 * Le moteur de maitrise les ignore ; elles restent en base comme trace.
 *
 * <h2>Idempotence</h2>
 * La cle est {@code (user, competence, source, attempt)} — l'attempt est
 * l'identite stable de la session. Un rafraichissement, un double envoi mobile,
 * une cloture automatique a echeance suivie d'un {@code finish} explicite ou un
 * rejeu quelconque retombent sur la meme cle : le doublon est refuse en amont
 * par la lecture, et en dernier ressort par
 * {@code uq_learning_plan_observation_source}.
 *
 * <h2>Best-effort</h2>
 * {@link Propagation#REQUIRES_NEW} : l'ecriture des observations vit dans sa
 * <b>propre</b> transaction, ce qui permet a l'appelant d'avaler l'exception
 * sans que la correction du QCM ni la reponse HTTP n'en souffrent — une
 * violation de contrainte dans la transaction englobante l'aurait marquee
 * {@code rollback-only}. Meme invariant que
 * {@code ProductionPipelineFailureRecorder}.
 */
@Service
@Slf4j
@RequiredArgsConstructor
public class ComprehensionObservationService {

    private final LearningPlanProperties properties;
    private final LearningPlanObservationManager observationManager;
    private final SkillManager skillManager;
    private final UserManager userManager;

    /**
     * Une reponse elementaire, reduite a ce qui decide de son rattachement.
     *
     * <p><b>Valeurs, pas entites</b> : l'appelant les extrait dans SA
     * transaction, ou tout est deja charge, et rien de detache ne traverse la
     * frontiere {@code REQUIRES_NEW}.
     */
    public record ReponseComprehension(
            QuestionType questionType, Difficulty difficulty, boolean correct) {}

    /**
     * Enregistre ce qu'une session QCM terminee apprend sur la comprehension.
     *
     * @param userId     proprietaire de la session ; {@code null} (invite) =
     *                   rien a faire.
     * @param attemptId  identite stable de la session, qui sert de
     *                   {@code source_id} <b>et</b> de {@code subject_id}.
     * @param observedAt fin de la session.
     * @param reponses   toutes les reponses de la session, tous types confondus.
     * @return nombre d'observations effectivement ecrites (0 est un cas normal :
     *         session civique, session STRUCTURE, ou session deja observee).
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public int record(
            UUID userId,
            UUID attemptId,
            Instant observedAt,
            List<ReponseComprehension> reponses) {
        if (userId == null || attemptId == null || reponses == null || reponses.isEmpty()) {
            return 0;
        }
        Map<Cle, Compte> parNiveau = ventile(reponses);
        // Zero requete supplementaire sur une session sans comprehension :
        // civique, STRUCTURE seule, ou production.
        if (parNiveau.isEmpty()) return 0;

        Map<Cle, Skill> competences = competencesParCle();
        if (competences.isEmpty()) {
            log.warn("Aucune competence de comprehension active : observations CO/CE ignorees.");
            return 0;
        }
        Optional<User> user = userManager.findById(userId);
        if (user.isEmpty()) return 0;

        Instant quand = observedAt == null ? Instant.now() : observedAt;
        int ecrites = 0;
        for (Map.Entry<Cle, Compte> entree : parNiveau.entrySet()) {
            Skill skill = competences.get(entree.getKey());
            if (skill == null) continue;
            if (ecrire(user.get(), skill, entree.getKey(), entree.getValue(), attemptId, quand)) {
                ecrites++;
            }
        }
        return ecrites;
    }

    // ------------------------------------------------------------------------
    // Interne
    // ------------------------------------------------------------------------

    /**
     * Ventilation par (domaine, niveau). {@code CO_IMAGE} rejoint {@code CO} —
     * c'est un format de question de comprehension orale, pas un domaine.
     */
    private static Map<Cle, Compte> ventile(List<ReponseComprehension> reponses) {
        Map<Cle, Compte> parNiveau = new LinkedHashMap<>();
        for (ReponseComprehension reponse : reponses) {
            SkillSection domaine = domaine(reponse.questionType());
            if (domaine == null) continue;
            String niveau = niveau(reponse.difficulty());
            if (niveau == null) continue;
            parNiveau.computeIfAbsent(new Cle(domaine, niveau), key -> new Compte())
                    .ajoute(reponse.correct());
        }
        return parNiveau;
    }

    /** {@code null} pour tout ce qui n'est pas de la comprehension — STRUCTURE comprise. */
    private static SkillSection domaine(QuestionType type) {
        if (type == null) return null;
        return switch (type) {
            case CO, CO_IMAGE -> SkillSection.CO;
            case CE -> SkillSection.CE;
            default -> null;
        };
    }

    /** {@code null} pour les difficultes civiques, qui ne sont pas des paliers CECRL. */
    private static String niveau(Difficulty difficulty) {
        if (difficulty == null) return null;
        return switch (difficulty) {
            case A2, B1, B2 -> difficulty.name();
            default -> null;
        };
    }

    private Map<Cle, Skill> competencesParCle() {
        Map<Cle, Skill> parCle = new LinkedHashMap<>();
        for (Skill skill : skillManager.findActiveComprehension()) {
            if (skill.getSection() == null || skill.getTargetLevel() == null) continue;
            parCle.putIfAbsent(new Cle(skill.getSection(), skill.getTargetLevel()), skill);
        }
        return parCle;
    }

    private boolean ecrire(
            User user, Skill skill, Cle cle, Compte compte, UUID attemptId, Instant quand) {
        LearningPlanSourceType source = cle.domaine() == SkillSection.CO
                ? LearningPlanSourceType.TCF_CO : LearningPlanSourceType.TCF_CE;
        if (observationManager.findBySource(
                user.getId(), skill.getId(), source, attemptId).isPresent()) {
            return false;
        }
        LearningPlanProperties.Comprehension config = properties.getComprehension();
        boolean fiable = compte.total() >= config.getMinQuestions();

        LearningPlanObservation observation = new LearningPlanObservation();
        observation.setUser(user);
        observation.setSkill(skill);
        observation.setSourceType(source);
        observation.setSourceId(attemptId);
        // Le SUJET d'une session QCM, c'est la SESSION elle-meme. Deux series
        // distinctes tirent des questions differentes : ce sont deux preuves
        // independantes, et le moteur a raison de les compter comme telles.
        // A l'inverse, une meme session relue, rejouee ou reclose garde son
        // identite — c'est aussi ce qui tient l'idempotence.
        observation.setSubjectId(attemptId);
        observation.setObserved(fiable);
        observation.setStatus(fiable ? statut(compte, config) : LearningPlanSkillStatus.NOT_OBSERVED);
        // `chk_learning_plan_observation_coherence` : une observation non
        // observee n'a PAS de preuve, une observation probante en a une.
        observation.setEvidence(fiable
                ? compte.correctes() + " / " + compte.total() + " bonnes réponses" : null);
        observation.setConfidence(fiable
                ? (compte.total() >= config.getHighConfidenceQuestions()
                        ? ObservationConfidence.HIGH : ObservationConfidence.MEDIUM)
                : ObservationConfidence.LOW);
        // La baseline, c'est le diagnostic initial et lui seul.
        observation.setBaseline(false);
        observation.setObservedAt(quand);
        try {
            observationManager.save(observation);
            return true;
        } catch (DataIntegrityViolationException doublonConcurrent) {
            // uq_learning_plan_observation_source : deux clotures concurrentes
            // de la meme session aboutissent au meme signal, jamais a un doublon.
            return false;
        }
    }

    private static LearningPlanSkillStatus statut(
            Compte compte, LearningPlanProperties.Comprehension config) {
        double ratio = compte.ratio();
        if (ratio >= config.getSolidRatio()) return LearningPlanSkillStatus.SOLID;
        if (ratio >= config.getReinforceRatio()) return LearningPlanSkillStatus.TO_REINFORCE;
        return LearningPlanSkillStatus.PRIORITY;
    }

    /** Cle de ventilation : un domaine et un palier, exactement ce qui identifie une competence. */
    private record Cle(SkillSection domaine, String niveau) {}

    /** Accumulateur d'un (domaine, niveau) sur une session. */
    private static final class Compte {
        private int total;
        private int correctes;

        private void ajoute(boolean correcte) {
            total++;
            if (correcte) correctes++;
        }

        private int total() { return total; }
        private int correctes() { return correctes; }
        private double ratio() { return total == 0 ? 0 : (double) correctes / total; }
    }
}
