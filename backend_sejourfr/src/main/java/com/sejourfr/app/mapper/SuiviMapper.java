package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.AdminSuiviResponse;
import com.sejourfr.app.dto.AdminSuiviResponse.Activity;
import com.sejourfr.app.dto.AdminSuiviResponse.AfterDiagnostic;
import com.sejourfr.app.dto.AdminSuiviResponse.AttachedBreakdown;
import com.sejourfr.app.dto.AdminSuiviResponse.Funnel;
import com.sejourfr.app.dto.AdminSuiviResponse.FunnelStep;
import com.sejourfr.app.dto.AdminSuiviResponse.Kpi;
import com.sejourfr.app.dto.AdminSuiviResponse.Kpis;
import com.sejourfr.app.dto.AdminSuiviResponse.ProviderRow;
import com.sejourfr.app.dto.AdminSuiviResponse.PurchasesByOrigin;
import com.sejourfr.app.dto.AdminSuiviResponse.Ratios;
import com.sejourfr.app.dto.AdminSuiviResponse.Refunds;
import com.sejourfr.app.dto.AdminSuiviResponse.Revenue;
import com.sejourfr.app.dto.AdminSuiviResponse.SignupPlatforms;
import com.sejourfr.app.dto.AdminSuiviResponse.Signups;
import com.sejourfr.app.dto.AdminSuiviResponse.SourceRow;
import com.sejourfr.app.dto.AdminSuiviResponse.TypeRow;
import com.sejourfr.app.enums.SubscriptionSource;
import com.sejourfr.app.enums.SuiviFunnelStep;
import com.sejourfr.app.enums.SuiviIndicator;
import com.sejourfr.app.enums.SuiviPlatformFilter;
import com.sejourfr.app.enums.SuiviTypeFilter;
import com.sejourfr.app.manager.SuiviReadManager;
import com.sejourfr.app.repository.SuiviReadRepository.FunnelRow;
import com.sejourfr.app.repository.SuiviReadRepository.PurchaseCell;
import com.sejourfr.app.repository.SuiviReadRepository.RefundCell;
import com.sejourfr.app.repository.SuiviReadRepository.SignupRow;
import com.sejourfr.app.repository.SuiviReadRepository.VisitorCell;
import com.sejourfr.app.service.analytics.SuiviQuery;
import com.sejourfr.app.util.FenetreMesure;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;

/**
 * Construit la reponse du dashboard « Suivi » depuis les agregats SQL — pur :
 * aucune lecture, aucune horloge (l'instant de reference est recu).
 *
 * <p>🛑 <b>Un indicateur non mesure vaut {@code null}</b>, jamais 0 (Q16, D43) :
 * {@link Mesure} dit, pour un jour de debut de periode, si chaque indicateur
 * etait deja en service. Une somme <i>mesuree</i> mais vide vaut 0 : il ne
 * s'est rien passe, et on le sait.
 */
@Component
public class SuiviMapper {

    /** Ce qui etait mesure au debut de la periode et de la periode precedente. */
    public record Mesure(Map<SuiviIndicator, LocalDate> starts, LocalDate from, LocalDate previousFrom,
                         boolean needsPlatformDetail) {

        /** Tous ces indicateurs etaient en service le {@code day}. */
        public boolean at(LocalDate day, SuiviIndicator... indicators) {
            for (SuiviIndicator indicator : indicators) {
                LocalDate start = starts.get(indicator);
                if (start == null || start.isAfter(day)) return false;
            }
            return true;
        }

        public boolean now(SuiviIndicator... indicators) {
            return at(from, indicators);
        }

        public boolean before(SuiviIndicator... indicators) {
            return at(previousFrom, indicators);
        }
    }

    public AdminSuiviResponse toResponse(SuiviQuery query, FenetreMesure previous, int windowDays,
                                         Instant now, List<String> availableSources,
                                         Map<SuiviIndicator, LocalDate> starts, Mesure mesure,
                                         SuiviReadManager.Lectures l) {
        Instant endExclusive = query.window().endInstantExclusive();
        boolean ongoing = endExclusive.plus(java.time.Duration.ofDays(windowDays)).isAfter(now);

        Revenue revenue = revenue(l.purchases(), l.refunds(), "CUR", mesure, true);
        Revenue previousRevenue = revenue(l.purchases(), l.refunds(), "PREV", mesure, false);

        Map<String, FunnelRow> funnelRows = new java.util.HashMap<>();
        for (FunnelRow row : l.funnel()) funnelRows.put(row.getScope(), row);
        FunnelRow scopeRow = funnelRows.get(scopeKey(query.type()));
        Funnel funnel = funnel(query.type(), scopeRow, mesure, windowDays, ongoing);

        boolean visitorsMeasured = mesure.now(SuiviIndicator.VISITORS) && platformOk(mesure, true);
        boolean visitorsPrevMeasured = mesure.before(SuiviIndicator.VISITORS) && platformOk(mesure, false);
        Long visitors = visitorsMeasured ? sumVisitors(l.visitors(), "CUR") : null;
        Long visitorsPrev = visitorsPrevMeasured ? sumVisitors(l.visitors(), "PREV") : null;

        Long submitted = mesure.now(SuiviIndicator.DIAGNOSTIC_SUBMITTED) ? l.activity().getCurFirst() : null;
        Long submittedPrev = mesure.before(SuiviIndicator.DIAGNOSTIC_SUBMITTED) ? l.activity().getPrevFirst() : null;
        Long submittedRaw = mesure.now(SuiviIndicator.DIAGNOSTIC_SUBMITTED) ? l.activity().getCurRaw() : null;

        Kpis kpis = new Kpis(
                new Kpi(visitors, visitorsPrev, delta(visitors, visitorsPrev), null),
                new Kpi(submitted, submittedPrev, delta(submitted, submittedPrev), pct(submitted, visitors)),
                new Kpi(revenue.purchases(), previousRevenue.purchases(),
                        delta(revenue.purchases(), previousRevenue.purchases()), pct(revenue.purchases(), submitted)),
                new Kpi(revenue.netExVatAfterRefundsCents(), previousRevenue.netExVatAfterRefundsCents(),
                        delta(revenue.netExVatAfterRefundsCents(), previousRevenue.netExVatAfterRefundsCents()), null));

        boolean anonMeasured = mesure.now(SuiviIndicator.DIAGNOSTIC_SUBMITTED, SuiviIndicator.ACCOUNT_ATTACHED);
        Activity activity = new Activity(submitted, submittedRaw,
                purchasesByOrigin(l.purchases(), mesure),
                anonMeasured ? l.activity().getAnonNeverAttached() : null, ongoing);

        return new AdminSuiviResponse(
                new AdminSuiviResponse.Window(query.preset(), query.window().from(), query.window().to(),
                        previous.from(), previous.to(), FenetreMesure.PARIS.getId(), windowDays, ongoing, now),
                new AdminSuiviResponse.Filters(query.type(), query.platform(),
                        query.source() == null ? "ALL" : query.source(), query.includeInternal(),
                        availableSources),
                starts,
                kpis,
                funnel,
                revenue,
                List.of(typeRow(SuiviTypeFilter.TCF, funnelRows.get("QUICK_TCF"), mesure),
                        typeRow(SuiviTypeFilter.CIVIQUE, funnelRows.get("CIVIQUE"), mesure)),
                signups(l.signups(), l.activity().getLoggedInAfter(), mesure),
                sources(l.visitors(), availableSources, visitorsMeasured
                        && mesure.now(SuiviIndicator.ACQUISITION_SOURCES)),
                ratios(scopeRow, funnel),
                activity);
    }

    // ------------------------------------------------------------------------
    // Tunnel
    // ------------------------------------------------------------------------

    static String scopeKey(SuiviTypeFilter type) {
        return switch (type) {
            case ALL -> "ALL";
            case TCF -> "QUICK_TCF";
            case CIVIQUE -> "CIVIQUE";
        };
    }

    /** Une etape est mesuree si elle ET toutes les precedentes le sont (le tunnel est sequentiel). */
    static boolean[] stepsMeasured(Mesure mesure) {
        SuiviFunnelStep[] steps = SuiviFunnelStep.values();
        boolean[] measured = new boolean[steps.length];
        boolean all = true;
        for (int i = 0; i < steps.length; i++) {
            all = all && mesure.now(steps[i].indicator());
            if (steps[i] == SuiviFunnelStep.PURCHASED) all = all && mesure.now(SuiviIndicator.PURCHASES);
            measured[i] = all;
        }
        return measured;
    }

    private static long[] counts(FunnelRow row) {
        if (row == null) return new long[7];
        return new long[]{row.getS1(), row.getS2(), row.getS3(), row.getS4(), row.getS5(), row.getS6(),
                row.getS7()};
    }

    private Funnel funnel(SuiviTypeFilter scope, FunnelRow row, Mesure mesure, int windowDays, boolean ongoing) {
        boolean[] measured = stepsMeasured(mesure);
        long[] counts = counts(row);
        SuiviFunnelStep[] codes = SuiviFunnelStep.values();
        List<FunnelStep> steps = new ArrayList<>(codes.length);
        Long first = measured[0] ? counts[0] : null;
        Long previous = null;
        for (int i = 0; i < codes.length; i++) {
            Long count = measured[i] ? counts[i] : null;
            Double fromPrevious = i == 0
                    ? (count != null && count > 0 ? 100.0 : null)
                    : pct(count, previous);
            steps.add(new FunnelStep(codes[i], count, fromPrevious, pct(count, first), codes[i].indicator()));
            previous = count;
        }
        boolean attachedMeasured = measured[2];
        AttachedBreakdown attached = attachedMeasured
                ? new AttachedBreakdown(row == null ? 0L : row.getAttachedAlready(),
                row == null ? 0L : row.getAttachedSignup(), row == null ? 0L : row.getAttachedLogin())
                : new AttachedBreakdown(null, null, null);
        boolean netMeasured = measured[6] && mesure.now(SuiviIndicator.REVENUE_BREAKDOWN, SuiviIndicator.REFUNDS);
        Long net = netMeasured ? (row == null || row.getCohortNet() == null ? 0L : row.getCohortNet()) : null;
        Long unknown = netMeasured ? (row == null ? 0L : row.getCohortUnknown()) : null;
        return new Funnel(scope, steps, attached, net, unknown, windowDays, ongoing);
    }

    private TypeRow typeRow(SuiviTypeFilter type, FunnelRow row, Mesure mesure) {
        boolean[] measured = stepsMeasured(mesure);
        long[] counts = counts(row);
        return new TypeRow(type, measured[0] ? counts[0] : null, measured[1] ? counts[1] : null,
                measured[6] ? counts[6] : null);
    }

    private Ratios ratios(FunnelRow row, Funnel funnel) {
        List<FunnelStep> s = funnel.steps();
        Long s1 = s.get(0).count();
        Long s2 = s.get(1).count();
        Long s3 = s.get(2).count();
        Long s4 = s.get(3).count();
        Long s5 = s.get(4).count();
        Long s6 = s.get(5).count();
        Long s7 = s.get(6).count();
        Long anonymous = s2 == null ? null : (row == null ? 0L : row.getAnonSubmitted());
        Long netPerSubmitted = null;
        if (funnel.cohortNetExVatCents() != null && s2 != null && s2 > 0) {
            netPerSubmitted = BigDecimal.valueOf(funnel.cohortNetExVatCents())
                    .divide(BigDecimal.valueOf(s2), 0, RoundingMode.HALF_UP).longValue();
        }
        return new Ratios(pct(s2, s1), pct(funnel.attached().signedUpAfter(), anonymous), pct(s4, s3),
                pct(s5, s4), pct(s6, s5), pct(s7, s6), pct(s7, s2), netPerSubmitted);
    }

    // ------------------------------------------------------------------------
    // Revenus
    // ------------------------------------------------------------------------

    private Revenue revenue(List<PurchaseCell> cells, List<RefundCell> refundCells, String per, Mesure mesure,
                            boolean current) {
        boolean purchasesMeasured = current ? mesure.now(SuiviIndicator.PURCHASES)
                : mesure.before(SuiviIndicator.PURCHASES);
        boolean breakdownMeasured = purchasesMeasured && (current ? mesure.now(SuiviIndicator.REVENUE_BREAKDOWN)
                : mesure.before(SuiviIndicator.REVENUE_BREAKDOWN));
        boolean refundsMeasured = current ? mesure.now(SuiviIndicator.REFUNDS)
                : mesure.before(SuiviIndicator.REFUNDS);

        Map<SubscriptionSource, long[]> byProvider = new EnumMap<>(SubscriptionSource.class);
        for (SubscriptionSource source : SubscriptionSource.values()) byProvider.put(source, new long[4]);
        long n = 0, gross = 0, vat = 0, fee = 0, netAfterFee = 0, netExVat = 0, without = 0, estimated = 0;
        for (PurchaseCell c : cells) {
            if (!per.equals(c.getPer())) continue;
            long[] p = byProvider.get(SubscriptionSource.valueOf(c.getProvider()));
            p[0] += c.getN();
            p[1] += zero(c.getGross());
            p[2] += zero(c.getFee());
            p[3] += zero(c.getNetExVat());
            n += c.getN();
            gross += zero(c.getGross());
            vat += zero(c.getVat());
            fee += zero(c.getFee());
            netAfterFee += zero(c.getNetAfterFee());
            netExVat += zero(c.getNetExVat());
            without += c.getWithoutBreakdown();
            estimated += c.getEstimatedFee();
        }
        long refundCount = 0, refundAmount = 0, refundDelta = 0;
        for (RefundCell r : refundCells) {
            if (!per.equals(r.getPer())) continue;
            refundCount += r.getN();
            refundAmount += zero(r.getAmount());
            refundDelta += zero(r.getDelta());
        }
        List<ProviderRow> providers = new ArrayList<>();
        for (Map.Entry<SubscriptionSource, long[]> e : byProvider.entrySet()) {
            long[] p = e.getValue();
            providers.add(new ProviderRow(e.getKey(), purchasesMeasured ? p[0] : null,
                    purchasesMeasured ? p[1] : null, breakdownMeasured ? p[2] : null,
                    breakdownMeasured ? p[3] : null));
        }
        Refunds refunds = refundsMeasured ? new Refunds(refundCount, refundAmount, refundDelta)
                : new Refunds(null, null, null);
        return new Revenue(
                purchasesMeasured ? n : null,
                purchasesMeasured ? gross : null,
                breakdownMeasured ? vat : null,
                breakdownMeasured ? fee : null,
                breakdownMeasured ? netAfterFee : null,
                breakdownMeasured ? netExVat : null,
                refunds,
                breakdownMeasured && refundsMeasured ? netExVat + refundDelta : null,
                breakdownMeasured ? without : null,
                breakdownMeasured ? estimated : null,
                providers);
    }

    private PurchasesByOrigin purchasesByOrigin(List<PurchaseCell> cells, Mesure mesure) {
        if (!mesure.now(SuiviIndicator.PURCHASES, SuiviIndicator.PURCHASE_ORIGIN)) {
            return new PurchasesByOrigin(null, null, null);
        }
        long plan = 0, other = 0, unknown = 0;
        for (PurchaseCell c : cells) {
            if (!"CUR".equals(c.getPer())) continue;
            plan += c.getOriginDiagnosticPlan();
            other += c.getOriginOtherCta();
            unknown += c.getOriginUnknown();
        }
        return new PurchasesByOrigin(plan, other, unknown);
    }

    // ------------------------------------------------------------------------
    // Inscriptions, sources
    // ------------------------------------------------------------------------

    private Signups signups(SignupRow row, long loggedInAfter, Mesure mesure) {
        boolean totalMeasured = platformOk(mesure, true);
        boolean context = totalMeasured && mesure.now(SuiviIndicator.SIGNUP_CONTEXT);
        boolean platforms = mesure.now(SuiviIndicator.SIGNUP_PLATFORM_DETAIL);
        return new Signups(
                totalMeasured ? row.getTotal() : null,
                context ? new AfterDiagnostic(row.getAfterTotal(), row.getAfterTcf(), row.getAfterCivique())
                        : new AfterDiagnostic(null, null, null),
                context ? row.getOutside() : null,
                context ? row.getContextUnknown() : null,
                mesure.now(SuiviIndicator.ACCOUNT_ATTACHED) ? loggedInAfter : null,
                platforms ? new SignupPlatforms(row.getWeb(), row.getIos(), row.getAndroid(), row.getMobile(),
                        row.getPlatformUnknown()) : new SignupPlatforms(null, null, null, null, null),
                false);
    }

    private List<SourceRow> sources(List<VisitorCell> cells, List<String> groups, boolean measured) {
        List<SourceRow> rows = new ArrayList<>(groups.size());
        for (String group : groups) {
            long n = 0;
            for (VisitorCell c : cells) {
                if ("CUR".equals(c.getPer()) && group.equals(c.getGrp())) n += c.getN();
            }
            rows.add(new SourceRow(group, measured ? n : null));
        }
        return rows;
    }

    private static long sumVisitors(List<VisitorCell> cells, String per) {
        long n = 0;
        for (VisitorCell c : cells) if (per.equals(c.getPer())) n += c.getN();
        return n;
    }

    /**
     * Un filtre iOS / Android ne lit des faits declares par plateforme qu'a partir
     * de la mesure iOS / Android ({@code SIGNUP_PLATFORM_DETAIL}) : avant, ces
     * lignes etaient « mobile » ou inconnues, et le filtre rendrait un 0 faux.
     */
    private static boolean platformOk(Mesure mesure, boolean current) {
        if (!mesure.needsPlatformDetail()) return true;
        return current ? mesure.now(SuiviIndicator.SIGNUP_PLATFORM_DETAIL)
                : mesure.before(SuiviIndicator.SIGNUP_PLATFORM_DETAIL);
    }

    // ------------------------------------------------------------------------
    // Pourcentages
    // ------------------------------------------------------------------------

    /** {@code num / den} en %, une decimale ; {@code null} si l'un est inconnu ou si {@code den} vaut 0. */
    public static Double pct(Long num, Long den) {
        if (num == null || den == null || den == 0) return null;
        return BigDecimal.valueOf(num * 100L).divide(BigDecimal.valueOf(den), 1, RoundingMode.HALF_UP)
                .doubleValue();
    }

    /** Variation en % ; {@code null} si l'un est inconnu ou si la periode precedente vaut 0. */
    public static Double delta(Long current, Long previous) {
        if (current == null || previous == null || previous == 0) return null;
        return BigDecimal.valueOf((current - previous) * 100L)
                .divide(BigDecimal.valueOf(previous), 1, RoundingMode.HALF_UP).doubleValue();
    }

    private static long zero(Long value) {
        return value == null ? 0L : value;
    }

    /** Filtre plateforme qui demande la mesure iOS / Android. */
    public static boolean needsPlatformDetail(SuiviPlatformFilter platform) {
        return platform == SuiviPlatformFilter.IOS || platform == SuiviPlatformFilter.ANDROID;
    }
}
