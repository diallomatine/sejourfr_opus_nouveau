package com.sejourfr.app.util;

import com.sejourfr.app.enums.AnalyticsDeviceType;
import com.sejourfr.app.enums.ClientPlatform;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class DeviceTypeResolverTest {

    private final DeviceTypeResolver resolver = new DeviceTypeResolver();

    @Test
    @DisplayName("Sans user-agent, on ne devine rien")
    void sansUserAgent() {
        assertThat(resolver.resolve(null, ClientPlatform.WEB)).isEqualTo(AnalyticsDeviceType.UNKNOWN);
        assertThat(resolver.resolve("  ", ClientPlatform.MOBILE)).isEqualTo(AnalyticsDeviceType.UNKNOWN);
    }

    @Test
    @DisplayName("Application native : le système, ou rien")
    void applicationNative() {
        assertThat(resolver.resolve("Dart/3.6 (dart:io) iPhone", ClientPlatform.MOBILE))
                .isEqualTo(AnalyticsDeviceType.IOS);
        assertThat(resolver.resolve("okhttp/4.12.0", ClientPlatform.MOBILE))
                .isEqualTo(AnalyticsDeviceType.ANDROID);
        // L'application ne dit pas sur quoi elle tourne : on ne choisit pas à
        // sa place, une plateforme inventée se mêlerait aux vrais chiffres.
        assertThat(resolver.resolve("Dart/3.6 (dart:io)", ClientPlatform.MOBILE))
                .isEqualTo(AnalyticsDeviceType.UNKNOWN);
    }

    @Test
    @DisplayName("Téléphone et tablette ne se confondent pas")
    void telephoneEtTablette() {
        String iphone = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) "
                + "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1";
        assertThat(resolver.resolve(iphone, ClientPlatform.WEB))
                .isEqualTo(AnalyticsDeviceType.MOBILE_WEB);

        String ipad = "Mozilla/5.0 (iPad; CPU OS 17_0 like Mac OS X) AppleWebKit/605.1.15 "
                + "(KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1";
        assertThat(resolver.resolve(ipad, ClientPlatform.WEB))
                .isEqualTo(AnalyticsDeviceType.TABLET_WEB);
    }

    /**
     * Convention Google : une tablette Android dit « Android » SANS « Mobile ».
     * Tester le téléphone en premier les rangerait toutes les deux ensemble.
     */
    @Test
    @DisplayName("Android sans « Mobile » est une tablette, avec « Mobile » un téléphone")
    void androidTabletteVsTelephone() {
        assertThat(resolver.resolve(
                "Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/120 Safari/537.36",
                ClientPlatform.WEB)).isEqualTo(AnalyticsDeviceType.TABLET_WEB);
        assertThat(resolver.resolve(
                "Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 Mobile Safari/537.36",
                ClientPlatform.WEB)).isEqualTo(AnalyticsDeviceType.MOBILE_WEB);
    }

    @Test
    @DisplayName("Un navigateur de bureau est reconnu")
    void bureau() {
        assertThat(resolver.resolve(
                "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
                        + "(KHTML, like Gecko) Chrome/120.0 Safari/537.36",
                ClientPlatform.WEB)).isEqualTo(AnalyticsDeviceType.DESKTOP_WEB);
    }

    /**
     * Un outil en ligne de commande n'est pas un visiteur. Le ranger en
     * « ordinateur » gonflerait la part du bureau avec du trafic automatisé.
     */
    @Test
    @DisplayName("Un outil qui n'est pas un navigateur n'est pas rangé en « ordinateur »")
    void outilNonNavigateur() {
        assertThat(resolver.resolve("curl/8.4.0", ClientPlatform.WEB))
                .isEqualTo(AnalyticsDeviceType.UNKNOWN);
        assertThat(resolver.resolve("python-requests/2.31", ClientPlatform.UNKNOWN))
                .isEqualTo(AnalyticsDeviceType.UNKNOWN);
    }
}
