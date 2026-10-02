package com.sejourfr.app.service.access;

import com.sejourfr.app.entity.AccessOverride;
import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.AccessOrigin;
import com.sejourfr.app.enums.AccessOverrideType;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.PaymentStatus;
import com.sejourfr.app.enums.ProductAccessStatus;
import com.sejourfr.app.enums.SubscriptionStatus;
import com.sejourfr.app.service.SubscriptionService;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;
import java.util.TreeSet;

/**
 * 🛑 <b>LA règle de l'accès effectif</b> (spec §2.3, GO §3-§4 et §17) : à partir
 * des ACHATS ({@code user_subscriptions}, intacts) et des DÉCISIONS admin
 * courantes ({@code access_overrides}), dit ce qu'un compte peut réellement
 * utiliser à l'instant {@code t}. Pur, sans Spring, sans base : appelé par
 * {@link SubscriptionService} (l'autorité que lisent tous les verrous, {@code /me},
 * {@code subscription-status}, {@code verify-receipt} et le quota EO) et par la
 * console admin. Personne ne recopie cette règle.
 *
 * <p>Pour un produit {@code P} ∈ {CIVIQUE, INTEGRAL} à l'instant {@code t} :
 * <ul>
 *   <li>la décision courante dont la fenêtre couvre {@code t} — au plus une, par
 *       la contrainte d'exclusion V083 ; une décision future n'a <b>aucun effet</b>
 *       avant son début ;</li>
 *   <li>GRANT ⇒ accès ;</li>
 *   <li>REVOKE ⇒ accès seulement si un achat de {@code P} valide à {@code t} a été
 *       fait APRÈS la décision ({@code decidedAt}) — un REVOKE ne bloque jamais
 *       un rachat ;</li>
 *   <li>aucune ⇒ accès s'il existe un achat de {@code P} valide à {@code t}
 *       ({@link SubscriptionService#covers}, règle réutilisée, jamais réécrite).</li>
 * </ul>
 * INTEGRAL ouvre Civique + TCF ; CIVIQUE ouvre Civique. Sans aucune décision, le
 * résultat est <b>exactement</b> celui du calcul historique sur les seuls achats.
 */
public final class AccesEffectifResolver {

    /** Les produits réellement vendus (GO §1) : pas de produit « TCF » seul. */
    public static final List<ModuleAccess> PRODUITS = List.of(ModuleAccess.CIVIQUE, ModuleAccess.INTEGRAL);

    private static final String FREE_PLAN_CODE = "FREE";

    private AccesEffectifResolver() {}

    /**
     * Fin d'un accès. {@code sansFin} : l'accès ne s'arrête jamais (achat sans
     * date de fin) — l'appelant choisit alors sa convention historique.
     */
    public record Fin(Instant instant, boolean sansFin) {
        static final Fin AUCUNE = new Fin(null, false);
        static final Fin SANS_FIN = new Fin(null, true);
    }

    /** Ce que l'admin voit pour un produit (spec §2.4) ; dérivé, jamais persisté. */
    public record EtatProduit(
            ModuleAccess produit,
            ProductAccessStatus statut,
            Instant debut,
            Instant fin,
            AccessOrigin origine,
            List<Alerte> alertes) {}

    public enum CodeAlerte {
        ACHAT_REMBOURSE,
        ACHAT_PARTIELLEMENT_REMBOURSE,
        REVOCATION_PROGRAMMEE,
        ACCES_PROGRAMME,
        ROUVERT_PAR_ACHAT,
        INCLUS_DANS_INTEGRAL,
        ABONNEMENT_RECURRENT
    }

    /** Une alerte et ses dates ; le libellé est composé par le mapper admin. */
    public record Alerte(CodeAlerte code, Instant date1, Instant date2) {}

    // ------------------------------------------------------------------ accès

    /** Le produit vendu par une ligne d'achat, ou {@code null} (plan gratuit, sans module). */
    public static ModuleAccess produitDe(UserSubscription s) {
        Plan plan = s.getPlan();
        if (plan == null || FREE_PLAN_CODE.equalsIgnoreCase(plan.getCode())) return null;
        ModuleAccess m = plan.getModuleAccess();
        return m == ModuleAccess.NONE ? null : m;
    }

    /** La décision courante de {@code p} dont la fenêtre couvre {@code t} (au plus une). */
    public static Optional<AccessOverride> decisionApplicable(
            List<AccessOverride> decisions, ModuleAccess p, Instant t) {
        return decisions.stream()
                .filter(AccessOverride::estCourante)
                .filter(d -> d.getProduct() == p && d.couvre(t))
                .findFirst();
    }

    /**
     * Les achats de {@code p} qui comptent à {@code t} : valides à {@code t}, et
     * postérieurs à la décision si un REVOKE s'applique.
     */
    public static List<UserSubscription> achatsOuvrants(
            List<UserSubscription> achats, List<AccessOverride> decisions, ModuleAccess p, Instant t) {
        Optional<AccessOverride> d = decisionApplicable(decisions, p, t);
        List<UserSubscription> out = new ArrayList<>();
        for (UserSubscription s : achats) {
            if (produitDe(s) != p || !SubscriptionService.covers(s, t)) continue;
            if (d.isPresent() && d.get().getType() == AccessOverrideType.REVOKE
                    && !dateAchat(s).isAfter(d.get().getDecidedAt())) continue;
            out.add(s);
        }
        return out;
    }

    public static boolean acces(List<UserSubscription> achats, List<AccessOverride> decisions,
                                ModuleAccess p, Instant t) {
        Optional<AccessOverride> d = decisionApplicable(decisions, p, t);
        if (d.isPresent() && d.get().getType() == AccessOverrideType.GRANT) return true;
        return !achatsOuvrants(achats, decisions, p, t).isEmpty();
    }

    /** Accès à un produit de rang au moins {@code min} (NONE &lt; CIVIQUE &lt; INTEGRAL). */
    public static boolean accesAuMoins(List<UserSubscription> achats, List<AccessOverride> decisions,
                                       ModuleAccess min, Instant t) {
        for (ModuleAccess p : produitsAuMoins(min)) {
            if (acces(achats, decisions, p, t)) return true;
        }
        return false;
    }

    /** Le module effectif : INTEGRAL l'emporte sur CIVIQUE, NONE sans accès. */
    public static ModuleAccess module(List<UserSubscription> achats, List<AccessOverride> decisions, Instant t) {
        if (acces(achats, decisions, ModuleAccess.INTEGRAL, t)) return ModuleAccess.INTEGRAL;
        if (acces(achats, decisions, ModuleAccess.CIVIQUE, t)) return ModuleAccess.CIVIQUE;
        return ModuleAccess.NONE;
    }

    /**
     * Fin de l'accès continu à un produit de rang ≥ {@code min} en cours à
     * {@code t} : le premier instant où il cesse. L'accès ne change de valeur
     * qu'aux bornes des décisions et aux fins d'achat ; on les parcourt dans
     * l'ordre. Sans décision, c'est la fin d'achat la plus tardive (calcul
     * historique).
     */
    public static Fin fin(List<UserSubscription> achats, List<AccessOverride> decisions,
                          ModuleAccess min, Instant t) {
        if (!accesAuMoins(achats, decisions, min, t)) return Fin.AUCUNE;
        List<ModuleAccess> produits = produitsAuMoins(min);
        TreeSet<Instant> bornes = new TreeSet<>();
        for (AccessOverride d : decisions) {
            if (!d.estCourante() || !produits.contains(d.getProduct())) continue;
            ajouterSiApres(bornes, d.getStartsAt(), t);
            ajouterSiApres(bornes, d.getEndsAt(), t);
        }
        for (UserSubscription s : achats) {
            if (produits.contains(produitDe(s))) ajouterSiApres(bornes, s.getEndsAt(), t);
        }
        for (Instant b : bornes) {
            if (!accesAuMoins(achats, decisions, min, b)) return new Fin(b, false);
        }
        return Fin.SANS_FIN;
    }

    /**
     * Convention historique pour un accès sans fin : la fin d'achat FINIE la plus
     * tardive parmi les achats qui comptent ({@code null} s'il n'y en a pas).
     */
    public static Instant derniereFinFinie(List<UserSubscription> achats, List<AccessOverride> decisions,
                                           ModuleAccess min, Instant t) {
        Instant latest = null;
        for (ModuleAccess p : produitsAuMoins(min)) {
            for (UserSubscription s : achatsOuvrants(achats, decisions, p, t)) {
                Instant e = s.getEndsAt();
                if (e != null && (latest == null || e.isAfter(latest))) latest = e;
            }
        }
        return latest;
    }

    /**
     * L'achat « qui compte » du module effectif : parmi les achats qui comptent
     * de ce produit, le meilleur au sens historique (fin la plus tardive, un
     * achat sans fin l'emporte). Vide si l'accès effectif ne vient d'aucun achat
     * de ce produit (GRANT seul).
     */
    public static Optional<UserSubscription> achatRepresentatif(
            List<UserSubscription> achats, List<AccessOverride> decisions, Instant t) {
        ModuleAccess m = module(achats, decisions, t);
        if (m == ModuleAccess.NONE) return Optional.empty();
        return meilleur(achatsOuvrants(achats, decisions, m, t));
    }

    /**
     * Vrai si {@code candidate} doit l'emporter sur {@code incumbent} : INTEGRAL
     * &gt; CIVIQUE ; à produit égal, la fin la plus tardive ; une ligne sans fin
     * bat toute date finie. (Départage historique de {@code currentSubscription}.)
     */
    public static boolean meilleurQue(UserSubscription candidate, UserSubscription incumbent) {
        ModuleAccess c = candidate.getPlan().getModuleAccess();
        ModuleAccess i = incumbent.getPlan().getModuleAccess();
        if (c == ModuleAccess.INTEGRAL && i != ModuleAccess.INTEGRAL) return true;
        if (c != ModuleAccess.INTEGRAL && i == ModuleAccess.INTEGRAL) return false;
        Instant ce = candidate.getEndsAt();
        Instant ie = incumbent.getEndsAt();
        if (ce == null) return ie != null;
        if (ie == null) return false;
        return ce.isAfter(ie);
    }

    public static Optional<UserSubscription> meilleur(List<UserSubscription> lignes) {
        UserSubscription best = null;
        for (UserSubscription s : lignes) {
            if (best == null || meilleurQue(s, best)) best = s;
        }
        return Optional.ofNullable(best);
    }

    /**
     * Une décision admin courante qui n'est pas encore terminée à {@code t}
     * (drapeau « Accès manuel »). Même définition que le filtre SQL
     * {@code UserSpecifications.hasOpenOverride}, qui ne fait que la porter en base.
     */
    public static boolean aDecisionOuverte(List<AccessOverride> decisions, Instant t) {
        return decisions.stream().anyMatch(o -> o.estCourante()
                && (o.getEndsAt() == null || o.getEndsAt().isAfter(t)));
    }

    // ------------------------------------------------------------ vue admin

    /** Statut, dates, origine et alertes d'un produit pour la console admin (spec §2.4, §5.2). */
    public static EtatProduit etat(List<UserSubscription> achats, List<AccessOverride> decisions,
                                   ModuleAccess p, Instant t) {
        Optional<AccessOverride> d = decisionApplicable(decisions, p, t);
        boolean actif = acces(achats, decisions, p, t);
        List<AccessOverride> grantsFuturs = decisions.stream()
                .filter(AccessOverride::estCourante)
                .filter(o -> o.getProduct() == p && o.getType() == AccessOverrideType.GRANT
                        && o.getStartsAt().isAfter(t))
                .sorted(Comparator.comparing(AccessOverride::getStartsAt))
                .toList();

        ProductAccessStatus statut;
        Instant debut = null;
        Instant fin = null;
        AccessOrigin origine = null;
        if (actif) {
            statut = ProductAccessStatus.ACTIVE;
            // La fin d'un produit se lit sur ce seul produit : pour CIVIQUE,
            // fin(min = CIVIQUE) compterait aussi un Intégral.
            fin = finDuProduit(achats, decisions, p, t).instant();
            if (d.isPresent() && d.get().getType() == AccessOverrideType.GRANT) {
                origine = AccessOrigin.ADMIN_GRANT;
                debut = d.get().getStartsAt();
            } else {
                UserSubscription best = meilleur(achatsOuvrants(achats, decisions, p, t)).orElseThrow();
                origine = AccessOrigin.ofPurchase(best.getSource());
                debut = best.getStartsAt();
            }
        } else if (!grantsFuturs.isEmpty()) {
            statut = ProductAccessStatus.SCHEDULED;
            AccessOverride g = grantsFuturs.getFirst();
            debut = g.getStartsAt();
            fin = g.getEndsAt();
            origine = AccessOrigin.ADMIN_GRANT;
        } else if (d.isPresent() && d.get().getType() == AccessOverrideType.REVOKE) {
            statut = ProductAccessStatus.REVOKED;
            debut = d.get().getStartsAt();
            origine = AccessOrigin.ADMIN_REVOKE;
        } else {
            Instant derniere = null;
            AccessOrigin derniereOrigine = null;
            boolean passe = false;
            for (UserSubscription s : achats) {
                if (produitDe(s) != p) continue;
                passe = true;
                if (derniereOrigine == null) derniereOrigine = AccessOrigin.ofPurchase(s.getSource());
                Instant e = s.getEndsAt();
                if (e != null && !e.isAfter(t) && (derniere == null || e.isAfter(derniere))) {
                    derniere = e;
                    derniereOrigine = AccessOrigin.ofPurchase(s.getSource());
                }
            }
            for (AccessOverride o : decisions) {
                if (!o.estCourante() || o.getProduct() != p || o.getType() != AccessOverrideType.GRANT) continue;
                if (o.getEndsAt() != null && !o.getEndsAt().isAfter(t)) {
                    passe = true;
                    if (derniere == null || o.getEndsAt().isAfter(derniere)) {
                        derniere = o.getEndsAt();
                        derniereOrigine = AccessOrigin.ADMIN_GRANT;
                    }
                }
            }
            statut = passe ? ProductAccessStatus.EXPIRED : ProductAccessStatus.NONE;
            fin = derniere;
            origine = passe ? derniereOrigine : null;
        }
        return new EtatProduit(p, statut, debut, fin, origine,
                alertes(achats, decisions, p, t, statut, d, grantsFuturs));
    }

    private static Fin finDuProduit(List<UserSubscription> achats, List<AccessOverride> decisions,
                                    ModuleAccess p, Instant t) {
        if (p == ModuleAccess.INTEGRAL) return fin(achats, decisions, ModuleAccess.INTEGRAL, t);
        List<UserSubscription> achatsP = achats.stream().filter(s -> produitDe(s) == p).toList();
        List<AccessOverride> decisionsP = decisions.stream().filter(o -> o.getProduct() == p).toList();
        return fin(achatsP, decisionsP, p, t);
    }

    private static List<Alerte> alertes(List<UserSubscription> achats, List<AccessOverride> decisions,
                                        ModuleAccess p, Instant t, ProductAccessStatus statut,
                                        Optional<AccessOverride> d, List<AccessOverride> grantsFuturs) {
        List<Alerte> out = new ArrayList<>();
        boolean rembourse = false;
        boolean partiel = false;
        boolean recurrent = false;
        for (UserSubscription s : achats) {
            if (produitDe(s) != p) continue;
            if (s.getStatus() == SubscriptionStatus.REFUNDED || s.getPaymentStatus() == PaymentStatus.REFUNDED) {
                rembourse = true;
            } else if (s.getPaymentStatus() == PaymentStatus.PARTIALLY_REFUNDED) {
                partiel = true;
            }
            if (s.isAutoRenew() && SubscriptionService.covers(s, t)) recurrent = true;
        }
        if (rembourse) out.add(new Alerte(CodeAlerte.ACHAT_REMBOURSE, null, null));
        if (partiel) out.add(new Alerte(CodeAlerte.ACHAT_PARTIELLEMENT_REMBOURSE, null, null));
        decisions.stream()
                .filter(AccessOverride::estCourante)
                .filter(o -> o.getProduct() == p && o.getType() == AccessOverrideType.REVOKE
                        && o.getStartsAt().isAfter(t))
                .min(Comparator.comparing(AccessOverride::getStartsAt))
                .ifPresent(o -> out.add(new Alerte(CodeAlerte.REVOCATION_PROGRAMMEE, o.getStartsAt(), null)));
        if (statut != ProductAccessStatus.SCHEDULED && !grantsFuturs.isEmpty()) {
            AccessOverride g = grantsFuturs.getFirst();
            out.add(new Alerte(CodeAlerte.ACCES_PROGRAMME, g.getStartsAt(), g.getEndsAt()));
        }
        if (statut == ProductAccessStatus.ACTIVE && d.isPresent()
                && d.get().getType() == AccessOverrideType.REVOKE) {
            out.add(new Alerte(CodeAlerte.ROUVERT_PAR_ACHAT, null, null));
        }
        if (p == ModuleAccess.CIVIQUE && statut != ProductAccessStatus.ACTIVE
                && acces(achats, decisions, ModuleAccess.INTEGRAL, t)) {
            out.add(new Alerte(CodeAlerte.INCLUS_DANS_INTEGRAL, null, null));
        }
        if (recurrent) out.add(new Alerte(CodeAlerte.ABONNEMENT_RECURRENT, null, null));
        return out;
    }

    // ------------------------------------------------------------- internes

    private static List<ModuleAccess> produitsAuMoins(ModuleAccess min) {
        return min == ModuleAccess.INTEGRAL ? List.of(ModuleAccess.INTEGRAL) : PRODUITS;
    }

    /** Date d'un achat pour la règle « postérieur au REVOKE » : {@code purchased_at}, sinon son début. */
    private static Instant dateAchat(UserSubscription s) {
        return s.getPurchasedAt() != null ? s.getPurchasedAt() : s.getStartsAt();
    }

    private static void ajouterSiApres(TreeSet<Instant> bornes, Instant b, Instant t) {
        if (b != null && b.isAfter(t)) bornes.add(b);
    }
}
