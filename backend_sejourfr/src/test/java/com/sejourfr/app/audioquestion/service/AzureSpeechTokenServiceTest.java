package com.sejourfr.app.audioquestion.service;

import com.github.benmanes.caffeine.cache.Cache;
import com.sejourfr.app.audioquestion.config.AzureSpeechProperties;
import com.sejourfr.app.audioquestion.exception.AudioServicesUnavailableException;
import org.junit.jupiter.api.Test;

import java.lang.reflect.Field;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Token Azure Speech : 503-gate quand la cle/region manque, et lecture depuis le
 * cache Caffeine sans appel reseau (cache-hit). Le fetch HTTP reel n'est pas
 * teste ici (RestClient interne, pas de point d'injection) — voir note de batch.
 */
class AzureSpeechTokenServiceTest {

    private static AzureSpeechProperties configuredProps() {
        AzureSpeechProperties props = new AzureSpeechProperties();
        props.setKey("fake-key");
        props.setRegion("francecentral");
        return props;
    }

    @SuppressWarnings("unchecked")
    private static Cache<String, String> cacheOf(AzureSpeechTokenService service) throws Exception {
        Field f = AzureSpeechTokenService.class.getDeclaredField("cache");
        f.setAccessible(true);
        return (Cache<String, String>) f.get(service);
    }

    @Test
    void getToken_non_configure_leve_503() {
        AzureSpeechProperties props = new AzureSpeechProperties();
        props.setKey("");
        AzureSpeechTokenService service = new AzureSpeechTokenService(props);

        assertThatThrownBy(service::getToken)
            .isInstanceOf(AudioServicesUnavailableException.class);
    }

    @Test
    void getToken_renvoie_la_valeur_en_cache_sans_appel_reseau() throws Exception {
        AzureSpeechTokenService service = new AzureSpeechTokenService(configuredProps());
        cacheOf(service).put("token", "cached-token-abc");

        // Si le cache n'etait pas consulte, fetchToken irait sur le reseau et echouerait.
        assertThat(service.getToken()).isEqualTo("cached-token-abc");
    }

    @Test
    void invalidate_vide_le_cache() throws Exception {
        AzureSpeechTokenService service = new AzureSpeechTokenService(configuredProps());
        Cache<String, String> cache = cacheOf(service);
        cache.put("token", "cached-token-abc");

        service.invalidate();

        assertThat(cache.getIfPresent("token")).isNull();
    }
}
