package com.sejourfr.app.service;

import com.sejourfr.app.dto.AudienceFunnelResponse;
import com.sejourfr.app.enums.FunnelEvent;
import com.sejourfr.app.enums.FunnelStage;
import com.sejourfr.app.manager.AudienceFunnelManager;
import com.sejourfr.app.repository.AudienceFunnelRepository;
import com.sejourfr.app.util.FenetreMesure;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

/**
 * Funnel d'acquisition servi a la console admin : TikTok → inscription →
 * diagnostic commence → diagnostic termine → ecran Premium → clic abonnement →
 * depart de paiement → paiement.
 *
 * <p><strong>La population est la COHORTE D'INSCRIPTION</strong> : les comptes
 * crees dans la fenetre, comptes supprimes exclus, et chaque etape est mesuree
 * sur CETTE cohorte quelle que soit la date de l'etape. C'est ce qui rend le
 * taux de conversion honnete — diviser les paiements du mois par les
 * inscriptions du mois melange deux populations et donne un chiffre qui ne
 * decrit personne. Un inscrit du 3 qui paie le 20 compte dans la cohorte du 3,
 * et il y comptera encore quand la fenetre glissera.
 *
 * <p><strong>Deux origines, une seule echelle.</strong> Inscription, diagnostic
 * et paiement se lisent sur les vraies tables ({@code users},
 * {@code diagnostic_sessions}, {@code user_subscriptions}) ; seules les deux
 * etapes qui n'existent que dans le navigateur passent par
 * {@code user_funnel_events}. Ce ne sont donc pas des estimations.
 *
 * <p>Sans rapport avec {@code PageViewService}, qui mesure le PRE-inscription
 * de facon anonyme et agregee. Les deux ne se melangent jamais dans une meme
 * reponse : l'un compte des vues sans identite, l'autre des comptes.
 *
 * <p>Cout : six requetes agregees, toutes bornees, quel que soit le nombre de
 * comptes.
 */
@Service
@RequiredArgsConstructor
public class AudienceFunnelService {

    /** Indices du vecteur de compteurs d'une cellule (source, plateforme). */
    private static final int SIGNUPS = 0;
    private static final int DIAG_STARTED = 1;
    private static final int DIAG_COMPLETED = 2;
    private static final int PAYWALL = 3;
    private static final int SUBSCRIBE = 4;
    private static final int CHECKOUT = 5;
    private static final int PURCHASES = 6;
    private static final int SLOTS = 7;

    private final AudienceFunnelManager manager;

    /** Fenêtre glissante de {@code days} jours, aujourd'hui inclus. */
    public AudienceFunnelResponse funnel(int days) {
        return funnel(null, null, days);
    }

    /**
     * Fenêtre explicite {@code from}..{@code to} (bornes incluses), ou repli sur
     * {@code days} si aucune borne n'est fournie. Les libellés de période
     * (« hier », « ce mois ») vivent côté admin : ici on ne voit que deux dates.
     *
     * <p>{@code integrity} reste mesuré sur TOUTE la base et n'est jamais filtré
     * par la période : une anomalie d'unicité ne doit pas pouvoir sortir du
     * champ de vision parce qu'on a réduit la fenêtre.
     */
    public AudienceFunnelResponse funnel(String rawFrom, String rawTo, int days) {
        FenetreMesure fenetre = FenetreMesure.resolve(rawFrom, rawTo, days);
        LocalDate cohortFrom = fenetre.from();
        LocalDate cohortTo = fenetre.to();
        Instant from = fenetre.startInstant();
        Instant to = fenetre.endInstantExclusive();

        Map<Cell, long[]> cells = collectCells(from, to);

        return new AudienceFunnelResponse(
                fenetre.days(),
                cohortFrom.toString(),
                cohortTo.toString(),
                stages(cells),
                bySource(cells),
                byPlatform(cells),
                daily(cohortFrom, cohortTo, from, to),
                integrity());
    }

    // ------------------------------------------------------------------------
    // Cohorte
    // ------------------------------------------------------------------------

    /**
     * Une cellule par paire (provenance, plateforme) d'inscription. Chaque
     * compte appartient a exactement une cellule : les sous-totaux sont donc
     * additionnables, et la somme des comptes distincts par cellule est bien le
     * compte distinct global.
     *
     * <p>Seules les cellules issues des inscriptions existent : une etape ne
     * peut pas etre franchie par un compte qui n'est pas dans la cohorte.
     */
    private Map<Cell, long[]> collectCells(Instant from, Instant to) {
        Map<Cell, long[]> cells = new LinkedHashMap<>();
        for (AudienceFunnelRepository.CohortCell row : manager.signups(from, to)) {
            slot(cells, row.getSource(), row.getPlatform())[SIGNUPS] = row.getTotal();
        }
        for (AudienceFunnelRepository.DiagnosticCell row : manager.diagnostics(from, to)) {
            long[] counters = slot(cells, row.getSource(), row.getPlatform());
            counters[DIAG_STARTED] = row.getStarted();
            counters[DIAG_COMPLETED] = row.getCompleted();
        }
        for (AudienceFunnelRepository.EventCell row : manager.funnelEvents(from, to)) {
            int index = indexOf(row.getEvent());
            if (index < 0) continue; // événement retiré du contrat : on ignore, on n'invente pas
            slot(cells, row.getSource(), row.getPlatform())[index] = row.getTotal();
        }
        for (AudienceFunnelRepository.CohortCell row : manager.purchases(from, to)) {
            slot(cells, row.getSource(), row.getPlatform())[PURCHASES] = row.getTotal();
        }
        return cells;
    }

    private static long[] slot(Map<Cell, long[]> cells, String source, String platform) {
        return cells.computeIfAbsent(new Cell(source, platform), k -> new long[SLOTS]);
    }

    private static int indexOf(String event) {
        if (FunnelEvent.PAYWALL_VIEWED.name().equals(event)) return PAYWALL;
        if (FunnelEvent.SUBSCRIBE_CLICKED.name().equals(event)) return SUBSCRIBE;
        if (FunnelEvent.CHECKOUT_STARTED.name().equals(event)) return CHECKOUT;
        return -1;
    }

    // ------------------------------------------------------------------------
    // Vues
    // ------------------------------------------------------------------------

    /** Les 7 etapes, toujours servies, toujours dans l'ordre du parcours reel. */
    private static List<AudienceFunnelResponse.StageCount> stages(Map<Cell, long[]> cells) {
        long[] totals = new long[SLOTS];
        for (long[] counters : cells.values()) {
            for (int i = 0; i < SLOTS; i++) totals[i] += counters[i];
        }
        return List.of(
                new AudienceFunnelResponse.StageCount(FunnelStage.SIGNUP.name(), totals[SIGNUPS]),
                new AudienceFunnelResponse.StageCount(
                        FunnelStage.DIAGNOSTIC_STARTED.name(), totals[DIAG_STARTED]),
                new AudienceFunnelResponse.StageCount(
                        FunnelStage.DIAGNOSTIC_COMPLETED.name(), totals[DIAG_COMPLETED]),
                new AudienceFunnelResponse.StageCount(
                        FunnelStage.PAYWALL_VIEWED.name(), totals[PAYWALL]),
                new AudienceFunnelResponse.StageCount(
                        FunnelStage.SUBSCRIBE_CLICKED.name(), totals[SUBSCRIBE]),
                new AudienceFunnelResponse.StageCount(
                        FunnelStage.CHECKOUT_STARTED.name(), totals[CHECKOUT]),
                new AudienceFunnelResponse.StageCount(FunnelStage.PURCHASE.name(), totals[PURCHASES]));
    }

    private static List<AudienceFunnelResponse.SourceFunnel> bySource(Map<Cell, long[]> cells) {
        return foldBy(cells, Cell::source).entrySet().stream()
                .map(e -> new AudienceFunnelResponse.SourceFunnel(
                        e.getKey(),
                        e.getValue()[SIGNUPS], e.getValue()[DIAG_STARTED],
                        e.getValue()[DIAG_COMPLETED], e.getValue()[PAYWALL],
                        e.getValue()[SUBSCRIBE], e.getValue()[CHECKOUT],
                        e.getValue()[PURCHASES]))
                .sorted(Comparator
                        .comparingLong(AudienceFunnelResponse.SourceFunnel::signups).reversed()
                        .thenComparing(AudienceFunnelResponse.SourceFunnel::source))
                .toList();
    }

    private static List<AudienceFunnelResponse.PlatformFunnel> byPlatform(Map<Cell, long[]> cells) {
        return foldBy(cells, Cell::platform).entrySet().stream()
                .map(e -> new AudienceFunnelResponse.PlatformFunnel(
                        e.getKey(),
                        e.getValue()[SIGNUPS], e.getValue()[DIAG_STARTED],
                        e.getValue()[DIAG_COMPLETED], e.getValue()[PAYWALL],
                        e.getValue()[SUBSCRIBE], e.getValue()[CHECKOUT],
                        e.getValue()[PURCHASES]))
                .sorted(Comparator
                        .comparingLong(AudienceFunnelResponse.PlatformFunnel::signups).reversed()
                        .thenComparing(AudienceFunnelResponse.PlatformFunnel::platform))
                .toList();
    }

    private static Map<String, long[]> foldBy(Map<Cell, long[]> cells,
                                              java.util.function.Function<Cell, String> key) {
        Map<String, long[]> folded = new TreeMap<>();
        cells.forEach((cell, counters) -> {
            long[] bucket = folded.computeIfAbsent(key.apply(cell), k -> new long[SLOTS]);
            for (int i = 0; i < SLOTS; i++) bucket[i] += counters[i];
        });
        return folded;
    }

    /**
     * Serie continue : <strong>un point par jour de la fenetre, meme a zero</strong>.
     * Un trou dans une courbe se lit comme une absence de mesure, pas comme une
     * absence d'inscription — c'est au serveur de trancher, pas au front.
     */
    private List<AudienceFunnelResponse.DailyPoint> daily(LocalDate cohortFrom, LocalDate cohortTo,
                                                          Instant from, Instant to) {
        Map<String, long[]> byDay = new TreeMap<>();
        for (AudienceFunnelRepository.DailyCell row : manager.daily(from, to)) {
            if (row.getDay() == null) continue;
            long[] bucket = byDay.computeIfAbsent(row.getDay(), k -> new long[4]);
            switch (row.getKind()) {
                case "SIGNUP" -> bucket[0] = row.getTotal();
                case "DIAGNOSTIC_STARTED" -> bucket[1] = row.getTotal();
                case "DIAGNOSTIC_COMPLETED" -> bucket[2] = row.getTotal();
                case "PURCHASE" -> bucket[3] = row.getTotal();
                default -> { /* nature inconnue : ignorée, jamais inventée */ }
            }
        }
        List<AudienceFunnelResponse.DailyPoint> points = new ArrayList<>();
        for (LocalDate day = cohortFrom; !day.isAfter(cohortTo); day = day.plusDays(1)) {
            long[] bucket = byDay.getOrDefault(day.toString(), new long[4]);
            points.add(new AudienceFunnelResponse.DailyPoint(
                    day.toString(), bucket[0], bucket[1], bucket[2], bucket[3]));
        }
        return points;
    }

    /** Controle d'unicite du diagnostic, mesure sur TOUTE la base. */
    private AudienceFunnelResponse.Integrity integrity() {
        AudienceFunnelRepository.IntegrityRow row = manager.integrity();
        if (row == null) return new AudienceFunnelResponse.Integrity(0, 0, 0);
        return new AudienceFunnelResponse.Integrity(
                row.getAccounts(), row.getSessions(), row.getMulti());
    }

    /** Paire (provenance, plateforme) d'inscription : la maille de la cohorte. */
    private record Cell(String source, String platform) {
    }
}
