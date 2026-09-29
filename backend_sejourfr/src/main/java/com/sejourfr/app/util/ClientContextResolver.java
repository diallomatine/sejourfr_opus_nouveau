package com.sejourfr.app.util;

import com.sejourfr.app.enums.ClientPlatform;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.stereotype.Component;

import java.util.UUID;
import java.util.regex.Pattern;

/**
 * Lit le contexte declare par l'appelant dans ses en-tetes, sur le patron de
 * {@link ClientIpResolver} : le resolveur prend la requete en parametre, les
 * controllers l'appellent, les services recoivent un objet. <b>Autorite
 * unique</b> de ces quatre en-tetes (arbitrage Q4 du chantier Suivi).
 *
 * <ul>
 *   <li>{@code X-Sejourfr-Client} : {@code web} | {@code ios} | {@code android}.
 *       {@code mobile} (application d'avant la distinction) reste accepte et vaut
 *       {@link ClientPlatform#MOBILE}. Tout le reste vaut
 *       {@link ClientPlatform#UNKNOWN}.</li>
 *   <li>{@code X-Sejourfr-Source} : reseau de provenance, normalise par
 *       {@link TrafficSource}.</li>
 *   <li>{@code X-Sejourfr-Anonymous-Id} : identifiant de mesure (UUID). Illisible
 *       ⇒ {@code null}, jamais une erreur.</li>
 *   <li>{@code X-Sejourfr-App-Version} : version de l'application, charset et
 *       longueur bornes. Hors format ⇒ {@code null}.</li>
 * </ul>
 *
 * <p><strong>Ces en-tetes sont declaratifs et non verifiables</strong>, comme
 * les parametres UTM d'une campagne. Ils n'ouvrent aucun droit, ne changent
 * aucune regle metier et ne servent qu'a ventiler une mesure : les falsifier ne
 * donne rien d'autre qu'une ligne de statistique fausse chez soi.
 */
@Component
public class ClientContextResolver {

    public static final String HEADER_CLIENT = "X-Sejourfr-Client";
    public static final String HEADER_SOURCE = "X-Sejourfr-Source";
    public static final String HEADER_ANONYMOUS_ID = "X-Sejourfr-Anonymous-Id";
    public static final String HEADER_APP_VERSION = "X-Sejourfr-App-Version";

    /** « 2.4.1 », « 2.4.1+57 », « 1.0.0-beta.2 » : de quoi nommer une version, rien de plus. */
    private static final Pattern APP_VERSION = Pattern.compile("^[0-9A-Za-z][0-9A-Za-z.+_-]{0,31}$");

    /** Contexte de l'appel. Jamais {@code null}, meme sans requete. */
    public ClientContext resolve(HttpServletRequest request) {
        if (request == null) return ClientContext.unknown();
        return new ClientContext(
                ClientPlatform.parse(request.getHeader(HEADER_CLIENT)),
                TrafficSource.normalize(request.getHeader(HEADER_SOURCE)),
                parseAnonymousId(request.getHeader(HEADER_ANONYMOUS_ID)),
                parseAppVersion(request.getHeader(HEADER_APP_VERSION)));
    }

    /**
     * Contexte de l'appel, complete par ce que le <b>corps</b> declare quand un
     * en-tete manque.
     *
     * <p>Sert a l'ingestion en lot : un {@code sendBeacon} ne peut poser aucun
     * en-tete, donc un lot envoye a la fermeture d'une page arrive sans
     * {@code X-Sejourfr-Client}. <b>L'en-tete prime toujours</b> ; le corps ne
     * comble qu'une absence, avec les memes regles de lecture.
     */
    public ClientContext resolve(HttpServletRequest request, String declaredClient,
                                 String declaredAppVersion) {
        ClientContext headers = resolve(request);
        ClientPlatform platform = headers.platform() != ClientPlatform.UNKNOWN
                ? headers.platform()
                : ClientPlatform.parse(declaredClient);
        String appVersion = headers.appVersion() != null
                ? headers.appVersion()
                : parseAppVersion(declaredAppVersion);
        return new ClientContext(platform, headers.source(), headers.anonymousId(), appVersion);
    }

    /** UUID lisible, ou {@code null}. */
    public static UUID parseAnonymousId(String raw) {
        if (raw == null || raw.isBlank()) return null;
        try {
            return UUID.fromString(raw.trim());
        } catch (IllegalArgumentException e) {
            return null;
        }
    }

    /** Version bornee, ou {@code null}. */
    public static String parseAppVersion(String raw) {
        if (raw == null || raw.isBlank()) return null;
        String value = raw.trim();
        return APP_VERSION.matcher(value).matches() ? value : null;
    }
}
