package com.sejourfr.app.entity;

import com.sejourfr.app.audioquestion.domain.AudioMode;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.DifficultyBand;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionStatus;
import com.sejourfr.app.enums.QuestionType;
import org.hibernate.annotations.UuidGenerator;
import jakarta.persistence.*;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "questions", indexes = {
        @Index(name = "idx_question_module_active", columnList = "module,is_active"),
        @Index(name = "idx_question_theme", columnList = "theme_id"),
        @Index(name = "idx_question_difficulty", columnList = "difficulty"),
        @Index(name = "idx_questions_status", columnList = "status")
})
public class Question {

    @Id
    @UuidGenerator
    @Column(columnDefinition = "uuid")
    private UUID id;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    private Module module;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "theme_id", nullable = false)
    private Theme theme;

    /**
     * Notion civique <b>VALIDEE PAR UN HUMAIN</b> (V051, lot L8).
     *
     * <p>🛑 <b>{@code null} = pas encore taguee</b>, jamais « sans notion ».
     * Une question non taguee attend ; elle n'est pas hors programme.
     *
     * <p>🛑 A ne pas confondre avec {@code question_notion_suggestions}, ou une
     * machine PROPOSE. Le tag qui fait foi est celui-ci, et lui seul.
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "civic_notion_id")
    private CivicNotion civicNotion;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "passage_id")
    private Passage passage;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "media_id")
    private Media media;

    /**
     * Second média audio, utilisé uniquement par les questions {@code CO_IMAGE} :
     * {@link #media} porte alors l'image support et ce champ l'audio des 4
     * propositions lues. NULL pour tous les autres types.
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "audio_media_id")
    private Media audioMedia;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 8)
    private Difficulty difficulty;

    /**
     * La bande de difficulté <b>dans</b> le palier (V4.2 §7) — à ne pas
     * confondre avec {@link #difficulty}, qui porte le palier lui-même.
     *
     * <p>🛑 <b>Nullable, et sans valeur par défaut.</b> Le catalogue historique
     * n'est pas tagué, et lui affecter « MEDIUM » d'office affirmerait une
     * mesure qui n'a pas eu lieu — indiscernable d'un vrai tag le jour où on
     * commencera à taguer. Une série dont une seule question n'a pas de bande
     * est {@code UNCALIBRATED} : elle compte dans la maîtrise et la progression
     * visible, avec un poids réduit, mais ne verrouille jamais un palier.
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "difficulty_band", length = 8)
    private DifficultyBand difficultyBand;

    @Enumerated(EnumType.STRING)
    @Column(name = "question_type", nullable = false, length = 24)
    private QuestionType questionType;

    @Column(nullable = false, columnDefinition = "text")
    private String statement;

    @Column(columnDefinition = "text")
    private String explanation;

    @Column(name = "is_active", nullable = false)
    private boolean active = true;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    private QuestionStatus status = QuestionStatus.ACTIVE;

    @Column(name = "tcf_sub_theme", length = 64)
    private String tcfSubTheme;

    @Column(name = "competence_code", length = 64)
    private String competenceCode;

    @Enumerated(EnumType.STRING)
    @Column(name = "audio_mode", length = 32)
    private AudioMode audioMode;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at")
    private Instant updatedAt;

    @OneToMany(mappedBy = "question", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @OrderBy("displayOrder ASC")
    private List<Choice> choices = new ArrayList<>();

    @PrePersist
    void prePersist() {
        Instant now = Instant.now();
        if (createdAt == null) createdAt = now;
        updatedAt = now;
    }

    @PreUpdate
    void preUpdate() {
        updatedAt = Instant.now();
    }

    public void addChoice(Choice c) {
        c.setQuestion(this);
        this.choices.add(c);
    }

    public void clearChoices() {
        this.choices.clear();
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public Module getModule() { return module; }
    public void setModule(Module module) { this.module = module; }

    public Theme getTheme() { return theme; }
    public void setTheme(Theme theme) { this.theme = theme; }

    public CivicNotion getCivicNotion() { return civicNotion; }
    public void setCivicNotion(CivicNotion civicNotion) { this.civicNotion = civicNotion; }

    public Passage getPassage() { return passage; }
    public void setPassage(Passage passage) { this.passage = passage; }

    public Media getMedia() { return media; }
    public void setMedia(Media media) { this.media = media; }

    public Media getAudioMedia() { return audioMedia; }
    public void setAudioMedia(Media audioMedia) { this.audioMedia = audioMedia; }

    public Difficulty getDifficulty() { return difficulty; }
    public void setDifficulty(Difficulty difficulty) { this.difficulty = difficulty; }
    public DifficultyBand getDifficultyBand() { return difficultyBand; }
    public void setDifficultyBand(DifficultyBand difficultyBand) { this.difficultyBand = difficultyBand; }

    public QuestionType getQuestionType() { return questionType; }
    public void setQuestionType(QuestionType questionType) { this.questionType = questionType; }

    public String getStatement() { return statement; }
    public void setStatement(String statement) { this.statement = statement; }

    public String getExplanation() { return explanation; }
    public void setExplanation(String explanation) { this.explanation = explanation; }

    public boolean isActive() { return active; }
    public void setActive(boolean active) { this.active = active; }

    public QuestionStatus getStatus() { return status; }
    public void setStatus(QuestionStatus status) { this.status = status; }

    public String getTcfSubTheme() { return tcfSubTheme; }
    public void setTcfSubTheme(String tcfSubTheme) { this.tcfSubTheme = tcfSubTheme; }

    public String getCompetenceCode() { return competenceCode; }
    public void setCompetenceCode(String competenceCode) { this.competenceCode = competenceCode; }

    public AudioMode getAudioMode() { return audioMode; }
    public void setAudioMode(AudioMode audioMode) { this.audioMode = audioMode; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }

    public List<Choice> getChoices() { return choices; }
    public void setChoices(List<Choice> choices) { this.choices = choices; }
}
