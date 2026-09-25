package com.sejourfr.app.service.diagnosticrun;

import com.sejourfr.app.dto.DiagnosticRunClaimRequest;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AuthKind;
import com.sejourfr.app.enums.DiagnosticRunClaimVia;
import com.sejourfr.app.manager.DiagnosticRunManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.service.analytics.AnalyticsConfig;
import com.sejourfr.app.util.ClientContext;
import com.sejourfr.app.util.ClientContextResolver;
import com.sejourfr.app.util.SignupAttribution;
import com.sejourfr.app.util.SoumisRetenu;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
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
    private final AnalyticsConfig config;

    /** Runs claimees au plus par authentification (controle N3). */
    public static final int MAX_CLAIMS = 3;

    /**
     * Une run a claimer, telle que la requete d'auth la declare.
     *
     * @param runIdRaw   {@code diagnosticRunId} (texte : un identifiant illisible
     *                   ne doit pas faire un 400 d'auth)
     * @param claimToken {@code claimToken}
     * @param via        canal declare ({@code claimVia}) : meme appareil, ou lien
     *                   web → app (lot 3b) ; memes verifications
     */
    public record Candidate(String runIdRaw, String claimToken, DiagnosticRunClaimVia via) {
    }

    /**
     * Les runs a claimer d'une requete d'auth : le trio unique historique
     * (anciens clients) puis la liste {@code diagnosticRunClaims} (controle N3),
     * dedoublonnees par run, identifiants illisibles ecartes, bornees a
     * {@link #MAX_CLAIMS}. Jamais une erreur.
     */
    public static List<Candidate> candidates(String runIdRaw, String claimToken, String claimVia,
                                             List<DiagnosticRunClaimRequest> claims) {
        Map<UUID, Candidate> uniques = new LinkedHashMap<>();
        ajouter(uniques, runIdRaw, claimToken, claimVia);
        if (claims != null) {
            for (DiagnosticRunClaimRequest c : claims) {
                if (c != null) ajouter(uniques, c.diagnosticRunId(), c.claimToken(), c.claimVia());
            }
        }
        return uniques.values().stream().limit(MAX_CLAIMS).toList();
    }

    private static void ajouter(Map<UUID, Candidate> uniques, String runIdRaw, String claimToken, String claimVia) {
        UUID runId = ClientContextResolver.parseAnonymousId(runIdRaw);
        if (runId == null || claimToken == null || claimToken.isBlank()) return;
        uniques.putIfAbsent(runId, new Candidate(runIdRaw, claimToken, DiagnosticRunClaimVia.fromClient(claimVia)));
    }

    /**
     * Claime chaque run valide parmi {@code candidates} ; a l'inscription, pose
     * le contexte d'inscription.
     *
     * <p><b>Plusieurs runs</b> (controle N3) : un invite qui a passe le TCF rapide
     * ET le civique rattache les deux ; une run fausse, expiree ou deja claimee
     * n'empeche pas les autres. Le contexte d'inscription se lit sur la run
     * <b>soumise la plus recente</b> parmi celles claimees (le diagnostic le plus
     * proche de l'inscription) ; aucune soumise ⇒ {@code OUTSIDE_DIAGNOSTIC}, ou
     * inconnu pour un client ancien. « Soumise » = soumis RETENU
     * ({@link SoumisRetenu}, controle C) : une run civique sous le seuil de
     * reponses, ou sans mesure, n'est pas une run soumise ici non plus.
     *
     * @param client contexte de la requete d'auth : un client ancien laisse le
     *               contexte d'inscription inconnu (controle G)
     * @return les runs claimees (etat lu AVANT le claim), dans l'ordre des candidats
     */
    public List<DiagnosticRunManager.State> onAuthenticated(User user, AuthKind kind, ClientContext client,
                                                            List<Candidate> candidates) {
        List<DiagnosticRunManager.State> claimed = new ArrayList<>();
        if (candidates != null) {
            for (Candidate c : candidates.stream().limit(MAX_CLAIMS).toList()) {
                claim(user.getId(), kind, c.runIdRaw(), c.claimToken(), c.via()).ifPresent(claimed::add);
            }
        }
        if (kind == AuthKind.SIGNUP) {
            Optional<DiagnosticRunManager.State> reference = claimed.stream()
                    .filter(run -> SoumisRetenu.retenu(run.type(), run.submittedAt(),
                            run.submittedAnsweredCount(), run.submittedQuestionCount(),
                            config.civicSubmittedMinAnsweredRatio()))
                    .max(Comparator.comparing(DiagnosticRunManager.State::submittedAt)
                            .thenComparing(run -> run.id().toString()));
            SignupAttribution.stampContext(user, reference.map(DiagnosticRunManager.State::id).orElse(null),
                    reference.map(DiagnosticRunManager.State::type).orElse(null),
                    reference.map(DiagnosticRunManager.State::submittedAt).orElse(null), client);
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
