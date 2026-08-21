package com.sejourfr.app.support;

import com.sejourfr.app.audioquestion.entity.AudioDraftStatus;
import com.sejourfr.app.audioquestion.entity.AudioQuestionDraft;
import com.sejourfr.app.audioquestion.entity.AudioQuestionGenerationLog;
import com.sejourfr.app.audioquestion.entity.GenerationStatus;
import com.sejourfr.app.audioquestion.repository.AudioQuestionDraftRepository;
import com.sejourfr.app.audioquestion.repository.AudioQuestionGenerationLogRepository;
import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.Answer;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.AttemptQuestion;
import com.sejourfr.app.entity.Choice;
import com.sejourfr.app.entity.Conversation;
import com.sejourfr.app.entity.EmailChangeToken;
import com.sejourfr.app.entity.ExamTemplate;
import com.sejourfr.app.entity.ExamTemplateRule;
import com.sejourfr.app.entity.HumanCalibrationNote;
import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.entity.Media;
import com.sejourfr.app.entity.Message;
import com.sejourfr.app.entity.Passage;
import com.sejourfr.app.entity.PasswordResetToken;
import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.ProcessedExternalEvent;
import com.sejourfr.app.entity.ProductionExample;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.AgentRoleCard;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.entity.Question;
import com.sejourfr.app.entity.RealtimeSession;
import com.sejourfr.app.entity.RefreshToken;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.SkillConstraintTag;
import com.sejourfr.app.entity.SkillPrompt;
import com.sejourfr.app.entity.SkillReference;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.entity.Transcription;
import com.sejourfr.app.entity.DiagnosticSession;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserQuestionStatus;
import com.sejourfr.app.entity.UserSkillAttempt;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.AttemptMode;
import com.sejourfr.app.enums.AttemptStatus;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.AuthProvider;
import com.sejourfr.app.enums.BillingCycle;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.enums.MediaType;
import com.sejourfr.app.enums.MessageSender;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.PassageType;
import com.sejourfr.app.enums.PlanPurchaseType;
import com.sejourfr.app.enums.ProductionSubmissionSource;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.enums.RealtimeSessionStatus;
import com.sejourfr.app.enums.ClientPlatform;
import com.sejourfr.app.enums.DiagnosticSessionStatus;
import com.sejourfr.app.enums.FunnelEvent;
import com.sejourfr.app.enums.Role;
import com.sejourfr.app.enums.SkillAttemptStatut;
import com.sejourfr.app.enums.SkillDifficulty;
import com.sejourfr.app.enums.SkillReferenceLevel;
import com.sejourfr.app.enums.SkillConstraintIcon;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.enums.SubmissionStatut;
import com.sejourfr.app.enums.SubscriptionSource;
import com.sejourfr.app.enums.SubscriptionStatus;
import com.sejourfr.app.manager.AiEvaluationManager;
import com.sejourfr.app.manager.AnswerManager;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.AttemptQuestionManager;
import com.sejourfr.app.manager.ConversationManager;
import com.sejourfr.app.manager.EmailChangeTokenManager;
import com.sejourfr.app.manager.ExamTemplateManager;
import com.sejourfr.app.manager.HumanCalibrationNoteManager;
import com.sejourfr.app.manager.LearningPlanObservationManager;
import com.sejourfr.app.manager.MediaManager;
import com.sejourfr.app.manager.MessageManager;
import com.sejourfr.app.manager.PassageManager;
import com.sejourfr.app.manager.PasswordResetTokenManager;
import com.sejourfr.app.manager.PlanManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.manager.ProductionTaskManager;
import com.sejourfr.app.manager.QuestionManager;
import com.sejourfr.app.manager.RealtimeSessionManager;
import com.sejourfr.app.manager.RefreshTokenManager;
import com.sejourfr.app.manager.SkillManager;
import com.sejourfr.app.manager.SkillPromptManager;
import com.sejourfr.app.manager.ThemeManager;
import com.sejourfr.app.manager.TranscriptionManager;
import com.sejourfr.app.manager.DiagnosticSessionManager;
import com.sejourfr.app.manager.UserFunnelEventManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.manager.UserQuestionStatusManager;
import com.sejourfr.app.manager.UserSkillAttemptManager;
import com.sejourfr.app.manager.UserSubscriptionManager;
import com.sejourfr.app.repository.ProcessedExternalEventRepository;
import com.sejourfr.app.repository.ProductionTaskRepository;
import com.sejourfr.app.repository.SkillRepository;
import com.sejourfr.app.service.social.SocialIdentity;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicLong;

/**
 * Fabrique d'entités persistées pour les tests d'intégration. Chaque appel crée
 * une ligne réelle en base (Postgres embarqué). Les identifiants « naturels »
 * (email, code) sont rendus uniques par un compteur de séquence pour éviter les
 * collisions entre tests qui partagent la même instance.
 *
 * <p>Chaque fabrique {@code xxx(...)} renvoie l'entité <b>persistée</b> (id
 * peuplé). Pour les agrégats qui dépendent de parents (FK), une surcharge
 * paramétrée accepte le parent et une surcharge sans argument crée ses propres
 * parents — comme {@link #theme()} / {@link #theme(Module, String, String)}.</p>
 *
 * <p>Mot de passe par défaut des users : {@value #DEFAULT_PASSWORD}.</p>
 */
@RequiredArgsConstructor
public class TestData {

    public static final String DEFAULT_PASSWORD = "Test123!";

    private static final AtomicLong SEQ = new AtomicLong();

    private final UserManager userManager;
    private final ThemeManager themeManager;
    private final PasswordEncoder passwordEncoder;
    private final MediaManager mediaManager;
    private final PassageManager passageManager;
    private final QuestionManager questionManager;
    private final AttemptManager attemptManager;
    private final AttemptQuestionManager attemptQuestionManager;
    private final AnswerManager answerManager;
    private final PlanManager planManager;
    private final UserSubscriptionManager userSubscriptionManager;
    private final ProductionTaskManager productionTaskManager;
    private final ProductionTaskRepository productionTaskRepository;
    private final ProductionSubmissionManager productionSubmissionManager;
    private final ExamTemplateManager examTemplateManager;
    private final ConversationManager conversationManager;
    private final MessageManager messageManager;
    private final RefreshTokenManager refreshTokenManager;
    private final PasswordResetTokenManager passwordResetTokenManager;
    private final EmailChangeTokenManager emailChangeTokenManager;
    private final ProcessedExternalEventRepository processedExternalEventRepository;
    private final UserQuestionStatusManager userQuestionStatusManager;
    private final AiEvaluationManager aiEvaluationManager;
    private final TranscriptionManager transcriptionManager;
    private final HumanCalibrationNoteManager humanCalibrationNoteManager;
    private final RealtimeSessionManager realtimeSessionManager;
    private final LearningPlanObservationManager learningPlanObservationManager;
    private final SkillManager skillManager;
    private final SkillRepository skillRepository;
    private final SkillPromptManager skillPromptManager;
    private final UserSkillAttemptManager userSkillAttemptManager;
    private final AudioQuestionDraftRepository audioQuestionDraftRepository;
    private final AudioQuestionGenerationLogRepository audioQuestionGenerationLogRepository;
    private final DiagnosticSessionManager diagnosticSessionManager;
    private final UserFunnelEventManager userFunnelEventManager;

    private static long next() {
        return SEQ.incrementAndGet();
    }

    // ------------------------------------------------------------------------
    // User (signatures historiques — ne pas modifier)
    // ------------------------------------------------------------------------

    public User user() {
        return persistUser(Role.USER, "user" + next() + "@test.sejourfr");
    }

    public User user(String email) {
        return persistUser(Role.USER, email);
    }

    public User admin() {
        return persistUser(Role.ADMIN, "admin" + next() + "@test.sejourfr");
    }

    private User persistUser(Role role, String email) {
        User u = new User();
        u.setEmail(email);
        u.setPasswordHash(passwordEncoder.encode(DEFAULT_PASSWORD));
        u.setRole(role);
        u.setActive(true);
        return userManager.save(u);
    }

    // ------------------------------------------------------------------------
    // Theme (signatures historiques — ne pas modifier)
    // ------------------------------------------------------------------------

    public Theme theme(Module module, String code, String name) {
        Theme t = new Theme();
        t.setModule(module);
        t.setCode(code + "-" + next());
        t.setName(name);
        t.setDisplayOrder(0);
        return themeManager.save(t);
    }

    public Theme theme() {
        return theme(Module.CIVIQUE, "theme", "Thème de test");
    }

    // ------------------------------------------------------------------------
    // Media / Passage
    // ------------------------------------------------------------------------

    public Media media(MediaType type) {
        Media m = new Media();
        m.setType(type);
        m.setUrl("https://cdn.test.sejourfr/media/" + next() + ".bin");
        m.setContentType("application/octet-stream");
        return mediaManager.save(m);
    }

    public Media media() {
        return media(MediaType.IMAGE);
    }

    public Passage passage(PassageType type, Theme theme) {
        Passage p = new Passage();
        p.setType(type);
        p.setContent("Contenu de passage de test " + next());
        p.setTheme(theme);
        return passageManager.save(p);
    }

    public Passage passage() {
        return passage(PassageType.TEXTE, theme());
    }

    // ------------------------------------------------------------------------
    // Question (+ Choice)
    // ------------------------------------------------------------------------

    public Question question(Theme theme) {
        Question q = new Question();
        q.setModule(Module.CIVIQUE);
        q.setTheme(theme);
        q.setDifficulty(Difficulty.CSP);
        q.setQuestionType(QuestionType.CONNAISSANCE);
        q.setStatement("Énoncé de question de test " + next());
        q.setExplanation("Explication de test.");
        Choice c1 = newChoice("Bonne réponse", true, 0);
        Choice c2 = newChoice("Mauvaise réponse", false, 1);
        q.addChoice(c1);
        q.addChoice(c2);
        return questionManager.save(q);
    }

    public Question question() {
        return question(theme());
    }

    public Choice choice(Question question) {
        Choice c = newChoice("Choix " + next(), false, question.getChoices().size());
        question.addChoice(c);
        Question saved = questionManager.save(question);
        return saved.getChoices().get(saved.getChoices().size() - 1);
    }

    public Choice choice() {
        return choice(question());
    }

    private Choice newChoice(String label, boolean correct, int order) {
        Choice c = new Choice();
        c.setLabel(label);
        c.setCorrect(correct);
        c.setDisplayOrder(order);
        return c;
    }

    // ------------------------------------------------------------------------
    // Attempt / AttemptQuestion / Answer
    // ------------------------------------------------------------------------

    public Attempt attempt(User user) {
        Attempt a = new Attempt();
        a.setUser(user);
        a.setType(AttemptType.TRAINING);
        a.setModule(Module.CIVIQUE);
        a.setEpreuve(EpreuveType.CIVIQUE);
        a.setMode(AttemptMode.ENTRAINEMENT);
        a.setStatus(AttemptStatus.EN_COURS);
        a.setStartedAt(Instant.now());
        return attemptManager.save(a);
    }

    public Attempt attempt() {
        return attempt(user());
    }

    public AttemptQuestion attemptQuestion(Attempt attempt, Question question) {
        AttemptQuestion aq = new AttemptQuestion();
        aq.setAttempt(attempt);
        aq.setQuestion(question);
        aq.setPosition(attempt.getQuestions().size());
        return attemptQuestionManager.save(aq);
    }

    public AttemptQuestion attemptQuestion() {
        Attempt a = attempt();
        return attemptQuestion(a, question());
    }

    public Answer answer(AttemptQuestion attemptQuestion) {
        Answer ans = new Answer();
        ans.setAttemptQuestion(attemptQuestion);
        ans.setUser(attemptQuestion.getAttempt().getUser());
        ans.setSelectedChoiceIds(new ArrayList<>());
        ans.setCorrect(true);
        ans.setAnsweredAt(Instant.now());
        return answerManager.save(ans);
    }

    public Answer answer() {
        return answer(attemptQuestion());
    }

    // ------------------------------------------------------------------------
    // Plan / UserSubscription
    // ------------------------------------------------------------------------

    public Plan plan() {
        Plan p = new Plan();
        p.setCode("PLAN_" + next());
        p.setName("Plan de test");
        p.setBillingCycle(BillingCycle.MONTHLY);
        p.setPrice(new BigDecimal("9.99"));
        p.setModuleAccess(ModuleAccess.INTEGRAL);
        p.setDurationDays(30);
        p.setPurchaseType(PlanPurchaseType.SUBSCRIPTION);
        p.setActive(true);
        return planManager.save(p);
    }

    public UserSubscription userSubscription(User user, Plan plan) {
        UserSubscription s = new UserSubscription();
        s.setUser(user);
        s.setPlan(plan);
        s.setStatus(SubscriptionStatus.ACTIVE);
        s.setStartsAt(Instant.now());
        s.setEndsAt(Instant.now().plus(30, ChronoUnit.DAYS));
        s.setSource(SubscriptionSource.STRIPE);
        s.setOriginalTransactionId("sub_test_" + next());
        s.setProductId(plan.getCode());
        s.setAutoRenew(true);
        return userSubscriptionManager.save(s);
    }

    public UserSubscription userSubscription() {
        return userSubscription(user(), plan());
    }

    // ------------------------------------------------------------------------
    // ProductionTask / ProductionSubmission / ProductionExample
    // ------------------------------------------------------------------------

    public ProductionTask productionTask(EpreuveType epreuve) {
        ProductionTask t = new ProductionTask();
        t.setEpreuve(epreuve);
        t.setTacheNumero((short) 1);
        t.setNiveauCible("B1");
        t.setConsigne("Consigne de production de test " + next());
        t.setContexte("Contexte de test.");
        t.setActive(true);
        // Contrainte chk_prod_task_audio_text_coherence (V011) : TCF_EO porte une
        // durée (mots NULL), TCF_EE porte une fourchette de mots (durée NULL).
        if (epreuve == EpreuveType.TCF_EO) {
            t.setDureeMinSec(60);
            t.setDureeMaxSec(180);
        } else {
            // TCF IRN EE tâche 1 : volume officiel de 30 à 60 mots.
            t.setMotsMin(30);
            t.setMotsMax(60);
        }
        return productionTaskRepository.save(t);
    }

    public ProductionTask productionTask() {
        return productionTask(EpreuveType.TCF_EE);
    }

    /**
     * Tâche EO n°2 (jeu de rôle), seule combinaison autorisée à porter une fiche
     * de scénario (contrainte {@code chk_prod_task_agent_role_card}). {@code card}
     * peut être null pour représenter un sujet non encore doté d'une fiche.
     * {@code saveAndFlush} pour que la contrainte parle tout de suite.
     */
    public ProductionTask productionTaskEoT2(AgentRoleCard card) {
        ProductionTask t = new ProductionTask();
        t.setEpreuve(EpreuveType.TCF_EO);
        t.setTacheNumero((short) 2);
        t.setNiveauCible("B1");
        t.setConsigne("Consigne de jeu de rôle de test " + next());
        t.setContexte("L'examinateur joue le conseiller de test.");
        t.setDureeMinSec(120);
        t.setDureeMaxSec(210);
        t.setAgentRoleCard(card);
        t.setActive(true);
        return productionTaskRepository.saveAndFlush(t);
    }

    public ProductionSubmission productionSubmission(Attempt attempt, ProductionTask task, User user) {
        ProductionSubmission s = new ProductionSubmission();
        s.setAttempt(attempt);
        s.setProductionTask(task);
        s.setUser(user);
        s.setSubmittedAt(Instant.now());
        s.setTexteSoumis("Texte soumis de test " + next());
        s.setMotsCount(42);
        s.setStatut(SubmissionStatut.SUBMITTED);
        s.setSource(ProductionSubmissionSource.ASYNC);
        return productionSubmissionManager.save(s);
    }

    public ProductionSubmission productionSubmission() {
        User u = user();
        return productionSubmission(attempt(u), productionTask(), u);
    }

    public ProductionExample productionExample(ProductionTask task) {
        ProductionExample e = new ProductionExample();
        e.setTaskId(task.getId());
        e.setTitre("Exemple modèle " + next());
        e.setResume("Résumé court.");
        e.setContenu("Contenu du modèle de réponse.");
        e.setDisplayOrder(0);
        return productionTaskManager.saveExample(e);
    }

    public ProductionExample productionExample() {
        return productionExample(productionTask());
    }

    // ------------------------------------------------------------------------
    // ExamTemplate (+ ExamTemplateRule, persisté en cascade)
    // ------------------------------------------------------------------------

    public ExamTemplate examTemplate() {
        ExamTemplate t = new ExamTemplate();
        t.setSlug("exam-template-" + next());
        t.setModule(Module.TCF);
        t.setName("Examen blanc de test");
        t.setDurationSeconds(5400);
        t.setTotalQuestions(20);
        t.setPassingScore(12);
        t.setFree(true);
        t.setPublished(true);
        t.setPosition(0);
        return examTemplateManager.save(t);
    }

    public ExamTemplateRule examTemplateRule(ExamTemplate template) {
        ExamTemplateRule r = new ExamTemplateRule();
        r.setExamTemplate(template);
        r.setQuestionType(QuestionType.CO);
        r.setDifficulty(Difficulty.B1);
        r.setQuestionCount(5);
        r.setPosition(template.getRules().size());
        template.getRules().add(r);
        ExamTemplate saved = examTemplateManager.save(template);
        return saved.getRules().get(saved.getRules().size() - 1);
    }

    public ExamTemplateRule examTemplateRule() {
        return examTemplateRule(examTemplate());
    }

    // ------------------------------------------------------------------------
    // Conversation / Message
    // ------------------------------------------------------------------------

    public Conversation conversation(User user) {
        Conversation c = new Conversation();
        c.setUser(user);
        c.setSubject("Sujet de test " + next());
        return conversationManager.save(c);
    }

    public Conversation conversation() {
        return conversation(user());
    }

    public Message message(Conversation conversation) {
        Message m = new Message();
        m.setConversation(conversation);
        m.setSenderType(MessageSender.USER);
        m.setAuthor(conversation.getUser());
        m.setBody("Corps du message de test " + next());
        return messageManager.save(m);
    }

    public Message message() {
        return message(conversation());
    }

    // ------------------------------------------------------------------------
    // Tokens d'authentification
    // ------------------------------------------------------------------------

    public RefreshToken refreshToken(User user) {
        RefreshToken t = new RefreshToken();
        t.setJti(UUID.randomUUID());
        t.setUser(user);
        t.setExpiresAt(Instant.now().plus(30, ChronoUnit.DAYS));
        t.setUserAgent("test-agent");
        t.setIpAddress("127.0.0.1");
        return refreshTokenManager.save(t);
    }

    public RefreshToken refreshToken() {
        return refreshToken(user());
    }

    public PasswordResetToken passwordResetToken(User user) {
        PasswordResetToken t = new PasswordResetToken();
        t.setUser(user);
        t.setTokenHash("reset-hash-" + next());
        t.setExpiresAt(Instant.now().plus(1, ChronoUnit.HOURS));
        return passwordResetTokenManager.save(t);
    }

    public PasswordResetToken passwordResetToken() {
        return passwordResetToken(user());
    }

    public EmailChangeToken emailChangeToken(User user) {
        EmailChangeToken t = new EmailChangeToken();
        t.setUser(user);
        t.setTokenHash("email-hash-" + next());
        t.setNewEmail("new" + next() + "@test.sejourfr");
        t.setExpiresAt(Instant.now().plus(1, ChronoUnit.HOURS));
        return emailChangeTokenManager.save(t);
    }

    public EmailChangeToken emailChangeToken() {
        return emailChangeToken(user());
    }

    // ------------------------------------------------------------------------
    // ProcessedExternalEvent (PK composite, pas d'id généré)
    // ------------------------------------------------------------------------

    public ProcessedExternalEvent processedExternalEvent() {
        ProcessedExternalEvent e = new ProcessedExternalEvent(
                "stripe", "evt_test_" + next(), Instant.now());
        return processedExternalEventRepository.save(e);
    }

    // ------------------------------------------------------------------------
    // UserQuestionStatus
    // ------------------------------------------------------------------------

    public UserQuestionStatus userQuestionStatus(User user, Question question) {
        UserQuestionStatus s = new UserQuestionStatus();
        s.setUser(user);
        s.setQuestion(question);
        s.setFavorite(true);
        s.setWrongCount(1);
        s.setCorrectCount(2);
        s.setLastSeenAt(Instant.now());
        s.setUpdatedAt(Instant.now());
        return userQuestionStatusManager.save(s);
    }

    public UserQuestionStatus userQuestionStatus() {
        return userQuestionStatus(user(), question());
    }

    // ------------------------------------------------------------------------
    // Pipeline d'évaluation EO/EE
    // ------------------------------------------------------------------------

    public AiEvaluation aiEvaluation(ProductionSubmission submission) {
        AiEvaluation e = new AiEvaluation();
        e.setSubmission(submission);
        e.setModeleUtilise("claude-test");
        e.setPromptVersion("v1.0");
        e.setNoteSur20(new BigDecimal("14.5"));
        e.setNiveauCecrl(NiveauCecrl.B1);
        e.setNiveauCecrlIa(NiveauCecrl.B1);
        Map<String, Object> feedback = new HashMap<>();
        feedback.put("note_globale", 14.5);
        e.setFeedbackJson(feedback);
        return aiEvaluationManager.save(e);
    }

    public AiEvaluation aiEvaluation() {
        return aiEvaluation(productionSubmission());
    }

    public Transcription transcription(ProductionSubmission submission) {
        Transcription t = new Transcription();
        t.setSubmission(submission);
        t.setTexte("Texte transcrit de test " + next());
        t.setLangueDetectee("fr");
        t.setModeleUtilise("whisper-test");
        t.setAudioDurationSec(120);
        return transcriptionManager.save(t);
    }

    public Transcription transcription() {
        return transcription(productionSubmission());
    }

    public HumanCalibrationNote humanCalibrationNote(ProductionSubmission submission, User evaluator) {
        HumanCalibrationNote n = new HumanCalibrationNote();
        n.setSubmission(submission);
        n.setEvaluator(evaluator);
        n.setNoteHumaineSur20(new BigDecimal("15.0"));
        n.setNiveauCecrlHumain(NiveauCecrl.B1);
        n.setCommentaires("Note de calibration de test.");
        return humanCalibrationNoteManager.save(n);
    }

    public HumanCalibrationNote humanCalibrationNote() {
        return humanCalibrationNote(productionSubmission(), admin());
    }

    // ------------------------------------------------------------------------
    // RealtimeSession (EO temps réel)
    // ------------------------------------------------------------------------

    public RealtimeSession realtimeSession(User user) {
        RealtimeSession s = new RealtimeSession();
        s.setUser(user);
        s.setEpreuve(EpreuveType.TCF_EO);
        s.setTacheNumero((short) 1);
        s.setProvider("gemini");
        s.setModel("gemini-2.0-flash-live");
        s.setStatus(RealtimeSessionStatus.PENDING);
        s.setTranscript("");
        return realtimeSessionManager.save(s);
    }

    public RealtimeSession realtimeSession() {
        return realtimeSession(user());
    }

    // ------------------------------------------------------------------------
    // Module audioquestion (sous-module isolé)
    // ------------------------------------------------------------------------

    public AudioQuestionDraft audioQuestionDraft(Theme theme) {
        AudioQuestionDraft d = new AudioQuestionDraft();
        d.setDifficulty(Difficulty.B1);
        d.setCompetenceCode("CO-B1-01");
        d.setTheme(theme);
        d.setTranscriptText("Transcription audio de test " + next());
        d.setSsmlText("<speak>Bonjour</speak>");
        d.setStatement("Que dit le locuteur ?");
        d.setExplanation("Explication de test.");
        d.setChoices(List.of(
                new AudioQuestionDraft.DraftChoice("Bonjour", true, 0),
                new AudioQuestionDraft.DraftChoice("Bonsoir", false, 1)));
        d.setStatus(AudioDraftStatus.TEXT_VALIDATED);
        return audioQuestionDraftRepository.save(d);
    }

    public AudioQuestionDraft audioQuestionDraft() {
        return audioQuestionDraft(theme(Module.TCF, "tcf-co", "TCF CO"));
    }

    public AudioQuestionGenerationLog audioQuestionGenerationLog(User admin) {
        AudioQuestionGenerationLog log = new AudioQuestionGenerationLog();
        log.setAdminUserId(admin.getId());
        log.setRequestedParams("{}");
        log.setPromptVersion("v1");
        log.setAnthropicModel("claude-test");
        log.setStatus(GenerationStatus.SUCCESS);
        return audioQuestionGenerationLogRepository.save(log);
    }

    public AudioQuestionGenerationLog audioQuestionGenerationLog() {
        return audioQuestionGenerationLog(admin());
    }

    // ------------------------------------------------------------------------
    // Module competences : Skill / SkillPrompt / SkillReference / UserSkillAttempt
    // ------------------------------------------------------------------------

    /**
     * Competence de test rattachee a {@code taskCode}.
     *
     * <p><b>Le rang d'affichage se prend AU-DESSUS du seed, jamais dedans.</b>
     * Le schema impose {@code UNIQUE (task_code, display_order)} et le seed
     * publie exactement 8 competences par tache, donc les rangs 1..8 sont tous
     * occupes ; la fabrique se range a la suite. C'est la raison d'etre de la
     * borne haute a 50 du {@code CHECK} : a 8, la table etait saturee par
     * construction et aucune competence supplementaire ne pouvait exister — ni
     * en test, ni via l'admin.
     *
     * <p>La regle produit « exactement 8 competences actives par tache » reste
     * verrouillee, mais par {@code SkillSeedIT}, qui l'exprime la ou elle est
     * vraie : sur le contenu publie.
     */
    public Skill skill(SkillTaskCode taskCode) {
        Skill s = new Skill();
        s.setSection(taskCode.getSection());
        s.setTaskCode(taskCode);
        s.setCode("TST-C" + next());
        s.setTitle("Competence de test");
        s.setDescription("Ce que cette competence apporte au TCF.");
        s.setGeneralCriterion("Le critere general travaille par cette competence.");
        s.setTargetLevel(taskCode.getTargetLevel());
        s.setDisplayOrder(nextSkillDisplayOrder(taskCode));
        s.setActive(true);
        return skillRepository.saveAndFlush(s);
    }

    public Skill skill() {
        return skill(SkillTaskCode.EE1);
    }

    /** Rang libre le plus bas au-dessus des competences existantes, desactivees comprises. */
    private short nextSkillDisplayOrder(SkillTaskCode taskCode) {
        short max = 0;
        for (Skill existing : skillRepository.findByTaskCodeOrderByDisplayOrderAsc(taskCode)) {
            if (existing.getDisplayOrder() > max) max = existing.getDisplayOrder();
        }
        return (short) (max + 1);
    }

    /**
     * Petit sujet rattache a {@code skill}. La coherence mots / duree exigee par
     * {@code chk_skill_prompts_ee_eo_coherence} est respectee automatiquement
     * selon la section de la competence.
     */
    public SkillPrompt skillPrompt(Skill skill) {
        SkillPrompt p = new SkillPrompt();
        p.setSkill(skill);
        p.setSection(skill.getSection());
        p.setCode("TST-S" + next());
        p.setTitle("Petit sujet de test");
        p.setContext("Vous ecrivez a votre voisin.");
        p.setInstruction("Redigez deux phrases.");
        p.setUniqueCriterion("Adapter le ton au destinataire.");
        // Guidage de l'ecran de saisie : renseigne comme sur un sujet publie
        // (2 a 4 gestes, 1 a 3 etiquettes), pour qu'un test qui consomme cette
        // fabrique voie un sujet realiste et non un sujet a moitie vide. Un
        // sujet SANS guidage reste legal : le poser explicitement a null.
        p.setChecklist(List.of("Saluez votre voisin", "Dites qui vous etes", "Ecrivez deux phrases"));
        p.setConstraintTags(List.of(
                new SkillConstraintTag("Vouvoiement", SkillConstraintIcon.PERSON),
                new SkillConstraintTag("Ton poli", SkillConstraintIcon.TONE)));
        p.setTip("commencez par bonjour, puis presentez-vous");
        if (skill.getSection() == SkillSection.EE) {
            p.setRecommendedMinWords(15);
            p.setRecommendedMaxWords(50);
            p.setAnswerStarter("Bonjour Madame, je suis votre voisin du…");
        } else {
            p.setRecommendedDurationSeconds(45);
            p.setAnswerStarter("Bonjour, je voudrais vous parler de…");
        }
        p.setDifficultyLevel(SkillDifficulty.EASY);
        p.setDisplayOrder(nextPromptDisplayOrder(skill));
        p.setActive(true);
        return skillPromptManager.save(p);
    }

    public SkillPrompt skillPrompt() {
        return skillPrompt(skill());
    }

    /** Premier rang libre dans la competence ({@code UNIQUE (skill_id, display_order)}, borne 1..20). */
    private short nextPromptDisplayOrder(Skill skill) {
        short max = 0;
        for (SkillPrompt existing : skillPromptManager.findActiveBySkillId(skill.getId())) {
            if (existing.getDisplayOrder() > max) max = existing.getDisplayOrder();
        }
        return (short) (max + 1);
    }

    /** Une production de reference. Un seul niveau par sujet ({@code UNIQUE (prompt, level)}). */
    public SkillReference skillReference(SkillPrompt prompt, SkillReferenceLevel level) {
        SkillReference r = new SkillReference();
        r.setSkillPrompt(prompt);
        r.setLevel(level);
        r.setText("Production de reference " + level + " " + next());
        r.setPedagogicalNote("Ce que cette reference demontre.");
        return skillPromptManager.saveReference(r);
    }

    public SkillReference skillReference() {
        return skillReference(skillPrompt(), SkillReferenceLevel.EXPECTED);
    }

    /**
     * Production ecrite d'un candidat, sans analyse IA demandee (statut final
     * {@code RECORDED}) : c'est le cas nominal du parcours gratuit.
     */
    public UserSkillAttempt userSkillAttempt(User user, SkillPrompt prompt) {
        UserSkillAttempt a = new UserSkillAttempt();
        a.setUser(user);
        a.setSkillPrompt(prompt);
        a.setWrittenProduction("Reponse du candidat " + next());
        a.setWordsCount(12);
        a.setStatut(SkillAttemptStatut.RECORDED);
        a.setAnalysisRequested(false);
        return userSkillAttemptManager.save(a);
    }

    public UserSkillAttempt userSkillAttempt() {
        return userSkillAttempt(user(), skillPrompt());
    }

    // ------------------------------------------------------------------------
    // Observations du Plan
    // ------------------------------------------------------------------------

    /**
     * Un signal source du Plan. La contrainte
     * {@code chk_learning_plan_observation_coherence} lie {@code observed},
     * {@code status} et {@code evidence} : la fabrique les pose ensemble pour
     * qu'un test ne puisse pas produire une ligne que la base refuserait.
     *
     * @param subjectId sujet travaille ({@code skill_prompts.id} ou
     *                  {@code production_tasks.id}) ; {@code null} accepte,
     *                  c'est le cas des lignes anterieures au suivi.
     */
    public LearningPlanObservation learningPlanObservation(
            User user, Skill skill, LearningPlanSourceType source,
            LearningPlanSkillStatus status, ObservationConfidence confidence,
            UUID subjectId, Instant observedAt) {
        LearningPlanObservation o = new LearningPlanObservation();
        o.setUser(user);
        o.setSkill(skill);
        o.setSourceType(source);
        o.setSourceId(UUID.randomUUID());
        o.setSubjectId(subjectId);
        boolean observed = status != LearningPlanSkillStatus.NOT_OBSERVED;
        o.setObserved(observed);
        o.setStatus(status);
        o.setEvidence(observed ? "Passage cite de la production " + next() : null);
        o.setExplanation("Ce que le correcteur a constate.");
        o.setConfidence(confidence);
        o.setBaseline(source == LearningPlanSourceType.DIAGNOSTIC_EE
                || source == LearningPlanSourceType.DIAGNOSTIC_EO);
        o.setObservedAt(observedAt);
        return learningPlanObservationManager.save(o);
    }

    // ------------------------------------------------------------------------
    // Funnel d'acquisition : cohorte, diagnostic, étapes navigateur
    // ------------------------------------------------------------------------

    /** Réécrit un compte modifié par le test (anonymisation, etc.). */
    public User saveUser(User user) {
        return userManager.save(user);
    }

    /** Compte avec sa provenance d'inscription (colonnes V036). */
    public User userFrom(String signupSource, ClientPlatform signupPlatform) {
        User u = user();
        u.setSignupSource(signupSource);
        u.setSignupPlatform(signupPlatform);
        return userManager.save(u);
    }

    /**
     * Session de diagnostic minimale. Les deux tâches ne portent pas de
     * {@code diagnostic_code} : la FK ne l'exige pas, et ce qui est testé ici
     * c'est l'agrégat, pas le contenu servi.
     */
    public DiagnosticSession diagnosticSession(User user, DiagnosticSessionStatus status) {
        long n = next();
        DiagnosticSession session = new DiagnosticSession();
        session.setUser(user);
        session.setDiagnosticCode("TEST_DIAG_" + n);
        session.setDiagnosticVersion(1);
        session.setWrittenTask(productionTask(EpreuveType.TCF_EE));
        session.setOralTask(productionTask(EpreuveType.TCF_EO));
        session.setWrittenAttempt(attempt(user));
        session.setOralAttempt(attempt(user));
        session.setStatus(status);
        session.setStartedAt(Instant.now());
        if (status == DiagnosticSessionStatus.COMPLETED) {
            // chk_diagnostic_session_completed exige les deux : une session
            // terminée porte sa date ET son résumé.
            session.setCompletedAt(Instant.now());
            session.setSummaryJson(Map.of("test", true));
        }
        return diagnosticSessionManager.saveAndFlush(session);
    }

    public DiagnosticSession diagnosticSession(User user) {
        return diagnosticSession(user, DiagnosticSessionStatus.IN_PROGRESS);
    }

    /** Étape de funnel : première occurrence, comme en production. */
    public void funnelEvent(User user, FunnelEvent event, ClientPlatform platform, String source) {
        userFunnelEventManager.recordFirstOccurrence(user.getId(), event, platform, source);
    }

    public void funnelEvent(User user, FunnelEvent event) {
        funnelEvent(user, event, ClientPlatform.WEB, "tiktok");
    }

    // ------------------------------------------------------------------------
    // SocialIdentity : record (DTO), pas une entité JPA — rien à persister.
    // Fournie pour compléter la couverture de la fabrique.
    // ------------------------------------------------------------------------

    public SocialIdentity socialIdentity() {
        long n = next();
        return new SocialIdentity(
                AuthProvider.GOOGLE,
                "google-sub-" + n,
                "social" + n + "@test.sejourfr",
                "Prénom",
                "Nom");
    }
}
