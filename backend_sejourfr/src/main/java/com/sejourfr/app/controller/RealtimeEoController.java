package com.sejourfr.app.controller;

import com.sejourfr.app.dto.AppendTranscriptRequest;
import com.sejourfr.app.dto.RealtimeSessionDescriptor;
import com.sejourfr.app.dto.RealtimeSessionStateResponse;
import com.sejourfr.app.dto.ResumeRealtimeSessionRequest;
import com.sejourfr.app.dto.StartRealtimeSessionRequest;
import com.sejourfr.app.security.CurrentUser;
import com.sejourfr.app.service.realtime.RealtimeQuotaService;
import com.sejourfr.app.service.realtime.RealtimeSessionService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;
import java.util.UUID;

/**
 * Expression orale en temps reel (examinateur IA, Taches 1 & 2). Authentifie
 * (sous {@code anyRequest().authenticated()}). Schema (A) : le backend emet un
 * token ephemere, le client ouvre lui-meme le WebSocket Gemini ; ici on ne fait
 * que provisionner, recevoir le transcript et tenir le quota.
 */
@RestController
@RequestMapping("/api/realtime/eo")
@RequiredArgsConstructor
public class RealtimeEoController {

    private final RealtimeSessionService sessionService;
    private final RealtimeQuotaService quotaService;
    private final CurrentUser currentUser;

    /** Sessions temps reel restantes (compteur du modal de lancement). */
    @GetMapping("/quota")
    public Map<String, Integer> quota() {
        RealtimeQuotaService.Quota q = quotaService.evaluate(currentUser.getId());
        return Map.of("remaining", q.remaining(), "cap", q.cap());
    }

    /**
     * Demarre une session T1/T2 : renvoie un descripteur {@code REALTIME} (token
     * + endpoint WS) si le quota le permet, sinon {@code ASYNC_FALLBACK} pour
     * basculer en enregistrement classique.
     */
    @PostMapping("/sessions")
    public RealtimeSessionDescriptor start(@Valid @RequestBody StartRealtimeSessionRequest req) {
        return sessionService.start(currentUser.get(), req);
    }

    /**
     * Reprend une session dont le WebSocket est tombe : nouveau token, MEME
     * conversation, MEME transcript, et surtout AUCUN nouveau slot debite.
     */
    @PostMapping("/sessions/{id}/resume")
    public RealtimeSessionDescriptor resume(@PathVariable("id") UUID id,
                                            @RequestBody(required = false) ResumeRealtimeSessionRequest req) {
        return sessionService.resume(currentUser.get(), id, req);
    }

    /** Fragment de transcript relaye par le client (debite le quota au 1er recu). */
    @PostMapping("/sessions/{id}/transcript")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void appendTranscript(@PathVariable("id") UUID id,
                                 @Valid @RequestBody AppendTranscriptRequest req) {
        sessionService.appendTranscript(currentUser.get(), id, req);
    }

    /** Cloture la session (COMPLETED si elle a eu lieu, sinon FAILED). */
    @PostMapping("/sessions/{id}/finish")
    public RealtimeSessionStateResponse finish(@PathVariable("id") UUID id) {
        return sessionService.finish(currentUser.get(), id);
    }
}
