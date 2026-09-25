package com.sejourfr.app.service.diagnosticrun;

import com.sejourfr.app.dto.DiagnosticRunClaimRequest;
import com.sejourfr.app.enums.DiagnosticRunClaimVia;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.Arrays;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/** Contrôle N3 : les runs à claimer d'une requête d'auth, trio unique et liste fusionnés. */
class DiagnosticRunClaimServiceTest {

    private static String id() {
        return UUID.randomUUID().toString();
    }

    @Test
    @DisplayName("Trio unique puis liste, dédoublonnés par run, canal par élément")
    void fusionEtDedoublonnage() {
        String a = id();
        String b = id();
        List<DiagnosticRunClaimService.Candidate> c = DiagnosticRunClaimService.candidates(a, "ja", null,
                List.of(new DiagnosticRunClaimRequest(a, "autre", "APP_LINK"),
                        new DiagnosticRunClaimRequest(b, "jb", "APP_LINK")));

        assertThat(c).extracting(DiagnosticRunClaimService.Candidate::runIdRaw).containsExactly(a, b);
        assertThat(c.get(0).claimToken()).isEqualTo("ja");
        assertThat(c.get(0).via()).isEqualTo(DiagnosticRunClaimVia.SAME_DEVICE);
        assertThat(c.get(1).via()).isEqualTo(DiagnosticRunClaimVia.APP_LINK);
    }

    @Test
    @DisplayName("Au plus 3 runs ; identifiant illisible, jeton absent ou élément nul écartés, jamais une erreur")
    void borneEtRejets() {
        List<DiagnosticRunClaimRequest> liste = Arrays.asList(
                new DiagnosticRunClaimRequest("pas-un-uuid", "j", null),
                new DiagnosticRunClaimRequest(id(), null, null),
                null,
                new DiagnosticRunClaimRequest(id(), "j1", null),
                new DiagnosticRunClaimRequest(id(), "j2", null),
                new DiagnosticRunClaimRequest(id(), "j3", null),
                new DiagnosticRunClaimRequest(id(), "j4", null));

        assertThat(DiagnosticRunClaimService.candidates(null, null, null, liste))
                .extracting(DiagnosticRunClaimService.Candidate::claimToken).containsExactly("j1", "j2", "j3");
        assertThat(DiagnosticRunClaimService.candidates(null, null, null, null)).isEmpty();
    }
}
