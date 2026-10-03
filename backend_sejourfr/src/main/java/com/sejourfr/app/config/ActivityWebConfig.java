package com.sejourfr.app.config;

import com.sejourfr.app.security.UserActivityInterceptor;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * Branche {@link UserActivityInterceptor} sur les routes de l'API. Ne comptent
 * PAS comme activite : l'authentification (login, refresh, logout — un refresh
 * n'est jamais une connexion ni une presence, D4), la file d'analytics (videe
 * au passage en arriere-plan : ce n'est pas une presence), les fichiers, la
 * supervision et la page d'erreur. Une autre route publique appelee avec un
 * jeton valide (diagnostic d'un compte connecte) compte.
 */
@Configuration
@RequiredArgsConstructor
public class ActivityWebConfig implements WebMvcConfigurer {

    private final UserActivityInterceptor userActivityInterceptor;

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(userActivityInterceptor)
                .addPathPatterns("/api/**")
                .excludePathPatterns("/api/auth/**", "/api/public/analytics/**", "/files/**", "/actuator/**", "/error");
    }
}
