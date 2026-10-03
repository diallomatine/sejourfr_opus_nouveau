package com.sejourfr.app.security;

import com.sejourfr.app.service.activity.UserActivityService;
import com.sejourfr.app.util.ClientContextResolver;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

import java.util.UUID;

/**
 * Compte l'activite d'un compte connecte a chaque requete authentifiee (D1) :
 * lit l'id pose par {@link JwtAuthenticationFilter}, la plateforme par
 * {@link ClientContextResolver} (autorite unique des en-tetes), et delegue a
 * {@link UserActivityService}. Les chemins exclus sont declares dans
 * {@code config/ActivityWebConfig}.
 *
 * <p>🛑 <b>Ne refuse jamais une requete</b> : retour toujours {@code true},
 * toute erreur est avalee.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class UserActivityInterceptor implements HandlerInterceptor {

    private final UserActivityService activityService;
    private final ClientContextResolver clientContextResolver;

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
        try {
            if ("OPTIONS".equalsIgnoreCase(request.getMethod())) return true;
            Object userId = request.getAttribute(JwtAuthenticationFilter.ATTR_USER_ID);
            if (userId instanceof UUID id) {
                activityService.touch(id, clientContextResolver.resolve(request).platform());
            }
        } catch (RuntimeException e) {
            log.warn("Activite non enregistree : {}", e.toString());
        }
        return true;
    }
}
