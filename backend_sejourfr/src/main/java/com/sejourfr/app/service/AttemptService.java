package com.sejourfr.app.service;

import com.sejourfr.app.dto.AnswerResultResponse;
import com.sejourfr.app.dto.AttemptResponse;
import com.sejourfr.app.dto.AttemptSummaryResponse;
import com.sejourfr.app.dto.ProductionAttemptStartRequest;
import com.sejourfr.app.dto.StartAttemptRequest;
import com.sejourfr.app.dto.SubmitAnswerRequest;
import com.sejourfr.app.entity.Answer;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.AttemptQuestion;
import com.sejourfr.app.entity.Choice;
import com.sejourfr.app.entity.ExamTemplate;
import com.sejourfr.app.entity.ExamTemplateRule;
import com.sejourfr.app.entity.Question;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.AnswerManager;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.AttemptQuestionManager;
import com.sejourfr.app.manager.ExamTemplateManager;
import com.sejourfr.app.manager.QuestionManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.mapper.AttemptMapper;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AttemptService {

    // Fallback historique pour MOCK_EXAM sans ExamTemplate. Quand un template
    // est branche, ces valeurs viennent du template (durationSeconds, totalQuestions, passingScore).
    private static final int CIVIQUE_EXAM_SIZE = 40;
    private static final int CIVIQUE_EXAM_TIME = 45 * 60;
    private static final int CIVIQUE_EXAM_THRESHOLD = 32;

    // Examen civique scopé à un thème (lancé depuis l'onglet Examens du
    // détail thème). 20 questions du thème en 20 min, seuil 16/20.
    private static final int CIVIQUE_THEME_EXAM_SIZE = 20;
    private static final int CIVIQUE_THEME_EXAM_TIME = 20 * 60;
    private static final int CIVIQUE_THEME_EXAM_THRESHOLD = 16;

    private static final int TCF_EXAM_SIZE = 60;
    private static final int TCF_EXAM_TIME = 90 * 60;

    // Seuil de reussite par strate pour le calcul du niveau CECRL en TCF.
    // L'utilisateur "atteint" un niveau si son taux de bonnes reponses sur les
    // questions de ce niveau est >= 60 %.
    private static final double TCF_LEVEL_PASS_RATIO = 0.6;

    // Plafond d'entrainement TRAINING pour les comptes gratuits.
    private static final int FREE_TRAINING_MAX_SIZE = 20;
    private static final int PREMIUM_TRAINING_MAX_SIZE = 50;
    private static final int DEFAULT_TRAINING_SIZE = 10;

    private static final int LIST_LIMIT_MIN = 1;
    private static final int LIST_LIMIT_MAX = 100;

    // Composition d'un examen module TCF QCM : 8 A2 + 9 B1 + 8 B2 = 25 questions
    // progressives. Cf. StartAttemptRequest doc + AttemptService.startModuleExam.
    private static final int MODULE_EXAM_A2 = 8;
    private static final int MODULE_EXAM_B1 = 9;
    private static final int MODULE_EXAM_B2 = 8;
    private static final int MODULE_EXAM_TOTAL = MODULE_EXAM_A2 + MODULE_EXAM_B1 + MODULE_EXAM_B2;

    // Durée des examens module — Compréhension orale 20 min, écrite 35 min en
    // standalone. En examen blanc complet (TCF_COMPLET), CE est raccourci à
    // 30 min pour tenir dans l'enveloppe globale de 90 min.
    private static final int MODULE_EXAM_CO_SECONDS = 20 * 60;
    private static final int MODULE_EXAM_CE_SECONDS = 35 * 60;
    private static final int MODULE_EXAM_STRUCTURE_SECONDS = 20 * 60;
    private static final int FULL_EXAM_CE_SECONDS = 30 * 60;

    // Pondération du score par niveau (A2=1, B1=2, B2=3) — applique à la finalisation
    // d'un examen module. Max score = 8*1 + 9*2 + 8*3 = 50.
    private static final int WEIGHT_A2 = 1;
    private static final int WEIGHT_B1 = 2;
    private static final int WEIGHT_B2 = 3;

    private final AttemptManager attemptManager;
    private final AttemptQuestionManager attemptQuestionManager;
    private final AnswerManager answerManager;
    private final QuestionManager questionManager;
    private final UserManager userManager;
    private final ExamTemplateManager examTemplateManager;
    private final SubscriptionService subscriptionService;
    private final LotService lotService;
    private final AttemptMapper mapper;

    // ------------------------------------------------------------------------
    // Creation : utilisateur connecte
    // ------------------------------------------------------------------------

    @Transactional
    public AttemptResponse start(UUID userId, StartAttemptRequest req) {
        User user = userManager.findById(userId)
                .orElseThrow(() -> new EntityNotFoundException("User introuvable"));

        // Branche template : si un examTemplateId est fourni, c'est lui qui pilote
        // la config (duree, taille, seuil) et la composition (rules).
        if (req.examTemplateId() != null) {
            ExamTemplate template = examTemplateManager.findById(req.examTemplateId())
                    .orElseThrow(() -> new EntityNotFoundException("Examen blanc introuvable"));
            return startFromTemplate(user, template);
        }

        // Branche lot : si lotNumero est fourni, on retire la fenetre exacte du
        // pool filtre (module + difficulty + questionType) en tri stable. Cf. LotService.
        if (req.lotNumero() != null) {
            return startFromLot(user, req);
        }

        // Branche examen module : si moduleExamQuestionType est fourni, on tire
        // 8 A2 + 9 B1 + 8 B2 progressif dans l'epreuve concernee (CO, CE ou STRUCTURE).
        if (req.moduleExamQuestionType() != null) {
            return startModuleExam(user, req);
        }

        // Branche legacy : MOCK_EXAM sans template, TRAINING, REVIEW.
        boolean demoMode = req.type() == AttemptType.TRAINING && !subscriptionService.isPremium(userId);

        int size;
        Integer timeLimit = null;
        Integer threshold = null;

        // Civic MOCK_EXAM scopé à un thème (20 Q de ce thème) vs global
        // (40 Q tous thèmes). Détecté via `themeId` côté request.
        boolean civicThemeExam = req.type() == AttemptType.MOCK_EXAM
                && req.module() == Module.CIVIQUE
                && req.themeId() != null;

        if (req.type() == AttemptType.MOCK_EXAM) {
            if (req.module() == Module.CIVIQUE) {
                if (civicThemeExam) {
                    size = CIVIQUE_THEME_EXAM_SIZE;
                    timeLimit = CIVIQUE_THEME_EXAM_TIME;
                    threshold = CIVIQUE_THEME_EXAM_THRESHOLD;
                } else {
                    size = CIVIQUE_EXAM_SIZE;
                    timeLimit = CIVIQUE_EXAM_TIME;
                    threshold = CIVIQUE_EXAM_THRESHOLD;
                }
            } else {
                size = TCF_EXAM_SIZE;
                timeLimit = TCF_EXAM_TIME;
            }
        } else {
            int requested = req.size() != null ? req.size() : DEFAULT_TRAINING_SIZE;
            int hardMax = demoMode ? FREE_TRAINING_MAX_SIZE : PREMIUM_TRAINING_MAX_SIZE;
            size = Math.clamp(requested, 1, hardMax);
        }

        List<Question> questions;
        if (demoMode) {
            // Pool fixe par module : meme serie a chaque rejouage (cf. retrait
            // du quota guest 2026-05-17).
            questions = questionManager.findDemoPool(req.module(), size);
        } else {
            // Pour un examen civique theme-scopé, on garde le themeId — sinon
            // règle historique : pas de themeId sur MOCK_EXAM (tous thèmes).
            UUID themeId;
            if (civicThemeExam) {
                themeId = req.themeId();
            } else if (req.type() == AttemptType.MOCK_EXAM) {
                themeId = null;
            } else {
                themeId = req.themeId();
            }
            var qType = req.type() == AttemptType.MOCK_EXAM ? null : req.questionType();
            Difficulty effectiveDifficulty = resolveDifficulty(user, req.module(), req.difficulty());
            questions = questionManager.findRandom(req.module(), themeId, effectiveDifficulty, qType, size);
        }

        if (questions.isEmpty()) {
            throw new IllegalStateException("Aucune question disponible pour ces critères");
        }

        Attempt attempt = new Attempt();
        attempt.setUser(user);
        attempt.setType(req.type());
        attempt.setModule(req.module());
        attempt.setTotalQuestions(questions.size());
        attempt.setTimeLimitSeconds(timeLimit);
        attempt.setPassThreshold(threshold);
        attempt.setStartedAt(Instant.now());
        // Pour l'examen civique theme-scopé, on réutilise `lot_theme_id`
        // comme colonne de scoping de l'attempt (l'index existant suffit pour
        // filtrer l'historique par thème côté `MeAttemptsController`).
        if (civicThemeExam) {
            attempt.setLotThemeId(req.themeId());
        }
        attempt = attemptManager.save(attempt);

        List<AttemptQuestion> aqList = persistAttemptQuestions(attempt, questions);
        return mapper.toResponse(attempt, aqList, false);
    }

    /**
     * Cree un attempt vide pour une epreuve productive (TCF_EO / TCF_EE / TCF_COMPLET).
     * Pas de questions piochees : les productions sont rattachees ensuite via
     * {@code production_submissions.attempt_id}.
     *
     * <p>Pour un entrainement isole, {@code parentAttemptId} est null. Pour les
     * sous-attempts d'un examen blanc TCF complet, on vise le parent existant
     * (qui doit lui-meme porter {@code epreuve = TCF_COMPLET}).
     */
    @Transactional
    public AttemptResponse startProductionAttempt(UUID userId, ProductionAttemptStartRequest req) {
        if (!isProductionEpreuve(req.epreuve())) {
            throw new BusinessException("epreuve doit etre TCF_EO, TCF_EE ou TCF_COMPLET.");
        }
        if (req.module() != Module.TCF) {
            throw new BusinessException("Les epreuves productives sont reservees au module TCF.");
        }

        User user = userManager.findById(userId)
                .orElseThrow(() -> new NotFoundException("User introuvable : " + userId));

        Attempt parent = resolveParentAttempt(userId, req.parentAttemptId());

        Attempt attempt = new Attempt();
        attempt.setUser(user);
        attempt.setType(AttemptType.TRAINING);
        attempt.setModule(req.module());
        attempt.setEpreuve(req.epreuve());
        attempt.setParentAttempt(parent);
        attempt.setStartedAt(Instant.now());
        // Pas de QCM -> totalQuestions / timeLimit / threshold restent null.
        attempt = attemptManager.save(attempt);
        return mapper.toResponse(attempt, List.of(), false);
    }

    private Attempt resolveParentAttempt(UUID userId, UUID parentAttemptId) {
        if (parentAttemptId == null) return null;

        Attempt parent = attemptManager.findById(parentAttemptId)
                .orElseThrow(() -> new NotFoundException("Parent attempt introuvable : " + parentAttemptId));
        if (parent.getUser() == null || !parent.getUser().getId().equals(userId)) {
            throw new AccessDeniedException("Parent attempt n'appartient pas a l'utilisateur courant.");
        }
        if (parent.getEpreuve() != EpreuveType.TCF_COMPLET) {
            throw new BusinessException(
                    "parent_attempt_id doit pointer sur un attempt TCF_COMPLET (recu : " + parent.getEpreuve() + ").");
        }
        return parent;
    }

    // ------------------------------------------------------------------------
    // Creation : visiteur guest (demo non authentifiee)
    // ------------------------------------------------------------------------

    /**
     * Demarre un attempt "demo guest" (visiteur non authentifie, cf.
     * PublicAttemptService). La taille / duree sont fixees comme pour le mode
     * demo des comptes gratuits.
     * <p>
     * La demo etant desormais illimitee, on presente toujours la meme serie
     * deterministe — pour conversion, pas entrainement.
     */
    @Transactional
    public AttemptResponse startGuestDemo(StartAttemptRequest req, String clientIp) {
        // Validation du type (TRAINING / MOCK_EXAM) faite cote PublicAttemptService.
        int size;
        Integer timeLimit = null;
        Integer threshold = null;
        List<Question> questions;
        ExamTemplate template = null;

        if (req.type() == AttemptType.MOCK_EXAM) {
            if (req.examTemplateId() != null) {
                template = examTemplateManager.findById(req.examTemplateId())
                        .orElseThrow(() -> new EntityNotFoundException("Examen blanc introuvable"));
                if (!template.isPublished() || !template.isFree()) {
                    throw new AccessDeniedException("Examen blanc non disponible en démo");
                }
                size = template.getTotalQuestions();
                timeLimit = template.getDurationSeconds();
                threshold = template.getPassingScore();
                // Guest sur template free : tirage deterministe.
                questions = pickQuestionsForTemplate(template, true);
            } else {
                if (req.module() == Module.CIVIQUE) {
                    size = CIVIQUE_EXAM_SIZE;
                    timeLimit = CIVIQUE_EXAM_TIME;
                    threshold = CIVIQUE_EXAM_THRESHOLD;
                } else {
                    size = TCF_EXAM_SIZE;
                    timeLimit = TCF_EXAM_TIME;
                }
                questions = questionManager.findDemoPool(req.module(), size);
            }
        } else {
            size = FREE_TRAINING_MAX_SIZE;
            questions = questionManager.findDemoPool(req.module(), size);
        }

        if (questions.isEmpty()) {
            throw new IllegalStateException("Aucune question disponible pour ces critères");
        }

        Attempt attempt = new Attempt();
        // user = null (guest)
        attempt.setClientIp(clientIp);
        attempt.setExamTemplate(template);
        attempt.setType(req.type());
        attempt.setModule(req.module());
        attempt.setTotalQuestions(questions.size());
        attempt.setTimeLimitSeconds(timeLimit);
        attempt.setPassThreshold(threshold);
        attempt.setStartedAt(Instant.now());
        attempt = attemptManager.save(attempt);

        List<AttemptQuestion> aqList = persistAttemptQuestions(attempt, questions);
        return mapper.toResponse(attempt, aqList, false);
    }

    /**
     * Demarre un examen blanc a partir d'un ExamTemplate publie. La composition
     * derive des ExamTemplateRule (theme + difficulte + type + count). Si les
     * regles ne suffisent pas a remplir totalQuestions, on complete par un
     * tirage libre dans le module (jamais de doublon intra-attempt).
     */
    private AttemptResponse startFromTemplate(User user, ExamTemplate template) {
        if (!template.isPublished()) {
            throw new AccessDeniedException("Examen blanc non disponible");
        }
        if (!template.isFree() && !subscriptionService.isPremium(user.getId())) {
            throw new AccessDeniedException("Examen blanc réservé aux abonnés");
        }

        // Premium : tirage aleatoire (variete). Non-premium sur template free :
        // tirage deterministe (regle demo "memes questions a chaque lancement").
        boolean deterministic = template.isFree() && !subscriptionService.isPremium(user.getId());
        List<Question> picked = pickQuestionsForTemplate(template, deterministic);
        if (picked.isEmpty()) {
            throw new IllegalStateException("Aucune question disponible pour cet examen blanc");
        }

        Attempt attempt = new Attempt();
        attempt.setUser(user);
        attempt.setExamTemplate(template);
        attempt.setType(AttemptType.MOCK_EXAM);
        attempt.setModule(template.getModule());
        attempt.setTotalQuestions(picked.size());
        attempt.setTimeLimitSeconds(template.getDurationSeconds());
        // En TCF on garde passingScore en base (0 par convention) : l'evaluation
        // cote front s'appuie sur levelAchieved, pas sur ce seuil.
        attempt.setPassThreshold(template.getPassingScore());
        attempt.setStartedAt(Instant.now());
        attempt = attemptManager.save(attempt);

        List<AttemptQuestion> aqList = persistAttemptQuestions(attempt, picked);
        return mapper.toResponse(attempt, aqList, false);
    }

    /**
     * Demarre un attempt TRAINING sur un lot precis. La taille de la fenetre
     * est resolue par {@link LotService#resolveLotSize} pour rester aligne
     * avec ce que `/api/lots` expose au front (y compris le cas d'un lot
     * partiel quand le pool est sous la taille standard).
     *
     * <p>Reserve aux comptes premium pour le module concerne — le filtre n'a
     * pas de sens en demo (le backend ignore les filtres en demo).
     */
    private AttemptResponse startFromLot(User user, StartAttemptRequest req) {
        if (req.type() != AttemptType.TRAINING) {
            throw new BusinessException("Les lots sont reserves au type TRAINING.");
        }
        if (!subscriptionService.isPremium(user.getId())) {
            throw new AccessDeniedException("Les lots cibles sont reserves aux abonnes.");
        }
        if (req.module() == Module.CIVIQUE) {
            return startCiviqueLot(user, req);
        }
        if (req.module() != Module.TCF) {
            throw new BusinessException("Module non supporte pour les lots : " + req.module());
        }
        if (req.difficulty() == null) {
            throw new BusinessException("difficulty est obligatoire pour un lot TCF (A2/B1/B2).");
        }

        int effectiveSize = lotService.resolveLotSize(
                req.module(), req.questionType(), req.difficulty(), req.lotNumero());

        List<Question> questions = questionManager.findLotQuestions(
                req.module(), req.questionType(), req.difficulty(), req.lotNumero(), effectiveSize);

        if (questions.isEmpty()) {
            // Cas defensif : LotService a valide la fenetre, mais aucune question
            // ne ressort — peut arriver si le pool change entre les deux appels.
            throw new BusinessException("Lot " + req.lotNumero() + " indisponible pour ces criteres.");
        }

        Attempt attempt = new Attempt();
        attempt.setUser(user);
        attempt.setType(AttemptType.TRAINING);
        attempt.setModule(req.module());
        attempt.setTotalQuestions(questions.size());
        attempt.setStartedAt(Instant.now());
        // Trace du lot d'origine : permet a `GET /api/lots` d'enrichir chaque
        // lot avec le dernier score de l'utilisateur (cf. AttemptManager.findLastFinishedByLots).
        attempt.setLotNumero(req.lotNumero());
        attempt.setLotQuestionType(req.questionType());
        attempt.setLotDifficulty(req.difficulty());
        attempt = attemptManager.save(attempt);

        List<AttemptQuestion> aqList = persistAttemptQuestions(attempt, questions);
        return mapper.toResponse(attempt, aqList, false);
    }

    /**
     * Variante Civique : pas de difficulty / questionType, le lot est porté
     * par {@code themeId} (fenêtre de 15 questions sur le pool actif du thème,
     * tri stable identique à {@link LotService#listCivique}).
     */
    private AttemptResponse startCiviqueLot(User user, StartAttemptRequest req) {
        if (req.themeId() == null) {
            throw new BusinessException("themeId est obligatoire pour un lot Civique.");
        }

        int effectiveSize = lotService.resolveLotSizeCivique(req.themeId(), req.lotNumero());

        List<Question> questions = questionManager.findLotQuestionsCivique(
                req.themeId(), req.lotNumero(), effectiveSize);

        if (questions.isEmpty()) {
            throw new BusinessException("Lot " + req.lotNumero() + " indisponible pour ce thème.");
        }

        Attempt attempt = new Attempt();
        attempt.setUser(user);
        attempt.setType(AttemptType.TRAINING);
        attempt.setModule(Module.CIVIQUE);
        attempt.setTotalQuestions(questions.size());
        attempt.setStartedAt(Instant.now());
        attempt.setLotNumero(req.lotNumero());
        attempt.setLotThemeId(req.themeId());
        attempt = attemptManager.save(attempt);

        List<AttemptQuestion> aqList = persistAttemptQuestions(attempt, questions);
        return mapper.toResponse(attempt, aqList, false);
    }

    /**
     * Demarre un examen blanc scope a une epreuve TCF QCM (CO, CE ou
     * STRUCTURE). Composition : 8 A2 + 9 B1 + 8 B2 progressifs (constantes
     * MODULE_EXAM_*), tire aleatoirement dans le pool filtre par module +
     * questionType. Si une strate est trop petite, on complete avec les
     * niveaux voisins pour atteindre 25 questions au total (fallback).
     *
     * <p>STRUCTURE est un module bonus (hors TCF IRN officiel), inclus ici
     * pour exposer la meme experience d'examen blanc que CO/CE cote mobile.
     * Duree : 20 min (alignee sur CO). N'apparait jamais en sous-attempt
     * d'un examen blanc complet TCF_COMPLET — cf. {@link #startModuleExamSubAttempt}.
     *
     * <p>Reserve aux comptes premium TCF. Sur 403 le front affiche le paywall.
     */
    private AttemptResponse startModuleExam(User user, StartAttemptRequest req) {
        if (req.type() != AttemptType.MOCK_EXAM) {
            throw new BusinessException("moduleExamQuestionType implique type=MOCK_EXAM.");
        }
        if (req.module() != Module.TCF) {
            throw new BusinessException("Les examens module sont reserves au module TCF.");
        }
        QuestionType qType = req.moduleExamQuestionType();
        if (qType != QuestionType.CO && qType != QuestionType.CE && qType != QuestionType.STRUCTURE) {
            throw new BusinessException("moduleExamQuestionType doit etre CO, CE ou STRUCTURE.");
        }
        if (!subscriptionService.isPremium(user.getId())) {
            throw new AccessDeniedException("Les examens module sont reserves aux abonnes.");
        }

        List<Question> picked = composeModuleExam(req.module(), qType);
        if (picked.isEmpty()) {
            throw new BusinessException("Aucune question disponible pour cet examen module.");
        }

        int timeLimit = switch (qType) {
            case CO -> MODULE_EXAM_CO_SECONDS;
            case CE -> MODULE_EXAM_CE_SECONDS;
            case STRUCTURE -> MODULE_EXAM_STRUCTURE_SECONDS;
            default -> throw new BusinessException("qType non supporte pour examen module : " + qType);
        };

        Attempt attempt = new Attempt();
        attempt.setUser(user);
        attempt.setType(AttemptType.MOCK_EXAM);
        attempt.setModule(req.module());
        attempt.setModuleExamQuestionType(qType);
        attempt.setTotalQuestions(picked.size());
        attempt.setTimeLimitSeconds(timeLimit);
        attempt.setStartedAt(Instant.now());
        attempt = attemptManager.save(attempt);

        List<AttemptQuestion> aqList = persistAttemptQuestions(attempt, picked);
        return mapper.toResponse(attempt, aqList, false);
    }

    /**
     * Variante de {@link #startModuleExam} pour les sous-attempts d'un examen
     * blanc TCF complet (parent TCF_COMPLET). Skip le check premium (l'accès
     * est porté par le parent), pose {@code parent_attempt_id} et applique la
     * durée full-exam pour CE (30 min au lieu de 35).
     *
     * <p>Réservé à {@link FullTcfExamService} qui valide l'access avant l'appel.
     */
    @Transactional
    public AttemptResponse startModuleExamSubAttempt(User user, QuestionType qType, Attempt parent) {
        if (qType != QuestionType.CO && qType != QuestionType.CE) {
            throw new BusinessException("qType doit être CO ou CE pour un sous-attempt examen module.");
        }
        if (parent == null || parent.getEpreuve() != EpreuveType.TCF_COMPLET) {
            throw new BusinessException("parent doit être un attempt TCF_COMPLET.");
        }

        List<Question> picked = composeModuleExam(Module.TCF, qType);
        if (picked.isEmpty()) {
            throw new BusinessException("Aucune question disponible pour le sous-attempt " + qType + ".");
        }

        int timeLimit = qType == QuestionType.CO ? MODULE_EXAM_CO_SECONDS : FULL_EXAM_CE_SECONDS;

        Attempt attempt = new Attempt();
        attempt.setUser(user);
        attempt.setType(AttemptType.MOCK_EXAM);
        attempt.setModule(Module.TCF);
        attempt.setEpreuve(qType == QuestionType.CO ? EpreuveType.TCF_CO : EpreuveType.TCF_CE);
        attempt.setParentAttempt(parent);
        attempt.setModuleExamQuestionType(qType);
        attempt.setTotalQuestions(picked.size());
        attempt.setTimeLimitSeconds(timeLimit);
        attempt.setStartedAt(Instant.now());
        attempt = attemptManager.save(attempt);

        List<AttemptQuestion> aqList = persistAttemptQuestions(attempt, picked);
        return mapper.toResponse(attempt, aqList, false);
    }

    /**
     * Compose la liste des 25 questions d'un examen module en suivant les
     * proportions A2/B1/B2 et en evitant les doublons. Tire aleatoirement
     * dans chaque strate, puis complete par un tirage libre si une strate
     * est sous-dotee (fallback).
     */
    private List<Question> composeModuleExam(Module module, QuestionType questionType) {
        LinkedHashSet<Question> picked = new LinkedHashSet<>();
        List<UUID> exclude = new ArrayList<>();
        addStrata(picked, exclude, module, questionType, Difficulty.A2, MODULE_EXAM_A2);
        addStrata(picked, exclude, module, questionType, Difficulty.B1, MODULE_EXAM_B1);
        addStrata(picked, exclude, module, questionType, Difficulty.B2, MODULE_EXAM_B2);

        int missing = MODULE_EXAM_TOTAL - picked.size();
        if (missing > 0) {
            // Fallback : on complete sans contrainte de niveau si une strate
            // etait sous-dotee. Garantit qu'on serve quand meme un examen
            // utile plutot que d'en refuser le demarrage.
            List<Question> extra = questionManager.findRandomExcluding(
                    module, null, null, questionType, exclude, missing);
            for (Question q : extra) {
                if (picked.add(q)) exclude.add(q.getId());
            }
        }
        return new ArrayList<>(picked);
    }

    private void addStrata(
            LinkedHashSet<Question> picked, List<UUID> exclude,
            Module module, QuestionType questionType, Difficulty difficulty, int count) {
        List<Question> drawn = questionManager.findRandomExcluding(
                module, null, difficulty, questionType, exclude, count);
        for (Question q : drawn) {
            if (picked.add(q)) exclude.add(q.getId());
        }
    }

    /**
     * Pioche les questions d'un ExamTemplate en suivant ses regles.
     *
     * @param deterministic si vrai, ordre stable {@code created_at ASC, id ASC}
     *                      au lieu de {@code random()} — utilise pour la demo
     *                      (guest ou non-premium sur template free) afin que
     *                      rejouer redonne toujours la meme serie.
     */
    private List<Question> pickQuestionsForTemplate(ExamTemplate template, boolean deterministic) {
        LinkedHashSet<Question> picked = new LinkedHashSet<>();
        List<UUID> exclude = new ArrayList<>();

        // Regles ordonnees par position (@OrderBy porte par l'entite).
        for (ExamTemplateRule rule : template.getRules()) {
            int needed = rule.getQuestionCount();
            if (needed <= 0) continue;

            UUID themeId = rule.getTheme() != null ? rule.getTheme().getId() : null;
            List<Question> drawn = deterministic
                    ? questionManager.findOrderedExcluding(
                            template.getModule(), themeId, rule.getDifficulty(),
                            rule.getQuestionType(), exclude, needed)
                    : questionManager.findRandomExcluding(
                            template.getModule(), themeId, rule.getDifficulty(),
                            rule.getQuestionType(), exclude, needed);
            for (Question q : drawn) {
                if (picked.add(q)) exclude.add(q.getId());
            }
        }

        // Fallback : si les regles n'ont pas comble totalQuestions (stock faible),
        // on complete sans contrainte autre que le module, en evitant les doublons.
        int missing = template.getTotalQuestions() - picked.size();
        if (missing > 0) {
            List<Question> extra = deterministic
                    ? questionManager.findOrderedExcluding(
                            template.getModule(), null, null, null, exclude, missing)
                    : questionManager.findRandomExcluding(
                            template.getModule(), null, null, null, exclude, missing);
            for (Question q : extra) {
                if (picked.add(q)) exclude.add(q.getId());
            }
        }
        return new ArrayList<>(picked);
    }

    private List<AttemptQuestion> persistAttemptQuestions(Attempt attempt, List<Question> questions) {
        List<AttemptQuestion> aqList = new ArrayList<>(questions.size());
        for (int i = 0; i < questions.size(); i++) {
            AttemptQuestion aq = new AttemptQuestion();
            aq.setAttempt(attempt);
            aq.setQuestion(questions.get(i));
            aq.setPosition(i);
            aqList.add(attemptQuestionManager.save(aq));
        }
        return aqList;
    }

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
        return attempts.stream().map(mapper::toSummary).toList();
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

    private AnswerResultResponse doSubmitAnswer(Attempt attempt, SubmitAnswerRequest req) {
        AttemptQuestion aq = attemptQuestionManager.findById(req.attemptQuestionId())
                .orElseThrow(() -> new EntityNotFoundException("Question introuvable dans la session"));

        if (!aq.getAttempt().getId().equals(attempt.getId())) {
            throw new IllegalArgumentException("Cette question n'appartient pas à cette session");
        }

        Question question = aq.getQuestion();
        Set<UUID> correctIds = question.getChoices().stream()
                .filter(Choice::isCorrect)
                .map(Choice::getId)
                .collect(Collectors.toSet());
        Set<UUID> submitted = new HashSet<>(req.choiceIds());
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

        // En entrainement : on renvoie la correction. En examen blanc : on
        // confirme juste l'enregistrement.
        if (attempt.getType() == AttemptType.TRAINING) {
            return new AnswerResultResponse(true, correct, new ArrayList<>(correctIds), question.getExplanation());
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

    private AttemptResponse doFinish(Attempt attempt) {
        UUID attemptId = attempt.getId();
        List<AttemptQuestion> aqs = attemptQuestionManager.findByAttemptOrderedByPosition(attemptId);

        if (attempt.getFinishedAt() != null) {
            // Idempotent : on renvoie l'etat actuel.
            return mapper.toResponse(attempt, aqs, true);
        }

        int score = (int) aqs.stream()
                .filter(aq -> aq.getAnswer() != null && Boolean.TRUE.equals(aq.getAnswer().getCorrect()))
                .count();

        attempt.setFinishedAt(Instant.now());
        attempt.setScore(score);

        // Pour le TCF on calcule en plus le niveau CECRL atteint a partir du
        // taux de reussite par strate A2/B1/B2. Civique : levelAchieved reste null.
        if (attempt.getModule() == Module.TCF) {
            attempt.setLevelAchieved(computeLevelAchieved(aqs));
        }

        // Examen module TCF : on persiste aussi le score pondere par niveau
        // (A2=1, B1=2, B2=3) pour permettre un affichage X/50 cote front sans
        // re-joindre attempt_questions a chaque lecture de l'historique.
        if (attempt.getModuleExamQuestionType() != null) {
            attempt.setWeightedScore(computeWeightedScore(aqs, true));
            attempt.setMaxWeightedScore(computeWeightedScore(aqs, false));
        }

        attemptManager.save(attempt);
        return mapper.toResponse(attempt, aqs, true);
    }

    /**
     * Niveau CECRL atteint : on retient le plus haut niveau A2/B1/B2 ou le
     * taux de bonnes reponses sur les questions de cette strate depasse le
     * seuil {@link #TCF_LEVEL_PASS_RATIO}. Si meme A2 n'est pas atteint,
     * renvoie null.
     */
    private TargetLevel computeLevelAchieved(List<AttemptQuestion> aqs) {
        TargetLevel result = null;
        for (TargetLevel level : List.of(TargetLevel.A2, TargetLevel.B1, TargetLevel.B2)) {
            Difficulty strata = toDifficulty(level);
            long total = aqs.stream()
                    .filter(aq -> aq.getQuestion().getDifficulty() == strata)
                    .count();
            if (total == 0) continue;

            long correct = aqs.stream()
                    .filter(aq -> aq.getQuestion().getDifficulty() == strata)
                    .filter(aq -> aq.getAnswer() != null && Boolean.TRUE.equals(aq.getAnswer().getCorrect()))
                    .count();

            if ((double) correct / total >= TCF_LEVEL_PASS_RATIO) {
                result = level;
            }
        }
        return result;
    }

    private Difficulty toDifficulty(TargetLevel level) {
        return switch (level) {
            case A2 -> Difficulty.A2;
            case B1 -> Difficulty.B1;
            case B2 -> Difficulty.B2;
        };
    }

    /**
     * Calcule le score pondéré d'un examen module en sommant les poids par
     * niveau des questions correctes (si {@code onlyCorrect}) ou de toutes
     * les questions (= max score atteignable). Poids : A2=1, B1=2, B2=3.
     * Les questions sans niveau (rare) sont ignorées.
     */
    private int computeWeightedScore(List<AttemptQuestion> aqs, boolean onlyCorrect) {
        int total = 0;
        for (AttemptQuestion aq : aqs) {
            Difficulty d = aq.getQuestion().getDifficulty();
            if (d == null) continue;
            if (onlyCorrect && (aq.getAnswer() == null || !Boolean.TRUE.equals(aq.getAnswer().getCorrect()))) {
                continue;
            }
            total += switch (d) {
                case A2 -> WEIGHT_A2;
                case B1 -> WEIGHT_B1;
                case B2 -> WEIGHT_B2;
                default -> 0;
            };
        }
        return total;
    }

    // ------------------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------------------

    /**
     * Determine la difficulte a appliquer pour un attempt : la valeur explicite
     * si presente, sinon derivee du parcours vise par l'utilisateur (CIVIQUE
     * uniquement). Le TCF n'est jamais filtre par niveau : le test est unique
     * pour tous, le niveau CECRL est calcule a la finalisation a partir des
     * bonnes reponses par strate A2/B1/B2 dans les questions tirees.
     */
    private Difficulty resolveDifficulty(User user, Module module, Difficulty requested) {
        if (requested != null) return requested;
        if (module == Module.TCF) return null;

        TargetProcedure path = user.getTargetProcedure();
        if (path == null) return null;

        return switch (path) {
            case CSP -> Difficulty.CSP;
            case CR -> Difficulty.CR;
            case NAT -> Difficulty.NAT;
        };
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

    private static boolean isProductionEpreuve(EpreuveType e) {
        return e == EpreuveType.TCF_EO || e == EpreuveType.TCF_EE || e == EpreuveType.TCF_COMPLET;
    }
}
