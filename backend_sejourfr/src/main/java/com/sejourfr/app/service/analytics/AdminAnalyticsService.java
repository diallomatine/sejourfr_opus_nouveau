package com.sejourfr.app.service.analytics;

import com.github.benmanes.caffeine.cache.Cache;
import com.github.benmanes.caffeine.cache.Caffeine;
import com.sejourfr.app.config.AnalyticsProperties;
import com.sejourfr.app.dto.AdminAnalyticsResponse;
import com.sejourfr.app.dto.AnalyticsAnnotationDto;
import com.sejourfr.app.enums.AnalyticsCtaLocation;
import com.sejourfr.app.enums.AnalyticsGrain;
import com.sejourfr.app.manager.AnalyticsReadManager;
import com.sejourfr.app.repository.AnalyticsReadRepository;
import com.sejourfr.app.util.AnalyticsLibelles;
import com.sejourfr.app.util.FenetreMesure;
import com.sejourfr.app.util.RepartitionArrondie;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.DayOfWeek;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.time.temporal.TemporalAdjusters;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

/**
 * L'ecran Analytics : acquisition → diagnostic → inscription → Premium →
 * paiement, en <b>une seule reponse</b>.
 *
 * <h2>Ce qui tient la justesse de cet ecran</h2>
 * <ul>
 *   <li>🛑 <b>{@code v} compte des visiteurs DISTINCTS</b>, jamais des vues
 *       (brief §27, §109), et {@code prem} des <b>cliqueurs uniques</b> : le
 *       volume brut de clics n'apparait que dans la table CTA, ou il decrit
 *       autre chose.</li>
 *   <li>🛑 <b>{@code sig}, {@code pay} et les ventilations suivent la COHORTE
 *       d'inscription</b> — la population est celle des comptes crees dans la
 *       fenetre, et chaque etape se mesure sur ces memes comptes quelle que soit
 *       sa date (patron {@code AudienceFunnelService}). C'est ce qui rend
 *       « 4 payants sur 50 inscrits TikTok » vrai. Un payant etant un
 *       <b>compte</b> et non une souscription, un renouvellement n'ajoute jamais
 *       un nouvel abonne.</li>
 *   <li>🛑 <b>{@code revEurCents} est la somme REELLE de
 *       {@code amount_eur_cents}</b>. La maquette calcule
 *       {@code pay × 14,99} : on ne le reproduit pas. Un montant inconnu ne
 *       compte pas — il ne vaut pas zero.</li>
 *   <li><b>Comparaison</b> : periode precedente de meme duree, collee a
 *       {@code from}. {@code previous = 0} ⇒ ecart {@code null}, jamais une
 *       division par zero ({@link AnalyticsCalculs}).</li>
 *   <li><b>Series continues des deux cotes</b>, zeros compris : sans ca,
 *       {@code from == to} sur une journee creuse rendait une serie vide, qui se
 *       lit comme une panne de mesure et non comme une journee sans visite.</li>
 *   <li><b>Arrondi a somme conservee</b> dans les ventilations en part
 *       ({@link RepartitionArrondie}) : la somme des lignes egale toujours le
 *       pied de table. Le front ne recalcule rien.</li>
 *   <li><b>Comptes de test exclus EN SQL</b> (brief §85), jamais soustraits
 *       apres coup.</li>
 *   <li><b>{@code direct} ≠ {@code inconnu}</b>, et {@code inconnu} ne se cache
 *       jamais : un gros volume d'inconnu est lui-meme l'information.</li>
 * </ul>
 *
 * <h2>Cout</h2>
 * <b>Dix requetes agregees, constantes</b> : le nombre ne depend ni du nombre de
 * sources, ni de pays, ni de campagnes, ni de visiteurs. Verrouille par un test
 * qui compte les statements prepares et exige une <b>egalite</b> — patron
 * {@code SkillMasteryResolverIT} : sans egalite, un N+1 se glisse sans qu'aucun
 * test ne rougisse.
 *
 * <h2>Cache</h2>
 * 60 s (brief §67), par fenetre <i>appliquee</i> et par jeu de filtres. Assez
 * court pour qu'un admin qui recharge voie ses chiffres bouger, assez long pour
 * absorber les allers-retours d'un ecran qu'on parcourt.
 */
@Service
@RequiredArgsConstructor
public class AdminAnalyticsService {

    /** Brief §67 : « 30-120 secondes est acceptable ». */
    static final Duration DUREE_CACHE = Duration.ofSeconds(60);

    /** Seule devise servie : le revenu est deja converti et fige a l'encaissement. */
    private static final String DEVISE = "EUR";

    private static final DateTimeFormatter CLE_SEAU =
            DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
    private static final DateTimeFormatter LIBELLE_HEURE =
            DateTimeFormatter.ofPattern("d MMMM, HH'h'", Locale.FRANCE);
    private static final DateTimeFormatter LIBELLE_JOUR =
            DateTimeFormatter.ofPattern("EEEE d MMMM", Locale.FRANCE);
    private static final DateTimeFormatter LIBELLE_COURT_JOUR =
            DateTimeFormatter.ofPattern("dd/MM", Locale.FRANCE);
    private static final DateTimeFormatter LIBELLE_COURT_HEURE =
            DateTimeFormatter.ofPattern("HH'h'", Locale.FRANCE);
    private static final DateTimeFormatter LIBELLE_DATE =
            DateTimeFormatter.ofPattern("d MMMM yyyy", Locale.FRANCE);

    /**
     * Separateur des composantes d'une cle de campagne — {@code chr(31)}, le
     * separateur d'unites ASCII, cote SQL comme ici.
     *
     * <p>Un caractere de controle, et non un {@code |} ou un {@code ;} : un nom
     * de campagne est redige par un outil marketing sur lequel nous n'avons
     * aucun pouvoir, et le jour ou il contiendrait le separateur, la cle se
     * couperait au mauvais endroit.
     */
    private static final String SEP = String.valueOf((char) 31);

    private final AnalyticsReadManager manager;
    private final AnalyticsAnnotationService annotationService;
    private final AnalyticsInsightsBuilder insightsBuilder;
    private final AnalyticsProperties properties;

    private final Cache<String, AdminAnalyticsResponse> cache = Caffeine.newBuilder()
            .expireAfterWrite(DUREE_CACHE)
            .maximumSize(256)
            .build();

    /**
     * L'ecran, pour une fenetre et des filtres.
     *
     * <p>{@code from}/{@code to} l'emportent sur {@code days} ; une seule borne,
     * une date illisible, {@code from > to} ou plus de 365 jours sont des
     * <b>400 nommes</b>, jamais un repli muet sur la fenetre par defaut —
     * autorite {@link FenetreMesure}, reutilisee telle quelle.
     */
    public AdminAnalyticsResponse analytics(String rawFrom, String rawTo, int days,
                                            String source, String country,
                                            String device, String platform) {
        FenetreMesure fenetre = FenetreMesure.resolve(rawFrom, rawTo, days);
        AnalyticsReadManager.Filtres filtres =
                new AnalyticsReadManager.Filtres(source, country, device, platform);
        String cle = fenetre.from() + "→" + fenetre.to() + "#" + filtres.cle();
        return cache.get(cle, ignored -> compute(fenetre, filtres));
    }

    /**
     * Vide le cache.
     *
     * <p>Appele quand un <b>repere</b> est cree ou supprime : c'est la seule
     * ecriture qu'un admin fait depuis cet ecran, et lui faire attendre 60 s
     * pour voir sa propre annotation lui donnerait l'impression que rien ne
     * s'est passe — il la reposerait. Les mesures, elles, continuent d'etre
     * servies avec leur fraicheur de 60 s : elles ne dependent d'aucun geste de
     * l'admin.
     */
    public void invalidate() {
        cache.invalidateAll();
    }

    /**
     * Le calcul reel, sans cache — <b>c'est ce chemin que mesure le test de
     * cout</b> : compter les requetes derriere un cache ne prouverait rien.
     */
    AdminAnalyticsResponse compute(FenetreMesure fenetre, AnalyticsReadManager.Filtres filtres) {
        int jours = fenetre.days();
        AnalyticsGrain grain = AnalyticsGrain.pour(jours);

        // Periode precedente : meme duree, COLLEE a `from` (elle finit la veille).
        FenetreMesure precedente = new FenetreMesure(
                fenetre.from().minusDays(jours), fenetre.from().minusDays(1));

        List<String> exclus = properties.getExcludedEmails();

        Map<Cle, Agg> courant = collecte(fenetre, grain, filtres, exclus);
        Map<Cle, Agg> ancien = collecte(precedente, grain, filtres, exclus);

        AdminAnalyticsResponse.Metrics total = metrics(courant, "TOTAL", "ALL");
        AdminAnalyticsResponse.Metrics prev = metrics(ancien, "TOTAL", "ALL");

        List<AdminAnalyticsResponse.SourceRow> sources = sources(courant);
        List<AdminAnalyticsResponse.AbandonRow> abandon = abandon(total);

        LocalDate aujourdHui = LocalDate.now(FenetreMesure.PARIS);

        return new AdminAnalyticsResponse(
                periode(fenetre, jours, grain, aujourdHui),
                fenetre.from().toString(), fenetre.to().toString(),
                precedente.from().toString(), precedente.to().toString(),
                !fenetre.to().isBefore(aujourdHui),
                LocalTime.now(FenetreMesure.PARIS).getHour(),
                manager.totalUsers(exclus),
                DEVISE,
                total, prev,
                sources, sources(ancien),
                series(fenetre, grain, courant), series(precedente, grain, ancien),
                funnel(total), funnel(prev),
                countries(courant), devices(courant), campaigns(courant),
                ctas(fenetre, filtres, exclus),
                triggers(fenetre, filtres),
                paths(fenetre, filtres),
                diagTypes(fenetre, filtres, exclus),
                abandon,
                annotations(fenetre),
                insightsBuilder.build(total, prev, sources, abandon));
    }

    // ------------------------------------------------------------------------
    // Collecte : deux requetes, toutes les ventilations
    // ------------------------------------------------------------------------

    private Map<Cle, Agg> collecte(FenetreMesure fenetre, AnalyticsGrain grain,
                                   AnalyticsReadManager.Filtres filtres, List<String> exclus) {
        Instant from = fenetre.startInstant();
        Instant to = fenetre.endInstantExclusive();
        Map<Cle, Agg> aggs = new LinkedHashMap<>();

        for (AnalyticsReadRepository.VisitorCell cell
                : manager.visitorCells(from, to, grain, filtres)) {
            Agg agg = slot(aggs, cell.getDim(), cell.getDimKey(), cell.getDimKey2());
            long n = cell.getN();
            switch (cell.getMetric()) {
                case "VISITEUR" -> agg.v = n;
                case "DIAGNOSTIC_CTA_CLICKED" -> agg.cta = n;
                case "CIVIQUE_CTA_CLICKED" -> agg.civique = n;
                case "DIAGNOSTIC_STARTED" -> agg.start = n;
                case "DIAGNOSTIC_EE_STARTED" -> agg.ee1 = n;
                case "DIAGNOSTIC_EE_COMPLETED" -> agg.ee2 = n;
                case "DIAGNOSTIC_EO_STARTED" -> agg.eo1 = n;
                case "DIAGNOSTIC_EO_COMPLETED" -> agg.eo2 = n;
                case "DIAGNOSTIC_ACCOUNT_REQUIRED" -> agg.account = n;
                case "DIAGNOSTIC_REPORT_VIEWED" -> agg.rep = n;
                case "PREMIUM_CTA_CLICKED" -> agg.prem = n;
                // CO/CE terminees ne sont pas dans le vecteur : elles ne servent
                // que les chaines de diagnostic. Une metrique inconnue est
                // ignoree, jamais rangee ailleurs « au cas ou ».
                default -> { }
            }
        }
        for (AnalyticsReadRepository.UserCell cell
                : manager.userCells(from, to, grain, exclus, filtres)) {
            Agg agg = slot(aggs, cell.getDim(), cell.getDimKey(), cell.getDimKey2());
            agg.sig = cell.getSig();
            agg.pay = cell.getPay();
            agg.ck = cell.getCk();
            agg.rev = cell.getRev();
        }
        return aggs;
    }

    private static Agg slot(Map<Cle, Agg> aggs, String dim, String key, String key2) {
        return aggs.computeIfAbsent(
                new Cle(dim, key == null ? "" : key, key2 == null ? "" : key2), k -> new Agg());
    }

    private static AdminAnalyticsResponse.Metrics metrics(Map<Cle, Agg> aggs,
                                                          String dim, String key) {
        Agg agg = aggs.get(new Cle(dim, key, ""));
        return agg == null ? AdminAnalyticsResponse.Metrics.ZERO : agg.toMetrics();
    }

    // ------------------------------------------------------------------------
    // Ventilations
    // ------------------------------------------------------------------------

    private static List<AdminAnalyticsResponse.SourceRow> sources(Map<Cle, Agg> aggs) {
        List<AdminAnalyticsResponse.SourceRow> rows = new ArrayList<>();
        aggs.forEach((cle, agg) -> {
            if (!"SOURCE".equals(cle.dim())) return;
            rows.add(new AdminAnalyticsResponse.SourceRow(
                    cle.k(), AnalyticsLibelles.source(cle.k()), agg.toMetrics()));
        });
        rows.sort(AnalyticsInsightsBuilder.CLASSEMENT);
        return List.copyOf(rows);
    }

    private static List<AdminAnalyticsResponse.CountryRow> countries(Map<Cle, Agg> aggs) {
        List<AdminAnalyticsResponse.CountryRow> rows = new ArrayList<>();
        aggs.forEach((cle, agg) -> {
            if (!"COUNTRY".equals(cle.dim())) return;
            rows.add(new AdminAnalyticsResponse.CountryRow(
                    cle.k(), AnalyticsLibelles.pays(cle.k()),
                    agg.v, agg.sig, agg.rep, agg.prem, agg.pay, agg.rev));
        });
        rows.sort(Comparator.comparingLong(AdminAnalyticsResponse.CountryRow::v).reversed()
                .thenComparing(AdminAnalyticsResponse.CountryRow::id));
        return List.copyOf(rows);
    }

    private static List<AdminAnalyticsResponse.DeviceRow> devices(Map<Cle, Agg> aggs) {
        List<AdminAnalyticsResponse.DeviceRow> rows = new ArrayList<>();
        aggs.forEach((cle, agg) -> {
            if (!"DEVICE".equals(cle.dim())) return;
            rows.add(new AdminAnalyticsResponse.DeviceRow(
                    cle.k(), AnalyticsLibelles.appareil(cle.k()),
                    AnalyticsLibelles.plateforme(cle.k2()),
                    agg.v, agg.sig, agg.rep, agg.prem, agg.pay, agg.rev));
        });
        rows.sort(Comparator.comparingLong(AdminAnalyticsResponse.DeviceRow::v).reversed()
                .thenComparing(AdminAnalyticsResponse.DeviceRow::id));
        return List.copyOf(rows);
    }

    /**
     * Une ligne par (provenance, campagne, medium, contenu). {@code utm_content}
     * fait partie de la cle : c'est lui qui distingue deux videos d'une meme
     * campagne, et les fondre effacerait la seule comparaison utile.
     */
    private static List<AdminAnalyticsResponse.CampaignRow> campaigns(Map<Cle, Agg> aggs) {
        List<AdminAnalyticsResponse.CampaignRow> rows = new ArrayList<>();
        aggs.forEach((cle, agg) -> {
            if (!"CAMPAIGN".equals(cle.dim())) return;
            String[] parts = cle.k().split(SEP, -1);
            String source = parts.length > 0 ? parts[0] : "";
            String name = parts.length > 1 ? parts[1] : "";
            String medium = parts.length > 2 ? vide(parts[2]) : null;
            String content = parts.length > 3 ? vide(parts[3]) : null;
            rows.add(new AdminAnalyticsResponse.CampaignRow(
                    cle.k(), AnalyticsLibelles.source(source), source, name, medium, content,
                    agg.v, agg.start, agg.rep, agg.sig, agg.prem, agg.pay, agg.rev));
        });
        rows.sort(Comparator.comparingLong(AdminAnalyticsResponse.CampaignRow::v).reversed()
                .thenComparing(AdminAnalyticsResponse.CampaignRow::id));
        return List.copyOf(rows);
    }

    // ------------------------------------------------------------------------
    // Serie temporelle
    // ------------------------------------------------------------------------

    /**
     * Un point par seau de la fenetre, <b>zeros compris</b>.
     *
     * <p>Un trou dans une courbe se lit comme une absence de mesure, pas comme
     * une absence de visite — c'est au serveur de trancher, pas au front (acquis
     * de {@code PageViewStatsResponse}).
     *
     * <p>⚠️ La somme des points n'egale pas {@code total} pour les metriques
     * d'acteurs uniques, et c'est normal : un visiteur actif deux jours compte
     * dans deux barres. Aucune courbe d'uniques n'est additive ; l'aplatir
     * donnerait « nouveaux visiteurs par jour », ce que la courbe ne dit pas.
     */
    private static List<AdminAnalyticsResponse.SeriesPoint> series(
            FenetreMesure fenetre, AnalyticsGrain grain, Map<Cle, Agg> aggs) {

        Map<String, Agg> parSeau = new LinkedHashMap<>();
        aggs.forEach((cle, agg) -> {
            if ("BUCKET".equals(cle.dim())) parSeau.put(cle.k(), agg);
        });

        List<AdminAnalyticsResponse.SeriesPoint> points = new ArrayList<>();
        for (LocalDateTime debut : seaux(fenetre, grain)) {
            LocalDateTime fin = suivant(debut, grain);
            Agg agg = parSeau.get(debut.format(CLE_SEAU));
            AdminAnalyticsResponse.Metrics m =
                    agg == null ? AdminAnalyticsResponse.Metrics.ZERO : agg.toMetrics();
            points.add(new AdminAnalyticsResponse.SeriesPoint(
                    libelleSeau(debut, grain), libelleCourtSeau(debut, grain),
                    debut.toString(), fin.toString(), m, agg == null));
        }
        return List.copyOf(points);
    }

    private static List<LocalDateTime> seaux(FenetreMesure fenetre, AnalyticsGrain grain) {
        LocalDateTime debut = switch (grain) {
            case HOUR, DAY -> fenetre.from().atStartOfDay();
            // date_trunc('week') tombe sur le lundi : le premier seau demarre
            // donc AVANT `from` quand la fenetre ne commence pas un lundi. Le
            // suivre est la seule facon de retrouver les cles rendues par SQL.
            case WEEK -> fenetre.from()
                    .with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY)).atStartOfDay();
        };
        LocalDateTime fin = fenetre.to().plusDays(1).atStartOfDay();
        List<LocalDateTime> seaux = new ArrayList<>();
        for (LocalDateTime courant = debut; courant.isBefore(fin);
             courant = suivant(courant, grain)) {
            seaux.add(courant);
        }
        return seaux;
    }

    private static LocalDateTime suivant(LocalDateTime debut, AnalyticsGrain grain) {
        return switch (grain) {
            case HOUR -> debut.plusHours(1);
            case DAY -> debut.plusDays(1);
            case WEEK -> debut.plusWeeks(1);
        };
    }

    private static String libelleSeau(LocalDateTime debut, AnalyticsGrain grain) {
        return switch (grain) {
            case HOUR -> debut.format(LIBELLE_HEURE);
            case DAY -> debut.format(LIBELLE_JOUR);
            case WEEK -> "semaine du " + debut.toLocalDate().format(LIBELLE_DATE);
        };
    }

    private static String libelleCourtSeau(LocalDateTime debut, AnalyticsGrain grain) {
        return grain == AnalyticsGrain.HOUR
                ? debut.format(LIBELLE_COURT_HEURE)
                : debut.format(LIBELLE_COURT_JOUR);
    }

    // ------------------------------------------------------------------------
    // Entonnoir et abandons
    // ------------------------------------------------------------------------

    /**
     * L'entonnoir principal (brief §36), <b>lu sur le meme vecteur que tout le
     * reste</b> : une marche ne peut donc pas contredire le KPI qui la resume.
     *
     * <p>⚠️ Il melange volontairement deux populations : les cinq premieres
     * marches comptent des <b>visiteurs</b>, les trois dernieres des
     * <b>comptes</b> (la ou vivent les faits autoritatifs). Une conversion
     * « rapport → inscription » traverse donc cette frontiere, et c'est
     * inevitable : l'inscription n'existe pas cote visiteur, elle existe dans
     * {@code users}.
     */
    private static List<AdminAnalyticsResponse.FunnelStep> funnel(
            AdminAnalyticsResponse.Metrics m) {

        record Marche(String k, String label, String q, long value) { }
        List<Marche> marches = List.of(
                new Marche("v", "Visiteurs", "Visiteurs uniques sur la période.", m.v()),
                new Marche("cta", "Clic diagnostic",
                        "Ont cliqué « Faire mon diagnostic ».", m.cta()),
                new Marche("start", "Diagnostic commencé",
                        "Sont entrés dans le parcours.", m.start()),
                new Marche("ee2", "Écrit terminé", "Ont rendu leur production écrite.", m.ee2()),
                new Marche("eo2", "Oral terminé", "Ont rendu leur production orale.", m.eo2()),
                new Marche("rep", "Rapport affiché", "Ont vu leur niveau estimé.", m.rep()),
                new Marche("sig", "Inscrits", "Comptes créés (source : users).", m.sig()),
                new Marche("prem", "Clic Premium",
                        "Cliqueurs uniques sur un CTA d'achat.", m.prem()),
                new Marche("ck", "Paiement lancé", "Ont ouvert une session de paiement.", m.ck()),
                new Marche("pay", "Payants", "Comptes ayant réellement payé.", m.pay()));

        List<AdminAnalyticsResponse.FunnelStep> steps = new ArrayList<>();
        Long precedent = null;
        for (Marche marche : marches) {
            // La premiere marche n'a rien avant elle : sa conversion est une
            // INCONNUE (donc null), mais sa perte vaut bel et bien zero — rien
            // ne peut se perdre avant le debut.
            Double conv = precedent == null ? null
                    : AnalyticsCalculs.taux(marche.value(), precedent);
            long perdus = precedent == null ? 0 : Math.max(0, precedent - marche.value());
            Double part = precedent == null ? null : AnalyticsCalculs.taux(perdus, precedent);
            steps.add(new AdminAnalyticsResponse.FunnelStep(
                    marche.k(), marche.label(), marche.q(), marche.value(),
                    conv, perdus, part == null ? 0d : part));
            precedent = marche.value();
        }
        return List.copyOf(steps);
    }

    /**
     * Ou le diagnostic perd du monde (brief §39).
     *
     * <p>La marche « la pire » n'est designee qu'a partir de
     * {@link AnalyticsInsightsBuilder#MIN_SIGNUPS_POUR_DESIGNER_UNE_FUITE}
     * diagnostics commences : en dessous, un candidat de plus renverse le
     * classement, et designer une etape serait une conclusion tiree du hasard.
     * Les chiffres, eux, restent tous servis — on masque une conclusion, jamais
     * une donnee.
     */
    private static List<AdminAnalyticsResponse.AbandonRow> abandon(
            AdminAnalyticsResponse.Metrics m) {

        record Marche(String id, String label, String sub, String baseKey,
                      long base, long reste) { }
        List<Marche> marches = List.of(
                new Marche("BEFORE_EE", "Avant l'écrit",
                        "Le parcours est commencé, la première production ne l'est pas.",
                        "start", m.start(), m.ee1()),
                new Marche("DURING_EE", "Pendant l'écrit",
                        "L'écrit est commencé mais jamais rendu.", "ee1", m.ee1(), m.ee2()),
                new Marche("BEFORE_EO", "Entre l'écrit et l'oral",
                        "L'écrit est rendu, l'oral n'est jamais lancé.", "ee2", m.ee2(), m.eo1()),
                new Marche("DURING_EO", "Pendant l'oral",
                        "L'oral est commencé mais jamais rendu.", "eo1", m.eo1(), m.eo2()),
                new Marche("BEFORE_REPORT", "Avant le rapport",
                        "Les deux productions sont faites, le rapport n'est pas ouvert.",
                        "eo2", m.eo2(), m.rep()));

        long pire = 0;
        for (Marche marche : marches) pire = Math.max(pire, perte(marche.base(), marche.reste()));
        boolean designable = m.start() >= AnalyticsInsightsBuilder.MIN_SIGNUPS_POUR_DESIGNER_UNE_FUITE
                && pire > 0;

        List<AdminAnalyticsResponse.AbandonRow> rows = new ArrayList<>();
        boolean pireDejaMarquee = false;
        for (Marche marche : marches) {
            long perdus = perte(marche.base(), marche.reste());
            boolean worst = designable && !pireDejaMarquee && perdus == pire;
            if (worst) pireDejaMarquee = true;
            rows.add(new AdminAnalyticsResponse.AbandonRow(
                    marche.id(), marche.label(), marche.sub(), perdus, marche.baseKey(), worst));
        }
        return List.copyOf(rows);
    }

    private static long perte(long base, long reste) {
        return Math.max(0, base - reste);
    }

    // ------------------------------------------------------------------------
    // CTA, contextes, parcours, formats de diagnostic
    // ------------------------------------------------------------------------

    private List<AdminAnalyticsResponse.CtaRow> ctas(
            FenetreMesure fenetre, AnalyticsReadManager.Filtres filtres, List<String> exclus) {

        Map<String, long[]> parEmplacement = new LinkedHashMap<>();
        for (AnalyticsReadRepository.CtaCell cell : manager.ctaCells(
                fenetre.startInstant(), fenetre.endInstantExclusive(), exclus, filtres)) {
            long[] bucket = parEmplacement.computeIfAbsent(cell.getLoc(), k -> new long[4]);
            bucket[0] += cell.getPrem();
            bucket[1] += cell.getCk();
            bucket[2] += cell.getPay();
            bucket[3] += cell.getRev();
        }
        List<AdminAnalyticsResponse.CtaRow> rows = new ArrayList<>();
        parEmplacement.forEach((loc, b) -> rows.add(new AdminAnalyticsResponse.CtaRow(
                loc, libelleCta(loc), loc, b[0], b[1], b[2], b[3])));
        rows.sort(Comparator.comparingLong(AdminAnalyticsResponse.CtaRow::prem).reversed()
                .thenComparing(AdminAnalyticsResponse.CtaRow::id));
        return List.copyOf(rows);
    }

    private static String libelleCta(String code) {
        for (AnalyticsCtaLocation location : AnalyticsCtaLocation.values()) {
            if (location.name().equals(code)) return location.getLabel();
        }
        return AnalyticsCtaLocation.OTHER.getLabel();
    }

    /**
     * Ou l'inscription se declenche dans le parcours (brief §47).
     *
     * <p>Les parts sont arrondies <b>a somme conservee</b> : trois lignes a un
     * tiers affichent 34/33/33, jamais 33/33/33 avec un pied a 99 % qui ferait
     * douter du tableau entier.
     */
    private List<AdminAnalyticsResponse.TriggerRow> triggers(
            FenetreMesure fenetre, AnalyticsReadManager.Filtres filtres) {

        List<AnalyticsReadRepository.TriggerCell> cells = manager.registrationTriggers(
                fenetre.startInstant(), fenetre.endInstantExclusive(), filtres);
        List<AnalyticsReadRepository.TriggerCell> triees = new ArrayList<>(cells);
        triees.sort(Comparator.comparingLong(AnalyticsReadRepository.TriggerCell::getN).reversed()
                .thenComparing(AnalyticsReadRepository.TriggerCell::getContexte));

        long[] poids = triees.stream().mapToLong(AnalyticsReadRepository.TriggerCell::getN).toArray();
        int[] parts = RepartitionArrondie.pourcentages(poids);

        List<AdminAnalyticsResponse.TriggerRow> rows = new ArrayList<>();
        for (int i = 0; i < triees.size(); i++) {
            String code = triees.get(i).getContexte();
            rows.add(new AdminAnalyticsResponse.TriggerRow(
                    code, AnalyticsLibelles.contexte(code), AnalyticsLibelles.indiceContexte(code),
                    triees.get(i).getN(), parts[i]));
        }
        return List.copyOf(rows);
    }

    /** Les cinq parcours les plus frequents, provenance en tete. */
    private List<AdminAnalyticsResponse.PathRow> paths(
            FenetreMesure fenetre, AnalyticsReadManager.Filtres filtres) {

        List<AnalyticsReadRepository.PathCell> cells = manager.topPaths(
                fenetre.startInstant(), fenetre.endInstantExclusive(), filtres);
        long[] poids = cells.stream().mapToLong(AnalyticsReadRepository.PathCell::getN).toArray();
        int[] parts = RepartitionArrondie.pourcentages(poids);

        List<AdminAnalyticsResponse.PathRow> rows = new ArrayList<>();
        for (int i = 0; i < cells.size(); i++) {
            List<String> chaine = new ArrayList<>();
            chaine.add(AnalyticsLibelles.source(cells.get(i).getSource()));
            for (String jalon : cells.get(i).getChain().split(">")) {
                chaine.add(libelleJalon(jalon));
            }
            rows.add(new AdminAnalyticsResponse.PathRow(
                    List.copyOf(chaine), cells.get(i).getN(), parts[i]));
        }
        return List.copyOf(rows);
    }

    private static String libelleJalon(String jalon) {
        return switch (jalon) {
            case "LANDING" -> "Landing";
            case "SIGNUP" -> "Inscription";
            case "DIAGNOSTIC_RAPID" -> "Diagnostic rapide";
            case "DIAGNOSTIC_COMPLETE" -> "Diagnostic complet";
            case "REPORT" -> "Rapport";
            case "PREMIUM_CLICK" -> "Clic Premium";
            default -> jalon;
        };
    }

    /**
     * La progression <b>reelle</b> de chaque format.
     *
     * <p>🛑 La maquette dessine ces chaines avec des ratios ecrits en dur
     * (0,74 / 0,58 / 0,55) ; on sert les vrais. Et un maillon dont aucun
     * evenement n'existe <b>n'est pas servi</b> : un zero se lirait « tout le
     * monde abandonne ici », alors qu'on ne mesure simplement pas encore cette
     * etape. C'est le cas de {@code CO} et {@code CE} tant que les fronts
     * n'emettent que leurs {@code _STARTED} — le runner QCM ignore pourquoi il
     * s'ouvre.
     *
     * <p>Un format dont on ne sait rien rend une chaine <b>vide</b>, pas une
     * chaine de zeros.
     */
    private List<AdminAnalyticsResponse.DiagTypeRow> diagTypes(
            FenetreMesure fenetre, AnalyticsReadManager.Filtres filtres, List<String> exclus) {

        Map<String, Map<String, Long>> parType = new LinkedHashMap<>();
        for (AnalyticsReadRepository.DiagStepCell cell : manager.diagnosticSteps(
                fenetre.startInstant(), fenetre.endInstantExclusive(), exclus, filtres)) {
            parType.computeIfAbsent(cell.getDiagType(), k -> new LinkedHashMap<>())
                    .merge(cell.getStep(), cell.getN(), Long::sum);
        }

        List<String> formats = new ArrayList<>(List.of("RAPID", "COMPLETE"));
        parType.keySet().stream().filter(t -> !formats.contains(t)).sorted().forEach(formats::add);

        List<AdminAnalyticsResponse.DiagTypeRow> rows = new ArrayList<>();
        for (String format : formats) {
            Map<String, Long> steps = parType.getOrDefault(format, Map.of());
            long start = steps.getOrDefault("START", 0L);
            long done = steps.getOrDefault("DIAGNOSTIC_REPORT_VIEWED", 0L);
            long prem = steps.getOrDefault("PREMIUM_CTA_CLICKED", 0L);
            long pay = steps.getOrDefault("PAY", 0L);

            List<AdminAnalyticsResponse.ChainLink> chain =
                    start == 0 ? List.of() : chaine(format, steps, start);
            rows.add(new AdminAnalyticsResponse.DiagTypeRow(
                    format, AnalyticsLibelles.diagnostic(format),
                    AnalyticsLibelles.sousTitreDiagnostic(format),
                    start, done, prem, pay, chain.size(), chain));
        }
        return List.copyOf(rows);
    }

    private static List<AdminAnalyticsResponse.ChainLink> chaine(
            String format, Map<String, Long> steps, long start) {

        record Maillon(String k, String label, String event) { }
        List<Maillon> maillons = new ArrayList<>(List.of(
                new Maillon("ee2", "Écrit rendu", "DIAGNOSTIC_EE_COMPLETED"),
                new Maillon("eo2", "Oral rendu", "DIAGNOSTIC_EO_COMPLETED")));
        if ("COMPLETE".equals(format)) {
            maillons.add(new Maillon("co2", "Compréhension orale", "DIAGNOSTIC_CO_COMPLETED"));
            maillons.add(new Maillon("ce2", "Compréhension écrite", "DIAGNOSTIC_CE_COMPLETED"));
        }
        maillons.add(new Maillon("rep", "Rapport affiché", "DIAGNOSTIC_REPORT_VIEWED"));

        List<AdminAnalyticsResponse.ChainLink> chain = new ArrayList<>();
        chain.add(new AdminAnalyticsResponse.ChainLink("start", "Commencé", start, null));
        Long precedent = start;
        for (Maillon maillon : maillons) {
            // 🛑 Aucun evenement de cette nature : le maillon est servi a `null`,
            // JAMAIS a zero. « Personne n'est arrive ici » et « on ne mesure pas
            // encore cette etape » se ressemblent a l'ecran et ne veulent pas
            // dire la meme chose — un zero se lirait « tout le monde abandonne ».
            Long valeur = steps.get(maillon.event());
            Double conv = (valeur == null || precedent == null) ? null
                    : AnalyticsCalculs.taux(valeur, precedent);
            chain.add(new AdminAnalyticsResponse.ChainLink(
                    maillon.k(), maillon.label(), valeur, conv));
            precedent = valeur;
        }
        return List.copyOf(chain);
    }

    private List<AdminAnalyticsResponse.AnnotationPoint> annotations(FenetreMesure fenetre) {
        List<AnalyticsAnnotationDto> reperes =
                annotationService.between(fenetre.from(), fenetre.to());
        return reperes.stream()
                .map(a -> new AdminAnalyticsResponse.AnnotationPoint(
                        a.occurredOn().toString(), a.title(), a.category().name()))
                .toList();
    }

    // ------------------------------------------------------------------------
    // Periode
    // ------------------------------------------------------------------------

    private static AdminAnalyticsResponse.Period periode(
            FenetreMesure fenetre, int jours, AnalyticsGrain grain, LocalDate aujourdHui) {

        boolean glissante = fenetre.to().equals(aujourdHui);
        String id;
        String label;
        if (glissante && jours == 1) {
            id = "today";
            label = "Aujourd'hui";
        } else if (glissante) {
            id = "d" + jours;
            label = jours + " derniers jours";
        } else if (jours == 1) {
            id = "custom";
            label = "Le " + fenetre.from().format(LIBELLE_DATE);
        } else {
            id = "custom";
            label = "Du " + fenetre.from().format(LIBELLE_DATE)
                    + " au " + fenetre.to().format(LIBELLE_DATE);
        }
        return new AdminAnalyticsResponse.Period(id, label, jours, grain.name());
    }

    private static String vide(String raw) {
        return raw == null || raw.isBlank() ? null : raw;
    }

    // ------------------------------------------------------------------------

    /** Coordonnee d'une cellule de ventilation. */
    private record Cle(String dim, String k, String k2) {
    }

    /** Accumulateur du vecteur de mesure, le temps de la lecture. */
    private static final class Agg {
        private long v;
        private long cta;
        private long civique;
        private long start;
        private long ee1;
        private long ee2;
        private long eo1;
        private long eo2;
        private long account;
        private long rep;
        private long sig;
        private long prem;
        private long ck;
        private long pay;
        private long rev;

        AdminAnalyticsResponse.Metrics toMetrics() {
            return new AdminAnalyticsResponse.Metrics(
                    v, cta, civique, start, ee1, ee2, eo1, eo2, account, rep, sig, prem, ck, pay,
                    rev);
        }
    }
}
