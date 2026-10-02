package com.sejourfr.app.service.realtime;

import com.sejourfr.app.entity.AccessOverride;
import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.RealtimeSession;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.AccessOverrideType;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.manager.AccessOverrideManager;
import com.sejourfr.app.manager.UserSubscriptionManager;
import com.sejourfr.app.service.SubscriptionService;
import com.sejourfr.app.service.access.AccesEffectifResolver;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * 🛑 <b>L'UNIQUE autorité du quota de sessions EO temps réel</b> : affichage
 * ({@code /api/realtime/eo/quota}, {@code subscription-status}), démarrage,
 * débit et fiche admin passent tous par {@link #evaluer}. Personne d'autre ne
 * lit ni ne débite un solde.
 *
 * <p>Deux porteurs possibles, consommés dans cet ordre (arbitrage n°4 du
 * 2026-10-02) :
 * <ol>
 *   <li>le <b>GRANT INTEGRAL admin</b> applicable maintenant (V084 :
 *       {@code access_overrides.realtime_eo_sessions_remaining}, sessions
 *       offertes par l'admin) ;</li>
 *   <li>l'<b>achat Intégral</b> qui porte l'accès effectif
 *       ({@code user_subscriptions.realtime_eo_sessions_remaining}, posé à
 *       l'achat = {@code plans.realtime_eo_sessions}).</li>
 * </ol>
 * Les deux sélections RÉUTILISENT {@link AccesEffectifResolver} : un achat
 * révoqué ou remboursé en totalité n'est plus l'achat qui compte, donc son solde
 * ne compte plus ; un GRANT terminé, expiré ou remplacé par un accès non
 * Intégral ne couvre plus maintenant, donc son solde est perdu (jamais
 * transféré). Les sessions achetées ne passent jamais sur un GRANT, ni
 * l'inverse.
 *
 * <p>Ce que reçoivent les fronts (forme inchangée) : {@code remaining} = somme
 * des deux soldes, {@code cap} = somme des deux allocations. Sans décision
 * admin, valeurs identiques à avant.
 *
 * <p>Un plan sans accès TCF (Civique, Free) porte 0 : le candidat fait
 * l'épreuve en async (jamais bloqué).
 */
@Slf4j
@Service
@Transactional(readOnly = true)
@RequiredArgsConstructor
public class RealtimeQuotaService {

    private final SubscriptionService subscriptionService;
    private final UserSubscriptionManager userSubscriptionManager;
    private final AccessOverrideManager accessOverrideManager;

    /**
     * Le quota d'un compte à un instant.
     *
     * @param grant     le GRANT INTEGRAL admin applicable (vide sinon)
     * @param achat     l'achat qui porte l'accès effectif (vide sinon)
     * @param cap       somme des allocations (sessions offertes + incluses dans le pass)
     * @param remaining somme des soldes ({@code >= 0})
     */
    public record Quota(Optional<AccessOverride> grant, Optional<UserSubscription> achat, int cap, int remaining) {

        public static final Quota VIDE = new Quota(Optional.empty(), Optional.empty(), 0, 0);

        public boolean canStartRealtime() {
            return remaining > 0;
        }

        public int grantRemaining() {
            return grant.map(g -> Math.max(0, g.getRealtimeEoSessionsRemaining())).orElse(0);
        }

        public int grantGranted() {
            return grant.map(g -> Math.max(0, g.getRealtimeEoSessionsGranted())).orElse(0);
        }

        public int achatRemaining() {
            return achat.map(s -> Math.max(0, s.getRealtimeEoSessionsRemaining())).orElse(0);
        }

        /** Le GRANT à réserver au démarrage : le premier porteur, s'il lui reste une session. */
        public Optional<AccessOverride> grantPorteur() {
            return grantRemaining() > 0 ? grant : Optional.empty();
        }

        /** L'achat à réserver au démarrage : seulement si le GRANT n'a plus rien. */
        public Optional<UserSubscription> achatPorteur() {
            return grantPorteur().isEmpty() && achatRemaining() > 0 ? achat : Optional.empty();
        }
    }

    /** LA règle. Pure : la même pour l'affichage, le démarrage, le débit et la fiche admin. */
    public static Quota evaluer(SubscriptionService.DonneesAcces d, Instant t) {
        Optional<AccessOverride> grant = AccesEffectifResolver
                .decisionApplicable(d.decisions(), ModuleAccess.INTEGRAL, t)
                .filter(o -> o.getType() == AccessOverrideType.GRANT);
        Optional<UserSubscription> achat = AccesEffectifResolver.achatRepresentatif(d.achats(), d.decisions(), t);
        int capGrant = grant.map(g -> Math.max(0, g.getRealtimeEoSessionsGranted())).orElse(0);
        int soldeGrant = grant.map(g -> Math.max(0, g.getRealtimeEoSessionsRemaining())).orElse(0);
        int capAchat = achat.map(UserSubscription::getPlan).map(Plan::getRealtimeEoSessions)
                .map(n -> Math.max(0, n)).orElse(0);
        int soldeAchat = achat.map(s -> Math.max(0, s.getRealtimeEoSessionsRemaining())).orElse(0);
        return new Quota(grant, achat, capGrant + capAchat, soldeGrant + soldeAchat);
    }

    public Quota evaluate(UUID userId) {
        return evaluer(subscriptionService.charger(userId), Instant.now());
    }

    /** Sessions restantes pour affichage (compteur). 0 si rien n'est consommable. */
    public int remaining(UUID userId) {
        return evaluate(userId).remaining();
    }

    /**
     * Le SEUL point de débit, appelé à la transition {@code PENDING -> ACTIVE}
     * d'une session (sous verrou de ligne de la session, donc une fois par
     * session).
     * <ul>
     *   <li>Session portée par un achat : débit inchangé sur sa ligne
     *       ({@code UserSubscriptionManager.decrementRealtimeSessions}).</li>
     *   <li>Session portée par un GRANT : sous le verrou consultatif du compte
     *       (le même que les actions admin, qui réécrivent la ligne entière à la
     *       supersession), relit le GRANT applicable — une prolongation entre le
     *       démarrage et la connexion a pu déplacer le solde sur une nouvelle
     *       ligne — et le débite. La session garde la ligne réellement débitée,
     *       ou {@code null} si aucune ne l'a été (course perdue : la session
     *       continue sans débit, comme un achat à 0).</li>
     * </ul>
     */
    @Transactional
    public void debiter(RealtimeSession session) {
        UserSubscription achat = session.getSubscription();
        if (achat != null) {
            userSubscriptionManager.decrementRealtimeSessions(achat.getId());
            return;
        }
        if (session.getAccessOverrideId() == null) {
            return;
        }
        UUID userId = session.getUser().getId();
        accessOverrideManager.verrouiller(userId);
        Optional<AccessOverride> grant = evaluer(subscriptionService.charger(userId), Instant.now()).grant();
        UUID debitee = grant
                .filter(g -> accessOverrideManager.decrementRealtimeSessions(g.getId()))
                .map(AccessOverride::getId)
                .orElse(null);
        if (debitee == null) {
            log.info("Session temps réel {} : aucun solde de GRANT débitable à la connexion, pas de débit.",
                    session.getId());
        }
        session.setAccessOverrideId(debitee);
    }

    // ---------------------------------------------------------- fiche admin

    /**
     * Ce que la fiche admin affiche des sessions EO temps réel, calculé par la
     * même règle. {@code null} = sans objet (pas de GRANT applicable, pas
     * d'achat qui compte, pas de GRANT programmé).
     *
     * @param grantGranted         sessions offertes par le GRANT applicable
     * @param grantRemaining       solde du GRANT applicable
     * @param purchaseRemaining    solde de l'achat qui compte
     * @param purchaseEndsAt       fin de cet achat (son solde n'est utilisable que jusque-là)
     * @param scheduledGrantGranted sessions offertes par le prochain GRANT INTEGRAL programmé
     * @param sansSessionOfferte   le GRANT INTEGRAL affiché sur la carte (applicable, sinon
     *                             programmé) n'offre aucune session
     */
    public record VueAdmin(int remaining, Integer grantGranted, Integer grantRemaining,
                           Integer purchaseRemaining, Instant purchaseEndsAt,
                           Integer scheduledGrantGranted, boolean sansSessionOfferte) {}

    public static VueAdmin vueAdmin(SubscriptionService.DonneesAcces d, Instant t) {
        Quota q = evaluer(d, t);
        Optional<AccessOverride> programme = q.grant().isPresent() ? Optional.empty() : grantProgramme(d.decisions(), t);
        Optional<AccessOverride> affiche = q.grant().or(() -> programme);
        return new VueAdmin(
                q.remaining(),
                q.grant().map(g -> q.grantGranted()).orElse(null),
                q.grant().map(g -> q.grantRemaining()).orElse(null),
                q.achat().map(a -> q.achatRemaining()).orElse(null),
                q.achat().map(UserSubscription::getEndsAt).orElse(null),
                programme.map(AccessOverride::getRealtimeEoSessionsGranted).orElse(null),
                affiche.map(g -> g.getRealtimeEoSessionsGranted() == 0).orElse(false));
    }

    private static Optional<AccessOverride> grantProgramme(List<AccessOverride> decisions, Instant t) {
        return decisions.stream()
                .filter(AccessOverride::estCourante)
                .filter(o -> o.getProduct() == ModuleAccess.INTEGRAL && o.getType() == AccessOverrideType.GRANT
                        && o.getStartsAt().isAfter(t))
                .min(Comparator.comparing(AccessOverride::getStartsAt));
    }
}
