package com.sejourfr.app.dto;

import com.sejourfr.app.entity.RealtimeSession;
import com.sejourfr.app.enums.RealtimeSessionStatus;

import java.util.UUID;

/**
 * Etat d'une session temps reel renvoye apres {@code finish} (ou consultation).
 * Le transcript n'est pas expose ici (il sert a la notation cote serveur).
 *
 * <p>{@code evaluated} : vrai quand la session a produit une notation (le
 * candidat a pris la parole au moins une fois -> une submission a ete creee et
 * le pipeline lance). Faux quand seul l'examinateur a parle (accueil sans reponse
 * du candidat) : il n'y a alors AUCUNE submission a afficher, et les fronts
 * doivent l'annoncer clairement au lieu d'ouvrir un ecran de resultat vide.
 */
public record RealtimeSessionStateResponse(
        UUID sessionId,
        RealtimeSessionStatus status,
        int tacheNumero,
        int sessionsRemaining,
        boolean evaluated
) {
    public static RealtimeSessionStateResponse of(RealtimeSession s, int sessionsRemaining, boolean evaluated) {
        return new RealtimeSessionStateResponse(
                s.getId(), s.getStatus(), s.getTacheNumero(), sessionsRemaining, evaluated);
    }
}
