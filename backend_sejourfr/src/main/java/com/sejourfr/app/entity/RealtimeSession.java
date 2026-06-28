package com.sejourfr.app.entity;

import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.RealtimeSessionStatus;
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
import org.hibernate.annotations.UuidGenerator;

import java.time.Instant;
import java.util.UUID;

/**
 * Une session d'expression orale en temps reel (examinateur IA) pour une Tache 1
 * ou 2. Sert a deux choses : (1) tenir le QUOTA par pass (le ledger : une ligne
 * = une session, comptee quand elle passe ACTIVE), (2) capturer cote serveur le
 * TRANSCRIPT dialogue (examinateur + candidat) accumule au fil de l'echange,
 * qui alimentera ensuite la notation par le pipeline existant (lot 2).
 *
 * <p>Schema de connexion (A) : le client parle directement a Gemini (token
 * ephemere). Le serveur ne voit pas l'audio ; il recoit les fragments de
 * transcript que le client relaie (cf. {@code RealtimeSessionService}).
 */
@Entity
@Table(name = "realtime_sessions", indexes = {
        @Index(name = "idx_rt_session_user", columnList = "user_id, started_at DESC"),
        @Index(name = "idx_rt_session_quota", columnList = "subscription_id, status"),
        @Index(name = "idx_rt_session_attempt", columnList = "attempt_id")
})
public class RealtimeSession {

    @Id
    @UuidGenerator
    @Column(columnDefinition = "uuid")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    /**
     * Pass (souscription couvrante) au moment du demarrage. Porte le scope du
     * quota : le decompte se reinitialise par pass (un user empile/renouvelle
     * ses pass). NULL seulement pour un cas degrade (ne devrait pas arriver : le
     * temps reel n'est ouvert qu'aux pass TCF).
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "subscription_id")
    private UserSubscription subscription;

    /** Attempt rattache (entrainement isole ou sous-attempt d'examen complet). */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "attempt_id")
    private Attempt attempt;

    /** La consigne T1/T2 jouee (rôle examinateur + situation candidat). */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "production_task_id")
    private ProductionTask productionTask;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private EpreuveType epreuve;

    @Column(name = "tache_numero", nullable = false)
    private short tacheNumero;

    @Column(nullable = false, length = 32)
    private String provider;

    @Column(nullable = false, length = 128)
    private String model;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private RealtimeSessionStatus status = RealtimeSessionStatus.PENDING;

    /** Transcript dialogue accumule (examinateur + candidat). Source de notation. */
    @Column(columnDefinition = "text", nullable = false)
    private String transcript = "";

    /** Emission du token (creation de la session). */
    @Column(name = "started_at", nullable = false)
    private Instant startedAt;

    /** Premier fragment recu = connexion etablie = debit du quota. */
    @Column(name = "connected_at")
    private Instant connectedAt;

    @Column(name = "ended_at")
    private Instant endedAt;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @PrePersist
    void prePersist() {
        Instant now = Instant.now();
        if (startedAt == null) startedAt = now;
        if (createdAt == null) createdAt = now;
        if (updatedAt == null) updatedAt = now;
        if (transcript == null) transcript = "";
    }

    @PreUpdate
    void preUpdate() {
        updatedAt = Instant.now();
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }

    public UserSubscription getSubscription() { return subscription; }
    public void setSubscription(UserSubscription subscription) { this.subscription = subscription; }

    public Attempt getAttempt() { return attempt; }
    public void setAttempt(Attempt attempt) { this.attempt = attempt; }

    public ProductionTask getProductionTask() { return productionTask; }
    public void setProductionTask(ProductionTask productionTask) { this.productionTask = productionTask; }

    public EpreuveType getEpreuve() { return epreuve; }
    public void setEpreuve(EpreuveType epreuve) { this.epreuve = epreuve; }

    public short getTacheNumero() { return tacheNumero; }
    public void setTacheNumero(short tacheNumero) { this.tacheNumero = tacheNumero; }

    public String getProvider() { return provider; }
    public void setProvider(String provider) { this.provider = provider; }

    public String getModel() { return model; }
    public void setModel(String model) { this.model = model; }

    public RealtimeSessionStatus getStatus() { return status; }
    public void setStatus(RealtimeSessionStatus status) { this.status = status; }

    public String getTranscript() { return transcript; }
    public void setTranscript(String transcript) { this.transcript = transcript; }

    public Instant getStartedAt() { return startedAt; }
    public void setStartedAt(Instant startedAt) { this.startedAt = startedAt; }

    public Instant getConnectedAt() { return connectedAt; }
    public void setConnectedAt(Instant connectedAt) { this.connectedAt = connectedAt; }

    public Instant getEndedAt() { return endedAt; }
    public void setEndedAt(Instant endedAt) { this.endedAt = endedAt; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
