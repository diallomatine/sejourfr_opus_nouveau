package com.sejourfr.app.entity;

import com.sejourfr.app.enums.ClientPlatform;
import com.sejourfr.app.enums.DiagnosticRunType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;
import java.util.UUID;

/**
 * Un passage dans le tunnel diagnostic ({@code diagnostic_run}, V074) : la
 * <b>trace</b>, jamais le contenu. Aucun texte, aucun audio, aucune reponse
 * (invariant V053, arbitrage Q3).
 *
 * <p>Le cycle de vie (creation publique, « soumis », claim) est ecrit au lot 2
 * du chantier Suivi. L'ingestion d'analytics s'en sert deja pour verifier
 * qu'une run citee par un evenement existe, et en deduire son type cote
 * serveur.
 */
@Entity
@Table(name = "diagnostic_run")
@Getter
@Setter
public class DiagnosticRun {

    @Id
    @Column(columnDefinition = "uuid")
    private UUID id;

    @Enumerated(EnumType.STRING)
    @Column(name = "diagnostic_type", nullable = false, length = 16)
    private DiagnosticRunType diagnosticType;

    @Enumerated(EnumType.STRING)
    @Column(name = "platform", length = 16)
    private ClientPlatform platform;

    @Column(name = "app_version", length = 32)
    private String appVersion;

    @Column(name = "anonymous_id", columnDefinition = "uuid")
    private UUID anonymousId;

    @Column(name = "user_id", columnDefinition = "uuid")
    private UUID userId;

    @Column(name = "client_key", columnDefinition = "uuid")
    private UUID clientKey;

    @Column(name = "subject_viewed_at", nullable = false)
    private Instant subjectViewedAt;

    @Column(name = "submitted_at")
    private Instant submittedAt;

    @Column(name = "submitted_authenticated")
    private Boolean submittedAuthenticated;

    @Column(name = "claim_token_hash", length = 64)
    private String claimTokenHash;

    @Column(name = "claim_token_expires_at")
    private Instant claimTokenExpiresAt;

    @Column(name = "claimed_at")
    private Instant claimedAt;

    @Column(name = "claim_kind", length = 8)
    private String claimKind;

    @Column(name = "claimed_via", length = 16)
    private String claimedVia;

    @Column(name = "diagnostic_session_id", columnDefinition = "uuid")
    private UUID diagnosticSessionId;

    @Column(name = "tcf_diagnostic_session_id", columnDefinition = "uuid")
    private UUID tcfDiagnosticSessionId;

    @Column(name = "civic_diagnostic_session_id", columnDefinition = "uuid")
    private UUID civicDiagnosticSessionId;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;
}
