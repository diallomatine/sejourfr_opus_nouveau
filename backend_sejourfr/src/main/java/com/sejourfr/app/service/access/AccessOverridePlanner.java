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
 */
public final class AccessOverridePlanner {

    private AccessOverridePlanner() {}

    /** Une décision à poser : {@code fin} exclusive, {@code null} = sans fin (REVOKE seulement). */
    public record Decision(ModuleAccess produit, AccessOverrideType type, Instant debut, Instant fin) {}

    /** Ce qu'il faut écrire : les décisions à remplacer, puis celles à insérer, dans cet ordre. */
    public record Plan(List<AccessOverride> aRemplacer, List<AccessOverride> aInserer) {

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
        return new Plan(List.copyOf(aRemplacer), List.copyOf(aInserer));
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
        return o;
    }
}
