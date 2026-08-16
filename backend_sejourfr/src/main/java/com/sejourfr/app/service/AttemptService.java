package com.sejourfr.app.service;

import com.sejourfr.app.dto.AnswerResultResponse;
import com.sejourfr.app.dto.AttemptResponse;
import com.sejourfr.app.dto.AttemptSummaryResponse;
import com.sejourfr.app.dto.ProductionAttemptStartRequest;
import com.sejourfr.app.dto.StartAttemptRequest;
import com.sejourfr.app.dto.SubmitAnswerRequest;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.AttemptQuestion;
import com.sejourfr.app.entity.ExamTemplate;
import com.sejourfr.app.entity.Question;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.DureeEpreuve;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.AttemptQuestionManager;
import com.sejourfr.app.manager.ExamTemplateManager;
import com.sejourfr.app.manager.QuestionManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.mapper.AttemptMapper;
import com.sejourfr.app.service.attempt.AttemptCompositionService;
import com.sejourfr.app.service.attempt.AttemptInteractionService;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Façade des attempts QCM / production. Conserve l'API publique historique
 * (controllers + FullTcfExamService) et orchestre le démarrage / dispatch d'un
 * attempt ; délègue la composition des questions à {@link AttemptCompositionService}
 * et le cycle de vie post-start (lecture, soumission, finalisation) à
 * {@link AttemptInteractionService}.
 */
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

    /**
     * Slots de la grille d'examens blancs QCM (cf. V110) : 20 par module,
     * aligné sur les fronts (web {@code SLOTS = 20}, mobile
     * {@code CiviqueFullExamsScreen} / {@code TcfFullExamsScreen}).
     */
    static final int MOCK_EXAM_SLOTS = 20;

    // Plafond d'entrainement TRAINING pour les comptes gratuits.
    private static final int FREE_TRAINING_MAX_SIZE = 20;
    private static final int PREMIUM_TRAINING_MAX_SIZE = 50;
    private static final int DEFAULT_TRAINING_SIZE = 10;

    // Les durées d'épreuve vivent TOUTES dans DureeEpreuve (CO 20 min, CE
    // 35 min partout — y compris en examen complet, STRUCTURE 20 min, EE
    // 30 min, EO chronométrée tâche par tâche). Ne pas en redéclarer ici.

    private final AttemptManager attemptManager;
    private final AttemptQuestionManager attemptQuestionManager;
    private final QuestionManager questionManager;
    private final UserManager userManager;
    private final ExamTemplateManager examTemplateManager;
    private final SubscriptionService subscriptionService;
    private final LotService lotService;
    private final AttemptCompositionService compositionService;
    private final AttemptInteractionService interactionService;
    private final ProductionAccessService productionAccessService;
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
            return startFromTemplate(user, template, req.slotNumber());
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
            // Verrou freemium des examens blancs QCM — MÊME règle que
            // startModuleExam et startFromTemplate : slot 1 offert (et
            // rejouable), slots 2+ réservés aux abonnés du module. Cette
            // branche (examens civiques globaux 40 Q, examens de thème 20 Q,
            // examen TCF 60 Q legacy) ne contrôlait rien : le verrou n'existait
            // que côté client, un compte gratuit pouvait lancer n'importe quel
            // slot en illimité.
            enforceMockExamSlotAccess(userId, req.module(), req.slotNumber(),
                    civicThemeExam ? "de thème " : "");
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
            boolean civiqueFullExam = req.type() == AttemptType.MOCK_EXAM
                    && req.module() == Module.CIVIQUE
                    && themeId == null;
            questions = civiqueFullExam
                    // Examen civique complet : composition stratifiée sur les
                    // thèmes (8 Q × 5 thèmes), comme les templates. Le tirage
                    // aléatoire global pouvait concentrer l'examen sur 1-2
                    // thèmes selon le pool de la difficulté visée.
                    ? compositionService.composeCiviqueFullExam(effectiveDifficulty, size)
                    : questionManager.findRandom(req.module(), themeId, effectiveDifficulty, qType, size);
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
        // Slot d'examen blanc visé dans la grille UI (cf. V110). Ignoré pour
        // TRAINING/REVIEW. Permet à l'UI de retrouver « le dernier essai du
        // slot N » au lieu de glisser les essais d'un cran à chaque refait.
        if (req.type() == AttemptType.MOCK_EXAM && req.slotNumber() != null) {
            attempt.setSlotNumber(req.slotNumber());
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

        final boolean isExamSession = Boolean.TRUE.equals(req.exam());
        if (isExamSession) {
            productionAccessService.assertCanStartProductionExam(userId);
        }

        Attempt attempt = new Attempt();
        attempt.setUser(user);
        attempt.setType(AttemptType.TRAINING);
        attempt.setModule(req.module());
        attempt.setEpreuve(req.epreuve());
        attempt.setParentAttempt(parent);
        attempt.setStartedAt(Instant.now());
        // Session d'examen blanc production : marquée via slotNumber (slot de
        // la grille 1-10, pilote la composition déterministe des sujets). Les
        // soumissions de cette session passent outre le quota d'entraînement.
        if (isExamSession) {
            attempt.setSlotNumber(validateProductionExamSlot(req.slotNumber()));
        }
        // Chrono d'épreuve : 30 min pour l'expression ÉCRITE (comme au vrai TCF
        // IRN), qu'elle soit jouée en examen blanc d'épreuve ou en sous-épreuve
        // d'un examen complet — une épreuve a la même durée où qu'elle soit
        // jouée (cf. DureeEpreuve). L'ancre du décompte, elle, diffère : sur un
        // sous-attempt d'examen complet c'est `timer_started_at`, posé au
        // lancement réel de l'épreuve (cf. AttemptChrono).
        //
        // L'expression ORALE n'a volontairement AUCUN chrono d'épreuve : son
        // temps se compte par tâche, au lancement de chaque tâche
        // (production_tasks.duree_max_sec). Le seul plafond de session est le
        // garde-fou anti-abus DureeEpreuve.EO_GARDE_SESSION_SECONDS, opposé par
        // ProductionAccessService et jamais persisté ni exposé.
        if ((isExamSession || parent != null) && req.epreuve() == EpreuveType.TCF_EE) {
            attempt.setTimeLimitSeconds(DureeEpreuve.secondes(EpreuveType.TCF_EE));
        }
        // Pas de QCM -> totalQuestions / threshold restent null.
        attempt = attemptManager.save(attempt);
        return mapper.toResponse(attempt, List.of(), false);
    }

    /**
     * Crée l'attempt vide d'une étape diagnostic. Le purpose n'est pas deviné
     * depuis TRAINING : il devient durable par la FK de diagnostic_sessions,
     * créée dans la même transaction par DiagnosticSessionCreator.
     */
    @Transactional
    public Attempt createDiagnosticProductionAttempt(UUID userId, EpreuveType epreuve) {
        if (epreuve != EpreuveType.TCF_EE && epreuve != EpreuveType.TCF_EO) {
            throw new BusinessException("Une étape diagnostic doit être TCF_EE ou TCF_EO.");
        }
        User user = userManager.findById(userId)
                .orElseThrow(() -> new NotFoundException("User introuvable : " + userId));
        Attempt attempt = new Attempt();
        attempt.setUser(user);
        attempt.setType(AttemptType.TRAINING);
        attempt.setModule(Module.TCF);
        attempt.setEpreuve(epreuve);
        attempt.setStartedAt(Instant.now());
        return attemptManager.save(attempt);
    }

    /**
     * Verrou freemium commun à TOUS les examens blancs QCM (branche legacy,
     * examens module CO/CE/STRUCTURE, templates) : le slot 1 est offert et
     * rejouable à volonté pour tout compte inscrit, les slots 2+ sont réservés
     * aux abonnés du module concerné (Civique → hasCivique, TCF → hasTcf).
     *
     * <p>Valide aussi la borne du slot (1..{@value #MOCK_EXAM_SLOTS}) : sans
     * ça, {@code slotNumber: 999} ou {@code -3} étaient persistés tels quels et
     * un slot ≤ 0 passait sous le verrou {@code slot > 1}.
     *
     * @param label qualifiant inséré dans le message (« CO », « de thème »…),
     *              suffixé d'un espace ou vide.
     */
    private void enforceMockExamSlotAccess(UUID userId, Module module, Integer requestedSlot, String label) {
        int slot = validateMockExamSlot(requestedSlot);
        if (slot <= 1) return;
        final boolean hasAccess = switch (module) {
            case CIVIQUE -> subscriptionService.hasCivique(userId);
            case TCF -> subscriptionService.hasTcf(userId);
        };
        if (!hasAccess) {
            throw new AccessDeniedException(
                    "Les examens blancs " + label + "au-delà du premier sont réservés aux abonnés "
                            + moduleLabel(module) + ".");
        }
    }

    private static String moduleLabel(Module module) {
        return switch (module) {
            case CIVIQUE -> "Civique";
            case TCF -> "TCF";
        };
    }

    /** Slot d'examen blanc QCM : 1..{@value #MOCK_EXAM_SLOTS} ; null → slot 1. */
    private static int validateMockExamSlot(Integer slot) {
        if (slot == null) return 1;
        if (slot < 1 || slot > MOCK_EXAM_SLOTS) {
            throw new BusinessException("slotNumber doit être entre 1 et " + MOCK_EXAM_SLOTS + ".");
        }
        return slot;
    }

    private static int validateProductionExamSlot(Integer slot) {
        if (slot == null) return 1;
        if (slot < 1 || slot > ProductionExamCompositionService.EXAM_SLOTS_PER_EPREUVE) {
            throw new BusinessException("slotNumber doit être entre 1 et "
                    + ProductionExamCompositionService.EXAM_SLOTS_PER_EPREUVE + ".");
        }
        return slot;
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
        // Les examens civiques de theme exigent toujours un compte. Les examens
        // blancs d'epreuve TCF QCM (CO / CE / STRUCTURE) ouvrent leur SLOT 1 aux
        // visiteurs (cf. startGuestModuleExam) ; les templates free (diagnostic
        // complet) restent jouables en guest.
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
                questions = compositionService.pickQuestionsForTemplate(template, true);
            } else if (req.themeId() != null) {
                // Examens civiques de thème : toujours réservés aux comptes.
                throw new AccessDeniedException(
                        "Les examens blancs par thème sont réservés aux comptes. Créez un compte gratuit pour continuer.");
            } else if (req.moduleExamQuestionType() != null) {
                // Examen blanc d'une épreuve TCF QCM (CO / CE / STRUCTURE) :
                // l'examen 1 est OUVERT aux visiteurs depuis le 2026-08-16.
                return startGuestModuleExam(req, clientIp);
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
        } else if (req.lotNumero() != null) {
            // Série offerte sans compte : uniquement la série 1 de chaque
            // catégorie (découverte). Les séries 2+ exigent un compte.
            if (req.lotNumero() != 1) {
                throw new AccessDeniedException(
                        "Seule la série 1 est offerte sans compte. Créez un compte gratuit pour continuer.");
            }
            return startGuestLot(req, clientIp);
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
     * Série 1 guest (anonyme) : même fenêtre déterministe que les comptes
     * (LotService), attempt persisté avec user NULL + clientIp — utile pour
     * mesurer combien de visiteurs se testent avant inscription.
     */
    private AttemptResponse startGuestLot(StartAttemptRequest req, String clientIp) {
        final List<Question> questions;
        if (req.module() == Module.CIVIQUE) {
            if (req.themeId() == null) {
                throw new BusinessException("themeId est obligatoire pour une série Civique.");
            }
            int effectiveSize = lotService.resolveLotSizeCivique(req.themeId(), 1);
            questions = questionManager.findLotQuestionsCivique(req.themeId(), 1, effectiveSize);
        } else {
            if (req.difficulty() == null) {
                throw new BusinessException("difficulty est obligatoire pour une série TCF (A2/B1/B2).");
            }
            int effectiveSize = lotService.resolveLotSize(
                    req.module(), req.questionType(), req.difficulty(), 1);
            questions = questionManager.findLotQuestions(
                    req.module(), req.questionType(), req.difficulty(), 1, effectiveSize);
        }
        if (questions.isEmpty()) {
            throw new BusinessException("Série 1 indisponible pour ces critères.");
        }

        Attempt attempt = new Attempt();
        // user = null (guest)
        attempt.setClientIp(clientIp);
        attempt.setType(AttemptType.TRAINING);
        attempt.setModule(req.module());
        attempt.setTotalQuestions(questions.size());
        attempt.setStartedAt(Instant.now());
        attempt.setLotNumero(1);
        if (req.module() == Module.CIVIQUE) {
            attempt.setLotThemeId(req.themeId());
        } else {
            attempt.setLotQuestionType(req.questionType());
            attempt.setLotDifficulty(req.difficulty());
        }
        attempt = attemptManager.save(attempt);

        List<AttemptQuestion> aqList = persistAttemptQuestions(attempt, questions);
        return mapper.toResponse(attempt, aqList, false);
    }

    /**
     * Examen blanc d'une epreuve TCF QCM (CO / CE / STRUCTURE) joue SANS COMPTE.
     *
     * <p><b>Changement de regle, 2026-08-16.</b> Ces examens etaient refuses aux
     * visiteurs (403 sur tout MOCK_EXAM guest portant un
     * {@code moduleExamQuestionType}) et les pages web n'etaient que des
     * vitrines. Le proprietaire a arbitre d'ouvrir le <b>slot 1</b> de chaque
     * epreuve : un visiteur doit pouvoir se tester en conditions d'examen avant
     * de creer un compte. Ce n'est pas un correctif, c'est une nouvelle regle.
     *
     * <p>Perimetre volontairement etroit, rien d'autre n'est ouvert :
     * <ul>
     *   <li>slots 2..{@value #MOCK_EXAM_SLOTS} : refuses (compte requis) ;</li>
     *   <li>examens civiques de theme ({@code themeId}) : toujours refuses ;</li>
     *   <li>EE / EO : hors de ce chemin, toujours reservees aux comptes.</li>
     * </ul>
     *
     * <p>Tirage <b>deterministe</b>, comme toutes les entrees guest (serie 1,
     * template free) : rejouer redonne le meme examen. L'objectif est de
     * convertir, pas d'offrir la banque de questions sans compte.
     */
    private AttemptResponse startGuestModuleExam(StartAttemptRequest req, String clientIp) {
        if (req.module() != Module.TCF) {
            throw new BusinessException("Les examens module sont reserves au module TCF.");
        }
        QuestionType qType = req.moduleExamQuestionType();
        if (qType != QuestionType.CO && qType != QuestionType.CE && qType != QuestionType.STRUCTURE) {
            throw new BusinessException("moduleExamQuestionType doit etre CO, CE ou STRUCTURE.");
        }
        int slot = validateMockExamSlot(req.slotNumber());
        if (slot != 1) {
            throw new AccessDeniedException(
                    "Seul le premier examen blanc est offert sans compte. Créez un compte gratuit pour continuer.");
        }

        List<Question> picked = compositionService.composeModuleExam(req.module(), qType, true);
        if (picked.isEmpty()) {
            throw new BusinessException("Aucune question disponible pour cet examen module.");
        }

        Attempt attempt = new Attempt();
        // user = null (guest)
        attempt.setClientIp(clientIp);
        attempt.setType(AttemptType.MOCK_EXAM);
        attempt.setModule(req.module());
        attempt.setEpreuve(moduleExamEpreuve(qType));
        attempt.setModuleExamQuestionType(qType);
        attempt.setTotalQuestions(picked.size());
        attempt.setTimeLimitSeconds(DureeEpreuve.secondesPourQcm(qType));
        attempt.setStartedAt(Instant.now());
        attempt.setSlotNumber(slot);
        attempt = attemptManager.save(attempt);

        List<AttemptQuestion> aqList = persistAttemptQuestions(attempt, picked);
        return mapper.toResponse(attempt, aqList, false);
    }

    /**
     * Demarre un examen blanc a partir d'un ExamTemplate publie. La composition
     * derive des ExamTemplateRule (theme + difficulte + type + count). Si les
     * regles ne suffisent pas a remplir totalQuestions, on complete par un
     * tirage libre dans le module (jamais de doublon intra-attempt).
     */
    private AttemptResponse startFromTemplate(User user, ExamTemplate template, Integer slotNumber) {
        // Borne du slot (l'accès, lui, est porté par template.isFree()).
        validateMockExamSlot(slotNumber);
        if (!template.isPublished()) {
            throw new AccessDeniedException("Examen blanc non disponible");
        }
        if (!template.isFree() && !subscriptionService.isPremium(user.getId())) {
            throw new AccessDeniedException("Examen blanc réservé aux abonnés");
        }

        // Premium : tirage aleatoire (variete). Non-premium sur template free :
        // tirage deterministe (regle demo "memes questions a chaque lancement").
        boolean deterministic = template.isFree() && !subscriptionService.isPremium(user.getId());
        List<Question> picked = compositionService.pickQuestionsForTemplate(template, deterministic);
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
        // Slot UI (cf. V110) : refaire « l'examen N » depuis la grille
        // /examens-blancs réutilise slot_number=N, l'UI prend le plus récent
        // par slot au lieu d'empiler les essais.
        if (slotNumber != null) {
            attempt.setSlotNumber(slotNumber);
        }
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
     * <p>Verrou freemium par sous-module : Lot 1 = decouverte gratuite ;
     * Lot 2+ reserve aux abonnes du module concerne (Civique → hasCivique,
     * TCF → hasTcf). Cf. mobile {@code TcfLevelLotsScreen} /
     * {@code CiviqueThemeDetailScreen} qui appliquent le meme verrou en UI.
     */
    private AttemptResponse startFromLot(User user, StartAttemptRequest req) {
        if (req.type() != AttemptType.TRAINING) {
            throw new BusinessException("Les lots sont reserves au type TRAINING.");
        }
        // Lot 1 = gratuit pour tous (decouverte du sous-module). Lot 2+ →
        // check premium ciblé sur le module.
        if (req.lotNumero() != null && req.lotNumero() > 1) {
            final UUID uid = user.getId();
            final boolean hasAccess = switch (req.module()) {
                case CIVIQUE -> subscriptionService.hasCivique(uid);
                case TCF -> subscriptionService.hasTcf(uid);
            };
            if (!hasAccess) {
                throw new AccessDeniedException(
                        "Les lots au-delà du premier sont reserves aux abonnes du module.");
            }
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
        // Même raison qu'en examen module : sans épreuve explicite, un lot
        // d'entraînement CE ou STRUCTURE ressortait étiqueté TCF_CO.
        if (req.questionType() != null) {
            attempt.setEpreuve(moduleExamEpreuve(req.questionType()));
        }
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
     * STRUCTURE). Composition : 8 A2 + 9 B1 + 8 B2 progressifs, tire
     * aleatoirement dans le pool filtre par module + questionType. Duree lue
     * dans {@link DureeEpreuve}, jamais recopiee ici. Si une strate est trop petite, on complete avec les
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
        // Verrou freemium par sous-module TCF QCM : le 1er examen blanc (slot 1)
        // est gratuit ET rejouable à volonté pour chaque épreuve (CO / CE /
        // STRUCTURE) par tout compte inscrit ; seuls les slots 2+ sont réservés
        // aux abonnés TCF. EE/EO ont leur propre quota (cf.
        // ProductionSubmissionService). Le front applique déjà ce verrou en UI ;
        // on le double ici par sécurité. Le slotNumber ne pilote pas la
        // composition (cf. composeModuleExam) — c'est un repère de grille (V110).
        enforceMockExamSlotAccess(user.getId(), req.module(), req.slotNumber(), qType + " ");

        List<Question> picked = compositionService.composeModuleExam(req.module(), qType, false);
        if (picked.isEmpty()) {
            throw new BusinessException("Aucune question disponible pour cet examen module.");
        }

        int timeLimit = DureeEpreuve.secondesPourQcm(qType);

        Attempt attempt = new Attempt();
        attempt.setUser(user);
        attempt.setType(AttemptType.MOCK_EXAM);
        attempt.setModule(req.module());
        // Épreuve explicite : sans ça le @PrePersist d'Attempt retombait sur
        // deriveEpreuveFromModule(TCF) = TCF_CO, et un examen de CE ou de
        // STRUCTURE était étiqueté « Compréhension orale » partout où les
        // fronts labellisent sur `epreuve` (/api/me/attempts, historiques).
        attempt.setEpreuve(moduleExamEpreuve(qType));
        attempt.setModuleExamQuestionType(qType);
        attempt.setTotalQuestions(picked.size());
        attempt.setTimeLimitSeconds(timeLimit);
        attempt.setStartedAt(Instant.now());
        // Slot UI (cf. V110) — propage le slotNumber demandé pour que la
        // grille mobile retrouve « le dernier essai du slot N ».
        if (req.slotNumber() != null) {
            attempt.setSlotNumber(req.slotNumber());
        }
        attempt = attemptManager.save(attempt);

        List<AttemptQuestion> aqList = persistAttemptQuestions(attempt, picked);
        return mapper.toResponse(attempt, aqList, false);
    }

    /** Épreuve fine portée par un examen module TCF QCM (CO / CE / STRUCTURE). */
    static EpreuveType moduleExamEpreuve(QuestionType qType) {
        return switch (qType) {
            case CO, CO_IMAGE -> EpreuveType.TCF_CO;
            case CE -> EpreuveType.TCF_CE;
            case STRUCTURE -> EpreuveType.TCF_STRUCTURE;
            default -> throw new BusinessException(
                    "qType sans épreuve d'examen module : " + qType);
        };
    }

    /**
     * Variante de {@link #startModuleExam} pour les sous-attempts d'un examen
     * blanc TCF complet (parent TCF_COMPLET). Skip le check premium (l'accès
     * est porté par le parent) et pose {@code parent_attempt_id}.
     *
     * <p>La durée est celle de l'épreuve, <b>identique au standalone</b> (CO
     * 20 min, CE 35 min) : la CE n'est plus raccourcie à 30 min, l'enveloppe
     * globale de 90 min qui l'imposait ayant disparu. Son décompte ne démarre
     * qu'au lancement réel de l'épreuve ({@code timer_started_at}, posé par
     * {@link FullTcfExamService#beginEpreuve}) — cf. {@code AttemptChrono}.
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

        List<Question> picked = compositionService.composeModuleExam(Module.TCF, qType, false);
        if (picked.isEmpty()) {
            throw new BusinessException("Aucune question disponible pour le sous-attempt " + qType + ".");
        }

        int timeLimit = DureeEpreuve.secondesPourQcm(qType);

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
    // Lecture — délégué à AttemptInteractionService
    // ------------------------------------------------------------------------

    /**
     * Lecture d'une session. Clôture d'abord la session si son délai est
     * écoulé — clôture <b>paresseuse, à la lecture</b>, sans job planifié
     * (même philosophie que l'expiration d'abonnement dans
     * {@code SubscriptionService.isCovering}). Quitter ne suspend rien : le
     * candidat qui revient après l'échéance retrouve son épreuve close avec ce
     * qui avait été enregistré.
     */
    public AttemptResponse getById(UUID userId, UUID attemptId) {
        interactionService.closeIfExpired(attemptId);
        return interactionService.getById(userId, attemptId);
    }

    public List<AttemptSummaryResponse> listMine(
            UUID userId,
            AttemptType type,
            Module module,
            QuestionType moduleExamQuestionType,
            UUID themeId,
            int limit) {
        return interactionService.listMine(userId, type, module, moduleExamQuestionType, themeId, limit);
    }

    /**
     * Lookup d'un attempt guest pour la branche publique. Renvoie l'attempt
     * SEULEMENT si user IS NULL ET client_ip matche. Toute non-correspondance
     * (id inexistant, attempt d'un user, autre IP) est traitee en 404 par
     * l'appelant pour ne pas reveler l'existence.
     */
    public Attempt loadGuestAttempt(UUID attemptId, String clientIp) {
        return interactionService.loadGuestAttempt(attemptId, clientIp);
    }

    /**
     * Variante de {@link #getById(UUID, UUID)} sans controle user (l'appelant
     * a deja valide l'IP via {@link #loadGuestAttempt}).
     */
    public AttemptResponse readAttempt(Attempt attempt) {
        return interactionService.readAttempt(attempt);
    }

    // ------------------------------------------------------------------------
    // Soumission d'une reponse — délégué à AttemptInteractionService
    // ------------------------------------------------------------------------

    public AnswerResultResponse submitAnswer(UUID userId, UUID attemptId, SubmitAnswerRequest req) {
        return interactionService.submitAnswer(userId, attemptId, req);
    }

    /**
     * Variante de {@link #submitAnswer(UUID, UUID, SubmitAnswerRequest)} qui
     * skip le controle user (deja fait via IP cote guest).
     */
    public AnswerResultResponse submitAnswerForAttempt(Attempt attempt, SubmitAnswerRequest req) {
        return interactionService.submitAnswerForAttempt(attempt, req);
    }

    // ------------------------------------------------------------------------
    // Finalisation — délégué à AttemptInteractionService
    // ------------------------------------------------------------------------

    public AttemptResponse finish(UUID userId, UUID attemptId) {
        return interactionService.finish(userId, attemptId);
    }

    /** Variante de {@link #finish(UUID, UUID)} qui skip le controle user. */
    public AttemptResponse finishAttempt(Attempt attempt) {
        return interactionService.finishAttempt(attempt);
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

    private static boolean isProductionEpreuve(EpreuveType e) {
        return e == EpreuveType.TCF_EO || e == EpreuveType.TCF_EE || e == EpreuveType.TCF_COMPLET;
    }
}
