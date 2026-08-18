package com.sejourfr.app.util;

import com.sejourfr.app.enums.ClientPlatform;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.stereotype.Component;

/**
 * Lit le contexte declare par l'appelant dans deux en-tetes, sur le patron de
 * {@link ClientIpResolver} : le resolveur prend la requete en parametre, les
 * controllers l'appellent, les services recoivent un objet.
 *
 * <ul>
 *   <li>{@code X-Sejourfr-Client} : {@code web} | {@code mobile}. Tout le reste
 *       (absent, inconnu) vaut {@link ClientPlatform#UNKNOWN}.</li>
 *   <li>{@code X-Sejourfr-Source} : reseau de provenance, normalise par
 *       {@link TrafficSource} — <b>la meme allowlist</b> que celle opposee aux
 *       evenements anonymes de {@code page_views}.</li>
 * </ul>
 *
 * <p><strong>Ces deux en-tetes sont declaratifs et non verifiables</strong>,
 * comme le sont les parametres UTM d'une campagne. Ils n'ouvrent aucun droit,
 * ne changent aucune regle metier et ne servent qu'a ventiler une mesure : les
 * falsifier ne donne rien d'autre qu'une ligne de statistique fausse chez soi.
 * L'allowlist de provenances borne de toute facon les valeurs possibles.
 */
@Component
public class ClientContextResolver {

    public static final String HEADER_CLIENT = "X-Sejourfr-Client";
    public static final String HEADER_SOURCE = "X-Sejourfr-Source";

    /** Contexte de l'appel. Jamais {@code null}, meme sans requete. */
    public ClientContext resolve(HttpServletRequest request) {
        if (request == null) return ClientContext.unknown();
        return new ClientContext(
                ClientPlatform.parse(request.getHeader(HEADER_CLIENT)),
                TrafficSource.normalize(request.getHeader(HEADER_SOURCE)));
    }
}
