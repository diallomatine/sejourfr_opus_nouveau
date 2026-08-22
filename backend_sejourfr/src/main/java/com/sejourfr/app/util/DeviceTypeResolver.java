package com.sejourfr.app.util;

import com.sejourfr.app.enums.AnalyticsDeviceType;
import com.sejourfr.app.enums.ClientPlatform;
import org.springframework.stereotype.Component;

import java.util.Locale;

/**
 * Type d'appareil d'un appelant, deduit de son user-agent et de la plateforme
 * qu'il declare.
 *
 * <p><b>Le user-agent n'est jamais conserve</b>, seule sa conclusion l'est :
 * c'est une chaine identifiante (elle sert d'empreinte de navigateur), sa
 * conclusion ne l'est pas.
 *
 * <p><b>Pourquoi la plateforme entre dans le calcul.</b> Un user-agent seul ne
 * distingue pas « Safari sur iPhone » de « l'application native iOS » de facon
 * fiable : les deux disent {@code iPhone}. L'en-tete {@code X-Sejourfr-Client},
 * lui, sait s'il vient d'une application. Web et natif sont donc deux branches
 * separees, et non deux heuristiques qui se marchent dessus.
 *
 * <p><b>On ne devine pas.</b> {@link AnalyticsDeviceType#UNKNOWN} est rendu des
 * que rien de sur ne ressort — user-agent absent, application native dont l'UA
 * ne nomme aucun systeme, chaine qui n'a rien d'un navigateur. Une heuristique
 * fausse est pire qu'une absence declaree : elle se mele aux vrais chiffres
 * sans se signaler (meme parti pris que {@link ClientPlatform#UNKNOWN}).
 */
@Component
public class DeviceTypeResolver {

    /**
     * Type d'appareil.
     *
     * @param userAgent en-tete {@code User-Agent}, eventuellement {@code null}
     * @param platform  plateforme declaree ({@code X-Sejourfr-Client})
     */
    public AnalyticsDeviceType resolve(String userAgent, ClientPlatform platform) {
        if (userAgent == null || userAgent.isBlank()) return AnalyticsDeviceType.UNKNOWN;
        String ua = userAgent.toLowerCase(Locale.ROOT);

        // --- Application native : le systeme, ou rien -------------------------
        if (platform == ClientPlatform.MOBILE) {
            if (contains(ua, "iphone", "ipad", "ios", "cfnetwork", "darwin")) {
                return AnalyticsDeviceType.IOS;
            }
            if (contains(ua, "android", "okhttp")) {
                return AnalyticsDeviceType.ANDROID;
            }
            // Dart/Flutter sans mention de systeme : l'application ne dit pas
            // sur quoi elle tourne. On ne choisit pas a sa place.
            return AnalyticsDeviceType.UNKNOWN;
        }

        // --- Navigateur ------------------------------------------------------
        // Tablette d'abord : un iPad dit « ipad » ET « mobile » chez certains
        // navigateurs, et un Android tablette dit « android » SANS « mobile »
        // (c'est la convention Google). Tester le telephone en premier les
        // rangerait tous les deux dans MOBILE_WEB.
        boolean android = ua.contains("android");
        if (contains(ua, "ipad", "tablet", "kindle", "playbook", "silk")
                || (android && !ua.contains("mobile"))) {
            return AnalyticsDeviceType.TABLET_WEB;
        }
        if (contains(ua, "mobi", "iphone", "ipod", "windows phone", "blackberry") || android) {
            return AnalyticsDeviceType.MOBILE_WEB;
        }
        // Un vrai navigateur de bureau se declare toujours « mozilla/5.0 ».
        // Sans ce marqueur, on a affaire a un outil (curl, bot, script) : le
        // ranger en « ordinateur » gonflerait la part du bureau avec du trafic
        // qui n'est pas un visiteur.
        if (contains(ua, "mozilla", "webkit", "gecko", "trident")) {
            return AnalyticsDeviceType.DESKTOP_WEB;
        }
        return AnalyticsDeviceType.UNKNOWN;
    }

    private static boolean contains(String haystack, String... needles) {
        for (String needle : needles) {
            if (haystack.contains(needle)) return true;
        }
        return false;
    }
}
