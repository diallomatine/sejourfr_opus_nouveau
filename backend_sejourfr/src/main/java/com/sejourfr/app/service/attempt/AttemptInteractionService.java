package com.sejourfr.app.service.attempt;

import com.sejourfr.app.dto.AnswerResultResponse;
import com.sejourfr.app.dto.AttemptResponse;
import com.sejourfr.app.dto.AttemptSummaryResponse;
import com.sejourfr.app.dto.SubmitAnswerRequest;
import com.sejourfr.app.entity.Answer;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.CivicDiagnosticSession;
import com.sejourfr.app.entity.CivicOfficialUnit;
import com.sejourfr.app.entity.AttemptQuestion;
import com.sejourfr.app.entity.Choice;
import com.sejourfr.app.entity.Question;
import com.sejourfr.app.enums.AttemptStatus;
import com.sejourfr.app.enums.AttemptMode;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.DureeEpreuve;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.manager.AnswerManager;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.AttemptQuestionManager;
import com.sejourfr.app.mapper.AttemptMapper;
import com.sejourfr.app.mapper.QuestionMapper;
import com.sejourfr.app.progression.domain.AttemptCompletionStatus;
import com.sejourfr.app.progression.domain.EvidenceEntryPoint;
import com.sejourfr.app.progression.domain.EvidenceSourceType;
import com.sejourfr.app.progression.service.ReceptiveEvidenceAdapter;
import com.sejourfr.app.progression.service.ReceptiveEvidenceAdapter.ReponseQcm;
import com.sejourfr.app.service.journey.JourneyEvaluation;
import com.sejourfr.app.service.diagnosticrun.DiagnosticRunService;
import com.sejourfr.app.service.journey.JourneyProductionBridge;
import com.sejourfr.app.util.TcfDomaine;
import com.sejourfr.app.service.journey.JourneyService;
import com.sejourfr.app.service.ComprehensionObservationService;
import com.sejourfr.app.service.CivicObservationService;
import com.sejourfr.app.service.CivicObservationService.ReponseCivique;
import com.sejourfr.app.service.TcfLevelEstimatorService;
import com.sejourfr.app.service.examencivique.CivicExamCompositionService;
import com.sejourfr.app.service.ComprehensionObservationService.ReponseComprehension;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Cycle de vie post-start d'un attempt : lecture, soumission de réponse et
 * finalisation. Extrait d'AttemptService pour isoler la mécanique de jeu de
 * la logique de composition / dispatch de démarrage.
 */
@Service
@Slf4j
@RequiredArgsConstructor
public class AttemptInteractionService {

    private static final int LIST_LIMIT_MIN = 1;
    private static final int LIST_LIMIT_MAX = 100;

    private final AttemptManager attemptManager;
    private final AttemptQuestionManager attemptQuestionManager;
    private final AnswerManager answerManager;
    private final AttemptScoringService scoringService;
    // 🛑 Autorite unique du niveau QCM, et la SEULE forme groupee : la liste
    // d'historique demande les niveaux de toute sa page en une requete.
    private final TcfLevelEstimatorService levelEstimator;
    private final ReceptiveEvidenceAdapter receptiveEvidenceAdapter;
    private final AttemptMapper mapper;
    private final QuestionMapper questionMapper;
    private final ComprehensionObservationService comprehensionObservationService;
    private final CivicObservationService civicObservationService;
    // 🛑 L'autorite de « de quelle unite releve cette question » -- la meme que
    // celle qui COMPOSE les examens. Une seconde version ferait ranger une
    // question dans deux unites selon qu'on la tire ou qu'on la mesure.
    private final CivicExamCompositionService civicCompositionService;
    private final JourneyService journeyService;
    private final JourneyProductionBridge journeyProductionBridge;
    private final DiagnosticRunService diagnosticRunService;

    // ------------------------------------------------------------------------
    // Lecture
    // ------------------------------------------------------------------------

    @Transactional(readOnly = true)
    public AttemptResponse getById(UUID userId, UUID attemptId) {
        Attempt attempt = loadAndCheck(userId, attemptId);
        List<AttemptQuestion> aqs = attemptQuestionManager.findByAttemptOrderedByPosition(attemptId);
        boolean revealCorrect = attempt.getFinishedAt() != null;
        return mapper.toResponse(attempt, aqs, revealCorrect);
    }

    @Transactional(readOnly = true)
    public List<AttemptSummaryResponse> listMine(
            UUID userId,
            AttemptType type,
            Module module,
            QuestionType moduleExamQuestionType,
            UUID themeId,
            int limit) {
        int safeLimit = Math.max(LIST_LIMIT_MIN, Math.min(LIST_LIMIT_MAX, limit));
        List<Attempt> attempts = attemptManager.findByUserFiltered(
                userId, type, module, moduleExamQuestionType, themeId, safeLimit);
        // 🛑 UNE requête agrégée pour TOUTE la page. Le niveau CECRL n'est plus
        // persisté : il se dérive des réponses. Le demander ligne par ligne
        // ferait un N+1 sur l'écran d'historique — verrouillé par un test qui
        // compte les requêtes à l'ÉGALITÉ (AttemptListeNiveauDeriveIT).
        Map<UUID, NiveauCecrl> niveaux = levelEstimator.niveauxQcm(
                attempts.stream().map(Attempt::getId).toList());
        return attempts.stream()
                .map(a -> mapper.toSummary(a, niveaux.get(a.getId())))
                .toList();
    }

    /**
     * Lookup d'un attempt guest pour la branche publique. Renvoie l'attempt
     * SEULEMENT si user IS NULL ET client_ip matche. Toute non-correspondance
     * (id inexistant, attempt d'un user, autre IP) est traitee en 404 par
     * l'appelant pour ne pas reveler l'existence.
     */
    @Transactional(readOnly = true)
    public Attempt loadGuestAttempt(UUID attemptId, String clientIp) {
        return attemptManager.findGuestByIdAndIp(attemptId, clientIp)
                .orElseThrow(() -> new EntityNotFoundException("Session introuvable"));
    }

    /**
     * Variante de {@link #getById(UUID, UUID)} sans controle user (l'appelant
     * a deja valide l'IP via {@link #loadGuestAttempt}).
     */
    @Transactional(readOnly = true)
    public AttemptResponse readAttempt(Attempt attempt) {
        List<AttemptQuestion> aqs = attemptQuestionManager.findByAttemptOrderedByPosition(attempt.getId());
        boolean revealCorrect = attempt.getFinishedAt() != null;
        return mapper.toResponse(attempt, aqs, revealCorrect);
    }

    // ------------------------------------------------------------------------
    // Soumission d'une reponse
    // ------------------------------------------------------------------------

    @Transactional
    public AnswerResultResponse submitAnswer(UUID userId, UUID attemptId, SubmitAnswerRequest req) {
        Attempt attempt = loadAndCheck(userId, attemptId);
        if (attempt.getFinishedAt() != null) {
            throw new IllegalStateException("Session déjà terminée");
        }
        return doSubmitAnswer(attempt, req);
    }

    /**
     * Variante de {@link #submitAnswer(UUID, UUID, SubmitAnswerRequest)} qui
     * skip le controle user (deja fait via IP cote guest).
     */
    @Transactional
    public AnswerResultResponse submitAnswerForAttempt(Attempt attempt, SubmitAnswerRequest req) {
        if (attempt.getFinishedAt() != null) {
            throw new IllegalStateException("Session déjà terminée");
        }
        return doSubmitAnswer(attempt, req);
    }

    /**
     * Chrono d'épreuve QCM, <b>opposable serveur</b>. {@code time_limit_seconds}
     * n'était lu que par les fronts : rien n'empêchait de répondre après
     * l'échéance, alors que les productions EE/EO sont protégées depuis
     * toujours par {@code ProductionAccessService.assertWithinTimeLimit}. Même
     * grâce que là-bas ({@value DureeEpreuve#GRACE_SOUMISSION_SECONDS} s), pour
     * couvrir la latence de l'auto-soumission déclenchée à 0:00.
     *
     * <p>Le refus porte sur <b>une</b> réponse et ne fait pas échouer la
     * session : les réponses déjà enregistrées restent acquises et l'épreuve se
     * clôture proprement à la lecture suivante ({@link #closeIfExpired}).
     */
    private void assertWithinTimeLimit(Attempt attempt) {
        if (AttemptChrono.horsDelai(attempt, Instant.now())) {
            throw new BusinessException(
                    "Le temps de cette épreuve est écoulé — cette réponse n'est plus "
                            + "enregistrée. Vos réponses précédentes sont conservées.");
        }
    }

    private AnswerResultResponse doSubmitAnswer(Attempt attempt, SubmitAnswerRequest req) {
        assertWithinTimeLimit(attempt);
        AttemptQuestion aq = attemptQuestionManager.findById(req.attemptQuestionId())
                .orElseThrow(() -> new EntityNotFoundException("Question introuvable dans la session"));

        if (!aq.getAttempt().getId().equals(attempt.getId())) {
            throw new IllegalArgumentException("Cette question n'appartient pas à cette session");
        }

        Question question = aq.getQuestion();
        Set<UUID> questionChoiceIds = question.getChoices().stream()
                .map(Choice::getId)
                .collect(Collectors.toSet());
        Set<UUID> correctIds = question.getChoices().stream()
                .filter(Choice::isCorrect)
                .map(Choice::getId)
                .collect(Collectors.toSet());
        Set<UUID> submitted = new HashSet<>(req.choiceIds());
        // Les choix soumis doivent appartenir à CETTE question. Sans ce contrôle,
        // un choiceId pris sur une autre question était accepté et persisté dans
        // answers.selected_choice_ids — sans effet sur le score, mais la revue
        // affichait ensuite une sélection qui n'existe pas dans la question.
        if (!questionChoiceIds.containsAll(submitted)) {
            throw new IllegalArgumentException(
                    "Un choix soumis n'appartient pas à cette question");
        }
        boolean correct = submitted.equals(correctIds);

        // Sauvegarde/MAJ de la reponse (une seule par attempt_question)
        Answer existing = aq.getAnswer();
        Answer answer = existing != null ? existing : new Answer();
        answer.setAttemptQuestion(aq);
        answer.setSelectedChoiceIds(new ArrayList<>(submitted));
        answer.setCorrect(correct);
        answer.setAnsweredAt(Instant.now());
        answerManager.save(answer);

        aq.setAnswer(answer);
        attemptQuestionManager.save(aq);

        // 🛑 LE REGIME DE PASSATION DECIDE, PAS LE TYPE (2026-09-20).
        // `mode` est la MEME valeur que celle servie dans AttemptResponse.mode :
        // l'ecran et ce refus ne peuvent donc pas diverger. Le comportement
        // historique est inchange (TRAINING -> ENTRAINEMENT, MOCK_EXAM ->
        // EXAMEN, REVIEW -> REVISION, derives par Attempt.prePersist) ; ce qui
        // s'y ajoute est la SERIE D'ETAPE : un TRAINING pose en mode EXAMEN,
        // donc sans aucune correction pendant la passation.
        if (attempt.regime() == AttemptMode.ENTRAINEMENT) {
            // Les lettres citées par l'explication suivent l'ordre AFFICHÉ, pas le
            // display_order de la base : même graine que le runner (AttemptQuestion.id),
            // donc mêmes lettres que les propositions sous les yeux du candidat.
            return new AnswerResultResponse(true, correct, new ArrayList<>(correctIds),
                    questionMapper.explication(question, aq.getId()));
        }
        return new AnswerResultResponse(true, null, null, null);
    }

    // ------------------------------------------------------------------------
    // Finalisation
    // ------------------------------------------------------------------------

    @Transactional
    public AttemptResponse finish(UUID userId, UUID attemptId) {
        Attempt attempt = loadAndCheck(userId, attemptId);
        return doFinish(attempt);
    }

    /** Variante de {@link #finish(UUID, UUID)} qui skip le controle user. */
    @Transactional
    public AttemptResponse finishAttempt(Attempt attempt) {
        return doFinish(attempt);
    }

    // ------------------------------------------------------------------------
    // Clôture automatique à échéance (paresseuse, à la lecture)
    // ------------------------------------------------------------------------

    /**
     * Clôture la session si son délai est écoulé, avec ce qui a été enregistré.
     * <b>Paresseux, à la lecture</b> — aucun job planifié, même philosophie que
     * l'expiration d'abonnement de {@code SubscriptionService.isCovering} :
     * l'état se dérive du temps, on ne le pousse pas.
     *
     * <p>Quitter ne suspend rien. Le candidat qui revient <b>avant</b>
     * l'échéance reprend avec le temps réellement restant ; celui qui revient
     * <b>après</b> retrouve son épreuve close, notée sur les réponses
     * existantes. Il n'y a volontairement aucun flux « recommencer une épreuve
     * interrompue ».
     *
     * <p>Transaction <b>propre</b> ({@link Propagation#REQUIRES_NEW}) : les
     * appelants lisent en {@code readOnly}, et une écriture doit pouvoir s'y
     * glisser sans les rendre écrivables. Idempotent (une session déjà
     * terminée est ignorée) et sans effet quand l'épreuve n'a pas de chrono
     * (entraînement libre, expression orale, épreuve d'examen complet pas
     * encore lancée).
     *
     * @return true si la session vient d'être close par cet appel.
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public boolean closeIfExpired(UUID attemptId) {
        if (attemptId == null) return false;
        return attemptManager.findById(attemptId)
                .map(this::closeExpired)
                .orElse(false);
    }

    /**
     * Même clôture, appliquée aux sous-épreuves d'un examen blanc TCF complet.
     * Chacune porte son propre chrono, ancré sur son lancement réel : la CO
     * peut expirer pendant que la CE n'a même pas commencé.
     *
     * @return nombre de sous-épreuves closes par cet appel.
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public int closeExpiredSubAttempts(UUID parentAttemptId) {
        if (parentAttemptId == null) return 0;
        int closed = 0;
        for (Attempt sub : attemptManager.findSubAttempts(parentAttemptId)) {
            if (closeExpired(sub)) closed++;
        }
        return closed;
    }

    private boolean closeExpired(Attempt attempt) {
        if (attempt.getFinishedAt() != null) return false;
        if (!AttemptChrono.horsDelai(attempt, Instant.now())) return false;
        doFinish(attempt);
        return true;
    }

    private AttemptResponse doFinish(Attempt attempt) {
        UUID attemptId = attempt.getId();

        // Attempts production (EE/EO) : pas de questions ni de score QCM — on
        // pose juste finishedAt + TERMINE. Appelé par les fronts à la fin
        // d'une session d'examen production (ou à l'expiration du chrono EE) ;
        // le bilan comptera les tâches non rendues à 0 (ProductionBilanService).
        if (attempt.getEpreuve() == EpreuveType.TCF_EE || attempt.getEpreuve() == EpreuveType.TCF_EO) {
            if (attempt.getFinishedAt() == null) {
                attempt.setFinishedAt(Instant.now());
                attempt.setStatus(AttemptStatus.TERMINE);
                attemptManager.save(attempt);
                // 🛑 SECOND POINT DE BRANCHEMENT DU PARCOURS (D-24, point 2).
                // Cette sortie anticipee ne passe PAS par la suite de doFinish,
                // donc pas par `porterAuParcours` : une epreuve EE/EO
                // ABANDONNEE — une ou deux taches rendues, session close a
                // l'echeance — n'ouvrait aucun lot, et son travail etait perdu
                // (dette D-11 / A16). Le pont decide seul s'il y a quelque
                // chose a signaler : il se tait quand une correction est encore
                // en cours, et quand aucune tache n'a ete corrigee.
                journeyProductionBridge.onProductionAttemptClosed(attempt);
            }
            return mapper.toResponse(attempt, List.of(), true);
        }

        List<AttemptQuestion> aqs = attemptQuestionManager.findByAttemptOrderedByPosition(attemptId);

        if (attempt.getFinishedAt() != null) {
            // Idempotent : on renvoie l'etat actuel.
            return mapper.toResponse(attempt, aqs, true);
        }

        int score = (int) aqs.stream()
                .filter(aq -> aq.getAnswer() != null && Boolean.TRUE.equals(aq.getAnswer().getCorrect()))
                .count();

        attempt.setFinishedAt(Instant.now());
        // Le statut restait EN_COURS sur une session QCM pourtant terminée
        // (seule la branche production le posait). C'est lui qui distingue une
        // épreuve en cours d'une épreuve close, y compris pour la clôture
        // automatique à échéance.
        attempt.setStatus(AttemptStatus.TERMINE);
        attempt.setScore(score);

        if (attempt.getModule() == Module.TCF) {
            // Les examens template TCF (diagnostic CO→CE) ont aussi leurs
            // strates garanties depuis la composition sectionnée : même
            // notation que les examens module.
            boolean stratifiedExam = attempt.getModuleExamQuestionType() != null
                    || (attempt.getType() == AttemptType.MOCK_EXAM && attempt.getExamTemplate() != null);
            if (stratifiedExam) {
                // 🛑 `cecrl_level` N'EST PLUS ÉCRIT (2026-09-20). Le niveau
                // CECRL est un dérivé : il se recalcule à la lecture depuis les
                // réponses (TcfLevelEstimatorService), et le persister aurait
                // figé ici des lignes que le changement de règle ne peut plus
                // relire. Ce qui reste écrit est de la MESURE, pas un verdict :
                // le score pondéré (A2=1, B1=2, B2=3), matière du score de
                // progression 100-499.
                attempt.setLevelAchieved(AttemptScoringService.toTargetLevel(
                        scoringService.estimatePerEpreuveFloor(aqs)));
                attempt.setWeightedScore(scoringService.computeWeightedScore(aqs, true));
                attempt.setMaxWeightedScore(scoringService.computeWeightedScore(aqs, false));
            } else {
                // Entraînement TCF libre : strates non garanties (pool
                // aléatoire) → palier indicatif seulement, sans score pondéré.
                attempt.setLevelAchieved(scoringService.computeLevelAchieved(aqs));
            }
        }

        attemptManager.save(attempt);
        // Fin de l'attempt d'un diagnostic civique = « soumis » de sa run
        // (chantier Suivi, lot 2a). Ici et nulle part ailleurs : c'est le seul
        // point de fin d'un QCM (fin explicite publique ou connectee, echeance).
        diagnosticRunService.onCivicAttemptFinished(attempt);
        recordComprehension(attempt, aqs);
        recordCivique(attempt, aqs);
        recordProgression(attempt, aqs);
        return mapper.toResponse(attempt, aqs, true);
    }

    /**
     * Ce que cette session apprend au <b>moteur de progression V4.2</b>
     * (docs/regles/progression.md).
     *
     * <p>Second producteur, à côté de {@link #recordComprehension} : les deux
     * coexistent volontairement le temps du shadow mode. L'ancien alimente le
     * Plan servi aujourd'hui, le nouveau écrit dans son registre et prédit sans
     * rien piloter. On ne bascule qu'après validation des métriques
     * ({@code PROGRESSION_ENGINE_MODE=ACTIVE}) — d'ici là, aucun candidat ne
     * voit un Plan calculé sur des seuils encore hypothétiques.
     *
     * <p><b>Best-effort, jamais bloquant</b>, même montage que le producteur
     * voisin : transaction propre côté adaptateur, valeurs simples à la
     * frontière, exception avalée et journalisée. La correction d'une session
     * QCM est déterministe ; rien de ce qui alimente une projection ne doit
     * pouvoir la faire échouer.
     */
    private void recordProgression(Attempt attempt, List<AttemptQuestion> aqs) {
        if (attempt.getModule() != Module.TCF || attempt.getUser() == null || aqs.isEmpty()) {
            return;
        }
        try {
            List<ReponseQcm> reponses = aqs.stream()
                    .map(aq -> new ReponseQcm(
                            aq.getQuestion().getId(),
                            aq.getQuestion().getQuestionType(),
                            aq.getQuestion().getDifficulty(),
                            aq.getQuestion().getDifficultyBand(),
                            aq.getQuestion().getChoices().size(),
                            aq.getAnswer() != null,
                            aq.getAnswer() != null
                                    && Boolean.TRUE.equals(aq.getAnswer().getCorrect())))
                    .toList();
            receptiveEvidenceAdapter.ingerer(
                    attempt.getUser().getId(), attempt.getId(), attempt.getFinishedAt(),
                    completionDe(attempt), sourceTypeDe(attempt), entryPointDe(attempt), reponses);
        } catch (RuntimeException echec) {
            log.warn("Progression non alimentée pour la session {} : {}",
                    attempt.getId(), echec.toString());
        }
    }

    /**
     * §23.4 — une session close par le chrono reste <b>qualifiante</b> : les
     * questions non répondues comptent fausses. C'est un examen, pas un
     * entraînement, et le candidat le savait en le lançant.
     */
    private AttemptCompletionStatus completionDe(Attempt attempt) {
        boolean expiree = attempt.getTimeLimitSeconds() != null
                && AttemptChrono.horsDelai(attempt, attempt.getFinishedAt());
        return expiree ? AttemptCompletionStatus.TIME_EXPIRED : AttemptCompletionStatus.SUBMITTED;
    }

    /**
     * §5 — la <b>valeur pédagogique</b> de ce qui a été fait, à ne pas confondre
     * avec le point d'entrée.
     */
    private EvidenceSourceType sourceTypeDe(Attempt attempt) {
        if (attempt.getType() == AttemptType.MOCK_EXAM) {
            return attempt.getParentAttempt() != null
                    ? EvidenceSourceType.FULL_MOCK_EXAM
                    : EvidenceSourceType.DOMAIN_MOCK;
        }
        return EvidenceSourceType.CO_CE_20_SERIES;
    }

    /**
     * 🛑 Trace produit uniquement (§1, T24). Une série lancée depuis « Réviser »
     * vaut exactement autant que la même depuis le Plan : ce champ n'entre dans
     * aucun calcul, et {@code startedFromPlan == true} comme condition
     * d'admission d'une preuve est explicitement interdit.
     */
    private EvidenceEntryPoint entryPointDe(Attempt attempt) {
        if (attempt.getExamTemplate() != null) {
            return EvidenceEntryPoint.DIAGNOSTIC;
        }
        return attempt.getType() == AttemptType.MOCK_EXAM
                ? EvidenceEntryPoint.EXAM_HUB
                : EvidenceEntryPoint.REVISER;
    }

    /**
     * Ce que cette session apprend au Plan sur les competences de COMPREHENSION
     * (CO / CE), ventile par niveau de question.
     *
     * <p><b>Best-effort, jamais bloquant</b> : une session QCM se corrige de
     * facon entierement deterministe, et rien de ce qui alimente le Plan ne doit
     * pouvoir faire echouer cette correction ni la reponse HTTP. Le producteur
     * ecrit dans sa <b>propre</b> transaction
     * ({@code Propagation.REQUIRES_NEW}), donc une violation de contrainte de
     * son cote ne marque pas celle-ci {@code rollback-only} — c'est la raison
     * meme de ce montage, pas un detail. Meme invariant que
     * {@code ProductionPipelineAsyncRunner} pour les productions.
     *
     * <p>Les reponses sont extraites <b>ici</b>, en valeurs simples : la
     * frontiere de transaction est traversee par des donnees, jamais par des
     * entites detachees. 🛑 {@code answered} y est porte <b>separement</b> de
     * {@code correct} : une question laissee vide n'est pas une reponse fausse,
     * et le producteur l'ecarte entierement de la mesure de competence.
     *
     * <p>Appele depuis {@code doFinish} <b>apres</b> le point d'idempotence (une
     * session deja terminee est rendue telle quelle sans repasser ici), donc une
     * seule fois par session dans le cas nominal ; le producteur reste malgre
     * tout idempotent sur {@code (source, attempt)} pour couvrir les rejeux
     * concurrents.
     */
    private void recordComprehension(Attempt attempt, List<AttemptQuestion> aqs) {
        if (attempt.getModule() != Module.TCF || attempt.getUser() == null || aqs.isEmpty()) {
            return;
        }
        try {
            List<ReponseComprehension> reponses = aqs.stream()
                    .map(aq -> new ReponseComprehension(
                            aq.getQuestion().getQuestionType(),
                            aq.getQuestion().getDifficulty(),
                            aq.getAnswer() != null,
                            aq.getAnswer() != null
                                    && Boolean.TRUE.equals(aq.getAnswer().getCorrect())))
                    .toList();
            Set<UUID> competences = comprehensionObservationService.record(
                    attempt.getUser().getId(), attempt.getId(), attempt.getFinishedAt(), reponses);
            porterAuParcours(attempt, competences);
        } catch (RuntimeException echec) {
            log.warn("Observations CO/CE non enregistrees pour la session {} : {}",
                    attempt.getId(), echec.toString());
        }
    }

    /**
     * Ce que cette session apprend au <b>cycle civique</b>, par <b>unite
     * officielle</b> (D-48, D-49).
     *
     * <p>🛑 <b>L'unite est resolue chez son autorite unique</b> —
     * {@code CivicExamCompositionService.uniteOfficielle} —, celle qui compose
     * deja les examens. Une seconde version ici aurait fait ranger une question
     * dans deux unites differentes selon qu'on la <b>tire</b> ou qu'on la
     * <b>mesure</b> : des verdicts faux, sans jamais lever.
     *
     * <p>🛑 <b>La SOURCE distingue la serie de l'examen</b>, et c'est opposable :
     * {@code JourneyEvaluationFilter} en deduit qu'une serie <b>n'evalue pas</b>
     * (R3), donc qu'elle n'alimente jamais le cycle en attente.
     *
     * <p><b>Best-effort</b>, comme la comprehension : le producteur ecrit dans sa
     * propre transaction, et son echec n'emporte ni la correction ni la reponse
     * HTTP. ⚠️ C'est aussi {@code DETTE-M1} : l'echec est <b>avale</b>, donc
     * toute contrainte ajoutee ici se verifie <b>en base</b>, pas au vert des
     * tests.
     */
    private void recordCivique(Attempt attempt, List<AttemptQuestion> aqs) {
        if (attempt.getModule() != Module.CIVIQUE || attempt.getUser() == null || aqs.isEmpty()) {
            return;
        }
        UUID userId = attempt.getUser().getId();
        try {
            LearningPlanSourceType source = attempt.getType() == AttemptType.MOCK_EXAM
                    ? LearningPlanSourceType.CIVIQUE_EXAMEN
                    : LearningPlanSourceType.CIVIQUE_SERIE;
            List<ReponseCivique> reponses = aqs.stream()
                    .map(aq -> new ReponseCivique(
                            uniteDe(aq),
                            aq.getAnswer() != null,
                            aq.getAnswer() != null
                                    && Boolean.TRUE.equals(aq.getAnswer().getCorrect())))
                    .toList();
            Set<UUID> unites = civicObservationService.record(
                    userId, attempt.getId(), source, attempt.getFinishedAt(), reponses);

            if (source == LearningPlanSourceType.CIVIQUE_SERIE) {
                journeyService.onTrainingProgressCivique(userId, unites);
            } else {
                journeyService.onAssessmentCompleted(userId, evaluationCivique(attempt));
            }
        } catch (RuntimeException echec) {
            log.warn("Observations civiques non enregistrees pour la session {} : {}",
                    attempt.getId(), echec.toString());
        }
    }

    /**
     * <b>🛑 TROIS PASSATIONS CIVIQUES, TROIS NATURES</b> — et les deux
     * discriminants sont <b>deja persistes sur l'attempt</b>, poses a sa
     * creation (A74). Aucun n'est deduit : ni le template relu, ni les questions
     * recomptees, ni le score regarde. Une seconde definition de « quel examen
     * est-ce » aurait pu diverger de la premiere.
     *
     * <ol>
     *   <li>{@code civic_diagnostic_id} non nul ⇒ <b>diagnostic civique</b>. Il
     *       ne mesure aucune thematique : il <b>peuple</b> le cycle et ne clot
     *       aucun examen (pendant civique de R11). 🛑 Son identite est celle de
     *       la <b>SESSION</b>, pas celle de l'attempt — c'est ce que dit
     *       {@code JourneyAssessmentKind} : la nature dit de quelle table vient
     *       l'identifiant (A08), et {@code CIVIC_DIAGNOSTIC} designe
     *       {@code civic_diagnostic_sessions}.</li>
     *   <li>{@code lot_theme_id} non nul ⇒ <b>examen de theme</b> : il mesure SA
     *       thematique.</li>
     *   <li>ni l'un ni l'autre ⇒ <b>examen complet</b> : un fait GLOBAL, qui
     *       clot chaque bloc debloque (D-51).</li>
     * </ol>
     *
     * <p>⚠️ <b>Le diagnostic se teste EN PREMIER</b>, et pas pour l'elegance :
     * il porte {@code MOCK_EXAM} <b>sans</b> {@code lot_theme_id}, donc il
     * tombait exactement dans la branche « examen complet » — c'est tout le
     * defaut. Les trois cas restent exclusifs (un diagnostic n'a jamais de
     * {@code lot_theme_id}), l'ordre le rend seulement lisible.
     *
     * <p>🛑 <b>Zero requete de plus</b> : {@code civicDiagnostic} est un
     * {@code @ManyToOne(LAZY)} dont la cle etrangere est <b>sur la ligne
     * {@code attempts} deja chargee</b>. Hibernate rend un proxy non initialise
     * et {@code getId()} lit son identifiant sans toucher la base — exactement
     * comme {@code getLotThemeId()} lit une colonne.
     */
    private JourneyEvaluation evaluationCivique(Attempt attempt) {
        CivicDiagnosticSession diagnostic = attempt.getCivicDiagnostic();
        if (diagnostic != null) {
            return JourneyEvaluation.diagnosticCivique(
                    diagnostic.getId(), attempt.getFinishedAt());
        }
        if (attempt.getLotThemeId() != null) {
            return JourneyEvaluation.examenDeTheme(
                    attempt.getId(), attempt.getLotThemeId(), attempt.getFinishedAt());
        }
        return JourneyEvaluation.examenCivique(attempt.getId(), attempt.getFinishedAt());
    }

    /** L'unite officielle de cette question, ou {@code null} hors programme. */
    private UUID uniteDe(AttemptQuestion aq) {
        CivicOfficialUnit unite = civicCompositionService.uniteOfficielle(aq.getQuestion());
        return unite == null ? null : unite.getId();
    }

    /**
     * Ce que cette session apprend au <b>parcours TCF</b> (spec §7.2 / §7.3).
     *
     * <p>🛑 <b>Le branchement est ICI, apres l'ecriture des observations</b>, et
     * pas plus haut : en comprehension, la competence travaillee est
     * <b>derivee du contenu des questions</b> par
     * {@code ComprehensionObservationService} — {@code doFinish} ne la connait
     * pas. Le parcours avance donc sur ce qui a <b>reellement</b> ete observe.
     *
     * <p>🛑 <b>R1 (arbitrage D-6) passe par le TYPE de la session</b>, et c'est
     * tout ce qui distingue les deux appels :
     * <ul>
     *   <li>{@code MOCK_EXAM} ⇒ une <b>evaluation</b> : elle peut clore un lot et
     *       en creer un nouveau (R7) ;</li>
     *   <li>{@code TRAINING} / {@code REVIEW} ⇒ un <b>entrainement</b> : il fait
     *       avancer ou clot une etape existante, il n'en cree <b>jamais</b>.</li>
     * </ul>
     * Le producteur d'observations, lui, ne fait pas cette difference — « en
     * comprehension, une bonne reponse est une bonne reponse » (2026-08-21), et
     * ca ne change pas.
     *
     * <p><b>Best-effort</b>, comme tout ce qui entoure la correction : le
     * parcours ecrit dans sa propre transaction et son echec est avale ici. La
     * correction du QCM et la reponse HTTP n'en dependent pas.
     */
    private void porterAuParcours(Attempt attempt, Set<UUID> competences) {
        UUID userId = attempt.getUser().getId();
        try {
            // 🛑 SEULES LES QUATRE EPREUVES DU TCF IRN SONT DES EVALUATIONS.
            // `TCF_STRUCTURE` est un module d'entrainement complementaire — pas
            // une cinquieme epreuve — et `TCF_COMPLET` un conteneur : aucun des
            // deux ne porte de niveau d'epreuve. Un examen blanc STRUCTURE
            // arrivait ici en MOCK_EXAM et faisait echouer l'enregistrement de
            // l'evaluation contre `chk_journey_assessment_exam_type`, en
            // silence (l'exception est avalee juste en dessous). L'autorite de
            // « est-ce une epreuve ? » est `TcfDomaine.section`, jamais une
            // liste recopiee.
            boolean epreuveDuTcfIrn = TcfDomaine.section(attempt.getEpreuve()) != null;
            if (attempt.getType() == AttemptType.MOCK_EXAM && epreuveDuTcfIrn) {
                journeyService.onAssessmentCompleted(userId, new JourneyEvaluation(
                        attempt.getId(),
                        JourneyProductionBridge.natureDeLEvaluation(attempt),
                        attempt.getEpreuve(), attempt.getFinishedAt()));
            } else if (!competences.isEmpty()) {
                journeyService.onTrainingProgress(userId, competences);
            }
        } catch (RuntimeException echec) {
            log.warn("Parcours TCF non mis a jour pour la session {} : {}",
                    attempt.getId(), echec.toString());
        }
    }


    private Attempt loadAndCheck(UUID userId, UUID attemptId) {
        Attempt attempt = attemptManager.findById(attemptId)
                .orElseThrow(() -> new EntityNotFoundException("Session introuvable"));
        // Un attempt sans user (demo guest, cf. PublicAttemptService) ne peut
        // pas appartenir a un user connecte.
        if (attempt.getUser() == null || !attempt.getUser().getId().equals(userId)) {
            throw new AccessDeniedException("Cette session ne vous appartient pas");
        }
        return attempt;
    }
}
