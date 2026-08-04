package com.sejourfr.app.ratelimit;

import com.sejourfr.app.config.RateLimitProperties;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;

@ExtendWith(MockitoExtension.class)
class RateLimitGuardTest {

    @Mock
    private InMemoryRateLimiter limiter;

    private RateLimitProperties props;
    private RateLimitGuard guard;

    @BeforeEach
    void setUp() {
        props = new RateLimitProperties();
        guard = new RateLimitGuard(props, limiter);
    }

    @Test
    void disabled_isNoOp() {
        props.setEnabled(false);
        guard.checkLogin("1.2.3.4", "a@b.fr");
        guard.onLoginSuccess("1.2.3.4", "a@b.fr");
        guard.checkRegister("1.2.3.4");
        guard.checkDemo("1.2.3.4");
        guard.checkProductionSubmission(UUID.randomUUID());
        verifyNoInteractions(limiter);
    }

    /**
     * Une authentification réussie efface les deux compteurs : le garde-fou
     * vise l'enchaînement d'ÉCHECS, pas l'utilisateur qui se reconnecte.
     */
    @Test
    void onLoginSuccess_resetsIpAndAccountCounters() {
        guard.onLoginSuccess("1.2.3.4", "  KARIM@Sejourfr.FR ");

        verify(limiter).reset("login:ip", "1.2.3.4");
        verify(limiter).reset("login:account", "karim@sejourfr.fr");
    }

    @Test
    void checkLogin_appliesIpAndNormalizedAccountKeys() {
        guard.checkLogin("1.2.3.4", "  KARIM@Sejourfr.FR ");

        verify(limiter).check("login:ip", "1.2.3.4", props.getLogin());
        verify(limiter).check("login:account", "karim@sejourfr.fr", props.getLoginPerAccount());
    }

    @Test
    void checkRegister_usesRegisterBucket() {
        guard.checkRegister("9.9.9.9");
        verify(limiter).check("register", "9.9.9.9", props.getRegister());
    }

    @Test
    void checkForgotPassword_usesBucket() {
        guard.checkForgotPassword("9.9.9.9");
        verify(limiter).check("forgot-password", "9.9.9.9", props.getForgotPassword());
    }

    @Test
    void checkDemo_usesDemoBucket() {
        guard.checkDemo("9.9.9.9");
        verify(limiter).check("demo", "9.9.9.9", props.getDemo());
    }

    @Test
    void checkProductionSubmission_appliesBurstAndDaily() {
        UUID userId = UUID.randomUUID();
        guard.checkProductionSubmission(userId);

        verify(limiter).check("production:burst", userId.toString(), props.getProductionBurst());
        verify(limiter).check("production:daily", userId.toString(), props.getProductionDaily());
    }

    @Test
    void checkProductionSubmission_nullUser_isNoOp() {
        guard.checkProductionSubmission(null);
        verify(limiter, never()).check(anyString(), any(), any());
    }
}
