package com.sejourfr.app.dto;

import com.sejourfr.app.enums.TargetProcedure;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.util.List;

/**
 * Création de compte ({@code POST /api/auth/register}).
 *
 * <p><b>{@code targetProcedure} est FACULTATIF</b>, et c'est volontaire : le web
 * fait choisir la démarche sur l'écran de compte qui clôt le diagnostic (le
 * candidat vient de produire, on lui demande son objectif au même endroit),
 * alors que le mobile a son écran de parcours dédié ({@code /target-path}) et
 * n'envoie donc rien ici. Une inscription sans démarche reste parfaitement
 * valide — on ne devine jamais une démarche à la place du candidat.
 *
 * <p><b>Le palier de français n'est PAS dans ce payload</b> et ne le sera
 * jamais : il est posé par le serveur depuis la démarche
 * ({@link TargetProcedure#getRequiredTcfLevel()}), par l'unique point d'écriture
 * {@code MeService.updateTargetProcedure}. Une valeur de démarche inconnue est
 * refusée en 400 par la désérialisation — jamais persistée, jamais ignorée en
 * silence : c'est ce silence (le champ n'existait pas côté serveur) qui a créé
 * des comptes sans objectif alors que le candidat en avait choisi un.
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
 *
 * <p><b>{@code diagnosticRunClaims} est FACULTATIF</b> (controle N3) : une
 * liste de runs a rattacher ({@link DiagnosticRunClaimRequest}), pour l'invite
 * qui a passe plusieurs diagnostics (TCF rapide ET civique, plus une run recue
 * par le lien web → app). Le serveur y ajoute le trio unique ci-dessus (anciens
 * clients), dedoublonne par run et en garde {@value
 * com.sejourfr.app.service.diagnosticrun.DiagnosticRunClaimService#MAX_CLAIMS}
 * au plus : chaque run valide est claimee, les autres sont ignorees.
 */
public record RegisterRequest(
        @NotBlank @Email String email,
        @NotBlank @Size(min = 8, message = "Le mot de passe doit faire au moins 8 caractères") String password,
        @NotBlank String firstName,
        @NotBlank String lastName,
        TargetProcedure targetProcedure,
        String anonymousId,
        String diagnosticRunId,
        String claimToken,
        String claimVia,

        List<DiagnosticRunClaimRequest> diagnosticRunClaims
) {}
