package com.sejourfr.app.dto;

import com.fasterxml.jackson.annotation.JsonProperty;

import java.util.List;

/**
 * L'ecran Analytics, en <b>un seul objet</b>.
 *
 * <p><b>Pourquoi un endpoint et pas cinq.</b> L'ecran recalcule toutes ses
 * sections a partir d'une meme periode et des memes filtres. Cinq endpoints,
 * c'est cinq fenetres de temps a garder coherentes cote console — et le jour ou
 * l'une d'elles decale d'une seconde, deux blocs de la meme page racontent deux
 * histoires. Une reponse, une periode, une verite.
 *
 * <p><b>Les bornes appliquees sont RENDUES</b> ({@link #from}, {@link #to},
 * {@link #prevFrom}, {@link #prevTo}) : l'ecran affiche la periode d'apres le
 * serveur, jamais d'apres ce que le client croit avoir demande. C'est l'acquis
 * de {@code PageViewStatsResponse}, et il vaut ici pour la meme raison — une
 * borne future est ramenee a aujourd'hui, un ecran qui l'ignorerait afficherait
 * une periode qui n'a pas ete mesuree.
 *
 * @param period      identite de la periode affichee
 * @param from        premier jour couvert, inclus (ISO, Europe/Paris)
 * @param to          dernier jour couvert, inclus
 * @param prevFrom    premier jour de la periode de comparaison
 * @param prevTo      dernier jour de la periode de comparaison
 * @param partial     vrai si la periode contient la journee en cours — les
 *                    chiffres du dernier point ne sont pas encore complets
 * @param hourNow     heure courante a Paris (0-23), pour le dire a l'ecran
 * @param totalUsers  comptes actifs a date, <b>jamais filtre par la periode</b>
 * @param currency    devise du revenu servi ({@code EUR})
 * @param total       le vecteur de la periode
 * @param prev        le meme vecteur sur la periode precedente
 * @param sources     ventilation par provenance (first touch)
 * @param prevSources la meme, periode precedente
 * @param series      courbe temporelle, <b>continue</b> (zeros compris)
 * @param prevSeries  la meme, periode precedente
 * @param funnel      entonnoir principal, etape par etape
 * @param prevFunnel  le meme, periode precedente
 * @param countries   audience par pays
 * @param devices     audience par appareil
 * @param campaigns   audience par campagne UTM
 * @param ctas        CTA Premium par emplacement, avec attribution du paiement
 * @param triggers    ou, dans le parcours, l'inscription se declenche
 * @param paths       les parcours les plus frequents, reduits a leurs jalons
 * @param diagTypes   progression reelle de chaque format de diagnostic
 * @param abandon     ou le diagnostic perd du monde
 * @param annotations reperes produit / marketing poses sur la courbe
 * @param insights    lecture deterministe, sans LLM, au plus 4
 */
public record AdminAnalyticsResponse(
        Period period,
        String from,
        String to,
        String prevFrom,
        String prevTo,
        boolean partial,
        int hourNow,
        long totalUsers,
        String currency,
        Metrics total,
        Metrics prev,
        List<SourceRow> sources,
        List<SourceRow> prevSources,
        List<SeriesPoint> series,
        List<SeriesPoint> prevSeries,
        List<FunnelStep> funnel,
        List<FunnelStep> prevFunnel,
        List<CountryRow> countries,
        List<DeviceRow> devices,
        List<CampaignRow> campaigns,
        List<CtaRow> ctas,
        List<TriggerRow> triggers,
        List<PathRow> paths,
        List<DiagTypeRow> diagTypes,
        List<AbandonRow> abandon,
        List<AnnotationPoint> annotations,
        List<Insight> insights) {

    /**
     * Identite de la periode.
     *
     * @param id    cle stable ({@code d1}, {@code d7}, {@code custom}...)
     * @param label libelle FR pret a afficher
     * @param days  amplitude reelle, bornes incluses
     * @param grain pas de la courbe ({@code HOUR} / {@code DAY} / {@code WEEK})
     */
    public record Period(String id, String label, int days, String grain) {
    }

    /**
     * Le vecteur unique de mesure. <b>Toutes les ventilations le portent</b> :
     * une seule definition par metrique, partout.
     *
     * @param v           visiteurs <b>uniques</b> ayant eu au moins un geste —
     *                    jamais des vues (brief §27)
     * @param cta         cliqueurs sur « Faire mon diagnostic »
     * @param civique     cliqueurs sur « Passer l'examen découverte » — la
     *                    <b>seconde</b> porte de la landing, jamais fondue dans
     *                    la premiere
     * @param start       diagnostics commences
     * @param ee1         expression ecrite commencee
     * @param ee2         expression ecrite terminee
     * @param eo1         expression orale commencee
     * @param eo2         expression orale terminee
     * @param account     compte demande, les deux productions faites — la seule
     *                    marche du parcours invite qui ne laisse rien en base
     * @param rep         rapport de diagnostic affiche
     * @param sig         inscriptions, lues sur {@code users}
     * @param prem        <b>cliqueurs uniques</b> sur un CTA Premium (le volume
     *                    brut de clics ne sort que dans la table CTA)
     * @param ck          departs de paiement, lus sur {@code user_funnel_events}
     * @param pay         comptes payants, lus sur {@code user_subscriptions} —
     *                    un renouvellement n'est jamais un nouvel abonne
     * @param revEurCents revenu <b>reellement encaisse</b>, en centimes d'euro.
     *                    Un montant inconnu n'y entre pas : il ne vaut pas zero
     */
    public record Metrics(
            long v, long cta, long civique, long start,
            long ee1, long ee2, long eo1, long eo2,
            long account, long rep, long sig, long prem, long ck, long pay,
            long revEurCents) {

        public static final Metrics ZERO =
                new Metrics(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    }

    /** Une provenance et son vecteur complet. */
    public record SourceRow(String id, String label, Metrics m) {
    }

    /**
     * Un point de la courbe.
     *
     * @param label libelle long ({@code lundi 18 août})
     * @param shortLabel libelle court, pour l'axe
     * @param iso   debut du seau, ISO
     * @param isoEnd fin du seau, exclue
     * @param m     le vecteur du seau
     * @param empty vrai si rien du tout n'a ete observe — l'ecran peut le griser
     *              sans avoir a redeviner ce que « tout a zero » signifie
     */
    public record SeriesPoint(String label,
                              // « short » est un mot-cle Java : le nom du champ
                              // differe, le contrat servi ne bouge pas.
                              @JsonProperty("short") String shortLabel,
                              String iso, String isoEnd,
                              Metrics m, boolean empty) {
    }

    /**
     * Une marche de l'entonnoir.
     *
     * @param k         cle de la metrique dans {@link Metrics}
     * @param label     libelle FR
     * @param q         ce que la marche compte reellement, en une phrase
     * @param value     valeur de la marche
     * @param conv      conversion depuis la marche precedente (0..1), {@code null}
     *                  sur la premiere marche et quand la precedente vaut 0 —
     *                  <b>jamais une division par zero</b>. Une conversion
     *                  depuis rien est une <i>inconnue</i>, pas un zero
     * @param lost      acteurs perdus depuis la marche precedente. Vaut
     *                  <b>0 sur la premiere</b>, et c'est un fait : rien ne peut
     *                  se perdre avant la premiere marche
     * @param lostShare part perdue (0..1), 0 sur la premiere marche
     */
    public record FunnelStep(String k, String label, String q, long value,
                             Double conv, long lost, double lostShare) {
    }

    /**
     * Un pays. {@code id} vaut {@code UNKNOWN} quand la geo-IP n'a rien conclu —
     * jamais un pays plausible : <i>null = inconnu, jamais invente</i>.
     */
    public record CountryRow(String id, String label, long v, long sig, long rep,
                             long prem, long pay, long revEurCents) {
    }

    /** Un type d'appareil, avec la plateforme qui le porte. */
    public record DeviceRow(String id, String label, String platform, long v, long sig,
                            long rep, long prem, long pay, long revEurCents) {
    }

    /**
     * Une campagne UTM.
     *
     * @param id       cle stable de la ligne
     * @param source   libelle de la provenance
     * @param sourceId provenance normalisee
     * @param name     {@code utm_campaign}
     * @param medium   {@code utm_medium}, {@code null} si absent
     * @param content  {@code utm_content} — c'est lui qui distingue deux videos
     *                 d'une meme campagne
     * @param start    diagnostics commences
     */
    public record CampaignRow(String id, String source, String sourceId, String name,
                              String medium, String content, long v, long start, long rep,
                              long sig, long prem, long pay, long revEurCents) {
    }

    /**
     * Un emplacement de CTA Premium.
     *
     * @param where emplacement brut ({@code AnalyticsCtaLocation})
     * @param prem  cliqueurs uniques
     * @param ck    departs de paiement <b>attribues</b> a cet emplacement
     * @param pay   paiements attribues a cet emplacement
     */
    public record CtaRow(String id, String label, String where, long prem, long ck,
                         long pay, long revEurCents) {
    }

    /**
     * Un contexte d'inscription.
     *
     * @param hint  ce que ce contexte dit du parcours
     * @param sig   visiteurs ayant declenche l'inscription la
     * @param share part en pourcent, <b>arrondie a somme conservee</b>
     */
    public record TriggerRow(String id, String label, String hint, long sig, int share) {
    }

    /**
     * Un parcours, reduit a ses jalons.
     *
     * @param chain suite de jalons, provenance en tete
     * @param sig   visiteurs distincts ayant suivi exactement ce parcours
     * @param share part en pourcent des parcours servis, a somme conservee
     */
    public record PathRow(List<String> chain, long sig, int share) {
    }

    /**
     * Un format de diagnostic et sa progression reelle.
     *
     * @param steps nombre de maillons de la chaine
     * @param chain progression, maillon par maillon. <b>Vide quand on ne sait
     *              rien du format</b> — jamais une chaine de zeros, qui se
     *              lirait « tout le monde abandonne »
     */
    public record DiagTypeRow(String id, String label, String sub, long start, long done,
                              long prem, long pay, int steps, List<ChainLink> chain) {
    }

    /**
     * Un maillon d'une chaine de diagnostic.
     *
     * @param value acteurs parvenus jusqu'ici. 🛑 {@code null} quand l'evenement
     *              qui l'alimente n'existe pas encore (CO et CE du format
     *              complet : les fronts n'emettent aujourd'hui que leurs
     *              {@code _STARTED}) — <b>jamais un zero</b>, qui se lirait
     *              « tout le monde abandonne ici » alors qu'on ne mesure
     *              simplement pas encore cette etape
     * @param conv  conversion depuis le maillon precedent, {@code null} sur le
     *              premier, quand le precedent vaut 0, et quand l'un des deux
     *              n'est pas mesure
     */
    public record ChainLink(String k, String label, Long value, Double conv) {
    }

    /**
     * Une perte du diagnostic.
     *
     * @param v     acteurs perdus a cette marche
     * @param base  <b>cle de la metrique</b> sur laquelle {@code v} se lit
     *              ({@code start}, {@code ee1}, {@code ee2}, {@code eo1},
     *              {@code eo2}). On sert la cle et non le nombre : le
     *              denominateur vit deja dans {@link Metrics}, et le publier
     *              deux fois ouvrirait la porte a ce que les deux divergent
     * @param worst vrai pour la marche qui perd le plus — une seule, et
     *              seulement si le volume autorise a la designer
     */
    public record AbandonRow(String id, String label, String sub, long v, String base,
                             boolean worst) {
    }

    /** Un repere pose sur la courbe. */
    public record AnnotationPoint(String iso, String label, String kind) {
    }

    /**
     * Une lecture deterministe.
     *
     * @param tone {@code OK} / {@code WARN} / {@code BAD} / {@code NEUTRAL}
     * @param html phrase, avec au plus {@code <b> <strong> <em> <i>} —
     *             aucune autre balise n'est jamais emise
     */
    public record Insight(String tone, String html) {
    }
}
