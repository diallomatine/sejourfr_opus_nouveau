package com.sejourfr.app.repository;

import com.sejourfr.app.entity.RealtimeSessionTurn;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface RealtimeSessionTurnRepository extends JpaRepository<RealtimeSessionTurn, UUID> {

    long countBySessionId(UUID sessionId);

    List<RealtimeSessionTurn> findBySessionIdOrderBySeqAsc(UUID sessionId);
}
