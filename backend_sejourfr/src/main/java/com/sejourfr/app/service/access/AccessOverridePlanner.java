package com.sejourfr.app.service.access;

import com.sejourfr.app.entity.AccessOverride;
import com.sejourfr.app.enums.AccessOverrideType;
import com.sejourfr.app.enums.ModuleAccess;

import java.time.Instant;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

/**
 * Traduit de nouvelles décisions admin en écritures sur {@code access_overrides}
 * (GO §4 et §18). Pur : le même plan sert à l'APERÇU ({@code dryRun}, simulé en
 * mémoire puis passé au résolveur) et à l'ÉCRITURE — l'aperçu ne peut pas
 * diverger de ce qui sera écrit.
 *
 * <p>Pour une nouvelle décision {@code D} sur le produit {@code P}, fenêtre
 * {@code [S, E)} ({@code E} absent = sans fin), chaque décision courante
 * {@code O} de {@code P} qui recoupe la fenêtre est <b>remplacée</b>
 * (supersedée, jamais supprimée) puis, si une part d'elle reste hors de la
 * fenêtre :
 * <ul>
 *   <li>sa part AVANT {@code S} est réinsérée tronquée à {@code S} — programmer
 *       une décision future ne modifie jamais l'accès d'ici là ;</li>
 *   <li>si {@code O} est un REVOKE qui dure au-delà de {@code E}, sa part APRÈS
 *       {@code E} est réinsérée : un accès accordé par-dessus une révocation ne
 *       restitue pas l'achat révoqué à sa fin (même esprit que GO §18, « le
 *       reliquat n'est pas restitué »). La part après {@code E} d'un GRANT n'est
 *       jamais conservée : raccourcir un GRANT, c'est bien le raccourcir.</li>
 * </ul>
 * Les copies gardent le type, le motif, l'auteur et l'instant de décision
 * d'origine ({@code decidedAt}) ; elles portent l'{@code operationId} de la
 * nouvelle action et {@code replacesOverrideId} = l'ancienne. Par construction
 * les fenêtres courantes ne se chevauchent jamais (la contrainte d'exclusion
 * V083 le vérifie en filet).
 *
 * <p><b>Sessions EO temps réel d'un GRANT INTEGRAL</b> (V084, B-1) — le solde
 * suit l'instant présent par la lignée :
 * <ol>
 *   <li>nouvelle décision GRANT INTEGRAL : {@code granted = remaining = N} (N = 0
 *       pour toute autre décision) ;</li>
 *   <li>copie (tête ou queue) : {@code granted = source.granted}, {@code remaining = 0} ;</li>
 *   <li>report : le solde d'un GRANT INTEGRAL remplacé qui couvre MAINTENANT passe
 *       sur le GRANT INTEGRAL inséré qui couvre maintenant (prolonger 4 → 4,
 *       raccourcir, donner programmé : la tête) ; si celui-ci est une nouvelle
 *       décision, son {@code granted} reçoit aussi celui de l'ancien (cumul
 *       « 4 restantes + 10 offertes → 14 ») ; le solde d'un GRANT FUTUR remplacé
 *       passe sur sa propre tête s'il en a une ;</li>
 *   <li>sinon le solde est <b>perdu</b> (terminer, corriger vers Civique) : le plan
 *       le dit ({@link SessionsEo#perdues()}), l'aperçu l'annonce.</li>
 * </ol>
 * 🛑 Le planner ne touche JAMAIS une décision existante (entités gérées : en
 * aperçu, une écriture serait flushée) : la remise à 0 du solde d'une ligne
 * remplacée se fait à l'écriture, avec {@code supersededAt}.
 */
public final class AccessOverridePlanner {

    private AccessOverridePlanner() {}

    /**
     * Une décision à poser : {@code fin} exclusive, {@code null} = sans fin (REVOKE
     * seulement). {@code sessionsEo} : sessions EO temps réel offertes, lues pour
     * un GRANT INTEGRAL seulement (0 ailleurs, validé en amont).
     */
    public record Decision(ModuleAccess produit, AccessOverrideType type, Instant debut, Instant fin,
                           int sessionsEo) {
        public Decision(ModuleAccess produit, AccessOverrideType type, Instant debut, Instant fin) {
            this(produit, type, debut, fin, 0);
        }

        public boolean grantIntegral() {
            return produit == ModuleAccess.INTEGRAL && type == AccessOverrideType.GRANT;
        }
    }

    /**
     * Le devenir des sessions EO temps réel des GRANT INTEGRAL touchés.
     *
     * @param offertes   sessions offertes par les nouvelles décisions
     * @param reportees  solde des lignes remplacées repris par la lignée
     * @param cumulees   le report s'est fait sur la NOUVELLE décision (cumul)
     * @param perdues    solde des lignes remplacées qui n'est repris nulle part
     */
    public record SessionsEo(int offertes, int reportees, boolean cumulees, int perdues) {}

    /** Ce qu'il faut écrire : les décisions à remplacer, puis celles à insérer, dans cet ordre. */
    public record Plan(List<AccessOverride> aRemplacer, List<AccessOverride> aInserer, SessionsEo sessionsEo) {

        /** Les décisions courantes telles qu'elles seront après l'écriture (simulation de l'aperçu). */
        public List<AccessOverride> appliqueA(List<AccessOverride> courants) {
            Set<UUID> remplaces = new HashSet<>();
            aRemplacer.forEach(o -> remplaces.add(o.getId()));
            List<AccessOverride> out = new ArrayList<>();
            for (AccessOverride o : courants) {
                if (!remplaces.contains(o.getId())) out.add(o);
            }
            out.addAll(aInserer);
            return out;
        }
    }

    /** Contexte commun aux écritures d'une action admin. */
    public record Contexte(UUID userId, UUID operationId, UUID adminId, String motif, Instant maintenant) {}

    public static Plan planifier(List<AccessOverride> courants, List<Decision> decisions, Contexte ctx) {
        List<AccessOverride> etat = new ArrayList<>(courants);
        List<AccessOverride> aRemplacer = new ArrayList<>();
        List<AccessOverride> aInserer = new ArrayList<>();
        for (Decision d : decisions) {
            for (AccessOverride o : List.copyOf(etat)) {
                if (o.getProduct() != d.produit() || !recoupe(o, d)) continue;
                etat.remove(o);
                // Écrite par cette même action (jamais en base) : on l'oublie au
                // lieu de la remplacer, et ses copies pointent vers SON original.
                boolean ecriteIci = aInserer.remove(o);
                if (!ecriteIci) aRemplacer.add(o);
                UUID original = ecriteIci ? o.getReplacesOverrideId() : o.getId();
                if (o.getStartsAt().isBefore(d.debut())) {
                    AccessOverride tete = copie(o, o.getStartsAt(), d.debut(), original, ctx);
                    etat.add(tete);
                    aInserer.add(tete);
                }
                if (o.getType() == AccessOverrideType.REVOKE && d.fin() != null
                        && (o.getEndsAt() == null || o.getEndsAt().isAfter(d.fin()))) {
                    AccessOverride queue = copie(o, d.fin(), o.getEndsAt(), original, ctx);
                    etat.add(queue);
                    aInserer.add(queue);
                }
            }
            AccessOverride nouvelle = nouvelle(d, ctx);
            etat.add(nouvelle);
            aInserer.add(nouvelle);
        }
        int offertes = decisions.stream().filter(Decision::grantIntegral).mapToInt(d -> Math.max(0, d.sessionsEo())).sum();
        return new Plan(List.copyOf(aRemplacer), List.copyOf(aInserer),
                reporterLesSessions(aRemplacer, aInserer, offertes, ctx.maintenant()));
    }

    /** Règle 3 / 4 de la classe : le solde des GRANT INTEGRAL remplacés suit la lignée, ou est perdu. */
    private static SessionsEo reporterLesSessions(List<AccessOverride> aRemplacer, List<AccessOverride> aInserer,
                                                  int offertes, Instant maintenant) {
        AccessOverride courantApres = aInserer.stream()
                .filter(o -> estGrantIntegral(o) && o.couvre(maintenant))
                .findFirst().orElse(null);
        int reportees = 0;
        int perdues = 0;
        boolean cumulees = false;
        for (AccessOverride o : aRemplacer) {
            int solde = Math.max(0, o.getRealtimeEoSessionsRemaining());
            if (!estGrantIntegral(o) || solde == 0) continue;
            AccessOverride cible = o.couvre(maintenant)
                    ? courantApres
                    : aInserer.stream()
                            .filter(c -> estGrantIntegral(c) && o.getId().equals(c.getReplacesOverrideId()))
                            .findFirst().orElse(null);
            if (cible == null) {
                perdues += solde;
                continue;
            }
            cible.setRealtimeEoSessionsRemaining(cible.getRealtimeEoSessionsRemaining() + solde);
            if (cible.getReplacesOverrideId() == null) {
                // Nouvelle décision : l'allocation reprend aussi celle de l'ancienne
                // (remaining <= granted tient : solde <= o.granted).
                cible.setRealtimeEoSessionsGranted(cible.getRealtimeEoSessionsGranted()
                        + Math.max(0, o.getRealtimeEoSessionsGranted()));
                cumulees = true;
            }
            reportees += solde;
        }
        return new SessionsEo(offertes, reportees, cumulees, perdues);
    }

    private static boolean estGrantIntegral(AccessOverride o) {
        return o.getProduct() == ModuleAccess.INTEGRAL && o.getType() == AccessOverrideType.GRANT;
    }

    /** Les fenêtres {@code [a, b)} et {@code [c, d)} se recoupent-elles ? ({@code null} = +∞) */
    private static boolean recoupe(AccessOverride o, Decision d) {
        boolean oCommenceAvantFinD = d.fin() == null || o.getStartsAt().isBefore(d.fin());
        boolean dCommenceAvantFinO = o.getEndsAt() == null || d.debut().isBefore(o.getEndsAt());
        return oCommenceAvantFinD && dCommenceAvantFinO;
    }

    private static AccessOverride nouvelle(Decision d, Contexte ctx) {
        AccessOverride o = new AccessOverride();
        o.setId(UUID.randomUUID());
        o.setUserId(ctx.userId());
        o.setProduct(d.produit());
        o.setType(d.type());
        o.setStartsAt(d.debut());
        o.setEndsAt(d.fin());
        o.setDecidedAt(ctx.maintenant());
        o.setReason(ctx.motif());
        o.setCreatedBy(ctx.adminId());
        o.setCreatedAt(ctx.maintenant());
        o.setOperationId(ctx.operationId());
        int sessions = d.grantIntegral() ? Math.max(0, d.sessionsEo()) : 0;
        o.setRealtimeEoSessionsGranted(sessions);
        o.setRealtimeEoSessionsRemaining(sessions);
        return o;
    }

    private static AccessOverride copie(AccessOverride source, Instant debut, Instant fin,
                                        UUID original, Contexte ctx) {
        AccessOverride o = new AccessOverride();
        o.setId(UUID.randomUUID());
        o.setUserId(source.getUserId());
        o.setProduct(source.getProduct());
        o.setType(source.getType());
        o.setStartsAt(debut);
        o.setEndsAt(fin);
        o.setDecidedAt(source.getDecidedAt());
        o.setReason(source.getReason());
        o.setCreatedBy(source.getCreatedBy());
        o.setCreatedAt(ctx.maintenant());
        o.setOperationId(ctx.operationId());
        o.setReplacesOverrideId(original);
        o.setRealtimeEoSessionsGranted(source.getRealtimeEoSessionsGranted());
        o.setRealtimeEoSessionsRemaining(0);
        return o;
    }
}
