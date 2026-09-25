package com.sejourfr.app.service.email;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.manager.UserManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/**
 * Le desabonnement des mails ENGAGEMENT par lien (brief §6, arbitrage n°12).
 *
 * <ul>
 *   <li>La page GET ne modifie RIEN : un scanner de liens (antivirus, SafeLinks)
 *       qui suit l'URL ne desabonne personne.</li>
 *   <li>Le POST du formulaire et le POST one-click (RFC 8058) desactivent
 *       {@code engagement_enabled}.</li>
 *   <li>Jeton invalide, compte inconnu ou supprime : la MEME page neutre, sans
 *       rien reveler.</li>
 * </ul>
 * Les pages sont rendues par le backend, sur le patron de la confirmation de
 * changement d'email.
 */
@Service
@RequiredArgsConstructor
public class EmailUnsubscribeService {

    static final String CONFIRM_PAGE = "email/pages/unsubscribe-confirm.html";
    static final String MESSAGE_PAGE = "email/pages/message.html";

    private final UnsubscribeTokenService tokens;
    private final UserManager userManager;
    private final EmailPreferenceService preferences;
    private final MailTemplateRenderer renderer;
    private final EmailLinks links;

    /** Une page HTML et son statut HTTP. */
    public record Page(int status, String html) {}

    @Transactional(readOnly = true)
    public Page confirmation(String token) {
        if (resolve(token).isEmpty()) {
            return neutral();
        }
        return new Page(200, renderer.render(CONFIRM_PAGE, Map.of(
                "formAction", links.unsubscribeFormAction(),
                "token", token)));
    }

    @Transactional
    public Page unsubscribe(String token) {
        Optional<UUID> userId = resolve(token);
        if (userId.isEmpty()) {
            return neutral();
        }
        preferences.disableEngagement(userId.get());
        return new Page(200, renderer.render(MESSAGE_PAGE, Map.of(
                "title", "Désinscription confirmée",
                "message", "Vous ne recevrez plus les conseils et rappels d'entraînement.",
                "detail", "Les emails indispensables liés à votre compte, votre sécurité ou vos "
                        + "paiements continueront à être envoyés. Vous pouvez réactiver les rappels "
                        + "à tout moment depuis « Notifications par e-mail » dans votre compte.")));
    }

    /** RFC 8058 : le client mail poste sans afficher la reponse. */
    @Transactional
    public boolean oneClick(String token) {
        Optional<UUID> userId = resolve(token);
        userId.ifPresent(preferences::disableEngagement);
        return userId.isPresent();
    }

    /** Un jeton valide ET un compte encore actif ; tout le reste est indistinct. */
    private Optional<UUID> resolve(String token) {
        return tokens.verify(token)
                .flatMap(userManager::findById)
                .filter(u -> u.getDeletedAt() == null && u.isActive())
                .map(User::getId);
    }

    private Page neutral() {
        return new Page(400, renderer.render(MESSAGE_PAGE, Map.of(
                "title", "Lien invalide",
                "message", "Ce lien n'est pas valide.",
                "detail", "Vous pouvez gérer vos préférences d'e-mails depuis « Notifications par "
                        + "e-mail » dans votre compte SejourFR.")));
    }
}
