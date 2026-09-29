package com.sejourfr.app.enums;

/**
 * Type d'appareil du visiteur, <b>deduit serveur</b> du user-agent et de la
 * plateforme declaree (cf. {@code util/DeviceTypeResolver}).
 *
 * <p>Le client ne l'envoie jamais : il serait falsifiable, et surtout le
 * dupliquer des deux cotes garantirait qu'un jour les deux ne diraient plus la
 * meme chose.
 *
 * <p>{@link #UNKNOWN} n'est pas une erreur — c'est un user-agent absent ou
 * illisible. On ne devine pas : une heuristique fausse est pire qu'une absence
 * declaree, parce qu'elle se mele aux vrais chiffres sans se signaler (meme
 * parti pris que {@link ClientPlatform#UNKNOWN}).
 */
public enum AnalyticsDeviceType {

    /** Navigateur sur telephone. */
    MOBILE_WEB,

    /** Navigateur sur ordinateur. */
    DESKTOP_WEB,

    /** Navigateur sur tablette. */
    TABLET_WEB,

    /** Application native iOS. */
    IOS,

    /** Application native Android. */
    ANDROID,

    /** Indeterminable. Jamais une valeur inventee. */
    UNKNOWN
}
