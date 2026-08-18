package com.sejourfr.app.service;

import com.sejourfr.app.enums.FunnelEvent;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.manager.UserFunnelEventManager;
import com.sejourfr.app.util.ClientContext;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.UUID;

/**
 * Enregistre les deux etapes de funnel qui n'existent que dans le navigateur —
 * l'ecran Premium affiche et le clic sur l'abonnement — plus le depart de
 * paiement, pose par le serveur.
 *
 * <p><strong>Premiere occurrence seulement.</strong> L'unicite
 * {@code (user_id, event)} en base borne la table a 3 lignes par compte, pour
 * toujours : c'est cette borne, et non un rate-limit, qui protege l'endpoint
 * d'ecriture. Un client qui rejoue son evenement en boucle n'ecrit rien apres
 * le premier appel — inutile d'ajouter un compteur par IP la ou le schema
 * rend l'abus sans effet.
 *
 * <p>L'ecriture passe par un {@code ON CONFLICT DO NOTHING} : le rejeu ne leve
 * pas, y compris quand deux requetes concurrentes arrivent ensemble. C'est ce
 * qui permet de l'appeler depuis la creation d'une session de paiement sans
 * risquer d'empoisonner sa transaction.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class FunnelEventService {

    private final UserFunnelEventManager manager;

    /**
     * Etape declaree par le candidat lui-meme (route {@code /api/me/funnel-events}).
     *
     * @throws BusinessException si le client tente de poser
     *         {@link FunnelEvent#CHECKOUT_STARTED}, qui est un fait constate par
     *         le serveur et non une intention declarable.
     */
    public void recordFromClient(UUID userId, FunnelEvent event, ClientContext client) {
        if (event == FunnelEvent.CHECKOUT_STARTED) {
            throw new BusinessException(
                    "CHECKOUT_STARTED est posé par le serveur au moment où la session de "
                    + "paiement est réellement créée, jamais par un client.");
        }
        record(userId, event, client);
    }

    /** Pose l'etape si elle ne l'etait pas deja. Idempotent, ne leve pas sur rejeu. */
    public void record(UUID userId, FunnelEvent event, ClientContext client) {
        ClientContext ctx = client == null ? ClientContext.unknown() : client;
        manager.recordFirstOccurrence(userId, event, ctx.platform(), ctx.source());
    }

    /**
     * Variante <strong>best-effort</strong>, pour les appelants dont l'echec
     * d'enregistrement ne doit rien casser — au premier rang desquels la
     * creation d'une session de paiement : perdre une ligne de statistique est
     * sans commune mesure avec empecher quelqu'un de payer.
     */
    public void recordQuietly(UUID userId, FunnelEvent event, ClientContext client) {
        try {
            record(userId, event, client);
        } catch (RuntimeException e) {
            log.warn("Etape de funnel {} non enregistrée pour {} : {}",
                    event, userId, e.getMessage());
        }
    }
}
