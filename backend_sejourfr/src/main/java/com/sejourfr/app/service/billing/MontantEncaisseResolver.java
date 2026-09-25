package com.sejourfr.app.service.billing;

import com.sejourfr.app.config.AnalyticsProperties;
import com.sejourfr.app.entity.Plan;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Locale;
import java.util.regex.Pattern;

/**
 * Constate le montant reellement encaisse — <b>autorite unique</b> des quatre
 * colonnes de montant de {@code user_subscriptions}.
 *
 * <p><b>Ordre des sources, du plus sur au moins sur :</b>
 * <ol>
 *   <li>ce que le <b>canal de paiement</b> declare avoir preleve (Stripe
 *       {@code amount_total}, prix du store remonte par l'application) — c'est
 *       le seul chiffre qui soit un <i>fait</i> ;</li>
 *   <li>a defaut, {@code plans.price} <b>au moment de l'achat</b>, en euros.
 *       C'est une approximation honnete : ce prix est ce qu'on affichait ce
 *       jour-la. Ce qui serait malhonnete, c'est de le relire plus tard.</li>
 * </ol>
 *
 * <p>La conversion en euros se fait au taux de
 * {@code sejourfr.analytics.fx-rates}, <b>recopie dans la ligne</b> : la
 * configuration peut changer, la ligne ne bouge plus. Une devise absente de la
 * table donne un montant en euros <b>nul</b> — on n'invente pas un taux, et un
 * revenu inconnu n'est pas un revenu de zero.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class MontantEncaisseResolver {

    /** ISO 4217 : exactement trois lettres. */
    private static final Pattern DEVISE = Pattern.compile("^[A-Z]{3}$");

    private static final String EUR = "EUR";

    private final AnalyticsProperties properties;

    /**
     * Montant declare par un store mobile ({@code ProductDetails.rawPrice} +
     * {@code currencyCode}), ou {@link MontantEncaisse#INCONNU}.
     *
     * <p>Le client peut mentir — mais il ne peut mentir que sur <i>son propre</i>
     * chiffre d'affaires, et le reçu, lui, reste verifie aupres du store. Le
     * risque est sans commune mesure avec le benefice : c'est la seule source
     * qui connaisse le prix reellement affiche a cet utilisateur, dans sa
     * region et sa devise.
     */
    public MontantEncaisse duStore(Double rawPrice, String currencyCode) {
        if (rawPrice == null || rawPrice <= 0) return MontantEncaisse.INCONNU;
        String devise = normaliseDevise(currencyCode);
        if (devise == null) return MontantEncaisse.INCONNU;
        int cents = BigDecimal.valueOf(rawPrice)
                .movePointRight(2)
                .setScale(0, RoundingMode.HALF_UP)
                .intValueExact();
        return construire(cents, devise);
    }

    /**
     * Montant declare en unites mineures, ou {@link MontantEncaisse#INCONNU} :
     * Stripe {@code amount_total}, ou {@code amountCents} + {@code currency}
     * envoyes par l'application mobile a verify-receipt.
     */
    public MontantEncaisse enUnitesMineures(Long amountMinor, String currencyCode) {
        if (amountMinor == null || amountMinor <= 0 || amountMinor > Integer.MAX_VALUE) {
            return MontantEncaisse.INCONNU;
        }
        String devise = normaliseDevise(currencyCode);
        if (devise == null) return MontantEncaisse.INCONNU;
        return construire(amountMinor.intValue(), devise);
    }

    /**
     * Prix d'une transaction Apple lu dans le JWS <b>signe</b>
     * ({@code JWSTransactionDecodedPayload.price} + {@code currency}), ou
     * {@link MontantEncaisse#INCONNU}. Le champ est en <b>milliemes</b> d'unite
     * (9,99 € = {@code 9990}) : ramene en centiemes, HALF_UP — la meme echelle
     * que {@link #duStore} et que les taux de {@code fx-rates}.
     *
     * <p>C'est le seul prix Apple qui soit un fait : celui que l'application
     * declare n'est plus lu (bug Q11).
     */
    public MontantEncaisse duJwsApple(Long priceMilliemes, String currencyCode) {
        if (priceMilliemes == null || priceMilliemes <= 0) return MontantEncaisse.INCONNU;
        String devise = normaliseDevise(currencyCode);
        if (devise == null) return MontantEncaisse.INCONNU;
        long cents = BigDecimal.valueOf(priceMilliemes)
                .movePointLeft(1)
                .setScale(0, RoundingMode.HALF_UP)
                .longValueExact();
        if (cents <= 0 || cents > Integer.MAX_VALUE) return MontantEncaisse.INCONNU;
        return construire((int) cents, devise);
    }

    /**
     * Montant declare par le client, <b>borne par le catalogue</b> (bug Q11,
     * Google : {@code purchases.products.get} ne rend aucun prix, seul le client
     * le connait). Il n'est retenu que si son equivalent en euros est connu et
     * tient dans {@code plans.price × (1 ± tolerance)} ; sinon, ou si le plan n'a
     * pas de prix, c'est le prix du catalogue qui est ecrit. Un montant absurde
     * ne peut donc plus entrer dans le chiffre d'affaires.
     */
    public MontantEncaisse borneParCatalogue(MontantEncaisse declare, Plan plan, BigDecimal tolerance) {
        MontantEncaisse catalogue = duPlan(plan);
        if (declare == null || !declare.estConnu() || declare.amountEurCents() == null
                || !catalogue.estConnu() || tolerance == null) {
            return catalogue;
        }
        BigDecimal reference = BigDecimal.valueOf(catalogue.amountEurCents());
        BigDecimal min = reference.multiply(BigDecimal.ONE.subtract(tolerance));
        BigDecimal max = reference.multiply(BigDecimal.ONE.add(tolerance));
        BigDecimal eur = BigDecimal.valueOf(declare.amountEurCents());
        if (eur.compareTo(min) < 0 || eur.compareTo(max) > 0) {
            log.warn("Montant declare hors catalogue ({} {} ≈ {} c€, plan {} a {} c€) : prix du plan retenu.",
                    declare.amountCents(), declare.currency(), declare.amountEurCents(),
                    plan.getCode(), catalogue.amountEurCents());
            return catalogue;
        }
        return declare;
    }

    /**
     * Repli : le prix affiche du plan, en euros, <b>tel qu'il est aujourd'hui</b>
     * — c'est-a-dire au moment de l'achat, puisque c'est la seule fois ou cette
     * methode est appelee. Ne jamais s'en servir pour reconstituer un montant
     * passe.
     */
    public MontantEncaisse duPlan(Plan plan) {
        if (plan == null || plan.getPrice() == null) return MontantEncaisse.INCONNU;
        BigDecimal price = plan.getPrice();
        if (price.signum() <= 0) return MontantEncaisse.INCONNU;
        int cents = price.movePointRight(2).setScale(0, RoundingMode.HALF_UP).intValueExact();
        return construire(cents, EUR);
    }

    /**
     * Le premier montant reellement constate, le repli du plan sinon.
     *
     * <p>Signature commode pour les trois canaux : ils ont tous un montant
     * potentiel et tous un plan.
     */
    public MontantEncaisse ouDefautDuPlan(MontantEncaisse constate, Plan plan) {
        if (constate != null && constate.estConnu()) return constate;
        return duPlan(plan);
    }

    private MontantEncaisse construire(int cents, String devise) {
        if (EUR.equals(devise)) {
            // Pas de conversion, pas de taux a chercher : 1, et c'est ecrit
            // dans la ligne pour que la lecture n'ait aucun cas particulier.
            return new MontantEncaisse(cents, EUR, cents, BigDecimal.ONE);
        }
        BigDecimal taux = properties.fxRate(devise);
        if (taux == null || taux.signum() <= 0) {
            log.info("Devise {} sans taux configure : le montant est conserve tel quel, "
                    + "son equivalent en euros reste inconnu (jamais zero).", devise);
            return new MontantEncaisse(cents, devise, null, null);
        }
        int eurCents = BigDecimal.valueOf(cents)
                .multiply(taux)
                .setScale(0, RoundingMode.HALF_UP)
                .intValueExact();
        return new MontantEncaisse(cents, devise, eurCents, taux);
    }

    private String normaliseDevise(String raw) {
        if (raw == null || raw.isBlank()) return null;
        String devise = raw.trim().toUpperCase(Locale.ROOT);
        return DEVISE.matcher(devise).matches() ? devise : null;
    }
}
