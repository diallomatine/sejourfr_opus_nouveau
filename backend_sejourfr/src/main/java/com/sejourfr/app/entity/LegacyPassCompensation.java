package com.sejourfr.app.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.UuidGenerator;

import java.time.Instant;
import java.util.UUID;

/**
 * Trace du geste commercial V038 envers les acheteurs de l'ancien catalogue
 * Intégral (pass sprint 6 semaines / pass 3 mois) : jours d'accès rouverts et
 * plancher de simulations orales garanti.
 *
 * <p>Trois usages, tous portés par cette seule table :
 * <ul>
 *   <li><b>audit</b> — ce qui a été donné, et l'état d'avant ({@code
 *       endsAtBefore} / {@code sessionsBefore}), donc de quoi défaire ;</li>
 *   <li><b>anti-doublon du mailing</b> — {@code mailedAt}, contrainte unique sur
 *       {@code user_id} : un compte ne peut pas être compensé ni prévenu deux
 *       fois, quelle que soit la façon dont l'envoi est relancé ;</li>
 *   <li><b>ciblage</b> — {@code subscriptionId} est la souscription réellement
 *       créditée, pas forcément celle du pass qui a ouvert le droit
 *       ({@code planCode}).</li>
 * </ul>
 *
 * <p>Écrite par la migration, jamais par le code applicatif : seul
 * {@code mailedAt} est posé à l'exécution.
 */
@Entity
@Table(name = "legacy_pass_compensations")
@Getter
@Setter
public class LegacyPassCompensation {

    @Id
    @UuidGenerator
    @Column(columnDefinition = "uuid")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    /** Souscription effectivement créditée (celle que l'app lira). */
    @Column(name = "subscription_id", nullable = false, columnDefinition = "uuid")
    private UUID subscriptionId;

    /** Pass qui a ouvert le droit — donc le barème appliqué. */
    @Column(name = "plan_code", nullable = false, length = 64)
    private String planCode;

    @Column(name = "days_granted", nullable = false)
    private int daysGranted;

    @Column(name = "ends_at_before")
    private Instant endsAtBefore;

    @Column(name = "ends_at_after")
    private Instant endsAtAfter;

    @Column(name = "sessions_before", nullable = false)
    private int sessionsBefore;

    @Column(name = "sessions_after", nullable = false)
    private int sessionsAfter;

    @Column(name = "granted_at", nullable = false)
    private Instant grantedAt;

    /** {@code null} tant que l'e-mail d'annonce n'est pas parti. */
    @Column(name = "mailed_at")
    private Instant mailedAt;
}
