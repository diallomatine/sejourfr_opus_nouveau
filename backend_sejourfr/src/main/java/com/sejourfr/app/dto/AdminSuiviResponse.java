package com.sejourfr.app.dto;

import com.sejourfr.app.enums.SubscriptionSource;
import com.sejourfr.app.enums.SuiviFunnelStep;
import com.sejourfr.app.enums.SuiviIndicator;
import com.sejourfr.app.enums.SuiviPeriodPreset;
import com.sejourfr.app.enums.SuiviPlatformFilter;
import com.sejourfr.app.enums.SuiviTypeFilter;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

/**
 * Reponse de {@code GET /api/admin/analytics/suivi} — le dashboard « Suivi »
 * (template {@code docs/admin/sejourfr-suivi-dashboard.html}, brief §7).
 *
 * <p>🛑 <b>{@code null} = inconnu ou pas encore mesure, jamais zero</b> (Q16,
 * D43). Un indicateur dont la date de debut de mesure est absente, ou posterieure
 * au debut de la periode, vaut {@code null} ; la date est servie dans
 * {@link #measurementStart} pour que l'ecran dise « mesuré depuis le … ».
 *
 * <p>Montants en <b>centimes d'euro</b>. Pourcentages en pourcent, une decimale
 * (64.0 = 64 %), {@code null} si le denominateur vaut 0 ou est inconnu. Le front
 * n'en recalcule aucun.
 *
 * <p>Deux logiques, jamais melangees : le <b>tunnel</b> (et le bloc « par
 * type », et les ratios) est une <b>cohorte</b> — les personnes dont le 1er sujet
 * d'un type a ete vu dans la periode, suivies {@code cohortWindowDays} jours ;
 * les <b>KPI, revenus, inscriptions, sources et l'activite</b> comptent ce qui
 * s'est passe <b>dans la periode</b>.
 */
public record AdminSuiviResponse(
        Window window,
        Filters filters,
        /** Toutes les cles de {@link SuiviIndicator} ; valeur {@code null} = pas encore mesure. */
        Map<SuiviIndicator, LocalDate> measurementStart,
        Kpis kpis,
        Funnel funnel,
        Revenue revenue,
        /** Toujours TCF puis CIVIQUE ; ignore le filtre type (c'est un comparatif). */
        List<TypeRow> byType,
        Signups signups,
        /** Groupes de la config dans leur ordre, repli ({@code autre}) en dernier. */
        List<SourceRow> sources,
        Ratios ratios,
        Activity activity
) {

    /**
     * @param preset          {@code null} pour une periode personnalisee
     * @param from            premier jour couvert, inclus (Paris)
     * @param to              dernier jour couvert, inclus (Paris)
     * @param previousFrom    periode de comparaison des tendances : meme duree,
     *                        juste avant (aujourd'hui → hier)
     * @param cohortWindowDays fenetre de conversion du tunnel
     * @param cohortOngoing   vrai si la fenetre d'au moins une entree de la
     *                        cohorte n'est pas encore ecoulee (chiffres encore mobiles)
     */
    public record Window(SuiviPeriodPreset preset, LocalDate from, LocalDate to,
                         LocalDate previousFrom, LocalDate previousTo, String timezone,
                         int cohortWindowDays, boolean cohortOngoing, Instant generatedAt) {
    }

    /**
     * Filtres appliques (echo). {@code availableSources} = valeurs admises pour
     * {@code source} (groupes de la config + repli), a utiliser pour construire
     * le selecteur.
     */
    public record Filters(SuiviTypeFilter type, SuiviPlatformFilter platform, String source,
                          boolean includeInternal, List<String> availableSources) {
    }

    /**
     * Un KPI de periode.
     *
     * @param value     valeur de la periode
     * @param previous  meme mesure sur la periode de comparaison
     * @param deltaPct  variation en %, {@code null} si {@code previous} vaut 0 ou est inconnu
     * @param ratioPct  ligne secondaire du template : submitted = % des visiteurs,
     *                  purchases = % des diagnostics soumis ; {@code null} pour les autres
     */
    public record Kpi(Long value, Long previous, Double deltaPct, Double ratioPct) {
    }

    /**
     * @param visitors      visiteurs uniques (identifiants de mesure distincts ayant
     *                      au moins un evenement dans la periode)
     * @param submitted     diagnostics soumis dans la periode, 1ʳᵉ tentative par
     *                      personne et par type (« Tous » = personnes distinctes)
     * @param purchases     achats de la periode (rembourses inclus)
     * @param netExVatCents net reel estime : net HT apres frais des achats de la
     *                      periode, remboursements de la periode deduits
     */
    public record Kpis(Kpi visitors, Kpi submitted, Kpi purchases, Kpi netExVatCents) {
    }

    /**
     * @param count           personnes ayant atteint l'etape
     * @param pctFromPrevious % depuis l'etape precedente (100.0 pour l'etape 1 non vide)
     * @param pctOfFirst      % de l'etape 1 (largeur de barre)
     * @param indicator       indicateur dont depend la mesure de l'etape
     */
    public record FunnelStep(SuiviFunnelStep code, Long count, Double pctFromPrevious, Double pctOfFirst,
                             SuiviIndicator indicator) {
    }

    /** Les 3 sous-lignes de « Compte rattache » ; leur somme vaut l'etape 3. */
    public record AttachedBreakdown(Long alreadyAuthenticated, Long signedUpAfter, Long loggedInAfter) {
    }

    /**
     * @param scope                         vue affichee (= filtre type)
     * @param steps                         les 7 etapes, dans l'ordre
     * @param cohortNetExVatCents           CA net cohorte : net HT des achats de
     *                                      l'etape 7, tous leurs remboursements deduits
     *                                      (quelle que soit leur date)
     * @param cohortPurchasesWithoutBreakdown achats de l'etape 7 dont le net est
     *                                      inconnu (non comptes dans le CA net)
     */
    public record Funnel(SuiviTypeFilter scope, List<FunnelStep> steps, AttachedBreakdown attached,
                         Long cohortNetExVatCents, Long cohortPurchasesWithoutBreakdown,
                         int cohortWindowDays, boolean ongoing) {
    }

    /** Un canal de paiement : STRIPE (web), APPLE (iOS), GOOGLE (Android). Toujours les 3, dans cet ordre. */
    public record ProviderRow(SubscriptionSource provider, Long purchases, Long grossCents,
                              Long providerFeeCents, Long netExVatCents) {
    }

    /**
     * Remboursements dates dans la periode.
     *
     * @param amountCents        montant rembourse en euros
     * @param netExVatDeltaCents effet sur le net HT (≤ 0)
     */
    public record Refunds(Long count, Long amountCents, Long netExVatDeltaCents) {
    }

    /**
     * Revenus de la periode (achats dates par {@code purchased_at}).
     *
     * @param grossCents                 brut paye TTC
     * @param netAfterFeeCents           ce qui arrive sur le compte bancaire
     * @param netExVatCents              net HT apres frais, AVANT remboursements
     * @param netExVatAfterRefundsCents  net reel estime (= KPI) : {@code netExVatCents}
     *                                   + {@code refunds.netExVatDeltaCents}
     * @param purchasesWithoutBreakdown  achats dont TVA / frais / net sont inconnus
     *                                   (non comptes dans les sommes de decomposition)
     * @param estimatedFeePurchases      achats dont le frais est une estimation (formule)
     */
    public record Revenue(Long purchases, Long grossCents, Long vatCents, Long providerFeeCents,
                          Long netAfterFeeCents, Long netExVatCents, Refunds refunds,
                          Long netExVatAfterRefundsCents, Long purchasesWithoutBreakdown,
                          Long estimatedFeePurchases, List<ProviderRow> byProvider) {
    }

    /** Colonnes TCF / Civique du tunnel (cohorte) : etapes 1, 2 et 7. */
    public record TypeRow(SuiviTypeFilter type, Long subjectViewed, Long submitted, Long purchases) {
    }

    public record AfterDiagnostic(Long total, Long tcf, Long civique) {
    }

    /** {@code mobileUnspecified} = application d'avant iOS/Android ; {@code unknown} = non declare. */
    public record SignupPlatforms(Long web, Long ios, Long android, Long mobileUnspecified, Long unknown) {
    }

    /**
     * Inscriptions de la periode ({@code users.created_at}). Le filtre type ne
     * s'y applique pas ({@code typeFilterApplied = false}) : une inscription
     * directe n'a pas de type ; la ventilation TCF / Civique est dans
     * {@code afterDiagnostic}.
     *
     * @param contextUnknown          comptes sans contexte d'inscription (anterieurs a la mesure)
     * @param loggedInAfterDiagnostic connexions a un compte existant ayant rattache un
     *                                diagnostic dans la periode (ce ne sont pas des inscriptions)
     */
    public record Signups(Long total, AfterDiagnostic afterDiagnostic, Long outsideDiagnostic,
                          Long contextUnknown, Long loggedInAfterDiagnostic, SignupPlatforms byPlatform,
                          boolean typeFilterApplied) {
    }

    /** Visiteurs de la periode par groupe de source first-touch. */
    public record SourceRow(String group, Long visitors) {
    }

    /**
     * Ratios §7.4, sur la cohorte du tunnel (memes filtres).
     *
     * @param diagnosticToSignupPct inscrits apres diagnostic / soumis anonymes (les
     *                              « deja connectes » exclus des deux termes)
     * @param netPerSubmittedCents  CA net cohorte / etape 2
     */
    public record Ratios(Double subjectToSubmissionPct, Double diagnosticToSignupPct,
                         Double reportViewedPct, Double planViewedPct, Double unlockIntentPct,
                         Double clickConversionPct, Double globalConversionPct,
                         Long netPerSubmittedCents) {
    }

    public record PurchasesByOrigin(Long diagnosticPlan, Long otherCta, Long unknown) {
    }

    /**
     * Activite de la periode (§7.3), sans cohorte.
     *
     * @param submittedFirst                    = KPI « Diagnostics soumis »
     * @param submittedRaw                      toutes les soumissions (refaites comprises)
     * @param anonymousSubmittedNeverAttached   soumis anonymes de la periode sans
     *                                          rattachement dans les {@code cohortWindowDays}
     *                                          jours (J+14)
     * @param anonymousNeverAttachedOngoing     vrai si J+14 n'est pas encore passe pour
     *                                          toute la periode (le chiffre peut encore baisser)
     */
    public record Activity(Long submittedFirst, Long submittedRaw, PurchasesByOrigin purchasesByOrigin,
                           Long anonymousSubmittedNeverAttached, boolean anonymousNeverAttachedOngoing) {
    }
}
