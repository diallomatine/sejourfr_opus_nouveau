package com.sejourfr.app.dto;

/**
 * Attribution envoyee par un front <b>a la premiere requete d'un visiteur, et
 * a elle seule</b> (brief §13).
 *
 * <p>Le serveur ne fait de toute facon jamais confiance a la repetition : le
 * first touch est ecrit en {@code ON CONFLICT DO NOTHING}, donc renvoyer ce
 * bloc plus tard ne le reecrirait pas. Le front s'abstient quand meme, pour ne
 * pas transporter des UTM a chaque geste.
 *
 * @param source       {@code utm_source} ou {@code ?src=}. Normalise serveur par
 *                     {@code util/TrafficSource} — l'allowlist est fermee, ce
 *                     champ ne peut pas creer de dimension.
 * @param medium       {@code utm_medium}
 * @param campaign     {@code utm_campaign}
 * @param content      {@code utm_content} — c'est lui qui distingue deux videos
 *                     d'une meme campagne, la question la plus utile du lot
 * @param term         {@code utm_term}
 * @param landingPath  page d'arrivee
 * @param referrerHost <b>hote seul</b> (« tiktok.com »), jamais l'URL complete :
 *                     une URL de referrer peut porter un identifiant ou un terme
 *                     de recherche. Le serveur re-extrait l'hote par securite si
 *                     une URL entiere arrive quand meme.
 */
public record AnalyticsFirstTouchRequest(
        String source,
        String medium,
        String campaign,
        String content,
        String term,
        String landingPath,
        String referrerHost
) {}
