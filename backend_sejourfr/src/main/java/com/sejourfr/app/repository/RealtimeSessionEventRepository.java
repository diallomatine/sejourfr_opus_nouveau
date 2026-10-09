package com.sejourfr.app.repository;

import com.sejourfr.app.entity.RealtimeSessionEvent;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface RealtimeSessionEventRepository extends JpaRepository<RealtimeSessionEvent, UUID> {

    List<RealtimeSessionEvent> findBySessionIdOrderByCreatedAtAsc(UUID sessionId);
}
