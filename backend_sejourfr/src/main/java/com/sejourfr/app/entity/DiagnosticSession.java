package com.sejourfr.app.entity;

import com.sejourfr.app.enums.ClientPlatform;
import com.sejourfr.app.enums.DiagnosticSessionStatus;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.annotations.UuidGenerator;
import org.hibernate.type.SqlTypes;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

/** Agrégat persistant et reprenable des deux productions du diagnostic. */
@Entity
@Table(name = "diagnostic_sessions", indexes = {
        @Index(name = "idx_diagnostic_session_user_updated", columnList = "user_id, updated_at DESC")
})
public class DiagnosticSession {

    @Id
    @UuidGenerator
    @Column(columnDefinition = "uuid")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "diagnostic_code", nullable = false, length = 64)
    private String diagnosticCode;

    @Column(name = "diagnostic_version", nullable = false)
    private int diagnosticVersion;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "written_task_id", nullable = false)
    private ProductionTask writtenTask;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "oral_task_id", nullable = false)
    private ProductionTask oralTask;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "written_attempt_id", nullable = false)
    private Attempt writtenAttempt;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "oral_attempt_id", nullable = false)
    private Attempt oralAttempt;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private DiagnosticSessionStatus status = DiagnosticSessionStatus.IN_PROGRESS;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "summary_json", columnDefinition = "jsonb")
    private Map<String, Object> summaryJson;

    @Column(name = "error_message", columnDefinition = "text")
    private String errorMessage;

    @Column(name = "retry_count", nullable = false)
    private short retryCount;

    /**
     * Plateforme sur laquelle la session a ete creee. {@code null} sur les
     * sessions anterieures a la mesure — rendu « UNKNOWN » a la lecture, jamais
     * devine depuis un user-agent.
     */
    @Enumerated(EnumType.STRING)
    @Column(length = 16)
    private ClientPlatform platform;

    @Column(name = "started_at", nullable = false, updatable = false)
    private Instant startedAt;

    @Column(name = "completed_at")
    private Instant completedAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @PrePersist
    void prePersist() {
        Instant now = Instant.now();
        if (startedAt == null) startedAt = now;
        if (updatedAt == null) updatedAt = now;
    }

    @PreUpdate
    void preUpdate() { updatedAt = Instant.now(); }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }
    public String getDiagnosticCode() { return diagnosticCode; }
    public void setDiagnosticCode(String diagnosticCode) { this.diagnosticCode = diagnosticCode; }
    public int getDiagnosticVersion() { return diagnosticVersion; }
    public void setDiagnosticVersion(int diagnosticVersion) { this.diagnosticVersion = diagnosticVersion; }
    public ProductionTask getWrittenTask() { return writtenTask; }
    public void setWrittenTask(ProductionTask writtenTask) { this.writtenTask = writtenTask; }
    public ProductionTask getOralTask() { return oralTask; }
    public void setOralTask(ProductionTask oralTask) { this.oralTask = oralTask; }
    public Attempt getWrittenAttempt() { return writtenAttempt; }
    public void setWrittenAttempt(Attempt writtenAttempt) { this.writtenAttempt = writtenAttempt; }
    public Attempt getOralAttempt() { return oralAttempt; }
    public void setOralAttempt(Attempt oralAttempt) { this.oralAttempt = oralAttempt; }
    public DiagnosticSessionStatus getStatus() { return status; }
    public void setStatus(DiagnosticSessionStatus status) { this.status = status; }
    public Map<String, Object> getSummaryJson() { return summaryJson; }
    public void setSummaryJson(Map<String, Object> summaryJson) {
        this.summaryJson = summaryJson == null ? null : new LinkedHashMap<>(summaryJson);
    }
    public String getErrorMessage() { return errorMessage; }
    public void setErrorMessage(String errorMessage) { this.errorMessage = errorMessage; }
    public short getRetryCount() { return retryCount; }
    public void setRetryCount(short retryCount) { this.retryCount = retryCount; }
    public ClientPlatform getPlatform() { return platform; }
    public void setPlatform(ClientPlatform platform) { this.platform = platform; }

    public Instant getStartedAt() { return startedAt; }
    public void setStartedAt(Instant startedAt) { this.startedAt = startedAt; }
    public Instant getCompletedAt() { return completedAt; }
    public void setCompletedAt(Instant completedAt) { this.completedAt = completedAt; }
    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
