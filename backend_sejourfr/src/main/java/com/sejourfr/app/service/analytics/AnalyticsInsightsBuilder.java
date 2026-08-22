package com.sejourfr.app.service.analytics;

import com.sejourfr.app.dto.AdminAnalyticsResponse;
import com.sejourfr.app.util.TrafficSource;
import org.springframework.stereotype.Component;

import java.text.NumberFormat;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;

/**
 * Lecture <b>deterministe</b> de la periode, sans LLM (brief §56).
 *
 * <p><b>Les trois seuils d'honnetete sont le coeur du fichier.</b> Ils viennent
 * de l'ancien {@code admin/features/audience/insights.ts}, supprime avec la
 * feature qu'il servait ; les valeurs sont reprises telles quelles, le calcul
 * passe au serveur. Sur un petit volume, « TikTok convertit le mieux » n'est pas
 * une observation, c'est du bruit : un seul paiement de plus renverse le
 * classement. Sous le seuil, on <b>enonce les chiffres et on dit pourquoi on
 * s'arrete la</b> — on masque une conclusion, jamais une donnee.
 *
 * <p>🛑 <b>Le classement des sources trie les PAYANTS d'abord, le taux
 * ensuite.</b> Trier sur le taux seul hisserait en tete une provenance a
 * 1 inscrit et 1 payant (100 %), qui n'a rien demontre. {@code inconnu} reste
 * toujours en dernier : ce n'est pas un canal sur lequel on peut investir.
 *
 * <p>Le HTML emis n'admet que {@code <b> <strong> <em> <i>}. La console le passe
 * deja par un assainisseur, mais on ne s'en remet pas a lui : on n'emet rien
 * d'autre, et c'est ce qui rend la regle vraie par construction.
 */
@Component
public class AnalyticsInsightsBuilder {

    /** En dessous, aucune marche du parcours n'est designee comme « celle qui fuit ». */
    public static final int MIN_SIGNUPS_POUR_DESIGNER_UNE_FUITE = 10;

    /** En dessous, aucune provenance n'est designee comme « celle qui convertit le mieux ». */
    public static final int MIN_SIGNUPS_POUR_COMPARER_LES_RESEAUX = 20;

    /** Une provenance ne se compare pas a 3 inscrits, meme si le total est eleve. */
    public static final int MIN_SIGNUPS_PAR_RESEAU = 5;

    /** Au plus 4 lectures : au-dela, plus personne ne les lit (brief §56). */
    public static final int MAX_INSIGHTS = 4;

    private static final String OK = "OK";
    private static final String WARN = "WARN";
    private static final String BAD = "BAD";
    private static final String NEUTRAL = "NEUTRAL";

    /**
     * Classement affiche : payants d'abord, taux ensuite, {@code inconnu}
     * toujours dernier. Deterministe jusqu'au bout (le code de la provenance
     * departage), donc reproductible d'un appel a l'autre.
     */
    public static final Comparator<AdminAnalyticsResponse.SourceRow> CLASSEMENT =
            (a, b) -> {
                boolean aInconnu = TrafficSource.UNKNOWN.equals(a.id());
                boolean bInconnu = TrafficSource.UNKNOWN.equals(b.id());
                if (aInconnu != bInconnu) return aInconnu ? 1 : -1;
                int parPayants = Long.compare(b.m().pay(), a.m().pay());
                if (parPayants != 0) return parPayants;
                double tauxA = taux(a);
                double tauxB = taux(b);
                if (Double.compare(tauxB, tauxA) != 0) return Double.compare(tauxB, tauxA);
                int parInscrits = Long.compare(b.m().sig(), a.m().sig());
                if (parInscrits != 0) return parInscrits;
                return a.id().compareTo(b.id());
            };

    /**
     * Construit au plus {@link #MAX_INSIGHTS} lectures.
     *
     * @param total    le vecteur de la periode
     * @param prev     le meme vecteur, periode precedente
     * @param sources  ventilation par provenance, deja calculee
     * @param abandon  les pertes du diagnostic, deja calculees
     */
    public List<AdminAnalyticsResponse.Insight> build(
            AdminAnalyticsResponse.Metrics total,
            AdminAnalyticsResponse.Metrics prev,
            List<AdminAnalyticsResponse.SourceRow> sources,
            List<AdminAnalyticsResponse.AbandonRow> abandon) {

        List<AdminAnalyticsResponse.Insight> insights = new ArrayList<>();
        insights.add(bilan(total));
        insights.add(fuite(total, abandon));
        AdminAnalyticsResponse.Insight reseaux = reseaux(total, sources);
        if (reseaux != null) insights.add(reseaux);
        AdminAnalyticsResponse.Insight tendance = tendance(total, prev);
        if (tendance != null) insights.add(tendance);
        return insights.size() > MAX_INSIGHTS ? insights.subList(0, MAX_INSIGHTS) : insights;
    }

    // ------------------------------------------------------------------------

    /** Le fait brut, toujours servi : il ne conclut rien, donc aucun seuil ne le garde. */
    private AdminAnalyticsResponse.Insight bilan(AdminAnalyticsResponse.Metrics m) {
        if (m.v() == 0 && m.sig() == 0) {
            return new AdminAnalyticsResponse.Insight(NEUTRAL,
                    "Aucune visite mesurée sur cette période.");
        }
        String debut = nombre(m.v()) + " " + pluriel(m.v(), "visiteur", "visiteurs")
                + " et <b>" + nombre(m.sig()) + "</b> "
                + pluriel(m.sig(), "inscrit", "inscrits");
        if (m.pay() == 0) {
            return new AdminAnalyticsResponse.Insight(NEUTRAL, debut + ", aucun paiement.");
        }
        Double conversion = AnalyticsCalculs.taux(m.pay(), m.sig());
        return new AdminAnalyticsResponse.Insight(OK,
                debut + ", dont <b>" + nombre(m.pay()) + "</b> "
                        + pluriel(m.pay(), "payant", "payants")
                        + (conversion == null ? "" : " (" + pourcent(conversion) + ")") + ".");
    }

    /**
     * La marche qui perd le plus. Sous {@link #MIN_SIGNUPS_POUR_DESIGNER_UNE_FUITE}
     * diagnostics commences, on ne designe rien : l'ecart tiendrait au hasard.
     */
    private AdminAnalyticsResponse.Insight fuite(
            AdminAnalyticsResponse.Metrics total, List<AdminAnalyticsResponse.AbandonRow> abandon) {

        if (total.start() < MIN_SIGNUPS_POUR_DESIGNER_UNE_FUITE) {
            return new AdminAnalyticsResponse.Insight(NEUTRAL,
                    "Sous " + MIN_SIGNUPS_POUR_DESIGNER_UNE_FUITE
                            + " diagnostics commencés, aucune étape n'est désignée comme "
                            + "celle qui fuit : l'écart tiendrait au hasard.");
        }
        AdminAnalyticsResponse.AbandonRow pire = abandon.stream()
                .filter(AdminAnalyticsResponse.AbandonRow::worst)
                .findFirst().orElse(null);
        if (pire == null || pire.v() == 0) {
            return new AdminAnalyticsResponse.Insight(OK,
                    "Aucune étape du diagnostic ne perd de candidat.");
        }
        // `base` est une CLE de metrique, pas un nombre : le denominateur vit
        // dans le vecteur, et le publier deux fois ouvrirait la porte a ce que
        // les deux divergent.
        Double part = AnalyticsCalculs.taux(pire.v(), valeur(total, pire.base()));
        return new AdminAnalyticsResponse.Insight(BAD,
                "La plus grosse perte du diagnostic est <b>" + echappe(pire.label()) + "</b> : −"
                        + nombre(pire.v()) + " " + pluriel(pire.v(), "candidat", "candidats")
                        + (part == null ? "" : " (" + pourcent(part) + " de cette étape)") + ".");
    }

    /**
     * La provenance qui convertit le mieux — ou la raison de ne pas la nommer.
     *
     * <p>Deux seuils s'appliquent ensemble : assez d'inscrits <b>sur la
     * periode</b>, et assez d'inscrits <b>sur cette provenance-la</b>. Le second
     * est indispensable : un total eleve n'empeche pas un reseau d'y peser
     * trois comptes.
     */
    private AdminAnalyticsResponse.Insight reseaux(
            AdminAnalyticsResponse.Metrics total, List<AdminAnalyticsResponse.SourceRow> sources) {

        if (total.sig() < MIN_SIGNUPS_POUR_COMPARER_LES_RESEAUX) {
            return new AdminAnalyticsResponse.Insight(NEUTRAL,
                    "Il faut au moins " + MIN_SIGNUPS_POUR_COMPARER_LES_RESEAUX
                            + " inscrits pour comparer les provenances : le classement reste "
                            + "affiché, il ne conclut rien.");
        }
        AdminAnalyticsResponse.SourceRow meilleure = sources.stream()
                .filter(s -> !TrafficSource.UNKNOWN.equals(s.id()))
                .filter(s -> s.m().sig() >= MIN_SIGNUPS_PAR_RESEAU)
                .filter(s -> s.m().pay() > 0)
                .max(Comparator.comparingDouble(AnalyticsInsightsBuilder::taux))
                .orElse(null);
        if (meilleure == null) {
            return new AdminAnalyticsResponse.Insight(NEUTRAL,
                    "Aucune provenance n'atteint " + MIN_SIGNUPS_PAR_RESEAU
                            + " inscrits avec au moins un paiement : rien à départager.");
        }
        Double conversion = AnalyticsCalculs.taux(meilleure.m().pay(), meilleure.m().sig());
        return new AdminAnalyticsResponse.Insight(OK,
                "<b>" + echappe(meilleure.label()) + "</b> convertit le mieux : "
                        + nombre(meilleure.m().pay()) + " "
                        + pluriel(meilleure.m().pay(), "payant", "payants") + " sur "
                        + nombre(meilleure.m().sig()) + " "
                        + pluriel(meilleure.m().sig(), "inscrit", "inscrits")
                        + (conversion == null ? "" : " (" + pourcent(conversion) + ")") + ".");
    }

    /**
     * L'ecart avec la periode precedente, <b>seulement s'il y a de quoi
     * comparer</b> : une periode precedente vide ne produit pas « +100 % », elle
     * ne produit rien.
     */
    private AdminAnalyticsResponse.Insight tendance(
            AdminAnalyticsResponse.Metrics total, AdminAnalyticsResponse.Metrics prev) {

        Double ecart = AnalyticsCalculs.delta(total.sig(), prev.sig());
        if (ecart == null || prev.sig() < MIN_SIGNUPS_POUR_DESIGNER_UNE_FUITE) return null;
        if (Math.abs(ecart) < 0.05) {
            return new AdminAnalyticsResponse.Insight(NEUTRAL,
                    "Les inscriptions sont stables par rapport à la période précédente ("
                            + nombre(prev.sig()) + ").");
        }
        boolean hausse = ecart > 0;
        return new AdminAnalyticsResponse.Insight(hausse ? OK : WARN,
                "Les inscriptions sont " + (hausse ? "en hausse de <b>" : "en baisse de <b>")
                        + pourcent(Math.abs(ecart)) + "</b> par rapport à la période précédente ("
                        + nombre(prev.sig()) + ").");
    }

    // ------------------------------------------------------------------------

    /** Le denominateur d'une marche d'abandon, lu sur le vecteur qui fait foi. */
    private static long valeur(AdminAnalyticsResponse.Metrics m, String cle) {
        return switch (cle) {
            case "v" -> m.v();
            case "start" -> m.start();
            case "ee1" -> m.ee1();
            case "ee2" -> m.ee2();
            case "eo1" -> m.eo1();
            case "eo2" -> m.eo2();
            case "rep" -> m.rep();
            // Cle inconnue : on ne devine pas un denominateur, on n'affiche
            // simplement pas de pourcentage.
            default -> 0;
        };
    }

    private static double taux(AdminAnalyticsResponse.SourceRow row) {
        Double t = AnalyticsCalculs.taux(row.m().pay(), row.m().sig());
        return t == null ? 0d : t;
    }

    private static String nombre(long value) {
        return NumberFormat.getIntegerInstance(Locale.FRANCE).format(value);
    }

    private static String pourcent(double fraction) {
        return String.format(Locale.FRANCE, "%.1f %%", fraction * 100);
    }

    private static String pluriel(long value, String un, String plusieurs) {
        return value > 1 ? plusieurs : un;
    }

    /**
     * Les libelles servis viennent de nos propres tables de correspondance, mais
     * une provenance inconnue est rendue telle quelle : on echappe, plutot que de
     * faire confiance a une chaine qui a transite par une base.
     */
    private static String echappe(String texte) {
        if (texte == null) return "";
        return texte.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;");
    }
}
