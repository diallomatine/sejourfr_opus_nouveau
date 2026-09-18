package com.sejourfr.app.entity;

import com.sejourfr.app.enums.FreeEntitlementCode;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.UuidGenerator;

import java.time.Instant;
import java.util.UUID;

/**
 * <b>Une gratuite consommee</b> : « cet examen blanc EE lui a bien ete offert,
 * une fois, a cette date ».
 *
 * <p>C'est le <b>ledger unique</b> de l'arbitrage D-17. L'audit du 2026-09-18 a
 * releve <b>quatre</b> manieres differentes de deviner « premiere fois
 * gratuite » — {@code ProductionAccessService}, {@code
 * ProductionSubmissionManager.hasFullExamProductionSubmission}, {@code
 * attempts.production_locked} et la convention « slot &le; 1 » — et aucune ne
 * sait distinguer un freebie <b>consomme</b> d'un examen <b>abandonne</b>.
 * Quatre facons de dire la meme chose finissent toujours par se contredire.
 *
 * <p>🛑 <b>La ligne s'ecrit a la REMISE DE L'ANALYSE.</b> Ni au demarrage de
 * l'examen, ni sur {@code doFinish} seul : un abandon, une expiration, un echec
 * technique ou un echec du correcteur laissent le freebie <b>intact</b> et le
 * candidat le retrouve. Sinon « offert une fois » voudrait dire « perdu une
 * fois », et ce serait une promesse trahie a l'ecran.
 *
 * <p>⚠️ <b>Rien ne lit ni n'ecrit cette table aujourd'hui</b> : la bascule des
 * quatre mecaniques existantes est en P4. D'ici la, elles restent seules en
 * vigueur.
 */
@Entity
@Table(name = "free_entitlement_usage")
@Getter
@Setter
public class FreeEntitlementUsage {

    @Id
    @UuidGenerator
    @Column(columnDefinition = "uuid")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    /**
     * Laquelle des gratuites. 🛑 <b>Une seule ligne par (candidat, code)</b>,
     * tenue par {@code uq_free_entitlement_usage} : deux requetes concurrentes
     * ne se voient pas l'une l'autre, et ce qui est en jeu est une correction
     * LLM payee deux fois pour une gratuite qui n'en valait qu'une. Meme
     * discipline que {@code production_submissions.client_submission_id} (V046).
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "code", nullable = false, length = 48)
    private FreeEntitlementCode code;

    @Column(name = "consumed_at", nullable = false)
    private Instant consumedAt;

    /**
     * La session qui a consomme la gratuite, pour la tracabilite du support.
     *
     * <p><b>Nullable, et le restera</b> : la base efface la reference quand la
     * session disparait ({@code ON DELETE SET NULL}) parce que la disparition
     * d'une trace ne doit pas <b>rendre</b> une gratuite deja honoree. Le fait
     * survit a sa preuve.
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "source_attempt_id")
    private Attempt sourceAttempt;

    @PrePersist
    void prePersist() {
        if (consumedAt == null) consumedAt = Instant.now();
    }
}
