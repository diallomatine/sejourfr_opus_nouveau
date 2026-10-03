package com.sejourfr.app.service.activity;

import com.sejourfr.app.entity.UserLoginEvent;
import com.sejourfr.app.enums.AuthKind;
import com.sejourfr.app.enums.AuthProvider;
import com.sejourfr.app.enums.ClientPlatform;
import com.sejourfr.app.manager.UserLoginEventManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.UUID;

/**
 * Journal des <b>ouvertures de session</b> ({@code user_login_event}, V087) :
 * une ligne par login ou inscription, jamais par refresh (D4).
 *
 * <p>Appele par {@code SessionService.openSession} <b>apres le commit</b> de
 * l'authentification ({@code util/ApresCommit}), dans sa propre transaction :
 * en Postgres, un {@code INSERT} en echec DANS la transaction de connexion
 * l'empoisonnerait et ferait echouer le login. Apres commit, un echec ne coute
 * qu'une ligne de mesure ({@code ApresCommit} l'avale et le journalise).
 */
@Service
@RequiredArgsConstructor
public class UserLoginEventService {

    private final UserLoginEventManager manager;

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void record(UUID userId, AuthKind kind, AuthProvider method, ClientPlatform platform,
                       Instant occurredAt) {
        UserLoginEvent event = new UserLoginEvent();
        event.setId(UUID.randomUUID());
        event.setUserId(userId);
        event.setOccurredAt(occurredAt);
        event.setKind(kind);
        event.setAuthMethod(method);
        event.setPlatform(platform == null ? ClientPlatform.UNKNOWN : platform);
        manager.save(event);
    }
}
