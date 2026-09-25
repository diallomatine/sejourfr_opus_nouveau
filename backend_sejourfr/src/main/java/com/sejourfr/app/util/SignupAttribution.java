package com.sejourfr.app.util;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.DiagnosticRunType;
import com.sejourfr.app.enums.SignupContext;

import java.time.Instant;
import java.util.UUID;

/**
 * <b>Autorite unique</b> de la provenance posee sur un compte a sa creation :
 * inscription locale et premier sign-in social (Google, Apple). Elle vivait en
 * deux copies (AuthService, SocialAuthService) ; une troisieme colonne
 * ({@code signup_anonymous_id}, V074) aurait fait trois endroits a tenir
 * alignes.
 *
 * <p>Posee <b>une fois, a la creation, jamais reecrite</b> : la provenance d'une
 * acquisition est celle du jour ou elle a eu lieu. Le contexte d'inscription
 * ({@code signup_context}, {@code signup_diagnostic_*}) est pose par
 * {@link #stampContext}, dans la meme transaction d'inscription, au moment du
 * claim de la run ({@code DiagnosticRunClaimService}).
 */
public final class SignupAttribution {

    private SignupAttribution() {
    }

    /**
     * @param declaredAnonymousId {@code anonymousId} du corps de la requete
     *                            d'auth ; prime sur l'en-tete
     */
    public static void stamp(User user, ClientContext client, String declaredAnonymousId) {
        ClientContext ctx = client == null ? ClientContext.unknown() : client;
        user.setSignupSource(ctx.source());
        user.setSignupPlatform(ctx.platform());
        user.setSignupAnonymousId(ctx.anonymousIdPreferring(declaredAnonymousId));
    }

    /**
     * Contexte d'inscription (brief §3.4) : {@code AFTER_DIAGNOSTIC} si
     * l'inscription vient de claimer une run <b>soumise</b>, avec son type et son
     * id ; {@code OUTSIDE_DIAGNOSTIC} sinon — y compris une run claimee mais
     * jamais soumise (le sujet vu ne fait pas un diagnostic).
     *
     * @param claimedRunId       run claimee par cette inscription, {@code null} si aucune
     * @param claimedType        son type
     * @param claimedSubmittedAt sa date de soumission, {@code null} si jamais soumise
     */
    public static void stampContext(User user, UUID claimedRunId, DiagnosticRunType claimedType,
                                    Instant claimedSubmittedAt) {
        if (claimedRunId != null && claimedType != null && claimedSubmittedAt != null) {
            user.setSignupContext(SignupContext.AFTER_DIAGNOSTIC);
            user.setSignupDiagnosticType(claimedType);
            user.setSignupDiagnosticRunId(claimedRunId);
        } else {
            user.setSignupContext(SignupContext.OUTSIDE_DIAGNOSTIC);
            user.setSignupDiagnosticType(null);
            user.setSignupDiagnosticRunId(null);
        }
    }
}
