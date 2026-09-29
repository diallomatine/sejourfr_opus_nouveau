package com.sejourfr.app.service.analytics;

import com.sejourfr.app.enums.AuthKind;
import com.sejourfr.app.manager.AnalyticsIdentityManager;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.UUID;

/**
 * Ce que la mesure fait d'une authentification reussie : rattacher le parcours
 * anonyme de l'appareil au compte (brief §3.2).
 *
 * <p>Le claim d'une {@code diagnostic_run} (lot 2a) ne vit PAS ici : il est
 * transactionnel et porte le contexte d'inscription, la ou ce lien-ci est
 * best-effort. Les services d'auth appellent les deux cote a cote
 * ({@code DiagnosticRunClaimService}). Aucune recherche heuristique par
 * {@code anonymous_id} : le lien pose ici ne sert qu'a la mesure d'audience.
 *
 * <p><b>Pourquoi un lien plutot qu'un backfill.</b> On pourrait poser le
 * {@code user_id} sur les evenements passes du visiteur. On ne le fait pas :
 * c'est un {@code UPDATE} de volume inconnu sur le chemin critique d'une
 * connexion. Une ligne de liaison suffit — la lecture joint.
 *
 * <p>🛑 <b>Best-effort, toujours.</b> Une mesure d'audience ne doit jamais
 * empecher quelqu'un d'entrer chez lui : toute exception est avalee, et
 * l'absence d'identifiant (navigation privee, client ancien) est le cas
 * ordinaire.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class AnalyticsIdentityService {

    private final AnalyticsIdentityManager identityManager;

    /**
     * Apres une inscription ou une connexion reussie (locale, Google, Apple).
     * Idempotent : chaque connexion repose le meme lien et n'ecrit rien de plus.
     * Un identifiant dont aucun evenement n'est jamais arrive n'ecrit rien non
     * plus — le visiteur n'existe pas, il n'y a rien a relier.
     *
     * @param anonymousId identifiant resolu (corps, puis en-tete), {@code null}
     *                    s'il n'y en a pas
     */
    public void onAuthenticated(UUID userId, AuthKind kind, UUID anonymousId) {
        if (anonymousId == null || userId == null) return;
        try {
            identityManager.link(anonymousId, userId);
        } catch (RuntimeException e) {
            log.warn("Fusion anonyme -> compte impossible ({}, user={}) : {}", kind, userId, e.toString());
        }
    }
}
