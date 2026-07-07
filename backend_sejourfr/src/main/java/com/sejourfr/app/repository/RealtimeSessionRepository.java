package com.sejourfr.app.repository;

import com.sejourfr.app.entity.RealtimeSession;
import com.sejourfr.app.enums.RealtimeSessionStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

/**
 * Les lignes {@code realtime_sessions} portent le cycle de vie d'une session
 * (PENDING → ACTIVE → COMPLETED | FAILED) et servent d'audit / analytics. Le
 * quota n'est PLUS dérivé de leur comptage : il vit sur
 * {@code user_subscriptions.realtime_eo_sessions_remaining} (cf. RealtimeQuotaService).
 */
@Repository
public interface RealtimeSessionRepository extends JpaRepository<RealtimeSession, UUID> {

    long countByStatus(RealtimeSessionStatus status);
}
