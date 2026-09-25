package com.sejourfr.app.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

/**
 * Connexion locale.
 *
 * <p><b>{@code anonymousId} est FACULTATIF</b> : c'est l'identifiant de mesure
 * d'audience du visiteur, envoyé pour rattacher son parcours <i>avant</i>
 * compte au compte qui vient de naître (cf.
 * {@code AnalyticsIdentityService}). Absent — navigation privée, stockage
 * bloqué, client qui ne l'envoie pas encore —, on ne fait rien : une mesure
 * d'audience ne conditionne jamais l'accès à son propre compte.
 *
 * <p><b>{@code diagnosticRunId} + {@code claimToken} sont FACULTATIFS</b>
 * (chantier Suivi, lot 2a) : la run de diagnostic passee sur cet appareil avant
 * l'authentification, et le jeton rendu a sa creation. Ensemble, ils la
 * rattachent au compte dans la transaction d'auth. Absents, faux, expires ou
 * deja utilises : rien n'est rattache et l'authentification reussit quand meme.
 *
 * <p><b>{@code claimVia} est FACULTATIF</b> (lot 3b) : {@code "APP_LINK"} quand
 * la run et son jeton sont arrives par le lien web → app « Continuer sur
 * l'application » ; toute autre valeur (ou rien) vaut {@code SAME_DEVICE}. Il
 * qualifie le claim, il ne l'autorise pas : seul le jeton prouve la run.
 */
public record LoginRequest(
        @Email(message = "Email invalide")
        @NotBlank(message = "Email requis")
        String email,

        @NotBlank(message = "Mot de passe requis")
        String password,

        String anonymousId,

        String diagnosticRunId,

        String claimToken,

        String claimVia
) {}
