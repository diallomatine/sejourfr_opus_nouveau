package com.sejourfr.app.entity;

import com.sejourfr.app.enums.AttemptMode;
import com.sejourfr.app.enums.AttemptStatus;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.enums.TargetLevel;
import org.hibernate.annotations.UuidGenerator;
import jakarta.persistence.*;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "attempts", indexes = {
        @Index(name = "idx_attempt_user", columnList = "user_id"),
        @Index(name = "idx_attempt_status", columnList = "status")
})
public class Attempt {

    @Id
    @UuidGenerator
    @Column(columnDefinition = "uuid")
    private UUID id;

    // user_id devient nullable depuis V100 : un attempt "démo guest" (lancé
    // depuis la landing par un visiteur non authentifié) n'a pas de user.
    // Pour ces attempts, client_ip est posée à la place et sert au quota.
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user;

    @Column(name = "client_ip", length = 45)
    private String clientIp;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "exam_template_id")
    private ExamTemplate examTemplate;

    @Enumerated(EnumType.STRING)
    @Column(name = "type", length = 16)
    private AttemptType type;

    @Enumerated(EnumType.STRING)
    @Column(name = "module", length = 16)
    private Module module;

    // Granularite fine de l'epreuve (ex: TCF_CO, TCF_EO). Orthogonal a `mode`
    // et `module`. Backfill V100 : derive du module pour les attempts historiques.
    @Enumerated(EnumType.STRING)
    @Column(name = "epreuve", nullable = false, length = 20)
    private EpreuveType epreuve;

    // Pour les examens blancs TCF complets : ce parent porte TCF_COMPLET et
    // chaque sous-attempt porte sa propre epreuve. NULL pour un attempt isole.
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "parent_attempt_id")
    private Attempt parentAttempt;

    @OneToMany(mappedBy = "parentAttempt", fetch = FetchType.LAZY)
    private List<Attempt> subAttempts = new ArrayList<>();

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    private AttemptMode mode;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    private AttemptStatus status;

    @Column(name = "total_questions")
    private Integer totalQuestions;

    @Column(name = "time_limit_seconds")
    private Integer timeLimitSeconds;

    @Column(name = "pass_threshold")
    private Integer passThreshold;

    @Column
    private Integer score;

    @Column(name = "max_score")
    private Integer maxScore;

    @Enumerated(EnumType.STRING)
    @Column(name = "level_achieved", length = 8)
    private TargetLevel levelAchieved;

    @Column(name = "started_at", nullable = false)
    private Instant startedAt;

    @Column(name = "finished_at")
    private Instant finishedAt;

    // Lien vers le lot d'origine (TCF QCM). NULL pour les attempts libres,
    // les examens blancs, ou les productions. Cf. `LotService` + migration V097.
    @Column(name = "lot_numero")
    private Integer lotNumero;

    @Enumerated(EnumType.STRING)
    @Column(name = "lot_question_type", length = 24)
    private QuestionType lotQuestionType;

    @Enumerated(EnumType.STRING)
    @Column(name = "lot_difficulty", length = 8)
    private Difficulty lotDifficulty;

    // Lots Civique : identifient un lot par son thème (les TCF utilisent
    // difficulty + questionType à la place). NULL pour les lots TCF, les
    // examens et les attempts non-lot. Cf. migration V100.
    @Column(name = "lot_theme_id", columnDefinition = "uuid")
    private UUID lotThemeId;

    // Examen blanc scopé à une épreuve TCF QCM (CO ou CE). NULL pour les
    // examens blancs complets et les attempts non-MOCK_EXAM. Cf. migration V098
    // et `AttemptService.startModuleExam`.
    @Enumerated(EnumType.STRING)
    @Column(name = "module_exam_question_type", length = 24)
    private QuestionType moduleExamQuestionType;

    // Numéro de slot stable d'examen blanc dans la grille UI (TCF QCM, TCF
    // complet, civique global, civique thématique). Cf. migration V110.
    // - NULL pour tout sauf MOCK_EXAM standalone.
    // - NULL aussi pour les sous-attempts d'un TCF complet (parent non null).
    // - Plusieurs attempts peuvent partager le même slot_number (refait
    //   successif) ; l'UI prend toujours le plus récent par slot.
    @Column(name = "slot_number")
    private Integer slotNumber;

    // Score pondéré par niveau (A2=1, B1=2, B2=3) — calculé à la finalisation
    // des examens module pour éviter de re-joindre questions à chaque lecture.
    // Reste NULL pour les autres attempts (training, examens complets, lots).
    @Column(name = "weighted_score")
    private Integer weightedScore;

    @Column(name = "max_weighted_score")
    private Integer maxWeightedScore;

    // Niveau CECRL plancher (TCF_COMPLET uniquement) — règle officielle TCF IRN
    // où le niveau final = min des 4 sous-épreuves. Posé à la finalisation. NULL
    // tant que toutes les évaluations IA (EE/EO) ne sont pas EVALUATED.
    @Enumerated(EnumType.STRING)
    @Column(name = "final_cecrl_level", length = 24)
    private NiveauCecrl finalCecrlLevel;

    @OneToMany(mappedBy = "attempt", fetch = FetchType.LAZY, cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderBy("position ASC")
    private List<AttemptQuestion> questions = new ArrayList<>();

    @PrePersist
    void prePersist() {
        if (startedAt == null) startedAt = Instant.now();
        // mode / status sont NOT NULL en base : on dérive du type si rien n'a été posé.
        if (mode == null) mode = deriveModeFromType(type);
        if (status == null) status = AttemptStatus.EN_COURS;
        // epreuve devient NOT NULL en V100 : pour le code legacy qui ne pose pas
        // encore la valeur, on retombe sur le module (CIVIQUE/TCF -> TCF_CO).
        if (epreuve == null) epreuve = deriveEpreuveFromModule(module);
    }

    private static AttemptMode deriveModeFromType(AttemptType t) {
        if (t == null) return AttemptMode.ENTRAINEMENT;
        return switch (t) {
            case TRAINING -> AttemptMode.ENTRAINEMENT;
            case MOCK_EXAM -> AttemptMode.EXAMEN;
            case REVIEW -> AttemptMode.REVISION;
        };
    }

    private static EpreuveType deriveEpreuveFromModule(Module m) {
        if (m == null) return EpreuveType.CIVIQUE;
        return switch (m) {
            case CIVIQUE -> EpreuveType.CIVIQUE;
            case TCF -> EpreuveType.TCF_CO;
        };
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }

    public String getClientIp() { return clientIp; }
    public void setClientIp(String clientIp) { this.clientIp = clientIp; }

    public ExamTemplate getExamTemplate() { return examTemplate; }
    public void setExamTemplate(ExamTemplate examTemplate) { this.examTemplate = examTemplate; }

    public AttemptType getType() { return type; }
    public void setType(AttemptType type) { this.type = type; }

    public Module getModule() { return module; }
    public void setModule(Module module) { this.module = module; }

    public EpreuveType getEpreuve() { return epreuve; }
    public void setEpreuve(EpreuveType epreuve) { this.epreuve = epreuve; }

    public Attempt getParentAttempt() { return parentAttempt; }
    public void setParentAttempt(Attempt parentAttempt) { this.parentAttempt = parentAttempt; }

    public List<Attempt> getSubAttempts() { return subAttempts; }
    public void setSubAttempts(List<Attempt> subAttempts) { this.subAttempts = subAttempts; }

    public AttemptMode getMode() { return mode; }
    public void setMode(AttemptMode mode) { this.mode = mode; }

    public AttemptStatus getStatus() { return status; }
    public void setStatus(AttemptStatus status) { this.status = status; }

    public Integer getTotalQuestions() { return totalQuestions; }
    public void setTotalQuestions(Integer totalQuestions) { this.totalQuestions = totalQuestions; }

    public Integer getTimeLimitSeconds() { return timeLimitSeconds; }
    public void setTimeLimitSeconds(Integer timeLimitSeconds) { this.timeLimitSeconds = timeLimitSeconds; }

    public Integer getPassThreshold() { return passThreshold; }
    public void setPassThreshold(Integer passThreshold) { this.passThreshold = passThreshold; }

    public Integer getScore() { return score; }
    public void setScore(Integer score) { this.score = score; }

    public Integer getMaxScore() { return maxScore; }
    public void setMaxScore(Integer maxScore) { this.maxScore = maxScore; }

    public TargetLevel getLevelAchieved() { return levelAchieved; }
    public void setLevelAchieved(TargetLevel levelAchieved) { this.levelAchieved = levelAchieved; }

    public Instant getStartedAt() { return startedAt; }
    public void setStartedAt(Instant startedAt) { this.startedAt = startedAt; }

    public Instant getFinishedAt() { return finishedAt; }
    public void setFinishedAt(Instant finishedAt) { this.finishedAt = finishedAt; }

    public List<AttemptQuestion> getQuestions() { return questions; }
    public void setQuestions(List<AttemptQuestion> questions) { this.questions = questions; }

    public Integer getLotNumero() { return lotNumero; }
    public void setLotNumero(Integer lotNumero) { this.lotNumero = lotNumero; }

    public QuestionType getLotQuestionType() { return lotQuestionType; }
    public void setLotQuestionType(QuestionType lotQuestionType) { this.lotQuestionType = lotQuestionType; }

    public Difficulty getLotDifficulty() { return lotDifficulty; }
    public void setLotDifficulty(Difficulty lotDifficulty) { this.lotDifficulty = lotDifficulty; }

    public UUID getLotThemeId() { return lotThemeId; }
    public void setLotThemeId(UUID lotThemeId) { this.lotThemeId = lotThemeId; }

    public QuestionType getModuleExamQuestionType() { return moduleExamQuestionType; }
    public void setModuleExamQuestionType(QuestionType moduleExamQuestionType) { this.moduleExamQuestionType = moduleExamQuestionType; }

    public Integer getSlotNumber() { return slotNumber; }
    public void setSlotNumber(Integer slotNumber) { this.slotNumber = slotNumber; }

    public Integer getWeightedScore() { return weightedScore; }
    public void setWeightedScore(Integer weightedScore) { this.weightedScore = weightedScore; }

    public Integer getMaxWeightedScore() { return maxWeightedScore; }
    public void setMaxWeightedScore(Integer maxWeightedScore) { this.maxWeightedScore = maxWeightedScore; }

    public NiveauCecrl getFinalCecrlLevel() { return finalCecrlLevel; }
    public void setFinalCecrlLevel(NiveauCecrl finalCecrlLevel) { this.finalCecrlLevel = finalCecrlLevel; }
}
