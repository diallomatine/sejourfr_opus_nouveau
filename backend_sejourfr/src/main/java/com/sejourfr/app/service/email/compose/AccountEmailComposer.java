package com.sejourfr.app.service.email.compose;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EmailType;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.service.email.EmailFormats;
import com.sejourfr.app.service.email.EmailKeys;
import com.sejourfr.app.service.email.EmailLinks;
import com.sejourfr.app.service.email.EmailRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/**
 * Les mails du COMPTE, composes depuis la source (la ligne {@code users}).
 *
 * <p>Utilise a l'envoi initial comme a la relance differee : les variables ne
 * sont jamais stockees, elles se relisent ici.
 */
@Component
@RequiredArgsConstructor
public class AccountEmailComposer {

    private final UserManager userManager;
    private final EmailLinks links;

    @Transactional(readOnly = true)
    public Optional<EmailRequest> welcome(UUID userId, EmailRequest.Origin origin) {
        return activeUser(userId).map(user -> new EmailRequest(
                EmailType.WELCOME, user.getId(), user.getEmail(),
                Map.of("firstName", EmailFormats.firstName(user.getFirstName()),
                        "greeting", EmailFormats.greeting(user.getFirstName()),
                        "appUrl", links.dashboard()),
                EmailKeys.welcome(user.getId()), user.getId(), null, origin));
    }

    /** Un compte anonymise ou desactive ne recoit plus rien. */
    Optional<User> activeUser(UUID userId) {
        return userManager.findById(userId)
                .filter(u -> u.getDeletedAt() == null && u.isActive());
    }
}
