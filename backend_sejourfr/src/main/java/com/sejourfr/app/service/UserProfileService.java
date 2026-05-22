package com.sejourfr.app.service;

import com.sejourfr.app.entity.EmailChangeToken;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AuthProvider;
import com.sejourfr.app.manager.EmailChangeTokenManager;
import com.sejourfr.app.manager.UserManager;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.UUID;

/**
 * Profil utilisateur "compte" : mise à jour des champs d'identité
 * (firstName/lastName), mot de passe, et changement d'email avec
 * vérification.
 *
 * <p>Sépare ces responsabilités de {@link MeService} pour garder
 * {@code MeService} centré sur les données pédagogiques (stats, favoris,
 * erreurs). Ce service ne touche jamais le repository directement — il passe
 * par les managers.
 */
@Service
@Slf4j
@RequiredArgsConstructor
public class UserProfileService {

    /** Durée de validité du lien de confirmation de changement d'email. */
    private static final Duration EMAIL_CHANGE_TOKEN_TTL = Duration.ofHours(1);

    /** 32 octets de random → token URL-safe ~43 caractères. */
    private static final int EMAIL_CHANGE_TOKEN_BYTES = 32;

    private final UserManager userManager;
    private final EmailChangeTokenManager emailChangeTokenManager;
    private final PasswordEncoder passwordEncoder;
    private final MailService mailService;
    private final SessionService sessionService;
    private final SecureRandom random = new SecureRandom();

    // ------------------------------------------------------------------------
    // Profil — prénom, nom
    // ------------------------------------------------------------------------

    /** Met à jour le prénom / nom du user. */
    @Transactional
    public void updateProfile(UUID userId, String firstName, String lastName) {
        User user = loadUser(userId);
        user.setFirstName(firstName.trim());
        user.setLastName(lastName.trim());
        userManager.save(user);
    }

    // ------------------------------------------------------------------------
    // Mot de passe
    // ------------------------------------------------------------------------

    /**
     * Change le mot de passe. Refuse si l'ancien mot de passe est incorrect.
     * Refuse aussi pour les comptes social (Google/Apple) qui n'ont pas de
     * passwordHash : ils doivent passer par leur provider.
     */
    @Transactional
    public void changePassword(UUID userId, String currentPassword, String newPassword) {
        User user = loadUser(userId);

        if (user.getPasswordHash() == null || user.getAuthProvider() != AuthProvider.LOCAL) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Votre compte est connecté via " + user.getAuthProvider()
                            + ". Le mot de passe se gère depuis votre fournisseur.");
        }

        if (!passwordEncoder.matches(currentPassword, user.getPasswordHash())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Mot de passe actuel incorrect.");
        }

        if (passwordEncoder.matches(newPassword, user.getPasswordHash())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Le nouveau mot de passe doit être différent de l'actuel.");
        }

        user.setPasswordHash(passwordEncoder.encode(newPassword));
        userManager.save(user);

        // Cascade : révoque toutes les autres sessions actives. Un attaquant
        // qui détenait un refresh token devient incapable de prolonger sa
        // session — l'utilisateur devra se reconnecter avec le nouveau mdp.
        sessionService.revokeAllForUser(userId);
    }

    // ------------------------------------------------------------------------
    // Changement d'email (workflow en 2 temps)
    // ------------------------------------------------------------------------

    /**
     * Demande un changement d'email : valide le mot de passe, vérifie que
     * le nouvel email est libre, crée un token et envoie le lien de
     * vérification au NOUVEL email.
     *
     * <p>L'email du compte n'est PAS mis à jour ici — il faut que le user
     * clique sur le lien dans le mail de vérification. Tant qu'il ne l'a
     * pas fait, le compte reste accessible avec son ancien email.
     */
    @Transactional
    public void requestEmailChange(UUID userId, String newEmailRaw, String currentPassword) {
        User user = loadUser(userId);

        if (user.getAuthProvider() != AuthProvider.LOCAL || user.getPasswordHash() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Votre compte est connecté via " + user.getAuthProvider()
                            + ". Le changement d'email se fait via votre fournisseur.");
        }

        if (!passwordEncoder.matches(currentPassword, user.getPasswordHash())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Mot de passe actuel incorrect.");
        }

        final String newEmail = newEmailRaw.toLowerCase().trim();
        if (newEmail.equalsIgnoreCase(user.getEmail())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Cet email est déjà associé à votre compte.");
        }
        if (userManager.existsByEmail(newEmail)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Cet email est déjà utilisé par un autre compte.");
        }

        // Invalide les tokens en attente pour éviter qu'un ancien lien encore
        // valide ne fasse passer le compte sur un email entre-temps obsolète.
        emailChangeTokenManager.invalidateAllForUser(user.getId(), Instant.now());

        String rawToken = generateRawToken();
        EmailChangeToken token = new EmailChangeToken();
        token.setUser(user);
        token.setTokenHash(sha256(rawToken));
        token.setNewEmail(newEmail);
        token.setExpiresAt(Instant.now().plus(EMAIL_CHANGE_TOKEN_TTL));
        emailChangeTokenManager.save(token);

        mailService.sendEmailChangeConfirmation(newEmail, rawToken);
    }

    /**
     * Applique le changement d'email à partir du token reçu par mail.
     * Idempotent côté token : un token "used" lève une erreur. Retourne
     * l'email final pour que le caller (controller HTML) puisse afficher.
     *
     * @return le nouvel email maintenant actif sur le compte.
     */
    @Transactional
    public String confirmEmailChange(String rawToken) {
        EmailChangeToken token = emailChangeTokenManager.findByTokenHash(sha256(rawToken))
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST,
                        "Lien invalide."));

        if (!token.isValid()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Lien expiré ou déjà utilisé.");
        }

        // Race condition : un autre compte peut avoir réclamé le même email
        // entre la demande et la confirmation. On refuse plutôt que d'écraser
        // un autre user (ce serait UB et indétectable côté loginUI).
        if (userManager.existsByEmail(token.getNewEmail())) {
            User current = token.getUser();
            if (current.getEmail() == null
                    || !current.getEmail().equalsIgnoreCase(token.getNewEmail())) {
                throw new ResponseStatusException(HttpStatus.CONFLICT,
                        "Cet email a été pris entre-temps par un autre compte.");
            }
        }

        User user = token.getUser();
        user.setEmail(token.getNewEmail());
        try {
            userManager.save(user);
        } catch (DataIntegrityViolationException e) {
            // Course gagnée par un autre user (register / autre confirmEmailChange)
            // entre notre existsByEmail() ci-dessus et le save final. La
            // contrainte UNIQUE de la DB nous protège, on traduit en 409 propre
            // au lieu du 500 brut. Cf audit Vuln 9.
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Cet email a été pris entre-temps par un autre compte.");
        }

        token.setUsedAt(Instant.now());
        emailChangeTokenManager.save(token);

        // Cascade : un changement d'email implique souvent une perte de
        // contrôle de l'ancienne adresse (vol, abandon). On déconnecte
        // toutes les sessions pour forcer une reconnexion avec le nouvel
        // email — défense contre l'attaquant qui aurait gardé un refresh
        // token de l'ancien compte.
        sessionService.revokeAllForUser(user.getId());

        return user.getEmail();
    }

    // ------------------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------------------

    private User loadUser(UUID userId) {
        return userManager.findById(userId)
                .orElseThrow(() -> new EntityNotFoundException("User introuvable"));
    }

    private String generateRawToken() {
        byte[] bytes = new byte[EMAIL_CHANGE_TOKEN_BYTES];
        random.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    private static String sha256(String value) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] digest = md.digest(value.getBytes(StandardCharsets.UTF_8));
            return Base64.getUrlEncoder().withoutPadding().encodeToString(digest);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 introuvable", e);
        }
    }
}
