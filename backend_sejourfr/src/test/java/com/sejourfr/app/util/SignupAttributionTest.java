package com.sejourfr.app.util;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.ClientPlatform;
import com.sejourfr.app.enums.DiagnosticRunType;
import com.sejourfr.app.enums.SignupContext;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/** Contexte d'inscription (brief §3.4) : AFTER_DIAGNOSTIC seulement sur une run claimée ET soumise. */
class SignupAttributionTest {

    /** Client recent : plateforme declaree et version. */
    private static final ClientContext RECENT = new ClientContext(ClientPlatform.WEB, "direct", null, "0.1.0");

    @Test
    @DisplayName("Run soumise claimée ⇒ AFTER_DIAGNOSTIC, avec son type et son id")
    void apresDiagnostic() {
        User user = new User();
        UUID run = UUID.randomUUID();
        SignupAttribution.stampContext(user, run, DiagnosticRunType.CIVIQUE, Instant.now(), RECENT);
        assertThat(user.getSignupContext()).isEqualTo(SignupContext.AFTER_DIAGNOSTIC);
        assertThat(user.getSignupDiagnosticType()).isEqualTo(DiagnosticRunType.CIVIQUE);
        assertThat(user.getSignupDiagnosticRunId()).isEqualTo(run);
    }

    @Test
    @DisplayName("Aucune run, ou run jamais soumise ⇒ OUTSIDE_DIAGNOSTIC, sans type ni id")
    void horsDiagnostic() {
        User sansRun = new User();
        SignupAttribution.stampContext(sansRun, null, null, null, RECENT);
        assertThat(sansRun.getSignupContext()).isEqualTo(SignupContext.OUTSIDE_DIAGNOSTIC);
        assertThat(sansRun.getSignupDiagnosticType()).isNull();

        User nonSoumise = new User();
        SignupAttribution.stampContext(nonSoumise, UUID.randomUUID(), DiagnosticRunType.QUICK_TCF, null, RECENT);
        assertThat(nonSoumise.getSignupContext()).isEqualTo(SignupContext.OUTSIDE_DIAGNOSTIC);
        assertThat(nonSoumise.getSignupDiagnosticRunId()).isNull();
    }

    @Test
    @DisplayName("Contrôle G — client ancien sans run soumise ⇒ contexte inconnu (null), jamais OUTSIDE_DIAGNOSTIC")
    void clientAncienInconnu() {
        for (ClientContext ancien : new ClientContext[]{
                new ClientContext(ClientPlatform.MOBILE, "direct", null, null),
                new ClientContext(ClientPlatform.UNKNOWN, "direct", null, "1.0.0"),
                new ClientContext(ClientPlatform.WEB, "direct", null, null),
                ClientContext.unknown(), null}) {
            User user = new User();
            SignupAttribution.stampContext(user, null, null, null, ancien);
            assertThat(user.getSignupContext()).isNull();
            assertThat(user.getSignupDiagnosticType()).isNull();
            assertThat(user.getSignupDiagnosticRunId()).isNull();
        }
    }

    @Test
    @DisplayName("Contrôle G — une run soumise claimée reste un fait, même depuis un client ancien")
    void clientAncienAvecRunSoumise() {
        User user = new User();
        UUID run = UUID.randomUUID();
        SignupAttribution.stampContext(user, run, DiagnosticRunType.QUICK_TCF, Instant.now(),
                new ClientContext(ClientPlatform.MOBILE, "direct", null, null));
        assertThat(user.getSignupContext()).isEqualTo(SignupContext.AFTER_DIAGNOSTIC);
    }

    @Test
    @DisplayName("Contrôle G — client récent (web versionné, iOS, Android) sans run ⇒ OUTSIDE_DIAGNOSTIC")
    void clientRecent() {
        for (ClientContext recent : new ClientContext[]{RECENT,
                new ClientContext(ClientPlatform.IOS, "direct", null, "2.4.1"),
                new ClientContext(ClientPlatform.ANDROID, "direct", null, "2.4.1")}) {
            User user = new User();
            SignupAttribution.stampContext(user, null, null, null, recent);
            assertThat(user.getSignupContext()).isEqualTo(SignupContext.OUTSIDE_DIAGNOSTIC);
        }
    }
}
