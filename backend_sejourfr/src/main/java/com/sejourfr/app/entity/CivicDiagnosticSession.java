package com.sejourfr.app.entity;

import com.sejourfr.app.enums.Difficulty;
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
 * Le diagnostic civique d'un candidat (V052, lot L9).
 *
 * <p>🛑 <b>Ce n'est PAS un examen blanc</b> (20_ §4.1) : 24 questions au lieu de
 * 40, couverture equilibree sur les 5 themes au lieu de representative, et il
 * CREE le plan au lieu de verifier la preparation. Les deux objets coexistent,
 * et {@code attempts.civic_diagnostic_id} les tient a l'ecart l'un de l'autre.
 *
 * <p>Cette table n'est qu'une <b>enveloppe</b> : les reponses vivent dans
 * {@code attempt_questions}, et les etats par theme comme la projection se
 * recalculent a la lecture — « derive serveur ⇒ jamais persiste ».
 */
@Entity
@Table(name = "civic_diagnostic_sessions", indexes = {
        @Index(name = "idx_civic_diagnostic_user", columnList = "user_id, started_at DESC")
})
@Getter
@Setter
public class CivicDiagnosticSession {

    @Id
    @UuidGenerator
    @Column(columnDefinition = "uuid")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    /** L'attempt qui porte les 24 questions. Un seul : pas de sous-epreuves. */
    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "attempt_id", nullable = false, unique = true)
    private Attempt attempt;

    /**
     * La mention du candidat <b>au moment du diagnostic</b>.
     *
     * <p>🛑 Recopiee, jamais relue depuis {@code users} : changer de demarche ne
     * doit pas reinterpreter un diagnostic deja passe.
     */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 8)
    private Difficulty mention;

    /**
     * Version de configuration appliquee. Un diagnostic se relit avec la
     * configuration QUI L'A PRODUIT.
     */
    @Column(name = "config_version", nullable = false)
    private int configVersion;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    private TcfDiagnosticStatus status = TcfDiagnosticStatus.IN_PROGRESS;

    @Column(name = "started_at", nullable = false)
    private Instant startedAt;

    @Column(name = "completed_at")
    private Instant completedAt;

    @PrePersist
    void prePersist() {
        if (startedAt == null) {
            startedAt = Instant.now();
        }
    }
}
