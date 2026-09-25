package com.sejourfr.app.service.diagnosticrun;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AuthKind;
import com.sejourfr.app.enums.DiagnosticRunClaimVia;
import com.sejourfr.app.manager.DiagnosticRunManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.util.ClientContextResolver;
import com.sejourfr.app.util.SignupAttribution;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

/**
 * <b>Le claim d'une {@code diagnostic_run}</b>, dans la transaction d'auth
 * (inscription, connexion, Google, Apple) — et, a l'inscription, le contexte
 * d'inscription pose au meme instant (brief §3.3-3.4, arbitrage « claim »).
 *
 * <p>Conditions, toutes redites dans l'{@code UPDATE} : la run existe, le
 * {@code claimToken} correspond a son hash, il n'est pas expire, la run n'a
 * jamais ete claimee et n'a pas de porteur. Une run deja portee par un compte
 * (soumise connectee, creee connectee) n'est pas « claimee » : elle etait deja
 * rattachee.
 *
 * <p>🛑 <b>Aucune recherche heuristique par {@code anonymous_id}</b> : sans
 * jeton, pas de claim, et l'inscription est {@code OUTSIDE_DIAGNOSTIC}
 * (scenario 5). 🛑 <b>Le claim ne depend pas du quota</b> : un compte qui a
 * deja son diagnostic claime quand meme la run (le tunnel le compte
 * « rattache ») ; le contenu, lui, est refuse plus loin comme avant
 * (adoption civique, handoff TCF).
 *
 * <p><b>Jamais une erreur</b> : un identifiant illisible, un jeton faux, expire
 * ou deja utilise ne claime rien et laisse l'authentification reussir. Les
 * verifications se font AVANT l'ecriture, en Java, pour qu'aucune requete
 * refusee ne touche la transaction d'auth.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class DiagnosticRunClaimService {

    private final DiagnosticRunManager runManager;
    private final UserManager userManager;

    /**
     * @param runIdRaw   {@code diagnosticRunId} de la requete d'auth (texte : un
     *                   identifiant illisible ne doit pas faire un 400 d'auth)
     * @param claimToken {@code claimToken} de la requete d'auth
     * @param via        {@link DiagnosticRunClaimVia#SAME_DEVICE} aujourd'hui ;
     *                   {@link DiagnosticRunClaimVia#APP_LINK} au lot 3b, meme jeton
     * @return la run claimee (etat lu AVANT le claim), vide sinon
     */
    public Optional<DiagnosticRunManager.State> onAuthenticated(User user, AuthKind kind, String runIdRaw,
                                                                String claimToken, DiagnosticRunClaimVia via) {
        Optional<DiagnosticRunManager.State> claimed = claim(user.getId(), kind, runIdRaw, claimToken, via);
        if (kind == AuthKind.SIGNUP) {
            SignupAttribution.stampContext(user, claimed.map(DiagnosticRunManager.State::id).orElse(null),
                    claimed.map(DiagnosticRunManager.State::type).orElse(null),
                    claimed.map(DiagnosticRunManager.State::submittedAt).orElse(null));
            userManager.save(user);
        }
        return claimed;
    }

    private Optional<DiagnosticRunManager.State> claim(UUID userId, AuthKind kind, String runIdRaw, String claimToken,
                                          DiagnosticRunClaimVia via) {
        UUID runId = ClientContextResolver.parseAnonymousId(runIdRaw);
        if (userId == null || runId == null || claimToken == null || claimToken.isBlank()) {
            return Optional.empty();
        }
        Optional<DiagnosticRunManager.State> found = runManager.findState(runId);
        if (found.isEmpty()) return Optional.empty();
        DiagnosticRunManager.State run = found.get();
        Instant now = Instant.now();
        if (!DiagnosticRunService.jetonValide(run, claimToken, now)
                || run.claimedAt() != null || run.userId() != null) {
            log.info("Claim de run refuse : run={} ({})", runId, kind);
            return Optional.empty();
        }
        boolean ok = runManager.claim(runId, run.claimTokenHash(), userId, kind, via, now);
        if (ok) {
            log.info("Run claimee : run={} type={} kind={} via={}", runId, run.type(), kind, via);
        }
        return ok ? Optional.of(run) : Optional.empty();
    }
}
