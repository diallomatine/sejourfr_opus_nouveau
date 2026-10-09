package com.sejourfr.app.manager;

import com.sejourfr.app.entity.RealtimeFallback;
import com.sejourfr.app.entity.RealtimeSessionEvent;
import com.sejourfr.app.entity.RealtimeSessionTurn;
import com.sejourfr.app.enums.RealtimeConductEventType;
import com.sejourfr.app.enums.RealtimeFallbackReason;
import com.sejourfr.app.repository.RealtimeFallbackRepository;
import com.sejourfr.app.repository.RealtimeSessionEventRepository;
import com.sejourfr.app.repository.RealtimeSessionTurnRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Mesure de la conduite de l'examinateur temps réel (V090) : segments horodatés,
 * événements de conduite, replis asynchrones. Rien de ce qui passe ici n'entre
 * dans une note, un niveau ou un quota.
 */
@Component
@RequiredArgsConstructor
public class RealtimeMesureManager {

    private final RealtimeSessionTurnRepository turnRepository;
    private final RealtimeSessionEventRepository eventRepository;
    private final RealtimeFallbackRepository fallbackRepository;

    /**
     * Ajoute un segment à la suite des précédents. À appeler sous le verrou de
     * ligne de la session : c'est lui qui rend le {@code seq} sans collision.
     */
    public RealtimeSessionTurn ajouterTour(UUID sessionId, Integer turnIndex, String speaker, String text,
                                           Integer startedAtMs, Integer endedAtMs) {
        RealtimeSessionTurn turn = new RealtimeSessionTurn();
        turn.setId(UUID.randomUUID());
        turn.setSessionId(sessionId);
        turn.setSeq((int) turnRepository.countBySessionId(sessionId));
        turn.setTurnIndex(turnIndex);
        turn.setSpeaker(speaker);
        turn.setText(text);
        turn.setWordCount(compterMots(text));
        turn.setStartedAtMs(startedAtMs);
        turn.setEndedAtMs(endedAtMs);
        turn.setCreatedAt(Instant.now());
        return turnRepository.save(turn);
    }

    public void ajouterEvenement(UUID sessionId, RealtimeConductEventType type, Integer atMs, Integer valueMs) {
        RealtimeSessionEvent event = new RealtimeSessionEvent();
        event.setId(UUID.randomUUID());
        event.setSessionId(sessionId);
        event.setType(type);
        event.setAtMs(atMs);
        event.setValueMs(valueMs);
        event.setCreatedAt(Instant.now());
        eventRepository.save(event);
    }

    public void tracerRepli(UUID userId, UUID productionTaskId, UUID sessionId, Short tacheNumero,
                            RealtimeFallbackReason reason) {
        RealtimeFallback fallback = new RealtimeFallback();
        fallback.setId(UUID.randomUUID());
        fallback.setUserId(userId);
        fallback.setProductionTaskId(productionTaskId);
        fallback.setSessionId(sessionId);
        fallback.setTacheNumero(tacheNumero);
        fallback.setReason(reason);
        fallback.setCreatedAt(Instant.now());
        fallbackRepository.save(fallback);
    }

    public List<RealtimeSessionTurn> tours(UUID sessionId) {
        return turnRepository.findBySessionIdOrderBySeqAsc(sessionId);
    }

    public List<RealtimeSessionEvent> evenements(UUID sessionId) {
        return eventRepository.findBySessionIdOrderByCreatedAtAsc(sessionId);
    }

    static int compterMots(String text) {
        if (text == null || text.isBlank()) return 0;
        return text.strip().split("\\s+").length;
    }
}
