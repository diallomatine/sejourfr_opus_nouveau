package com.sejourfr.app.dto;

import com.sejourfr.app.enums.FunnelEvent;
import jakarta.validation.constraints.NotNull;

/**
 * Payload de POST /api/me/funnel-events.
 *
 * <p>Volontairement pauvre : la nature de l'etape, et rien d'autre. Le compte
 * vient du JWT, la plateforme et la provenance des en-tetes, l'horodatage du
 * serveur. Un client ne peut donc ni antidater son evenement, ni le poser pour
 * quelqu'un d'autre, ni inventer une etape — {@link FunnelEvent} est ferme et
 * double d'un CHECK en base.
 *
 * <p>{@code CHECKOUT_STARTED} est <strong>refuse</strong> sur cette route : il
 * signifie « une session de paiement a reellement ete creee chez le
 * fournisseur », un fait que seul le serveur constate. L'accepter d'un client
 * en ferait une intention, pas un fait, et la derniere marche du funnel
 * cesserait d'etre un vrai chiffre.
 */
public record FunnelEventRequest(@NotNull FunnelEvent event) {
}
