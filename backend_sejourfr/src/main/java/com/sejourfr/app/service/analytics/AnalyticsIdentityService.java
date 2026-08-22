package com.sejourfr.app.service.analytics;

import com.sejourfr.app.manager.AnalyticsIdentityManager;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.UUID;

/**
 * Rattache un parcours anonyme au compte qui vient de s'inscrire ou de se
 * connecter (brief §9).
 *
 * <p><b>Pourquoi un lien plutot qu'un backfill.</b> On pourrait mettre a jour
 * les evenements passes du visiteur pour y poser son {@code user_id}. On ne le
 * fait pas : c'est un {@code UPDATE} de volume inconnu sur le chemin critique
 * d'une connexion, et il faudrait le refaire a chaque appareil supplementaire.
 * Une ligne de liaison suffit — la lecture joint, elle ne reecrit pas.
 *
 * <p>🛑 <b>Best-effort, toujours.</b> Cette ecriture a lieu <i>pendant</i> une
 * inscription ou une connexion. Une mesure d'audience ne doit jamais empecher
 * quelqu'un d'entrer chez lui : toute exception est avalee, et l'absence
 * d'{@code anonymousId} (client sans stockage, navigation privee, application
 * qui ne l'envoie pas encore) n'est pas une erreur mais le cas ordinaire.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class AnalyticsIdentityService {

    private final AnalyticsIdentityManager identityManager;

    /**
     * Pose le lien anonyme -> compte, s'il y a de quoi.
     *
     * <p>Idempotent : chaque connexion repose le meme lien et n'ecrit rien de
     * plus. Un {@code anonymousId} dont aucun evenement n'est jamais arrive
     * n'ecrit rien non plus — le visiteur n'existe pas, il n'y a rien a relier.
     */
    public void link(String anonymousId, UUID userId) {
        if (anonymousId == null || anonymousId.isBlank() || userId == null) return;
        UUID visitor;
        try {
            visitor = UUID.fromString(anonymousId.trim());
        } catch (IllegalArgumentException e) {
            // Identifiant illisible : on n'en fait pas une erreur de connexion.
            log.debug("anonymousId illisible a la fusion d'identite, ignore.");
            return;
        }
        try {
            identityManager.link(visitor, userId);
        } catch (RuntimeException e) {
            log.warn("Fusion anonyme -> compte impossible (user={}) : {}", userId, e.toString());
        }
    }
}
