package com.sejourfr.app.util;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.DiagnosticRunType;
import com.sejourfr.app.enums.SignupContext;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/** Contexte d'inscription (brief §3.4) : AFTER_DIAGNOSTIC seulement sur une run claimée ET soumise. */
class SignupAttributionTest {

    @Test
    @DisplayName("Run soumise claimée ⇒ AFTER_DIAGNOSTIC, avec son type et son id")
    void apresDiagnostic() {
        User user = new User();
        UUID run = UUID.randomUUID();
        SignupAttribution.stampContext(user, run, DiagnosticRunType.CIVIQUE, Instant.now());
        assertThat(user.getSignupContext()).isEqualTo(SignupContext.AFTER_DIAGNOSTIC);
        assertThat(user.getSignupDiagnosticType()).isEqualTo(DiagnosticRunType.CIVIQUE);
        assertThat(user.getSignupDiagnosticRunId()).isEqualTo(run);
    }

    @Test
    @DisplayName("Aucune run, ou run jamais soumise ⇒ OUTSIDE_DIAGNOSTIC, sans type ni id")
    void horsDiagnostic() {
        User sansRun = new User();
        SignupAttribution.stampContext(sansRun, null, null, null);
        assertThat(sansRun.getSignupContext()).isEqualTo(SignupContext.OUTSIDE_DIAGNOSTIC);
        assertThat(sansRun.getSignupDiagnosticType()).isNull();

        User nonSoumise = new User();
        SignupAttribution.stampContext(nonSoumise, UUID.randomUUID(), DiagnosticRunType.QUICK_TCF, null);
        assertThat(nonSoumise.getSignupContext()).isEqualTo(SignupContext.OUTSIDE_DIAGNOSTIC);
        assertThat(nonSoumise.getSignupDiagnosticRunId()).isNull();
    }
}
