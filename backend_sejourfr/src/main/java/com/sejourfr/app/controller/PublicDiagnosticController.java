package com.sejourfr.app.controller;

import com.sejourfr.app.dto.PublicDiagnosticResponse;
import com.sejourfr.app.ratelimit.RateLimitGuard;
import com.sejourfr.app.service.diagnostic.PublicDiagnosticService;
import com.sejourfr.app.util.ClientIpResolver;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Sujets du diagnostic servis à un visiteur non authentifié : il rédige son
 * expression écrite et s'enregistre à l'oral <em>avant</em> qu'on lui demande un
 * compte, puis s'inscrit au moment d'« Analyser mes réponses ».
 *
 * <p><strong>Rien n'est persisté ici.</strong> Tant qu'il n'y a pas de compte,
 * les productions restent côté client : pas de session diagnostic anonyme, pas
 * d'attempt, pas d'audio invité sur R2. Seule la suite du parcours est
 * authentifiée — {@code POST /api/diagnostics} puis les deux
 * {@code POST /api/production-submissions}.
 *
 * <p><strong>Après l'inscription, cas d'un diagnostic déjà terminé.</strong>
 * {@code POST /api/diagnostics} est idempotent : un compte qui avait déjà
 * terminé ce diagnostic (même code, même version) reçoit sa session existante,
 * donc {@code status=COMPLETED}, {@code nextStep=RESULT} et son {@code result}
 * — jamais une erreur, jamais une session neuve. Les deux soumissions qui
 * suivraient sont alors refusées en <strong>422</strong> (« Ce diagnostic
 * n'accepte plus de nouvelle production. »). C'est au front d'anticiper cet
 * état à la lecture du {@code status} et de proposer le résultat existant
 * plutôt que d'envoyer les productions.
 */
@RestController
@RequestMapping("/api/public/diagnostics")
@RequiredArgsConstructor
public class PublicDiagnosticController {

    private final PublicDiagnosticService publicDiagnosticService;
    private final RateLimitGuard rateLimitGuard;
    private final ClientIpResolver clientIpResolver;

    /**
     * Version active et ses deux sujets.
     *
     * <p>Rate-limit volontairement <strong>large</strong> (120 requêtes par
     * tranche de 10 minutes et par IP, cf.
     * {@code RateLimitProperties.publicDiagnostic}) : c'est une lecture de
     * contenu seedé, sans écriture, sans appel LLM et sans donnée personnelle,
     * qu'un même visiteur rappelle à chaque étape, rechargement ou retour
     * arrière. La borne ne sert donc qu'à couper une boucle automatisée, pas à
     * gêner un candidat réel — même philosophie que la démo invitée, avec un
     * plafond doublé puisque le coût d'un appel est ici quasi nul.
     */
    @GetMapping("/current")
    public PublicDiagnosticResponse current(HttpServletRequest httpRequest) {
        rateLimitGuard.checkPublicDiagnostic(clientIpResolver.resolve(httpRequest));
        return publicDiagnosticService.current();
    }
}
