package com.sejourfr.app.service;

import com.sejourfr.app.config.AppConfigProperties;
import com.sejourfr.app.dto.AppConfigResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

/** Configuration publique de l'application mobile (controle G, option a). */
@Service
@RequiredArgsConstructor
public class AppConfigService {

    private final AppConfigProperties properties;

    public AppConfigResponse current() {
        AppConfigProperties.MinSupportedVersion min = properties.getMinSupportedVersion();
        return new AppConfigResponse(new AppConfigResponse.MinSupportedVersion(min.getIos(), min.getAndroid()));
    }
}
