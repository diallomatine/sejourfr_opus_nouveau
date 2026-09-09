package com.sejourfr.app.entity;

import com.sejourfr.app.enums.TcfDiagnosticStatus;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.UuidGenerator;

import java.time.Instant;
import java.util.UUID;

/**
 * Le diagnostic TCF 4 epreuves d'un candidat (V049).
 *
 * <p>🛑 <b>Ce n'est PAS un examen blanc</b> (10_ §4.1) : format reduit en
 * comprehension, gratuit une fois, il sert a construire le Plan. L'examen blanc
 * complet, au format reel, reste un objet distinct.
 *
 * <p>Cette table n'est qu'une <b>enveloppe</b> : elle porte l'echeance de
 * reprise, le statut d'ensemble et la version de configuration. L'etat des
 * sections est celui des sous-attempts, et les niveaux se recalculent a la
 * lecture — « derive serveur ⇒ jamais persiste ».
 */
@Entity
@Table(name = "tcf_diagnostic_sessions", indexes = {
        @Index(name = "idx_tcf_diagnostic_user", columnList = "user_id, started_at DESC")
})
@Getter
@Setter
public class TcfDiagnosticSession {

    @Id
    @UuidGenerator
    @Column(columnDefinition = "uuid")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    /** L'attempt {@code TCF_COMPLET} qui porte les 4 sous-epreuves. */
    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "parent_attempt_id", nullable = false, unique = true)
    private Attempt parentAttempt;

    /**
     * Version de configuration appliquee au tirage. Un diagnostic se relit avec
     * la configuration QUI L'A PRODUIT : sans elle, un recalibrage
     * reinterpreterait retroactivement des diagnostics deja passes.
     */
    @Column(name = "config_version", nullable = false)
    private int configVersion;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    private TcfDiagnosticStatus status = TcfDiagnosticStatus.IN_PROGRESS;

    @Column(name = "started_at", nullable = false)
    private Instant startedAt;

    /**
     * Echeance de <b>reprise</b>, pas de peremption du resultat (10_ §4.2).
     * Passee cette date, les sections realisees comptent toujours et les autres
     * restent « non evaluee » : rien n'est detruit.
     */
    @Column(name = "expires_at", nullable = false)
    private Instant expiresAt;

    @Column(name = "completed_at")
    private Instant completedAt;

    @PrePersist
    void prePersist() {
        if (startedAt == null) {
            startedAt = Instant.now();
        }
    }

    /** Le delai de reprise est-il ecoule ? Ne rend jamais le diagnostic invalide. */
    public boolean repriseEcoulee(Instant now) {
        return expiresAt != null && now.isAfter(expiresAt);
    }
}
